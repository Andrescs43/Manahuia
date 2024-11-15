import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'views/ui_mapaZonasOscuras.dart';
import 'views/ui_login.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manahuia',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginView(),
        '/home': (context) => const UIMapaZonasOscuras(),
      },
    );
  }
}
