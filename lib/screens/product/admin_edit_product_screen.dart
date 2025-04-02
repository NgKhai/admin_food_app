import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/admin_product_service.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/utils.dart';
import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';

class AdminEditProductScreen extends StatefulWidget {
  final Product product;

  const AdminEditProductScreen({super.key, required this.product});

  @override
  _AdminEditProductScreenState createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
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
  String? _uploadedImageUrl;

  // Controller variables
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _preparationTimeController;
  late TextEditingController _caloController;
  late TextEditingController _priceController;

  List<Category> _categories = [];
  String? _selectedCategoryId;
  List<ProductSize> _sizes = [];
  String? _networkImageUrl;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchCategories();
  }

  void _initializeControllers() {
    final product = widget.product;
    _nameController = TextEditingController(text: product.productName);
    _descriptionController = TextEditingController(text: product.productDescription);
    _preparationTimeController = TextEditingController(text: product.productPreparationTime.toString());
    _caloController = TextEditingController(text: product.productCalo.toString());
    _priceController = TextEditingController(text: product.productPrice.toString());
    _selectedCategoryId = product.categoryId;
    _sizes = List.from(product.sizes);
    _networkImageUrl = product.productImg;
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
      setState(() {
        _categories = categoriesSnapshot.docs
            .map((doc) => Category.fromJson(doc.data()))
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
          _networkImageUrl = null;
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

        // Determine image URL
        String? imageUrl = _networkImageUrl;

        // Upload new image if selected
        if (_imageFile != null) {
          imageUrl = await _cloudinaryService.uploadImage(
              _imageFile!,
              fileName: 'product_${widget.product.productId}'
          );
          if (imageUrl == null) {
            _showErrorSnackBar('Lỗi tải ảnh lên');
            setState(() {
              _isUploading = false;
            });
            return;
          }
        }

        final updatedProduct = Product(
          productId: widget.product.productId,
          productName: _nameController.text,
          productImg: imageUrl ?? '',
          productPreparationTime: int.parse(_preparationTimeController.text),
          productCalo: int.parse(_caloController.text),
          productPrice: num.parse(_priceController.text),
          productDescription: _descriptionController.text,
          productStatus: true,
          categoryId: _selectedCategoryId ?? '',
          sizes: _sizes,
        );

        await _productService.updateProduct(updatedProduct);

        _showSuccessSnackBar('Cập nhật sản phẩm thành công');
        Navigator.pop(context, true);
      } catch (e) {
        _showErrorSnackBar('Lỗi cập nhật sản phẩm: $e');
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
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accentColor,
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
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm Kích Cỡ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              controller: sizeNameController,
              decoration: InputDecoration(
                labelText: 'Tên Kích Cỡ',
                labelStyle: TextStyle(color: accentColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mainColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: mainColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: lightColor),
                ),
                prefixText: '+ ',
                prefixStyle: TextStyle(color: accentColor),
              ),
            ),
            SizedBox(height: 24),
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
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: accentColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: mainColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red[400]!, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ultraLightColor,
      appBar: AppBar(
        title: Text(
          'Chỉnh Sửa Sản Phẩm',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: mainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 26),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hình Ảnh Sản Phẩm',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: mainColor,
                              ),
                            ),
                            SizedBox(height: 12),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _imageFile != null || _networkImageUrl != null
                                        ? Colors.transparent
                                        : lightColor,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  color: _imageFile != null || _networkImageUrl != null
                                      ? Colors.transparent
                                      : ultraLightColor,
                                ),
                                child: _imageFile != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                    : _networkImageUrl != null
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: _networkImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Icon(Icons.error, color: accentColor, size: 40),
                                    ),
                                  ),
                                )
                                    : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 48,
                                      color: accentColor,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Chọn Hình Ảnh',
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Product Details Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông Tin Sản Phẩm',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: mainColor,
                              ),
                            ),
                            SizedBox(height: 16),

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
                              value: _selectedCategoryId,
                              decoration: _buildInputDecoration('Danh Mục'),
                              icon: Icon(Icons.arrow_drop_down, color: accentColor),
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
                                    decoration: _buildInputDecoration('Thời Gian (phút)').copyWith(
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
                                    decoration: _buildInputDecoration('Calories').copyWith(
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
                              decoration: _buildInputDecoration('Giá').copyWith(
                                prefixText: 'VND ',
                                prefixStyle: TextStyle(color: accentColor),
                                suffixIcon: Icon(Icons.monetization_on, color: accentColor),
                              ),
                              validator: (value) => value!.isEmpty ? 'Vui lòng nhập giá' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Product Sizes Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  icon: Icon(Icons.add, color: Colors.white, size: 18),
                                  label: Text(
                                    'Thêm Kích Cỡ',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            _sizes.isEmpty
                                ? Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: ultraLightColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: lightColor.withOpacity(0.5),
                                  width: 1,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Chưa có kích cỡ nào',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
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
                                    color: ultraLightColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: lightColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: accentColor,
                                      child: Text(
                                        size.sizeName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      size.sizeName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
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
                                      icon: Icon(Icons.delete_outline, color: Colors.red[700]),
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
                    SizedBox(height: 30),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isUploading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Lưu Thay Đổi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Đang cập nhật...',
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}