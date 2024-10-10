import 'package:flutter/material.dart';
import 'package:manahuia/views/listaContactos.dart';
import 'package:manahuia/views/ui_reporte.dart';
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
    const ReportForm(),                      // Página 1 con el formulario
    const MapaZonaTab(),                     // Página 2 con el mapa
    const ListaCETab(),   // Página 3
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
  BitmapDescriptor? uazonIcon;
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

  Future<BitmapDescriptor> getCustomIcon() async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)), // Tamaño del ícono
      'assets/images/zona.png', // Ruta de la imagen en assets
    );
  }

  Future<void> loadCustomMarkerIcon() async {
    uazonIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/uazon.png',
    );
  }

  Future<void> fetchMarkersFromFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    BitmapDescriptor customIcon = await getCustomIcon();
    QuerySnapshot querySnapshot = await firestore.collection('Reporte').get();

    for (var doc in querySnapshot.docs) {
      double lat = double.parse(doc['Latitud']); // Convierte la cadena a double
      double lon = double.parse(doc['Longitud']); // Convierte la cadena a double

      _markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(lat, lon),
          icon: customIcon,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadCustomMarkerIcon(); // Cargar el icono aquí
      await fetchLocationUpdates();
      await fetchMarkersFromFirestore(); // Cargar marcadores de Firestore
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar un loader mientras se carga el icono
    if (uazonIcon == null || currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: currentPosition!,
        zoom: 11.0,
      ),
      markers: _markers.union({
        Marker(
          markerId: const MarkerId('currentPosition'),
          icon: uazonIcon!, // Ya que el icono se ha cargado, lo usamos
          position: currentPosition!,
        ),
      }),
    );
  }
}
