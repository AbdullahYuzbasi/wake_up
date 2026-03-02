import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/global_state.dart'; // GlobalState'e erişim için yolu kontrol et

class SettingsScreen extends StatefulWidget {
  // Uygulama seçili mi (rutin aktif mi) bilgisini ana sayfadan alır.
  final bool isRoutineActive;

  const SettingsScreen({super.key, this.isRoutineActive = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE DEĞİŞKENLERİ ---
  late double alarmVolume;
  late bool isFadeInEnabled;
  late bool isVibrationEnabled;
  late int snoozeDuration; // Erteleme süresini tutacak değişken

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında GlobalState'den güncel verileri çekiyoruz
    alarmVolume = GlobalState.alarmVolume;
    isFadeInEnabled = GlobalState.isFadeInEnabled;
    isVibrationEnabled = GlobalState.isVibrationEnabled;
    snoozeDuration = GlobalState.snoozeDuration;
  }

  // Yardımcı fonksiyon: Her değişimde hem local state'i hem GlobalState'i güncelle
  void _updateAndSave() {
    GlobalState.alarmVolume = alarmVolume;
    GlobalState.isFadeInEnabled = isFadeInEnabled;
    GlobalState.isVibrationEnabled = isVibrationEnabled;
    GlobalState.snoozeDuration = snoozeDuration;
    GlobalState.saveSettings(); // Telefona kaydet
  }

  // --- ERTELEME SÜRESİ SEÇİCİ PANEL (BOTTOM SHEET) ---
  void _showSnoozePicker() {
    // Çark çevrilirken modal içindeki geçici değeri tutması için
    int tempDuration = snoozeDuration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.45,
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
                        const Text(
                          'Erteleme Süresi',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // --- ÇARK (WHEEL) SEÇİCİ ---
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Seçili alanı belli eden neon çizgiler
                        Container(
                          height: 50,
                          width: 150,
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: const Color(0xFF00E5FF).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: ListWheelScrollView.useDelegate(
                            itemExtent: 50,
                            perspective: 0.005,
                            diameterRatio: 1.2,
                            physics: const FixedExtentScrollPhysics(),
                            controller: FixedExtentScrollController(initialItem: tempDuration - 1),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempDuration = index + 1;
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 10, // 1'den 10'a kadar
                              builder: (context, index) {
                                int duration = index + 1;
                                return Center(
                                  child: Text(
                                    '$duration dk',
                                    style: TextStyle(
                                      fontSize: tempDuration == duration ? 24 : 18,
                                      fontWeight: tempDuration == duration ? FontWeight.bold : FontWeight.normal,
                                      color: tempDuration == duration ? const Color(0xFF00E5FF) : Colors.white24,
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

                  // --- KAYDET BUTONU ---
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 10.0, bottom: 40.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          // Seçimi asıl değişkene aktarıp sayfayı yeniliyoruz
                          setState(() {
                            snoozeDuration = tempDuration;
                          });
                          _updateAndSave(); // Kaydet
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Kaydet',
                          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B101E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B101E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. SES AYARLARI ---
            _buildSectionHeader(Icons.volume_up_outlined, 'SES AYARLARI'),
            const SizedBox(height: 12),
            _buildCardContainer(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Varsayılan Alarm Sesi',
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Radar', style: TextStyle(color: Colors.white54, fontSize: 14)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                      ],
                    ),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Alarm Ses Seviyesi', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('${alarmVolume.toInt()}%', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF00E5FF),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFF00E5FF),
                            trackHeight: 4.0,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                          ),
                          child: Slider(
                            value: alarmVolume,
                            min: 0,
                            max: 100,
                            onChanged: (value) {
                              setState(() {
                                alarmVolume = value;
                              });
                              _updateAndSave();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    title: 'Artan Ses (Fade-in)',
                    subtitle: 'Ses yavaşça artar',
                    trailingWidget: Switch(
                      value: isFadeInEnabled,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (value) {
                        setState(() {
                          isFadeInEnabled = value;
                        });
                        _updateAndSave();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. TİTREŞİM VE ERTELEME ---
            _buildSectionHeader(Icons.vibration, 'TİTREŞİM VE ERTELEME'),
            const SizedBox(height: 12),
            _buildCardContainer(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Titreşim',
                    trailingWidget: Switch(
                      value: isVibrationEnabled,
                      activeColor: const Color(0xFF00E5FF),
                      onChanged: (value) {
                        setState(() {
                          isVibrationEnabled = value;
                        });
                        _updateAndSave();
                      },
                    ),
                  ),
                  _buildDivider(),

                  // SADECE ERTELEME KISITLANMIŞTIR
                  if (widget.isRoutineActive)
                    _buildListTile(
                      title: 'Erteleme Süresi',
                      subtitle: 'Uyanıklık testi aktifken erteleme kapalıdır.',
                      titleColor: Colors.white30,
                      subtitleColor: Colors.white24,
                      trailingWidget: const Icon(Icons.block, color: Colors.white24, size: 20),
                      onTap: null,
                    )
                  else
                    _buildListTile(
                      title: 'Erteleme Süresi',
                      trailingWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$snoozeDuration dk', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                        ],
                      ),
                      onTap: () {
                        _showSnoozePicker();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 3. DİĞER ---
            _buildSectionHeader(Icons.info_outline, 'DİĞER'),
            const SizedBox(height: 12),
            _buildCardContainer(
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Uygulama Sürümü',
                    trailingWidget: const Text(
                      'v1.0.0',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    leadingIcon: Icons.mail_outline,
                    title: 'Geri Bildirim Gönder',
                    trailingWidget: const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: "destek@sabahrutinim.com")).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'E-posta adresi panoya kopyalandı! (destek@sabahrutinim.com)',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF161F30),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Widget? trailingWidget,
    VoidCallback? onTap,
    Color titleColor = Colors.white,
    Color subtitleColor = Colors.white54,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: const Color(0xFF00E5FF), size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 13)),
                  ]
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Colors.white12, height: 1, thickness: 1, indent: 16, endIndent: 16);
  }
}