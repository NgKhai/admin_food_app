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
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isNewUser ? 'Thêm Người Dùng Mới' : 'Chỉnh Sửa Người Dùng',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(CupertinoIcons.back, size: 32,)),
        actions: [
          if (!widget.isNewUser)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
              tooltip: 'Làm mới',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildUserInfoForm(),
            const SizedBox(height: 16),
            _buildCouponSection(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveUser,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông Tin Cá Nhân',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên người dùng',
                hintText: 'Nhập tên người dùng',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                hintText: 'Nhập số điện thoại',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.update, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Cập nhật lần cuối: ${DateFormat('dd/MM/yyyy - HH:mm').format(_userInfo!.updatedAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.perm_identity, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID: ${_userInfo!.userId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coupon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Số lượng: ${_selectedCouponIds.length}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingCoupons
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
              : _allCoupons.isEmpty
              ? Center(
            child: Column(
              children: [
                Icon(Icons.card_giftcard, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Người dùng này không có coupon nào',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
              : Column(
            children: [
              const Text(
                'Coupon của người dùng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._allCoupons.asMap().entries.map((entry) {
                final index = entry.key;
                final coupon = entry.value;
                // Include the index in the key to make sure each tile is unique in the widget tree
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Text(
            'Chưa chọn coupon nào',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Coupon đã chọn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCoupons.map((coupon) {
              return Chip(
                label: Text(
                  coupon.couponName,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.white,
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _toggleCouponSelection(coupon),
                avatar: Icon(
                  coupon.type == CouponType.order ? Icons.shopping_bag : Icons.local_shipping,
                  size: 16,
                  color: Theme.of(context).primaryColor,
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
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Theme.of(context).primaryColor
              : (isExpired ? Colors.grey : Colors.blue).withOpacity(0.2),
          child: Icon(
            coupon.type == CouponType.order ? Icons.shopping_bag : Icons.local_shipping,
            color: isSelected
                ? Colors.white
                : (isExpired ? Colors.grey : Colors.blue),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                coupon.couponName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.grey : null,
                  decoration: isExpired ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: (isExpired
                    ? Colors.grey
                    : (coupon.type == CouponType.order ? Colors.orange : Colors.blue))
                    .withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                coupon.type == CouponType.order ? 'Đơn hàng' : 'Vận chuyển',
                style: TextStyle(
                  fontSize: 10,
                  color: isExpired
                      ? Colors.grey
                      : (coupon.type == CouponType.order ? Colors.orange : Colors.blue),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              coupon.isPercentage
                  ? 'Giảm ${coupon.discountValue.toStringAsFixed(0)}%${coupon.maxDiscountValue != null ? ' (tối đa ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(coupon.maxDiscountValue)})' : ''}'
                  : 'Giảm ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(coupon.discountValue)}',
              style: TextStyle(
                color: isExpired ? Colors.grey : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: isExpired ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'HSD: ${DateFormat('dd/MM/yyyy').format(coupon.expiredDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.red : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.monetization_on,
                  size: 12,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tối thiểu: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(coupon.minPurchaseAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
          activeColor: Theme.of(context).primaryColor,
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