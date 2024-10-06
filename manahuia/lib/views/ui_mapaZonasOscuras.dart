import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    const Icon(Icons.assignment, size: 150), // Página 1
    const MapaZonaTab(),                     // Página 2 con el mapa
    const Icon(Icons.contacts, size: 150),   // Página 3
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
              label: 'Reporte', // Label vacío
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.place),    // Icono de la pestaña
              label: 'Mapa', // Label vacío
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts), // Icono de la pestaña
              label: 'Contactos', // Label vacío
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

  LatLng? currentPosition;
  final LatLng _center = const LatLng(22.73897, -102.66891); // Coordenadas de ejemplo (Zacatecas)
  final Set<Marker> _markers = {}; // Conjunto para los marcadores

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> fetchLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    locationController.onLocationChanged.listen((currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        print(currentPosition);
      }
    });
  }

  Future<void> fetchMarkersFromFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('Reporte').get(); // Cambia 'tu_coleccion' por el nombre de tu colección

    for (var doc in querySnapshot.docs) {
      double lat = double.parse(doc['Latitud']); // Convierte la cadena a double
      double lon = double.parse(doc['Longitud']); // Convierte la cadena a double

      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lon),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await fetchLocationUpdates();
      await fetchMarkersFromFirestore(); // Cargar marcadores de Firestore
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: currentPosition == null
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
              icon: BitmapDescriptor.defaultMarker,
              position: currentPosition!,
            ),
          }),
        ),
  );
}
