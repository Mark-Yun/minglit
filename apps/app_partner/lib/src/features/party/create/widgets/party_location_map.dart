import 'package:flutter/material.dart';

class PartyLocationMap extends StatelessWidget {
  const PartyLocationMap({
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
