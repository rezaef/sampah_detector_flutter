# Aplikasi Flutter Deteksi Sampah Organik dan Anorganik

Project ini dibuat untuk menyesuaikan proposal penelitian tentang klasifikasi sampah organik dan anorganik berbasis mobile. Struktur aplikasi mengikuti alur:

**capture gambar -> preprocessing -> inferensi -> tampilkan hasil**

## Fitur yang sudah dibuat

- Ambil gambar dari **kamera** atau **galeri**
- Preview pipeline preprocessing:
  - original
  - CLAHE approximation
  - preprocessing lanjutan (resize + smoothing)
  - edge detection preview
- Inferensi lokal dengan **TensorFlow Lite** bila model tersedia
- **Fallback mode demo heuristik** saat file model `.tflite` belum dimasukkan
- Penyimpanan **riwayat deteksi** secara lokal
- Gambar hasil deteksi disalin ke storage aplikasi agar riwayat tetap aman
- UI sederhana dan siap dikembangkan lebih lanjut

## Struktur project

```
lib/
  app.dart
  main.dart
  models/
  pages/
  services/
  utils/
  widgets/
assets/
  models/
```

## Cara menjalankan

Karena folder platform native belum digenerate di environment ini, jalankan perintah berikut di komputer lokal yang sudah terpasang Flutter SDK:

```bash
flutter create .
flutter pub get
flutter run
```

## Integrasi model TFLite

Saat ini aplikasi akan otomatis masuk ke **mode demo** jika file model belum tersedia.

Agar memakai model CNN asli:

1. Simpan model ke:

```
assets/models/waste_classifier.tflite
```

2. Pastikan `assets/models/labels.txt` berisi label sesuai urutan output model. Default project ini adalah:

```
Organik
Anorganik
```

3. Jalankan ulang:

```bash
flutter pub get
flutter run
```

## Konfigurasi platform

### Android
Untuk penggunaan `image_picker`, umumnya **tidak perlu konfigurasi tambahan** di Android.
Project ini juga sudah menyiapkan pemulihan `lost data` saat aplikasi dibuka kembali.

### iOS
Tambahkan di `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Aplikasi memerlukan akses kamera untuk mendeteksi sampah.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Aplikasi memerlukan akses galeri untuk memilih gambar sampah.</string>
```

## Catatan penting

- Pipeline CLAHE dan edge detection di project ini dibuat **ringan** agar cocok untuk perangkat mobile.
- Jika model training kalian memakai preprocessing yang sedikit berbeda, sesuaikan file `lib/utils/image_preprocessor.dart`.
- Jika output model bukan `[organik, anorganik]`, sesuaikan label pada `assets/models/labels.txt`.

## Pengembangan lanjutan yang disarankan

- Tambahkan **live camera detection**
- Tambahkan **penjelasan edukatif** per kategori sampah
- Simpan riwayat ke database lokal seperti Hive/SQLite
- Tambahkan **upload dataset contoh** untuk uji coba internal
