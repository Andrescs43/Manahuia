import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manahuia/views/listaContactos.dart';
import 'package:manahuia/views/ui_reporte.dart';

void main() {
  runApp(const UIMapaZonasOscuras());
}

class UIMapaZonasOscuras extends StatefulWidget {
  const UIMapaZonasOscuras({super.key});

  @override
  _UIMapaZonasState createState() => _UIMapaZonasState();
}

class _UIMapaZonasState extends State<UIMapaZonasOscuras> {
  int _currentIndex = 0;

  // Lista de las diferentes vistas que cambiarán en función de la pestaña seleccionada
  final List<Widget> _pages = [
    const ReportForm(),  // Página 1
    const MapaZonaTab(),                   // Página 2 con el mapa
    const ListaCETab(), // Página 3 
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Manahuia'),
        ),
        body: _pages[_currentIndex], // Cambia el cuerpo según la pestaña seleccionada
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex, // Indica la pestaña seleccionada
          onTap: (int index) {
            setState(() {
              _currentIndex = index; // Cambia la página al hacer clic en una pestaña
            });
          },
          showUnselectedLabels: false, // Ocultar el label del ítem no seleccionado
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment), // Icono de la pestaña
              label: 'Reporte', // Label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.place),    // Icono de la pestaña
              label: 'Mapa', // Label
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts), // Icono de la pestaña
              label: 'Contactos', // Label
            ),
          ],
        ),
      ),
    );
  }
}

class MapaZonaTab extends StatefulWidget {
  const MapaZonaTab({super.key});

  @override
  _MapaZonaTabState createState() => _MapaZonaTabState();
}

class _MapaZonaTabState extends State<MapaZonaTab> {
  late GoogleMapController mapController;
  final locationController = Location();
  BitmapDescriptor? uazonIcon;
  BitmapDescriptor? customIcon;
  LatLng? currentPosition;
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;

  final LatLng _center = const LatLng(22.73897, -102.66891); // Coordenadas de ejemplo (Zacatecas)
  final Set<Marker> _markers = {}; // Conjunto para los marcadores

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> fetchLocationUpdates() async {
    _serviceEnabled = await locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await locationController.requestPermission();
    }

    if (_permissionGranted == PermissionStatus.granted) {
      locationController.onLocationChanged.listen((currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          setState(() {
            currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          });
        }
      });
    }
  }

  Future<void> loadCustomMarkerIcon() async {
    uazonIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(24, 24)),
      'assets/images/circulo.png',
    );
  }

  Future<void> loadFirestoreMarkers() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/zona.png',
    );
    QuerySnapshot querySnapshot = await firestore.collection('Reporte').get();

    for (var doc in querySnapshot.docs) {
      double lat = double.parse(doc['Latitud']);
      double lon = double.parse(doc['Longitud']);

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lon),
            icon: customIcon!, // Usar el icono personalizado para los marcadores de Firestore
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCustomMarkerIcon(); // Cargar el icono personalizado
      await fetchLocationUpdates();
      await loadFirestoreMarkers(); // Cargar los marcadores de Firestore
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: currentPosition!,
              zoom: 11.0,
            ),
            markers: _markers.union({
              Marker(
                markerId: const MarkerId('currentPosition'),
                icon: uazonIcon ?? BitmapDescriptor.defaultMarker, // Usar el icono cargado
                position: currentPosition!,
              ),
            }),
          );
  }
}
