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

  // Colors
  final Color mainColor = Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background

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
      backgroundColor: ultraLightColor.withOpacity(0.5),
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
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 28),
        ),
        backgroundColor: mainColor,
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
                backgroundColor: accentColor,
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
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
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
          color: accentColor,
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
              hintStyle: TextStyle(color: lightColor),
              prefixIcon: Icon(Icons.search, color: accentColor),
              filled: true,
              fillColor: ultraLightColor.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accentColor, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
            style: TextStyle(color: mainColor),
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
                    Text(
                      'Hiển thị: ',
                      style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ultraLightColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<bool>(
                        value: _showActiveOnly,
                        underline: Container(),
                        icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
                        style: TextStyle(color: mainColor),
                        dropdownColor: Colors.white,
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
                    ),
                  ],
                ),
              ),

              // Sort options
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Sắp xếp: ',
                      style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: ultraLightColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<String>(
                        value: _sortOption,
                        underline: Container(),
                        icon: Icon(Icons.keyboard_arrow_down, color: accentColor),
                        style: TextStyle(color: mainColor),
                        dropdownColor: Colors.white,
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
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hiển thị ${_filteredCoupons.length} mã giảm giá',
                style: TextStyle(
                  color: lightColor,
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
            color: lightColor,
          ),
          const SizedBox(height: 20),
          Text(
            'Không Tìm Thấy Mã Giảm Giá',
            style: TextStyle(
              fontSize: 24,
              color: mainColor,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 10),
          _searchQuery.isNotEmpty || !_showActiveOnly
              ? Text(
            'Thử thay đổi bộ lọc tìm kiếm',
            style: TextStyle(
              fontSize: 16,
              color: accentColor,
            ),
          )
              : Text(
            'Bắt đầu bằng việc thêm mã giảm giá đầu tiên',
            style: TextStyle(
              fontSize: 16,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 20),
          if (_searchQuery.isNotEmpty || !_showActiveOnly)
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Xóa bộ lọc'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                color: mainColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: coupon.couponImageUrl,
                      height: constraints.maxWidth * 0.6,
                      width: double.infinity,
                      fit: BoxFit.fitHeight,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: accentColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: constraints.maxWidth * 0.6,
                        color: ultraLightColor,
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: lightColor, size: 48),
                        ),
                      ),
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
                            fontSize: 12,
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
                  padding: const EdgeInsets.all(12.0),
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
                              color: isExpired ? lightColor : mainColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Discount Details
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isExpired ? Colors.grey[200] : ultraLightColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coupon.isPercentage
                                  ? 'Giảm ${coupon.discountValue.toStringAsFixed(0)}%'
                                  : 'Giảm ${Utils.formatCurrency(coupon.discountValue)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isExpired ? Colors.grey[500] : accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Additional Coupon Details
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: isExpired ? Colors.grey[400] : lightColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Hạn đến: ${dateFormat.format(coupon.expiredDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.grey[500] : lightColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 14,
                                color: isExpired ? Colors.grey[400] : lightColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Đơn tối thiểu: ${Utils.formatCurrency(coupon.minPurchaseAmount)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.grey[500] : lightColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Max Discount (if applicable)
                          if (coupon.maxDiscountValue != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.money_off_outlined,
                                  size: 14,
                                  color: isExpired ? Colors.grey[400] : lightColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Giảm tối đa: ${Utils.formatCurrency(coupon.maxDiscountValue!)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isExpired ? Colors.grey[500] : lightColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Action Buttons
                      Row(
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
                                backgroundColor: isExpired ? Colors.grey[200] : ultraLightColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Chỉnh Sửa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.grey[600] : mainColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isExpired ? Colors.grey[200] : Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: isExpired ? Colors.grey[400] : Colors.red[400],
                                size: 20,
                              ),
                              onPressed: () {
                                _showDeleteConfirmation(coupon.couponId);
                              },
                              constraints: BoxConstraints.tightFor(
                                width: 40,
                                height: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Xóa Mã Giảm Giá',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa mã giảm giá này không?',
          style: TextStyle(color: accentColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(color: lightColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCoupon(couponId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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