//Controlador de las notificaciones que maneja la logica de los tokens
//para enviarlos a diferentes dispositivos.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:manahuia/models/contactosModelo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reporte_model.dart';
import 'dart:async';

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

class NotificacionService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> mostrarNotificacion(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id', 
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max, 
      priority: Priority.high,
      icon: 'notif_icon',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }
}

class NotificacionesControl {
  List<NotificacionesModel> zonasOscuras = [];
  Map<String, bool> notificacionesEnviadas = {};

   Future<void> iniciar() async {
    // Obtener las zonas oscuras desde el modelo
    zonasOscuras = await NotificacionesModel.obtenerZonasOscuras();
    _iniciarMonitoreo();
  }

  // Método para iniciar el monitoreo de la ubicación del usuario
  void _iniciarMonitoreo() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      _verificarProximidad(position);
    });
  }

  // Verificar proximidad del usuario a las zonas oscuras
  void _verificarProximidad(Position userPosition) {
    for (var zone in zonasOscuras) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        zone.latitud,
        zone.longitud,
      );

      String zoneKey = '${zone.latitud},${zone.longitud}';
      if (distance <= 100) {
        if (!notificacionesEnviadas.containsKey(zoneKey) || !notificacionesEnviadas[zoneKey]!) {
          NotificacionService().mostrarNotificacion(
            'Advertencia',
            'Estás cerca de una zona con poca iluminación',
          );
          notificacionesEnviadas[zoneKey] = true;
        }
      } else if (notificacionesEnviadas.containsKey(zoneKey) && notificacionesEnviadas[zoneKey]!) {
        notificacionesEnviadas[zoneKey] = false;
      }
    }
  }
}
