import 'package:flutter/material.dart';
import 'package:wake_up/screens/settings_screen.dart';
import '../widgets/add_alarm_bottom_sheet.dart';
import '../widgets/edit_alarm_bottom_sheet.dart';
import '../state/global_state.dart';
import 'package:alarm/alarm.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _fabController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await GlobalState.loadSettings();
    _rescheduleActiveAlarms();
    if (mounted) setState(() {});
  }

  void _rescheduleActiveAlarms() {
    for (var alarm in GlobalState.alarms) {
      if (alarm["isActive"] == true) {
        _handleAlarmSchedule(alarm, true);
      }
    }
  }

  Future<void> _handleAlarmSchedule(Map<String, dynamic> alarm, bool isActive) async {
    int alarmId = alarm["id"] % 10000;
    if (!isActive) {
      await Alarm.stop(alarmId);
      return;
    }
    final parts = alarm["time"].split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: scheduledDate,
      assetAudioPath: 'assets/sounds/alarm.mp3',
      loopAudio: true,
      vibrate: GlobalState.isVibrationEnabled,
      volume: GlobalState.alarmVolume / 100,
      fadeDuration: GlobalState.isFadeInEnabled ? 5.0 : 0.0,
      androidFullScreenIntent: true, // Kilit ekranını delip geçer
      notificationSettings: const NotificationSettings(
        title: 'WAKE UP!',
        body: 'Görevi tamamlamak için dokun!',
        stopButton: null, // Asla susturma butonu koyma
        icon: '@mipmap/ic_launcher',
      ),
    );
    try { await Alarm.set(alarmSettings: alarmSettings); } catch (e) { debugPrint(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    bool isLight = GlobalState.themeMode == "light";
    Color bgColor = GlobalState.themeMode == "custom" ? GlobalState.customBgColor : (isLight ? Colors.white : const Color(0xFF0B101E));
    Color cardColor = isLight ? const Color(0xFFF5F6F9) : const Color(0xFF161F30);
    Color textColor = isLight ? Colors.black : Colors.white;
    Color accentColor = GlobalState.themeMode == "custom" ? GlobalState.accentColor : const Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alarmlar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: textColor.withOpacity(0.7)),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: GlobalState.alarms.isEmpty
                  ? Center(child: Text("Henüz alarm yok", style: TextStyle(color: textColor.withOpacity(0.3))))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: GlobalState.alarms.length,
                itemBuilder: (context, index) => _buildAlarmCard(GlobalState.alarms[index], index, cardColor, accentColor, textColor),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3 * _fabController.value),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: accentColor,
              foregroundColor: Colors.black,
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddAlarmBottomSheet(),
                );
                setState(() {});
              },
              label: const Text("ALARM KUR", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              icon: const Icon(Icons.add_alarm),
            ),
          );
        },
      ),
    );
  }

  // home_screen.dart içindeki _buildAlarmCard fonksiyonunun ilgili kısmı:
  Widget _buildAlarmCard(Map<String, dynamic> alarm, int index, Color cardColor, Color accentColor, Color textColor) {
    bool isActive = alarm["isActive"] ?? false;

    // Uygulama seçilip seçilmediğini kontrol et
    String packageName = alarm["packageName"] ?? "";
    String subTitle = "";

    if (packageName.isEmpty) {
      // Klasik Alarm Durumu
      int snooze = (alarm["snooze"] as num? ?? 5).toInt();
      subTitle = "Klasik Alarm • Ertele: $snooze dk";
    } else {
      // Görevli Alarm Durumu
      String appName = alarm["appName"] ?? "Uygulama";
      subTitle = "Görev: $appName";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => EditAlarmBottomSheet(index: index),
          );
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                    alarm["time"],
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isActive ? textColor : textColor.withOpacity(0.3)
                    )
                ),
                // YENİLENEN ALT METİN:
                Text(
                    subTitle,
                    style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5), fontWeight: FontWeight.w600)
                ),
                Text(
                    alarm["days"],
                    style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.3))
                ),
              ]),
              Switch(
                value: alarm["isActive"] ?? false, // Burası doğrudan GlobalState verisini okumalı
                activeColor: accentColor,
                onChanged: (val) {
                  setState(() => GlobalState.alarms[index]["isActive"] = val);
                  GlobalState.saveSettings();
                  _handleAlarmSchedule(GlobalState.alarms[index], val);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}