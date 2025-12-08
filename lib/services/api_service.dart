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

  // Instance CookieRequest disuntikkan dari AuthProvider
  final CookieRequest request;

  ApiService(this.request);

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
    // request.get dari pbp_django_auth otomatis menangani cookies
    final response = await request.get(url);
    return response;
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
    final data = await get('/profile/api/events/', queryParams: query);
    return EventsResponse.fromJson(data);
  }

  Future<Event> getEvent(int id) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEvent(id);
    }
    final data = await get('/profile/api/events/$id/');
    return Event.fromJson(data);
  }

  Future<EventDetail> getEventDetail(int eventId) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEventDetail(eventId);
    }
    final data = await get('/profile/api/events/$eventId/detail/');
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
    final data = await post(
      '/profile/api/profile/update/',
      profileData,
    ); // Sesuaikan endpoint
    return UserProfile.fromJson(data);
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
      '/profile/api/forum/threads/',
      queryParams: {'event': eventId.toString(), 'page': page.toString()},
    );
    return ThreadsResponse.fromJson(data);
  }

  Future<ForumThread> createThread(
    int eventId,
    String title,
    String body,
  ) async {
    final data = await post('/profile/api/forum/threads/', {
      'event': eventId,
      'title': title,
      'body': body,
    });
    return ForumThread.fromJson(data);
  }

  Future<PostsResponse> getPosts(int threadId, {int page = 1}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getPosts(threadId, page: page);
    }
    final data = await get(
      '/profile/api/forum/threads/$threadId/posts/',
      queryParams: {'page': page.toString()},
    );
    return PostsResponse.fromJson(data);
  }

  Future<ForumPost> createPost(
    int threadId,
    String content, {
    int? parentId,
  }) async {
    final data = await post('/profile/api/forum/posts/', {
      'thread': threadId,
      'content': content,
      if (parentId != null) 'parent': parentId,
    });
    return ForumPost.fromJson(data);
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
      '/profile/api/registrations/',
      queryParams: {'page': page.toString()},
    );
    return RegistrationsResponse.fromJson(data);
  }

  Future<EventRegistration> registerForEvent(
    int eventId,
    int categoryId,
    Map<String, dynamic> registrationData,
  ) async {
    final data = await post('/profile/api/registrations/', {
      'event': eventId,
      'category': categoryId,
      ...registrationData,
    });
    return EventRegistration.fromJson(data);
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
    final data = await get('/profile/api/notifications/', queryParams: query);
    return NotificationsResponse.fromJson(data);
  }

  Future<void> markNotificationRead(int id) async {
    await post('/profile/api/notifications/$id/read/', {});
  }

  Future<void> markAllNotificationsRead() async {
    await post('/profile/api/notifications/mark-all-read/', {});
  }
}
