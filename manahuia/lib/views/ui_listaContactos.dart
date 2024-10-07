import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // Clase para manejar los contactos de flutter
import 'package:manahuia/views/ui_mapaZonasOscuras.dart'; //Clase de las zonas oscuras.
import 'package:permission_handler/permission_handler.dart'; //Maneja permisos del dispositivo.
import 'package:shared_preferences/shared_preferences.dart'; //Guarda las listas de contactos en el dispositivo.
import 'dart:convert'; //Convierte a JSON

void main() {
  runApp(const UIListaContactosEmergencia());
}

class UIListaContactosEmergencia extends StatefulWidget {
  const UIListaContactosEmergencia({super.key});
  
  @override
  _UIListaContactosEmergencia createState() => _UIListaContactosEmergencia();
}

//Clase externa que permite obtener la lista de contactos cuando sea necesaria.
class ContactosService {

  //Metodo que permite agregar contactos a la lista interna
  void agregarContacto(Contact contacto) {
    if (!contactos.contains(contacto)){
      contactos.add(contacto);
      String name = contacto.displayName;
      guardarContactos();
      print("Contacto agregada a la clase de servicio de contactos: "+name+" \ntotal de contactos:"+contactos.length.toString());
    } else {
      print("El contacto ya esta en la lista");
    }
  }

  // Método para guardar los contactos en SharedPreferences y encodificar a formato JSON.
  Future<void> guardarContactos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); //obtener las instancias
    List<String> contactosJson = contactos.map((contacto) => jsonEncode(contacto.toJson())).toList();
    await prefs.setStringList('contactos', contactosJson);
  }

  // Método para cargar los contactos guardados
  Future<void> cargarContactos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? contactosJson = prefs.getStringList('contactos');
    if (contactosJson != null) {
      contactos = contactosJson.map((contactoStr) => Contact.fromJson(jsonDecode(contactoStr))).toList();
    }
  }
  
  //Metodo que permite obtener la lista de contactos cuando se necesite.
  List<Contact> obtenerContactos() {
    print("Contactos devueltos>> ");
    print(contactos.length);
    return contactos;
  }
}

class _UIListaContactosEmergencia extends State<UIListaContactosEmergencia> {
  int _currentIndex = 0;
  late ContactosService contactosService = ContactosService();
  List <Contact> contactos = [];
  // Lista de las diferentes vistas que cambiarán en función de la pestaña seleccionada
  final List<Widget> _pages = [
    const Icon(Icons.assignment, size: 150), // Página 1
    const MapaZonaTab(),   // Página 2 (actual con el reporte)
    const ListaCETab(),   // Página 3 del reporte
  ];

//funcion que obtiene la lista de contactos
 Future <Contact?> obtenContacto() async {
    try {
      // Pedir permiso
      var permissionStatus = await Permission.contacts.status;
      await Permission.contacts.request();
      if (!permissionStatus.isGranted) { //si NO se permite acceder a los contactos
            muestraDialogoPermiso(context);
        } else { //si se permite acceder a los contactos
            final contacto = await FlutterContacts.openExternalPick();
            if (contacto != null){ //el usuario elije un contacto
              String nombreContacto = contacto.displayName;
              contactosService.agregarContacto(contacto); //invoca a la clase de la lista de contactos para agregar a un usuraio nuevo
              contactos = contactosService.obtenerContactos();
              print("Guardado el contacto de "+nombreContacto);
              String total = contactos.length.toString();
              print("Contactos totales en la lista de UI: "+total);
              return contacto;
            } else { //si el usuario no ingresa un contacto
              muestraDialogoNoSeleccionado(context);
              return null;
            }
        } 
      //setState(() => _contactos = contactos);
    } catch (e) {
      print("No se pudo seleccionar un contacto ($e)");
      return null;
    }
  }

  List<Contact> obtenerListaContactos() {
    return contactosService.obtenerContactos();
  }

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


Future<void> _printContactsList() async {
  int n = 1;
  for (var contacto in contactos) {
    String name = contacto.displayName;
    print("Contacto #"+n.toString()+": "+name);
    n = n+1;
  }
}

int numeroContactos()  {
  int n = 1;
  for (var contacto in contactos) {
    n = n+1;
  }
  return n;
}

 /** Abre un cuadro de dialogo informando que no se han concedido permisos de contactos.
  */
  Future<void> muestraDialogoPermiso(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aviso'),
          content: const Text(
            'Para poder crear tu lista de contactos\n'
                'de emergencia son necesarios los\n'
                'permisos para leer tus contactos.\n'
                '\nPor favor, ve a Configuracion > Aplicaciones > Manahuia > Permisos > Contactos > Permitir :)\n',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    }

 /** Abre un cuadro de dialogo informando que no se ha seleccionado un contacto.
  */
    Future<void> muestraDialogoNoSeleccionado(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Advertencia'),
          content: const Text(
            'Ningun contacto fue seleccionado.\n',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    }
}

//crea el widget de estados
class ListaCETab extends StatefulWidget {
  const ListaCETab({super.key});

  @override
  _ListaCETabState createState() => _ListaCETabState();
}

ContactosService contactosService = ContactosService();
List<Contact> contactos = [];
//muestra la pestana en la vista de navegacion
class _ListaCETabState extends State<ListaCETab> {
  final _UIListaContactosEmergencia uiListaCE = _UIListaContactosEmergencia();
  
  bool isLoading = true; // Bandera para mostrar estado de carga

  @override
  void initState() {
    super.initState();
    // Cargar contactos al iniciar la pantalla
    cargarContactos();
  }

Future<void> cargarContactos() async {
    await contactosService.cargarContactos();
    setState(() {
      contactos = contactosService.obtenerContactos();
      isLoading = false;
    });
  }

  // Método para obtener los contactos y actualizar la lista
  /*
  void cargarContactos() async {
    final nuevosContactos = await contactosService.obtenerContactos();
    setState(() {
      contactos = uiListaCE.obtenerListaContactos();
      isLoading = false;
    });
  }
  */

  // Método para agregar un contacto nuevo
  void agregarContactoNuevo() async{
    final nuevoContacto = await uiListaCE.obtenContacto(); // Llama al método para agregar un contacto de la clase uiListaCE y espera a que se seleccione
    contactosService.cargarContactos();
    if (nuevoContacto != null) {
      // Si se seleccionó un contacto válido, refrescamos la lista
      cargarContactos();
    }// Refrescar la lista después de agregar un contacto
  }

  Future<void> verContacto(Contact contacto) async {
    await FlutterContacts.openExternalView(contacto.id);
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar indicador de carga mientras se obtienen los contactos


    // Si no hay contactos, mostrar un mensaje
    if (contactos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No hay contactos guardados.\n¿Por qué no empiezas agregando uno?\n(Pulsa el botón '+')"),
            IconButton(
              onPressed: agregarContactoNuevo,
              icon: Icon(Icons.add),
              iconSize: 50,
            )
          ],
        ),
      );
    }

    // Construir la lista de contactos
    return Stack(
    children: [
      ListView.builder(
        itemCount: contactos.length,
        itemBuilder: (context, index) {
          final Contact contacto = contactos[index];
          return Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.all(15),
            height: 130,
            color: const Color.fromARGB(255, 183, 182, 182),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                contacto.displayName+"\n",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
            ElevatedButton(
                onPressed: () {
                  // Acción que quieres ejecutar al presionar el botón
                  verContacto(contacto);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 83, 83, 83), // Color del botón
                ),
                child: Row(
                      mainAxisSize: MainAxisSize.min, // Ajusta el tamaño de la fila al contenido
                      children: [
                        Icon(
                          Icons.phone, // Aquí puedes poner el ícono que prefieras
                          color: Colors.white, // Color del ícono
                        ),
                        const SizedBox(width: 5), // Espacio entre el ícono y el texto
                        const Text(
                          "Ver Contacto",
                          style: TextStyle(color: Colors.white), // Estilo del texto
                        ),
                      ],
                    ),
            )
            ],
          )
          );
        },
      ),
      // Botón en la esquina superior izquierda
    Positioned(
      top: -5, // Ajusta la posición vertical
      left: -5, // Ajusta la posición horizontal
      child: IconButton(
        iconSize: 50,
        onPressed: agregarContactoNuevo,
        icon: Icon(Icons.add),
      ),
    ),
    ]
    );
  }
}
