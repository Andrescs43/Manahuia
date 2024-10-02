import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  final LatLng _center = const LatLng(22.73897, -102.66891); // Coordenadas de ejemplo (Zacatecas)

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
  );
  }
}