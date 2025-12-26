import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapWidget extends StatefulWidget {
  final String? mapUrl;
  final String city;
  final String country;

  const MapWidget({
    super.key,
    this.mapUrl,
    required this.city,
    required this.country,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late GoogleMapController _mapController;

  // Default location (Jakarta, Indonesia) - can be improved to parse from mapUrl
  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, // Increased height to accommodate button
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultLocation,
                  zoom: 10,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('event_location'),
                    position: _defaultLocation,
                    infoWindow: InfoWindow(
                      title: '${widget.city}, ${widget.country}',
                    ),
                  ),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                // Open Google Maps directions
                final url =
                    'https://www.google.com/maps/dir/?api=1&destination=${widget.city}+${widget.country}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open Google Maps'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF177FDA), // primaryColor
                minimumSize: const Size(double.infinity, 36),
              ),
              child: const Text('Get Directions'),
            ),
          ),
        ],
      ),
    );
  }
}