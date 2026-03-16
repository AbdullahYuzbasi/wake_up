import 'package:flutter/material.dart';
import '../state/global_state.dart';
import 'package:alarm/alarm.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class EditAlarmBottomSheet extends StatefulWidget {
  final int index;
  const EditAlarmBottomSheet({super.key, required this.index});

  @override
  State<EditAlarmBottomSheet> createState() => _EditAlarmBottomSheetState();
}

class _EditAlarmBottomSheetState extends State<EditAlarmBottomSheet> {
  // --- DEĞİŞKENLER ---
  late int selectedHour;
  late int selectedMinute;
  late List<bool> selectedDays;
  final List<String> dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  // Uygulama ve Süre Ayarları (Düzenleme için eklendi)
  AppInfo? selectedApp;
  late double testDelay;
  late double usageTarget;
  late double snoozeDuration;
  String? currentPackageName;

  @override
  void initState() {
    super.initState();
    final alarm = GlobalState.alarms[widget.index];

    // Zamanı yükle
    final timeParts = alarm["time"].split(":");
    selectedHour = int.parse(timeParts[0]);
    selectedMinute = int.parse(timeParts[1]);

    // Günleri yükle
    String daysText = alarm["days"];
    selectedDays = dayNames.map((name) => daysText.contains(name)).toList();

    // Süreleri ve Paket Adını yükle
    testDelay = (alarm["testDelay"] as num? ?? 5.0).toDouble();
    usageTarget = (alarm["usageTarget"] as num? ?? 2.0).toDouble();
    snoozeDuration = (alarm["snooze"] as num? ?? 5.0).toDouble();
    currentPackageName = alarm["packageName"];

    // Eğer bir paket adı varsa, uygulama ikonunu ve ismini getir
    if (currentPackageName != null && currentPackageName!.isNotEmpty) {
      _loadSelectedApp(currentPackageName!);
    }
  }

  // Kayıtlı paket adından uygulama bilgilerini çeker
  Future<void> _loadSelectedApp(String packageName) async {
    try {
      AppInfo? app = await InstalledApps.getAppInfo(packageName);
      setState(() => selectedApp = app);
    } catch (e) {
      print("Uygulama bilgisi yüklenemedi: $e");
    }
  }

  String _getDaysText() {
    List<String> selectedList = [];
    for (int i = 0; i < 7; i++) {
      if (selectedDays[i]) selectedList.add(dayNames[i]);
    }
    return selectedList.isEmpty ? "Tek seferlik" : selectedList.join(", ");
  }

  // Uygulama Seçici (AddAlarm sayfasıyla aynı mantık)
  void _showAppPicker() async {
    try {
      List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        withIcon: true,
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF161F30),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const Text(
                  "Takip Edilecek Uygulama",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: apps[index].icon != null
                            ? Image.memory(apps[index].icon!, width: 40)
                            : const Icon(Icons.android, color: Colors.white),
                        title: Text(
                          apps[index].name ?? "Bilinmeyen Uygulama",
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          setState(() => selectedApp = apps[index]);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      print("Uygulama listesi alınırken hata: $e");
    }
  }

  Future<void> _updateSystemAlarm(Map<String, dynamic> alarm) async {
    int alarmId = alarm["id"] % 10000;
    await Alarm.stop(alarmId);

    if (alarm["isActive"]) {
      final parts = alarm["time"].split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));

      final settings = AlarmSettings(
        id: alarmId,
        dateTime: scheduledDate,
        assetAudioPath: 'assets/sounds/alarm.mp3',
        loopAudio: true,
        vibrate: GlobalState.isVibrationEnabled,
        volume: GlobalState.alarmVolume / 100,
        notificationSettings: NotificationSettings(
          title: 'Uyanma Vakti!',
          body: selectedApp != null
              ? '${selectedApp!.name} görevi seni bekliyor!'
              : 'Alarm güncellendi ve hazır.',
          stopButton: 'Durdur',
          icon: '@mipmap/ic_launcher',
        ),
      );
      await Alarm.set(alarmSettings: settings);
    }
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required Color confirmTextColor,
    required VoidCallback onConfirm,
    required Color bgColor,
    required Color textColor,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          content: Text(content, style: TextStyle(color: textColor.withOpacity(0.7))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: textColor.withOpacity(0.5))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: Text(
                confirmText,
                style: TextStyle(color: confirmTextColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = GlobalState.themeMode == "light";
    Color bgColor = GlobalState.themeMode == "custom"
        ? GlobalState.customBgColor
        : (isLight ? Colors.white : const Color(0xFF0B101E));
    Color cardColor = isLight ? const Color(0xFFF5F6F9) : const Color(0xFF161F30);
    Color textColor = isLight ? Colors.black : Colors.white;
    Color subTextColor = isLight ? Colors.black45 : Colors.white54;
    Color accentColor = GlobalState.themeMode == "custom" ? GlobalState.accentColor : const Color(0xFF00E5FF);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Boyut biraz artırıldı sliderlar için
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView( // İçerik uzadığı için scroll eklendi
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alarmı Düzenle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(
                    icon: Icon(Icons.close, color: subTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // --- SAAT SEÇİCİ ---
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                      height: 60,
                      width: 200,
                      decoration: BoxDecoration(
                          border: Border.symmetric(
                              horizontal: BorderSide(color: accentColor.withOpacity(0.3))
                          )
                      )
                  ),
                  Text(":", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: accentColor)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWheel(24, selectedHour, (val) => setState(() => selectedHour = val), accentColor, textColor),
                      const SizedBox(width: 40),
                      _buildWheel(60, selectedMinute, (val) => setState(() => selectedMinute = val), accentColor, textColor),
                    ],
                  ),
                ],
              ),
            ),

            // --- GÜN SEÇİCİ ---
            Text('Tekrar günleri', style: TextStyle(color: subTextColor, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedDays[index] = !selectedDays[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedDays[index] ? accentColor : (isLight ? Colors.grey[200] : cardColor),
                    ),
                    child: Center(
                        child: Text(
                            dayNames[index],
                            style: TextStyle(
                                color: selectedDays[index] ? Colors.black : subTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11
                            )
                        )
                    ),
                  ),
                );
              }),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Divider(color: Colors.white10, thickness: 1),
            ),

            // --- EKSTRA AYARLAR (Uygulama ve Erteleme Süresi) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.apps, color: accentColor),
                    title: Text("Uyanıklık Testi Uygulaması", style: TextStyle(color: textColor, fontSize: 15)),
                    subtitle: Text(selectedApp?.name ?? "Uygulama Seçilmedi", style: TextStyle(color: subTextColor)),
                    trailing: Icon(Icons.arrow_forward_ios, color: subTextColor, size: 16),
                    onTap: _showAppPicker,
                  ),
                  const SizedBox(height: 15),

                  if (selectedApp == null) ...[
                    _buildCustomSlider("Erteleme Süresi", snoozeDuration, 1, 10, (val) => setState(() => snoozeDuration = val), "dk", accentColor, textColor),
                  ] else ...[
                    _buildCustomSlider("Test Süresi", testDelay, 1, 10, (val) {
                      setState(() {
                        testDelay = val;
                        if (usageTarget > testDelay) usageTarget = testDelay;
                      });
                    }, "dk", accentColor, textColor),
                    const SizedBox(height: 10),
                    _buildCustomSlider("Hedef Kullanım", usageTarget, 1, 5, (val) {
                      if (val <= testDelay) setState(() => usageTarget = val);
                    }, "dk", accentColor, textColor),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- AKSİYONLAR ---
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 33.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () {
                        String newTime = "${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";
                        _showConfirmationDialog(
                          title: 'Güncelle',
                          content: 'Alarm ayarlarını kaydetmek istiyor musun?',
                          confirmText: 'Kaydet',
                          confirmColor: accentColor,
                          confirmTextColor: Colors.black,
                          bgColor: isLight ? Colors.white : cardColor,
                          textColor: textColor,
                          onConfirm: () async {
                            // TÜM VERİLERİ GÜNCELLE
                            GlobalState.alarms[widget.index]["time"] = newTime;
                            GlobalState.alarms[widget.index]["days"] = _getDaysText();
                            GlobalState.alarms[widget.index]["packageName"] = selectedApp?.packageName ?? "";
                            GlobalState.alarms[widget.index]["appName"] = selectedApp?.name ?? "";
                            GlobalState.alarms[widget.index]["testDelay"] = testDelay;
                            GlobalState.alarms[widget.index]["usageTarget"] = usageTarget;
                            GlobalState.alarms[widget.index]["snooze"] = selectedApp == null ? snoozeDuration : 0;

                            await GlobalState.saveSettings();
                            await _updateSystemAlarm(GlobalState.alarms[widget.index]);
                            if (mounted) Navigator.pop(context);
                          },
                        );
                      },
                      child: const Text('Değişiklikleri Kaydet', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _showConfirmationDialog(
                        title: 'Alarmı Sil',
                        content: 'Bu alarm kalıcı olarak silinecek. Emin misin?',
                        confirmText: 'Sil',
                        confirmColor: Colors.redAccent,
                        confirmTextColor: Colors.white,
                        bgColor: isLight ? Colors.white : cardColor,
                        textColor: textColor,
                        onConfirm: () async {
                          int alarmId = GlobalState.alarms[widget.index]["id"] % 10000;
                          await Alarm.stop(alarmId);
                          GlobalState.alarms.removeAt(widget.index);
                          await GlobalState.saveSettings();
                          if (mounted) Navigator.pop(context);
                        },
                      );
                    },
                    child: const Text('Alarmı Sil', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel(int count, int selectedVal, Function(int) onSelected, Color accent, Color textColor) {
    return SizedBox(
      width: 70,
      child: ListWheelScrollView.useDelegate(
        itemExtent: 60,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        controller: FixedExtentScrollController(initialItem: selectedVal),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, index) {
            bool isSelected = selectedVal == index;
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 36 : 28,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? textColor : textColor.withOpacity(0.2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCustomSlider(String label, double value, double min, double max, Function(double) onChanged, String unit, Color accentColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 13)),
            Text("${value.toInt()} $unit", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value, min: min, max: max,
            activeColor: accentColor,
            inactiveColor: textColor.withOpacity(0.1),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}