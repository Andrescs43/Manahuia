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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manahuia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const UIMapaZonasOscuras(),
      );
}*/

//Comentario totalmente necesario: 