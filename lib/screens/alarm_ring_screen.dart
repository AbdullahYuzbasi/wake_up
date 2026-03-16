import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:device_apps/device_apps.dart'; // Uygulama açmak için eklendi
import '../state/global_state.dart';
import 'home_screen.dart'; // EKLENDİ: HomeScreen'e doğrudan dönmek için

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  // --- YARDIMCI FONKSİYON: GlobalState'de Alarmi Kapat ---
  void _disableAlarmInGlobalState(int alarmId) {
    // Global listedeki ilgili alarmı bul ve isActive değerini false yap
    for (var i = 0; i < GlobalState.alarms.length; i++) {
      // ID eşleşmesini kontrol et (alarmId, milisaniye cinsinden ID'nin %10000'idir)
      if ((GlobalState.alarms[i]["id"] % 10000) == alarmId) {
        GlobalState.alarms[i]["isActive"] = false;
        print("Alarm Durumu Kapatıldı: ID $alarmId"); // Kontrol için log
        break;
      }
    }
    GlobalState.saveSettings(); // Değişikliği hafızaya (SharedPreferences) kaydet
  }

  @override
  Widget build(BuildContext context) {
    // --- VERİLERİ GLOBALSTATE'DEN ÇEK (Eşleştirme Yöntemi) ---
    // Çalan alarmın id'si ile GlobalState listesindeki orijinal veriyi buluyoruz.
    final alarmData = GlobalState.alarms.firstWhere(
          (a) => (a["id"] % 10000) == (alarmSettings.id),
      orElse: () => <String, dynamic>{},
    );

    // Verileri çekiyoruz, eğer liste boşsa varsayılan değerleri atıyoruz.
    final String packageName = alarmData['packageName'] ?? "";
    final String appName = alarmData['appName'] ?? (packageName.isNotEmpty ? "Uygulama" : "");
    final int testDelay = (alarmData['testDelay'] as num? ?? 5).toInt();
    final int snoozeMin = (alarmData['snooze'] as num? ?? 5).toInt();

    // Durum Kontrolü: Uygulama seçilmiş mi?
    bool hasTask = packageName.isNotEmpty;

    // --- TEMA VE RENKLER ---
    bool isLight = GlobalState.themeMode == "light";
    Color bgColor = GlobalState.themeMode == "custom"
        ? GlobalState.customBgColor
        : (isLight ? Colors.white : const Color(0xFF0B101E));
    Color textColor = isLight ? Colors.black : Colors.white;
    Color accentColor = GlobalState.themeMode == "custom"
        ? GlobalState.accentColor
        : const Color(0xFF00E5FF);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // 1. ÜST İKON (Parlayan Efekt)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.1),
                  border: Border.all(color: accentColor.withOpacity(0.2), width: 2),
                ),
                child: Icon(
                  hasTask ? Icons.auto_awesome_rounded : Icons.alarm_on_rounded,
                  size: 64,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 32),

              // 2. SAAT GÖSTERİMİ
              Text(
                "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -2,
                ),
              ),

              // 3. DURUM KARTI (Klasik mi yoksa Görev mi olduğunu belirtir)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isLight ? Colors.black.withOpacity(0.05) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  hasTask ? "GÖREV: $appName" : "GÜNAYDIN, UYANMA VAKTİ!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // 4. AKSİYON ALANI (Butonlar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // ANA BUTON (Durdur veya Görevi Başlat)
                    _buildMainActionButton(
                      label: hasTask ? "GÖREVİ BAŞLAT" : "DURDUR",
                      color: hasTask ? accentColor : Colors.redAccent,
                      textColor: hasTask ? Colors.black : Colors.white,
                      onTap: () async {
                        if (!hasTask) {
                          await Alarm.stop(alarmSettings.id);
                          _disableAlarmInGlobalState(alarmSettings.id);

                          if (context.mounted) {
                            // Doğrudan sayfayı temizle ve HomeScreen oluştur
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                                  (route) => false,
                            );
                          }
                        } else {
                          // --- 2. DURUM: GÖREVİ BAŞLAT VE UYGULAMAYI AÇ ---
                          await Alarm.stop(alarmSettings.id);
                          bool isOpened = await DeviceApps.openApp(packageName);

                          if (isOpened) {
                            if (context.mounted) {
                              // Uygulama açılsa bile arkadaki alarm ekranını temizle
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                                    (route) => false,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("$appName başlatılamadı!")),
                              );
                            }
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // ERTELEME BUTONU
                    _buildSnoozeButton(
                      label: hasTask ? "ERTELE ($testDelay DK)" : "ERTELE ($snoozeMin DK)",
                      textColor: textColor,
                      onTap: () async {
                        final now = DateTime.now();
                        // Görev varsa testDelay süresini, yoksa normal snooze süresini kullanır
                        final int minutes = hasTask ? testDelay : snoozeMin;

                        final newSettings = alarmSettings.copyWith(
                          dateTime: now.add(Duration(minutes: minutes)),
                        );

                        // Mevcut alarmı durdurup yeni (ertelenmiş) alarmı kurar
                        await Alarm.stop(alarmSettings.id);
                        await Alarm.set(alarmSettings: newSettings);

                        if (context.mounted) {
                          // Doğrudan sayfayı temizle ve HomeScreen oluştur
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                                (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET: Ana Aksiyon Butonu (Durdur/Görevi Başlat) ---
  Widget _buildMainActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET: Erteleme Butonu ---
  Widget _buildSnoozeButton({
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withOpacity(0.5),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}