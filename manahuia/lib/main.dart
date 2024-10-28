import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'views/ui_mapaZonasOscuras.dart';
import 'package:manahuia/location_service.dart';
import 'package:manahuia/notifications_service.dart';
import 'package:manahuia/zones_service.dart';

//Permite a Firebase Cloud Messaging mandar notificaciones en segundo plano.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Mensaje en segundo plano: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();
  // Configura el manejador de mensajes en segundo plano.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
    // getToken() obtiene el token del dispositivo al iniciar la app.
    getToken();
  }

  //Guarda el token para enviar notificaciones a dispositivos especificos
    void getToken() async {
      String? token = await FirebaseMessaging.instance.getToken();
      print("Token del dispositivo: $token");
      // Se debe guardar este token en Firestore bajo el usuario para luego enviarle notificaciones específicas
    }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manahuia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const UIMapaZonasOscuras(),
  );
}

//Comentario totalmente necesario: 
