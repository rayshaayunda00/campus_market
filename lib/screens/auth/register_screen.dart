import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

// Warna Tema PNP
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpAccentYellow = Color(0xFFFFC107);

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller
  final _nameCtrl = TextEditingController();
  final _nimCtrl = TextEditingController(); // Controller NIM Baru
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Role Logic
  String _selectedRole = 'pembeli';
  final List<String> _roles = ['pembeli', 'penjual'];

  bool _isLoading = false;

  void _register() async {
    // Validasi Form
    if (_nameCtrl.text.isEmpty || _nimCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Semua data wajib diisi!")));
      return;
    }

    setState(() => _isLoading = true);

    // Panggil Auth Service dengan NIM & Role
    bool success = await AuthService().register(
        _nameCtrl.text,
        _nimCtrl.text,
        _emailCtrl.text,
        _passCtrl.text,
        _selectedRole
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context); // Balik ke Login
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrasi Berhasil! Silakan Login."), backgroundColor: Colors.green)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Register. Cek koneksi."), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buat Akun Baru"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: pnpPrimaryBlue,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.app_registration, size: 60, color: pnpAccentYellow),
            SizedBox(height: 10),
            Text("Gabung Campus Market", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
            Text("Lengkapi data diri mahasiswa Anda", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 30),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // 1. Nama
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Nama Lengkap",
                        prefixIcon: Icon(Icons.person_outline, color: pnpPrimaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 15),

                    // 2. NIM (Input Baru)
                    TextField(
                      controller: _nimCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "NIM / No. BP",
                        prefixIcon: Icon(Icons.badge_outlined, color: pnpPrimaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 15),

                    // 3. Email
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email Kampus",
                        prefixIcon: Icon(Icons.email_outlined, color: pnpPrimaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 15),

                    // 4. Role (Dropdown Baru)
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: "Daftar Sebagai",
                        prefixIcon: Icon(Icons.people_alt_outlined, color: pnpPrimaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(
                            role == 'penjual' ? 'Penjual (Mahasiswa)' : 'Pembeli (Mahasiswa)',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    SizedBox(height: 15),

                    // 5. Password
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock_outline, color: pnpPrimaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 30),

                    // Tombol Register
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pnpPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("DAFTAR SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey[700])),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text("Login di sini", style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}