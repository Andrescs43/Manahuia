import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:manahuia/models/reporte_model.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/trabajadorModelo.dart';

class MapaControlador {
  final ReporteModel _reporteModel = ReporteModel();
  final ContactosModelo _contactosModelo = ContactosModelo();
  late GoogleMapController _mapController;
  final loc.Location _locationController = loc.Location();
  BitmapDescriptor? uazonIcon;
  BitmapDescriptor? customIcon;
  BitmapDescriptor? bienIcon;
  BitmapDescriptor? malIcon;
  LatLng? currentPosition;
  bool _serviceEnabled = false;
  loc.PermissionStatus _permissionGranted = loc.PermissionStatus.denied;
  final Set<Marker> _markers = {};
  bool showCustomInfoWindow = false;
  LatLng customInfoWindowPosition = LatLng(0, 0);
  String customInfoWindowTitle = '';
  String customInfoWindowDescription = '';
  final CollectionReference _reportesCollection = FirebaseFirestore.instance.collection('Reporte');

  Future<void> inicializarMapa(
      BuildContext context, Function actualizarVista) async {
    await _cargarIconos();
    await _actualizarUbicacion();
    await _cargarMarcadores(actualizarVista, context);
  }

  Future<void> _cargarIconos() async {
    uazonIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(24, 24)), 'assets/images/circulo.png');
    customIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(48, 48)), 'assets/images/zona.png');
    bienIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(24, 24)), 'assets/images/bien.png');
    malIcon = await BitmapDescriptor.asset(const ImageConfiguration(size: Size(24, 24)), 'assets/images/mal.png');
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

  // Función para mostrar el BottomSheet con el diseño personalizado
void mostrarDetallesEstado(BuildContext context, String nombre, String estado, String mensaje) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nombre,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Estado: $estado',
                style: TextStyle(
                  fontSize: 16,
                  color: estado == 'Bien' ? Colors.green : Colors.red,
                ),
            ),
            SizedBox(height: 8),
            Text(
              'Mensaje: $mensaje',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Acción del botón si se necesita
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFB9BDCF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _cargarMarcadores(Function actualizarVista, BuildContext context) async {
  // Cargar zonas oscuras
  List<Map<String, dynamic>> zonasOscuras = await _reporteModel.obtenerZonasOscuras();
  _markers.clear();
  for (var zona in zonasOscuras) {
    _markers.add(
      Marker(
        markerId: MarkerId(zona['id']),
        position: LatLng(zona['latitud'], zona['longitud']),
        icon: customIcon!,
      ),
    );
  }

  // Cargar contactos desde el modelo de contactos
  _contactosModelo.cargarContactos();
  List<Contact> contactos = _contactosModelo.obtenerContactos();
  for (var contacto in contactos) {
    String? telefono = contacto.phones.isNotEmpty ? contacto.phones.first.number : null;

    if (telefono != null) {
      // Eliminar el prefijo +52 del número
      telefono = telefono.replaceFirst('+52', '').replaceAll(' ', '');

      print("Buscando estado para el teléfono: $telefono");

      // Obtener estado y nombre desde Firebase usando el teléfono como identificador
      String? estado = await _contactosModelo.obtenerEstado(telefono);

      //Obtener mesnaje desde firebase usando el teléfono como identificador
      String? mensaje = await _contactosModelo.obtenerMensaje(telefono);

      if (estado != null) {
        print("Estado obtenido para $telefono: $estado");

        // Obtener latitud y longitud desde Firebase usando el teléfono como ID
        String? latitud = await _contactosModelo.obtenerCampo(telefono, 'Latitud');
        String? longitud = await _contactosModelo.obtenerCampo(telefono, 'Longitud');

        if (latitud != null && longitud != null) {
          print("Ubicación obtenida para $telefono - Latitud: $latitud, Longitud: $longitud");

          LatLng posicionContacto = LatLng(double.parse(latitud), double.parse(longitud));

          // Selección de ícono basado en el estado
          BitmapDescriptor iconoEstado = (estado == 'Bien')
              ? bienIcon!  // Ícono para "Bien"
              : malIcon!;  // Ícono para "Mal"
          String nombreContacto = contacto.displayName;
          _markers.add(
            Marker(
              markerId: MarkerId(contacto.id),
              position: posicionContacto,
              icon: iconoEstado,
              onTap: () => mostrarDetallesEstado(context, nombreContacto, estado, mensaje!),
            ),
          );


          print("Marcador agregado para $telefono en la posición $posicionContacto");
        } else {
          print("Latitud o longitud no disponible para $telefono");
        }
      } else {
        print("No se encontró el estado para el teléfono: $telefono");
      }
    } else {
      print("Contacto sin teléfono válido");
    }
  }

  actualizarVista();
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

Stream<List<obtenerReportes>> solicitarReportes() {
    return _reportesCollection
        .orderBy('Fecha', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          //Mapea cada documento en un Future para agregar la dirección
          var reportes = await Future.wait(snapshot.docs.map((doc) async {
            var reporte = obtenerReportes.fromFirestore(doc.data() as Map<String, dynamic>);
            //Obtener la dirección a partir de la latitud y longitud
            var direccion = await _obtenerDireccion(reporte.latitud, reporte.longitud);
            return reporte.copyWith(direccion: direccion); //Copia el reporte con la dirección
          }));
          return reportes;
        });
        //.map((snapshot) => snapshot.docs.map((doc) => ObtenerReportes.fromFirestore(doc.data() as Map<String, dynamic>)).toList());
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
            initialCameraPosition: CameraPosition(target: currentPosition!, zoom: 17.0),
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
