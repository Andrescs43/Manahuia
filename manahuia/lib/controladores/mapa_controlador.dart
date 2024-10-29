import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:manahuia/models/reporte_model.dart';

class MapaControlador {
  final ReporteModel _reporteModel = ReporteModel();
  late GoogleMapController _mapController;
  final loc.Location _locationController = loc.Location();
  BitmapDescriptor? uazonIcon;
  BitmapDescriptor? customIcon;
  LatLng? currentPosition;
  bool _serviceEnabled = false;
  loc.PermissionStatus _permissionGranted = loc.PermissionStatus.denied;
  final Set<Marker> _markers = {};
  final CollectionReference _reportesCollection = FirebaseFirestore.instance.collection('Reporte');

  Future<void> inicializarMapa(
      BuildContext context, Function actualizarVista) async {
    await _cargarIconos();
    await _actualizarUbicacion();
    await _cargarMarcadores(actualizarVista);
  }

  Future<void> _cargarIconos() async {
    uazonIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(24, 24)),
        'assets/images/circulo.png');
    customIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)), 'assets/images/zona.png');
  }

  Future<void> _actualizarUbicacion() async {
    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
    }

    if (_permissionGranted == loc.PermissionStatus.granted) {
      _locationController.onLocationChanged.listen((currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null) {
          currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        }
      });
    }
  }

  Future<void> _cargarMarcadores(Function actualizarVista) async {
    List<Map<String, dynamic>> zonasOscuras =
        await _reporteModel.obtenerZonasOscuras();
    for (var zona in zonasOscuras) {
      _markers.add(
        Marker(
          markerId: MarkerId(zona['id']),
          position: LatLng(zona['latitud'], zona['longitud']),
          icon: customIcon!,
        ),
      );
    }
    actualizarVista();
  }

  // Método para obtener un Stream de reportes, ordenados por fecha
  Stream<List<ObtenerReportes>> obtenerReportes() {
    return _reportesCollection
        .orderBy('Fecha', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          // Mapea cada documento en un Future para agregar la dirección
          var reportes = await Future.wait(snapshot.docs.map((doc) async {
            var reporte = ObtenerReportes.fromFirestore(doc.data() as Map<String, dynamic>);
            // Obtener la dirección a partir de la latitud y longitud
            var direccion = await _obtenerDireccion(reporte.latitud, reporte.longitud);
            return reporte.copyWith(direccion: direccion); // copia el reporte con la dirección
          }));
          return reportes;
        });
        //.map((snapshot) => snapshot.docs.map((doc) => ObtenerReportes.fromFirestore(doc.data() as Map<String, dynamic>)).toList());
  }

  // Método para obtener la dirección a partir de latitud y longitud
  Future<String> _obtenerDireccion(String lat, String lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(double.parse(lat), double.parse(lon));
      Placemark place = placemarks.first;
      return "${place.street}, ${place.locality}, ${place.country}";
    } catch (e) {
      return "Ubicación no disponible";
    }
  }

  Widget obtenerVistaMapa() {
    if (!_serviceEnabled || _permissionGranted == loc.PermissionStatus.denied) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('La ubicación no está habilitada.'),
            SizedBox(height: 16),
          ],
        ),
      );
    }

    return currentPosition == null
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition:
                CameraPosition(target: currentPosition!, zoom: 11.0),
            markers: _markers.union({
              Marker(
                markerId: const MarkerId('currentPosition'),
                icon: uazonIcon ?? BitmapDescriptor.defaultMarker,
                position: currentPosition!,
              ),
            }),
          );
  }
}
