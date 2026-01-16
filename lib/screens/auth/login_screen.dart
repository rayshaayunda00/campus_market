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

    var data = await AuthService().login(_emailCtrl.text, _passCtrl.text);

    setState(() => _isLoading = false);

    if (data != null) {
      // Pastikan User Model menerima data dari backend Java/PostgreSQL
      User user = User(
          id: data['id'],
          nama: data['nama'],
          nim: data['nim'] ?? '-',
          email: data['email'],
          role: data['role']
      );

      Provider.of<UserProvider>(context, listen: false).setUser(user);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Gagal! Cek koneksi User Service."), backgroundColor: Colors.red)
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
            // Header Biru dengan Judul Baru
            Container(
              height: 280, // Ukuran ditambah sedikit agar judul muat
              width: double.infinity,
              decoration: BoxDecoration(
                  color: pnpPrimaryBlue,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(60)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
                  ]
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_rounded, size: 60, color: pnpAccentYellow),
                    SizedBox(height: 15),
                    Text(
                        "Campus Market",
                        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text(
                        "Platform Jual-Beli Barang Bekas\nKhusus Mahasiswa", // JUDUL DITAMBAHKAN DISINI
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.5),
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: pnpAccentYellow, borderRadius: BorderRadius.circular(20)),
                      child: Text("Politeknik Negeri Padang", style: TextStyle(color: pnpPrimaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 35),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Selamat Datang!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
                  Text("Gunakan akun SSO/Email Kampus Anda", style: TextStyle(color: Colors.grey[600])),
                  SizedBox(height: 30),

                  // Input Email
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email",
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
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("MASUK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Belum punya akun? ", style: TextStyle(color: Colors.grey[700])),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                        child: Text("Daftar Sekarang", style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
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