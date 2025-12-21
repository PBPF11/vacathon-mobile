import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/dummy_data_service.dart';
import 'profile_screen.dart';
import 'account_settings_screen.dart';

const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with TickerProviderStateMixin {
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    await authProvider.loadProfile();
    _profile = authProvider.userProfile;

    _achievements = DummyDataService.USE_DUMMY_DATA
        ? await DummyDataService.getAchievements()
        : await _apiService.getAchievements();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildHeader(),
          _buildActionButtons(),
          _buildStats(),
          _buildTabs(),
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

  SliverAppBar _buildHeader() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 55,
              backgroundColor: whiteColor.withOpacity(0.2),
              child:
                  _profile!.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _profile!.avatarUrl!,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Text(
                            _profile!.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 40,
                              color: whiteColor,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      _profile!.displayName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: whiteColor),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              _profile!.displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: whiteColor,
              ),
            ),
            if (_profile!.city != null || _profile!.country != null)
              Text(
                '${_profile!.city ?? ''}${_profile!.country != null ? ', ${_profile!.country}' : ''}',
                style: TextStyle(color: whiteColor.withOpacity(0.85)),
              ),
            if (_profile!.bio != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _profile!.bio!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: whiteColor.withOpacity(0.9)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildActionButtons() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                _loadProfileData();
              },
              child: const Text('Edit profile'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: const BorderSide(color: primaryColor, width: 2),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              },
              child: const Text('Account settings'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStats() {
    return SliverToBoxAdapter(
      child: Container(
        color: whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('Total Events', _profile!.stats['total_events']),
            _stat('Completed', _profile!.stats['completed']),
            _stat('Upcoming', _profile!.stats['upcoming']),
          ],
        ),
      ),
    );
  }

  SliverPersistentHeader _buildTabs() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabDelegate(
        TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textColor.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _stat(String label, dynamic value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildOverviewTab() => const Center(child: Text('Overview OK'));
  Widget _buildHistoryTab() => const Center(child: Text('History OK'));
  Widget _buildAchievementsTab() =>
      const Center(child: Text('Achievements OK'));
}

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, _, __) => Container(color: whiteColor, child: tabBar);

  @override
  bool shouldRebuild(_) => false;
}
