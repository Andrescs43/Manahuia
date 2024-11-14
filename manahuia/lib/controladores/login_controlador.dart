// login_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trabajadorModelo.dart';

class LoginController {
  final CollectionReference usuariosCollection = FirebaseFirestore.instance.collection('Trabajador');

  // Método para iniciar sesión
  Future<bool> iniciarSesion(int telefono, String password) async {
    try {
      // Buscar al usuario por su teléfono en Firestore
      var snapshot = await usuariosCollection
          .where('Telefono', isEqualTo: telefono)
          .where('Password', isEqualTo: password)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print("Inicio de sesión exitoso");
        await guardarSesion(telefono); // Guardamos la sesión
        return true;
      } else {
        print("Teléfono o contraseña incorrectos");
        return false;
      }
    } catch (e) {
      print("Error al iniciar sesión: $e");
      return false;
    }
  }

  // Método para guardar el teléfono en SharedPreferences y mantener la sesión activa
  Future<void> guardarSesion(int telefono) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesion_iniciada', true); // Indicador de sesión activa
    await prefs.setString('telefono', telefono.toString());
  }

  // Método para verificar si ya existe una sesión activa al iniciar la app
  Future<bool> verificarSesionActiva() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sesion_iniciada') ?? false; // Retorna true si la sesión está activa
  }

  // Método para cerrar la sesión y eliminar los datos de SharedPreferences
  Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('sesion_iniciada');
    await prefs.remove('telefono');
  }

  // Método para registrar un nuevo usuario en Firebase
  Future<void> registrarUsuario(LoginModel usuario) async {
    try {
      await usuariosCollection.add(usuario.toMap());
      print("Usuario registrado exitosamente");
    } catch (e) {
      print("Error al registrar usuario: $e");
    }
  }
}

// registro

class RegistroController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registrarUsuario(String nombre, int telefono, String password, String confirmPassword) async {
    if (password != confirmPassword) {
      return "Las contraseñas no coinciden";
    }

    try {
      LoginModel usuario = LoginModel(nombre: nombre, telefono: telefono, password: password);
      await _firestore.collection('Trabajador').doc(telefono.toString()).set(usuario.toMap());
      return null; // Sin errores
    } catch (e) {
      return "Error al registrar el usuario: $e";
    }
  }
}
