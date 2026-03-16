import 'package:flutter/material.dart';
import '../state/global_state.dart';
import 'package:alarm/alarm.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AddAlarmBottomSheet extends StatefulWidget {
  const AddAlarmBottomSheet({super.key});

  @override
  State<AddAlarmBottomSheet> createState() => _AddAlarmBottomSheetState();
}

class _AddAlarmBottomSheetState extends State<AddAlarmBottomSheet> {
  // --- DEĞİŞKENLER ---
  int selectedHour = DateTime.now().hour;
  int selectedMinute = DateTime.now().minute;

  // Uygulama ve Süre Ayarları (Arkadaşının vizyonu için eklendi)
  AppInfo? selectedApp;
  double testDelay = 5.0; // Test Süresi (1-10 dk)
  double usageTarget = 2.0; // Hedef Kullanım (1-5 dk)
  double snoozeDuration = 5.0; // Erteleme (1-10 dk)

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  final List<String> dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  List<bool> selectedDays = [false, false, false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController(initialItem: selectedHour);
    _minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  // --- YARDIMCI FONKSİYONLAR ---

  String _getDaysText() {
    List<String> selectedList = [];
    for (int i = 0; i < 7; i++) {
      if (selectedDays[i]) selectedList.add(dayNames[i]);
    }
    return selectedList.isEmpty ? "Tek seferlik" : selectedList.join(", ");
  }

  // Hata aldığın yer düzeltildi: Parametreler kaldırıldı veya isimlendirildi
  void _showAppPicker() async {
    try {
      // GÜNCELLEME: Sistem uygulamalarını dahil etmek için excludeSystemApps: false yapıldı
      // Parametreler: (excludeSystemApps, withIcon)
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

  Future<void> _scheduleNewAlarm(Map<String, dynamic> alarm) async {
    int alarmId = alarm["id"] % 10000;
    final parts = alarm["time"].split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final settings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledDate,
      assetAudioPath: 'assets/sounds/alarm.mp3', // Ses dosyanın yolundan emin ol
      loopAudio: true,
      vibrate: GlobalState.isVibrationEnabled,
      volume: GlobalState.alarmVolume / 100,
      notificationSettings: NotificationSettings(
        title: 'Uyanma Vakti!',
        body: selectedApp != null
            ? '${selectedApp!.name} görevi seni bekliyor!'
            : 'Güne başlamaya hazır mısın?',
        stopButton: 'Durdur',
        icon: '@mipmap/ic_launcher',
      ),
    );

    await Alarm.set(alarmSettings: settings);
  }

  // --- WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    // Tema uyumluluğu için renkleri GlobalState'den çekiyoruz
    bool isLight = GlobalState.themeMode == "light";
    Color bgColor = GlobalState.themeMode == "custom"
        ? GlobalState.customBgColor
        : (isLight ? Colors.white : const Color(0xFF0B101E));
    Color accentColor = GlobalState.themeMode == "custom"
        ? GlobalState.accentColor
        : const Color(0xFF00E5FF);
    Color textColor = isLight ? Colors.black : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            _buildHeader(textColor),

            // Time Picker Wheels
            _buildTimePickerSection(accentColor, textColor),

            const SizedBox(height: 20),

            // Day Selection
            _buildDayPickerSection(accentColor, isLight),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Divider(color: Colors.white10, thickness: 1),
            ),

            // APP AND TEST SETTINGS (Arkadaşının istediği yeni alan)
            _buildExtraSettingsSection(accentColor, textColor),

            // Save Button
            _buildSaveButton(accentColor),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Yeni Alarm Oluştur',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          IconButton(
            icon: Icon(Icons.close, color: textColor.withOpacity(0.5)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickerSection(Color accentColor, Color textColor) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 60,
            width: 220,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: accentColor.withOpacity(0.3), width: 1.5),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWheelScrollView(_hourController, 24, (index) => setState(() => selectedHour = index), selectedHour, textColor),
              Text(":", style: TextStyle(fontSize: 40, color: accentColor, fontWeight: FontWeight.bold)),
              _buildWheelScrollView(_minuteController, 60, (index) => setState(() => selectedMinute = index), selectedMinute, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWheelScrollView(controller, int count, Function(int) onSelected, int current, Color textColor) {
    return SizedBox(
      width: 80,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 60,
        perspective: 0.005,
        diameterRatio: 1.2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, index) {
            bool isSelected = current == index;
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: isSelected ? 38 : 28,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? textColor : textColor.withOpacity(0.24),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDayPickerSection(Color accentColor, bool isLight) {
    return Column(
      children: [
        Text('Hangi günlerde çalsın?', style: TextStyle(color: isLight ? Colors.black54 : Colors.white54, fontSize: 14)),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            bool isSelected = selectedDays[index];
            return GestureDetector(
              onTap: () => setState(() => selectedDays[index] = !selectedDays[index]),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accentColor : (isLight ? Colors.grey[200] : const Color(0xFF1E2638)),
                  boxShadow: isSelected ? [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 8)] : [],
                ),
                child: Center(
                  child: Text(
                    dayNames[index],
                    style: TextStyle(color: isSelected ? Colors.black : (isLight ? Colors.black54 : Colors.white54), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildExtraSettingsSection(Color accentColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // APP PICKER
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.apps, color: accentColor),
            title: Text("Uyanıklık Testi Uygulaması", style: TextStyle(color: textColor, fontSize: 15)),
            subtitle: Text(selectedApp?.name ?? "Uygulama Seçilmedi", style: TextStyle(color: textColor.withOpacity(0.38))),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            onTap: _showAppPicker,
          ),
          const SizedBox(height: 15),

          // SLIDERS
          if (selectedApp == null) ...[
            // Uygulama seçilmediyse Erteleme (Snooze) gösterilir
            _buildCustomSlider("Erteleme Süresi", snoozeDuration, 1, 10, (val) => setState(() => snoozeDuration = val), "dk", accentColor, textColor),
          ] else ...[
            // Uygulama seçildiyse Test Süresi ve Hedef Kullanım gösterilir
            _buildCustomSlider("Test Süresi (Alarmdan Sonra)", testDelay, 1, 10, (val) {
              setState(() {
                testDelay = val;
                // KURAL: Hedef kullanım test süresinden büyük olamaz
                if (usageTarget > testDelay) usageTarget = testDelay;
              });
            }, "dk", accentColor, textColor),
            const SizedBox(height: 10),
            _buildCustomSlider("Hedef Kullanım Süresi", usageTarget, 1, 5, (val) {
              // KURAL: Hedef kullanım test süresinden büyük olamaz
              if (val <= testDelay) {
                setState(() => usageTarget = val);
              }
            }, "dk", accentColor, textColor),
          ],
        ],
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
            value: value,
            min: min,
            max: max,
            activeColor: accentColor,
            inactiveColor: textColor.withOpacity(0.1),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 10,
            shadowColor: accentColor.withOpacity(0.3),
          ),
          onPressed: () async {
            String timeStr = "${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";

            final newAlarm = {
              "id": DateTime.now().millisecondsSinceEpoch,
              "time": timeStr,
              "days": _getDaysText(),
              "isActive": true,
              "packageName": selectedApp?.packageName ?? "",
              "appName": selectedApp?.name ?? "", // BU SATIRI EKLEDİK
              "testDelay": testDelay,
              "usageTarget": usageTarget,
              "snooze": selectedApp == null ? snoozeDuration : 0
            };

            GlobalState.alarms.add(newAlarm);
            await GlobalState.saveSettings();
            await _scheduleNewAlarm(newAlarm);

            if (mounted) Navigator.pop(context);
          },
          child: const Text(
            'ALAMI KAYDET',
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}