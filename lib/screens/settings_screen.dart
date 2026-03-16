import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/global_state.dart';
// GÜNCELLEME: Rehber sayfasına gitmek için import eklendi
import 'how_to_use_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- STATE DEĞİŞKENLERİ ---
  late double alarmVolume;
  late bool isFadeInEnabled;
  late bool isVibrationEnabled;
  late String themeMode; // "dark", "light", "custom"

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında GlobalState'den güncel verileri çekiyoruz
    alarmVolume = GlobalState.alarmVolume;
    isFadeInEnabled = GlobalState.isFadeInEnabled;
    isVibrationEnabled = GlobalState.isVibrationEnabled;
    themeMode = GlobalState.themeMode;
  }

  // Yardımcı fonksiyon: Her değişimde hem local state'i hem GlobalState'i güncelle
  void _updateAndSave() {
    GlobalState.alarmVolume = alarmVolume;
    GlobalState.isFadeInEnabled = isFadeInEnabled;
    GlobalState.isVibrationEnabled = isVibrationEnabled;
    GlobalState.themeMode = themeMode;
    GlobalState.saveSettings(); // Telefona kaydet
    if (mounted) setState(() {}); // UI'ı anlık güncelle
  }

  // --- RENK SEÇİCİ PANEL (Gelişmiş Kart Yapısı ve Anlık Geri Bildirim) ---
  void _showColorPicker({required bool isBackground}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // StatefulBuilder kullanarak BottomSheet içindeki seçimlerin anlık görünmesini sağlıyoruz
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (_, controller) => Container(
                decoration: BoxDecoration(
                  color: themeMode == "light" ? Colors.white : const Color(0xFF161F30),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isBackground ? "Arka Plan Tasarımı" : "Vurgu Rengi Seçin",
                            style: TextStyle(
                                color: themeMode == "light" ? Colors.black : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          // GÜNCELLEME: Uygula butonu yerine zarif bir kapatma ikonu
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: Colors.grey.withOpacity(0.6)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: GridView.count(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: isBackground
                            ? [
                          // --- KLASİK KOYU ARKA PLANLAR ---
                          _buildColorCard(const Color(0xFF0B101E), "Lacivert", true, setModalState),
                          _buildColorCard(const Color(0xFF1B0000), "Koyu Kırmızı", true, setModalState),
                          _buildColorCard(const Color(0xFF001B05), "Koyu Yeşil", true, setModalState),
                          _buildColorCard(const Color(0xFF241400), "Koyu Turuncu", true, setModalState),
                          _buildColorCard(const Color(0xFF212121), "Koyu Gri", true, setModalState),
                          _buildColorCard(const Color(0xFF211D18), "Koyu Bej", true, setModalState),
                          _buildColorCard(const Color(0xFF001122), "Derin Mavi", true, setModalState),
                          _buildColorCard(const Color(0xFF1B1209), "Koyu Kahve", true, setModalState),
                          _buildColorCard(const Color(0xFF1A1A1A), "Saf Siyah", true, setModalState),
                          _buildColorCard(const Color(0xFF1E1428), "Derin Mor", true, setModalState),
                        ]
                            : [
                          // --- KLASİK CANLI VURGU RENKLERİ ---
                          _buildColorCard(const Color(0xFF2196F3), "Mavi", false, setModalState),
                          _buildColorCard(const Color(0xFF4CAF50), "Yeşil", false, setModalState),
                          _buildColorCard(const Color(0xFFF44336), "Kırmızı", false, setModalState),
                          _buildColorCard(const Color(0xFFFF9800), "Turuncu", false, setModalState),
                          _buildColorCard(const Color(0xFF9E9E9E), "Gri", false, setModalState),
                          _buildColorCard(const Color(0xFFF5F5DC), "Bej", false, setModalState),
                          _buildColorCard(const Color(0xFF1A237E), "Lacivert", false, setModalState),
                          _buildColorCard(const Color(0xFF8D6E63), "Açık Kahve", false, setModalState),
                          _buildColorCard(const Color(0xFF00E5FF), "Siber Mavi", false, setModalState),
                          _buildColorCard(const Color(0xFFFF4081), "Neon Pembe", false, setModalState),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- YARDIMCI WIDGET: Kart Yapısında Renk Seçici (setModalState eklendi) ---
  Widget _buildColorCard(Color color, String name, bool isBackground, StateSetter setModalState) {
    // Seçililik kontrolünü doğrudan GlobalState üzerinden anlık yapıyoruz
    bool isSelected = isBackground
        ? GlobalState.customBgColor.value == color.value
        : GlobalState.accentColor.value == color.value;

    Color textColor = themeMode == "light" ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();

        // Önce Modal'ın içindeki UI'ı güncelle (Tik işareti ve çerçeve için)
        setModalState(() {
          if (isBackground) {
            GlobalState.customBgColor = color;
          } else {
            GlobalState.accentColor = color;
          }
        });

        // Sonra ana sayfanın temasını güncelle
        _updateAndSave();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.25) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? (isBackground ? Colors.white : color) : Colors.white.withOpacity(0.08),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 26 : 22,
              height: isSelected ? 26 : 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected ? textColor : textColor.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema bazlı dinamik renk atamaları
    Color bgColor = themeMode == "light"
        ? Colors.white
        : (themeMode == "custom" ? GlobalState.customBgColor : const Color(0xFF0B101E));

    Color cardColor = themeMode == "light"
        ? const Color(0xFFF5F6F9)
        : (themeMode == "custom" ? Colors.white.withOpacity(0.05) : const Color(0xFF161F30));

    Color textColor = themeMode == "light" ? Colors.black87 : Colors.white;
    Color subTextColor = themeMode == "light" ? Colors.black45 : Colors.white54;
    Color accentColor = themeMode == "custom" ? GlobalState.accentColor : const Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayarlar',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: accentColor, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HowToUseScreen()),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GÖRÜNÜM VE TEMA ---
            _buildSectionHeader(Icons.palette_outlined, 'GÖRÜNÜM VE TEMA', subTextColor),
            const SizedBox(height: 12),
            _buildCardContainer(
              backgroundColor: cardColor,
              child: Column(
                children: [
                  _buildThemeTile("Koyu Mod", "dark", Icons.dark_mode_outlined, accentColor, textColor, subTextColor),
                  _buildDivider(),
                  _buildThemeTile("Açık Mod", "light", Icons.light_mode_outlined, accentColor, textColor, subTextColor),
                  _buildDivider(),
                  _buildThemeTile("Özel Mod", "custom", Icons.color_lens_outlined, accentColor, textColor, subTextColor),
                  if (themeMode == "custom") ...[
                    _buildDivider(),
                    _buildListTile(
                      title: 'Vurgu Rengini Seç',
                      leadingIcon: Icons.circle,
                      iconColor: GlobalState.accentColor,
                      textColor: textColor,
                      trailingWidget: Icon(Icons.chevron_right, color: subTextColor),
                      onTap: () => _showColorPicker(isBackground: false),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      title: 'Arka Plan Rengini Seç',
                      leadingIcon: Icons.format_color_fill,
                      iconColor: GlobalState.customBgColor,
                      textColor: textColor,
                      trailingWidget: Icon(Icons.chevron_right, color: subTextColor),
                      onTap: () => _showColorPicker(isBackground: true),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. SES AYARLARI ---
            _buildSectionHeader(Icons.volume_up_outlined, 'SES AYARLARI', subTextColor),
            const SizedBox(height: 12),
            _buildCardContainer(
              backgroundColor: cardColor,
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Varsayılan Alarm Sesi',
                    textColor: textColor,
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Radar', style: TextStyle(color: subTextColor, fontSize: 14)),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: subTextColor, size: 20),
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
                            Text('Alarm Ses Seviyesi', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('${alarmVolume.toInt()}%', style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: accentColor,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: accentColor,
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
                    textColor: textColor,
                    subTextColor: subTextColor,
                    trailingWidget: Switch(
                      value: isFadeInEnabled,
                      activeColor: accentColor,
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

            // --- 3. TİTREŞİM ---
            _buildSectionHeader(Icons.vibration, 'BİLDİRİM AYARLARI', subTextColor),
            const SizedBox(height: 12),
            _buildCardContainer(
              backgroundColor: cardColor,
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Titreşim',
                    textColor: textColor,
                    trailingWidget: Switch(
                      value: isVibrationEnabled,
                      activeColor: accentColor,
                      onChanged: (value) {
                        setState(() {
                          isVibrationEnabled = value;
                        });
                        _updateAndSave();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 4. DİĞER ---
            _buildSectionHeader(Icons.info_outline, 'DİĞER', subTextColor),
            const SizedBox(height: 12),
            _buildCardContainer(
              backgroundColor: cardColor,
              child: Column(
                children: [
                  _buildListTile(
                    title: 'Uygulama Sürümü',
                    textColor: textColor,
                    trailingWidget: Text(
                      'v1.1.0',
                      style: TextStyle(color: subTextColor, fontSize: 14),
                    ),
                  ),
                  _buildDivider(),
                  _buildListTile(
                    leadingIcon: Icons.mail_outline,
                    title: 'Geri Bildirim Gönder',
                    textColor: textColor,
                    trailingWidget: Icon(Icons.chevron_right, color: subTextColor, size: 20),
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: "destek@sabahrutinim.com")).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('E-posta adresi panoya kopyalandı!'),
                            backgroundColor: cardColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildThemeTile(String title, String mode, IconData icon, Color accent, Color textColor, Color subTextColor) {
    bool isSelected = themeMode == mode;
    return _buildListTile(
      title: title,
      textColor: textColor,
      leadingIcon: icon,
      iconColor: isSelected ? accent : subTextColor,
      trailingWidget: isSelected
          ? Icon(Icons.radio_button_checked, color: accent)
          : Icon(Icons.radio_button_off, color: subTextColor),
      onTap: () {
        setState(() {
          themeMode = mode;
        });
        _updateAndSave();
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child, required Color backgroundColor}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Color? iconColor,
    Widget? trailingWidget,
    VoidCallback? onTap,
    required Color textColor,
    Color? subTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: iconColor ?? const Color(0xFF00E5FF), size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: subTextColor ?? Colors.white54, fontSize: 13)),
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
    return Divider(color: Colors.black.withOpacity(0.05), height: 1, thickness: 1, indent: 16, endIndent: 16);
  }
}