import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'location_service.dart';
import 'notifications_service.dart';

class ZonesService {
  List<Map<String, double>> dangerZones = [];
  Map<String, bool> notifiedZones = {};
  StreamSubscription<Position>? positionStream;

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
    
    _startMonitoringLocation(locationService, notificationService);
  }

  // Iniciar monitoreo de la ubicación del usuario
  void _startMonitoringLocation(LocationService locationService, NotificationService notificationService) {
    // Definir las configuraciones de ubicación
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Precisión alta
      distanceFilter: 10, // Notificar cambios cuando el usuario se mueva 10 metros
    );

    // Iniciar el stream de la posición
    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _checkProximity(position, locationService, notificationService);
    });
  }

  // Verificar si el usuario está cerca de una zona peligrosa
  void _checkProximity(Position userPosition, LocationService locationService, NotificationService notificationService) {
    for (var zone in dangerZones) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        zone['Latitud']!,
        zone['Longitud']!,
      );

      // Si la distancia es menor a 100 metros
      String zoneKey = '${zone['Latitud']},${zone['Longitud']}';
      if (distance <= 9) {
        // Si no ha sido notificado para esta zona, enviar la notificación
        if (!notifiedZones.containsKey(zoneKey) || !notifiedZones[zoneKey]!) {
          notificationService.showNotification(
            'Advertencia',
            'Estás cerca de una zona con poca iluminación',
          );

          // Marcar esta zona como notificada
          notifiedZones[zoneKey] = true;
        }
      } else {
        // Resetear la notificación si el usuario se aleja de la zona
        if (notifiedZones.containsKey(zoneKey) && notifiedZones[zoneKey]!) {
          notifiedZones[zoneKey] = false;
        }
      }
    }
  }

  //Cancelar el monitoreo de la ubicación
  void cancelLocationMonitoring() {
    positionStream?.cancel();
  }
}
