import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

class PartyLocationMap extends StatefulWidget {
  const PartyLocationMap({
    required this.latitude,
    required this.longitude,
    super.key,
  });

  final double latitude;
  final double longitude;

  @override
  State<PartyLocationMap> createState() => _PartyLocationMapState();
}

class _PartyLocationMapState extends State<PartyLocationMap> {
  KakaoMapController? _mapController;

  @override
  void didUpdateWidget(covariant PartyLocationMap oldWidget) {
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
