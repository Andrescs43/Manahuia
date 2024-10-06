import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manahuia/location_service.dart';
import 'package:manahuia/notifications_service.dart';

import 'views/ui_mapaZonasOscuras.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {
  final LocationService locationService = LocationService();
  final NotificationService notificationService = NotificationService();
  List<Map<String, double>> dangerZones = [];

  @override
  void initState() {
    super.initState();
    notificationService.init();
    _fetchDangerZones();
  }

  // Función para obtener las coordenadas de Firestore
  void _fetchDangerZones() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('Reporte').get();

    List<Map<String, double>> fetchedZones = snapshot.docs.map((doc) {
      String latString = doc['Latitud'] ?? ''; // Manejar el caso en que no exista 'Latitud'
      String lonString = doc['Longitud'] ?? ''; // Manejar el caso en que no exista 'Longitud'
      
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

    setState(() {
      dangerZones = fetchedZones;
    });

    // Después de obtener las coordenadas, chequear la proximidad
    _checkProximity();
}

  // Verificar si el usuario está cerca de una zona peligrosa
  void _checkProximity() async {
    if (dangerZones.isNotEmpty) {
      Position userPosition = await locationService.getCurrentLocation();
      if (locationService.isUserNearZone(userPosition, dangerZones)) {
        notificationService.showNotification(
          'Alerta',
          'Estás cerca de una zona con poca iluminación',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manahuia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const UIMapaZonasOscuras(),
  );
}