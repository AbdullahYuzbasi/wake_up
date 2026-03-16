import 'package:flutter/material.dart';
import '../state/global_state.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dinamik Tema Renkleri
    bool isLight = GlobalState.themeMode == "light";
    Color bgColor = GlobalState.themeMode == "custom"
        ? GlobalState.customBgColor
        : (isLight ? Colors.white : const Color(0xFF0B101E));
    Color textColor = isLight ? Colors.black : Colors.white;
    Color accentColor = GlobalState.themeMode == "custom" ? GlobalState.accentColor : const Color(0xFF00E5FF);
    Color cardColor = isLight ? Colors.grey[200]! : const Color(0xFF161F30);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Nasıl Kullanılır?", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: Center( // İçeriği ortalamak için
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ortalamaya yardımcı olur
            children: [
              Icon(Icons.help_outline, size: 80, color: accentColor),
              const SizedBox(height: 20),
              Text(
                "Uykuyu Geride Bırakmanın Yolu",
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 30),

              // Adımlar Listesi
              _buildStepTile(
                  context,
                  "1. Alarmını Oluştur",
                  "Saati seç ve hangi günlerde uyanmak istediğini belirle. Klasik bir alarm gibi başla!",
                  Icons.alarm, accentColor, cardColor, textColor
              ),
              _buildStepTile(
                  context,
                  "2. Uyanma Kanıtı Seç",
                  "Alarmı susturmak için bir uygulama seçebilirsin. Eğer bir uygulama seçersen, o uygulamada vakit geçirene kadar alarm tam olarak susmaz.",
                  Icons.apps, accentColor, cardColor, textColor
              ),
              _buildStepTile(
                  context,
                  "3. Süreleri Belirle",
                  "Test Süresi: Alarm çaldıktan sonra testi tamamlaman gereken süre.\nHedef Kullanım: Seçtiğin uygulamada kesintisiz kalman gereken süre.",
                  Icons.timer, accentColor, cardColor, textColor
              ),
              _buildStepTile(
                  context,
                  "4. Erteleme (Snooze)",
                  "Eğer uygulama seçmezsen, klasik erteleme mantığı çalışır. Uygulama seçtiğinde ise erteleme devre dışı kalır çünkü hedefimiz seni yataktan çıkarmak!",
                  Icons.snooze, accentColor, cardColor, textColor
              ),
              _buildStepTile(
                  context,
                  "5. Kişiselleştirme",
                  "Ayarlar menüsünden 'Özel Mod' ile vurgu rengini değiştirebilir, ses seviyesini ve artan ses (fade-in) özelliğini yönetebilirsin.",
                  Icons.palette, accentColor, cardColor, textColor
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepTile(BuildContext context, String title, String content, IconData icon, Color accent, Color card, Color text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: accent),
          title: Text(title, style: TextStyle(color: text, fontWeight: FontWeight.bold)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: accent,
          collapsedIconColor: text.withOpacity(0.5),
          children: [
            Text(
              content,
              style: TextStyle(color: text.withOpacity(0.7), fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}