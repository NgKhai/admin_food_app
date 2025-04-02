import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/admin_product_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/utils.dart';
import 'package:image_picker_web/image_picker_web.dart';

class AdminAddProductScreen extends StatefulWidget {
  const AdminAddProductScreen({Key? key}) : super(key: key);

  @override
  _AdminAddProductScreenState createState() => _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends State<AdminAddProductScreen> {
  // Color scheme
  final Color mainColor = Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background

  final _formKey = GlobalKey<FormState>();
  final AdminProductService _productService = AdminProductService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Image-related variables
  Uint8List? _imageFile;

  // Controller variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _preparationTimeController = TextEditingController();
  final TextEditingController _caloController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<ProductSize> _sizes = [];

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = categoriesSnapshot.docs
            .map((doc) => Category.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi không thể tải danh mục: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();
      if (imageBytes != null) {
        setState(() {
          _imageFile = imageBytes;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi chọn ảnh: $e');
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isUploading = true;
        });

        // Check if image is selected
        if (_imageFile == null) {
          _showErrorSnackBar('Vui lòng chọn ảnh sản phẩm');
          setState(() {
            _isUploading = false;
          });
          return;
        }

        // Upload image
        String? imageUrl = await _cloudinaryService.uploadImage(
          _imageFile!,
          fileName: 'product_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (imageUrl == null) {
          _showErrorSnackBar('Lỗi tải ảnh lên');
          setState(() {
            _isUploading = false;
          });
          return;
        }

        final newProduct = Product(
          productId: DateTime.now().millisecondsSinceEpoch.toString(),
          productName: _nameController.text,
          productImg: imageUrl,
          productPreparationTime: int.parse(_preparationTimeController.text),
          productCalo: int.parse(_caloController.text),
          productPrice: num.parse(_priceController.text),
          productDescription: _descriptionController.text,
          productStatus: true,
          categoryId: _selectedCategoryId ?? '',
          sizes: _sizes,
        );

        await _productService.addProduct(newProduct);

        _showSuccessSnackBar('Thêm sản phẩm thành công');
        Navigator.pop(context, true);
      } catch (e) {
        _showErrorSnackBar('Lỗi thêm sản phẩm: $e');
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSizeBottomSheet() {
    final sizeNameController = TextEditingController();
    final extraPriceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm Kích Cỡ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            TextField(
              controller: sizeNameController,
              decoration: InputDecoration(
                labelText: 'Tên Kích Cỡ',
                labelStyle: TextStyle(color: accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accentColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: mainColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: lightColor),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: extraPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá Thêm',
                labelStyle: TextStyle(color: accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: mainColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: lightColor),
                ),
                prefixText: '+ ',
                prefixStyle: TextStyle(color: accentColor),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (sizeNameController.text.isNotEmpty && extraPriceController.text.isNotEmpty) {
                  setState(() {
                    _sizes.add(ProductSize(
                      sizeId: DateTime.now().millisecondsSinceEpoch.toString(),
                      sizeName: sizeNameController.text,
                      extraPrice: num.parse(extraPriceController.text),
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Thêm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _preparationTimeController.dispose();
    _caloController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  InputDecoration _buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: accentColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: mainColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: lightColor),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ultraLightColor,
      appBar: AppBar(
        title: Text(
          'Thêm Sản Phẩm Mới',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 28),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card wrapper for form
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image Picker
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: ultraLightColor,
                                  border: Border.all(color: lightColor, width: 1),
                                ),
                                child: _imageFile != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.memory(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 50,
                                      color: accentColor,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Chọn Hình Ảnh',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 24),

                            // Product Name
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildInputDecoration('Tên Sản Phẩm'),
                              validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                            ),
                            SizedBox(height: 16),

                            // Description
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: _buildInputDecoration('Mô Tả'),
                              validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
                            ),
                            SizedBox(height: 16),

                            // Category Dropdown
                            DropdownButtonFormField<String>(
                              decoration: _buildInputDecoration('Danh Mục'),
                              dropdownColor: Colors.white,
                              icon: Icon(Icons.arrow_drop_down, color: accentColor),
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                              items: _categories.map((category) {
                                return DropdownMenuItem(
                                  value: category.categoryId,
                                  child: Text(category.categoryName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategoryId = value;
                                });
                              },
                              validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
                            ),
                            SizedBox(height: 16),

                            // Row for Preparation Time and Calories
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _preparationTimeController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration('Thời Gian (phút)',
                                      suffixIcon: Icon(Icons.timer, color: accentColor),
                                    ),
                                    validator: (value) => value!.isEmpty ? 'Nhập thời gian' : null,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _caloController,
                                    keyboardType: TextInputType.number,
                                    decoration: _buildInputDecoration('Calories',
                                      suffixIcon: Icon(Icons.local_fire_department, color: accentColor),
                                    ),
                                    validator: (value) => value!.isEmpty ? 'Nhập calories' : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Price
                            TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration('Giá (VNĐ)',
                                suffixIcon: Icon(Icons.attach_money, color: accentColor),
                              ),
                              validator: (value) => value!.isEmpty ? 'Vui lòng nhập giá' : null,
                            ),
                            SizedBox(height: 24),

                            // Product Sizes Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kích Cỡ Sản Phẩm',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showSizeBottomSheet,
                                  icon: Icon(Icons.add, color: Colors.white, size: 20),
                                  label: Text('Thêm Kích Cỡ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),

                            // Sizes List
                            _sizes.isEmpty
                                ? Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: ultraLightColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: lightColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                'Chưa có kích cỡ nào',
                                style: TextStyle(color: lightColor),
                                textAlign: TextAlign.center,
                              ),
                            )
                                : ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _sizes.length,
                              itemBuilder: (context, index) {
                                final size = _sizes[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: ultraLightColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: lightColor.withOpacity(0.5)),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      size.sizeName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: mainColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '+${Utils.formatCurrency(size.extraPrice)}',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red[700]),
                                      onPressed: () {
                                        setState(() {
                                          _sizes.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isUploading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        disabledBackgroundColor: lightColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploading
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Đang Xử Lý...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                          : Text(
                        'Thêm Sản Phẩm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Đang tải lên sản phẩm...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}