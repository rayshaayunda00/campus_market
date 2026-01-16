import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

// Warna Tema PNP
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpAccentYellow = Color(0xFFFFC107);

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Email dan Password harus diisi")));
      return;
    }

    setState(() => _isLoading = true);

    // Panggil Service Login
    var data = await AuthService().login(_emailCtrl.text, _passCtrl.text);

    setState(() => _isLoading = false);

    if (data != null) {
      // Masukkan data ke User Model (Termasuk NIM)
      User user = User(
          id: data['id'],
          nama: data['nama'],
          nim: data['nim'] ?? '-', // Ambil NIM dari JSON response
          email: data['email'],
          role: data['role']
      );

      // Simpan ke Provider
      Provider.of<UserProvider>(context, listen: false).setUser(user);

      // Pindah ke Halaman Utama
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Gagal! Cek Email/Password."), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Biru Melengkung
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: pnpPrimaryBlue,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 70, color: pnpAccentYellow),
                    SizedBox(height: 10),
                    Text("Campus Market", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text("Politeknik Negeri Padang", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40),

            // Form Login
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selamat Datang!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
                  Text("Silakan login untuk berbelanja atau berjualan", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 30),

                  // Input Email
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email Kampus",
                      prefixIcon: Icon(Icons.email_outlined, color: pnpPrimaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Input Password
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock_outline, color: pnpPrimaryBlue),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Tombol Login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pnpPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Belum punya akun? ", style: TextStyle(color: Colors.grey[700])),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                        child: Text("Daftar Sekarang", style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}