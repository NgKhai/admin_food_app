import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:admin_food_app/models/user_info.dart';
import 'package:admin_food_app/services/admin_account_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../models/notify.dart';
import '../../services/admin_notification_service.dart';

class UserNotificationManager extends StatefulWidget {
  const UserNotificationManager({Key? key}) : super(key: key);

  @override
  State<UserNotificationManager> createState() =>
      _UserNotificationManagerState();
}

class _UserNotificationManagerState extends State<UserNotificationManager>
    with SingleTickerProviderStateMixin {
  final AdminAccountService _accountService = AdminAccountService();
  final NotificationService _notificationService = NotificationService();

  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _couponIdController = TextEditingController();

  List<UserInfo> _users = [];
  List<UserInfo> _filteredUsers = [];
  List<UserInfo> _selectedUsers = [];
  List<Notify> _recentNotifications = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _searchQuery = '';

  // Theme colors
  final Color _primaryColor = Colors.deepPurple;
  final Color _accentColor = Colors.amber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
    _loadRecentNotifications();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _couponIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final users = await _accountService.getAllUsers();

    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  Future<void> _loadRecentNotifications() async {
    // Here we could load the 10 most recent notifications sent from the server
    // For now, I'll use dummy data
    setState(() {
      _recentNotifications = [
        Notify(
          title: "Welcome",
          body: "Welcome to our app!",
          dateCreated: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Notify(
          title: "New Promotion",
          body: "Check out our latest deals!",
          dateCreated: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.phone.contains(query) ||
              user.userId.contains(query);
        }).toList();
      }
    });
  }

  void _toggleUserSelection(UserInfo user) {
    setState(() {
      if (_selectedUsers.any((u) => u.userId == user.userId)) {
        _selectedUsers.removeWhere((u) => u.userId == user.userId);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _sendNotificationToSelected() async {
    if (_selectedUsers.isEmpty) {
      _showSnackBar('Vui lòng chọn ít nhất một người dùng', isError: true);
      return;
    }

    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề và nội dung thông báo',
          isError: true);
      return;
    }

    setState(() {
      _isSending = true;
    });

    final userIds = _selectedUsers.map((user) => user.userId).toList();
    final results = await _notificationService.sendBulkNotifications(
      userIds: userIds,
      title: _titleController.text,
      body: _bodyController.text,
    );

    setState(() {
      _isSending = false;
    });

    // Add to recent notifications
    final newNotify = Notify(
      title: _titleController.text,
      body: _bodyController.text,
      dateCreated: DateTime.now(),
    );

    setState(() {
      _recentNotifications.insert(0, newNotify);
      _titleController.clear();
      _bodyController.clear();
      _selectedUsers.clear();
    });

    // Count successful and failed notifications
    final successCount = results.values.where((success) => success).length;
    final failedCount = results.values.where((success) => !success).length;

    _showSnackBar(
      'Đã gửi thành công $successCount thông báo${failedCount > 0 ? ", $failedCount thất bại" : ""}',
      isError: failedCount > 0,
    );

    if (successCount > 0) {
      _showSuccessDialog();
    }
  }

  Future<void> _sendNotificationToAllUsers() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề và nội dung thông báo',
          isError: true);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận'),
        content: Text(
            'Bạn có chắc chắn muốn gửi thông báo đến tất cả ${_users.length} người dùng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Gửi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSending = true;
    });

    final success = await _notificationService.sendNotificationToAllUsers(
      title: _titleController.text,
      body: _bodyController.text,
      accountService: _accountService,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      // Add to recent notifications
      final newNotify = Notify(
        title: _titleController.text,
        body: _bodyController.text,
        dateCreated: DateTime.now(),
      );

      setState(() {
        _recentNotifications.insert(0, newNotify);
        _titleController.clear();
        _bodyController.clear();
      });

      _showSnackBar('Đã gửi thông báo đến tất cả ${_users.length} người dùng');
      _showSuccessDialog();
    } else {
      _showSnackBar('Gửi thông báo thất bại', isError: true);
    }
  }

  Future<void> _sendNotificationToCouponHolders() async {
    if (_titleController.text.isEmpty ||
        _bodyController.text.isEmpty ||
        _couponIdController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập tiêu đề, nội dung và mã coupon',
          isError: true);
      return;
    }

    setState(() {
      _isSending = true;
    });

    final success = await _notificationService.sendNotificationToCouponHolders(
      couponId: _couponIdController.text,
      title: _titleController.text,
      body: _bodyController.text,
      accountService: _accountService,
    );

    setState(() {
      _isSending = false;
    });

    if (success) {
      // Add to recent notifications
      final newNotify = Notify(
        title: _titleController.text,
        body: _bodyController.text,
        dateCreated: DateTime.now(),
      );

      setState(() {
        _recentNotifications.insert(0, newNotify);
        _titleController.clear();
        _bodyController.clear();
        _couponIdController.clear();
      });

      _showSnackBar('Đã gửi thông báo đến người dùng có coupon');
      _showSuccessDialog();
    } else {
      _showSnackBar('Không tìm thấy người dùng có coupon này hoặc gửi thất bại',
          isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.network(
                'https://assets4.lottiefiles.com/packages/lf20_xvrofzfk.json',
                height: 150,
                repeat: false,
              ),
              const SizedBox(height: 20),
              const Text(
                'Thành công!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Thông báo đã được gửi thành công đến người dùng',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final Color _primaryColor = Color(0xFF162F4A); // Deep blue - primary
    final Color _accentColor = Color(0xFF3A5F82); // Medium blue - secondary
    final Color _tertiaryColor = Color(0xFF718EA4); // Light blue - tertiary
    final Color _backgroundColor = Color(0xFFD0DCE7); // Very light blue - background

    return Theme(
      data: ThemeData(
        primaryColor: _primaryColor,
        colorScheme: ColorScheme.light(
          primary: _primaryColor,
          secondary: _accentColor,
          tertiary: _tertiaryColor,
          background: _backgroundColor,
        ),
        scaffoldBackgroundColor: _backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicator: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shadowColor: _primaryColor.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _primaryColor, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return _primaryColor;
            }
            return null;
          }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              const Text(
                'Quản lý thông báo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(CupertinoIcons.back, color: Colors.white, size: 32,)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Làm mới',
              onPressed: () {
                _loadUsers();
                _loadRecentNotifications();
                _showSnackBar('Đã làm mới dữ liệu');
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TabBar(
                  controller: _tabController,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: _primaryColor), // Độ dày và màu gạch dưới
                  ),
                  labelColor: Colors.black, // Giữ màu chữ đen khi chọn
                  unselectedLabelColor: Colors.grey.shade700, // Màu chữ khi không chọn
                  dividerColor: Colors.transparent, // Ẩn đường kẻ trên tab
                  tabs: [
                    Tab(
                      icon: Icon(Icons.notifications_active, size: 20),
                      child: Text(
                        'Tạo thông báo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      icon: Icon(Icons.people, size: 20),
                      child: Text(
                        'Người dùng',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Tab(
                      icon: Icon(Icons.history, size: 20),
                      child: Text(
                        'Lịch sử',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade100,
                Colors.white,
              ],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSendNotificationTab(),
              _buildUsersTab(),
              _buildNotificationHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderWithIcon(
            'Tạo thông báo mới',
            Icons.notifications_active,
            _accentColor,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Nội dung thông báo', Icons.edit),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      hintText: 'Nhập tiêu đề thông báo',
                      prefixIcon: Icon(Icons.title),
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      hintText: 'Nhập nội dung thông báo chi tiết',
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  if (_titleController.text.isNotEmpty ||
                      _bodyController.text.isNotEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xem trước thông báo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _titleController.text.isEmpty
                                          ? 'Tiêu đề thông báo'
                                          : _titleController.text,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _bodyController.text.isEmpty
                                          ? 'Nội dung thông báo'
                                          : _bodyController.text,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Bây giờ',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Người nhận', Icons.people),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.group,
                          label:
                              'Người dùng đã chọn (${_selectedUsers.length})',
                          onPressed: () {
                            _tabController.animateTo(1);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.group_add,
                          label: 'Tất cả người dùng (${_users.length})',
                          color: Colors.blue,
                          onPressed: _sendNotificationToAllUsers,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // TextField(
                  //   controller: _couponIdController,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Mã Coupon',
                  //     hintText: 'Gửi cho người dùng có coupon này',
                  //     prefixIcon: Icon(Icons.card_giftcard),
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: _buildActionButton(
                  //     icon: Icons.card_giftcard,
                  //     color: Colors.orange,
                  //     label: 'Gửi cho người dùng có coupon',
                  //     onPressed: _sendNotificationToCouponHolders,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 60,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotificationToSelected,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
              label: Text(
                _isSending ? 'Đang gửi...' : 'Gửi thông báo',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSending ? Colors.grey : _primaryColor,
                elevation: _isSending ? 2 : 8,
                shadowColor: _primaryColor.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm người dùng',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _filterUsers('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onChanged: _filterUsers,
          ),
        ),
        const SizedBox(height: 8),
        _selectedUsers.isNotEmpty
            ? Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _selectedUsers.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Đã chọn ${_selectedUsers.length} người dùng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedUsers.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Bỏ chọn tất cả'),
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryColor,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: _primaryColor,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: _primaryColor,
                  child: _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không tìm thấy người dùng',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredUsers.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final isSelected = _selectedUsers
                                .any((u) => u.userId == user.userId);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? _accentColor.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _accentColor : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected ? _primaryColor.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CheckboxListTile(
                                title: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? _primaryColor
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user.phone,
                                          style: TextStyle(
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.card_giftcard,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${user.couponIds.length} coupon',
                                          style: TextStyle(
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.perm_identity,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            user.userId,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontFamily: 'monospace',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                secondary: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? _primaryColor
                                      : Colors.grey.shade200,
                                  child: Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                value: isSelected,
                                onChanged: (_) => _toggleUserSelection(user),
                                activeColor: _primaryColor,
                                checkColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationHistoryTab() {
    return _recentNotifications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.network(
                  'https://assets3.lottiefiles.com/packages/lf20_XyoSty.json',
                  height: 200,
                ),
                const SizedBox(height: 20),
                Text(
                  'Chưa có thông báo nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thông báo đã gửi sẽ xuất hiện tại đây',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _recentNotifications.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final notification = _recentNotifications[index];
              final isToday =
                  notification.dateCreated.day == DateTime.now().day;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  notification.body,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isToday
                                  ? 'Hôm nay, ${DateFormat('HH:mm').format(notification.dateCreated)}'
                                  : DateFormat('dd/MM/yyyy, HH:mm')
                                      .format(notification.dateCreated),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildHeaderWithIcon(String title, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: _primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.green,
  }) {
    return ElevatedButton.icon(
      onPressed: _isSending ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
      ),
    );
  }
}
