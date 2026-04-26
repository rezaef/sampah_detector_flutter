# Update Maps Gratis

Versi ini mengganti Google Maps/Places menjadi OpenStreetMap.

## Paket yang dipakai
- flutter_map untuk menampilkan peta OpenStreetMap
- latlong2 untuk koordinat
- geolocator untuk lokasi perangkat
- http untuk mengambil data wilayah Indonesia, Nominatim, dan Overpass
- url_launcher untuk membuka rute di browser/OpenStreetMap

## Tidak perlu API key
Tidak ada API key Google Maps yang perlu diisi.

## Jalankan ulang dependency
```bash
flutter clean
flutter pub get
flutter run
```

## Catatan data lokasi
Data bank sampah dan lokasi pengelolaan sampah bergantung pada data OpenStreetMap. Jika area tertentu belum lengkap di OSM, hasil pencarian bisa lebih sedikit daripada Google Places.
