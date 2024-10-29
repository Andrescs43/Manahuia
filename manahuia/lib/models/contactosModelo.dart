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
