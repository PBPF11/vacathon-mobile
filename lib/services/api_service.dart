import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'dummy_data_service.dart';

/// API Service for backend integration
class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Change this to your backend URL
  static const String apiPrefix = '/api';

  // Auth token
  String? _token;
  final SharedPreferences _prefs;

  ApiService(this._prefs) {
    _token = _prefs.getString('auth_token');
  }

  /// Set auth token
  void setToken(String token) {
    _token = token;
    _prefs.setString('auth_token', token);
  }

  /// Clear auth token
  void clearToken() {
    _token = null;
    _prefs.remove('auth_token');
  }

  /// Get headers with auth
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  /// Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// GET request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$apiPrefix$endpoint').replace(queryParameters: queryParams);
    print('[API] GET $uri');
    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  /// POST request
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$apiPrefix$endpoint');
    print('[API] POST $uri with body: $body');
    final response = await http.post(
      uri,
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT request
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$apiPrefix$endpoint');
    print('[API] PUT $uri with body: $body');
    final response = await http.put(
      uri,
      headers: _headers,
      body: body != null ? json.encode(body) : null,
    );
    return _handleResponse(response);
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$apiPrefix$endpoint');
    print('[API] DELETE $uri');
    final response = await http.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('/auth/login/', body: {
      'username': username,
      'password': password,
    });
    if (response['token'] != null) {
      setToken(response['token']);
    }
    return response;
  }

  Future<void> logout() async {
    await post('/auth/logout/');
    clearToken();
  }

  // Events API
  Future<EventsResponse> getEvents({int page = 1, Map<String, String>? filters}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEvents(page: page, filters: filters);
    }
    final query = {'page': page.toString(), ...?filters};
    final data = await get('/events/', queryParams: query);
    return EventsResponse.fromJson(data);
  }

  Future<Event> getEvent(int id) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEvent(id);
    }
    final data = await get('/events/$id/');
    return Event.fromJson(data);
  }

  Future<EventDetail> getEventDetail(int eventId) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getEventDetail(eventId);
    }
    final data = await get('/events/$eventId/detail/');
    return EventDetail.fromJson(data);
  }

  // Profile API
  Future<UserProfile> getProfile() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getProfile();
    }
    final data = await get('/profile/');
    return UserProfile.fromJson(data);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> profileData) async {
    final data = await put('/profile/', body: profileData);
    return UserProfile.fromJson(data);
  }

  Future<List<RunnerAchievement>> getAchievements() async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getAchievements();
    }
    final data = await get('/profile/achievements/');
    return (data['results'] as List).map((item) => RunnerAchievement.fromJson(item)).toList();
  }

  Future<RunnerAchievement> addAchievement(Map<String, dynamic> achievementData) async {
    final data = await post('/profile/achievements/', body: achievementData);
    return RunnerAchievement.fromJson(data);
  }

  Future<void> deleteAchievement(int id) async {
    await delete('/profile/achievements/$id/');
  }

  // Forum API
  Future<ThreadsResponse> getThreads(int eventId, {int page = 1}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getThreads(eventId, page: page);
    }
    final data = await get('/forum/threads/', queryParams: {
      'event': eventId.toString(),
      'page': page.toString(),
    });
    return ThreadsResponse.fromJson(data);
  }

  Future<ForumThread> createThread(int eventId, String title, String body) async {
    final data = await post('/forum/threads/', body: {
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
    final data = await get('/forum/threads/$threadId/posts/', queryParams: {
      'page': page.toString(),
    });
    return PostsResponse.fromJson(data);
  }

  Future<ForumPost> createPost(int threadId, String content, {int? parentId}) async {
    final data = await post('/forum/posts/', body: {
      'thread': threadId,
      'content': content,
      if (parentId != null) 'parent': parentId,
    });
    return ForumPost.fromJson(data);
  }

  Future<void> likePost(int postId) async {
    await post('/forum/posts/$postId/like/');
  }

  // Registrations API
  Future<RegistrationsResponse> getMyRegistrations({int page = 1}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getMyRegistrations(page: page);
    }
    final data = await get('/registrations/', queryParams: {'page': page.toString()});
    return RegistrationsResponse.fromJson(data);
  }

  Future<EventRegistration> registerForEvent(int eventId, int categoryId, Map<String, dynamic> registrationData) async {
    final data = await post('/registrations/', body: {
      'event': eventId,
      'category': categoryId,
      ...registrationData,
    });
    return EventRegistration.fromJson(data);
  }

  Future<EventRegistration> getRegistration(String referenceCode) async {
    final data = await get('/registrations/$referenceCode/');
    return EventRegistration.fromJson(data);
  }

  // Notifications API
  Future<NotificationsResponse> getNotifications({int page = 1, bool unreadOnly = false}) async {
    if (DummyDataService.USE_DUMMY_DATA) {
      return DummyDataService.getNotifications(page: page, unreadOnly: unreadOnly);
    }
    final query = {'page': page.toString()};
    if (unreadOnly) query['unread'] = 'true';
    final data = await get('/notifications/', queryParams: query);
    return NotificationsResponse.fromJson(data);
  }

  Future<void> markNotificationRead(int id) async {
    await post('/notifications/$id/read/');
  }

  Future<void> markAllNotificationsRead() async {
    await post('/notifications/mark-all-read/');
  }
}

/// API Exception
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException: $statusCode - $message';
}