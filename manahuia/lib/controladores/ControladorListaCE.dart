import 'package:manahuia/models/contactosModelo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';

class ControladorListaCE {
  final ContactosModelo contactosModel = ContactosModelo();
  String telefono = '';
  String estado = '';

  Future<void> cargarTelefonoYEstado() async {
    telefono = await contactosModel.obtenerTelefono() ?? "";
    estado = await contactosModel.obtenerEstado(telefono) ?? "";
  }
  // Método para obtener un contacto
  Future<Contact?> obtenContacto() async {
    var permissionStatus = await Permission.contacts.status;
    await Permission.contacts.request();

    if (!permissionStatus.isGranted) {
      return null;
    } else {
      final contacto = await FlutterContacts.openExternalPick();
      if (contacto != null) {
        contactosModel.agregarContacto(contacto);
        return contacto;
      }
    }
    return null;
  }

  // Método para borrar un contacto
  void borraContacto(Contact contacto) {
    contactosModel.quitaContacto(contacto);
  }

  // Método para obtener la lista de contactos
  List<Contact> obtenerListaContactos() {
    return contactosModel.obtenerContactos();
  }

  void actualizarEstado(String estado) async{
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String longitud = position.longitude.toString();
    String latitud = position.latitude.toString();
    contactosModel.actualizarEstado(estado, longitud, latitud);
  }

  //String obtenerEstado(String telefono){
    //String estado = contactosService.obtenerEstado(telefono) as String;
    //if (estado != ""){
      //return estado;
    //} else {
      //return "";
    //}
  //}

  String obtenerTelefono() => telefono;

  String obtenerEstado() => estado;

//Este metodo verifica si un texto esta vacio
  int verificaVacio(String texto){
    if (texto.isEmpty){
      return 0;
    } else {
      return 1;
    }
  }

  void guardaMensaje(String mensaje){
    contactosModel.actualizaMensajeFirebase(mensaje); 
  }
 
  Future<String> obtenerMensaje(String telefono) async {
    String? mensaje = await contactosModel.obtenerCampo(telefono, "Mensaje");

    if (mensaje != null){
      return mensaje;
    } else {
      return ""; //si no tiene estado o no se encuentra
    }
  }
}
