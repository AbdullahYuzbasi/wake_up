import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import '../state/global_state.dart';

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  Widget build(BuildContext context) {
    // MANTIK: Eğer rutin aktifse (uygulama seçilmişse) test gecikmesini kullan,
    // değilse ayarlardaki standart erteleme süresini kullan.
    final int snoozeMinutes = GlobalState.isRoutineActive
        ? GlobalState.testDelayMinutes.toInt()
        : GlobalState.snoozeDuration;

    return Scaffold(
      backgroundColor: const Color(0xFF0B101E),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, size: 100, color: Color(0xFF00E5FF)),
            const SizedBox(height: 30),

            // SAAT GÖSTERİMİ
            Text(
              "${alarmSettings.dateTime.hour.toString().padLeft(2, '0')}:${alarmSettings.dateTime.minute.toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            // DURUM METNİ
            Text(
              GlobalState.isRoutineActive ? "Sabah Rutini Bekliyor" : "Alarm Çalıyor!",
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 50),

            // DURDUR BUTONU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  await Alarm.stop(alarmSettings.id);
                  if (context.mounted) Navigator.pop(context);
                  // Burada durdurunca test süreci tetiklenebilir (eğer rutin aktifse)
                },
                child: const Text(
                  "DURDUR",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ERTELE BUTONU (DİNAMİK SÜRE)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00E5FF)),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () async {
                  final now = DateTime.now();

                  // Yeni alarm vaktini (Snooze veya Test Delay) ekliyoruz
                  final newSettings = alarmSettings.copyWith(
                    dateTime: now.add(Duration(minutes: snoozeMinutes)),
                  );

                  await Alarm.stop(alarmSettings.id);
                  await Alarm.set(alarmSettings: newSettings);

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  "ERTELE ($snoozeMinutes DK)",
                  style: const TextStyle(fontSize: 18, color: Color(0xFF00E5FF)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}