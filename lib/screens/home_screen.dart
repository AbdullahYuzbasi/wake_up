import 'package:flutter/material.dart';
import 'package:wake_up/screens/settings_screen.dart';
import '../widgets/add_alarm_bottom_sheet.dart';
import '../widgets/edit_alarm_bottom_sheet.dart';
import '../widgets/global_settings_bottom_sheet.dart';
import '../state/global_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> alarms = [
    {"time": "07:30", "days": "Hafta İçi", "isActive": true},
    {"time": "08:00", "days": "Hafta Sonu", "isActive": true},
    {"time": "06:45", "days": "Pzt, Çar, Cum", "isActive": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101E),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alarmlar',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161F30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(isRoutineActive: GlobalState.isRoutineActive),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  _buildGlobalSettingsCard(),
                  const SizedBox(height: 24),

                  ...alarms.asMap().entries.map((entry) {
                    int index = entry.key;
                    var alarm = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildAlarmCard(alarm, index),
                    );
                  }).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF00E5FF),
          foregroundColor: Colors.black,
          elevation: 0,
          onPressed: () async {
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return const AddAlarmBottomSheet();
              },
            );
            setState(() {});
          },
          child: const Icon(Icons.add, size: 32),
        ),
      ),
    );
  }

  Widget _buildGlobalSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SABAH RUTİNİM',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00E5FF),
                  letterSpacing: 2.0,
                  shadows: [Shadow(blurRadius: 15, color: Color(0xFF00E5FF))],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF00E5FF)),
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) {
                        return const GlobalSettingsBottomSheet();
                      },
                    );
                    setState(() {});
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),

          // TAŞMA HATASINI ÇÖZMEK İÇİN EXPANDED VE SIZEDBOX AYARI YAPILDI. SÜRELER DİNAMİK ALINDI.
          Row(
            children: [
              Expanded(child: _buildInfoItem(Icons.schedule, "Süre", "${GlobalState.testDelayMinutes.toInt()} Dk Sonra")),
              const SizedBox(width: 16),
              Expanded(child: _buildInfoItem(Icons.hourglass_empty, "Hedef Kullanım", "${GlobalState.selectedUsageDuration} Dk")),
            ],
          ),
          const SizedBox(height: 24),

          // YENİ METİN VE UYGULAMA İKONLARI ALANI
          const Text(
            "Uyandığını kanıtlamak için takip edilecek uygulamalar:",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 12),

          Row(
            children: GlobalState.selectedApps.isEmpty
                ? [
              const Expanded(
                child: Text(
                  "Henüz uygulama seçilmedi. Hadi seçin!",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              )
            ]
                : GlobalState.selectedApps.take(5).map((app) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    app.icon,
                    width: 32,
                    height: 32,
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
        ),
        const SizedBox(width: 10),
        // TAŞMAYI ÖNLEMEK İÇİN İÇERİĞİ EXPANDED İÇİNE ALIP, GEREKİRSE 3 NOKTA KOYUYORUZ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlarmCard(Map<String, dynamic> alarm, int index) {
    return GestureDetector(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return const EditAlarmBottomSheet();
          },
        );
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF161F30),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alarm["time"],
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: alarm["isActive"] ? Colors.white : Colors.white38,
                  ),
                ),
                Text(
                  alarm["days"],
                  style: TextStyle(
                    fontSize: 14,
                    color: alarm["isActive"] ? Colors.white70 : Colors.white30,
                  ),
                ),
              ],
            ),
            Switch(
              value: alarm["isActive"],
              activeColor: const Color(0xFF00E5FF),
              activeTrackColor: const Color(0xFF00E5FF).withOpacity(0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.white12,
              onChanged: (bool value) {
                setState(() {
                  alarms[index]["isActive"] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}