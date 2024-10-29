// Modelo: maneja la informacion.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'dart:convert';

class ContactosModelo {
  List<Contact> contactos = [];

  void agregarContacto(Contact contacto) {
    if (!contactos.contains(contacto)){
      contactos.add(contacto);
      guardarContactos();
    }
  }

  void quitaContacto(Contact contacto) {
    if (contactos.contains(contacto)){
      contactos.remove(contacto);
      guardarContactos();
    }
  }

  Future<void> guardarContactos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> contactosJson = contactos.map((contacto) {
      var contactoSinFoto = {
        ...contacto.toJson(),
        'photo': null,
        'thumbnail': null,
      };
      return jsonEncode(contactoSinFoto);
    }).toList();
    await prefs.setStringList('contactos', contactosJson);
  }

  Future<void> cargarContactos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? contactosJson = prefs.getStringList('contactos');
    if (contactosJson != null) {
      contactos = contactosJson.map((contactoStr) => Contact.fromJson(jsonDecode(contactoStr))).toList();
    }
  }

  List<Contact> obtenerContactos() {
    return contactos;
  }
}

// login_model.dart

class LoginModel {
  final String estado;
  final String latitud;
  final String longitud;
  final String nombre;
  final String password;
  final int telefono;

  LoginModel({
    this.estado='No especificado',
    this.latitud='Sin ubicacion',
    this.longitud='Sin ubicacion',
    required this.nombre,
    required this.password,
    required this.telefono,
  });

  // Validación de credenciales mínimas
  bool isValid() {
    return telefono.toString().isNotEmpty && password.isNotEmpty;
  }

  // Convertir el modelo a un mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'Estado': estado,
      'Latitud': latitud,
      'Longitud': longitud,
      'Nombre': nombre,
      'Password': password,
      'Telefono': telefono,
    };
  }

  // Crear el modelo a partir de un documento de Firebase
  factory LoginModel.fromMap(Map<String, dynamic> map) {
    return LoginModel(
      estado: map['Estado'],
      latitud: map['Latitud'],
      longitud: map['Longitud'],
      nombre: map['Nombre'],
      password: map['Password'],
      telefono: map['Telefono'],
    );
  }
}

