import 'dart:convert';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Untuk XFile

import '../api/api_services.dart';
import '../models/product_model.dart';

class ProductService {

  // 1. GET ALL PRODUCTS
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('${ApiServices.baseUrlProduct}/products'));

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        print("Gagal ambil data: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Get Products Error: $e");
      return [];
    }
  }

  // 2. CREATE PRODUCT (Kirim data JSON dengan URL gambar)
  Future<bool> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiServices.baseUrlProduct}/products'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "namaProduk": product.namaProduk,
          "harga": product.harga,
          "deskripsi": product.deskripsi,
          "sellerId": product.sellerId,
          "lamaPakai": "Baru",
          "gambar": product.gambar, // List String URL
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Add Product Error: $e");
      return false;
    }
  }

  // 3. UPDATE PRODUCT
  Future<bool> updateProduct(String id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiServices.baseUrlProduct}/products/$id'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "namaProduk": product.namaProduk,
          "harga": product.harga,
          "deskripsi": product.deskripsi,
          "gambar": product.gambar,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Update Product Error: $e");
      return false;
    }
  }

  // 4. DELETE PRODUCT
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiServices.baseUrlProduct}/products/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print("Delete Product Error: $e");
      return false;
    }
  }

  // === 5. UPLOAD IMAGE (SUPORT WEB & MOBILE) ===
  Future<String?> uploadImage(XFile image) async {
    try {
      var uri = Uri.parse('${ApiServices.baseUrlProduct}/products/upload');

      var request = http.MultipartRequest('POST', uri);

      http.MultipartFile multipartFile;

      if (kIsWeb) {
        // LOGIKA UNTUK WEB: Kirim Bytes
        var bytes = await image.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: image.name
        );
      } else {
        // LOGIKA UNTUK HP: Kirim Path
        multipartFile = await http.MultipartFile.fromPath('image', image.path);
      }

      request.files.add(multipartFile);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        return jsonResponse['url'];
      } else {
        print("Upload Failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error Upload: $e");
      return null;
    }
  }
}