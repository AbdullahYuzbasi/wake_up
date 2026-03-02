# Sabah Rutinim - Akıllı Alarm Sistemi ⏰

Bu uygulama, klasik alarmların aksine kullanıcıyı gerçekten uyandırmak için tasarlanmış bir disiplin asistanıdır. Flutter ile geliştirilmiştir.

## 🚀 Öne Çıkan Özellikler

- **Dinamik Erteleme:** Eğer bir sabah rutini seçilmemişse standart (2-5 dk) erteleme, rutin seçilmişse hazırlık süresi (örn: 10 dk) kadar erteleme yapar.
- **Disiplin Modu (Senaryo B):** En az bir uygulama seçildiğinde **"Durdur" butonu kaybolur.** Kullanıcıyı seçtiği uygulamalarda vakit geçirmeye zorlar.
- **Otomatik Kapanma:** Kullanıcı seçilen uygulamalarda hedef süre (örn: 5 dk) kadar vakit geçirdiğinde alarm otomatik olarak kapanır ve switch pasif hale gelir.
- **Overlay Desteği:** Uygulama kapalı olsa dahi ekranın üzerinde alarm penceresi fırlar.

## 🛠️ Kurulum (Android Studio için)

1. Bu projeyi klonlayın veya ZIP olarak indirin.
2. Terminale `flutter pub get` yazarak bağımlılıkları yükleyin.
3. Projeyi çalıştırmadan önce Android cihazınızda/emülatörünüzde şu izinleri kontrol edin:
   - **Diğer uygulamaların üzerinde görüntüleme (Overlay)**
   - **Tam ekran bildirim izni**

## 📖 Algoritma Nasıl Çalışır?

### Durum 1: Uygulama Seçilmemişse
- Ekranda **DURDUR** ve **ERTELE** butonları görünür.
- DURDUR butonuna basıldığı an alarm kapanır.

### Durum 2: Uygulama Seçilmişse (Rutin Aktif)
- Ekranda **sadece ERTELE** butonu görünür.
- Alarm çaldığı an arka planda uyanıklık testi başlar.
- Kullanıcı seçili uygulamalarda (Instagram, YouTube vb.) belirlenen süre kadar vakit geçirdiğinde sistem alarmı otomatik durdurur.
- Eğer şartlar tamamlanmazsa, alarmı kapatmanın tek yolu uygulamaya girip switch'i manuel kapatmaktır.

## 📦 Kullanılan Paketler
- `alarm`: Temel alarm işlevleri.
- `permission_handler`: İzin yönetimi.
- `shared_preferences`: Veri saklama.
- `device_apps`: Uygulama listeleme.
