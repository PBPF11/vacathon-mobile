import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// CSS Variables from reference - exact matches
const Color primaryColor = Color(0xFF177FDA);
const Color accentColor = Color(0xFFBBEE63);
const Color darkColor = Color(0xFF0F3057);
const Color textColor = Color(0xFF1B1B1B);
const Color bgColor = Color(0xFFF6F9FC);
const Color whiteColor = Color(0xFFFFFFFF);

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<String> _teamMembers = [
    'Ganesha Taqwa',
    'Tazkia Nur Alyani',
    'Josiah Naphta Simorangkir',
    'Muhammad Rafi Ghalib Fideligo',
    'Naufal Zafran Fadil',
    'Prama Ardend Narendradhipa',
  ];

  static const List<_ValueItem> _values = [
    _ValueItem(
      title: 'Community-Driven',
      description:
          'Built around the stories and camaraderie of runners across the globe.',
    ),
    _ValueItem(
      title: 'Data Smart',
      description:
          'Leverage rich event insights to plan runs aligned with your goals and schedule.',
    ),
    _ValueItem(
      title: 'Inclusive Access',
      description:
          'Support new organizers with tools to host safe, exciting, and sustainable events.',
    ),
  ];

  static const List<_ContactLink> _links = [
    _ContactLink(
      label: 'Vacathon Website',
      icon: Icons.travel_explore,
      url: 'https://muhammad-rafi419-vacathon.pbp.cs.ui.ac.id/',
    ),
    _ContactLink(
      label: 'Instagram',
      icon: Icons.camera_alt,
      url: 'https://www.instagram.com/',
    ),
    _ContactLink(
      label: 'Email',
      icon: Icons.email,
      url: 'mailto:vacathon@contact.com',
    ),
  ];

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  double _contentMaxWidth(double width) {
    if (width >= 1200) {
      return 1000;
    }
    if (width >= 900) {
      return 860;
    }
    return width;
  }

  BoxDecoration _surfaceDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? whiteColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: primaryColor.withOpacity(0.08)),
      boxShadow: [
        BoxShadow(
          color: darkColor.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }

  Widget _buildSurfaceCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    Color? color,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: _surfaceDecoration(color: color),
      child: child,
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                bgColor,
                bgColor.withOpacity(0.92),
                whiteColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              _buildBubble(
                top: -80,
                right: -40,
                size: 220,
                color: primaryColor.withOpacity(0.12),
              ),
              _buildBubble(
                top: 220,
                left: -90,
                size: 200,
                color: accentColor.withOpacity(0.2),
              ),
              _buildBubble(
                bottom: 160,
                right: -80,
                size: 220,
                color: primaryColor.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = _contentMaxWidth(constraints.maxWidth);
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('About Vacathon'),
            backgroundColor: primaryColor,
            elevation: 0,
            centerTitle: true,
          ),
          body: Stack(
            children: [
              _buildBackdrop(),
              ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeroCard(),
                          const SizedBox(height: 20),
                          _buildMissionSection(),
                          const SizedBox(height: 20),
                          _buildValuesSection(),
                          const SizedBox(height: 20),
                          _buildContactSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.85),
            accentColor.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.2),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Vacathon',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: whiteColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vacathon connects passionate runners with curated marathon '
            'experiences that double as unforgettable getaways.',
            style: TextStyle(
              color: whiteColor.withOpacity(0.92),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeroTag(label: 'Destination Races'),
              _HeroTag(label: 'Community'),
              _HeroTag(label: 'Travel Ready'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final mission = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We aspire to simplify the journey from discovering unique '
                'marathon events to experiencing them first-hand.',
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vacathon centralizes event discovery, registration, and community '
                'engagement so runners can focus on the miles ahead.',
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'From tropical sunrise runs to metropolitan night races, we '
                'highlight events that blend endurance, exploration, and culture.',
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  height: 1.6,
                ),
              ),
            ],
          );

          final team = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team Vacathon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: darkColor,
                  ),
                ),
                const SizedBox(height: 8),
                ..._teamMembers.map(
                  (member) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      member,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mission),
                const SizedBox(width: 24),
                Expanded(child: team),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mission,
              const SizedBox(height: 20),
              team,
            ],
          );
        },
      ),
    );
  }

  Widget _buildValuesSection() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Values',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 900
                  ? 3
                  : width >= 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: width >= 900 ? 1.6 : 1.9,
                children: _values.map(_buildValueCard).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(_ValueItem value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: darkColor.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.description,
            style: TextStyle(
              color: textColor.withOpacity(0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact and Links',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _links
                .map(
                  (link) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(link.icon, color: darkColor),
                    ),
                    title: Text(
                      link.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _openUrl(link.url),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;

  const _HeroTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: whiteColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: whiteColor.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: whiteColor,
        ),
      ),
    );
  }
}

class _ValueItem {
  final String title;
  final String description;

  const _ValueItem({required this.title, required this.description});
}

class _ContactLink {
  final String label;
  final IconData icon;
  final String url;

  const _ContactLink({
    required this.label,
    required this.icon,
    required this.url,
  });
}
