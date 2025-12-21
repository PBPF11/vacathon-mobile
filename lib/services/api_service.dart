import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/models.dart';
import 'dummy_data_service.dart';

/// API Service for backend integration using pbp_django_auth
class ApiService {
  // Ganti URL ini sesuai device:
  // Android Emulator: 'http://10.0.2.2:8000'
  // iOS Simulator / Web: 'http://localhost:8000'
  // HP Fisik: Pakai IP Laptop (misal 'http://192.168.1.xxx:8000')
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

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
      if (e is FormatException) {
        throw Exception(
          'Server returned non-JSON response from $url. '
          'Check API_BASE_URL or backend auth.',
        );
      }
      rethrow;
    }
  }

  /// Helper untuk POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = '$baseUrl$endpoint';
    print('[API] POST $url');

    // Gunakan postJson untuk mengirim data dalam format JSON
    try {
      final response = await request.postJson(url, jsonEncode(body));
      return response;
    } catch (e) {
      if (e is FormatException) {
        throw Exception(
          'Server returned non-JSON response from $url. '
          'Check API_BASE_URL or backend auth.',
        );
      }
      rethrow;
    }
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
    try {
      final response = await request.postJson(url, jsonEncode(body));
      return response;
    } catch (e) {
      if (e is FormatException) {
        throw Exception(
          'Server returned non-JSON response from $url. '
          'Check API_BASE_URL or backend auth.',
        );
      }
      rethrow;
    }
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
    try {
      final response = await request.postJson(url, jsonEncode({}));
      return response;
    } catch (e) {
      if (e is FormatException) {
        throw Exception(
          'Server returned non-JSON response from $url. '
          'Check API_BASE_URL or backend auth.',
        );
      }
      rethrow;
    }
  }

  Map<String, dynamic> _decodeJsonResponse(
    http.Response response,
    String url,
  ) {
    final body = response.body;
    final trimmed = body.trimLeft();

    if (trimmed.isEmpty) {
      return {
        'status': false,
        'message':
            'Server returned an empty response from $url (status ${response.statusCode}).',
      };
    }

    if (trimmed.startsWith('<')) {
      return {
        'status': false,
        'message':
            'Server returned HTML from $url (status ${response.statusCode}). '
                'Check API_BASE_URL ($baseUrl) or backend routing.',
      };
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'status': false,
        'message':
            'Unexpected JSON response from $url (status ${response.statusCode}).',
      };
    } catch (_) {
      return {
        'status': false,
        'message':
            'Invalid JSON from $url (status ${response.statusCode}). '
                'Check backend logs.',
      };
    }
  }

  String _formatErrors(dynamic errors) {
    if (errors is Map) {
      final parts = <String>[];
      errors.forEach((key, value) {
        if (value is List) {
          parts.add('$key: ${value.join(' ')}');
        } else if (value != null) {
          parts.add('$key: $value');
        }
      });
      if (parts.isNotEmpty) {
        return parts.join(' ');
      }
    }
    return errors?.toString() ?? 'Request failed.';
  }

  Future<Map<String, dynamic>> _sendMultipart(
    String endpoint,
    Map<String, dynamic> fields,
    XFile file, {
    String method = 'POST',
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    await request.init();

    final requestHeaders = <String, String>{};
    final cookieHeader = request.headers['cookie'];
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      requestHeaders['cookie'] = cookieHeader;
    }

    final multipartRequest = http.MultipartRequest(method, url)
      ..headers.addAll(requestHeaders);

    fields.forEach((key, value) {
      if (value == null) return;
      if (value is List || value is Map) {
        multipartRequest.fields[key] = jsonEncode(value);
      } else {
        multipartRequest.fields[key] = value.toString();
      }
    });

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'banner_image',
          bytes,
          filename: file.name,
        ),
      );
    } else {
      multipartRequest.files.add(
        await http.MultipartFile.fromPath(
          'banner_image',
          file.path,
          filename: file.name,
        ),
      );
    }

    final response = await multipartRequest.send();
    final responseBody = await response.stream.bytesToString();
    if (responseBody.trim().isEmpty) {
      throw Exception(
        'Server returned an empty response from $url (status ${response.statusCode}).',
      );
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('errors')) {
          throw Exception(_formatErrors(decoded['errors']));
        }
        return decoded;
      }
      throw Exception(
        'Unexpected JSON response from $url (status ${response.statusCode}).',
      );
    } catch (_) {
      throw Exception(
        'Server returned non-JSON response from $url (status ${response.statusCode}). '
        'Check API_BASE_URL or backend auth.',
      );
    }
  }

  // --- Authentication methods ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      // Dummy login for admin
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
          },
        };
      } else {
        return {'status': false, 'message': 'Invalid credentials'};
      }
    }

    // Gunakan request.login bawaan library untuk login yang support session/cookies
    // URL harus full path
    try {
      final response = await request.login('$baseUrl/profile/auth/login/', {
        'username': username,
        'password': password,
      });
      return response;
    } catch (e) {
      return {
        'status': false,
        'message':
            'Login failed. Server returned a non-JSON response from $baseUrl. '
                'Check API_BASE_URL or backend logs.',
      };
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    final uri = Uri.parse('$baseUrl/profile/auth/register/');
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );
      return _decodeJsonResponse(response, uri.toString());
    } catch (e) {
      return {
        'status': false,
        'message': 'Registration failed: $e',
      };
    }
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

  // --- Admin Events API ---

  Future<EventsResponse> getAdminEvents({
    int page = 1,
    Map<String, String>? filters,
  }) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getAdminEvents(page: page, filters: filters);
    }

    // Admin endpoint for managing events
    final query = {'page': page.toString(), ...?filters};
    try {
      final data = await get('/admin/events/api/', queryParams: query);
      return EventsResponse.fromJson(data);
    } catch (e) {
      // Fallback to dummy data if backend endpoint is unavailable or returns HTML/login page
      print('[API] getAdminEvents fallback to dummy data: $e');
      return DummyDataService.getAdminEvents(page: page, filters: filters);
    }
  }

  Future<List<EventCategory>> getEventCategories() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEventCategories();
    }

    try {
      final data = await get('/admin/events/api/categories/');
      final results = (data['results'] as List? ?? [])
          .map((item) => EventCategory.fromJson(item))
          .toList();
      return results;
    } catch (e) {
      print('[API] getEventCategories fallback to dummy data: $e');
      return DummyDataService.getEventCategories();
    }
  }

  Future<Event> createEventAdmin(Map<String, dynamic> eventData) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.createEvent(eventData);
    }

    final data = await post('/admin/events/api/', eventData);
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      throw Exception(_formatErrors(data['errors']));
    }
    return Event.fromJson(data);
  }

  Future<Event> updateEventAdmin(
    int eventId,
    Map<String, dynamic> eventData,
  ) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.updateEvent(eventId, eventData);
    }

    final data = await put('/admin/events/api/$eventId/', eventData);
    if (data is Map<String, dynamic> && data.containsKey('errors')) {
      throw Exception(_formatErrors(data['errors']));
    }
    return Event.fromJson(data);
  }

  Future<Event> createEventWithImage(
    Map<String, dynamic> eventData,
    XFile image,
  ) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.createEvent(eventData);
    }

    final data = await _sendMultipart(
      '/admin/events/api/',
      eventData,
      image,
    );
    return Event.fromJson(data);
  }

  Future<Event> updateEventWithImage(
    int eventId,
    Map<String, dynamic> eventData,
    XFile image,
  ) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.updateEvent(eventId, eventData);
    }

    final data = await _sendMultipart(
      '/admin/events/api/$eventId/',
      eventData,
      image,
    );
    return Event.fromJson(data);
  }

  Future<Event> createEvent(Map<String, dynamic> eventData) async {
    return createEventAdmin(eventData);
  }

  Future<Event> updateEvent(int eventId, Map<String, dynamic> eventData) async {
    return updateEventAdmin(eventId, eventData);
  }

  Future<void> deleteEvent(int eventId) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.deleteEvent(eventId);
    }

    await post('/admin/events/api/$eventId/delete/', {});
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
      // Return admin profile for dummy data
      return UserProfile(
        id: 1,
        username: 'admin',
        displayName: 'Admin User',
        bio: 'Administrator account',
        city: 'Jakarta',
        country: 'Indonesia',
        avatarUrl: null,
        favoriteDistance: '10K',
        emergencyContactName: 'Support',
        emergencyContactPhone: '+62-812-3456-7890',
        website: null,
        instagramHandle: null,
        stravaProfile: null,
        birthDate: DateTime(1990, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        history: [],
        achievements: [],
        isSuperuser: true,
        isStaff: true,
      );
    }
    // Pastikan URL ini sudah ada di profile/urls.py
    final data = await get('/profile/api/profile/');
    if (data is Map<String, dynamic> && data['status'] == false) {
      throw Exception(data['message'] ?? 'Not authenticated');
    }
    return UserProfile.fromJson(data);
  }

  Future<UserProfile?> tryGetProfile() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return getProfile();
    }
    try {
      final data = await request.get('$baseUrl/profile/api/profile/');
      if (data is Map<String, dynamic>) {
        if (data['status'] == false) {
          return null;
        }
        return UserProfile.fromJson(data);
      }
    } catch (_) {
      // Ignore HTML/redirect responses when not authenticated.
    }
    return null;
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

  Future<ThreadsResponse> getThreads({
    int? eventId,
    String? query,
    String? sort,
    int page = 1,
  }) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getThreads(
        eventId: eventId,
        query: query,
        sort: sort,
        page: page,
      );
    }

    final queryParams = {'page': page.toString()};
    if (eventId != null) {
      queryParams['event'] = eventId.toString();
    }
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    if (sort != null && sort.isNotEmpty) {
      queryParams['sort'] = sort;
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
    // Correct Endpoint: /forum/api/threads/create/
    final response = await post('/forum/api/threads/create/', {
      'event': eventId,
      'title': title,
      'body': body,
    });

    // Backend now returns the full created thread object
    return ForumThread.fromJson(response);
  }

  Future<PostsResponse> getPosts(String threadSlug, {int page = 1}) async {
    // Endpoint: /forum/api/threads/<slug>/posts/
    final data = await get(
      '/forum/api/threads/$threadSlug/posts/',
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
    final body = {'content': content, if (parentId != null) 'parent': parentId};

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

  // --- Admin Registrations API ---

  Future<RegistrationsResponse> getAdminRegistrations({
    int page = 1,
    Map<String, String>? filters,
  }) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getAdminRegistrations(page: page, filters: filters);
    }
    final query = {'page': page.toString(), ...?filters};
    try {
      final data = await get('/admin/participants/api/', queryParams: query);
      return RegistrationsResponse.fromJson(data);
    } catch (e) {
      print('[API] getAdminRegistrations fallback to dummy data: $e');
      return DummyDataService.getAdminRegistrations(page: page, filters: filters);
    }
  }

  Future<EventRegistration> confirmAdminRegistration(String registrationId) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.confirmAdminRegistration(registrationId);
    }
    final data = await post(
      '/admin/participants/api/$registrationId/confirm/',
      {},
    );
    return EventRegistration.fromJson(data);
  }

  Future<void> deleteAdminRegistration(String registrationId) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.deleteAdminRegistration(registrationId);
    }
    await post('/admin/participants/api/$registrationId/delete/', {});
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
    final data = await get(
      '/register/account/registrations/$referenceCode/api/',
    );
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
    // TAMBAHKAN BARIS INI:
    print('--- DATA DARI DJANGO ---');
    print(data);
    print('------------------------');
    return NotificationsResponse.fromJson(data);
  }

  Future<void> markNotificationRead(int id) async {
    await post('/profile/api/notifications/$id/read/', {});
  }

  Future<void> markAllNotificationsRead() async {
    await post('/profile/api/notifications/mark-all-read/', {});
  }
}
