import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product_model.dart';
import 'add_edit_product_screen.dart';
import 'incoming_order_screen.dart'; // Pastikan file ini ada di folder yang sama atau sesuaikan path-nya

// Warna Tema PNP
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpAccentYellow = Color(0xFFFFC107);
const Color pnpBackground = Color(0xFFF5F7FA);
const Color pnpRed = Color(0xFFD32F2F);

class ManageProductScreen extends StatefulWidget {
  @override
  _ManageProductScreenState createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;
    final productProvider = Provider.of<ProductProvider>(context);

    // Filter produk milik penjual
    final myProducts = productProvider.products
        .where((prod) => prod.sellerId == user?.id.toString())
        .toList();

    return Scaffold(
      backgroundColor: pnpBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Kelola Toko", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
                "${myProducts.length} Produk Aktif",
                style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.normal)
            ),
          ],
        ),
        backgroundColor: pnpPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: productProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: pnpPrimaryBlue))
          : Column(
        children: [
          // === TOMBOL PESANAN MASUK (TAMBAHAN BARU) ===
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.list_alt, color: Colors.white),
              label: Text("Lihat Pesanan Masuk", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, // Warna oranye agar mencolok
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => IncomingOrderScreen()));
              },
            ),
          ),

          // === DAFTAR PRODUK ===
          Expanded(
            child: myProducts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: () => productProvider.fetchProducts(),
              color: pnpPrimaryBlue,
              child: ListView.separated(
                padding: EdgeInsets.all(16),
                itemCount: myProducts.length,
                separatorBuilder: (ctx, i) => SizedBox(height: 16),
                itemBuilder: (ctx, i) {
                  return _buildProductCard(context, myProducts[i]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: pnpAccentYellow,
        icon: Icon(Icons.add, color: pnpPrimaryBlue),
        label: Text("Tambah Produk", style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditProductScreen()));
        },
      ),
    );
  }

  // WIDGET: Tampilan Saat Produk Kosong
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Icon(Icons.storefront_outlined, size: 80, color: pnpPrimaryBlue.withOpacity(0.5)),
          ),
          SizedBox(height: 20),
          Text(
            "Belum Ada Barang",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          SizedBox(height: 8),
          Text(
            "Ayo mulai berjualan di Campus Market!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // WIDGET: Kartu Produk (Desain Baru)
  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          // Bagian Atas: Gambar & Info Utama
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Produk dengan Rounded Corner
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[100],
                    child: product.gambar.isNotEmpty
                        ? Image.network(product.gambar[0], fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => Icon(Icons.image_not_supported, color: Colors.grey))
                        : Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                SizedBox(width: 16),

                // Info Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.namaProduk,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Rp ${product.harga}",
                        style: TextStyle(fontSize: 15, color: pnpPrimaryBlue, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 8),
                      // Badge Status
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text("Tersedia", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Pemisah Tipis
          Divider(height: 1, color: Colors.grey[200]),

          // Bagian Bawah: Tombol Aksi (Edit & Hapus)
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AddEditProductScreen(product: product),
                    ));
                  },
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.grey[700]),
                        SizedBox(width: 8),
                        Text("Edit", style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey[200]), // Garis vertikal
              Expanded(
                child: InkWell(
                  onTap: () => _confirmDelete(context, product.id),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(16)),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: pnpRed),
                        SizedBox(width: 8),
                        Text("Hapus", style: TextStyle(color: pnpRed, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Hapus Produk?"),
        content: Text("Produk akan dihapus permanen dari toko Anda."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ProductProvider>(context, listen: false).deleteProduct(productId);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Produk berhasil dihapus")));
            },
            style: ElevatedButton.styleFrom(backgroundColor: pnpRed, foregroundColor: Colors.white),
            child: Text("Hapus"),
          ),
        ],
      ),
    );
  }
}