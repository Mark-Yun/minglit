import 'package:geolocator/geolocator.dart';
import 'package:minglit_kit/src/utils/log.dart';

/// Holds latitude and longitude from a location query.
class LocationResult {
  /// Creates a [LocationResult] with the given [latitude] and [longitude].
  const LocationResult({required this.latitude, required this.longitude});

  /// The latitude coordinate.
  final double latitude;

  /// The longitude coordinate.
  final double longitude;
}

/// Service for retrieving the device's current GPS position.
class LocationService {
  /// Returns true if location permission is granted (whileInUse or always).
  ///
  /// Does NOT request permission — only checks current status.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Returns the current position, or null if unavailable or permission denied.
  ///
  /// // Fix #419: Try getLastKnownPosition first for instant results,
  /// then fall back to getCurrentPosition with timeout.
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

      // Fix #419: Try last known position first (instant, no GPS wait).
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        Log.d('[LocationService] Using last known position');
        return LocationResult(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        );
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
    } on Exception catch (e, st) {
      Log.e('[LocationService] getCurrentPosition failed', e, st);
      return null;
    }
  }
}
