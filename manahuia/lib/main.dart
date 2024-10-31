import 'package:firebase_core/firebase_core.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'views/ui_mapaZonasOscuras.dart';
import 'views/ui_login.dart';
import 'package:manahuia/location_service.dart';
import 'package:manahuia/notifications_service.dart';
import 'package:manahuia/zones_service.dart';
//Permite a Firebase Cloud Messaging mandar notificaciones en segundo plano.
//Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //await Firebase.initializeApp();
  //print("Mensaje en segundo plano: ${message.messageId}");
//}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manahuia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/home': (context) => const UIMapaZonasOscuras(),
      },
    );
  }
}

/*class MyApp extends StatelessWidget {
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


//Comentario totalmente necesario:
      );
}*/
