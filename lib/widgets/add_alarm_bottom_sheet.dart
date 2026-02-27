import 'package:flutter/material.dart';

class AddAlarmBottomSheet extends StatefulWidget {
  const AddAlarmBottomSheet({super.key});

  @override
  State<AddAlarmBottomSheet> createState() => _AddAlarmBottomSheetState();
}

class _AddAlarmBottomSheetState extends State<AddAlarmBottomSheet> {
  // Seçili saati ve dakikayı tutacak değişkenler
  int selectedHour = 0;
  int selectedMinute = 0;

  // Günlerin isimleri ve seçili olma durumları
  final List<String> dayNames = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
  List<bool> selectedDays = [false, false, false, false, false, false, false];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65, // Ekranın %65'ini kaplasın
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
                  'Alarmı Tamamla',
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
                // Ortadaki seçili alanı belli eden o şık çizgiler
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
                // Ortadaki ":" işareti
                const Text(
                  ":",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00E5FF),
                  ),
                ),
                // Çarklar (Saat ve Dakika)
                SizedBox(
                  width: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // SAAT ÇARKI
                      SizedBox(
                        width: 70,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 60, // Her bir rakamın yüksekliği
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
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
                                  index.toString().padLeft(2, '0'), // 01, 02 formatı
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

          // --- KAYDET BUTONU ---
          // Alt boşluk (bottom) 40 yapılarak buton yukarı alındı
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 20.0, bottom: 33.0),
            child: SizedBox(
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
                  // TODO: İleride burada alarmı veritabanına kaydedeceğiz.
                  // Şimdilik sadece paneli kapatıyoruz.
                  Navigator.pop(context);
                },
                child: const Text(
                  'Alarmı Kur',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}