# Integrasi Model CNN ke Flutter

Project ini sudah menyiapkan jalur inferensi TFLite. Agar hasil klasifikasi memakai model penelitian kalian, pastikan hal berikut:

## 1. Bentuk input model
Project saat ini mengasumsikan:

- ukuran input: **224 x 224 x 3**
- normalisasi: **0.0 - 1.0**
- output: **2 kelas**

## 2. Lokasi file model
Simpan model di:

```
assets/models/waste_classifier.tflite
```

## 3. Label output
Edit file:

```
assets/models/labels.txt
```

Isi default:

```
Organik
Anorganik
```

## 4. Jika model memakai preprocessing berbeda
Sesuaikan file:

```
lib/utils/image_preprocessor.dart
```

Bagian yang biasanya perlu disesuaikan:

- ukuran input
- normalisasi
- penggunaan edge image atau tidak
- urutan channel RGB/BGR

## 5. Jika output model berupa logits
Service classifier sudah mencoba menormalkan output menjadi probabilitas.
Jika kalian ingin kontrol penuh, edit file:

```
lib/services/classifier_service.dart
```

## 6. Float16 quantization
Project ini cocok dipakai untuk model TFLite hasil quantization float16 atau float32.
Jika hasil inferensi aneh, cek kembali:

- urutan label
- shape input
- preprocessing saat training vs inferensi
