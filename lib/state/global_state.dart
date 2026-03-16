import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_apps/device_apps.dart';
import 'package:vibration/vibration.dart';
import 'package:alarm/alarm.dart';

class GlobalState {
  // --- HAFIZADAKİ DEĞİŞKENLER ---
  static List<ApplicationWithIcon> selectedApps = [];
  static List<Map<String, dynamic>> alarms = [];
  static double testDelayMinutes = 10;
  static int selectedUsageDuration = 3;
  static double alarmVolume = 65;
  static bool isFadeInEnabled = true;
  static bool isVibrationEnabled = true;
  static int snoozeDuration = 5;

  // --- TEMA VE RENK DEĞİŞKENLERİ ---
  static String themeMode = "dark"; // "dark", "light", "custom"
  static Color accentColor = const Color(0xFF00E5FF); // Varsayılan Neon Mavi
  static Color customBgColor = const Color(0xFF0B101E); // --- EKLENDİ: Özel Arka Plan Rengi ---

  // Ses Seçimi İçin Değişkenler
  static String selectedAlarmSoundName = "Varsayılan";
  static String selectedAlarmSoundUri = "";

  // SP ANAHTARLARI
  static const String _keyAlarms = "alarms_list";
  static const String _keyDelay = "test_delay";
  static const String _keyDuration = "usage_duration";
  static const String _keyApps = "selected_app_packages";
  static const String _keyVolume = "alarm_volume";
  static const String _keyFade = "fade_in";
  static const String _keyVibrate = "vibration";
  static const String _keySnooze = "snooze_dur";
  static const String _keySoundName = "alarm_sound_name";
  static const String _keySoundUri = "alarm_sound_uri";

  // Tema Anahtarları
  static const String _keyThemeMode = "app_theme_mode";
  static const String _keyAccentColor = "app_accent_color_int";
  static const String _keyCustomBgColor = "app_custom_bg_color_int"; // --- EKLENDİ ---

  // --- MANTIK KONTROLÜ ---
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

    // Tema ve Renk Kaydetme
    await prefs.setString(_keyThemeMode, themeMode);
    await prefs.setInt(_keyAccentColor, accentColor.value);
    await prefs.setInt(_keyCustomBgColor, customBgColor.value); // --- EKLENDİ ---

    await prefs.setString(_keySoundName, selectedAlarmSoundName);
    await prefs.setString(_keySoundUri, selectedAlarmSoundUri);

    String encodedAlarms = jsonEncode(alarms);
    await prefs.setString(_keyAlarms, encodedAlarms);

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

    // Tema ve Renk Yükleme
    themeMode = prefs.getString(_keyThemeMode) ?? "dark";

    int? savedAccentValue = prefs.getInt(_keyAccentColor);
    accentColor = savedAccentValue != null ? Color(savedAccentValue) : const Color(0xFF00E5FF);

    int? savedBgValue = prefs.getInt(_keyCustomBgColor); // --- EKLENDİ ---
    customBgColor = savedBgValue != null ? Color(savedBgValue) : const Color(0xFF0B101E);

    selectedAlarmSoundName = prefs.getString(_keySoundName) ?? "Varsayılan";
    selectedAlarmSoundUri = prefs.getString(_keySoundUri) ?? "";

    String? encodedAlarms = prefs.getString(_keyAlarms);
    if (encodedAlarms != null) {
      alarms = List<Map<String, dynamic>>.from(jsonDecode(encodedAlarms));
    }

    List<String> savedPackageNames = prefs.getStringList(_keyApps) ?? [];

    if (savedPackageNames.isNotEmpty) {
      try {
        List<Application> installedApps = await DeviceApps.getInstalledApplications(
          includeAppIcons: true,
          includeSystemApps: true,
          onlyAppsWithLaunchIntent: true,
        );

        selectedApps = installedApps
            .where((app) => savedPackageNames.contains(app.packageName))
            .cast<ApplicationWithIcon>()
            .toList();
      } catch (e) {
        print("Uygulama yükleme hatası: $e");
      }
    } else {
      selectedApps = [];
    }
  }

  // --- ALARM TETİKLENDİĞİNDE ÇALIŞACAK FONKSİYON ---
  @pragma('vm:entry-point')
  static Future<void> alarmCallback() async {
    final prefs = await SharedPreferences.getInstance();

    double vol = prefs.getDouble(_keyVolume) ?? 65.0;
    bool fade = prefs.getBool(_keyFade) ?? true;
    bool vibrate = prefs.getBool(_keyVibrate) ?? true;
    String uri = prefs.getString(_keySoundUri) ?? "";

    final player = AudioPlayer();

    if (vibrate) {
      Vibration.vibrate(pattern: [500, 1000], repeat: 0);
    }

    double currentVol = fade ? 0.0 : (vol / 100);
    await player.setVolume(currentVol);

    if (uri.isNotEmpty) {
      await player.play(DeviceFileSource(uri));
    } else {
      await player.play(AssetSource('sounds/alarm.mp3'));
    }

    if (fade) {
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
  }

  static void onAlarmRing(AlarmSettings settings) {
    print("Alarm çalıyor: ${settings.id}");
  }
}