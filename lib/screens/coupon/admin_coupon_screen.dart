import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/coupon.dart';
import '../../services/admin_coupon_service.dart';
import 'admin_coupon_form_screen.dart';
import '../../utils/utils.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  _AdminCouponScreenState createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> with SingleTickerProviderStateMixin {
  final CouponService _couponService = CouponService();
  List<Coupon> _allCoupons = [];
  List<Coupon> _filteredCoupons = [];
  bool _isLoading = true;

  // Tab controller for order/shipping tabs
  late TabController _tabController;

  // Search and filter variables
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showActiveOnly = true;
  String _sortOption = 'expiredDate';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchCoupons();

    _searchController.addListener(() {
      _updateFilters();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || _tabController.index != _tabController.previousIndex) {
      _updateFilters();
    }
  }

  void _fetchCoupons() {
    _couponService.getCoupons().listen((coupons) {
      setState(() {
        _allCoupons = coupons;
        _updateFilters();
        _isLoading = false;
      });
    });
  }

  void _updateFilters() {
    setState(() {
      // First filter by tab (All, Order, Shipping)
      if (_tabController.index == 0) {
        _filteredCoupons = List.from(_allCoupons);
      } else if (_tabController.index == 1) {
        _filteredCoupons = _allCoupons.where((coupon) => coupon.type == CouponType.order).toList();
      } else {
        _filteredCoupons = _allCoupons.where((coupon) => coupon.type == CouponType.shipping).toList();
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        _filteredCoupons = _filteredCoupons.where((coupon) =>
        coupon.couponName.toLowerCase().contains(query) ||
            coupon.couponId.toLowerCase().contains(query)
        ).toList();
      }

      // Filter by active/expired status
      if (_showActiveOnly) {
        final now = DateTime.now();
        _filteredCoupons = _filteredCoupons.where((coupon) => coupon.expiredDate.isAfter(now)).toList();
      }

      // Sort coupons
      _sortCoupons();
    });
  }

  void _sortCoupons() {
    switch (_sortOption) {
      case 'name':
        _filteredCoupons.sort((a, b) => a.couponName.compareTo(b.couponName));
        break;
      case 'expiredDate':
        _filteredCoupons.sort((a, b) => a.expiredDate.compareTo(b.expiredDate));
        break;
      case 'discountValue':
        _filteredCoupons.sort((a, b) => b.discountValue.compareTo(a.discountValue));
        break;
      case 'minPurchaseAmount':
        _filteredCoupons.sort((a, b) => a.minPurchaseAmount.compareTo(b.minPurchaseAmount));
        break;
    }
  }

  void _deleteCoupon(String id) async {
    setState(() {
      _isLoading = true;
    });

    await _couponService.deleteCoupon(id);
    _fetchCoupons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Quản Lý Mã Giảm Giá',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 32),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        actions: [
          Container(
            height: 40,
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text(
                'Thêm Mã Giảm Giá',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AdminCouponFormScreen(),
                  ),
                ).then((_) => _fetchCoupons());
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Tất Cả'),
            Tab(text: 'Đơn Hàng'),
            Tab(text: 'Vận Chuyển'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.teal[600],
        ),
      )
          : Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: _filteredCoupons.isEmpty
                ? _buildEmptyState()
                : _buildCouponList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm mã giảm giá...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _updateFilters();
              });
            },
          ),

          SizedBox(height: 16),

          // Filter options
          Row(
            children: [
              // Active/Expired filter
              Expanded(
                child: Row(
                  children: [
                    Text('Hiển thị: '),
                    SizedBox(width: 8),
                    DropdownButton<bool>(
                      value: _showActiveOnly,
                      underline: Container(),
                      items: [
                        DropdownMenuItem(
                          value: true,
                          child: Text('Còn hiệu lực'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('Tất cả'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _showActiveOnly = value!;
                          _updateFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Sort options
              Expanded(
                child: Row(
                  children: [
                    Text('Sắp xếp: '),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortOption,
                      underline: Container(),
                      items: [
                        DropdownMenuItem(
                          value: 'expiredDate',
                          child: Text('Ngày hết hạn'),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('Tên mã'),
                        ),
                        DropdownMenuItem(
                          value: 'discountValue',
                          child: Text('Giá trị'),
                        ),
                        DropdownMenuItem(
                          value: 'minPurchaseAmount',
                          child: Text('Giá trị đơn tối thiểu'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortOption = value!;
                          _updateFilters();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hiển thị ${_filteredCoupons.length} mã giảm giá',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Không Tìm Thấy Mã Giảm Giá',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 10),
          _searchQuery.isNotEmpty || !_showActiveOnly
              ? Text(
            'Thử thay đổi bộ lọc tìm kiếm',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          )
              : Text(
            'Bắt đầu bằng việc thêm mã giảm giá đầu tiên',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          if (_searchQuery.isNotEmpty || !_showActiveOnly)
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Xóa bộ lọc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[400],
              ),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _showActiveOnly = true;
                  _sortOption = 'expiredDate';
                  _updateFilters();
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCouponList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 350,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredCoupons.length,
      itemBuilder: (context, index) {
        final coupon = _filteredCoupons[index];
        return _buildCouponCard(coupon);
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isExpired = coupon.expiredDate.isBefore(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Coupon Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: CachedNetworkImage(
                      imageUrl: coupon.couponImageUrl,
                      height: constraints.maxWidth * 0.6,
                      width: double.infinity,
                      fit: BoxFit.fitHeight,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: Colors.teal[300],
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                  if (isExpired)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Đã Hết Hạn',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Badge for coupon type
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: coupon.type == CouponType.order
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.purple.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        coupon.type == CouponType.order ? 'Đơn Hàng' : 'Vận Chuyển',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Coupon Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.couponName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.grey[600] : Colors.teal[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Discount Details
                          Text(
                            coupon.isPercentage
                                ? 'Giảm ${coupon.discountValue.toStringAsFixed(0)}%'
                                : 'Giảm ${Utils.formatCurrency(coupon.discountValue)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isExpired ? Colors.grey[500] : Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Additional Coupon Details
                          Text(
                            'Hạn đến: ${dateFormat.format(coupon.expiredDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? Colors.grey[500] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Đơn tối thiểu: ${Utils.formatCurrency(coupon.minPurchaseAmount)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isExpired ? Colors.grey[500] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Max Discount (if applicable)
                          if (coupon.maxDiscountValue != null)
                            Text(
                              'Giảm tối đa: ${Utils.formatCurrency(coupon.maxDiscountValue!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isExpired ? Colors.grey[500] : Colors.grey[700],
                              ),
                            ),
                        ],
                      ),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminCouponFormScreen(
                                      existingCoupon: coupon,
                                    ),
                                  ),
                                ).then((_) => _fetchCoupons());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExpired ? Colors.grey[300] : Colors.teal[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Chỉnh Sửa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.grey[600] : Colors.teal[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: isExpired ? Colors.grey[400] : Colors.red[400],
                              size: 20,
                            ),
                            onPressed: () {
                              _showDeleteConfirmation(coupon.couponId);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(String couponId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa Mã Giảm Giá',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa mã giảm giá này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCoupon(couponId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
            ),
            child: Text(
              'Xóa',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}