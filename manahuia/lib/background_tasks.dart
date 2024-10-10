import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';
import 'location_service.dart';
import 'notifications_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Workmanager ejecutando tarea en segundo plano");

    LocationService locationService = LocationService();
    NotificationService notificationService = NotificationService();

    Position currentPosition = await locationService.getCurrentLocation();
    List<Map<String, double>> dangerZones = await _getDangerZonesFromFirebase();

    if (locationService.isUserNearZone(currentPosition, dangerZones)) {
      notificationService.showNotification(
        "Advertencia",
        "Estás ingresando a una zona con poca iluminación",
      );
    }

    return Future.value(true);
  });
}

Future<List<Map<String, double>>> _getDangerZonesFromFirebase() async {
  // Simulación de obtención de zonas peligrosas de Firebase
  return [
    {'Latitud': 25.0, 'Longitud': -100.0},
    {'Latitud': 26.0, 'Longitud': -101.0},
  ];
}
