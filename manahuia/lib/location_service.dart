import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  bool isUserNearZone(Position userPosition, List<Map<String, double>> dangerZones) {
    for (var zone in dangerZones) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        zone['Latitud']??0.0,
        zone['Longitud']??0.0,
      );

      if (distance < 100) { // Si está a menos de 100 metros
        return true;
      }
    }
    return false;
  }
}
