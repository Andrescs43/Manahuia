//Controlador de las notificaciones que maneja la logica de los tokens
//para enviarlos a diferentes dispositivos.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:manahuia/models/contactosModelo.dart';

class NotificacionesControlador {
  final ContactosModelo contactosModelo = ContactosModelo();

  // Enviar notificación al contacto de confianza
  Future<void> enviarNotificacionEstado(String mensaje, String idUsuario) async {
    try {
      // Obtener el token usando el modelo
      final token = await contactosModelo.obtenerToken("0oIX6jkk6AjGduHHazes"); //deberia de buscarse el token de 
      //todos los contactos que esten en una lista de contactos de emergencia.

      if (token != null) {
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendNotification');
        await callable.call(<String, dynamic>{
          'tokens': [token], // Envía el token como una lista
          'message': mensaje,
        });
        print("Notificación enviada al contacto de confianza.");
      } else {
        print("Token del usuario no encontrado.");
      }
    } catch (e) {
      print("Error al enviar notificación: $e");
    }
  }
}
