import 'package:flutter/material.dart';
import '../state/global_state.dart';
import 'package:alarm/alarm.dart';

class EditAlarmBottomSheet extends StatefulWidget {
  final int index; // Düzenlenecek alarmın listedeki sırası
  const EditAlarmBottomSheet({super.key, required this.index});

  @override
  State<EditAlarmBottomSheet> createState() => _EditAlarmBottomSheetState();
}

class _EditAlarmBottomSheetState extends State<EditAlarmBottomSheet> {
  late int selectedHour;
  late int selectedMinute;
  late List<bool> selectedDays;
  final List<String> dayNames = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];

  @override
  void initState() {
    super.initState();
    // Mevcut alarm verilerini GlobalState'den çekiyoruz
    final alarm = GlobalState.alarms[widget.index];
    final timeParts = alarm["time"].split(":");
    selectedHour = int.parse(timeParts[0]);
    selectedMinute = int.parse(timeParts[1]);

    // Günleri mevcut veriye göre eşleştiriyoruz
    String daysText = alarm["days"];
    selectedDays = dayNames.map((name) => daysText.contains(name)).toList();
  }

  // Günleri yazıya döken yardımcı fonksiyon
  String _getDaysText() {
    List<String> selectedList = [];
    for (int i = 0; i < 7; i++) {
      if (selectedDays[i]) selectedList.add(dayNames[i]);
    }
    return selectedList.isEmpty ? "Tek seferlik" : selectedList.join(", ");
  }

  // --- GERÇEK ZAMANLI SİSTEM ALARMI GÜNCELLEME ---
  Future<void> _updateSystemAlarm(Map<String, dynamic> alarm) async {
    int alarmId = alarm["id"] % 10000;

    // Önce eski alarmı durdur
    await Alarm.stop(alarmId);

    // Eğer aktifse yenisini kur
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
          body: 'Alarm güncellendi ve hazır.',
          stopButton: 'Durdur',
          icon: '@mipmap/ic_launcher',
        ),
      );
      await Alarm.set(alarmSettings: settings);
    }
  }

  // --- ONAY DİYALOGU FONKSİYONU ---
  void _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required Color confirmTextColor,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161F30),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(content, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // Gün seçici eklendiği için uzatıldı
      decoration: const BoxDecoration(
        color: Color(0xFF0B101E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alarmı Düzenle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // --- SAAT SEÇİCİ ---
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 60, width: 200, decoration: BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3))))),
                const Text(":", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWheel(24, selectedHour, (val) => setState(() => selectedHour = val)),
                      _buildWheel(60, selectedMinute, (val) => setState(() => selectedMinute = val)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- GÜN SEÇİCİ ---
          const Text('Tekrar günleri', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(7, (index) {
              return GestureDetector(
                onTap: () => setState(() => selectedDays[index] = !selectedDays[index]),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 35, height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedDays[index] ? const Color(0xFF00E5FF) : const Color(0xFF1E2638),
                  ),
                  child: Center(child: Text(dayNames[index], style: TextStyle(color: selectedDays[index] ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12))),
                ),
              );
            }),
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
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      String newTime = "${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}";
                      _showConfirmationDialog(
                        title: 'Güncelle',
                        content: 'Alarm ayarlarını kaydetmek istiyor musun?',
                        confirmText: 'Kaydet',
                        confirmColor: const Color(0xFF00E5FF),
                        confirmTextColor: Colors.black,
                        onConfirm: () async {
                          GlobalState.alarms[widget.index]["time"] = newTime;
                          GlobalState.alarms[widget.index]["days"] = _getDaysText();
                          await GlobalState.saveSettings();
                          await _updateSystemAlarm(GlobalState.alarms[widget.index]);
                          if (context.mounted) Navigator.pop(context);
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
                      onConfirm: () async {
                        int alarmId = GlobalState.alarms[widget.index]["id"] % 10000;
                        await Alarm.stop(alarmId);
                        GlobalState.alarms.removeAt(widget.index);
                        await GlobalState.saveSettings();
                        if (context.mounted) Navigator.pop(context);
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
    );
  }

  Widget _buildWheel(int count, int selectedVal, Function(int) onSelected) {
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
            return Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: selectedVal == index ? 36 : 28,
                  fontWeight: selectedVal == index ? FontWeight.bold : FontWeight.normal,
                  color: selectedVal == index ? Colors.white : Colors.white24,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}