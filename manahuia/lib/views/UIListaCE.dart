import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:manahuia/controladores/ControladorListaCE.dart';

class ListaCETab extends StatefulWidget {
  const ListaCETab({super.key});

  @override
  _ListaCETabState createState() => _ListaCETabState();
}

class _ListaCETabState extends State<ListaCETab> {
  final ControladorListaCE contactosController = ControladorListaCE();
  bool isLoading = true;

  // Variables de estado para el mensaje y el color
  Color mensajeColor = Colors.black;
  String mensajeTexto = "Dile a tus contactos cómo estás:";
  Color botonColorBien = Colors.black;
  Color botonColorMal = Colors.black;

  @override
  void initState() {
    super.initState();
    cargarContactos();
  }

  Future<void> cargarContactos() async {
    await contactosController.contactosService.cargarContactos();
    setState(() {
      isLoading = false;
    });
  }

  void agregarContactoNuevo() async {
    final nuevoContacto = await contactosController.obtenContacto();
    if (nuevoContacto != null) {
      cargarContactos();
    }
  }

  void mostrarDialogoBorrar(Contact contacto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar contacto"),
        content: Text("¿Estás seguro de que deseas eliminar este contacto?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              contactosController.borraContacto(contacto);
              cargarContactos();
              Navigator.pop(context);
            },
            child: Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void verContacto(Contact contacto) async {
    await FlutterContacts.openExternalView(contacto.id);
  }

 //cambia colores de la interfaz
  void actualizarEstado(bool estoyBien) {
    setState(() {
      if (estoyBien) {
        mensajeColor = Colors.green;
        mensajeTexto = "Tus contactos verán que estás bien";
        botonColorBien = Colors.green;
        botonColorMal = Colors.black;
      } else {
        mensajeColor = Colors.red;
        mensajeTexto =
            "Notificaremos a tus contactos que te encuentras mal.\nPonte en contacto con ellos lo más rápido posible.";
        botonColorBien = Colors.black;
        botonColorMal = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactos = contactosController.obtenerListaContactos();
    return Scaffold(
      body: Stack(
        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : contactos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "No hay contactos guardados.\n¿Por qué no empiezas agregando uno?\n¡Pulsa el botón '+'!\n(Recuerda haber activado el permiso\npara acceder a tus contactos).",
                            textAlign: TextAlign.center,
                          ),
                          IconButton(
                            onPressed: agregarContactoNuevo,
                            icon: Icon(Icons.add),
                            iconSize: 50,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: contactos.length,
                            itemBuilder: (context, index) {
                              final Contact contacto = contactos[index];
                              return Stack(
                                children: [
                                  Container(
                                    alignment: Alignment.center,
                                    margin: const EdgeInsets.all(15),
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 183, 182, 182),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color.fromARGB(255, 63, 63, 63),
                                        width: 3,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          contacto.displayName + "\n",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            verContacto(contacto);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(255, 83, 83, 83),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.phone,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                "Ver Contacto",
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 8,
                                    child: IconButton(
                                      onPressed: () {
                                        mostrarDialogoBorrar(contacto);
                                      },
                                      icon: const Icon(Icons.cancel_outlined),
                                      color: const Color.fromARGB(255, 137, 10, 1),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Sección de mensaje de estado
                        Container(
                          color: mensajeColor,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              mensajeTexto,
                              style: TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // Botones de estado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.thumb_up_alt_outlined),
                                  color: botonColorBien,
                                  onPressed: () => actualizarEstado(true),
                                ),
                                const Text("Estoy bien", style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.thumb_down_alt_outlined),
                                  color: botonColorMal,
                                  onPressed: () => actualizarEstado(false),
                                ),
                                const Text("Estoy mal", style: TextStyle(fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
          // Botón de agregar contacto en la esquina superior derecha
          Positioned(
            top: 5,
            left: 5,
            child: IconButton(
              iconSize: 50,
              onPressed: agregarContactoNuevo,
              icon: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
