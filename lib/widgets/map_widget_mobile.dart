import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapWidget extends StatelessWidget {
  final String? mapUrl;
  final List<String> cities;
  final String country;

  const MapWidget({
    super.key,
    this.mapUrl,
    required this.cities,
    required this.country,
  });

  @override
  Widget build(BuildContext context) {
    final primaryCity = cities.isNotEmpty ? cities.first : 'Unknown';
    final isMultiCity = cities.length > 1;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: const Color(0xFF177FDA)),
            const SizedBox(height: 8),
            Text(
              isMultiCity
                  ? '${cities.join(' → ')}, $country'
                  : '$primaryCity, $country',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                // Open Google Maps directions
                String url;
                if (isMultiCity) {
                  // For multiple cities, create a route
                  final waypoints = cities.sublist(1, cities.length - 1).join('|');
                  url = 'https://www.google.com/maps/dir/?api=1&origin=${cities.first}+${country}&destination=${cities.last}+${country}&waypoints=$waypoints';
                } else {
                  url = 'https://www.google.com/maps/dir/?api=1&destination=$primaryCity+$country';
                }
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open Google Maps'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF177FDA),
              ),
              child: Text(isMultiCity ? 'View Route' : 'Get Directions'),
            ),
          ],
        ),
      ),
    );
  }
}