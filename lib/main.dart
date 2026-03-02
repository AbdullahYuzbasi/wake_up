import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'state/global_state.dart';
import 'screens/alarm_ring_screen.dart';

// Navigasyon için anahtar (Uygulama arka plandayken ekran fırlatmak için şart)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Flutter motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Alarm servisini başlat
  await Alarm.init();

  // 3. Hafızadaki kullanıcı ayarlarını (süreler vb.) yükle
  await GlobalState.loadSettings();

  // 4. KRİTİK: Overlay İzni Kontrolü
  // Android'de uygulamanın diğer uygulamaların üzerinde görünmesi için istenir.
  if (await Permission.systemAlertWindow.isDenied) {
    await Permission.systemAlertWindow.request();
  }

  // 5. ALARM ÇALMA DİNLEYİCİSİ
  Alarm.ringStream.stream.listen((settings) async {
    // GlobalState üzerinden alarm durumunu güncelle
    GlobalState.onAlarmRing(settings);

    // Sistem geçişleri için kısa bir bekleme (Stabilite sağlar)
    await Future.delayed(const Duration(milliseconds: 500));

    // NavigatorKey kullanarak her yerden AlarmRingScreen'i aç
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AlarmRingScreen(alarmSettings: settings),
      ),
    );
  });

  runApp(const WakeUpAlarmApp());
}

class WakeUpAlarmApp extends StatelessWidget {
  const WakeUpAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Dinleyici için bu anahtar zorunludur
      title: 'Sabah Rutinim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B101E),
        primaryColor: const Color(0xFF00E5FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF00E676),
        ),
      ),
      // İlk açılışta hoş geldin ekranı görünür
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 30),
                const Text(
                  'Hoş Geldin! 👋',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Sabahları gerçekten uyanmak bazen zor olabiliyor. Bu uygulama, seni gerçekten uyandırmak için tasarlandı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 40),
                _buildInfoTile(context),
                const SizedBox(height: 60),
                _buildStartButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Üst kısımdaki ikonlu kutu
  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(Icons.notifications_active_outlined, size: 50, color: Color(0xFF00E5FF)),
    );
  }

  // ExpansionTile (Nasıl Çalışır?)
  Widget _buildInfoTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Nasıl Çalışır?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: const Icon(Icons.auto_awesome, color: Color(0xFF00E5FF)),
          children: [
            _buildStep(1, 'Alarmını kur ve uyanma günlerini seç.'),
            _buildStep(2, 'Alarm kapandıktan sonra uyanıklık testi başlar.'),
            _buildStep(3, 'Seçtiğin uygulamalarda belirlenen süre kadar kal.'),
            _buildStep(4, 'Testi geçersen gerçekten uyanmış sayılırsın! 🎉'),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Başlat Butonu
  Widget _buildStartButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        child: const Text('Hadi alarmını kur! ⏰', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Liste Adımları
  Widget _buildStep(int stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2),
            child: Text(stepNumber.toString(), style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }
}