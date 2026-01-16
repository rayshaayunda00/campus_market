import 'dart:io'; // Import IO untuk File (Khusus Mobile)
import 'package:flutter/foundation.dart'; // Untuk cek kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile ada di sini
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart'; // Import Service langsung

const Color pnpPrimaryBlue = Color(0xFF0D47A1);
const Color pnpBackground = Color(0xFFF5F7FA);

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({this.product});

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaCtrl;
  late TextEditingController _hargaCtrl;
  late TextEditingController _deskripsiCtrl;

  // PERBAIKAN 1: Gunakan XFile agar support Web & Mobile
  XFile? _pickedFile;
  String? _existingImageUrl;

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.product?.namaProduk ?? '');
    _hargaCtrl = TextEditingController(text: widget.product?.harga.toString() ?? '');
    _deskripsiCtrl = TextEditingController(text: widget.product?.deskripsi ?? '');

    // Cek jika sedang Edit, simpan URL lama
    if (widget.product != null && widget.product!.gambar.isNotEmpty) {
      _existingImageUrl = widget.product!.gambar[0];
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  // LOGIKA AMBIL GAMBAR (Sama untuk Web & HP)
  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedFile = picked; // Simpan sebagai XFile
      });
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi: Harus ada gambar (Baru atau Lama)
    if (_pickedFile == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Wajib memasukkan foto produk")));
      return;
    }

    setState(() => _isLoading = true);

    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    final provider = Provider.of<ProductProvider>(context, listen: false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sesi habis, login ulang")));
      setState(() => _isLoading = false);
      return;
    }

    // 1. UPLOAD GAMBAR DULU (Jika user memilih file baru)
    String finalImageUrl = _existingImageUrl ?? "";

    if (_pickedFile != null) {
      // Panggil fungsi upload di Service yang baru diperbaiki
      String? uploadedUrl = await ProductService().uploadImage(_pickedFile!);

      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal upload gambar ke server")));
        return;
      }
    }

    // 2. BUAT OBJEK PRODUK
    Product newProduct = Product(
      id: widget.product?.id ?? '',
      namaProduk: _namaCtrl.text,
      harga: int.parse(_hargaCtrl.text),
      deskripsi: _deskripsiCtrl.text,
      sellerId: user.id.toString(),
      gambar: [finalImageUrl], // Masukkan URL hasil upload
    );

    // 3. SIMPAN KE DATABASE (VIA PROVIDER)
    bool success;
    if (widget.product == null) {
      success = await provider.addProduct(newProduct);
    } else {
      success = await provider.updateProduct(widget.product!.id, newProduct);
    }

    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Produk Disimpan!"), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menyimpan data"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: pnpBackground,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Produk" : "Jual Produk"),
        backgroundColor: pnpPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔥 AREA UPLOAD GAMBAR
                  GestureDetector(
                    onTap: _pickImage, // Klik untuk buka galeri
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      // PANGGIL WIDGET HELPER PREVIEW
                      child: _buildImagePreview(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(child: Text("Ketuk gambar untuk mengganti foto", style: TextStyle(color: Colors.grey, fontSize: 12))),
                  SizedBox(height: 20),

                  Text("Detail Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pnpPrimaryBlue)),
                  SizedBox(height: 15),

                  TextFormField(
                    controller: _namaCtrl,
                    decoration: _inputDecor("Nama Barang", Icons.shopping_bag_outlined),
                    validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  ),
                  SizedBox(height: 15),

                  TextFormField(
                    controller: _hargaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecor("Harga (Rp)", Icons.attach_money),
                    validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  ),
                  SizedBox(height: 15),

                  TextFormField(
                    controller: _deskripsiCtrl,
                    maxLines: 4,
                    decoration: _inputDecor("Deskripsi & Kondisi", Icons.description_outlined),
                    validator: (val) => val!.isEmpty ? "Wajib diisi" : null,
                  ),
                  SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pnpPrimaryBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("JUAL SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === PERBAIKAN 2: WIDGET PREVIEW UNTUK WEB & MOBILE ===
  Widget _buildImagePreview() {
    if (_pickedFile != null) {
      if (kIsWeb) {
        // LOGIKA WEB: ImagePicker di Web mengembalikan path sebagai Blob URL
        // Jadi kita bisa pakai Image.network untuk menampilkan previewnya
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(_pickedFile!.path, fit: BoxFit.cover),
        );
      } else {
        // LOGIKA MOBILE: Harus convert ke File IO
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
        );
      }
    } else if (_existingImageUrl != null) {
      // Tampilkan URL Lama (Mode Edit)
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _existingImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (c, o, s) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.grey),
              Text("Gagal memuat gambar", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    } else {
      // Belum Ada Gambar
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: pnpPrimaryBlue),
          SizedBox(height: 8),
          Text("Upload Foto Produk", style: TextStyle(color: pnpPrimaryBlue, fontWeight: FontWeight.bold)),
        ],
      );
    }
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: pnpPrimaryBlue, width: 2)),
      filled: true, fillColor: Colors.grey[50],
    );
  }
}