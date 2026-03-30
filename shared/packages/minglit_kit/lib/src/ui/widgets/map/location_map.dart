import 'package:flutter/material.dart';

/// Placeholder map widget for unsupported platforms.
class LocationMap extends StatelessWidget {
  /// Creates a location map placeholder.
  const LocationMap({
    required this.latitude,
    required this.longitude,
    super.key,
  });

  /// Latitude for the location.
  final double latitude;

  /// Longitude for the location.
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Map not supported on this platform'));
  }
}
