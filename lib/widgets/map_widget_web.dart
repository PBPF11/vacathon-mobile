import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

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
  @override
  void initState() {
    super.initState();
    // Register the HTML view for the map
    ui_web.platformViewRegistry.registerViewFactory(
      'map-view-${widget.mapUrl?.hashCode ?? 'default'}',
      (int viewId) => html.IFrameElement()
        ..src = widget.mapUrl ?? 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3966.521260322283!2d106.816666!3d-6.2!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x0%3A0x0!2zNsKwMTInMDAuMCJTIDEwNsKwNDknMDAuMCJF!5e0!3m2!1sen!2sid!4v1638360000000!5m2!1sen!2sid'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HtmlElementView(
          viewType: 'map-view-${widget.mapUrl?.hashCode ?? 'default'}',
        ),
      ),
    );
  }
}