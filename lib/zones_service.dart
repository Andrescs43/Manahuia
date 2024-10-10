import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import 'notifications_service.dart';

class ZonesService {
  List<Map<String, double>> dangerZones = [];

  void init(LocationService locationService, NotificationService notificationService) {
    _fetchDangerZones(locationService, notificationService);
  }

  // Función para obtener las coordenadas de Firestore
  void _fetchDangerZones(LocationService locationService, NotificationService notificationService) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('Reporte').get();
    
    List<Map<String, double>> fetchedZones = snapshot.docs.map((doc) {
      String latString = doc['Latitud'] ?? '';
      String lonString = doc['Longitud'] ?? '';

      double latitude = 0.0;
      double longitude = 0.0;
      try {
        latitude = double.parse(latString);
        longitude = double.parse(lonString);
      } catch (e) {
        print('Error al convertir las coordenadas: $e');
      }
      return {
        'Latitud': latitude,
        'Longitud': longitude,
      };
    }).toList();

    dangerZones = fetchedZones;
    _checkProximity(locationService, notificationService);
  }

  // Verificar si el usuario está cerca de una zona peligrosa
  void _checkProximity(LocationService locationService, NotificationService notificationService) async {
    if (dangerZones.isNotEmpty) {
      Position userPosition = await locationService.getCurrentLocation();
      if (locationService.isUserNearZone(userPosition, dangerZones)) {
        notificationService.showNotification(
          'Advertencia',
          'Estás cerca de una zona con poca iluminación',
        );
      }
    }
  }
}
