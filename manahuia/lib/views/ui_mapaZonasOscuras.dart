import 'package:flutter/material.dart';
import 'package:manahuia/models/reporte_model.dart';
import 'UIListaCE.dart';
import 'ui_reporte.dart';
import '../controladores/mapa_controlador.dart';
import 'package:permission_handler/permission_handler.dart'
    as PermissionHandler;

class ManahuiaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        const SnackBar(
            content: Text('Permisos de notificación están desactivados.')),
      );
    }
  }

  void actualizarMapa() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.controlador.obtenerVistaMapa(),
        Positioned(
          top: 20,
          right: 20,
          child: Tooltip(
            message: 'Ver listado de reportes',
            textStyle: const TextStyle(fontSize: 16, color: Colors.white),
            padding: const EdgeInsets.all(8),
            child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _verListadoReportes(),
                ),
              );
            },
            child: const Icon(Icons.list_alt),
          ),
          )
        ),
      ],
    );
  }
}

//Clase para ver el listado de reportes
//Clase para ver el listado de reportes
class _verListadoReportes extends StatelessWidget {
  final MapaControlador reportesController = MapaControlador();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Reportes")),
      body: StreamBuilder<List<obtenerReportes>>(
        stream: reportesController.solicitarReportes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) { //Muestra un indicador de carga
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) { //Si no hay datos muestra un mensaje
            return const Center(child: Text("No hay reportes disponibles"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var reporte = snapshot.data![index]; //Obtiene el reporte
              var fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} ${reporte.fecha.hour}:${reporte.fecha.minute}"; //Formatea la fecha

              if(reporte.fecha.day < 10){ //Agrega un 0 si el día es menor a 10
                fechaFormateada = "0$fechaFormateada";
              }
              if (reporte.fecha.minute < 10) { //Agrega un 0 si los minutos son menores a 10
                fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} ${reporte.fecha.hour}:0${reporte.fecha.minute}";
              }
              if (reporte.fecha.hour < 10) { //Agrega un 0 si la hora es menor a 10
                fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} 0${reporte.fecha.hour}:${reporte.fecha.minute}";
              }

              return Card( //Muestra los datos del reporte
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    "Reporte: ${reporte.tipoProblema}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Descripción: ${reporte.descripcion}"),
                      Text("Fecha: $fechaFormateada"),
                    ],
                  ),
                    trailing: SingleChildScrollView( //Muestra un botón para ver detalles
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () => _mostrarDetalles(context, reporte),
                          ),
                          const Text(
                            'Ver Detalles',
                            style: TextStyle(fontSize: 6),
                          ),
                        ],
                      ),
                    ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Método para mostrar el diálogo con detalles
  void _mostrarDetalles(BuildContext context, obtenerReportes reporte) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        
        //Sirve para formatear la fecha y no mostrar datos innecesarios
        var fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} ${reporte.fecha.hour}:${reporte.fecha.minute}";
        if(reporte.fecha.day < 10){
          fechaFormateada = "0$fechaFormateada";
        }
        if (reporte.fecha.minute < 10) {
          fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} ${reporte.fecha.hour}:0${reporte.fecha.minute}";
        }
        if (reporte.fecha.hour < 10) {
          fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} 0${reporte.fecha.hour}:${reporte.fecha.minute}";
        }

        print(reporte.imageUrls);
        //Muestra un diálogo con los detalles del reporte
        return AlertDialog(
          title: const Text('Detalles del Reporte'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 400, // Puedes ajustar la altura máxima según sea necesario
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reporte.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: reporte.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _ImageFullscreen(imageUrl: reporte.imageUrls[index]),
                                ),
                              ),
                              child: Image.network(
                                reporte.imageUrls[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null 
                                            ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1) 
                                            : null));
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, size: 100);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text("Reporte: ${reporte.tipoProblema}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("Descripción: ${reporte.descripcion}"),
                  const SizedBox(height: 4),
                  Text("Fecha: $fechaFormateada"),
                  const SizedBox(height: 4),
                  Text("Ubicación: ${reporte.direccion ?? 'Ubicación no disponible'}"),
                  const SizedBox(height: 4),
                  Text("Emisor: ${reporte.nombreEmisor}"),
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CERRAR'),
            ),
          ],
        );
      },
    );
  }
}

class _ImageFullscreen extends StatelessWidget {
  final String imageUrl;

  const _ImageFullscreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            width: MediaQuery.of(context).size.width,
          ),
        ),
      ),
    );
  }
}

// La función main debe estar aquí
void main() {
  runApp(ManahuiaApp());
}
