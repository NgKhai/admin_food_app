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
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                CupertinoIcons.back,
                size: 32,
              )),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đơn hàng...',
                  prefixIcon: Icon(Icons.search),
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
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                hint: Text("Trạng thái"),
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
          return Center(child: CircularProgressIndicator());
        }

        List<OrderProduct> orders = snapshot.data!;

        // Apply filters
        if (_filterStatus != "all") {
          orders =
              orders.where((order) => order.status == _filterStatus).toList();
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
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Không tìm thấy đơn hàng nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
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
                  return Center(child: CircularProgressIndicator());
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

  Widget _buildOrderCard(
      OrderProduct order, UserInfo user, BuildContext context) {
    // Status color mapping
    final Map<String, Color> statusColors = {
      'completed': Colors.teal.shade700,
      'cancelled': Colors.deepOrange.shade700,
      'preparing': Colors.amber.shade700,
      'delivering': Colors.blueAccent.shade700,
      'pending': Colors.purple.shade700,
    };

    // Format date
    String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt);
    Color statusColor = statusColors[order.status] ?? Colors.grey.shade700;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: _buildOrderHeader(order, formattedDate, statusColor),
        children: [
          Divider(height: 1, color: Colors.grey.shade300),
          _buildOrderDetails(order, user, context),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(OrderProduct order, String formattedDate, Color statusColor) {
    return Row(
      children: [
        // Status Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
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
                ),
              ),
              SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.grey,
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
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDetails(OrderProduct order, UserInfo user, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Information Section
          _buildSectionHeader('Thông tin khách hàng'),
          _infoRow('Tên', user.name),
          _infoRow('Số điện thoại', user.phone),
          _infoRow('Địa chỉ giao hàng', order.deliveryAddressName ?? 'Khách tự đến lấy'),

          SizedBox(height: 16),

          // Order Details Section
          _buildSectionHeader('Chi tiết đơn hàng'),
          _infoRow('Phương thức thanh toán', order.paymentMethod),
          _infoRow('Phí giao hàng', Utils.formatCurrency(order.deliveryFee)),
          _infoRow('Chiết khấu đơn hàng', order.orderDiscount != null
              ? Utils.formatCurrency(order.orderDiscount!)
              : 'Không có'),
          _infoRow('Ghi chú', order.note ?? 'Không có ghi chú'),

          SizedBox(height: 16),

          // Order Items Section
          _buildSectionHeader('Sản phẩm'),
          ...order.listCartItem.map((item) => _buildOrderItem(item)).toList(),

          SizedBox(height: 16),

          // Status Management Section
          _buildStatusManagement(order, context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
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
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${item.quantity} x ${Utils.formatCurrency(item.unitPrice)}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusManagement(OrderProduct order, BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Cập nhật trạng thái',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: order.status,
                onChanged: (String? newStatus) {
                  if (newStatus != null) {
                    _adminOrderService.updateOrderStatus(order.orderId, newStatus);
                  }
                },
                items: statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_adminOrderService.getStatusText(status)),
                  );
                }).toList(),
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => _showCancelOrderDialog(context, order),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Hủy đơn'),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelOrderDialog(BuildContext context, OrderProduct order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận hủy đơn hàng'),
        content: Text('Bạn có chắc chắn muốn hủy đơn hàng này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Quay lại'),
          ),
          TextButton(
            onPressed: () {
              _adminOrderService.updateOrderStatus(order.orderId, "cancelled");
              Navigator.pop(context);
            },
            child: Text(
              'Xác nhận hủy',
              style: TextStyle(color: Colors.red),
            ),
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
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
