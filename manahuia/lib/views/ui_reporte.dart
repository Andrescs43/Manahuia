import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../controladores/reporte_controlador.dart';
import '../models/reporte_model.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class UiReporte extends StatefulWidget {
  const UiReporte({super.key});

  @override
  _UiReporteState createState() => _UiReporteState();
}

class _UiReporteState extends State<UiReporte> {
  final _formKey = GlobalKey<FormState>();
  final ReportModel reportModel = ReportModel(
    description: '',
    emisorName: '',
    address: 'Obteniendo dirección...',
    isLocationAvailable: false,
  );
  late ReporteControlador reportController;
  bool _isDropdownError = false;

  final List<String> items = ['Alumbrado Dañado', 'Sin Alumbrado'];
  List<File> selectedImages = []; // Lista de imágenes seleccionadas

  @override
  void initState() {
    super.initState();
    reportController = ReporteControlador(reportModel);
    reportController.getCurrentLocation().then((_) => setState(() {})); // Obtener la ubicación actual
  }

  //Metodo para abrir la camara y tomar la evidencia fotografica
  Future<void> _tomarImagen(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, preferredCameraDevice: CameraDevice.rear,); //Camara trasera
      if (image != null) {
        setState(() {
          selectedImages.add(File(image.path));
        });
      }
  }

  // Método para limpiar el formulario
  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    reportModel.problemType = null;
    reportModel.description = '';
    selectedImages.clear();
    setState(() {
      _isDropdownError = false;
    });
  }

  // Método para construir el formulario de reporte
  Widget verFormularioReporte() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  labelText: 'Nombre del emisor',
                  hintText: 'Ejemplo: Juan Pérez López',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa el nombre del emisor' : null,
                onSaved: (value) => reportModel.emisorName = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  labelText: reportModel.address,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonHideUnderline(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Text('Selecciona el tipo de problema'),
                        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                        value: reportModel.problemType,
                        onChanged: (value) => setState(() {
                          reportModel.problemType = value;
                          _isDropdownError = false;
                        }),
                      ),
                      if (_isDropdownError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('Por favor selecciona el tipo de problema', style: TextStyle(color: Colors.red.shade700)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  labelText: 'Descripción',
                  hintText: 'Describe el problema',
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa una descripción' : null,
                onSaved: (value) => reportModel.description = value ?? '',
              ),

              // Botón subir imagenes
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    //backgroundColor: const Color(0xFFDE8E8E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  onPressed: () => _tomarImagen(ImageSource.camera),
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Subir Evidencia (Opcional)'),
                ),
              ),

              // Mostrar imágenes seleccionadas
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: selectedImages
                    .map((image) => Image.file(image, width: 80, height: 80, fit: BoxFit.cover))
                    .toList(),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDE8E8E),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: reportModel.isLocationAvailable ? () async {
                    setState(() {
                      if (reportModel.problemType == null) _isDropdownError = true;
                    });
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      try {
                        await reportController.enviaReporte(selectedImages);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado')));
                        _limpiarFormulario(); // Limpiar formulario después de enviar
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar reporte: $error')));
                      }
                    }
                  } : null,
                  child: const Text('Enviar Reporte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return verFormularioReporte();
  }
}
