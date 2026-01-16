class Product {
  final String id;
  final String namaProduk;
  final int harga;
  final String deskripsi;
  final String sellerId;
  final List<String> gambar;

  Product({
    required this.id,
    required this.namaProduk,
    required this.harga,
    required this.deskripsi,
    required this.sellerId,
    required this.gambar,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      namaProduk: json['namaProduk'] ?? '',
      harga: json['harga'] ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      sellerId: json['sellerId'] ?? '',
      gambar: List<String>.from(json['gambar'] ?? []),
    );
  }
}