import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({
    required this.latitude,
    required this.longitude,
    super.key,
  });

  final double latitude;
  final double longitude;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  KakaoMapController? _mapController;

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      _mapController?.panTo(LatLng(widget.latitude, widget.longitude));
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);
    return KakaoMap(
      onMapCreated: (controller) => _mapController = controller,
      center: center,
      markers: [
        Marker(
          markerId: 'selected',
          latLng: center,
          width: 30,
          height: 44,
          offsetX: 15,
          offsetY: 44,
        ),
      ],
    );
  }
}
