import 'dart:convert';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/models.dart';
import 'dummy_data_service.dart';

/// API Service for backend integration using pbp_django_auth
class ApiService {
  // Ganti URL ini sesuai device:
  // Android Emulator: 'http://10.0.2.2:8000'
  // iOS Simulator / Web: 'http://localhost:8000'
  // HP Fisik: Pakai IP Laptop (misal 'http://192.168.1.xxx:8000')
  static const String baseUrl = 'http://localhost:8000';

  // Singleton instance
  static ApiService? _instance;

  static ApiService get instance {
    if (_instance == null) {
      throw Exception('ApiService not initialized. Call ApiService.initialize() first.');
    }
    return _instance!;
  }

  static void initialize(CookieRequest request) {
    _instance = ApiService._internal(request);
  }

  // Instance CookieRequest disuntikkan dari AuthProvider
  final CookieRequest request;

  ApiService._internal(this.request);

  // --- Helper Methods ---

  /// Helper untuk GET request
  Future<dynamic> get(
      String endpoint, {
        Map<String, String>? queryParams,
      }) async {
    String url = '$baseUrl$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      url += '?' + Uri(queryParameters: queryParams).query;
    }

    print('[API] GET $url');
    try {
      // request.get dari pbp_django_auth otomatis menangani cookies
      final response = await request.get(url);
      print('[API] Response received: $response');
      return response;
    } catch (e) {
      print('[API] Error in GET $url: $e');
      rethrow;
    }
  }

  /// Helper untuk POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = '$baseUrl$endpoint';
    print('[API] POST $url');

    // Gunakan postJson untuk mengirim data dalam format JSON
    final response = await request.postJson(url, jsonEncode(body));
    return response;
  }

  /// Helper untuk PUT request
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final url = '$baseUrl$endpoint';
    print('[API] PUT $url');

    // pbp_django_auth mungkin tidak punya method putJson eksplisit di versi lama,
    // tapi kita bisa gunakan postJson jika backend support, atau gunakan http client bawaan request jika perlu.
    // Namun, biasanya update profile di Django PBP sering menggunakan POST.
    // Jika backend Anda strict PUT, kita bisa gunakan postJson tapi pastikan backend menerimanya,
    // atau gunakan request.put (jika tersedia di library versi terbaru).
    // Untuk aman di tutorial PBP, kita pakai postJson dulu (banyak modul Django PBP handle update via POST).
    // Jika error method not allowed, ganti endpoint backend jadi POST atau cek dokumentasi library.
    final response = await request.postJson(url, jsonEncode(body));
    return response;
  }

  /// Helper untuk DELETE request
  Future<dynamic> delete(String endpoint) async {
    final url = '$baseUrl$endpoint';
    print('[API] DELETE $url');
    // pbp_django_auth biasanya menggunakan post untuk delete di tutorial standar,
    // tapi jika library support delete, gunakan itu.
    // Kita coba gunakan get atau post tergantung implementasi backend.
    // Asumsi: Backend Django view menggunakan @csrf_exempt dan method check.
    // Untuk aman, gunakan POST saja ke endpoint delete jika library terbatas.
    // Tapi mari kita coba method standar library jika ada.
    // Fallback: gunakan postJson kosong jika endpoint support.
    final response = await request.postJson(url, jsonEncode({}));
    return response;
  }

  // --- Authentication methods ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    // Gunakan request.login bawaan library untuk login yang support session/cookies
    // URL harus full path
    final response = await request.login('$baseUrl/profile/auth/login/', {
      'username': username,
      'password': password,
    });
    return response;
  }

  Future<Map<String, dynamic>> register(
      String username,
      String password,
      ) async {
    // Panggil endpoint register di Django
    final response = await post('/profile/auth/register/', {
      'username': username,
      'password': password,
    });
    return response;
  }

  Future<void> logout() async {
    final response = await request.logout('$baseUrl/profile/auth/logout/');
    if (response['status'] == false) {
      throw Exception(response['message']);
    }
  }

  // --- Events API ---

  Future<EventsResponse> getEvents({
    int page = 1,
    Map<String, String>? filters,
  }) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEvents(page: page, filters: filters);
    }

    // Sesuaikan endpoint ini dengan urls.py Anda (misal: /profile/api/events/)
    // Jika belum ada di backend, kode ini akan error 404 sampai Anda buat view-nya.
    final query = {'page': page.toString(), ...?filters};
    final data = await get('/events/api/', queryParams: query);
    return EventsResponse.fromJson(data);
  }

  Future<Event> getEvent(int id) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEvent(id);
    }
    // Catatan: Endpoint ini mungkin perlu disesuaikan jika backend tidak menyediakan single fetch by ID.
    // Namun endpoint detail event menggunakan SLUG, bukan ID.
    throw UnimplementedError(
      "Backend uses slugs for details. Use getEventDetailBySlug instead.",
    );
  }

  // PERBAIKAN PENTING: Backend event_detail menggunakan SLUG, bukan Integer ID.
  // Lihat event_detail/urls.py -> path("events/<slug:slug>/api/", ...)
  // Anda perlu mengubah parameter dari int eventId menjadi String slug.
  Future<EventDetail> getEventDetail(String slug) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      // Dummy data service masih pakai ID, ini mungkin error jika tidak disesuaikan
      // return DummyDataService.getEventDetail(int.parse(slug));
      throw UnimplementedError("Dummy data uses INT, Backend uses SLUG.");
    }

    // URL: /event-detail/events/<slug>/api/
    final data = await get('/event-detail/events/$slug/api/');
    return EventDetail.fromJson(data);
  }

  // --- Profile API ---

  Future<UserProfile> getProfile() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getProfile();
    }
    // Pastikan URL ini sudah ada di profile/urls.py
    final data = await get('/profile/api/profile/');
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> profileData) async {
    // Endpoint yang baru kita buat di backend
    final response = await post('/profile/api/profile/update/', profileData);

    if (response['status'] == true) {
      // Jika backend mengembalikan objek 'profile' terbaru, gunakan itu.
      // Jika tidak, kita bisa fetch ulang.
      return getProfile();
    } else {
      throw Exception(response['message'] ?? "Gagal update profil");
    }
  }

  Future<List<RunnerAchievement>> getAchievements() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getAchievements();
    }
    final data = await get('/profile/api/achievements/');
    // Sesuaikan parsing JSON tergantung response Django (apakah list langsung atau dict)
    if (data['results'] != null) {
      return (data['results'] as List)
          .map((item) => RunnerAchievement.fromJson(item))
          .toList();
    }
    return [];
  }

  Future<RunnerAchievement> addAchievement(
      Map<String, dynamic> achievementData,
      ) async {
    final data = await post('/profile/api/achievements/', achievementData);
    return RunnerAchievement.fromJson(data);
  }

  Future<void> deleteAchievement(int id) async {
    await delete('/profile/api/achievements/$id/');
  }

  // --- Forum API ---

  Future<ThreadsResponse> getThreads(int eventId, {int page = 1}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getThreads(eventId, page: page);
    }
    final data = await get(
      '/forum/api/threads/',
      queryParams: {'event': eventId.toString(), 'page': page.toString()},
    );
    return ThreadsResponse.fromJson(data);
  }

  Future<ForumThread> createThread(
      int eventId,
      String title,
      String body,
      ) async {
    // Endpoint yang baru kita buat di backend
    final response = await post('/forum/api/threads/create/', {
      'event': eventId,
      'title': title,
      'body': body,
    });

    if (response['status'] == true) {
      // Karena backend mungkin belum mengembalikan full object yang dibutuhkan fromJson,
      // kita bisa return object manual atau fetch ulang.
      // Untuk amannya, kita return dummy object yang valid agar UI tidak crash,
      // lalu nanti UI akan refresh list thread.
      return ForumThread(
        id: response['id'],
        eventTitle: 'Unknown Event', // Placeholder
        authorId: '0', // Placeholder
        authorUsername: "Me",
        title: title,
        slug: response['slug'],
        body: body,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        isPinned: false,
        isLocked: false,
        viewCount: 0,
      );
    } else {
      throw Exception(response['message'] ?? "Gagal membuat thread");
    }
  }

  Future<PostsResponse> getPosts(String threadSlug, {int page = 1}) async {
    // Endpoint: /forum/api/threads/<slug>/posts/
    final data = await get(
      '/forum/api/threads/$threadSlug/posts/',
      queryParams: {'page': page.toString()},
    );
    return PostsResponse.fromJson(data);
  }

  // Pastikan parameter pertama adalah String threadSlug, BUKAN int threadId
  Future<ForumPost> createPost(
      String threadSlug,
      String content, {
        int? parentId,
      }) async {
    // URL Backend: threads/<slug:slug>/posts/
    // Prefix di urls.py project adalah 'forum/', jadi: /forum/threads/<slug>/posts/
    final url = '/forum/threads/$threadSlug/posts/';

    final body = {'content': content, if (parentId != null) 'parent': parentId};

    // Backend create_post di Django menggunakan form-data standard (request.POST)
    // Tapi pbp_django_auth .postJson mengirim JSON.
    // Anda mungkin perlu memodifikasi view create_post di backend agar menerima JSON,
    // ATAU gunakan request.post (bukan postJson) di sini jika library mendukung multipart/form-data.

    // SOLUSI TERBAIK (Ubah Backend Sedikit):
    // Buka vacathon-be/forum/views.py > create_post
    // Tambahkan logic untuk membaca json.loads(request.body) jika request.POST kosong.

    final response = await request.postJson('$baseUrl$url', jsonEncode(body));

    if (response['success'] == true) {
      // Backend mengembalikan HTML untuk partial render, bukan JSON object post lengkap.
      // Kita harus return object dummy agar Flutter tidak error.
      return ForumPost(
        id: response['post_id'],
        threadId: 0,
        authorId: '0',
        authorUsername: "Me",
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likesCount: 0,
        isLikedByUser: false,
      );
    } else {
      throw Exception("Gagal mengirim balasan");
    }
  }

  Future<void> likePost(int postId) async {
    await post('/profile/api/forum/posts/$postId/like/', {});
  }

  // --- Registrations API ---

  Future<RegistrationsResponse> getMyRegistrations({int page = 1}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getMyRegistrations(page: page);
    }
    final data = await get(
      '/register/account/registrations/api/',
      queryParams: {'page': page.toString()},
    );
    return RegistrationsResponse.fromJson(data);
  }

  // UBAH signature method ini
  Future<EventRegistration> registerForEvent(
      String eventSlug, // GANTI int eventId menjadi String eventSlug
      int categoryId,
      Map<String, dynamic> registrationData,
      ) async {
    // Sesuaikan URL dengan backend: vacathon-be/registrations/urls.py
    // path("events/<slug:slug>/register/ajax/", register_ajax, name="register-ajax")
    // URL penuh: /register/events/<slug>/register/ajax/

    // Perhatikan: registrations/urls.py di-include dengan prefix 'register/' di vacathon/urls.py
    final url = '/register/events/$eventSlug/register/ajax/';

    // Sesuaikan body request (backend mengharapkan form-data standard, tapi pbp_django_auth biasanya handle json)
    // Backend 'register_ajax' membaca request.POST.
    // Kita kirim sebagai map biasa, library akan handle.

    final data = {
      'category': categoryId.toString(), // Backend form expect string ID
      ...registrationData,
    };

    final response = await post(url, data);

    // Backend register_ajax mengembalikan {success: true, registration_url: ...}
    // Backend BELUM mengembalikan objek EventRegistration lengkap dalam JSON response.
    // Untuk solusi cepat "Fullstack", kita kembalikan object dummy atau fetch ulang.
    // Tapi idealnya, backend harusnya return data registrasi.

    if (response['success'] == true) {
      // Kita return fetch ulang registration terbaru user (opsional)
      // Atau return object sementara agar UI tidak error
      return EventRegistration(
        id: "temp",
        referenceCode: "PENDING",
        userId: 0,
        userUsername: "",
        event: Event(
          id: 0,
          title: "",
          slug: eventSlug,
          description: "",
          city: "",
          country: "",
          startDate: DateTime.now(),
          registrationDeadline: DateTime.now(),
          status: "",
          popularityScore: 0,
          participantLimit: 0,
          registeredCount: 0,
          featured: false,
          categories: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        distanceLabel: "",
        phoneNumber: "",
        emergencyContactName: "",
        emergencyContactPhone: "",
        status: "pending",
        paymentStatus: "unpaid",
        formPayload: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      throw Exception(response['errors'] ?? "Registration failed");
    }
  }

  Future<EventRegistration> getRegistration(String referenceCode) async {
    final data = await get('/profile/api/registrations/$referenceCode/');
    return EventRegistration.fromJson(data);
  }

  // --- Notifications API ---

  Future<NotificationsResponse> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getNotifications(
        page: page,
        unreadOnly: unreadOnly,
      );
    }
    final query = {'page': page.toString()};
    if (unreadOnly) query['unread'] = 'true';
    final data = await get('/notifications/api/', queryParams: query);
    return NotificationsResponse.fromJson(data);
  }

  Future<void> markNotificationRead(int id) async {
    await post('/profile/api/notifications/$id/read/', {});
  }

  Future<void> markAllNotificationsRead() async {
    await post('/profile/api/notifications/mark-all-read/', {});
  }
}
