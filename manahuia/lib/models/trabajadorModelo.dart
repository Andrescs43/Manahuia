// Modelo: maneja la informacion.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
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

  // Método genérico para obtener un campo específico de un contacto en Firestore
  // Método para obtener cualquier campo en Firestore usando el teléfono como identificador
  Future<String?> obtenerCampo(String telefono, String campo) async {
    try {
      // Convierte el teléfono a String en caso de ser necesario para la consulta
      final telefonoStr = telefono.toString();

      // Obtiene el documento del usuario con el teléfono especificado
      DocumentSnapshot snapshot = await _firestore.collection('Trabajador').doc(telefonoStr).get();

      // Verifica que el documento existe y obtiene el campo deseado
      if (snapshot.exists) {
        return snapshot.get(campo) as String?;
      } else {
        print("Documento no encontrado para el teléfono $telefonoStr");
        return null;
      }
    } catch (e) {
      print('Error al obtener el campo $campo: $e');
      return null;
    }
  }


  Future<void> actualizarEstado(String estado, String longitud, String latitud) async {
    String? telefonoActual = await obtenerTelefono(); // Usa await para obtener el valor, pero se tarda culeron
    if (telefonoActual != null && telefonoActual.isNotEmpty) {
      // Actualiza el documento del Trabajador en Firestore con el nuevo token
      await _firestore.collection('Trabajador').doc(telefonoActual).update({
        'Estado': estado,
        'Latitud': latitud,
        'Longitud': longitud,
      });
    } else {
      print("No se pudo actualizar el estado: Teléfono no disponible.");
    }
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

    Future<String?> obtenerMensaje(String telefono) async{
    try {
    // Obtiene el documento con el teléfono especificado
    DocumentSnapshot snapshot = await _firestore.collection('Trabajador').doc(telefono).get();
    // Verifica que el documento existe y obteniene el campo 'Mensaje'
    if (snapshot.exists) {
      return snapshot.get('Mensaje') as String?;
    } else {
      return ""; // Retorna null si el documento no existe
    }
  } catch (e) {
    print('Error al obtener el Mensaje: $e');
    return "";
  }
  }
  
  Future<String?> obtenerTelefono() async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // Usa await para resolver el Future
    return prefs.getString('telefono'); // Devuelve el valor como String
  }

  Future<void> actualizaMensajeFirebase(String mensaje) async {
    try{
      String? telefonoActual = await obtenerTelefono(); // Usa await para obtener el valor, pero se tarda culeron
    if (telefonoActual != null && telefonoActual.isNotEmpty) {
      // Actualiza el documento del Trabajador en Firestore con el nuevo token
      await _firestore.collection('Trabajador').doc(telefonoActual).update({
        'Mensaje': mensaje,
      });
    } else {
      print("No se pudo actualizar el estado: Teléfono no disponible.");
    }
    } catch (e){
      print("Error: $e");
    }
  }

}

  Future<void> llamar(Contact contacto) async {
    // Obtiene el número de teléfono sin espacios
    String numero = contacto.phones.isNotEmpty ? contacto.phones.first.number.replaceAll(' ', '') : '';
    
    if (numero.isNotEmpty) {
      await FlutterPhoneDirectCaller.callNumber(numero);
    } else {
      print("El contacto no tiene un número de teléfono válido.");
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
