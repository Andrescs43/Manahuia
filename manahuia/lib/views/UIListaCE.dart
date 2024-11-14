import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../controladores/ControladorListaCE.dart';

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
  final _mensajeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    cargarContactos();
    cargarEstado();
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
void muestraCampoMensaje() {
  bool isError = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text("Escribe un mensaje de estado."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Escribe un texto a tus contactos para que sepan de ti:"),
              TextField(
                controller: _mensajeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: isError ? Colors.red : Colors.grey),
                  ),
                  labelText: 'Escribe un mensaje...',
                ),
              ),
              if (isError) // Si hay error, mostramos el mensaje
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Por favor, escribe un mensaje.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cerrar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(222, 142, 142, 1),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    int respuesta = contactosController.verificaVacio(_mensajeController.text.trim());
                    if (respuesta != 1) {
                      setState(() {
                        isError = true; // Activa el mensaje de error si el campo está vacío
                      });
                      print("Este es un texto vacío.");
                    } else {
                      enviaMensaje(_mensajeController.text);
                      Navigator.pop(context);
                      // Muestra un SnackBar de confirmación
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("¡Mensaje enviado! Tus contactos lo podrán ver."),
                          backgroundColor: Colors.grey,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text("Enviar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(142, 174, 222, 1),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/*
  Metodo encargado de mandar al controlador el mensaje para que lo verifique y sea enviado
*/
  void enviaMensaje(String mensaje){
    print("Obtuve el mensaje de: "+mensaje);
    contactosController.guardaMensaje(mensaje);
  }

  void verContacto(Contact contacto) async {
    await FlutterContacts.openExternalView(contacto.id);
  }

 //cambia colores de la interfaz
  void actualizarEstado(bool estoyBien) async {
    setState(() {
        if (estoyBien) {
        mensajeColor = Colors.green;
        mensajeTexto = "Tus contactos verán que estás bien";
        contactosController.actualizarEstado("Bien");
        botonColorBien = Colors.green;
        botonColorMal = Colors.black;
      }  else {
        mensajeColor = Colors.red;
        mensajeTexto =
            "Mostraremos a tus contactos que te encuentras mal.\nPonte en contacto con ellos lo más rápido posible.";
            contactosController.actualizarEstado("Mal");
        botonColorBien = Colors.black;
        botonColorMal = Colors.red;
      }
    });
  }

  //carga el estado desde el controlador
  Future<void> cargarEstado() async {
    await contactosController.cargarTelefonoYEstado();
    String estadoActual = contactosController.obtenerEstado();
    setState(() {
      if (estadoActual == "Bien") {
        mensajeColor = Colors.green;
        mensajeTexto = "Tus contactos verán que estás bien";
        botonColorBien = Colors.green;
        botonColorMal = Colors.black;
      } else if (estadoActual == "Mal") {
        mensajeColor = Colors.red;
        mensajeTexto =
            "Mostraremos a tus contactos que te encuentras mal.\nPonte en contacto con ellos lo más rápido posible.";
        botonColorBien = Colors.black;
        botonColorMal = Colors.red;
      } else {
        mensajeColor = Colors.black;
        mensajeTexto = "Dile a tus contactos cómo estás:";
        botonColorBien = Colors.black;
        botonColorMal = Colors.black;
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
                              style: TextStyle(color: Colors.white, fontSize: 11),
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
              iconSize: 40,
              onPressed: agregarContactoNuevo,
              icon: Icon(Icons.add),
            ),
          ),
          Positioned(
            top: 50,
            left: 5,
            child: IconButton(
              iconSize: 35,
              onPressed: (){ muestraCampoMensaje();}, //por definir
              icon: Icon(Icons.edit_square)
              )
            ),
        ],
      ),
    );
  }
}