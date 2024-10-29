// login_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contactosModelo.dart';

class LoginController {
  final CollectionReference usuariosCollection =
      FirebaseFirestore.instance.collection('Trabajador');

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
        await guardarTelefono(telefono); // Guardamos el teléfono
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

  // Método para guardar el teléfono en SharedPreferences
Future<void> guardarTelefono(int telefono) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('telefono', telefono.toString());
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
