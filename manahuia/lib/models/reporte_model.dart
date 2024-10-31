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
