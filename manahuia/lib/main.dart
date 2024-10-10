import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manahuia/location_service.dart';
import 'package:manahuia/notifications_service.dart';
import 'package:workmanager/workmanager.dart';

import 'views/ui_mapaZonasOscuras.dart';

// Handler para los mensajes recibidos en segundo plano
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Un mensaje fue recibido en segundo plano: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Solicitar permisos de ubicación
  LocationPermission permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    print('Permisos de ubicación denegados');
  } else {
    print('Permisos de ubicación concedidos');
  }

  // Asegurarse de pedir el permiso de background
  if (permission == LocationPermission.whileInUse) {
    LocationPermission backgroundPermission = await Geolocator.requestPermission();
    if (backgroundPermission == LocationPermission.always) {
      print('Permisos de ubicación en segundo plano concedidos');
    }
  }


  // Registrar el handler para mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar WorkManager para tareas en segundo plano
  Workmanager().initialize(
    callbackDispatcher, // Función de manejo de tareas en segundo plano
    isInDebugMode: false, // Cambiar a false para producción
  );

  Workmanager().registerPeriodicTask(
    "1", // Identificador único de la tarea
    "locationTask", // Nombre de la tarea
    frequency: const Duration(minutes: 1), // Mínimo en Android es 15 minutos
  );

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

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    notificationService.init();
    _fetchDangerZones();
  }

  // Iniciar el monitoreo de ubicación en segundo plano
  void _startLocationMonitoring() {
  Workmanager().registerPeriodicTask(
    "1", // Identificador único de la tarea
    "locationTask", // Nombre de la tarea
    frequency: const Duration(minutes: 1), // Mínimo en Android es 15 minutos
    constraints: Constraints(
      networkType: NetworkType.not_required, 
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
    inputData: <String, dynamic>{'key': 'value'}, // Puedes pasar datos adicionales si es necesario
  );
  }


  void _requestPermissions() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      print('Permisos de ubicación denegados');
    } else {
      print('Permisos de ubicación concedidos');
    }

    // Asegurarse de pedir el permiso de background
    if (permission == LocationPermission.whileInUse) {
      LocationPermission backgroundPermission = await Geolocator.requestPermission();
      if (backgroundPermission == LocationPermission.always) {
        print('Permisos de ubicación en segundo plano concedidos');
      }
    }
  }


  // Inicializar Firebase Messaging
  void _initializeFirebaseMessaging() {
    // Inicializar notificaciones locales
    notificationService.init();

    // Manejar mensajes cuando la app está en segundo plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje en segundo plano: ${message.notification?.title}');
      notificationService.showNotification(
        message.notification?.title ?? 'Advertencia',
        message.notification?.body ?? 'Estás cerca de una zona con poca iluminación',
      );
    });

    // Manejar mensajes cuando la app está en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Suscribirse a un topic (si es necesario)
    messaging.subscribeToTopic("alertas_zonas_oscura");
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

// Función para manejar tareas en segundo plano
  void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("Workmanager ejecutando tarea en segundo plano");

    // Inicializar servicios de ubicación y notificaciones
    LocationService locationService = LocationService();
    NotificationService notificationService = NotificationService();

    // Obtener la ubicación actual del usuario
    Position currentPosition = await locationService.getCurrentLocation();

    // Obtener las zonas peligrosas desde Firestore
    List<Map<String, double>> zonasPeligrosas = await _getDangerZonesFromFirebase();

    // Verificar si el usuario está cerca de una zona peligrosa
    bool isNearDangerZone = locationService.isUserNearZone(currentPosition, zonasPeligrosas);

    if (isNearDangerZone) {
      // Enviar una notificación si está cerca de una zona peligrosa
      notificationService.showNotification(
        "¡Cuidado!",
        "Estás entrando a una zona con poca iluminación.",
      );
    }

    return Future.value(true); // Indicar que la tarea se completó
  });
}


  Future<List<Map<String, double>>> _getDangerZonesFromFirebase() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('zonasOscuras').get();

    // Check if any documents were found
    if (snapshot.docs.isEmpty) {
      return []; // Return an empty list if no documents exist
    }

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

    return fetchedZones;
}


