import 'package:device_apps/device_apps.dart';

class GlobalState {
  // Seçilen uygulamaları tüm detaylarıyla hafızada tutar
  static List<ApplicationWithIcon> selectedApps = [];

  // Süre ayarlarını hafızada tutar (Varsayılan değerlerle)
  static double testDelayMinutes = 10;
  static int selectedUsageDuration = 3;

  // Eğer listede en az 1 uygulama varsa rutin aktiftir (Erteleme kilitlenir)
  static bool get isRoutineActive => selectedApps.isNotEmpty;
}