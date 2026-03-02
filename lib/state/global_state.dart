import 'dart:async';
import 'dart:convert'; // JSON işlemleri için eklendi
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import 'package:vibration/vibration.dart';
import 'package:alarm/alarm.dart'; // Yeni eklenen paket

class GlobalState {
  // --- HAFIZADAKİ DEĞİŞKENLER ---
  static List<ApplicationWithIcon> selectedApps = [];
  static List<Map<String, dynamic>> alarms = []; // Alarmları tutan liste
  static double testDelayMinutes = 10;
  static int selectedUsageDuration = 3;
  static double alarmVolume = 65;
  static bool isFadeInEnabled = true;
  static bool isVibrationEnabled = true;
  static int snoozeDuration = 5;

  // Ses Seçimi İçin Değişkenler
  static String selectedAlarmSoundName = "Varsayılan"; // Ekranda görünecek isim
  static String selectedAlarmSoundUri = ""; // Sistemin çalacağı yol (URI)

  // SP ANAHTARLARI
  static const String _keyAlarms = "alarms_list"; // Alarmlar için anahtar
  static const String _keyDelay = "test_delay";
  static const String _keyDuration = "usage_duration";
  static const String _keyApps = "selected_app_packages";
  static const String _keyVolume = "alarm_volume";
  static const String _keyFade = "fade_in";
  static const String _keyVibrate = "vibration";
  static const String _keySnooze = "snooze_dur";
  static const String _keySoundName = "alarm_sound_name";
  static const String _keySoundUri = "alarm_sound_uri";

  // --- MANTIK KONTROLÜ ---
  // Eğer listede en az 1 uygulama varsa rutin aktiftir (Erteleme kilitlenir)
  static bool get isRoutineActive => selectedApps.isNotEmpty;

  // --- TELEFONA KAYDETME (SAVE) ---
  static Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_keyDelay, testDelayMinutes);
    await prefs.setInt(_keyDuration, selectedUsageDuration);
    await prefs.setDouble(_keyVolume, alarmVolume);
    await prefs.setBool(_keyFade, isFadeInEnabled);
    await prefs.setBool(_keyVibrate, isVibrationEnabled);
    await prefs.setInt(_keySnooze, snoozeDuration);

    // Ses bilgilerini kaydet
    await prefs.setString(_keySoundName, selectedAlarmSoundName);
    await prefs.setString(_keySoundUri, selectedAlarmSoundUri);

    // Alarmları JSON olarak kaydet
    String encodedAlarms = jsonEncode(alarms);
    await prefs.setString(_keyAlarms, encodedAlarms);

    // Seçili uygulamaların sadece paket isimlerini kaydet
    List<String> packageNames = selectedApps.map((app) => app.packageName).toList();
    await prefs.setStringList(_keyApps, packageNames);
  }

  // --- TELEFONDAN OKUMA (LOAD) ---
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    testDelayMinutes = prefs.getDouble(_keyDelay) ?? 10.0;
    selectedUsageDuration = prefs.getInt(_keyDuration) ?? 3;
    alarmVolume = prefs.getDouble(_keyVolume) ?? 65.0;
    isFadeInEnabled = prefs.getBool(_keyFade) ?? true;
    isVibrationEnabled = prefs.getBool(_keyVibrate) ?? true;
    snoozeDuration = prefs.getInt(_keySnooze) ?? 5;

    // Ses bilgilerini yükle
    selectedAlarmSoundName = prefs.getString(_keySoundName) ?? "Varsayılan";
    selectedAlarmSoundUri = prefs.getString(_keySoundUri) ?? "";

    // Alarmları yükle
    String? encodedAlarms = prefs.getString(_keyAlarms);
    if (encodedAlarms != null) {
      alarms = List<Map<String, dynamic>>.from(jsonDecode(encodedAlarms));
    }

    // Paket isimlerini geri al
    List<String> savedPackageNames = prefs.getStringList(_keyApps) ?? [];

    if (savedPackageNames.isNotEmpty) {
      // Yüklü tüm uygulamaları (sistem uygulamaları dahil) çek ve eşleştir
      List<Application> installedApps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
      );

      selectedApps = installedApps
          .where((app) => savedPackageNames.contains(app.packageName))
          .cast<ApplicationWithIcon>()
          .toList();
    } else {
      selectedApps = [];
    }
  }

  // --- ALARM TETİKLENDİĞİNDE ÇALIŞACAK FONKSİYON ---
  @pragma('vm:entry-point')
  static Future<void> alarmCallback() async {
    // Fonksiyon izole çalıştığı için SharedPreferences'ı tekrar açıyoruz
    final prefs = await SharedPreferences.getInstance();

    // Ayarları o anki dosyadan taze oku
    double vol = prefs.getDouble(_keyVolume) ?? 65.0;
    bool fade = prefs.getBool(_keyFade) ?? true;
    bool vibrate = prefs.getBool(_keyVibrate) ?? true;
    String uri = prefs.getString(_keySoundUri) ?? "";

    final player = AudioPlayer();

    // 1. TİTREŞİM KONTROLÜ
    if (vibrate) {
      // Durdurana kadar 500ms titre, 1000ms bekle
      Vibration.vibrate(pattern: [500, 1000], repeat: 0);
    }

    // 2. SES VE FADE-IN KONTROLÜ
    double currentVol = fade ? 0.0 : (vol / 100);
    await player.setVolume(currentVol);

    if (uri.isNotEmpty) {
      // Seçilen sistem sesini çal (URI üzerinden)
      await player.play(DeviceFileSource(uri));
    } else {
      // Seçili ses yoksa varsayılan bir asset çal (bu dosyanın assets'te olması lazım)
      await player.play(AssetSource('sounds/alarm.mp3'));
    }

    if (fade) {
      // Sesi 2 saniyede bir %10 artırarak hedefe ulaş
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (currentVol >= (vol / 100)) {
          timer.cancel();
        } else {
          currentVol += 0.1;
          if (currentVol > 1.0) currentVol = 1.0;
          player.setVolume(currentVol);
        }
      });
    }

    // 3. EKRANI FIRLATMA (Buraya Test Ekranı tetikleme gelecek)
    print("Alarm çalıyor! Seçilen ses: $uri");
  }

  // --- ALARM PAKETİ İÇİN YENİ TETİKLEYİCİ ---
  // Bu metod alarm çaldığı anda 'alarm' paketi tarafından çağrılır.
  static void onAlarmRing(AlarmSettings settings) {
    print("Alarm çalıyor: ${settings.id}");
    // Arka plan test mantığı buradan tetiklenecek.
  }
}