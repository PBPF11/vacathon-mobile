Plan/Perencanaan Per pekan per individu

17-24 November

Zafran: Mendesain layout fitur 'detail event' di mobile.

Ganesha (Backend): Modifikasi Backend. Mengimplementasikan autentikasi berbasis token (misalnya, menggunakan Django Rest Framework SimpleJWT) untuk membuat endpoint API /api/token/ (Login) dan /api/register/ (Register) yang baru untuk seluler.

Alyani (Auth & Profil): Flutter Setup & UI. Mendesain layout Flutter untuk fitur Login, Register, dan "My Dashboard" (Profil Saya) berdasarkan desain web/Figma.

Josiah (Core & Events): Flutter Setup & UI. Mendesain layout Flutter untuk Main Navigation (Bottom Navigation Bar) dan Halaman Event List (Daftar Event), termasuk filter.

Fide (Forum): Flutter Setup & UI. Mendesain layout Flutter untuk Halaman Forum List (Daftar Thread) dan Halaman Forum Detail (Detail Thread).

Prama (Registrations & Admin): Flutter Setup & UI. Mendesain layout Flutter untuk Halaman "My Registrations" (Registrasi Saya) dan Halaman "Admin Dashboard" (static).

25 November-1 Desember

Zafran: Mengimplementasi kode Flutter untuk design 'detail event' (halaman statis).

Ganesha (Backend): Menyelesaikan dan melakukan testing API auth. Mulai membuat API endpoint untuk Admin (misalnya, GET /api/admin/events/ dan POST /api/admin/events/).

Alyani (Auth & Profil): Implementasi Auth. Menghubungkan screen Login & Register Flutter ke API token baru dari Ganesha. Menyimpan token (misal: menggunakan flutter_secure_storage).

Josiah (Core & Events): Implementasi Event List. Menghubungkan screen Event List ke API events/api/ (events_json) untuk menampilkan daftar event.

Fide (Forum): Implementasi Forum List. Menghubungkan screen Forum List ke API forum/api/threads/ (threads_json) untuk menampilkan daftar thread.

Prama (Registrations & Admin): Implementasi Registrasi. Menghubungkan screen "My Registrations" ke API registrations/account/registrations/api/ (my_registrations_json).

2-8 Desember

Zafran: Integrasi screen 'detail event' dengan database backend menggunakan API event-detail/events/<slug>/api/ (event_detail_json).

Ganesha (Backend): Melanjutkan pembuatan API Admin untuk Participants (Kelola Peserta) dan Forum Moderation (Moderasi Forum).

Alyani (Auth & Profil): Implementasi Profil. Membangun screen "My Dashboard" yang mengambil data dari API profiles/api/profile/ (profile_json).

Josiah (Core & Events): Implementasi Filter. Menerapkan fungsi filter dan sort di screen Event List dengan mengirim parameter ke API events_json.

Fide (Forum): Implementasi Forum Detail. Membangun screen Detail Thread, menampilkan post dan replies dari context ThreadDetailView.

Prama (Registrations & Admin): Implementasi Admin. Mulai membangun screen "Manage Events" di Flutter, menghubungkan ke API Admin Event baru dari Ganesha (fitur Read).

9-15 Desember

Zafran: Melanjutkan fitur form pendaftaran Event (menggunakan modal atau halaman baru) yang terhubung ke API registrations/events/<slug>/register/ajax/ (register_ajax).

Ganesha (Backend): Menyelesaikan testing semua API Admin (CRUD Events, Manage Participants, Forum Moderation). Memberikan dukungan backend untuk tim frontend.

Alyani (Auth & Profil): Implementasi Edit Profil. Membangun screen "Account Settings" untuk update profil dan achievements (menggunakan API achievements_api).

Josiah (Core & Events): Implementasi Home & Core. Membangun Halaman Home dengan mengambil data highlight dari events_json dan membangun Halaman "About".

Fide (Forum): Implementasi Interaksi Forum. Menerapkan fitur create post (terhubung ke API create_post) dan like post (terhubung ke API toggle_like).

Prama (Registrations & Admin): Implementasi Admin Lanjutan. Menerapkan fitur Create, Update, Delete untuk "Manage Events" di Flutter.

16-21 Desember

Zafran: Unit test dan memastikan integrasi dan fungsionalitas fitur 'detail event' & 'registrasi' dengan keseluruhan aplikasi.

Ganesha (Backend): Deployment update backend (API baru) ke server production (PWS). Final testing dan dokumentasi API.

Alyani (Auth & Profil): Implementasi Notifikasi. Membangun screen Notifikasi yang terhubung ke API notifications/api/ (notifications_json) dan mark-read.

Josiah (Core & Events): Testing alur navigasi utama, state management (misalnya, status login), dan handling error API.

Fide (Forum): Testing semua alur fitur forum (list, detail, create post, like). Memastikan UI/UX responsif.

Prama (Registrations & Admin): Testing alur "My Registrations" dan semua fitur Admin (Events & Participants). Memastikan hak akses Admin berfungsi.
