import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../models/reporte_model.dart';

class MapaControlador {
  final ReporteModel _reporteModel = ReporteModel();
  late GoogleMapController _mapController;
  final Location _locationController = Location();
  BitmapDescriptor? uazonIcon;
  BitmapDescriptor? customIcon;
  LatLng? currentPosition;
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;
  final Set<Marker> _markers = {};

  Future<void> inicializarMapa(BuildContext context, Function actualizarVista) async {
    await _cargarIconos();
    await _actualizarUbicacion();
    await _cargarMarcadores(actualizarVista);
  }

  Future<void> _cargarIconos() async {
    uazonIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(24, 24)),'assets/images/circulo.png');
    customIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(48, 48)),'assets/images/zona.png');
  }

  Future<void> _actualizarUbicacion() async {
    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
    }

    if (_permissionGranted == PermissionStatus.granted) {
      _locationController.onLocationChanged.listen((currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        }
      });
    }
  }

  Future<void> _cargarMarcadores(Function actualizarVista) async {
    List<Map<String, dynamic>> zonasOscuras = await _reporteModel.obtenerZonasOscuras();
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

    Widget obtenerVistaMapa() {
      if (!_serviceEnabled || _permissionGranted == PermissionStatus.denied) {
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
              initialCameraPosition: CameraPosition(target: currentPosition!, zoom: 11.0),
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
