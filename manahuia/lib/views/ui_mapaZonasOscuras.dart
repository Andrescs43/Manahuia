import 'package:flutter/material.dart';
import 'package:manahuia/controladores/notificaciones_controlador.dart';
import 'package:manahuia/models/reporte_model.dart';
import 'UIListaCE.dart';
import 'ui_reporte.dart';
import '../controladores/mapa_controlador.dart';
import 'package:permission_handler/permission_handler.dart'
    as PermissionHandler;
import 'package:cached_network_image/cached_network_image.dart';
import '../controladores/login_controlador.dart';


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
      const UiReporte(),
      MapaZonaTab(controlador: _controlador), // Pasar controlador aquí
      const ListaCETab(),
    ]);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manahuia'),
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () async {
            // Llama al controlador para cerrar la sesión
            await LoginController().cerrarSesion();
            // Redirige a la pantalla de inicio de sesión
            Navigator.pushReplacementNamed(context, '/');
          },
          tooltip: 'Cerrar sesión',
        ),
      ],
    ),
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

  final NotificacionesControl notificacionesControl = NotificacionesControl();

  @override
  void initState() {
    super.initState();
    notificacionesControl.iniciarNotificaciones(); // Iniciar notificaciones
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
class _verListadoReportes extends StatelessWidget {
  final MapaControlador reportesController = MapaControlador();

  @override
  Widget build(BuildContext context) {
    final MapaControlador mapasController = MapaControlador();

    return Scaffold(
      appBar: AppBar(title: const Text("Lista de Reportes")),
      body: StreamBuilder<List<obtenerReportes>>(
        stream: mapasController.solicitarReportes(),
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

  // Método para mostrar la pantalla con detalles
  void _mostrarDetalles(BuildContext context, obtenerReportes reporte) {
  final TextEditingController resenaController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          var fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} ${reporte.fecha.hour}:${reporte.fecha.minute}";
          if (reporte.fecha.day < 10) fechaFormateada = "0$fechaFormateada";
          if (reporte.fecha.minute < 10) fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} ${reporte.fecha.hour}:0${reporte.fecha.minute}";
          if (reporte.fecha.hour < 10) fechaFormateada = "${reporte.fecha.day}/${reporte.fecha.month}/${reporte.fecha.year} 0${reporte.fecha.hour}:${reporte.fecha.minute}";

          return AlertDialog(
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reporte.imageUrls.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: reporte.imageUrls.map((imageUrl) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _ImageFullscreen(imageUrl: imageUrl),
                                  ),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error, size: 100),
                                  width: 120,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Reporte: ${reporte.tipoProblema}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Descripción: ${reporte.descripcion}",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Fecha: $fechaFormateada",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Ubicación: ${reporte.direccion ?? 'Ubicación no disponible'}",
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Emisor: ${reporte.nombreEmisor}",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const Text("Reseñas", style: TextStyle(fontWeight: FontWeight.bold)),
                  if (reporte.resenas!.isNotEmpty)
                    SizedBox(
                      height: 200,
                      child: SingleChildScrollView(
                        child: Column(
                          children: reporte.resenas!.map((resena) {
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(resena),
                                ),
                                const Divider(),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  else
                    const Text("No hay reseñas disponibles"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: resenaController,
                    decoration: const InputDecoration(
                      labelText: 'Añadir reseña',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final textoResena = resenaController.text.trim();
                        if (textoResena.isNotEmpty) {
                          await reportesController.agregarResena(reporte, textoResena);
                          setState(() {
                            // Actualiza la lista local de reseñas
                            reporte.resenas!.add(textoResena);
                          });
                          resenaController.clear();
                        }
                      },
                      child: const Text('Enviar Reseña'),
                    ),
                  ),
                ],
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
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            width: MediaQuery.of(context).size.width,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error, size: 100),
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
