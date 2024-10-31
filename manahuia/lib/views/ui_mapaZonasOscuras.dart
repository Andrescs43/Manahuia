import 'package:flutter/material.dart';
import 'UIListaCE.dart';
import 'ui_reporte.dart';
import '../controladores/mapa_controlador.dart';
import 'package:permission_handler/permission_handler.dart' as PermissionHandler;

class ManahuiaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UIMapaZonasOscuras(),
    );
  }
}

class UIMapaZonasOscuras extends StatefulWidget {
  const UIMapaZonasOscuras({super.key});

  @override
  _UIMapaZonasState createState() => _UIMapaZonasState();
}

class _UIMapaZonasState extends State<UIMapaZonasOscuras> {
  final MapaControlador _controlador = MapaControlador();
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const ReportForm(),
      MapaZonaTab(controlador: _controlador), // Pasar controlador aquí
      const ListaCETab(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manahuia')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Reporte',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.place),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contactos',
          ),
        ],
      ),
    );
  }
}

class MapaZonaTab extends StatefulWidget {
  final MapaControlador controlador; // Recibe el controlador

  const MapaZonaTab({super.key, required this.controlador}); // Constructor

  @override
  _MapaZonaTabState createState() => _MapaZonaTabState();
}

class _MapaZonaTabState extends State<MapaZonaTab> {
  @override
  void initState() {
    super.initState();
    widget.controlador.inicializarMapa(context, actualizarMapa);
    checkNotificationPermission();
  }

  // Verificar permisos de notificación
  Future<void> checkNotificationPermission() async {
    final status = await PermissionHandler.Permission.notification.status;
    if (!status.isGranted) {
      // Muestra un mensaje si el permiso sigue denegado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos de notificación están desactivados.')),
      );
    }
  }

  void actualizarMapa() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.controlador.obtenerVistaMapa(); // Muestra el mapa con los marcadores
  }
}
