import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../controladores/reporte_controlador.dart';
import '../models/reporte_model.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  _ReportFormState createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final _formKey = GlobalKey<FormState>();
  final ReportModel reportModel = ReportModel(
    description: '',
    streetName: '',
    address: 'Obteniendo dirección...',
    isLocationAvailable: false,
  );
  late ReportController reportController;
  bool _isDropdownError = false;

  final List<String> items = ['Alumbrado Dañado', 'Sin Alumbrado'];

  @override
  void initState() {
    super.initState();
    reportController = ReportController(reportModel);
    reportController.getCurrentLocation().then((_) => setState(() {}));
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
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  labelText: 'Nombre del emisor',
                  hintText: 'Ejemplo: Juan Pérez López',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Por favor ingresa el nombre del emisor' : null,
                onSaved: (value) => reportModel.streetName = value ?? '',
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
                        await reportController.sendReport();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte enviado')));
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
}
