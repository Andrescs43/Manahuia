import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reporte_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

class ReportController {
  final ReportModel reportModel;
  ReportController(this.reportModel);

  // Obtener la ubicación actual
  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    reportModel.currentPosition = position;
    reportModel.isLocationAvailable = true;
    await getAddressFromLatLng(position);
  }

  // Obtener la dirección a partir de la latitud y longitud
  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      reportModel.address = '${place.street}, ${place.locality}, ${place.country}';
    } catch (e) {
      reportModel.address = 'No se pudo obtener la dirección';
    }
  }

  //Agregar imagenes al reporte
  Future<List<String>> uploadImages(List<File> images) async {
    List<String> imageUrls = [];
    for (File image in images) {
      // Lee la imagen como bytes
      final bytes = await image.readAsBytes();

      // Decodifica la imagen original
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        // Define el nuevo alto máximo
        int maxHeight = 200;

        // Calcula el nuevo ancho manteniendo la relación de aspecto
        int newWidth = (originalImage.width * maxHeight) ~/ originalImage.height; // El operador ~/ divide y redondea hacia abajo

        // Redimensiona la imagen
        img.Image resizedImage = img.copyResize(originalImage, width: newWidth, height: maxHeight);

        // Codifica la imagen comprimida con calidad ajustada
        final compressedBytes = img.encodeJpg(resizedImage, quality: 90); //Imagen con una calidad al 90%

        // Guarda la imagen comprimida temporalmente
        final compressedImageFile = File(image.path)..writeAsBytesSync(compressedBytes);

        // Sube la imagen comprimida
        String fileName = 'evidences/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = storageRef.putFile(compressedImageFile);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  //Enviar reporte
  Future<void> sendReport(List<File> images) async {
    List<String> imageUrls = images.isNotEmpty ? await uploadImages(images) : [];
    await FirebaseFirestore.instance.collection('Reporte').add(reportModel.toFirestore(imageUrls));
  }
}
