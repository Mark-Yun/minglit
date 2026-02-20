import 'package:geolocator/geolocator.dart';
import 'package:minglit_kit/src/utils/log.dart';

class LocationResult {
  const LocationResult({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationService {
  Future<LocationResult?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Log.d('[LocationService] Location services disabled');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Log.d('[LocationService] Permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Log.d('[LocationService] Permission denied forever');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e, st) {
      Log.e('[LocationService] getCurrentPosition failed', e, st);
      return null;
    }
  }
}
