import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';

// CSS Variables from reference
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  UserProfile? _profile;
  List<RunnerAchievement> _achievements = [];
  bool _isLoading = true;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _apiService = ApiService.instance;
    await _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    print('[DEBUG] Loading profile data...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      print('[DEBUG] User not authenticated');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await authProvider.loadProfile();
      _profile = authProvider.userProfile;
      print('[DEBUG] Profile loaded: ${_profile?.username}');
      _achievements = await (DummyDataService.USE_DUMMY_DATA
          ? DummyDataService.getAchievements()
          : _apiService.getAchievements());
      print('[DEBUG] Achievements loaded: ${_achievements.length}');
    } catch (e) {
      print('[DEBUG] Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: primaryColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Profile Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 120,
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: whiteColor.withOpacity(0.2),
                        border: Border.all(color: whiteColor, width: 3),
                      ),
                      child: _profile!.avatarUrl != null
                          ? ClipOval(
                        child: Image.network(
                          _profile!.avatarUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Center(
                        child: Text(
                          _profile!.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: whiteColor,
                          ),
                        ),
                      ),
                    ),

                    // Name
                    Text(
                      _profile!.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: whiteColor,
                      ),
                    ),

                    // Location
                    if (_profile!.city != null || _profile!.country != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_profile!.city ?? ''}${_profile!.city != null && _profile!.country != null ? ', ' : ''}${_profile!.country ?? ''}',
                          style: TextStyle(
                            fontSize: 16,
                            color: whiteColor.withOpacity(0.8),
                          ),
                        ),
                      ),

                    // Bio
                    if (_profile!.bio != null && _profile!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 32, right: 32),
                        child: Text(
                          _profile!.bio!,
                          style: TextStyle(
                            fontSize: 14,
                            color: whiteColor.withOpacity(0.9),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile/edit');
                },
              ),
            ],
          ),

          // Stats Bar
          SliverToBoxAdapter(
            child: Container(
              color: whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Total Events', _profile!.stats['total_events'].toString()),
                  _buildStatItem('Completed', _profile!.stats['completed'].toString()),
                  _buildStatItem('Upcoming', _profile!.stats['upcoming'].toString()),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'History'),
                  Tab(text: 'Achievements'),
                ],
                labelColor: primaryColor,
                unselectedLabelColor: textColor.withOpacity(0.6),
                indicatorColor: primaryColor,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildHistoryTab(),
            _buildAchievementsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textColor.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information
          _buildSectionCard(
            'Basic Information',
            Column(
              children: [
                _buildInfoRow('Username', _profile!.username),
                if (_profile!.favoriteDistance != null)
                  _buildInfoRow('Favorite Distance', _profile!.favoriteDistance!),
                if (_profile!.birthDate != null)
                  _buildInfoRow('Birth Date', '${_profile!.birthDate!.month}/${_profile!.birthDate!.day}/${_profile!.birthDate!.year}'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Emergency Contact
          if (_profile!.emergencyContactName != null || _profile!.emergencyContactPhone != null)
            _buildSectionCard(
              'Emergency Contact',
              Column(
                children: [
                  if (_profile!.emergencyContactName != null)
                    _buildInfoRow('Name', _profile!.emergencyContactName!),
                  if (_profile!.emergencyContactPhone != null)
                    _buildInfoRow('Phone', _profile!.emergencyContactPhone!),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Social Links
          if (_profile!.website != null || _profile!.instagramHandle != null || _profile!.stravaProfile != null)
            _buildSectionCard(
              'Social Links',
              Column(
                children: [
                  if (_profile!.website != null)
                    _buildLinkRow('Website', _profile!.website!),
                  if (_profile!.instagramHandle != null)
                    _buildLinkRow('Instagram', '@${_profile!.instagramHandle}'),
                  if (_profile!.stravaProfile != null)
                    _buildLinkRow('Strava', _profile!.stravaProfile!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final history = _profile!.history;

    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No race history yet', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Start your running journey!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_run,
                color: primaryColor,
              ),
            ),
            title: Text(
              entry.event.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.event.city}, ${entry.event.country}'),
                Text(
                  '${entry.registrationDate.month}/${entry.registrationDate.day}/${entry.registrationDate.year} • ${entry.statusDisplay}',
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                if (entry.category.isNotEmpty)
                  Text(
                    'Category: ${entry.category}',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: entry.status == 'completed'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.schedule, color: Colors.orange),
            onTap: () {
              print('[ACTION] View race history: ${entry.id}');
              // TODO: Navigate to race detail
            },
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    if (_achievements.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No achievements yet', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Keep running to unlock achievements!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    achievement.description ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (achievement.achievedOn != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${achievement.achievedOn!.month}/${achievement.achievedOn!.day}/${achievement.achievedOn!.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
            ),
          ),
          TextButton(
            onPressed: () {
              print('[ACTION] Open link: $value');
              // TODO: Open URL
            },
            child: Text(
              value,
              style: const TextStyle(
                color: primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final PreferredSizeWidget _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: whiteColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
