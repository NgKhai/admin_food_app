import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:admin_food_app/models/user_info.dart';
import 'package:admin_food_app/models/coupon.dart';
import 'package:admin_food_app/services/admin_account_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../services/admin_coupon_service.dart';

class EditUserScreen extends StatefulWidget {
  final bool isNewUser;
  final String? userId;

  const EditUserScreen({
    super.key,
    required this.isNewUser,
    this.userId,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  // Color scheme
  final Color mainColor = const Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = const Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = const Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = const Color(0xFFD0DCE7); // Very light blue - background

  final AdminAccountService _adminAccountService = AdminAccountService();
  final _couponService = CouponService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingCoupons = false;

  // User information
  UserInfo? _userInfo;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Coupons
  List<Coupon> _allCoupons = [];
  List<Coupon> _selectedCoupons = [];
  List<String> _selectedCouponIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingCoupons = true;
    });

    try {
      // If editing an existing user, load their data
      if (!widget.isNewUser && widget.userId != null) {
        _userInfo = await _adminAccountService.getUserAccount(widget.userId!);
        _nameController.text = _userInfo?.name ?? 'Khách hàng';
        _phoneController.text = _userInfo?.phone ?? '';
        _selectedCouponIds = _userInfo?.couponIds ?? [];

        // Get unique coupon IDs to fetch from database
        final uniqueCouponIds = _selectedCouponIds.toSet().toList();

        // Fetch the coupons from Firestore
        final fetchedCoupons = await _couponService.getCouponsByIds(uniqueCouponIds);

        // Create a map of coupon ID to coupon object for faster lookup
        final couponMap = {for (var coupon in fetchedCoupons) coupon.couponId: coupon};

        // Maintain the original order and duplicates
        _selectedCoupons = [];
        _allCoupons = [];

        for (var couponId in _selectedCouponIds) {
          if (couponMap.containsKey(couponId)) {
            _selectedCoupons.add(couponMap[couponId]!);
            _allCoupons.add(couponMap[couponId]!);
          }
        }
      } else {
        // For new users
        _selectedCouponIds = [];
        _selectedCoupons = [];
        _allCoupons = [];
      }
    } catch (e) {
      _showErrorSnackBar('Không thể tải dữ liệu: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingCoupons = false;
      });
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String name = _nameController.text.trim();
      final String phone = _phoneController.text.trim();

      if (widget.isNewUser) {
        // Create new user
        final newUserId = const Uuid().v4();
        final newUser = UserInfo(
          userId: newUserId,
          name: name,
          phone: phone,
          couponIds: _selectedCouponIds,
          fcmToken: '',
          updatedAt: DateTime.now(),
        );

        final result = await _adminAccountService.createUser(newUser);
        if (result) {
          _showSuccessSnackBar('Đã tạo người dùng mới thành công');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Không thể tạo người dùng');
        }
      } else if (_userInfo != null) {
        // Update existing user
        final updatedUser = UserInfo(
          userId: _userInfo!.userId,
          name: name,
          phone: phone,
          couponIds: _selectedCouponIds,
          fcmToken: _userInfo!.fcmToken,
          updatedAt: DateTime.now(),
        );

        final result = await _adminAccountService.updateUser(updatedUser);
        if (result) {
          _showSuccessSnackBar('Đã cập nhật người dùng thành công');
          Navigator.pop(context, true);
        } else {
          _showErrorSnackBar('Không thể cập nhật người dùng');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi lưu người dùng: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleCouponSelection(Coupon coupon) {
    setState(() {
      if (_selectedCouponIds.contains(coupon.couponId)) {
        _selectedCouponIds.remove(coupon.couponId);
        _selectedCoupons.removeWhere((c) => c.couponId == coupon.couponId);
      } else {
        _selectedCouponIds.add(coupon.couponId);
        _selectedCoupons.add(coupon);
      }
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ultraLightColor.withOpacity(0.3),
      appBar: AppBar(
        title: Text(
          widget.isNewUser ? 'Thêm Người Dùng Mới' : 'Chỉnh Sửa Người Dùng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: mainColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(CupertinoIcons.back, size: 28, color: Colors.white),
        ),
        actions: [
          if (!widget.isNewUser)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
              tooltip: 'Làm mới',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mainColor))
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildUserInfoForm(),
            const SizedBox(height: 16),
            _buildCouponSection(),
            const SizedBox(height: 100), // Extra space for bottom button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
          )
              : Text(
            widget.isNewUser ? 'Tạo Người Dùng' : 'Lưu Thay Đổi',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: mainColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Thông Tin Cá Nhân',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên người dùng',
                labelStyle: TextStyle(color: accentColor),
                hintText: 'Nhập tên người dùng',
                hintStyle: TextStyle(color: lightColor.withOpacity(0.7)),
                prefixIcon: Icon(Icons.person, color: accentColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ultraLightColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: mainColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên người dùng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                labelStyle: TextStyle(color: accentColor),
                hintText: 'Nhập số điện thoại',
                hintStyle: TextStyle(color: lightColor.withOpacity(0.7)),
                prefixIcon: Icon(Icons.phone, color: accentColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ultraLightColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: mainColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                // Validate Vietnamese phone number format
                final phoneRegex = RegExp(r'^(0|\+84)(\d{9,10})$');
                if (!phoneRegex.hasMatch(value)) {
                  return 'Số điện thoại không hợp lệ';
                }
                return null;
              },
            ),
            if (!widget.isNewUser && _userInfo != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ultraLightColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ultraLightColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.update, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Cập nhật lần cuối: ${DateFormat('dd/MM/yyyy - HH:mm').format(_userInfo!.updatedAt)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.perm_identity, size: 16, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${_userInfo!.userId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: mainColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Coupon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Số lượng: ${_selectedCouponIds.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _isLoadingCoupons
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CircularProgressIndicator(color: mainColor),
            ),
          )
              : _allCoupons.isEmpty
              ? Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Icon(Icons.card_giftcard, size: 60, color: lightColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Người dùng này không có coupon nào',
                  style: TextStyle(
                    color: lightColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          )
              : Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ultraLightColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coupon của người dùng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              ..._allCoupons.asMap().entries.map((entry) {
                final index = entry.key;
                final coupon = entry.value;
                return _buildCouponTile(coupon, readOnly: true, key: '$index-${coupon.couponId}');
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCoupons() {
    if (_selectedCoupons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ultraLightColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ultraLightColor),
        ),
        child: Center(
          child: Text(
            'Chưa chọn coupon nào',
            style: TextStyle(color: lightColor, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coupon đã chọn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ultraLightColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ultraLightColor),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCoupons.map((coupon) {
              return Chip(
                label: Text(
                  coupon.couponName,
                  style: TextStyle(fontSize: 12, color: mainColor, fontWeight: FontWeight.w500),
                ),
                backgroundColor: Colors.white,
                deleteIcon: Icon(Icons.close, size: 16, color: accentColor),
                onDeleted: () => _toggleCouponSelection(coupon),
                avatar: Icon(
                  coupon.type == CouponType.order ? Icons.shopping_bag : Icons.local_shipping,
                  size: 16,
                  color: mainColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: mainColor.withOpacity(0.3)),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCouponTile(Coupon coupon, {bool readOnly = false, String? key}) {
    final bool isSelected = _selectedCouponIds.contains(coupon.couponId);
    final bool isExpired = coupon.expiredDate.isBefore(DateTime.now());

    return Card(
      key: key != null ? ValueKey(key) : null,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: mainColor, width: 2)
            : BorderSide(color: ultraLightColor, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? mainColor
              : (isExpired ? Colors.grey : accentColor).withOpacity(0.2),
          child: Icon(
            coupon.type == CouponType.order ? Icons.shopping_bag : Icons.local_shipping,
            color: isSelected
                ? Colors.white
                : (isExpired ? Colors.grey : accentColor),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                coupon.couponName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.grey : mainColor,
                  decoration: isExpired ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: (isExpired
                    ? Colors.grey
                    : (coupon.type == CouponType.order ? Colors.orange : accentColor))
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isExpired
                      ? Colors.grey
                      : (coupon.type == CouponType.order ? Colors.orange : accentColor))
                      .withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                coupon.type == CouponType.order ? 'Đơn hàng' : 'Vận chuyển',
                style: TextStyle(
                  fontSize: 11,
                  color: isExpired
                      ? Colors.grey
                      : (coupon.type == CouponType.order ? Colors.orange : accentColor),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isExpired ? Colors.grey.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                coupon.isPercentage
                    ? 'Giảm ${coupon.discountValue.toStringAsFixed(0)}%${coupon.maxDiscountValue != null ? ' (tối đa ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(coupon.maxDiscountValue)})' : ''}'
                    : 'Giảm ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(coupon.discountValue)}',
                style: TextStyle(
                  color: isExpired ? Colors.grey : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.red.withOpacity(0.1) : ultraLightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: isExpired ? Colors.red : lightColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'HSD: ${DateFormat('dd/MM/yyyy').format(coupon.expiredDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpired ? Colors.red : lightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ultraLightColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 12,
                        color: lightColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tối thiểu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(coupon.minPurchaseAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: lightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Only show checkbox if not in read-only mode
        trailing: readOnly ? null : Checkbox(
          value: isSelected,
          onChanged: isExpired
              ? null
              : (bool? value) {
            _toggleCouponSelection(coupon);
          },
          activeColor: mainColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Only make tappable if not in read-only mode
        onTap: readOnly || isExpired
            ? null
            : () {
          _toggleCouponSelection(coupon);
        },
      ),
    );
  }
}