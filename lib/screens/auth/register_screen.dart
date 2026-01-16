import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

// Warna Tema PNP (Politeknik Negeri Padang)
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpAccentYellow = Color(0xFFFFC107);

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controller untuk setiap field input
  final _nameCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _jurusanCtrl = TextEditingController(); // Field Baru: Jurusan
  final _prodiCtrl = TextEditingController();   // Field Baru: Prodi
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  // Logika Role Mahasiswa
  String _selectedRole = 'pembeli';
  final List<String> _roles = ['pembeli', 'penjual'];

  bool _isLoading = false;

  // Fungsi untuk memproses registrasi
  void _register() async {
    // Validasi: Memastikan semua field termasuk Jurusan & Prodi telah diisi
    if (_nameCtrl.text.isEmpty ||
        _nimCtrl.text.isEmpty ||
        _jurusanCtrl.text.isEmpty ||
        _prodiCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Semua data wajib diisi!"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isLoading = true);

    // Memanggil AuthService untuk mengirim data ke backend Java/Spring Boot
    // Pastikan fungsi register di AuthService.dart sudah Anda update parameternya
    bool success = await AuthService().register(
        _nameCtrl.text,
        _nimCtrl.text,
        _jurusanCtrl.text, // Parameter Baru
        _prodiCtrl.text,   // Parameter Baru
        _emailCtrl.text,
        _passCtrl.text,
        _selectedRole
    );

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context); // Kembali ke halaman Login
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registrasi Berhasil! Silakan Login."), backgroundColor: Colors.green)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal Register. Pastikan Backend Java aktif."), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buat Akun Baru", style: TextStyle(fontWeight: FontWeight.bold)),
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
            // Header Visual
            Icon(Icons.app_registration_rounded, size: 70, color: pnpAccentYellow),
            SizedBox(height: 10),
            Text("Gabung Campus Market",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
            Text("Lengkapi data diri mahasiswa Anda", style: TextStyle(color: Colors.grey[600])),
            SizedBox(height: 30),

            // Form Input Card
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildTextField(_nameCtrl, "Nama Lengkap", Icons.person_outline),
                    SizedBox(height: 16),

                    _buildTextField(_nimCtrl, "NIM / No. BP", Icons.badge_outlined, isNumber: true),
                    SizedBox(height: 16),

                    // Input Jurusan (Disesuaikan dengan tabel pgAdmin)
                    _buildTextField(_jurusanCtrl, "Jurusan", Icons.account_balance_outlined),
                    SizedBox(height: 16),

                    // Input Prodi (Disesuaikan dengan tabel pgAdmin)
                    _buildTextField(_prodiCtrl, "Program Studi", Icons.school_outlined),
                    SizedBox(height: 16),

                    _buildTextField(_emailCtrl, "Email", Icons.email_outlined, isEmail: true),
                    SizedBox(height: 16),

                    // Dropdown Pilihan Role
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: "Daftar Sebagai",
                        prefixIcon: Icon(Icons.people_alt_outlined, color: pnpPrimaryBlue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role == 'penjual' ? 'Penjual (Mahasiswa)' : 'Pembeli (Mahasiswa)'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    SizedBox(height: 16),

                    _buildTextField(_passCtrl, "Password", Icons.lock_outline, isPassword: true),
                    SizedBox(height: 30),

                    // Tombol Aksi Registrasi
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pnpPrimaryBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("DAFTAR SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey[700])),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text("Login di sini", style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget: TextField Generator untuk konsistensi UI
  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon,
      {bool isPassword = false, bool isEmail = false, bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: pnpPrimaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}