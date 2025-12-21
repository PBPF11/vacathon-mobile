import '../models/models.dart';

/// Centralized dummy data service
/// EASY TO REMOVE: Replace all method calls with real API calls
/// All dummy data is contained here for easy replacement
class DummyDataService {
  // Toggle dummy data globally. Set to false only when backend APIs are ready.
  static const bool USE_DUMMY_DATA = true; // Set to false to use real API

  // Dummy Events Data
  static final List<Event> _dummyEvents = [
    Event(
      id: 1,
      title: 'Jakarta Marathon 2024',
      slug: 'jakarta-marathon-2024',
      description:
          'Experience the vibrant city of Jakarta through this challenging marathon route featuring iconic landmarks and urban landscapes.',
      city: 'Jakarta',
      country: 'Indonesia',
      venue: 'National Monument',
      startDate: DateTime(2025, 11, 15),
      endDate: DateTime(2025, 11, 15),
      registrationOpenDate: DateTime(2025, 9, 1),
      registrationDeadline: DateTime(2026, 11, 1),
      status: 'upcoming',
      popularityScore: 95,
      participantLimit: 5000,
      registeredCount: 3247,
      featured: true,
      bannerImage:
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
      categories: [
        EventCategory(
          id: 1,
          name: 'full_marathon',
          distanceKm: 42.2,
          displayName: '42K Full Marathon',
        ),
        EventCategory(
          id: 2,
          name: 'half_marathon',
          distanceKm: 21.1,
          displayName: '21K Half Marathon',
        ),
        EventCategory(
          id: 3,
          name: '10k_run',
          distanceKm: 10.0,
          displayName: '10K Run',
        ),
        EventCategory(
          id: 4,
          name: '5k_fun_run',
          distanceKm: 5.0,
          displayName: '5K Fun Run',
        ),
      ],
      createdAt: DateTime(2024, 8, 1),
      updatedAt: DateTime(2024, 10, 15),
    ),
    Event(
      id: 2,
      title: 'Bali International Marathon',
      slug: 'bali-marathon-2024',
      description:
          'Run through the paradise island of Bali with stunning beach views and tropical landscapes.',
      city: 'Bali',
      country: 'Indonesia',
      venue: 'Sanur Beach',
      startDate: DateTime(2025, 12, 8),
      endDate: DateTime(2025, 12, 8),
      registrationOpenDate: DateTime(2025, 9, 15),
      registrationDeadline: DateTime(2026, 11, 15),
      status: 'upcoming',
      popularityScore: 88,
      participantLimit: 3000,
      registeredCount: 2156,
      featured: true,
      bannerImage:
          'https://images.unsplash.com/photo-1537953773345-d172ccf13cf1?w=800',
      categories: [
        EventCategory(
          id: 1,
          name: 'full_marathon',
          distanceKm: 42.2,
          displayName: '42K Full Marathon',
        ),
        EventCategory(
          id: 2,
          name: 'half_marathon',
          distanceKm: 21.1,
          displayName: '21K Half Marathon',
        ),
        EventCategory(
          id: 3,
          name: '10k_run',
          distanceKm: 10.0,
          displayName: '10K Run',
        ),
      ],
      createdAt: DateTime(2024, 8, 15),
      updatedAt: DateTime(2024, 10, 20),
    ),
    Event(
      id: 3,
      title: 'Bandung Mountain Trail Run',
      slug: 'bandung-trail-2024',
      description:
          'Challenge yourself with this scenic trail run through the mountains of Bandung.',
      city: 'Bandung',
      country: 'Indonesia',
      venue: 'Dago Pakar',
      startDate: DateTime(2025, 10, 20),
      endDate: DateTime(2025, 10, 20),
      registrationOpenDate: DateTime(2025, 8, 1),
      registrationDeadline: DateTime(2026, 10, 5),
      status: 'ongoing',
      popularityScore: 76,
      participantLimit: 800,
      registeredCount: 623,
      featured: false,
      bannerImage:
          'https://images.unsplash.com/photo-1551632811-561732d1e306?w=800',
      categories: [
        EventCategory(
          id: 2,
          name: 'half_marathon',
          distanceKm: 21.1,
          displayName: '21K Trail Run',
        ),
        EventCategory(
          id: 3,
          name: '10k_run',
          distanceKm: 10.0,
          displayName: '10K Trail Run',
        ),
        EventCategory(
          id: 4,
          name: '5k_fun_run',
          distanceKm: 5.0,
          displayName: '5K Fun Run',
        ),
      ],
      createdAt: DateTime(2024, 7, 1),
      updatedAt: DateTime(2024, 10, 10),
    ),
    Event(
      id: 4,
      title: 'Surabaya Night Run 2023',
      slug: 'surabaya-night-run-2023',
      description:
          'Experience the magic of Surabaya at night with this illuminated city marathon.',
      city: 'Surabaya',
      country: 'Indonesia',
      venue: 'Tugu Pahlawan',
      startDate: DateTime(2023, 12, 15),
      endDate: DateTime(2023, 12, 15),
      registrationOpenDate: DateTime(2023, 10, 1),
      registrationDeadline: DateTime(2023, 11, 30),
      status: 'completed',
      popularityScore: 82,
      participantLimit: 2000,
      registeredCount: 1876,
      featured: false,
      bannerImage:
          'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800',
      categories: [
        EventCategory(
          id: 3,
          name: '10k_run',
          distanceKm: 10.0,
          displayName: '10K Night Run',
        ),
        EventCategory(
          id: 4,
          name: '5k_fun_run',
          distanceKm: 5.0,
          displayName: '5K Fun Run',
        ),
      ],
      createdAt: DateTime(2023, 9, 1),
      updatedAt: DateTime(2023, 12, 16),
    ),
  ];

  // Dummy User Profile
  static final UserProfile _dummyUserProfile = UserProfile(
    id: 1,
    username: 'testuser',
    displayName: 'Test Runner',
    bio:
        'Passionate runner who loves exploring new routes and challenging myself. Marathon enthusiast with a love for adventure!',
    city: 'Jakarta',
    country: 'Indonesia',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    favoriteDistance: '21K',
    emergencyContactName: 'John Doe',
    emergencyContactPhone: '+62-812-3456-7890',
    website: 'https://testrunner.com',
    instagramHandle: '@testrunner',
    stravaProfile: 'https://strava.com/athletes/testrunner',
    birthDate: DateTime(1990, 5, 15),
    createdAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2024, 10, 1),
    history: [
      UserRaceHistory(
        id: 1,
        event: _dummyEvents[3], // Surabaya Night Run
        category: '10K Night Run',
        registrationDate: DateTime(2023, 11, 15),
        status: 'completed',
        bibNumber: 'BIB-1876',
        finishTime: const Duration(hours: 1, minutes: 2, seconds: 30),
        medalAwarded: true,
        certificateUrl: 'https://example.com/certificates/1876',
        notes: 'Great night run experience!',
        updatedAt: DateTime(2023, 12, 16),
      ),
      UserRaceHistory(
        id: 2,
        event: _dummyEvents[0], // Jakarta Marathon
        category: '21K Half Marathon',
        registrationDate: DateTime(2024, 10, 1),
        status: 'upcoming',
        bibNumber: null,
        finishTime: null,
        medalAwarded: false,
        certificateUrl: null,
        notes: null,
        updatedAt: DateTime(2024, 10, 15),
      ),
    ],
    achievements: [
      RunnerAchievement(
        id: 1,
        title: 'First Marathon Finisher',
        description: 'Completed my first full marathon in under 4 hours',
        achievedOn: DateTime(2023, 6, 15),
        link: 'https://strava.com/activities/123456789',
      ),
      RunnerAchievement(
        id: 2,
        title: 'Trail Running Champion',
        description: 'Won the Bandung Trail Run 2023 in the 21K category',
        achievedOn: DateTime(2023, 10, 20),
        link: null,
      ),
      RunnerAchievement(
        id: 3,
        title: 'Century Club Member',
        description: 'Completed 100+ running events',
        achievedOn: DateTime(2024, 8, 1),
        link: 'https://example.com/achievements/century-club',
      ),
    ],
  );

  // Dummy Forum Data
  static final List<ForumThread> _dummyThreads = [
    ForumThread(
      id: 1,
      eventId: 1,
      eventTitle: 'Jakarta Marathon 2024',
      authorId: '1',
      authorUsername: 'testuser',
      title: 'Training tips for Jakarta Marathon',
      slug: 'training-tips-jakarta-marathon',
      body:
          'Hi everyone! I\'m preparing for the Jakarta Marathon and would love to hear your training tips. What\'s your weekly mileage? Any specific workouts you recommend?',
      createdAt: DateTime(2024, 10, 1),
      updatedAt: DateTime(2024, 10, 5),
      lastActivityAt: DateTime(2024, 10, 5),
      isPinned: true,
      isLocked: false,
      viewCount: 45,
      postCount: 12,
    ),
    ForumThread(
      id: 2,
      eventId: 1, // Also Jakarta Marathon
      eventTitle: 'Jakarta Marathon 2024',
      authorId: '2',
      authorUsername: 'runningfan',
      title: 'Accommodation recommendations near start line',
      slug: 'accommodation-jakarta-marathon',
      body:
          'Looking for good hotels or Airbnbs near the National Monument. Any recommendations for budget-friendly options?',
      createdAt: DateTime(2024, 10, 3),
      updatedAt: DateTime(2024, 10, 4),
      lastActivityAt: DateTime(2024, 10, 4),
      isPinned: false,
      isLocked: false,
      viewCount: 23,
      postCount: 5,
    ),
  ];

  static final List<ForumPost> _dummyPosts = [
    ForumPost(
      id: 1,
      threadId: 1,
      authorId: '2',
      authorUsername: 'runningfan',
      parentId: null,
      content:
          'I recommend starting with a base of 20-30km per week and gradually increasing. Hill training is crucial for Jakarta\'s terrain!',
      createdAt: DateTime(2024, 10, 1, 14, 30),
      updatedAt: DateTime(2024, 10, 1, 14, 30),
      likesCount: 12,
      isLikedByUser: false,
    ),
    ForumPost(
      id: 2,
      threadId: 1,
      authorId: '3',
      authorUsername: 'marathoner',
      parentId: 1,
      content:
          'Agreed! Also don\'t forget about speed work. Intervals on Wednesdays really helped me.',
      createdAt: DateTime(2024, 10, 2, 9, 15),
      updatedAt: DateTime(2024, 10, 2, 9, 15),
      likesCount: 8,
      isLikedByUser: true,
    ),
  ];

  // Dummy Registrations
  static final List<EventRegistration> _dummyRegistrations = [
    EventRegistration(
      id: 'reg-001',
      referenceCode: 'VAC-ABC123DEF',
      userId: 1,
      userUsername: 'testuser',
      event: _dummyEvents[0],
      categoryId: 2,
      categoryDisplayName: '21K Half Marathon',
      distanceLabel: '21K Half Marathon',
      phoneNumber: '+62-812-3456-7890',
      emergencyContactName: 'Jane Doe',
      emergencyContactPhone: '+62-811-9876-5432',
      medicalNotes: 'No known allergies',
      status: 'confirmed',
      paymentStatus: 'paid',
      formPayload: {},
      decisionNote: null,
      createdAt: DateTime(2024, 10, 1),
      updatedAt: DateTime(2024, 10, 5),
      confirmedAt: DateTime(2024, 10, 5),
      cancelledAt: null,
    ),
  ];

  // Dummy Notifications
  static final List<Notification> _dummyNotifications = [
    Notification(
      id: 1,
      recipientId: 1,
      title: 'Registration Confirmed',
      message:
          'Your registration for Jakarta Marathon 2024 has been confirmed. Your BIB number is BIB-3247.',
      category: 'registration',
      linkUrl: '/registrations/VAC-ABC123DEF',
      isRead: false,
      createdAt: DateTime(2024, 10, 5),
      readAt: null,
    ),
    Notification(
      id: 2,
      recipientId: 1,
      title: 'Event Reminder',
      message:
          'Jakarta Marathon 2024 is coming up in 10 days! Don\'t forget to pick up your race kit.',
      category: 'event',
      linkUrl: '/events/jakarta-marathon-2024',
      isRead: true,
      createdAt: DateTime(2024, 11, 5),
      readAt: DateTime(2024, 11, 6),
    ),
  ];

  // API Methods - Replace these with real API calls when USE_DUMMY_DATA = false

  static Future<EventsResponse> getEvents({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (!USE_DUMMY_DATA) {
      // TODO: Replace with real API call
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getEvents called with page: $page, filters: $filters');

    // Apply filters
    List<Event> filteredEvents = List.from(_dummyEvents);

    if (filters != null) {
      if (filters['status'] != null) {
        filteredEvents = filteredEvents
            .where((e) => e.status == filters['status'])
            .toList();
      }
      if (filters['city'] != null) {
        filteredEvents = filteredEvents
            .where(
              (e) =>
                  e.city.toLowerCase().contains(filters['city']!.toLowerCase()),
            )
            .toList();
      }
      if (filters['distance'] != null) {
        final distance = double.tryParse(filters['distance']!);
        if (distance != null) {
          filteredEvents = filteredEvents
              .where(
                (e) => e.categories.any((cat) => cat.distanceKm == distance),
              )
              .toList();
        }
      }
      if (filters['search'] != null) {
        final query = filters['search']!.toLowerCase();
        filteredEvents = filteredEvents
            .where(
              (e) =>
                  e.title.toLowerCase().contains(query) ||
                  e.description.toLowerCase().contains(query) ||
                  e.city.toLowerCase().contains(query),
            )
            .toList();
      }
    }

    // Sort by date
    filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Pagination
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedEvents = filteredEvents.sublist(
      startIndex,
      endIndex > filteredEvents.length ? filteredEvents.length : endIndex,
    );

    return EventsResponse(
      events: paginatedEvents,
      pagination: EventPagination(
        page: page,
        pages: (filteredEvents.length / pageSize).ceil(),
        hasNext: endIndex < filteredEvents.length,
        hasPrevious: page > 1,
        total: filteredEvents.length,
      ),
    );
  }

  static Future<Event> getEvent(int id) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getEvent called with id: $id');
    return _dummyEvents.firstWhere((e) => e.id == id);
  }

  static Future<EventDetail> getEventDetail(int eventId) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getEventDetail called with eventId: $eventId');

    // Dummy event detail data
    return EventDetail(
      schedules: [
        EventSchedule(
          id: 1,
          eventId: eventId,
          title: 'Race Start',
          startTime: DateTime(2025, 11, 15, 6, 0),
          endTime: null,
          description: 'Flag off for all categories',
        ),
        EventSchedule(
          id: 2,
          eventId: eventId,
          title: 'Water Station 1',
          startTime: DateTime(2025, 11, 15, 6, 30),
          endTime: DateTime(2025, 11, 15, 7, 30),
          description: 'Km 5 - Water and energy gels available',
        ),
      ],
      aidStations: [
        AidStation(
          id: 1,
          eventId: eventId,
          name: 'Medical Station A',
          kilometerMarker: 10.0,
          supplies: 'Water, Energy Gels, Medical Support',
          isMedical: true,
        ),
        AidStation(
          id: 2,
          eventId: eventId,
          name: 'Water Station B',
          kilometerMarker: 15.0,
          supplies: 'Water, Bananas, Energy Bars',
          isMedical: false,
        ),
      ],
      routeSegments: [
        RouteSegment(
          id: 1,
          eventId: eventId,
          order: 1,
          title: 'City Center Loop',
          description:
              'Starting from National Monument, running through the main city center with moderate traffic.',
          distanceKm: 10.0,
          elevationGain: 50,
        ),
        RouteSegment(
          id: 2,
          eventId: eventId,
          order: 2,
          title: 'Riverside Path',
          description:
              'Scenic run along the river with beautiful views and shade from trees.',
          distanceKm: 15.0,
          elevationGain: 25,
        ),
      ],
      documents: [
        EventDocument(
          id: 1,
          eventId: eventId,
          title: 'Race Route GPX',
          documentUrl: 'https://example.com/route.gpx',
          documentType: 'gpx',
          uploadedBy: 'Race Organizer',
          uploadedAt: DateTime(2024, 9, 1),
        ),
        EventDocument(
          id: 2,
          eventId: eventId,
          title: 'Race Guide PDF',
          documentUrl: 'https://example.com/guide.pdf',
          documentType: 'guide',
          uploadedBy: 'Race Organizer',
          uploadedAt: DateTime(2024, 9, 1),
        ),
      ],
    );
  }

  static Future<UserProfile> getProfile() async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getProfile called');
    return _dummyUserProfile;
  }

  static Future<List<RunnerAchievement>> getAchievements() async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getAchievements called');
    return _dummyUserProfile.achievements;
  }

  static Future<ThreadsResponse> getThreads({
    int? eventId,
    String? query,
    String? sort,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print(
      '[DUMMY] getThreads called with eventId: $eventId, query: $query, sort: $sort, page: $page',
    );

    var filteredThreads = eventId != null
        ? _dummyThreads.where((t) => t.eventId == eventId).toList()
        : List<ForumThread>.from(_dummyThreads);

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filteredThreads = filteredThreads
          .where(
            (t) =>
                t.title.toLowerCase().contains(lowerQuery) ||
                t.body.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }

    // Sort logic (Matching backend: recent, latest, popular)
    if (sort == 'popular') {
      // Backend 'popular' is by Post Count (replies)
      filteredThreads.sort((a, b) => b.postCount.compareTo(a.postCount));
    } else if (sort == 'latest') {
      // Backend 'latest' is by Creation Time
      filteredThreads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (sort == 'oldest') {
      filteredThreads.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      // Default 'recent' is by Last Activity
      filteredThreads
          .sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    }

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedThreads = filteredThreads.sublist(
      startIndex,
      endIndex > filteredThreads.length ? filteredThreads.length : endIndex,
    );

    return ThreadsResponse(
      threads: paginatedThreads,
      total: filteredThreads.length,
      hasNext: endIndex < filteredThreads.length,
    );
  }

  static Future<PostsResponse> getPosts(
    String threadSlug, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getPosts called with threadSlug: $threadSlug, page: $page');

    // Find thread ID from slug
    final thread = _dummyThreads.firstWhere(
      (t) => t.slug == threadSlug,
      orElse: () => _dummyThreads[0],
    );

    final threadPosts = _dummyPosts
        .where((p) => p.threadId == thread.id)
        .toList();
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedPosts = threadPosts.sublist(
      startIndex,
      endIndex > threadPosts.length ? threadPosts.length : endIndex,
    );

    return PostsResponse(
      posts: paginatedPosts,
      total: threadPosts.length,
      hasNext: endIndex < threadPosts.length,
    );
  }

  static Future<ForumPost> addPost(
    String threadSlug,
    String content, {
    int? parentId,
    String authorUsername = 'you',
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    final thread = _dummyThreads.firstWhere(
      (t) => t.slug == threadSlug,
      orElse: () => _dummyThreads.first,
    );
    final newId =
        _dummyPosts.isNotEmpty ? _dummyPosts.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1 : 1;
    final now = DateTime.now();
    final post = ForumPost(
      id: newId,
      threadId: thread.id,
      authorId: 'dummy',
      authorUsername: authorUsername,
      parentId: parentId,
      content: content,
      createdAt: now,
      updatedAt: now,
      likesCount: 0,
      isLikedByUser: false,
    );
    _dummyPosts.add(post);

    // Update thread metadata
    final tIndex = _dummyThreads.indexWhere((t) => t.id == thread.id);
    if (tIndex != -1) {
      final updated = ForumThread(
        id: thread.id,
        eventId: thread.eventId,
        eventTitle: thread.eventTitle,
        authorId: thread.authorId,
        authorUsername: thread.authorUsername,
        title: thread.title,
        slug: thread.slug,
        body: thread.body,
        createdAt: thread.createdAt,
        updatedAt: now,
        lastActivityAt: now,
        isPinned: thread.isPinned,
        isLocked: thread.isLocked,
        viewCount: thread.viewCount,
        postCount: thread.postCount + 1,
      );
      _dummyThreads[tIndex] = updated;
    }

    return post;
  }

  static Future<ForumThread> createThread(
    int eventId,
    String title,
    String body, {
    String authorUsername = 'you',
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    final event = _dummyEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => _dummyEvents.first,
    );
    final newId =
        _dummyThreads.isNotEmpty ? _dummyThreads.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1 : 1;
    final slugBase = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'-+'), '-').trim();
    final slug = slugBase.endsWith('-') ? slugBase.substring(0, slugBase.length - 1) : slugBase;
    final now = DateTime.now();
    final thread = ForumThread(
      id: newId,
      eventId: event.id,
      eventTitle: event.title,
      authorId: 'dummy',
      authorUsername: authorUsername,
      title: title,
      slug: slug.isEmpty ? 'thread-$newId' : slug,
      body: body,
      createdAt: now,
      updatedAt: now,
      lastActivityAt: now,
      isPinned: false,
      isLocked: false,
      viewCount: 1,
      postCount: 0,
    );
    _dummyThreads.insert(0, thread);
    return thread;
  }

  static Future<RegistrationsResponse> getMyRegistrations({
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getMyRegistrations called with page: $page');

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedRegistrations = _dummyRegistrations.sublist(
      startIndex,
      endIndex > _dummyRegistrations.length
          ? _dummyRegistrations.length
          : endIndex,
    );

    return RegistrationsResponse(
      registrations: paginatedRegistrations,
      total: _dummyRegistrations.length,
      hasNext: endIndex < _dummyRegistrations.length,
    );
  }

  static Future<NotificationsResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print(
      '[DUMMY] getNotifications called with page: $page, unreadOnly: $unreadOnly',
    );

    List<Notification> filteredNotifications = List.from(_dummyNotifications);
    if (unreadOnly) {
      filteredNotifications = filteredNotifications
          .where((n) => !n.isRead)
          .toList();
    }

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedNotifications = filteredNotifications.sublist(
      startIndex,
      endIndex > filteredNotifications.length
          ? filteredNotifications.length
          : endIndex,
    );

    return NotificationsResponse(
      notifications: paginatedNotifications,
      total: filteredNotifications.length,
      hasNext: endIndex < filteredNotifications.length,
      unreadCount: _dummyNotifications.where((n) => !n.isRead).length,
    );
  }

  // Helper method to get all events (for filtering)
  static List<Event> getAllEvents() {
    return _dummyEvents;
  }

  // Helper method to get unique cities
  static List<String> getUniqueCities() {
    return _dummyEvents.map((e) => e.city).toSet().toList();
  }

  // Helper method to get unique distances
  static List<double> getUniqueDistances() {
    Set<double> distances = {};
    for (var event in _dummyEvents) {
      for (var category in event.categories) {
        distances.add(category.distanceKm);
      }
    }
    return distances.toList()..sort();
  }

  // Admin Events Methods
  static Future<List<EventCategory>> getEventCategories() async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    final categoryMap = <int, EventCategory>{};
    for (final event in _dummyEvents) {
      for (final category in event.categories) {
        categoryMap[category.id] = category;
      }
    }

    final categories = categoryMap.values.toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return categories;
  }

  static Future<EventsResponse> getAdminEvents({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] getAdminEvents called with page: $page, filters: $filters');

    // For admin, return all events without user-specific filtering
    List<Event> filteredEvents = List.from(_dummyEvents);

    if (filters != null) {
      if (filters['status'] != null) {
        filteredEvents = filteredEvents
            .where((e) => e.status == filters['status'])
            .toList();
      }
      if (filters['city'] != null) {
        filteredEvents = filteredEvents
            .where(
              (e) =>
                  e.city.toLowerCase().contains(filters['city']!.toLowerCase()),
            )
            .toList();
      }
      if (filters['search'] != null) {
        final query = filters['search']!.toLowerCase();
        filteredEvents = filteredEvents
            .where(
              (e) =>
                  e.title.toLowerCase().contains(query) ||
                  e.description.toLowerCase().contains(query) ||
                  e.city.toLowerCase().contains(query),
            )
            .toList();
      }
    }

    // Sort by date
    filteredEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Pagination
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedEvents = filteredEvents.sublist(
      startIndex,
      endIndex > filteredEvents.length ? filteredEvents.length : endIndex,
    );

    return EventsResponse(
      events: paginatedEvents,
      pagination: EventPagination(
        page: page,
        pages: (filteredEvents.length / pageSize).ceil(),
        hasNext: endIndex < filteredEvents.length,
        hasPrevious: page > 1,
        total: filteredEvents.length,
      ),
    );
  }

  static Future<Event> createEvent(Map<String, dynamic> eventData) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] createEvent called with data: $eventData');

    // Generate new ID
    final newId = _dummyEvents.isNotEmpty ? _dummyEvents.last.id + 1 : 1;

    // Create new event
    final newEvent = Event(
      id: newId,
      title: eventData['title'] ?? 'New Event',
      slug: eventData['slug'] ?? 'new-event-${newId}',
      description: eventData['description'] ?? '',
      city: eventData['city'] ?? '',
      country: eventData['country'] ?? 'Indonesia',
      venue: eventData['venue'] ?? '',
      startDate: DateTime.parse(
        eventData['start_date'] ?? DateTime.now().toIso8601String(),
      ),
      endDate: DateTime.parse(
        eventData['end_date'] ?? DateTime.now().toIso8601String(),
      ),
      registrationOpenDate: DateTime.parse(
        eventData['registration_open_date'] ?? DateTime.now().toIso8601String(),
      ),
      registrationDeadline: DateTime.parse(
        eventData['registration_deadline'] ?? DateTime.now().toIso8601String(),
      ),
      status: eventData['status'] ?? 'upcoming',
      popularityScore: eventData['popularity_score'] ?? 0,
      participantLimit: eventData['participant_limit'] ?? 1000,
      registeredCount: 0,
      featured: eventData['featured'] ?? false,
      bannerImage: eventData['banner_image'],
      categories: [], // TODO: Handle categories
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _dummyEvents.add(newEvent);
    return newEvent;
  }

  static Future<Event> updateEvent(
    int eventId,
    Map<String, dynamic> eventData,
  ) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] updateEvent called with id: $eventId, data: $eventData');

    final index = _dummyEvents.indexWhere((e) => e.id == eventId);
    if (index == -1) {
      throw Exception('Event not found');
    }

    final existingEvent = _dummyEvents[index];
    final updatedEvent = Event(
      id: existingEvent.id,
      title: eventData['title'] ?? existingEvent.title,
      slug: eventData['slug'] ?? existingEvent.slug,
      description: eventData['description'] ?? existingEvent.description,
      city: eventData['city'] ?? existingEvent.city,
      country: eventData['country'] ?? existingEvent.country,
      venue: eventData['venue'] ?? existingEvent.venue,
      startDate: eventData['start_date'] != null
          ? DateTime.parse(eventData['start_date'])
          : existingEvent.startDate,
      endDate: eventData['end_date'] != null
          ? DateTime.parse(eventData['end_date'])
          : existingEvent.endDate,
      registrationOpenDate: eventData['registration_open_date'] != null
          ? DateTime.parse(eventData['registration_open_date'])
          : existingEvent.registrationOpenDate,
      registrationDeadline: eventData['registration_deadline'] != null
          ? DateTime.parse(eventData['registration_deadline'])
          : existingEvent.registrationDeadline,
      status: eventData['status'] ?? existingEvent.status,
      popularityScore:
          eventData['popularity_score'] ?? existingEvent.popularityScore,
      participantLimit:
          eventData['participant_limit'] ?? existingEvent.participantLimit,
      registeredCount: existingEvent.registeredCount,
      featured: eventData['featured'] ?? existingEvent.featured,
      bannerImage: eventData['banner_image'] ?? existingEvent.bannerImage,
      categories: existingEvent.categories, // TODO: Handle categories update
      createdAt: existingEvent.createdAt,
      updatedAt: DateTime.now(),
    );

    _dummyEvents[index] = updatedEvent;
    return updatedEvent;
  }

  static Future<void> deleteEvent(int eventId) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print('[DUMMY] deleteEvent called with id: $eventId');

    _dummyEvents.removeWhere((e) => e.id == eventId);
  }

  static Future<RegistrationsResponse> getAdminRegistrations({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    var filtered = List<EventRegistration>.from(_dummyRegistrations);
    if (filters != null) {
      final status = filters['status'];
      if (status != null && status.isNotEmpty) {
        filtered = filtered.where((r) => r.status == status).toList();
      }
      final eventFilter = filters['event'];
      if (eventFilter != null && eventFilter.isNotEmpty) {
        filtered = filtered
            .where((r) => r.event.id.toString() == eventFilter)
            .toList();
      }
      final search = filters['q'] ?? filters['search'];
      if (search != null && search.isNotEmpty) {
        final query = search.toLowerCase();
        filtered = filtered
            .where(
              (r) =>
                  r.userUsername.toLowerCase().contains(query) ||
                  r.event.title.toLowerCase().contains(query),
            )
            .toList();
      }
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginated = filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );

    return RegistrationsResponse(
      registrations: paginated,
      total: filtered.length,
      hasNext: endIndex < filtered.length,
    );
  }

  static Future<EventRegistration> confirmAdminRegistration(
    String registrationId,
  ) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    final index =
        _dummyRegistrations.indexWhere((r) => r.id == registrationId);
    if (index == -1) {
      throw Exception('Registration not found');
    }

    final existing = _dummyRegistrations[index];
    final updated = EventRegistration(
      id: existing.id,
      referenceCode: existing.referenceCode,
      userId: existing.userId,
      userUsername: existing.userUsername,
      event: existing.event,
      categoryId: existing.categoryId,
      categoryDisplayName: existing.categoryDisplayName,
      distanceLabel: existing.distanceLabel,
      phoneNumber: existing.phoneNumber,
      emergencyContactName: existing.emergencyContactName,
      emergencyContactPhone: existing.emergencyContactPhone,
      medicalNotes: existing.medicalNotes,
      status: 'confirmed',
      paymentStatus: existing.paymentStatus,
      formPayload: existing.formPayload,
      decisionNote: existing.decisionNote,
      bibNumber: existing.bibNumber,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      confirmedAt: DateTime.now(),
      cancelledAt: existing.cancelledAt,
    );

    _dummyRegistrations[index] = updated;
    return updated;
  }

  static Future<void> deleteAdminRegistration(String registrationId) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    _dummyRegistrations.removeWhere((r) => r.id == registrationId);
  }

  // Registration functionality
  static Future<EventRegistration> registerForEvent(
    int eventId,
    Map<String, dynamic> registrationData,
  ) async {
    if (!USE_DUMMY_DATA) {
      throw UnimplementedError('Real API not implemented');
    }

    print(
      '[DUMMY] registerForEvent called with eventId: $eventId, data: $registrationData',
    );

    // Find the event
    final event = _dummyEvents.firstWhere((e) => e.id == eventId);

    // Create a new registration
    final registration = EventRegistration(
      id: 'VAC-${DateTime.now().millisecondsSinceEpoch}',
      referenceCode: 'VAC-${DateTime.now().millisecondsSinceEpoch}',
      userId: 1, // Assuming current user ID
      userUsername: 'testuser',
      event: event,
      categoryId: registrationData['category'] != null
          ? int.parse(registrationData['category'])
          : null,
      categoryDisplayName: registrationData['category'] != null
          ? event.categories
                .firstWhere(
                  (c) => c.id == int.parse(registrationData['category']),
                )
                .displayName
          : null,
      distanceLabel: registrationData['distance_label'] ?? '',
      phoneNumber: registrationData['phone_number'],
      emergencyContactName: registrationData['emergency_contact_name'],
      emergencyContactPhone: registrationData['emergency_contact_phone'],
      medicalNotes: registrationData['medical_notes'],
      status: 'pending',
      paymentStatus: 'unpaid',
      formPayload: registrationData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add to dummy registrations
    _dummyRegistrations.add(registration);

    // Update event registered count
    final eventIndex = _dummyEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex != -1) {
      _dummyEvents[eventIndex] = Event(
        id: event.id,
        title: event.title,
        slug: event.slug,
        description: event.description,
        city: event.city,
        country: event.country,
        venue: event.venue,
        startDate: event.startDate,
        endDate: event.endDate,
        registrationOpenDate: event.registrationOpenDate,
        registrationDeadline: event.registrationDeadline,
        status: event.status,
        popularityScore: event.popularityScore,
        participantLimit: event.participantLimit,
        registeredCount: event.registeredCount + 1,
        featured: event.featured,
        bannerImage: event.bannerImage,
        categories: event.categories,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
      );
    }

    return registration;
  }
}
