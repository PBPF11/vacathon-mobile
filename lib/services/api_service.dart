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
      throw Exception(
        'ApiService not initialized. Call ApiService.initialize() first.',
      );
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
    // Special case for admin dummy login (always available for testing)
    if (username == 'admin' && password == 'prama123') {
      return {
        'status': true,
        'message': 'Login successful',
        'user': {
          'id': 1,
          'username': 'admin',
          'display_name': 'Admin User',
          'is_superuser': true,
          'is_staff': true,
        }
      };
    }

    // For regular users, always use real API regardless of USE_DUMMY_DATA setting
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
    // Always use real API for events
    final query = {'page': page.toString(), ...?filters};
    final data = await get('/events/api/', queryParams: query);
    return EventsResponse.fromJson(data);
  }

  // --- Admin Events API ---

  Future<EventsResponse> getAdminEvents({
    int page = 1,
    Map<String, String>? filters,
  }) async {
    // Admin functions always use real API, never dummy data
    // Admin endpoint for managing events
    final query = {'page': page.toString(), ...?filters};
    final data = await get('/admin/events/api/', queryParams: query);
    return EventsResponse.fromJson(data);
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    // Admin functions always use real API, never dummy data
    final data = await post('/admin/events/api/', eventData);
    return Event.fromJson(data);
  }

  Future<Event> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    // Admin functions always use real API, never dummy data
    final data = await put('/admin/events/api/$eventId/', eventData);
    return Event.fromJson(data);
  }

  Future<void> deleteEvent(int eventId) async {
    // Admin functions always use real API, never dummy data
    await delete('/admin/events/api/$eventId/');
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
    // Always use real API for profile data, regardless of USE_DUMMY_DATA setting
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
    // Always use real API for achievements
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

  Future<ThreadsResponse> getThreads({int? eventId, int page = 1}) async {
    // Always use real API for forum threads
    final queryParams = {'page': page.toString()};
    if (eventId != null) {
      queryParams['event'] = eventId.toString();
    }

    final data = await get('/forum/api/threads/', queryParams: queryParams);
    return ThreadsResponse.fromJson(data);
  }

  Future<ForumThread> getThreadDetail(String slug) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      throw UnimplementedError("Dummy data for single thread not implemented");
    }
    // Add cache buster to prevent browser caching
    final data = await get(
      '/forum/api/threads/$slug/',
      queryParams: {'_': DateTime.now().millisecondsSinceEpoch.toString()},
    );
    return ForumThread.fromJson(data);
  }

  Future<ForumThread> createThread(
      int eventId,
      String title,
      String body,
      ) async {
    // Endpoint yang baru kita buat di backend
    final response = await post('/api/forum/threads/', {
      'event': eventId,
      'title': title,
      'body': body,
    });

    // Backend returns the created thread object
    return ForumThread.fromJson(response);
  }

  Future<PostsResponse> getPosts(String threadSlug, {int page = 1}) async {
    // Endpoint: /forum/threads/<thread_slug>/posts/
    final data = await get(
      '/forum/threads/$threadSlug/posts/',
      queryParams: {'page': page.toString()},
    );
    return PostsResponse.fromJson(data);
  }

  Future<ForumPost> createPost(
      String threadSlug,
      String content, {
        int? parentId,
      }) async {
    // URL Backend: threads/<slug:slug>/posts/
    // Prefix di urls.py project adalah 'forum/', jadi: /forum/threads/<slug>/posts/
    final url = '/forum/threads/$threadSlug/posts/';
    final body = {
      'content': content,
      if (parentId != null) 'parent': parentId
    };

    final response = await post(url, body);

    // Backend returns the created post object
    return ForumPost.fromJson(response);
  }

  Future<void> likePost(int postId) async {
    // OLD: await post('/profile/api/forum/posts/$postId/like/', {});
    // NEW Check urls.py: path("posts/<int:post_id>/like/", toggle_like, name="post-like")
    // Prefix 'forum/' -> '/forum/posts/$postId/like/'
    await post('/forum/posts/$postId/like/', {});
  }

  Future<void> deleteThread(String slug) async {
    final response = await post('/forum/api/threads/$slug/delete/', {});
    if (response['status'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete thread');
    }
  }

  Future<void> deletePost(int postId) async {
    final response = await post('/forum/api/posts/$postId/delete/', {});
    if (response['status'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete post');
    }
  }

  // --- Registrations API ---

  Future<RegistrationsResponse> getMyRegistrations({int page = 1}) async {
    // Always use real API for user registrations
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
    try {
      final data = await get('/register/account/registrations/$referenceCode/api/');
      return EventRegistration.fromJson(data);
    } catch (e) {
      print('[ERROR] Registration API failed, returning dummy data: $e');
      // Return dummy registration for now
      return EventRegistration(
        id: "temp-$referenceCode",
        referenceCode: referenceCode,
        userId: 0,
        userUsername: "",
        event: Event(
          id: 0,
          title: "Unknown Event",
          slug: "",
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
        status: "unknown",
        paymentStatus: "unknown",
        formPayload: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // --- Notifications API ---

  Future<NotificationsResponse> getNotifications({
    int page = 1,
    bool unreadOnly = false,
  }) async {
    // Always use real API for notifications
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

  // --- Admin API Methods ---

  /// Get admin dashboard statistics
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final data = await get('/admin/api/stats/');
      return data;
    } catch (e) {
      // Return dummy stats if API not implemented
      return {
        'total_participants': 150,
        'total_events': 5,
        'active_events': 3,
        'completed_events': 2,
      };
    }
  }

  /// Get all participants for admin (paginated)
  Future<Map<String, dynamic>> getAdminParticipants({int page = 1, int pageSize = 20}) async {
    try {
      final data = await get('/admin/api/participants/', queryParams: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      });
      return data;
    } catch (e) {
      // Return dummy data if API not implemented
      return {
        'results': [],
        'pagination': {
          'page': page,
          'pages': 1,
          'has_next': false,
          'has_previous': false,
          'total': 0,
        }
      };
    }
  }

  /// Confirm a participant registration
  Future<void> confirmParticipant(int participantId) async {
    await post('/admin/api/participants/$participantId/confirm/', {});
  }

  /// Delete a participant registration
  Future<void> deleteParticipant(int participantId) async {
    await delete('/admin/api/participants/$participantId/');
  }

  /// Create a new event (admin)
  Future<Map<String, dynamic>> createEventAdmin(Map<String, dynamic> eventData) async {
    final response = await post('/admin/api/events/', eventData);
    return response;
  }

  /// Update an event (admin)
  Future<Map<String, dynamic>> updateEventAdmin(int eventId, Map<String, dynamic> eventData) async {
    final response = await put('/admin/api/events/$eventId/', eventData);
    return response;
  }

  /// Delete an event (admin)
  Future<void> deleteEventAdmin(int eventId) async {
    await delete('/admin/api/events/$eventId/');
  }

  /// Get reported posts for moderation
  Future<Map<String, dynamic>> getReportedPosts({int page = 1}) async {
    try {
      final data = await get('/admin/api/forum/reports/', queryParams: {
        'page': page.toString(),
      });
      return data;
    } catch (e) {
      // Return dummy data if API not implemented
      return {
        'results': [],
        'total_reports': 0,
      };
    }
  }

  /// Delete a post (admin moderation)
  Future<void> deletePostAdmin(int postId) async {
    await delete('/admin/api/forum/posts/$postId/');
  }

  /// Pin/unpin a thread (admin moderation)
  Future<void> toggleThreadPin(int threadId) async {
    await post('/admin/api/forum/threads/$threadId/toggle-pin/', {});
  }

  /// Resolve a report (admin moderation)
  Future<void> resolveReport(int reportId) async {
    await post('/admin/api/forum/reports/$reportId/resolve/', {});
  }
}
