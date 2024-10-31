import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';


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
}
// Modelo: maneja la informacion del reporte.
class ReportModel {
  String description;
  String emisorName;
  String address;
  String? problemType;
  Position? currentPosition;
  bool isLocationAvailable;

  ReportModel({
    required this.description,
    required this.emisorName,
    required this.address,
    this.problemType,
    this.currentPosition,
    required this.isLocationAvailable,
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
    };
  }
}

class obtenerReportes {
  final String tipoProblema;
  final String descripcion;
  final DateTime fecha;
  final List<String> imageUrls;
  final String nombreEmisor;
  final String latitud;
  final String longitud;
  final String? direccion;

  obtenerReportes({
    required this.tipoProblema,
    required this.descripcion,
    required this.fecha,
    required this.imageUrls,
    required this.nombreEmisor,
    required this.latitud,
    required this.longitud,
    this.direccion,
  });

  // Método para crear una instancia de Reporte a partir de los datos de Firebase

  factory obtenerReportes.fromFirestore(Map<String, dynamic> data) {
    return obtenerReportes(
      tipoProblema: data['tipoProblema'] ?? 'Desconocido',
      descripcion: data['Descripcion'] ?? '',
      fecha: DateTime.parse(data['Fecha']),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      nombreEmisor: data['NombreEmisor'] ?? '',
      latitud: data['Latitud'] ?? '',
      longitud: data['Longitud'] ?? '',
    );
  }

  //Implementación de copyWith para crear una copia del reporte con valores modificados
  obtenerReportes copyWith({
    String? tipoProblema,
    String? descripcion,
    DateTime? fecha,
    List<String>? imageUrls,
    String? nombreEmisor,
    String? latitud,
    String? longitud,
    String? direccion,
  }) {
    return obtenerReportes(
      tipoProblema: tipoProblema ?? this.tipoProblema,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      imageUrls: imageUrls ?? this.imageUrls,
      nombreEmisor: nombreEmisor ?? this.nombreEmisor,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      direccion: direccion ?? this.direccion,
    );
  }
}
