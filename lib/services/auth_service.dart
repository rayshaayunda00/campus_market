import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_services.dart'; // Pastikan path ini benar sesuai struktur foldermu

class AuthService {

  // 1. LOGIN
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiServices.baseUrlUser}/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Login Error: $e");
    }
    return null;
  }

  // 2. REGISTER (Update dengan NIM & Role)
  Future<bool> register(String nama, String nim, String email, String password, String role) async {
    try {
      final url = Uri.parse('${ApiServices.baseUrlUser}/register');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": nama,
          "nim": nim,         // Kirim NIM
          "email": email,
          "password": password,
          "role": role        // Kirim Role (penjual/pembeli)
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }
}