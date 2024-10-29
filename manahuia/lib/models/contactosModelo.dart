// Modelo: maneja la informacion.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ContactosModelo {
  List<Contact> contactos = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; //para consultar tokens en y enviar notificaciones

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

//obtiene las ID de los contactos de emergencia
  List<String>? obtenerIDContactos(){
    if (contactos.isNotEmpty){ // si hay contactos
      List<String> idContactos = [];
      for (var contacto in contactos) {
        idContactos.add(contacto.id);
      }
      return idContactos;
    } else {
      return null;
    }
  }

  // Obtener el token del usuario
  Future<String?> obtenerToken(String idUsuario) async {
    try {
      final userDoc = await _firestore.collection('Trabajador').doc(idUsuario).get();
      return userDoc['token'] as String?;
    } catch (e) {
      print("Error al obtener el token desde Firestore: $e");
      return null;
    }
  }

  Future <void> actualizarEstado(String estado, String telefono, String longitud, String latitud) async{
        // Actualiza el documento del Trabajador en Firestore con el nuevo token
        await _firestore.collection('Trabajador').doc(telefono).update({
          'Estado': estado,
          'Latitud': latitud,
          'Longitud': longitud,
        });
  }

  Future<String?> obtenerEstado(String telefono) async{
    try {
    // Obtiene el documento con el teléfono especificado
    DocumentSnapshot snapshot = await _firestore.collection('Trabajador').doc(telefono).get();
    // Verifica que el documento existe y obteniene el campo 'Estado'
    if (snapshot.exists) {
      return snapshot.get('Estado') as String?;
    } else {
      return ""; // Retorna null si el documento no existe
    }
  } catch (e) {
    print('Error al obtener el estado: $e');
    return "";
  }
  } 
}
