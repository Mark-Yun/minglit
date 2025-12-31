class PartyLocation {
  const PartyLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.placeName,
  });

  final double latitude;
  final double longitude;
  final String address;
  final String placeName;

  @override
  String toString() =>
      'PartyLocation(lat: $latitude, lng: $longitude, '
      'address: $address, place: $placeName)';
}
