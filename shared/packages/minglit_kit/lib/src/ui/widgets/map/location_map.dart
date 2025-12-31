import 'package:flutter/material.dart';

class LocationMap extends StatelessWidget {
  const LocationMap({
    required this.latitude,
    required this.longitude,
    super.key,
  });

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Map not supported on this platform'));
  }
}
