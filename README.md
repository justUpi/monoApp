# 🎯 MonoTasks App

**MonoTasks** adalah aplikasi manajemen tugas (*Task Management*) modern berbasis mobile yang dirancang dengan pendekatan fokus tunggal (*mono-tasking*). Aplikasi ini mengintegrasikan **Flutter** untuk antarmuka pengguna yang responsif dan **Supabase** sebagai *backend-as-a-service* untuk sinkronisasi data secara *real-time* dan autentikasi yang aman.

---

## ✨ Fitur Utama

- **Focus-Oriented Screen**: Menyelesaikan tugas secara mendalam dari halaman fokus utama tanpa distraksi.
- **Tasks Hub**: Dasbor manajemen tugas yang rapi, terbagi menjadi dua kompartemen:
  - **Active Quests**: Menampilkan daftar tugas pending yang harus diselesaikan berdasarkan tingkat urgensi (*Importance Level 1-3*).
  - **History**: Menyimpan rekam jejak tugas-tugas yang telah sukses diselesaikan (*Read-Only View*).
- **Secure Authentication**: Sistem login dan manajemen sesi pengguna yang persisten menggunakan Supabase Auth.
- **Premium UI & Animations**: Pengalaman pengguna yang interaktif dengan micro-interactions didukung oleh `flutter_animate`.

---

## 🛠️ Arsitektur & Teknologi

Aplikasi ini dibangun menggunakan arsitektur yang bersih terpisah antara UI (*Presentation Layer*) dan *Service Layer*.

- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL Database & Auth)
- **State & Lifecycle Management**: Stateful Widgets dengan optimasi `didUpdateWidget` untuk sinkronisasi state antar halaman.

---

## 🚀 Panduan Instalasi & Menjalankan Proyek

### Prasyarat
- Flutter SDK (versi terbaru)
- Dart SDK
- Android Studio / VS Code
- Akun proyek Supabase

### Langkah-Langkah

1. **Klon Repositori ini**
   ```bash
   git clone https://github.com/justUpi/monoApp.git
   cd monotasks-app
   ```

2. **Instal Dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Supabase**
   - Buat tabel baru bernama `tasks` di dashboard Supabase milikmu dengan skema berikut:
     - `id`, `user_id`, `title`, `importance`, `is_completed`, `created_at`
   - Pastikan untuk mengaktifkan **Row Level Security (RLS)**.

4. **Inisialisasi Kredensial**
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

5. **Jalankan Aplikasi**
   ```bash
   flutter run
   ```

---

## 📂 Struktur Direktori Proyek (Singkat)

```text
lib/
├── core/
│   ├── constants.dart
|   ├── theme.dart
├── screens/
│   ├── focus_screen.dart
│   ├── home_screen.dart
|   ├── login_screen.dart
|   ├── register_screen.dart
│   └── tasks_screen.dart
├── services/
|   ├── auth_service.dart
|   ├── notification_services.dart
│   └── task_services.dart
└── widgets/
|   ├── mono_app_bar.dart
    ├── mono_card.dart
    └── task_item.dart
```

---

## 📝 Lisensi

Proyek ini dilisensikan di bawah **MIT License**.

---
*Dibuat dengan 💙 oleh Kelompok 7 ABP*
