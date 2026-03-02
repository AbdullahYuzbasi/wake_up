import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'screens/home_screen.dart';
import 'state/global_state.dart';
import 'screens/alarm_ring_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // 1. Flutter motorunun hazır olduğundan emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Alarm servisini başlatıyoruz
  await Alarm.init();

  // 3. Hafızadaki ayarları (Shared Preferences) yükle
  await GlobalState.loadSettings();

  // 4. ALARM ÇALDIĞINDA NE OLACAK?
  Alarm.ringStream.stream.listen((settings) async {
    // 1. Önce GlobalState işlemini yap
    GlobalState.onAlarmRing(settings);

    // 2. Navigasyon için kısa bir gecikme eklemek bazen Android'in yetişmesini sağlar
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. Ekranı fırlat
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
      // ÇOK ÖNEMLİ: navigatorKey'i buraya bağlamazsan ekran fırlamaz!
      navigatorKey: navigatorKey,
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
      home: const HomeScreen(), // İlk açılan ekran
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
                Container(
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
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    size: 50,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Hoş Geldin! 👋',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Sabahları gerçekten uyanmak bazen zor olabiliyor. Bu uygulama, alarm kapandıktan sonra seni gerçekten uyanık olduğundan emin ediyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161F30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: Colors.white,
                      collapsedIconColor: Colors.white70,
                      title: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Color(0xFF00E5FF)),
                          SizedBox(width: 10),
                          Text(
                            'Nasıl Çalışır?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Column(
                            children: [
                              _buildStep(1, 'Alarmını kur ve uyanma günlerini seç.'),
                              _buildStep(2, 'Alarm kapandıktan sonra bir uyanıklık testi başlar.'),
                              _buildStep(3, 'Seçtiğin uygulamalarda belirlenen süre kadar kal.'),
                              _buildStep(4, 'Testi geçersen gerçekten uyanmış sayılırsın! 🎉'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    child: const Text(
                      'Hadi alarmını kur! ⏰',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E5FF), width: 1.5),
              color: const Color(0xFF00E5FF).withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}