// registro_view.dart
import 'package:flutter/material.dart';
import '../controladores/login_controlador.dart';
import '../views/ui_login.dart';

class RegistroView extends StatefulWidget {
  const RegistroView({super.key});

  @override
  _RegistroViewState createState() => _RegistroViewState();
}

class _RegistroViewState extends State<RegistroView> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final RegistroController _controller = RegistroController();

  void _registrar() async {
    final nombre = _nombreController.text;
    final telefonoText = _telefonoController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validamos que el teléfono sea un número entero
    int? telefono = int.tryParse(telefonoText);
    if (telefono == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("El teléfono debe ser un número válido")));
      return;
    }

    String? mensajeError = await _controller.registrarUsuario(nombre, telefono, password, confirmPassword);
    if (mensajeError == null) {
      // Registro exitoso
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginView()));
    } else {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensajeError)));
    }
  }

  Widget verRegistro(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            Image.asset(
              'assets/images/Logo.png',
              height: 100,
              fit: BoxFit.contain,
            ),
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Contraseña'),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirmar Contraseña'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registrar,
              child: Text('Registrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginView()));
              },
              child: Text('¿Ya tienes una cuenta? Inicia sesión'),
            ),
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: verRegistro(context), // Llama al método verRegistro
    );
  }
}
