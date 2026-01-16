import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/order_service.dart';

// --- WARNA TEMA MODERN ---
const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpBackground = Color(0xFFF5F7FA);
const Color pnpGreen = Color(0xFF43A047);
const Color pnpRed = Color(0xFFD32F2F);
const Color pnpOrange = Color(0xFFFFA000);

class IncomingOrderScreen extends StatefulWidget {
  @override
  _IncomingOrderScreenState createState() => _IncomingOrderScreenState();
}

class _IncomingOrderScreenState extends State<IncomingOrderScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    // Gunakan ID user login (sebagai seller), default "1" untuk tes
    String sellerId = user?.id.toString() ?? "1";

    final data = await OrderService().getIncomingOrders(sellerId);
    if (mounted) {
      setState(() {
        orders = data;
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int orderId, String status) async {
    // Tampilkan loading dialog atau indikator jika perlu, disini kita pakai snackbar saja
    bool success = await OrderService().updateOrderStatus(orderId, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status berhasil diubah ke $status"), backgroundColor: pnpGreen)
      );
      _fetchOrders(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengubah status"), backgroundColor: pnpRed)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pnpBackground,
      appBar: AppBar(
        title: Text("Pesanan Masuk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: pnpPrimaryBlue))
          : orders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchOrders,
        color: pnpPrimaryBlue,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            return _buildOrderCard(orders[i]);
          },
        ),
      ),
    );
  }

  // ==========================
  // WIDGET: EMPTY STATE
  // ==========================
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
            child: Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
          ),
          SizedBox(height: 20),
          Text(
            "Belum ada pesanan masuk",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
          SizedBox(height: 5),
          Text(
            "Pesanan dari pembeli akan muncul di sini",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ==========================
  // WIDGET: ORDER CARD
  // ==========================
  Widget _buildOrderCard(dynamic order) {
    final items = (order['Items'] as List<dynamic>?) ?? [];
    final status = order['status'] ?? 'PENDING';
    final orderId = order['ID'];
    final totalPrice = order['total_price'] ?? 0; // Pastikan backend kirim ini, atau hitung manual

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: ID & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 18, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text("Order #$orderId", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                _buildStatusBadge(status),
              ],
            ),
            Divider(height: 24, thickness: 1, color: Colors.grey[100]),

            // --- LIST BARANG ---
            Column(
              children: items.map((item) => _buildOrderItem(item)).toList(),
            ),

            SizedBox(height: 12),
            Divider(height: 1, color: Colors.grey[200]),
            SizedBox(height: 12),

            // --- TOTAL HARGA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Pesanan", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text("Rp $totalPrice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pnpPrimaryBlue)),
              ],
            ),
            SizedBox(height: 16),

            // --- TOMBOL AKSI ---
            _buildActionButtons(orderId, status),
          ],
        ),
      ),
    );
  }

  // Helper: Status Badge Warna-warni
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'PENDING':
        bgColor = pnpOrange.withOpacity(0.1);
        textColor = pnpOrange;
        label = "Menunggu Konfirmasi";
        break;
      case 'DIPROSES':
        bgColor = pnpPrimaryBlue.withOpacity(0.1);
        textColor = pnpPrimaryBlue;
        label = "Siap COD";
        break;
      case 'SELESAI':
        bgColor = pnpGreen.withOpacity(0.1);
        textColor = pnpGreen;
        label = "Selesai";
        break;
      case 'DIBATALKAN':
        bgColor = pnpRed.withOpacity(0.1);
        textColor = pnpRed;
        label = "Dibatalkan";
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper: Tampilan Item Produk dengan Gambar
  Widget _buildOrderItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // Gambar Kecil
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              image: (item['gambar'] != null && item['gambar'] != "")
                  ? DecorationImage(
                  image: NetworkImage(item['gambar']),
                  fit: BoxFit.cover,
                  onError: (_,__) => Icon(Icons.broken_image, size: 20)
              )
                  : null,
            ),
            child: (item['gambar'] == null || item['gambar'] == "")
                ? Icon(Icons.shopping_bag_outlined, color: Colors.grey)
                : null,
          ),
          SizedBox(width: 12),
          // Info Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama_produk'] ?? 'Produk',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  "Rp ${item['harga']}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Logika Tombol Aksi
  Widget _buildActionButtons(int orderId, String status) {
    if (status == 'PENDING') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _updateStatus(orderId, 'DIBATALKAN'),
              style: OutlinedButton.styleFrom(
                foregroundColor: pnpRed,
                side: BorderSide(color: pnpRed),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("Tolak"),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateStatus(orderId, 'DIPROSES'),
              style: ElevatedButton.styleFrom(
                backgroundColor: pnpPrimaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text("Terima Pesanan"),
            ),
          ),
        ],
      );
    } else if (status == 'DIPROSES') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _updateStatus(orderId, 'SELESAI'),
          icon: Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
          label: Text("Transaksi Selesai (COD Sukses)"),
          style: ElevatedButton.styleFrom(
            backgroundColor: pnpGreen,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      );
    } else {
      // Status Selesai / Dibatalkan
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            status == 'SELESAI' ? "Transaksi Berhasil" : "Transaksi Dibatalkan",
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }
  }
}