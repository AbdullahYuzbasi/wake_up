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
  // --- STATE DEĞİŞKENLERİ ---
  late double testDelayMinutes;
  late int selectedUsageDuration;

  bool _hasUsagePermission = false;
  bool _isLoadingApps = true;
  List<ApplicationWithIcon> _installedApps = [];
  Set<String> _selectedAppPackages = {};

  @override
  void initState() {
    super.initState();
    // PANEL AÇILDIĞINDA HAFIZADAKİ (GLOBAL STATE) DEĞERLERİ ÇEKİYORUZ
    testDelayMinutes = GlobalState.testDelayMinutes;
    selectedUsageDuration = GlobalState.selectedUsageDuration;
    _selectedAppPackages = GlobalState.selectedApps.map((app) => app.packageName).toSet();

    _checkPermissionAndLoadApps();
  }

  Future<void> _checkPermissionAndLoadApps() async {
    setState(() {
      _isLoadingApps = true;
    });

    bool isGranted = await UsageStats.checkUsagePermission() ?? false;

    setState(() {
      _hasUsagePermission = isGranted;
    });

    if (isGranted) {
      _loadRealApps();
    } else {
      setState(() {
        _isLoadingApps = false;
      });
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0B101E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Uyanıklık Testini Ayarla',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Alarm kapandıktan sonra test kaç dakika açık kalsın?',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${testDelayMinutes.toInt()} dk',
                        style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00E5FF),
                      inactiveTrackColor: Colors.white12,
                      thumbColor: const Color(0xFF00E5FF),
                      trackHeight: 4.0,
                    ),
                    child: Slider(
                      value: testDelayMinutes,
                      min: 1,
                      max: 10,
                      divisions: 9,
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

                  const Text(
                    'Seçtiğin uygulamaların herhangi birinde kaç dakika kalmalısın?',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
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
                            if (testDelayMinutes < duration) {
                              testDelayMinutes = duration.toDouble();
                            }
                          });
                        },
                        child: Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF00E5FF) : const Color(0xFF1E2638),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 10)]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              '$duration dk',
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  const Text(
                    'SABAH RUTİNİM',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00E5FF),
                      letterSpacing: 2.0,
                      shadows: [Shadow(blurRadius: 15)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sabah kontrol edilecek uygulamaları listeden seç:',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 15),

                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFF121A2F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildAppListArea(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 40.0),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  // 1. RAM değerlerini güncelle
                  GlobalState.testDelayMinutes = testDelayMinutes;
                  GlobalState.selectedUsageDuration = selectedUsageDuration;

                  // 2. Seçili paket isimlerini gerçek uygulama objeleriyle eşle
                  GlobalState.selectedApps = _installedApps
                      .where((app) => _selectedAppPackages.contains(app.packageName))
                      .toList();

                  // 3. TELEFONA YAZ (KALICI YAP)
                  await GlobalState.saveSettings();

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
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

  Widget _buildAppListArea() {
    if (_isLoadingApps) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
    }

    if (!_hasUsagePermission) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 42),
              const SizedBox(height: 10),
              const Text("Takip İzni Gerekli", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                "Hangi uygulamaya girdiğini algılayabilmemiz için 'Kullanım Verilerine Erişim' izni vermelisin.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await UsageStats.grantUsagePermission();
                },
                child: const Text("Ayarlara Git", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: _checkPermissionAndLoadApps,
                child: const Text("İzin Verdim, Yenile", style: TextStyle(color: Colors.white70)),
              )
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _installedApps.length,
      itemBuilder: (context, index) {
        ApplicationWithIcon app = _installedApps[index];
        bool isSelected = _selectedAppPackages.contains(app.packageName);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAppPackages.remove(app.packageName);
              } else {
                _selectedAppPackages.add(app.packageName);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF161F30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(app.icon, width: 36, height: 36),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    app.appName,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: isSelected ? Colors.black : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}