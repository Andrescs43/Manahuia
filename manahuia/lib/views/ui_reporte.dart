import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Para convertir latitud y longitud a una dirección
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  _ReportFormState createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  String _streetName = '';
  String _address = 'Obteniendo dirección...'; // Se llenará automáticamente
  String? selectedValue;
  bool _isDropdownError = false;

  final List<String> items = ['Alumbrado Dañado', 'Sin Alumbrado'];

  Position? _currentPosition; // Para almacenar la ubicación actual (latitud y longitud)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Llamar para obtener la ubicación al iniciar
  }

  // Método para obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El servicio de ubicación está deshabilitado')),
      );
      return;
    }

    // Verificar permisos de ubicación
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los permisos de ubicación están permanentemente denegados')),
      );
      return;
    }

    // Obtener la ubicación actual
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
    });

    // Convertir latitud y longitud en dirección
    await _getAddressFromLatLng(position);
  }

  // Método para convertir latitud y longitud en dirección
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      Placemark place = placemarks[0];
      setState(() {
        _address = '${place.street}, ${place.locality}, ${place.country}';
      });
    } catch (e) {
      setState(() {
        _address = 'No se pudo obtener la dirección';
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo para el nombre del emisor
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  labelText: 'Nombre del emisor',
                  hintText: 'Ejemplo: Juan Pérez López',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del emisor';
                  } 
                  return null;
                },
                onSaved: (value) {
                  _streetName = value ?? '';
                },
              ),

              // Campo para la dirección (rellenado automáticamente)
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  labelText: 'Dirección',
                  hintText: _address,
                ),
              ),

              // Dropdown para el tipo de problema
              const SizedBox(height: 16),
              DropdownButtonHideUnderline(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton2<String>(
                      isExpanded: true,
                      hint: const Text('Selecciona el tipo de problema'),
                      items: items.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      value: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value;
                          _isDropdownError = false;
                        });
                      },
                    ),
                    if (_isDropdownError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Por favor selecciona el tipo de problema',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                  ],
                ),
              ),

              // Campo para la descripción
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  labelText: 'Descripción',
                  hintText: 'Describe el problema',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value ?? '';
                },
              ),

              // Botón para enviar el reporte
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE8E8E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      if (selectedValue == null) {
                        _isDropdownError = true;
                      }
                    });

                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      int reporteID = DateTime.now().millisecondsSinceEpoch;
                      FirebaseFirestore.instance.collection('Reporte').add({
                        'Latitud': _currentPosition?.latitude.toString() ?? 'Sin ubicación',
                        'Longitud': _currentPosition?.longitude.toString() ?? 'Sin ubicación',
                        'Descripcion': _description,
                        'Fecha': DateTime.now().toString(),
                        'NombreEmisor': _streetName,
                        'reporteID': reporteID,
                        'tipoProblema': selectedValue,
                      }).then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reporte enviado')),
                        );
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error al enviar reporte: $error')),
                        );
                      });
                    }
                  },
                  child: const Text('Enviar Reporte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
