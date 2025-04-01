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
        title: const Text(
          'Quản lý Người dùng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(CupertinoIcons.back, color: Colors.white, size: 32,)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSearchAndFilterSection(),
            const SizedBox(height: 8),
            _buildUserStats(),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Không tìm thấy người dùng nào',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
                  : _buildUserList(),
            ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     final result = await Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => EditUserScreen(isNewUser: true),
      //       ),
      //     );
      //     if (result == true) {
      //       _loadUsers();
      //     }
      //   },
      //   icon: const Icon(Icons.add),
      //   label: const Text('Thêm người dùng'),
      //   backgroundColor: Theme.of(context).primaryColor,
      //   foregroundColor: Colors.white,
      //   elevation: 4,
      // ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Lọc:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text('Sắp xếp:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Xoá sắp xếp'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
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
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _filterOption = label;
          _applyFilters();
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        ),
      ),
      showCheckmark: true,
      avatar: isSelected ? Icon(
        Icons.check_circle,
        color: Theme.of(context).primaryColor,
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
        color: isSelected ? Colors.white : Theme.of(context).primaryColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).primaryColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).primaryColor : Colors.white,
        side: BorderSide(
          color: Theme.of(context).primaryColor,
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
        padding: const EdgeInsets.all(12),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Theme.of(context).primaryColor.withOpacity(0.15),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              label: 'Tổng người dùng',
              value: totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
            ),
            _buildStatItem(
              label: 'Có coupon',
              value: usersWithCoupons.toString(),
              icon: Icons.card_giftcard,
              color: Colors.green,
            ),
            Container(
              height: 40,
              width: 1,
              color: Colors.grey[300],
            ),
            _buildStatItem(
              label: 'Không có coupon',
              value: (totalUsers - usersWithCoupons).toString(),
              icon: Icons.card_membership,
              color: Colors.orange,
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
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
            color: Colors.grey[600],
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
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  user.couponIds.isNotEmpty
                      ? Colors.green.withOpacity(0.05)
                      : Colors.blue.withOpacity(0.05),
                ],
              ),
            ),
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
                                  ? Colors.green.withOpacity(0.2)
                                  : Theme.of(context).primaryColor.withOpacity(0.2),
                              radius: 24,
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: user.couponIds.isNotEmpty
                                      ? Colors.green
                                      : Theme.of(context).primaryColor,
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
                                  child: const Icon(
                                    Icons.confirmation_number,
                                    size: 14,
                                    color: Colors.green,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${user.userId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // PopupMenuButton<String>(
                        //   icon: const Icon(Icons.more_vert),
                        //   onSelected: (value) async {
                        //     if (value == 'edit') {
                        //       final result = await Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (context) => EditUserScreen(
                        //             isNewUser: false,
                        //             userId: user.userId,
                        //           ),
                        //         ),
                        //       );
                        //       if (result == true) {
                        //         _loadUsers();
                        //       }
                        //     } else if (value == 'delete') {
                        //       showDialog(
                        //         context: context,
                        //         builder: (context) => AlertDialog(
                        //           title: const Text('Xác nhận xóa'),
                        //           content: Text(
                        //             'Bạn có chắc chắn muốn xóa người dùng "${user.name}" không?',
                        //           ),
                        //           actions: [
                        //             TextButton(
                        //               onPressed: () => Navigator.pop(context),
                        //               child: const Text('Hủy'),
                        //             ),
                        //             TextButton(
                        //               onPressed: () {
                        //                 Navigator.pop(context);
                        //                 _deleteUser(user.userId);
                        //               },
                        //               child: const Text(
                        //                 'Xóa',
                        //                 style: TextStyle(color: Colors.red),
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //       );
                        //     }
                        //   },
                        //   itemBuilder: (context) => [
                        //     const PopupMenuItem(
                        //       value: 'edit',
                        //       child: Row(
                        //         children: [
                        //           Icon(Icons.edit, color: Colors.blue),
                        //           SizedBox(width: 8),
                        //           Text('Chỉnh sửa'),
                        //         ],
                        //       ),
                        //     ),
                        //     const PopupMenuItem(
                        //       value: 'delete',
                        //       child: Row(
                        //         children: [
                        //           Icon(Icons.delete, color: Colors.red),
                        //           SizedBox(width: 8),
                        //           Text('Xóa', style: TextStyle(color: Colors.red)),
                        //         ],
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey[200]),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                user.phone,
                                style: TextStyle(color: Colors.grey[800]),
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
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.confirmation_number, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  '${user.couponIds.length} coupon',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
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
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Cập nhật: ${DateFormat('dd/MM/yyyy - HH:mm').format(user.updatedAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
          ),
        );
      },
    );
  }
}