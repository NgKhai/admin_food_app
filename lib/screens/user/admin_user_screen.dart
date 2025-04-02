import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:admin_food_app/models/user_info.dart';
import 'package:admin_food_app/services/admin_account_service.dart';
import 'package:intl/intl.dart';

import 'admin_user_edit_screen.dart';

enum SortOrder { none, aToZ, zToA }

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final AdminAccountService _adminAccountService = AdminAccountService();
  List<UserInfo> _allUsers = [];
  List<UserInfo> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterOption = 'Tất cả';
  SortOrder _sortOrder = SortOrder.none;

  // Color palette
  final Color mainColor = const Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = const Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = const Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = const Color(0xFFD0DCE7); // Very light blue - background

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _adminAccountService.getAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Không thể tải danh sách người dùng: $e');
    }
  }

  void _applyFilters() {
    List<UserInfo> filteredList = List.from(_allUsers);

    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.phone.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.userId.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Áp dụng bộ lọc
    if (_filterOption == 'Có coupon') {
      filteredList = filteredList.where((user) => user.couponIds.isNotEmpty).toList();
    } else if (_filterOption == 'Không có coupon') {
      filteredList = filteredList.where((user) => user.couponIds.isEmpty).toList();
    }

    // Áp dụng sắp xếp
    if (_sortOrder == SortOrder.aToZ) {
      filteredList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortOrder == SortOrder.zToA) {
      filteredList.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }

    setState(() {
      _filteredUsers = filteredList;
    });
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final result = await _adminAccountService.deleteUser(userId);
      if (result) {
        _showSuccessSnackBar('Đã xóa người dùng thành công');
        _loadUsers();
      } else {
        _showErrorSnackBar('Không thể xóa người dùng');
      }
    } catch (e) {
      _showErrorSnackBar('Lỗi khi xóa người dùng: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: accentColor,
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
      backgroundColor: ultraLightColor,
      appBar: AppBar(
        title: const Text(
          'Quản lý Người dùng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 28),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          const SizedBox(height: 12),
          _buildUserStats(),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: mainColor))
                : _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: lightColor),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy người dùng nào',
                    style: TextStyle(fontSize: 16, color: accentColor),
                  ),
                ],
              ),
            )
                : _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              hintStyle: TextStyle(color: lightColor),
              prefixIcon: Icon(Icons.search, color: mainColor),
              filled: true,
              fillColor: ultraLightColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: mainColor, width: 1),
              ),
            ),
            cursorColor: mainColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Lọc:', style: TextStyle(fontWeight: FontWeight.bold, color: mainColor)),
              const SizedBox(width: 8),
              _buildFilterChip('Tất cả'),
              const SizedBox(width: 8),
              _buildFilterChip('Có coupon'),
              const SizedBox(width: 8),
              _buildFilterChip('Không có coupon'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Sắp xếp:', style: TextStyle(fontWeight: FontWeight.bold, color: mainColor)),
              const SizedBox(width: 8),
              _buildSortButton(
                label: 'A → Z',
                icon: Icons.arrow_downward,
                sortOrder: SortOrder.aToZ,
              ),
              const SizedBox(width: 8),
              _buildSortButton(
                label: 'Z → A',
                icon: Icons.arrow_upward,
                sortOrder: SortOrder.zToA,
              ),
              const SizedBox(width: 8),
              if (_sortOrder != SortOrder.none)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _sortOrder = SortOrder.none;
                      _applyFilters();
                    });
                  },
                  icon: Icon(Icons.close, size: 18, color: lightColor),
                  label: Text('Xoá sắp xếp', style: TextStyle(color: lightColor)),
                  style: TextButton.styleFrom(
                    backgroundColor: ultraLightColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterOption == label;
    return FilterChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(
        color: isSelected ? Colors.white : accentColor,
      )),
      onSelected: (selected) {
        setState(() {
          _filterOption = label;
          _applyFilters();
        });
      },
      selectedColor: mainColor,
      backgroundColor: ultraLightColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? mainColor : lightColor,
          width: 1,
        ),
      ),
      showCheckmark: true,
      avatar: isSelected ? const Icon(
        Icons.check_circle,
        color: Colors.white,
        size: 16,
      ) : null,
    );
  }

  Widget _buildSortButton({
    required String label,
    required IconData icon,
    required SortOrder sortOrder,
  }) {
    final isSelected = _sortOrder == sortOrder;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _sortOrder = isSelected ? SortOrder.none : sortOrder;
          _applyFilters();
        });
      },
      icon: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : mainColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : mainColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? mainColor : Colors.white,
        side: BorderSide(
          color: mainColor,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildUserStats() {
    final totalUsers = _allUsers.length;
    final usersWithCoupons = _allUsers.where((user) => user.couponIds.isNotEmpty).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: ultraLightColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              label: 'Tổng người dùng',
              value: totalUsers.toString(),
              icon: Icons.people,
              color: mainColor,
            ),
            Container(
              height: 40,
              width: 1,
              color: ultraLightColor,
            ),
            _buildStatItem(
              label: 'Có coupon',
              value: usersWithCoupons.toString(),
              icon: Icons.card_giftcard,
              color: accentColor,
            ),
            Container(
              height: 40,
              width: 1,
              color: ultraLightColor,
            ),
            _buildStatItem(
              label: 'Không có coupon',
              value: (totalUsers - usersWithCoupons).toString(),
              icon: Icons.card_membership,
              color: lightColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ultraLightColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: accentColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: ultraLightColor, width: 1),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserScreen(
                    isNewUser: false,
                    userId: user.userId,
                  ),
                ),
              );
              if (result == true) {
                _loadUsers();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: user.couponIds.isNotEmpty
                                ? accentColor
                                : mainColor,
                            radius: 24,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          if (user.couponIds.isNotEmpty)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.white, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.confirmation_number,
                                  size: 14,
                                  color: accentColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: mainColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${user.userId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: lightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: accentColor),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditUserScreen(
                                isNewUser: false,
                                userId: user.userId,
                              ),
                            ),
                          );
                          if (result == true) {
                            _loadUsers();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: ultraLightColor, thickness: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 16, color: lightColor),
                            const SizedBox(width: 4),
                            Text(
                              user.phone,
                              style: TextStyle(color: accentColor),
                            ),
                          ],
                        ),
                      ),
                      if (user.couponIds.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ultraLightColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.confirmation_number, size: 14, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                '${user.couponIds.length} coupon',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: lightColor),
                            const SizedBox(width: 4),
                            Text(
                              'Cập nhật: ${DateFormat('dd/MM/yyyy - HH:mm').format(user.updatedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: lightColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}