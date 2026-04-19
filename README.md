## Prasyarat

-   **Flutter SDK** sudah terinstal.
-   **Android Studio** beserta **Android SDK** sudah terinstal.
-   Perangkat Android yang terhubung via USB (dengan **USB debugging** aktif) atau emulator Android yang sedang berjalan.

---

## Langkah-langkah

### 1. Mengatur Variabel Lingkungan (Environment Variables)

Salin file contoh konfigurasi dan sesuaikan isinya:

```bash
cp .env.example .env
```

Edit file `.env` dengan nilai yang sesuai dengan konfigurasi Anda.

### 2. Mengambil Dependensi

Jalankan perintah berikut untuk mengunduh paket-paket yang dibutuhkan:

```bash
flutter pub get
```

### 3. Menjalankan dalam Mode Debug

Gunakan perintah ini untuk menjalankan aplikasi secara spesifik di perangkat Android:

```bash
flutter run -d android
```

Atau cukup gunakan perintah di bawah ini

```bash
flutter run
```

---

## Perangkat yang Tersedia

Untuk melihat daftar perangkat dan emulator yang terhubung, gunakan perintah:

```bash
flutter devices
```
