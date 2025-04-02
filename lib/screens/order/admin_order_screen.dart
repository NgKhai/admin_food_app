import 'package:admin_food_app/models/user_info.dart';
import 'package:admin_food_app/services/admin_account_service.dart';
import 'package:flutter/cupertino.dart';

import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../services/admin_order_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../utils/utils.dart';

// App color scheme
final Color mainColor = Color(0xFF162F4A);     // Deep blue - primary
final Color accentColor = Color(0xFF3A5F82);   // Medium blue - secondary
final Color lightColor = Color(0xFF718EA4);    // Light blue - tertiary
final Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  _AdminOrderScreenState createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final _adminOrderService = AdminOrderService();
  final _adminAccountSerive = AdminAccountService();
  final List<String> statuses = [
    'pending',
    'delivering',
    'preparing',
    'completed',
    'cancelled'
  ];
  String _filterStatus = "all";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ultraLightColor.withOpacity(0.3),
      appBar: AppBar(
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: Text('Quản lý đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: ultraLightColor,
                border: Border.all(color: lightColor.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng...',
                  hintStyle: TextStyle(color: lightColor),
                  prefixIcon: Icon(Icons.search, color: accentColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 16),
          Container(
            height: 45,
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: ultraLightColor,
              border: Border.all(color: lightColor.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                hint: Text("Trạng thái", style: TextStyle(color: accentColor)),
                icon: Icon(Icons.arrow_drop_down, color: accentColor),
                style: TextStyle(color: mainColor, fontWeight: FontWeight.w500),
                items: ["all", ...statuses].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_adminOrderService.getStatusText(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return StreamBuilder<List<OrderProduct>>(
      stream: _adminOrderService.getOrders(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        List<OrderProduct> orders = snapshot.data!;

        // Apply filters
        if (_filterStatus != "all") {
          orders = orders.where((order) => order.status == _filterStatus).toList();
        }

        if (_searchQuery.isNotEmpty) {
          orders = orders
              .where((order) => order.orderId
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
              .toList();
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 70, color: lightColor),
                SizedBox(height: 16),
                Text(
                  'Không tìm thấy đơn hàng nào',
                  style: TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return FutureBuilder<UserInfo?>(
              future: _adminAccountSerive.getUserAccount(order.userId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator(color: accentColor)),
                  );
                }

                UserInfo userInfo = userSnapshot.data!;

                return _buildOrderCard(order, userInfo, context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderProduct order, UserInfo user, BuildContext context) {
    // Keep the original status colors as requested
    final Map<String, Color> statusColors = {
      'completed': Colors.teal.shade700,
      'cancelled': Colors.deepOrange.shade700,
      'preparing': Colors.amber.shade700,
      'delivering': Colors.blueAccent.shade700,
      'pending': Colors.purple.shade700,
    };

    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
    Color statusColor = statusColors[order.status] ?? Colors.grey.shade700;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: ultraLightColor.withOpacity(0.2),
          iconColor: accentColor,
          collapsedIconColor: accentColor,
          title: _buildOrderHeader(order, formattedDate, statusColor),
          children: [
            Divider(height: 1, color: lightColor.withOpacity(0.3)),
            _buildOrderDetails(order, user, context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderProduct order, String formattedDate, Color statusColor) {
    return Row(
      children: [
        // Status Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Text(
            _adminOrderService.getStatusText(order.status),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        SizedBox(width: 12),
        // Order Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đơn hàng #${order.orderId}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: mainColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  color: lightColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Total Price
        Text(
          Utils.formatCurrency(order.totalPrice),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(OrderProduct order, UserInfo user, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Information Section
          _buildSectionHeader('Thông tin khách hàng', CupertinoIcons.person),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ultraLightColor, width: 1.5),
            ),
            child: Column(
              children: [
                _infoRow('Tên', user.name),
                Divider(height: 16, color: ultraLightColor),
                _infoRow('Số điện thoại', user.phone),
                Divider(height: 16, color: ultraLightColor),
                _infoRow('Địa chỉ giao hàng', order.deliveryAddressName ?? 'Khách tự đến lấy'),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Order Details Section
          _buildSectionHeader('Chi tiết đơn hàng', CupertinoIcons.doc_text),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ultraLightColor, width: 1.5),
            ),
            child: Column(
              children: [
                _infoRow('Phương thức thanh toán', order.paymentMethod),
                Divider(height: 16, color: ultraLightColor),
                _infoRow('Phí giao hàng', Utils.formatCurrency(order.deliveryFee)),
                Divider(height: 16, color: ultraLightColor),
                _infoRow('Chiết khấu đơn hàng', order.orderDiscount != null
                    ? Utils.formatCurrency(order.orderDiscount!)
                    : 'Không có'),
                Divider(height: 16, color: ultraLightColor),
                _infoRow('Ghi chú', order.note ?? 'Không có ghi chú'),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Order Items Section
          _buildSectionHeader('Sản phẩm', CupertinoIcons.cart),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ultraLightColor, width: 1.5),
            ),
            child: Column(
              children: order.listCartItem.map((item) => Column(
                children: [
                  _buildOrderItem(item),
                  if (item != order.listCartItem.last)
                    Divider(height: 16, color: ultraLightColor),
                ],
              )).toList(),
            ),
          ),

          SizedBox(height: 20),

          // Status Management Section
          _buildStatusManagement(order, context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accentColor),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: mainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.productId,
              style: TextStyle(fontWeight: FontWeight.w500, color: mainColor),
            ),
          ),
          Text(
            '${item.quantity} x ${Utils.formatCurrency(item.unitPrice)}',
            style: TextStyle(color: accentColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusManagement(OrderProduct order, BuildContext context) {
    // Keep the original status colors as requested
    final Map<String, Color> statusColors = {
      'completed': Colors.teal.shade700,
      'cancelled': Colors.deepOrange.shade700,
      'preparing': Colors.amber.shade700,
      'delivering': Colors.blueAccent.shade700,
      'pending': Colors.purple.shade700,
    };

    Color currentStatusColor = statusColors[order.status] ?? Colors.grey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cập nhật trạng thái', CupertinoIcons.refresh),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: currentStatusColor.withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.info_circle, color: currentStatusColor, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Trạng thái hiện tại: ${_adminOrderService.getStatusText(order.status)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: currentStatusColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Cập nhật trạng thái',
                          labelStyle: TextStyle(color: accentColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: order.status,
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: accentColor),
                        onChanged: (String? newStatus) {
                          if (newStatus != null) {
                            _adminOrderService.updateOrderStatus(order.orderId, newStatus);
                          }
                        },
                        items: statuses.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(
                              _adminOrderService.getStatusText(status),
                              style: TextStyle(color: mainColor),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _showCancelOrderDialog(context, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelOrderDialog(BuildContext context, OrderProduct order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy đơn hàng', style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này? Hành động này không thể hoàn tác.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Quay lại', style: TextStyle(color: accentColor)),
          ),
          ElevatedButton(
            onPressed: () {
              _adminOrderService.updateOrderStatus(order.orderId, "cancelled");
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Xác nhận hủy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              color: lightColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: mainColor,
            ),
          ),
        ),
      ],
    );
  }
}