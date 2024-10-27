import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reporte_model.dart';

class ReportController {
  final ReportModel reportModel;
  ReportController(this.reportModel);

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

  Future<void> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      reportModel.address = '${place.street}, ${place.locality}, ${place.country}';
    } catch (e) {
      reportModel.address = 'No se pudo obtener la dirección';
    }
  }

  Future<void> sendReport() async {
    await FirebaseFirestore.instance.collection('Reporte').add(reportModel.toFirestore());
  }
}
