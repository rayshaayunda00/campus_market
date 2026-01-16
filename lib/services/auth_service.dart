import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_services.dart';

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

  // 2. REGISTER (DIPERBAIKI: Menambahkan parameter Jurusan & Prodi)
  Future<bool> register(
      String nama,
      String nim,
      String jurusan, // Tambahkan ini
      String prodi,   // Tambahkan ini
      String email,
      String password,
      String role
      ) async {
    try {
      final url = Uri.parse('${ApiServices.baseUrlUser}/register');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": nama,
          "nim": nim,
          "jurusan": jurusan, // Kirim data Jurusan ke Backend
          "prodi": prodi,     // Kirim data Prodi ke Backend
          "email": email,
          "password": password,
          "role": role
        }),
      );

      // Mengembalikan true jika status code 200 (OK) atau 201 (Created)
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }
}