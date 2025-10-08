# Deep Link Demo — README

## Concept Check
- Perbedaan route Flutter vs deep link Android  
  Route di Flutter adalah navigasi internal (Navigator, stack, widget tree). Deep link di level Android adalah URI/Intent dari luar yang dikirim oleh sistem ke aplikasi (memulai atau mengirim intent ke Activity), jadi deep link menghubungkan dunia luar dengan navigation in-app.

- Kenapa Android butuh intent filter?  
  Intent filter memberi tahu sistem Android intent/URI mana yang harus diteruskan ke aplikasi (scheme, host, path). Tanpa intent filter, sistem tidak tahu aplikasi mana yang menerima link tersebut.

## Technical Understanding
- Peran paket uni_links (atau app_links)  
  Paket seperti `uni_links` atau `app_links` menyediakan API Flutter untuk membaca intent Android / URI iOS: dapatkan initial link saat cold-start dan dengarkan stream untuk link yang masuk saat aplikasi berjalan sehingga kode Dart bisa merespon (navigasi, parsing parameter).

- Apa yang terjadi jika deep link dibuka saat app sudah berjalan?  
  Sistem mengirim intent ke Activity yang sudah ada (biasanya `singleTop`); plugin memancarkan event pada stream (uriLinkStream) dan aplikasi menerima event itu tanpa restart sehingga bisa langsung menavigasi.

## Debugging Insight
Jika adb membuka app tapi tidak menavigasi ke halaman detail, periksa urutan ini:
1. Intent filter di `android/app/src/main/AndroidManifest.xml` — scheme/host/path harus cocok persis dengan intent yang dikirim.  
2. `launchMode` pada Activity (disarankan `singleTop`) dan `android:exported` benar.  
3. Subscription ke stream berada di `initState()` dan aktif (mis. `AppLinks().uriLinkStream.listen(...)`).  
4. Navigasi: gunakan `navigatorKey` (MaterialApp(navigatorKey: ...)) atau pastikan Navigator siap — link yang tiba terlalu awal perlu pending-id + postFrameCallback.  
5. Periksa package name di perintah adb (`com.example.deep_link_demo`) dan log (`flutter run` / `adb logcat -s flutter`) untuk exception.

## Summary
Deep linking mengintegrasikan intent filter Android (menerima URI dari sistem) dengan navigasi Flutter (Navigator) lewat plugin yang memberikan initial-link dan stream event, sehingga app bisa menavigasi ketika link diterima. Praktis untuk skenario seperti shared links, notifikasi yang membuka konten spesifik, atau redirect setelah autentikasi eksternal. Tantangan utama yang ditemukan adalah link yang tiba sebelum Navigator siap — solusi: gunakan `navigatorKey` dan simpan pending-id lalu push setelah first frame agar navigasi terjadi konsisten.
