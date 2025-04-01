import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:image_picker_web/image_picker_web.dart';

import '../../models/coupon.dart';
import '../../services/admin_coupon_service.dart';
import '../../services/cloudinary_service.dart';

class AdminCouponFormScreen extends StatefulWidget {
  final Coupon? existingCoupon;

  const AdminCouponFormScreen({super.key, this.existingCoupon});

  @override
  _AdminCouponFormScreenState createState() => _AdminCouponFormScreenState();
}

class _AdminCouponFormScreenState extends State<AdminCouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CouponService _couponService = CouponService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late TextEditingController _couponIdController;
  late TextEditingController _couponNameController;
  late TextEditingController _discountValueController;
  late TextEditingController _minPurchaseAmountController;
  late TextEditingController _maxDiscountValueController;

  CouponType _selectedType = CouponType.order;
  bool _isPercentage = true;
  DateTime? _selectedExpiredDate;
  Uint8List? _pickedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final coupon = widget.existingCoupon;
    _couponIdController = TextEditingController(text: coupon?.couponId ?? '');
    _couponNameController = TextEditingController(text: coupon?.couponName ?? '');
    _discountValueController = TextEditingController(
      text: coupon?.discountValue.toString() ?? '',
    );
    _minPurchaseAmountController = TextEditingController(
      text: coupon?.minPurchaseAmount.toString() ?? '',
    );
    _maxDiscountValueController = TextEditingController(
      text: coupon?.maxDiscountValue?.toString() ?? '',
    );

    if (coupon != null) {
      _selectedType = coupon.type;
      _isPercentage = coupon.isPercentage;
      _selectedExpiredDate = coupon.expiredDate;
      _existingImageUrl = coupon.couponImageUrl;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePickerWeb.getImageAsBytes();
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
        _existingImageUrl = null;
      });
    }
  }

  Future<void> _selectExpiredDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiredDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedExpiredDate = picked;
        // Optional: You can add a SnackBar to show the selected date
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ngày hết hạn đã chọn: ${picked.day}/${picked.month}/${picked.year}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.teal[600],
            duration: Duration(seconds: 2),
          ),
        );
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Upload image if a new one is picked
      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        final fileName = 'coupon_${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await _cloudinaryService.uploadImage(
          _pickedImage!,
          fileName: fileName,
          folder: 'coupons',
        );
      }

      final coupon = Coupon(
        couponId: _couponIdController.text,
        couponName: _couponNameController.text,
        couponImageUrl: imageUrl ?? '',
        discountValue: double.parse(_discountValueController.text),
        isPercentage: _isPercentage,
        expiredDate: _selectedExpiredDate ?? DateTime.now(),
        minPurchaseAmount: double.parse(_minPurchaseAmountController.text),
        maxDiscountValue: _maxDiscountValueController.text.isNotEmpty
            ? double.parse(_maxDiscountValueController.text)
            : null,
        type: _selectedType,
      );

      bool success;
      if (widget.existingCoupon == null) {
        success = await _couponService.createCoupon(coupon) != null;
      } else {
        success = await _couponService.updateCoupon(widget.existingCoupon!.couponId, coupon);
      }

      if (success) {
        Navigator.of(context).pop();
      } else {
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Lỗi',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Không thể lưu mã giảm giá. Vui lòng thử lại.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: TextStyle(color: Colors.teal),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.existingCoupon == null
              ? 'Tạo Mã Giảm Giá Mới'
              : 'Chỉnh Sửa Mã Giảm Giá',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 32),
        ),
        backgroundColor: Colors.teal[600],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker Section
                      _buildImagePicker(),
                      const SizedBox(height: 20),

                      // Coupon Details
                      _buildCouponDetailsForm(),

                      const SizedBox(height: 24),

                      // Submit Button
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[200],
        ),
        child: _pickedImage != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            _pickedImage!,
            fit: BoxFit.fitHeight,
            // width: double.infinity,
          ),
        )
            : _existingImageUrl != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            _existingImageUrl!,
            fit: BoxFit.fitHeight,
            // width: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
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
              'Chọn Hình Ảnh Mã Giảm Giá',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponDetailsForm() {
    return Column(
      children: [
        // Coupon ID
        TextFormField(
          controller: _couponIdController,
          decoration: _inputDecoration('ID Mã Giảm Giá', Icons.code),
          validator: (value) => value!.isEmpty ? 'Vui lòng nhập ID Mã Giảm Giá' : null,
          readOnly: widget.existingCoupon != null,
        ),
        const SizedBox(height: 16),

        // Coupon Name
        TextFormField(
          controller: _couponNameController,
          decoration: _inputDecoration('Tên Mã Giảm Giá', Icons.text_fields),
          validator: (value) => value!.isEmpty ? 'Vui lòng nhập Tên Mã Giảm Giá' : null,
        ),
        const SizedBox(height: 16),

        // Discount Type Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discountValueController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  _isPercentage ? 'Phần Trăm' : 'Số Tiền Giảm',
                  Icons.discount,
                ),
                validator: (value) =>
                value!.isEmpty
                    ? 'Vui lòng nhập giá trị giảm giá'
                    : (double.tryParse(value) == null ? 'Số không hợp lệ' : null),
              ),
            ),
            const SizedBox(width: 16),
            ToggleButtons(
              isSelected: [_isPercentage, !_isPercentage],
              onPressed: (index) {
                setState(() {
                  _isPercentage = index == 0;
                });
              },
              color: Colors.teal[200],
              selectedColor: Colors.white,
              fillColor: Colors.teal[400],
              borderColor: Colors.teal[200],
              selectedBorderColor: Colors.teal[600],
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('%'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('VND'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Coupon Type and Minimum Purchase
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<CouponType>(
                value: _selectedType,
                decoration: _inputDecoration('Loại Mã Giảm Giá', Icons.category),
                items: CouponType.values
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type == CouponType.order
                      ? 'Giảm Giá Đơn Hàng'
                      : 'Giảm Giá Vận Chuyển'),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _minPurchaseAmountController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Giá Trị Đơn Tối Thiểu', Icons.shopping_cart),
                validator: (value) =>
                value!.isEmpty
                    ? 'Vui lòng nhập giá trị đơn tối thiểu'
                    : (double.tryParse(value) == null ? 'Số không hợp lệ' : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Optional Max Discount and Expiry Date
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxDiscountValueController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Giảm Giá Tối Đa', Icons.money_off, optional: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _selectExpiredDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _inputDecoration(
                      _selectedExpiredDate != null
                          ? '${_selectedExpiredDate!.day}/${_selectedExpiredDate!.month}/${_selectedExpiredDate!.year}'
                          : 'Ngày Hết Hạn',
                      Icons.calendar_today,
                      value: _selectedExpiredDate != null
                          ? '${_selectedExpiredDate!.day}/${_selectedExpiredDate!.month}/${_selectedExpiredDate!.year}'
                          : null,
                    ),
                    validator: (value) =>
                    _selectedExpiredDate == null
                        ? 'Vui lòng chọn ngày hết hạn'
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(
      String label,
      IconData icon, {
        String? value,
        bool optional = false,
      }) {
    return InputDecoration(
      labelText: optional ? '$label (Tùy Chọn)' : label,
      hintText: value,
      prefixIcon: Icon(icon, color: Colors.teal[300]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[100]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[100]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal[400]!, width: 2),
      ),
      labelStyle: TextStyle(color: Colors.teal[300]),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal[600],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        widget.existingCoupon == null ? 'Tạo Mã Giảm Giá' : 'Cập Nhật Mã Giảm Giá',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}