import 'package:flutter/material.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.shopping_bag, size: 40, color: Colors.blue),
        title: Text(product.namaProduk, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Rp ${product.harga}"),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}