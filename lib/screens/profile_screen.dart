import 'dart:convert'; // NUEVO: Para convertir la imagen a texto
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _lastPeriodController = TextEditingController();
  
  String _profileImageUrl = '';
  bool _isLoading = true;
  bool _isSaving = false;
  
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    if (_user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_user.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _emailController.text = doc['email'] ?? '';
          _ageController.text = doc['age']?.toString() ?? '';
          _lastPeriodController.text = doc['last_period_date'] ?? '';
          _profileImageUrl = doc['profile_image'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
        context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now(),
        builder: (context, child) => Theme(data: ThemeData.light().copyWith(primaryColor: const Color(0xFFF472B6)), child: child!)
    );
    if (picked != null) setState(() => _lastPeriodController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  void _updateProfile() async {
    if (_nameController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nombre mínimo 6 letras"), backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text) ?? 20,
      'last_period_date': _lastPeriodController.text,
    });
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil actualizado"), backgroundColor: Colors.green));
  }

  // TRUCO DE INGENIERÍA: Convertir imagen a Base64 y guardarla en Firestore
  void _pickAndUploadImage() async {
    // Pedimos la imagen con baja calidad para que el texto generado no sea tan pesado
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 25, 
      maxWidth: 400,
    );
    
    if (pickedFile != null) {
      setState(() => _isSaving = true);
      try {
        // Leemos los bytes de la foto y los pasamos a texto
        final bytes = await pickedFile.readAsBytes();
        final String base64Image = base64Encode(bytes);
        
        // Guardamos el texto en Firestore (Nos saltamos Firebase Storage)
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'profile_image': base64Image
        });
        
        setState(() => _profileImageUrl = base64Image);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al procesar la imagen"), backgroundColor: Colors.redAccent));
      }
      setState(() => _isSaving = false);
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  // Descodificador para mostrar la imagen en pantalla
  ImageProvider? _getAvatarImage() {
    if (_profileImageUrl.isEmpty) return null;
    if (_profileImageUrl.startsWith('http')) return NetworkImage(_profileImageUrl); // Por si quedó una URL vieja
    try {
      return MemoryImage(base64Decode(_profileImageUrl));
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Mi Perfil", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage, 
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFFCE7F3),
                    backgroundImage: _getAvatarImage(),
                    child: _profileImageUrl.isEmpty ? const Icon(Icons.camera_alt, size: 40, color: Color(0xFFF472B6)) : null,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField("Nombre (Mín 6 Letras)", _nameController, true), 
                const SizedBox(height: 15),
                _buildTextField("Correo Electrónico", _emailController, false), 
                const SizedBox(height: 15),
                _buildTextField("Edad", _ageController, true), 
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _lastPeriodController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: InputDecoration(
                    labelText: "Día de la Última Regla", 
                    prefixIcon: const Icon(Icons.date_range, color: Color(0xFFF472B6)), 
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF472B6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text("Guardar Cambios", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          ),
          if (_isSaving) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF472B6))))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, bool enabled) {
    return TextField(
      controller: ctrl,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label, filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}