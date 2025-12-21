import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import 'profile_screen.dart';
import 'account_settings_screen.dart';
import 'events_screen.dart';
import 'forum_screen.dart';
import 'notifications_screen.dart';
import 'profile_view_screen.dart';
import 'main_menu_screen.dart';
import 'about_screen.dart';

// CSS Variables from reference - exact matches
const Color primaryColor = Color(0xFF177FDA); // --primary: #177fda
const Color accentColor = Color(0xFFBBEE63); // --accent: #bbee63
const Color darkColor = Color(0xFF0F3057); // --dark: #0f3057
const Color textColor = Color(0xFF1B1B1B); // --text: #1b1b1b
const Color bgColor = Color(0xFFF6F9FC); // --bg: #f6f9fc
const Color whiteColor = Color(0xFFFFFFFF); // --white: #ffffff

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _buildWidgetOptions(bool isAdmin) {
    return <Widget>[
      isAdmin
          ? const DashboardContent()
          : MainMenuScreen(onNavigate: _onItemTapped),
      const EventsScreen(),
      const ProfileViewScreen(),
      const ForumScreen(),
      const NotificationsScreen(),
      const AboutScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print(
      '[NAV] Bottom nav tapped: index $index, screen: ${_getScreenName(index)}',
    );
  }

  String _getScreenName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Events';
      case 2:
        return 'Profile';
      case 3:
        return 'Forum';
      case 4:
        return 'Notifications';
      case 5:
        return 'About';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin =
        authProvider.userProfile?.isSuperuser == true ||
        authProvider.userProfile?.isStaff == true;
    final widgetOptions = _buildWidgetOptions(isAdmin);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(child: widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Forum'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: textColor.withOpacity(0.6),
        backgroundColor: whiteColor,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;

    print(
      '[DEBUG] DashboardContent.build: profile=${profile?.displayName}, isAuthenticated=${authProvider.isAuthenticated}',
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Page header - matches .page-header.layout-section.layout-section--compact
            Container(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${profile?.displayName ?? 'Runner'}!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your marathon journey, upcoming events, and achievements in one place.',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard layout - matches .profile-dashboard
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1024;
                final isAdmin =
                    profile != null && (profile.isSuperuser || profile.isStaff);

                return isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile card - matches .profile-card (320px width)
                          SizedBox(
                            width: 320,
                            child: _buildProfileCard(context, profile),
                          ),
                          const SizedBox(width: 32),
                          // Main content - matches .dashboard-main
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDashboardMain(profile),
                                if (isAdmin) ...[
                                  const SizedBox(height: 32),
                                  _buildAdminSection(context),
                                ],
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _buildProfileCard(context, profile),
                          const SizedBox(height: 32),
                          _buildDashboardMain(profile),
                          if (isAdmin) ...[
                            const SizedBox(height: 32),
                            _buildAdminSection(context),
                          ],
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile? profile) {
    print('[DEBUG] _buildProfileCard: profile=${profile?.displayName}');
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(24), // matches border-radius: 24px
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.12),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24), // matches clamp(1.75rem, 3vw, 2.5rem)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar - matches .profile-card .avatar
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(
                0.15,
              ), // matches background: rgba(23, 127, 218, 0.15)
            ),
            child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      profile!.avatarUrl!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            profile?.displayName?.isNotEmpty == true
                                ? profile!.displayName![0].toUpperCase()
                                : profile?.username?.isNotEmpty == true
                                    ? profile!.username![0].toUpperCase()
                                    : 'R',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      profile?.displayName?.isNotEmpty == true
                          ? profile!.displayName![0].toUpperCase()
                          : profile?.username?.isNotEmpty == true
                              ? profile!.username![0].toUpperCase()
                              : 'R',
                      style: const TextStyle(
                        fontSize: 40, // matches font-size: 2.5rem
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
          ),

          // Name
          Text(
            profile?.displayName ?? 'Test Runner',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),

          // Location
          Text(
            profile?.city != null || profile?.country != null
                ? '${profile?.city ?? ''}${profile?.city != null && profile?.country != null ? ', ' : ''}${profile?.country ?? ''}'
                : 'Location not set',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
          ),

          const SizedBox(height: 16),

          // Bio
          Text(
            profile?.bio ?? 'Tell the community about your running story.',
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Buttons
          Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  print('[ACTION] Edit profile button tapped');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: whiteColor,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      999,
                    ), // matches border-radius: 999px
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Edit profile',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  print('[ACTION] Account settings button tapped');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  foregroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Account settings',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              // Logout button
              TextButton(
                onPressed: () async {
                  print('[ACTION] Logout button tapped');
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626), // red color
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardMain(UserProfile? profile) {
    final stats =
        profile?.stats ?? {'total_events': 0, 'completed': 0, 'upcoming': 0};

    return Column(
      children: [
        // Stats grid - matches .stats-grid
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Total Events', stats['total_events'].toString()),
            _buildStatCard('Completed', stats['completed'].toString()),
            _buildStatCard('Upcoming', stats['upcoming'].toString()),
          ],
        ),

        const SizedBox(height: 32),

        // Next event section
        _buildNextEventSection(profile?.nextEvent),

        const SizedBox(height: 32),

        // History section
        _buildHistorySection(profile),

        const SizedBox(height: 32),

        // Achievements section
        _buildAchievementsSection(profile),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16), // matches border-radius: 16px
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.1),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20), // matches padding: 1.5rem
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12, // matches font-size: 0.75rem
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B), // matches color: #64748b
              letterSpacing: 0.08 * 16, // matches letter-spacing: 0.08em
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32, // matches font-size: 2rem
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextEventSection(UserRaceHistory? nextEvent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Next Marathon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            if (nextEvent != null)
              TextButton(
                onPressed: () {
                  print(
                    '[ACTION] View next event tapped: ${nextEvent.event.id}',
                  );
                  // TODO: Navigate to event detail
                },
                child: const Text(
                  'View event',
                  style: TextStyle(color: primaryColor),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (nextEvent != null)
          Container(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(
                0.12,
              ), // matches rgba(23, 127, 218, 0.12)
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20), // matches padding: 1.5rem
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nextEvent.event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${nextEvent.event.startDate.month}/${nextEvent.event.startDate.day}, ${nextEvent.event.startDate.year} · ${nextEvent.event.city}, ${nextEvent.event.country}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${nextEvent.statusDisplay}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'No upcoming marathons yet. Browse events to start planning.',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
          ),
      ],
    );
  }

  Widget _buildHistorySection(UserProfile? profile) {
    final upcoming = profile?.upcomingRaces ?? [];
    final completed =
        profile?.history.where((h) => h.status == 'completed').toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Event History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildHistoryList(
                'Upcoming & Registered',
                upcoming,
                false,
              ),
            ),
            const SizedBox(width: 24), // matches gap: 1.5rem
            Expanded(child: _buildHistoryList('Completed', completed, true)),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryList(
    String title,
    List<UserRaceHistory> history,
    bool isCompleted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Text(
            'No ${title.toLowerCase()} yet.',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
          )
        else
          Column(
            children: history
                .map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16), // matches padding: 1rem
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(
                        0.08,
                      ), // matches rgba(23, 127, 218, 0.08)
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // matches border-radius: 12px
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${entry.event.startDate.month}/${entry.event.startDate.day}, ${entry.event.startDate.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ), // matches padding: 0.25rem 0.65rem
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? accentColor.withOpacity(0.45)
                                : primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              999,
                            ), // matches border-radius: 999px
                          ),
                          child: Text(
                            isCompleted ? 'Completed' : entry.statusDisplay,
                            style: TextStyle(
                              fontSize: 12, // matches font-size: 0.75rem
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? const Color(0xFF14532D)
                                  : primaryColor, // matches color: #14532d for completed
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAchievementsSection(UserProfile? profile) {
    final achievements = profile?.achievements ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print('[ACTION] Add achievement button tapped');
                // TODO: Add achievement modal
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Add achievement',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (achievements.isEmpty)
          Text(
            'No achievements logged yet. Celebrate your milestones!',
            style: TextStyle(fontSize: 14, color: textColor.withOpacity(0.6)),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16, // matches gap: 1.5rem
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: achievements
                .map(
                  (achievement) => Container(
                    decoration: BoxDecoration(
                      color: whiteColor,
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // matches border-radius: 16px
                      boxShadow: [
                        BoxShadow(
                          color: darkColor.withOpacity(0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(
                      20,
                    ), // matches padding: 1.5rem
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        if (achievement.achievedOn != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${achievement.achievedOn!.month}/${achievement.achievedOn!.day}, ${achievement.achievedOn!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            achievement.description ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                          ),
                        ),
                        if (achievement.link != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              print(
                                '[ACTION] Achievement link tapped: ${achievement.link}',
                              );
                              // TODO: Open link
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'View proof',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Panel',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildAdminActionCard(
              'Manage Events',
              'Create, edit, and delete events',
              Icons.event,
              () => Navigator.pushNamed(context, '/admin/events'),
            ),
            _buildAdminActionCard(
              'Manage Participants',
              'View and manage registrations',
              Icons.people,
              () => Navigator.pushNamed(context, '/admin/participants'),
            ),
            _buildAdminActionCard(
              'Forum Moderation',
              'Moderate forum posts and reports',
              Icons.forum,
              () => Navigator.pushNamed(context, '/admin/forum'),
            ),
            _buildAdminActionCard(
              'View Statistics',
              'See platform analytics',
              Icons.analytics,
              () {
                // TODO: Show admin stats modal or navigate to stats page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Statistics feature coming soon'),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminActionCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkColor.withOpacity(0.1),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
