import 'package:manahuia/models/contactosModelo.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ControladorListaCE {
  final ContactosModelo contactosService = ContactosModelo();

  // Método para obtener un contacto
  Future<Contact?> obtenContacto() async {
    var permissionStatus = await Permission.contacts.status;
    await Permission.contacts.request();

    if (!permissionStatus.isGranted) {
      return null;
    } else {
      final contacto = await FlutterContacts.openExternalPick();
      if (contacto != null) {
        contactosService.agregarContacto(contacto);
        return contacto;
      }
    }
    return null;
  }

  // Método para borrar un contacto
  void borraContacto(Contact contacto) {
    contactosService.quitaContacto(contacto);
  }

  // Método para obtener la lista de contactos
  List<Contact> obtenerListaContactos() {
    return contactosService.obtenerContactos();
  }
}
