class CartItem {
  final int id;
  final int buyerId;
  final String productId;
  final int sellerId;
  final String namaProduk; // Sesuai JSON: nama_produk
  final int harga;
  final String gambar;
  bool isSelected;

  CartItem({
    required this.id,
    required this.buyerId,
    required this.productId,
    required this.sellerId,
    required this.namaProduk,
    required this.harga,
    required this.gambar,
    this.isSelected = true,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      buyerId: json['buyer_id'] ?? 0,
      productId: json['product_id'] ?? '',
      sellerId: json['seller_id'] ?? 0,
      // PERBAIKAN: Gunakan 'nama_produk' sesuai respon backend Golang Anda
      namaProduk: json['nama_produk'] ?? 'Produk Tanpa Nama',
      harga: json['harga'] != null ? json['harga'].toInt() : 0,
      gambar: json['gambar'] ?? '',
    );
  }
}