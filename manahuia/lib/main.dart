import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'views/ui_mapaZonasOscuras.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manahuia',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const UIMapaZonasOscuras(),
      );
}