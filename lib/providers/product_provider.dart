import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  // READ
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await ProductService().getProducts();

    _isLoading = false;
    notifyListeners();
  }

  // CREATE
  Future<bool> addProduct(Product product) async {
    bool success = await ProductService().addProduct(product);
    if (success) await fetchProducts(); // Refresh data otomatis
    return success;
  }

  // UPDATE
  Future<bool> updateProduct(String id, Product product) async {
    bool success = await ProductService().updateProduct(id, product);
    if (success) await fetchProducts();
    return success;
  }

  // DELETE
  Future<bool> deleteProduct(String id) async {
    bool success = await ProductService().deleteProduct(id);
    if (success) {
      _products.removeWhere((p) => p.id == id); // Hapus lokal biar cepat
      notifyListeners();
    }
    return success;
  }
}