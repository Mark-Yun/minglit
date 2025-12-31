import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

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
  final String _viewId = 'kakao-map-view';
  JSObject? _map;
  JSObject? _marker;

  @override
  void initState() {
    super.initState();
    ui.platformViewRegistry.registerViewFactory(_viewId, (int id) {
      final element = web.document.createElement('div') as web.HTMLDivElement;
      return element
        ..id = 'kakao-map-$id'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  void didUpdateWidget(covariant PartyLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      _updateMap(widget.latitude, widget.longitude);
    }
  }

  void _initMap(int id) {
    Future.delayed(const Duration(milliseconds: 500), () {
      _updateMap(widget.latitude, widget.longitude, id: id);
    });
  }

  void _updateMap(double lat, double lng, {int? id}) {
    // 1. Get Kakao Object
    final kakaoAny = web.window.getProperty('kakao'.toJS);
    if (kakaoAny == null) {
      debugPrint('Kakao Maps SDK not loaded yet.');
      return;
    }
    final kakao = kakaoAny as JSObject;

    // 2. Get Maps Object
    final mapsAny = kakao.getProperty('maps'.toJS);
    if (mapsAny == null) return;
    final maps = mapsAny as JSObject;

    // 3. Create LatLng using constructor
    final latLngConstructor = maps.getProperty('LatLng'.toJS) as JSFunction;
    final latLng = latLngConstructor.callAsConstructor(
      lat.toJS,
      lng.toJS,
    );

    // 4. Create Map or Update Center
    if (_map == null && id != null) {
      final container = web.document.getElementById('kakao-map-$id');
      if (container == null) return;

      final options = JSObject()
        ..setProperty('center'.toJS, latLng)
        ..setProperty('level'.toJS, 3.toJS);

      final mapConstructor = maps.getProperty('Map'.toJS) as JSFunction;
      _map = mapConstructor.callAsConstructor(
        container as JSObject,
        options,
      );
    } else if (_map != null) {
      _map!.callMethod('setCenter'.toJS, latLng);
    }

    // 5. Update Marker
    if (_map != null) {
      if (_marker != null) {
        // Pass explicit null to remove marker
        _marker!.callMethod('setMap'.toJS, null);
      }

      final markerOptions = JSObject()..setProperty('position'.toJS, latLng);

      final markerConstructor = maps.getProperty('Marker'.toJS) as JSFunction;
      _marker = markerConstructor.callAsConstructor(markerOptions);

      _marker!.callMethod('setMap'.toJS, _map);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: _viewId,
      onPlatformViewCreated: _initMap,
    );
  }
}
