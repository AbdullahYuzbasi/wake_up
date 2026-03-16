import 'dart:async'; // EKLENDİ: StreamSubscription için gerekli
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:installed_apps/installed_apps.dart';

import 'screens/home_screen.dart';
import 'state/global_state.dart';
import 'screens/alarm_ring_screen.dart';

class AppConfig {
  static Color primaryColor = const Color(0xFF00E5FF);
  static const Color scaffoldBg = Color(0xFF0B101E);
  static const Color cardBg = Color(0xFF161F30);
  static Color get borderColor => primaryColor.withOpacity(0.1);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
StreamSubscription<AlarmSettings>? ringSubscription; // EKLENDİ: Çift dinlemeyi önlemek için

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  await GlobalState.loadSettings();

  final prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('first_run') ?? true;

  bool hasUsagePerm = await UsageStats.checkUsagePermission() ?? false;
  bool hasOverlayPerm = await Permission.systemAlertWindow.isGranted;
  bool hasNotifPerm = await Permission.notification.isGranted;
  bool needsPermissions = !hasUsagePerm || !hasOverlayPerm || !hasNotifPerm;

  // --- GÜNCELLEME: Kilit Ekranı ve Arka Plan Tetikleyici ---
  ringSubscription?.cancel(); // EKLENDİ: Uygulama restart atınca hata vermesini önler
  ringSubscription = Alarm.ringStream.stream.listen((settings) async {
    GlobalState.onAlarmRing(settings);

    // Uygulama tamamen kapalıysa context'in oturması için süre tanıyoruz
    Future.delayed(const Duration(milliseconds: 900), () {
      if (navigatorKey.currentState != null) {
        // Doğrudan hedef ekrana, arkadaki her şeyi silerek git
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => AlarmRingScreen(alarmSettings: settings),
          ),
              (route) => false,
        );
      }
    });
  });

  runApp(WakeUpProApp(
    startScreen: (isFirstRun || needsPermissions)
        ? const PermissionScreen()
        : const HomeScreen(),
  ));
}

class WakeUpProApp extends StatelessWidget {
  final Widget startScreen;
  const WakeUpProApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WakeUp Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConfig.scaffoldBg,
        primaryColor: AppConfig.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: AppConfig.primaryColor,
          surface: AppConfig.cardBg,
        ),
      ),
      // KRİTİK DÜZELTME: initialRoute ve routes kaldırıldı. Doğrudan home kullanıyoruz.
      home: startScreen,
    );
  }
}

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});
  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  bool _notif = false, _usage = false, _overlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final n = await Permission.notification.isGranted;
    final u = await UsageStats.checkUsagePermission() ?? false;
    final o = await Permission.systemAlertWindow.isGranted;
    if (mounted) setState(() { _notif = n; _usage = u; _overlay = o; });
  }

  Future<void> _completePermissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run', false);
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const WelcomeGuideScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool all = _notif && _usage && _overlay;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _permTile(Icons.notifications_none_outlined, 'Bildirim İzni', 'Alarmın çalması için gereklidir.', _notif, () => openAppSettings()),
                    const SizedBox(height: 16),
                    _permTile(Icons.visibility_outlined, 'Kullanım Verileri', 'Uygulama görevini takip etmek içindir.', _usage, () => UsageStats.grantUsagePermission()),
                    const SizedBox(height: 16),
                    _permTile(Icons.layers_outlined, 'Üstte Gösterme', 'Alarmın ekranı kaplaması içindir.', _overlay, () => Permission.systemAlertWindow.request()),
                  ],
                ),
              ),
              _buildContinueButton(all),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(children: [
    Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppConfig.cardBg, shape: BoxShape.circle, border: Border.all(color: AppConfig.borderColor)),
        child: Icon(Icons.shield_outlined, size: 50, color: AppConfig.primaryColor)
    ),
    const SizedBox(height: 24),
    const Text('Gerekli İzinler', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('Uygulamanın çalışması için tüm izinleri vermelisiniz.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
  ]);

  Widget _permTile(IconData icon, String title, String desc, bool ok, VoidCallback onTap) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppConfig.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppConfig.borderColor)),
    child: Row(children: [
      Icon(icon, color: ok ? Colors.greenAccent : Colors.white60),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(desc, style: const TextStyle(fontSize: 11, color: Colors.white54))])),
      ok ? const Icon(Icons.check_circle, color: Colors.greenAccent) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor, foregroundColor: Colors.black), onPressed: onTap, child: const Text("Ayarlar")),
    ]),
  );

  Widget _buildContinueButton(bool isActive) => SizedBox(
    width: double.infinity, height: 55,
    child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? AppConfig.primaryColor : Colors.white12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
        ),
        onPressed: isActive ? _completePermissions : null,
        child: Text('Hadi Başlayalım!', style: TextStyle(color: isActive ? Colors.black : Colors.white24, fontWeight: FontWeight.bold))
    ),
  );
}

class WelcomeGuideScreen extends StatelessWidget {
  const WelcomeGuideScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(Icons.notifications_active_outlined, size: 60, color: AppConfig.primaryColor),
              const SizedBox(height: 16),
              const Text("Hoş Geldin! 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text("Sabahları gerçekten uyanman için yanındayız.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
              const SizedBox(height: 32),
              _buildGuideBox(),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.primaryColor, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomeScreen())),
                child: const Text("Hadi alarmını kur! ⏰", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideBox() {
    return Container(
      padding: const EdgeInsets.all(24), // Daha ferah bir padding
      decoration: BoxDecoration(
          color: AppConfig.cardBg,
          borderRadius: BorderRadius.circular(24), // Daha yumuşak köşeler
          border: Border.all(color: AppConfig.borderColor.withOpacity(0.5))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Yazıları sola yasladık
        children: [
          Row(
              children: [
                Icon(Icons.auto_awesome, size: 24, color: AppConfig.primaryColor),
                const SizedBox(width: 10),
                const Text(
                    "Nasıl Çalışır?",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                )
              ]
          ),
          const SizedBox(height: 24),

          _step("1", "Alarmını oluştur ve uyanma günlerini belirle."),
          const SizedBox(height: 12),

          _step("2", "Bir uygulama seç; o uygulamada vakit geçirene kadar alarm tam susmaz."),
          const SizedBox(height: 12),

          _step("3", "Test ve hedef sürelerini ayarla; uyanıklığını kanıtla."),
          const SizedBox(height: 12),

          _step("4", "Görevi tamamla! Uygulama seni yataktan çıkarana kadar yanındayız. 🚀"),

          const SizedBox(height: 20),
          // Kullanıcıya bu ayarların daha sonra Ayarlar'da olduğunu hatırlatan küçük bir not
          Center(
            child: Text(
              "Tüm detaylara Ayarlar > Soru İşareti ikonundan ulaşabilirsin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // Alt widget olan _step fonksiyonunu da metinlerin sığması için Expanded ile destekleyelim:
  Widget _step(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Çok satırlı metinlerde sayıyı tepede tutar
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}