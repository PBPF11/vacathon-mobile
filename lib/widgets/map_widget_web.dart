import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class MapWidget extends StatefulWidget {
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
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  @override
  void initState() {
    super.initState();
    // Register the HTML view for the map
    final viewType = 'map-view-${widget.cities.hashCode}-${widget.country.hashCode}';
    final locations = widget.cities.map((c) => '$c, ${widget.country}').join('/');
    final src = widget.cities.length == 1
        ? 'https://maps.google.com/maps?q=${Uri.encodeComponent(locations)}&output=embed'
        : 'https://maps.google.com/maps/dir/$locations&output=embed';
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewType = 'map-view-${widget.cities.hashCode}-${widget.country.hashCode}';
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}