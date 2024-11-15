import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:manahuia/controladores/reporte_controlador.dart';


class ReporteModel {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> obtenerZonasOscuras() async {
    List<Map<String, dynamic>> zonas = [];
    QuerySnapshot querySnapshot = await firestore.collection('Reporte').get();

    for (var doc in querySnapshot.docs) {
      zonas.add({
        'id': doc.id,
        'latitud': double.parse(doc['Latitud']),
        'longitud': double.parse(doc['Longitud']),
      });
    }
    return zonas;
  }

  Future<void> enviaResena(obtenerReportes reporte, String resena) async {
    try {
      // Asegúrate de que el reporteID esté en el tipo correcto
      final dynamic reporteID = int.tryParse(reporte.reporteID.toString()) ?? reporte.reporteID;

      print("ReporteID: $reporteID");
      // Obtener la referencia de la colección
      CollectionReference reportesCollection = FirebaseFirestore.instance.collection('Reporte');

      // Realizar una consulta para encontrar el documento con el reporteID específico
      QuerySnapshot querySnapshot = await reportesCollection.where('reporteID', isEqualTo: reporteID).get();

      print("Documentos encontrados: ${querySnapshot.docs.length}");

      // Verificar que se encontró al menos un documento
      if (querySnapshot.docs.isNotEmpty) {
        // Obtener la referencia del primer documento encontrado
        DocumentReference reporteRef = querySnapshot.docs.first.reference;

        // Intentar la actualización
        await reporteRef.update({
          'resenas': FieldValue.arrayUnion([resena])
        });

        print("Reseña agregada exitosamente.");
      } else {
        print("No se encontró el reporte con el ID especificado.");
      }
    } catch (e) {
      print("Error al agregar reseña: $e");
    }
  }
}

// Modelo: maneja la informacion del reporte.
class ReportModel {
  String description;
  String emisorName;
  String address;
  String? problemType;
  Position? currentPosition;
  bool isLocationAvailable;
  int reporteID;
  String fecha;
  String Latitud;
  String Longitud;
  List imageUrls;
  List<String> resenas;

  ReportModel({
    required this.description,
    required this.emisorName,
    required this.address,
    this.problemType,
    this.currentPosition,
    required this.isLocationAvailable,
    this.reporteID = 0,
    this.fecha = '',
    this.Latitud = '',
    this.Longitud = '',
    this.imageUrls = const [],
    this.resenas = const [],
  });

  Map<String, dynamic> toFirestore(List<String> imageUrls) {
    return {
      'Latitud': currentPosition?.latitude.toString() ?? 'Sin ubicación',
      'Longitud': currentPosition?.longitude.toString() ?? 'Sin ubicación',
      'Descripcion': description,
      'Fecha': DateTime.now().toString(),
      'NombreEmisor': emisorName,
      'reporteID': DateTime.now().millisecondsSinceEpoch,
      'tipoProblema': problemType,
      'imageUrls': imageUrls, // Lista de URLs de las imágenes
      'resenas': resenas,
    };
  }
}

class obtenerReportes {
  final int reporteID;
  final String tipoProblema;
  final String descripcion;
  final DateTime fecha;
  final List<String> imageUrls;
  final String nombreEmisor;
  final String latitud;
  final String longitud;
  final String? direccion;
  final List<String>? resenas;

  obtenerReportes({
    required this.reporteID,
    required this.tipoProblema,
    required this.descripcion,
    required this.fecha,
    required this.imageUrls,
    required this.nombreEmisor,
    required this.latitud,
    required this.longitud,
    this.direccion,
    this.resenas,
  });

  // Método para crear una instancia de Reporte a partir de los datos de Firebase

  factory obtenerReportes.fromFirestore(Map<String, dynamic> data) {
    return obtenerReportes(
      reporteID: data['reporteID'] ?? 0,
      tipoProblema: data['tipoProblema'] ?? 'Desconocido',
      descripcion: data['Descripcion'] ?? '',
      fecha: DateTime.parse(data['Fecha']),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      nombreEmisor: data['NombreEmisor'] ?? '',
      latitud: data['Latitud'] ?? '',
      longitud: data['Longitud'] ?? '',
      resenas: List<String>.from(data['resenas'] ?? []),
    );
  }

  //Implementación de copyWith para crear una copia del reporte con valores modificados
  obtenerReportes copyWith({
    int? reporteID,
    String? tipoProblema,
    String? descripcion,
    DateTime? fecha,
    List<String>? imageUrls,
    String? nombreEmisor,
    String? latitud,
    String? longitud,
    String? direccion,
    List<String>? resenas,
  }) {
    return obtenerReportes(
      reporteID: reporteID ?? this.reporteID,
      tipoProblema: tipoProblema ?? this.tipoProblema,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      imageUrls: imageUrls ?? this.imageUrls,
      nombreEmisor: nombreEmisor ?? this.nombreEmisor,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccion: direccion ?? this.direccion,
      resenas: resenas ?? this.resenas,
    );
  }
}

class NotificacionesModel {
  double latitud;
  double longitud;

  NotificacionesModel({required this.latitud, required this.longitud});

  // Constructor para crear un NotificacionesModel desde un documento de Firestore
  factory NotificacionesModel.fromFirestore(DocumentSnapshot doc) {
    return NotificacionesModel(
      latitud: double.parse(doc['Latitud'] ?? '0.0'),
      longitud: double.parse(doc['Longitud'] ?? '0.0'),
    );
  }

  // Método estático para obtener todas las zonas oscuras desde Firestore
  static Future<List<NotificacionesModel>> obtenerZonasOscuras() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('Reporte').get();
    return snapshot.docs.map((doc) => NotificacionesModel.fromFirestore(doc)).toList();
  }
}
