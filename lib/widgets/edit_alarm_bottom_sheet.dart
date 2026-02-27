import 'package:flutter/material.dart';

class EditAlarmBottomSheet extends StatefulWidget {
  // Gerçek bir uygulamada buraya tıklanan alarmın verileri (saati, günleri) parametre olarak gelir.
  // Şimdilik UI (Arayüz) kodladığımız için boş bırakıyoruz.
  const EditAlarmBottomSheet({super.key});

  @override
  State<EditAlarmBottomSheet> createState() => _EditAlarmBottomSheetState();
}

class _EditAlarmBottomSheetState extends State<EditAlarmBottomSheet> {
  // Varsayılan olarak 07:30 seçili gelsin (Örnek)
  int selectedHour = 7;
  int selectedMinute = 30;

  final List<String> dayNames = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
  // Hafta içi seçili olsun (Örnek)
  List<bool> selectedDays = [true, true, true, true, true, false, false];

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
          backgroundColor: const Color(0xFF161F30), // Temaya uygun koyu arkaplan
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(content, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Sadece diyalogu kapatır
              child: const Text('İptal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Diyalogu kapat
                onConfirm(); // Asıl işlemi gerçekleştir (Örn: BottomSheet'i kapat)
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
      height: MediaQuery.of(context).size.height * 0.75, // Silme butonu da olduğu için biraz daha uzun
      decoration: const BoxDecoration(
        color: Color(0xFF0B101E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // --- HEADER (Başlık ve Kapatma Butonu) ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Alarm Ayarla', // 5. Fotoğraftaki başlık
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // --- SAAT VE DAKİKA SEÇİCİ (WHEEL) ---
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 60,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: const Color(0xFF00E5FF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const Text(
                  ":",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // SAAT ÇARKI
                      SizedBox(
                        width: 70,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 60,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: selectedHour),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedHour = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 24,
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: selectedHour == index ? 36 : 28,
                                    fontWeight: selectedHour == index ? FontWeight.bold : FontWeight.normal,
                                    color: selectedHour == index ? Colors.white : Colors.white24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // DAKİKA ÇARKI
                      SizedBox(
                        width: 70,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 60,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          controller: FixedExtentScrollController(initialItem: selectedMinute),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              selectedMinute = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: selectedMinute == index ? 36 : 28,
                                    fontWeight: selectedMinute == index ? FontWeight.bold : FontWeight.normal,
                                    color: selectedMinute == index ? Colors.white : Colors.white24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- GÜN SEÇİCİ ---
          Column(
            children: [
              const Text(
                'Tekrar günleri',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (index) {
                  bool isSelected = selectedDays[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDays[index] = !selectedDays[index];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2638),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.4),
                            blurRadius: 10,
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          dayNames[index],
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // --- AKSİYON BUTONLARI (GÜNCELLE VE SİL) ---
          // Alt boşluk (bottom) 40 yapılarak butonlar yukarı alındı
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 10.0, bottom: 33.0),
            child: Column(
              children: [
                // 1. Alarmı Güncelle Butonu
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      // GÜNCELLEME İÇİN ONAY DİYALOGU
                      _showConfirmationDialog(
                        title: 'Alarmı Güncelle',
                        content: 'Yapılan değişiklikleri kaydetmek istediğinize emin misiniz?',
                        confirmText: 'Güncelle',
                        confirmColor: const Color(0xFF00E5FF),
                        confirmTextColor: Colors.black,
                        onConfirm: () {
                          Navigator.pop(context); // BottomSheet'i kapat
                        },
                      );
                    },
                    child: const Text(
                      'Alarmı Güncelle',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Alarmı Sil Butonu
                GestureDetector(
                  onTap: () {
                    // SİLME İÇİN ONAY DİYALOGU
                    _showConfirmationDialog(
                      title: 'Alarmı Sil',
                      content: 'Bu alarmı tamamen silmek istediğinize emin misiniz?',
                      confirmText: 'Sil',
                      confirmColor: Colors.redAccent,
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        Navigator.pop(context); // BottomSheet'i kapat
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Alarmı Sil',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}