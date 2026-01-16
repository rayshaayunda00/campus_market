import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_services.dart';
import '../models/cart_model.dart';

class OrderService {

  // 1. AMBIL DATA KERANJANG
  Future<List<CartItem>> getCart(int userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiServices.baseUrlCart}/cart/$userId'));

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => CartItem.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error Get Cart: $e");
      return [];
    }
  }

  // 2. TAMBAH KE KERANJANG
  // Menggunakan snake_case agar sinkron dengan Struct Cart di Golang
  // TAMBAHKAN PARAMETER GAMBAR DI AKHIR
  Future<Map<String, dynamic>?> addToCart(int userId, String productId, int sellerId, String nama, int harga, String gambar) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiServices.baseUrlCart}/cart'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "buyer_id": userId,
          "product_id": productId,
          "seller_id": sellerId,
          "nama_produk": nama,
          "harga": harga.toDouble(),
          "lama_pakai": "Baru",
          "gambar": gambar, // Sekarang gambar dikirim ke backend
          "deskripsi": ""
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print("Error Add to Cart: $e");
      return null;
    }
  }
  // 3. CHECKOUT
  // Backend Go menggunakan Path Param: /checkout/:buyerId
  Future<bool> checkout(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiServices.baseUrlCart}/checkout/$userId'),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Checkout: $e");
      return false;
    }
  }

  // 4. RIWAYAT PESANAN & UPDATE STATUS
  Future<List<dynamic>> getMyOrders(String userId) async {
    try {
      final response = await http.get(Uri.parse('${ApiServices.baseUrlCart}/orders/$userId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orders'] ?? [];
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getIncomingOrders(String sellerId) async {
    try {
      final response = await http.get(Uri.parse('${ApiServices.baseUrlCart}/seller-orders/$sellerId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orders'] ?? [];
      }
      return [];
    } catch (e) { return []; }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiServices.baseUrlCart}/orders/$orderId/status'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> deleteCartItem(int cartId) async {
    try {
      final response = await http.delete(Uri.parse('${ApiServices.baseUrlCart}/cart/$cartId'));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}