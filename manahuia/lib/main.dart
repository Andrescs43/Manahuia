import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:manahuia/location_service.dart';
import 'package:manahuia/notifications_service.dart';
import 'package:manahuia/zones_service.dart';
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
