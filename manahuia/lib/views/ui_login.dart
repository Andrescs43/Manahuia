// login_view.dart
import 'package:flutter/material.dart';
import '../views/ui_registro.dart';
import '../controladores/login_controlador.dart';

class LoginView extends StatelessWidget {
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginController _controller = LoginController();

  void _iniciarSesion(BuildContext context) async {
    final telefonoText = _telefonoController.text;
    final password = _passwordController.text;

    // Convertimos el teléfono a int
    int? telefono = int.tryParse(telefonoText);
    if (telefono == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("El teléfono debe ser un número válido")));
      return;
    }

    bool? mensajeError = await _controller.iniciarSesion(telefono, password);
    if (mensajeError) {
      // Sesión iniciada correctamente
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de inicio de sesion')));
    }
  }

  Widget verLogin(BuildContext context) {
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
              controller: _telefonoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Contraseña'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _iniciarSesion(context),
              child: Text('Iniciar Sesión'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegistroView()));
              },
              child: Text('¿No tienes una cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inicio de Sesión')),
      body: verLogin(context), // Llama al método verLogin
    );
  }
}
