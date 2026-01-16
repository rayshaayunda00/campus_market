import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/order_service.dart';

// Sesuaikan warna dengan tema aplikasi Anda
const Color pnpPrimaryBlue = Color(0xFF0D47A1);

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    // Gunakan ID user yang sedang login. Jika null (mode tamu/test), pakai "2"
    String userId = user?.id.toString() ?? "2";

    // Panggil Service yang baru saja Anda update
    final data = await OrderService().getMyOrders(userId);

    if (mounted) {
      setState(() {
        orders = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu supaya Card terlihat
      appBar: AppBar(
        title: Text("Riwayat Pesanan", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, // Hilangkan tombol back karena ini menu utama
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? Center(child: Text("Belum ada riwayat pesanan"))
          : RefreshIndicator(
        onRefresh: _fetchOrders, // Fitur tarik ke bawah untuk refresh
        child: ListView.builder(
          padding: EdgeInsets.all(15),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final order = orders[i];

            // Ambil detail item pertama untuk ditampilkan di depan
            final items = (order['Items'] as List<dynamic>?) ?? [];
            final firstItem = items.isNotEmpty ? items[0] : null;

            final total = order['total_price'];
            final status = order['status'] ?? 'PENDING';
            final orderId = order['ID'];

            return Card(
              margin: EdgeInsets.only(bottom: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === HEADER CARD (ID & STATUS) ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Order #$orderId", style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: status == 'PENDING' ? Colors.orange[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                              status,
                              style: TextStyle(
                                  color: status == 'PENDING' ? Colors.orange[800] : Colors.green[800],
                                  fontWeight: FontWeight.bold, fontSize: 12
                              )
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 20),

                    // === DETAIL BARANG ===
                    if (firstItem != null)
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                                image: (firstItem['gambar'] != null && firstItem['gambar'] != "")
                                    ? DecorationImage(
                                    image: NetworkImage(firstItem['gambar']),
                                    fit: BoxFit.cover,
                                    onError: (_,__) => Icon(Icons.broken_image)
                                )
                                    : null
                            ),
                            child: (firstItem['gambar'] == null || firstItem['gambar'] == "")
                                ? Icon(Icons.shopping_bag, color: Colors.grey)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstItem['nama_produk'] ?? 'Produk Tanpa Nama',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text("${items.length} Barang", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          )
                        ],
                      )
                    else
                      Text("Detail barang tidak tersedia", style: TextStyle(color: Colors.grey)),

                    SizedBox(height: 15),

                    // === FOOTER (TOTAL HARGA) ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Total Belanja", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text("Rp $total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}