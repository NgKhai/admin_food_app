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
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showSizeBottomSheet() {
    final sizeNameController = TextEditingController();
    final extraPriceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            TextField(
              controller: sizeNameController,
              decoration: InputDecoration(
                labelText: 'Tên Kích Cỡ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: extraPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá Thêm',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixText: '+ ',
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
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thêm Sản Phẩm Mới',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[400],
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 32),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
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
                      color: Colors.grey[200],
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        _imageFile!,
                        fit: BoxFit.fitHeight,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Chọn Hình Ảnh',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên Sản Phẩm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô Tả',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Vui lòng nhập mô tả' : null,
                ),
                SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Danh Mục',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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

                // Preparation Time and Calories
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _preparationTimeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Thời Gian Chuẩn Bị (phút)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Nhập thời gian' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _caloController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Calories',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                  decoration: InputDecoration(
                    labelText: 'Giá',
                    prefixText: 'VND ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Vui lòng nhập giá' : null,
                ),
                SizedBox(height: 16),

                // Product Sizes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kích Cỡ Sản Phẩm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showSizeBottomSheet,
                      icon: Icon(Icons.add, color: Colors.white,),
                      label: Text('Thêm Kích Cỡ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple[300],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _sizes.isEmpty
                    ? Text(
                  'Chưa có kích cỡ nào',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _sizes.length,
                  itemBuilder: (context, index) {
                    final size = _sizes[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(size.sizeName),
                        subtitle: Text(
                          '+${Utils.formatCurrency(size.extraPrice)}',
                          style: TextStyle(color: Colors.green),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
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
                SizedBox(height: 16),

                // Save Button
                ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Thêm Sản Phẩm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}