import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _lastPeriodDateController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
      } else {
        UserCredential user = await _auth.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());
        if (user.user != null) {
          await _firestore.collection('users').doc(user.user!.uid).set({
            'uid': user.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'age': int.parse(_ageController.text.trim()),
            'last_period_date': _lastPeriodDateController.text, 
            'profile_image': '',
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
    } on FirebaseAuthException catch (e) {
      String msg = "Ocurrió un error.";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') msg = "Credenciales incorrectas.";
      if (e.code == 'email-already-in-use') msg = "Este correo ya está registrado.";
      _showError(msg);
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(),
        builder: (context, child) => Theme(data: ThemeData.light().copyWith(primaryColor: const Color(0xFFF472B6)), child: child!)
    );
    if (picked != null) setState(() => _lastPeriodDateController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF1F2), Colors.white])),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 15),
                      const Center(child: Text("FemClock Pro", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                      const SizedBox(height: 30),
                      
                      if (!_isLogin) _buildField("Nombre Completo (Mín 6 letras)", _nameController, Icons.person_outline, false),
                      if (!_isLogin) const SizedBox(height: 16),
                      _buildField("Correo (Mín 6 caracteres antes del @)", _emailController, Icons.email_outlined, false),
                      const SizedBox(height: 16),
                      _buildField("Contraseña (Mín 6)", _passwordController, Icons.lock_outline, true),
                      const SizedBox(height: 16),
                      
                      if (!_isLogin) Row(
                        children: [
                          Expanded(child: _buildField("Edad", _ageController, Icons.calendar_today_outlined, false)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _lastPeriodDateController, readOnly: true, onTap: () => _selectDate(context),
                              validator: (val) => val == null || val.isEmpty ? "Obligatorio" : null,
                              decoration: InputDecoration(labelText: "Última Regla", prefixIcon: const Icon(Icons.date_range_outlined, color: Color(0xFFF472B6)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 35),
                      
                      SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: _submitAuth,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF472B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: Text(_isLogin ? "Iniciar Sesión" : "Registrar Cuenta", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "¿No tienes cuenta? Regístrate aquí" : "¿Ya tienes cuenta? Inicia sesión", style: const TextStyle(color: Color(0xFFF472B6))))
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF472B6))))),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, bool pass) {
    List<TextInputFormatter>? formatters;
    if (label.contains("Nombre")) formatters = [FilteringTextInputFormatter.allow(RegExp("[a-zA-ZáéíóúÁÉÍÓÚñÑ ]"))];
    if (label.contains("Edad")) formatters = [FilteringTextInputFormatter.digitsOnly];

    return TextFormField(
      controller: ctrl, obscureText: pass, inputFormatters: formatters,
      validator: (val) {
        if (val == null || val.isEmpty) return "Obligatorio";
        
        // VALIDACIÓN ESTRICTA (6 Letras mínimo)
        if (label.contains("Nombre") && val.trim().length < 6) return "Mínimo 6 letras";
        
        // VALIDACIÓN ESTRICTA CORREO (6 caracteres antes de @gmail.com)
        if (label.contains("Correo")) {
          if (!val.contains('@')) return "Falta el @";
          String preArroba = val.split('@')[0];
          if (preArroba.length < 6) return "Mínimo 6 caracteres antes del @";
          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val)) return "Formato inválido";
        }

        if (label.contains("Contraseña") && val.length < 6) return "Mínimo 6 caracteres";
        if (label.contains("Edad")) {
          int? edad = int.tryParse(val);
          if (edad == null || edad < 10 || edad > 100) return "Rango 10-100";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, color: const Color(0xFFF472B6)), filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFF472B6), width: 1.5)),
      ),
    );
  }
}