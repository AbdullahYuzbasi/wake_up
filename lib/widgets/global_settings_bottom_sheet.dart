/*
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:usage_stats/usage_stats.dart';
import '../state/global_state.dart';

class GlobalSettingsBottomSheet extends StatefulWidget {
  const GlobalSettingsBottomSheet({super.key});

  @override
  State<GlobalSettingsBottomSheet> createState() => _GlobalSettingsBottomSheetState();
}

class _GlobalSettingsBottomSheetState extends State<GlobalSettingsBottomSheet> {
  late double testDelayMinutes;
  late int selectedUsageDuration;

  bool _hasUsagePermission = false;
  bool _isLoadingApps = true;
  List<ApplicationWithIcon> _installedApps = [];
  Set<String> _selectedAppPackages = {};

  @override
  void initState() {
    super.initState();
    testDelayMinutes = GlobalState.testDelayMinutes;
    selectedUsageDuration = GlobalState.selectedUsageDuration;
    _selectedAppPackages = GlobalState.selectedApps.map((app) => app.packageName).toSet();
    _checkPermissionAndLoadApps();
  }

  Future<void> _checkPermissionAndLoadApps() async {
    setState(() => _isLoadingApps = true);
    bool isGranted = await UsageStats.checkUsagePermission() ?? false;
    setState(() => _hasUsagePermission = isGranted);

    if (isGranted) {
      _loadRealApps();
    } else {
      setState(() => _isLoadingApps = false);
    }
  }

  Future<void> _loadRealApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );
    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    setState(() {
      _installedApps = apps.cast<ApplicationWithIcon>();
      _isLoadingApps = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- DİNAMİK RENK VE TEMA TANIMLARI ---
    bool isLight = GlobalState.themeMode == "light";
    Color bgColor = isLight ? Colors.white : const Color(0xFF0B101E);
    Color cardColor = isLight ? const Color(0xFFF5F6F9) : const Color(0xFF161F30);
    Color textColor = isLight ? Colors.black : Colors.white;
    Color subTextColor = isLight ? Colors.black54 : Colors.white54;
    Color accentColor = GlobalState.themeMode == "custom" ? GlobalState.accentColor : const Color(0xFF00E5FF);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Uyanıklık Testini Ayarla',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: subTextColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Soru 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Alarm kapandıktan sonra test kaç dakika açık kalsın?',
                          style: TextStyle(color: subTextColor, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${testDelayMinutes.toInt()} dk',
                        style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accentColor,
                      inactiveTrackColor: accentColor.withOpacity(0.1),
                      thumbColor: accentColor,
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: testDelayMinutes,
                      min: 1, max: 10, divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          testDelayMinutes = value;
                          if (selectedUsageDuration > testDelayMinutes.toInt()) {
                            selectedUsageDuration = testDelayMinutes.toInt();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Soru 2
                  Text(
                    'Seçtiğin uygulamaların herhangi birinde kaç dakika kalmalısın?',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      int duration = index + 1;
                      bool isSelected = selectedUsageDuration == duration;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedUsageDuration = duration;
                            if (testDelayMinutes < duration) testDelayMinutes = duration.toDouble();
                          });
                        },
                        child: Container(
                          width: 55,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected ? [BoxShadow(color: accentColor.withOpacity(0.3), blurRadius: 10)] : [],
                          ),
                          child: Center(
                            child: Text(
                              '$duration dk',
                              style: TextStyle(
                                color: isSelected ? Colors.black : subTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // Uygulama Listesi Başlığı
                  Text(
                    'SABAH RUTİNİM',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sabah kontrol edilecek uygulamaları seç:',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: textColor.withOpacity(0.05), width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildAppListArea(accentColor, cardColor, textColor, subTextColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Kaydet Butonu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  GlobalState.testDelayMinutes = testDelayMinutes;
                  GlobalState.selectedUsageDuration = selectedUsageDuration;
                  GlobalState.selectedApps = _installedApps
                      .where((app) => _selectedAppPackages.contains(app.packageName))
                      .toList();
                  await GlobalState.saveSettings();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Kuralları Kaydet',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppListArea(Color accent, Color card, Color text, Color subText) {
    if (_isLoadingApps) return Center(child: CircularProgressIndicator(color: accent));

    if (!_hasUsagePermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Colors.orange, size: 40),
            const SizedBox(height: 10),
            Text("İzin Gerekli", style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () async => await UsageStats.grantUsagePermission(),
              child: Text("Ayarlara Git", style: TextStyle(color: accent)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _installedApps.length,
      itemBuilder: (context, index) {
        ApplicationWithIcon app = _installedApps[index];
        bool isSelected = _selectedAppPackages.contains(app.packageName);

        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) _selectedAppPackages.remove(app.packageName);
              else _selectedAppPackages.add(app.packageName);
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? accent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Image.memory(app.icon, width: 32, height: 32),
                const SizedBox(width: 12),
                Expanded(child: Text(app.appName, style: TextStyle(color: text, fontSize: 14))),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? accent : subText,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

*/

