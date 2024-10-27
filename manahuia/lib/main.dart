import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:manahuia/location_service.dart';
import 'package:manahuia/notifications_service.dart';
import 'package:manahuia/zones_service.dart';
import 'views/ui_mapaZonasOscuras.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Solicitar permisos para recibir notificaciones
  await _requestNotificationPermission();

  runApp(const MyApp());
}

Future<void> requestNotificationPermissions() async {
   final PermissionStatus status = await Permission.notification.request();
   if (status.isGranted) {
      // Notification permissions granted
   } else if (status.isDenied) {
      // Notification permissions denied
   } else if (status.isPermanentlyDenied) {
      // Notification permissions permanently denied, open app settings
      await openAppSettings();
   }
}

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('Permiso de notificación otorgado.');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('Permiso de notificación provisional otorgado.');
  } else {
    print('Permiso de notificación denegado.');
  }

  // Inicializar notificaciones locales
  await _initializeLocalNotifications();
}

Future<void> _initializeLocalNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocationService locationService = LocationService();
  final NotificationService notificationService = NotificationService();
  final ZonesService zonesService = ZonesService();

  @override
  void initState() {
    super.initState();
    notificationService.init();
    zonesService.init(locationService, notificationService);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manahuia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const UIMapaZonasOscuras(),
      );
}
