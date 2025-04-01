import 'package:admin_food_app/screens/address/admin_address_screen.dart';
import 'package:admin_food_app/screens/coupon/admin_coupon_screen.dart';
import 'package:admin_food_app/screens/order/admin_order_screen.dart';
import 'package:admin_food_app/screens/product/admin_product_screen.dart';
import 'package:admin_food_app/screens/user/admin_user_screen.dart';
import 'package:admin_food_app/services/admin_account_service.dart';
import 'package:admin_food_app/services/admin_order_service.dart';
import 'package:admin_food_app/services/admin_product_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../services/admin_auth_service.dart';
import '../utils/utils.dart';
import 'login/admin_login_screen.dart';
import 'notification/admin_notification_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Dashboard Statistics
  int totalUsers = 0;
  int totalOrders = 0;
  double totalRevenue = 0;
  List<dynamic> topProducts = [];
  List<dynamic> recentOrders = [];

  // Service instances
  final _userService = AdminAccountService();
  final _orderService = AdminOrderService();
  final _productService = ProductService();

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      // Fetch users count
      totalUsers = await _userService.getTotalUsersCount();

      // Fetch order analytics
      final orderAnalytics = await _orderService.getOrderAnalytics();
      setState(() {
        totalOrders = orderAnalytics['totalOrders'] ?? 0;
        totalRevenue = orderAnalytics['totalRevenue'] ?? 0.0;
      });

      // Fetch top selling products
      final topProductsData = await _productService.getTopSellingProducts();

      // Enrich top products with sales count
      final orderAnalyticsProductSales = orderAnalytics['productSales'] ?? {};
      setState(() {
        topProducts = topProductsData
            .map((product) => {
                  ...product.toJson(),
                  'salesCount':
                      orderAnalyticsProductSales[product.productId] ?? 0
                })
            .toList();
      });

      // Fetch recent orders
      final recentOrdersData = await _orderService.getRecentOrders();
      setState(() {
        recentOrders = recentOrdersData.map((order) => order.toJson()).toList();
      });
    } catch (e) {
      print('Lỗi khi tải dữ liệu bảng điều khiển: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải dữ liệu: $e')),
      );
    }
  }

  void _handleLogout() async {
    await AdminAuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AdminLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Crunch n Dash',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black26,
                offset: Offset(2.0, 2.0),
              )
            ],
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[700]!, Colors.deepPurpleAccent[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
            onPressed: () {
              // Handle logout logic here
              _handleLogout();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple[200]!,
                  Colors.deepPurple[100]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                )
              ],
            ),
            child: ListView(
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple[500]!,
                        Colors.deepPurpleAccent[200]!
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  accountName: Text(
                    'Quản Trị Viên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  accountEmail: Text('admin@gmail.com'),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Colors.deepPurple,
                      size: 40,
                    ),
                  ),
                ),
                // _buildNavItem(Icons.dashboard, 'Bảng Điều Khiển', () {}),
                _buildNavItem(Icons.people, 'Người Dùng', () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdminUserScreen()));
                }),
                _buildNavItem(Icons.shopping_cart, 'Đơn Hàng', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdminOrderScreen()));
                }),
                _buildNavItem(Icons.fastfood, 'Sản Phẩm', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdminProductScreen()));
                }),
                _buildNavItem(Icons.location_on, 'Địa Chỉ', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddressManagementScreen()));
                }),
                _buildNavItem(Icons.discount, 'Mã Giảm Giá', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AdminCouponScreen()));
                }),
                _buildNavItem(Icons.notifications, 'Thông Báo', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UserNotificationManager()));
                }),
              ],
            ),
          ),
          // Main Dashboard Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Cards
                    _buildQuickStatsRow(),

                    const SizedBox(height: 20),

                    // Charts and Detailed Stats
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Products Chart
                        Expanded(
                          child: _buildTopProductsChart(),
                        ),
                        const SizedBox(width: 20),
                        // Recent Orders
                        Expanded(
                          child: _buildRecentOrdersList(),
                        ),
                      ],
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

  Widget _buildNavItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple[700], size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.deepPurple[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
        hoverColor: Colors.deepPurple[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          title: 'Tổng Người Dùng',
          value: totalUsers.toString(),
          icon: Icons.people,
          color: Colors.blue[700]!,
        ),
        _buildStatCard(
          title: 'Tổng Đơn Hàng',
          value: totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.green[700]!,
        ),
        _buildStatCard(
          title: 'Tổng Doanh Thu',
          value: NumberFormat.currency(symbol: 'đ').format(totalRevenue),
          icon: Icons.monetization_on,
          color: Colors.orange[700]!,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 6,
        shadowColor: color.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white, size: 40),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title == 'Tổng Doanh Thu'
                      ? Utils.formatCurrency(
                          double.parse(value.replaceAll(RegExp(r'[^\d.]'), '')))
                      : value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProductsChart() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Sản Phẩm Bán Chạy Nhất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: topProducts.map((product) {
                    return BarChartGroupData(
                      x: topProducts.indexOf(product),
                      barRods: [
                        BarChartRodData(
                          toY: (product['salesCount'] ?? 0).toDouble(),
                          color: Colors.deepPurple[600],
                          width: 22,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              index < topProducts.length
                                  ? topProducts[index]['productName']
                                  : '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.deepPurple,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersList() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn Hàng Gần Đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            const SizedBox(height: 10),
            ...recentOrders
                .map((order) => Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        title: Text(
                          'Đơn Hàng #${order['orderId']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                        subtitle: Text(
                          'Tổng: ${Utils.formatCurrency(order['totalPrice'])}',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                        trailing: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(
                              (order['createdAt'] as Timestamp).toDate()),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }
}
