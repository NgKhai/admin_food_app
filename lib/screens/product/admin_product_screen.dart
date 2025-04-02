import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/admin_product_service.dart';
import '../../utils/utils.dart';
import 'admin_edit_product_screen.dart';
import 'admin_add_product_screen.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({super.key});

  @override
  _AdminProductScreenState createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  // Color scheme
  final Color mainColor = Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background

  final AdminProductService _productService = AdminProductService();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];

  // Search and Filter Variables
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _isLoading = true;

  // Filter Options
  final List<String> _sortOptions = [
    'Tên (A-Z)',
    'Tên (Z-A)',
    'Giá (Thấp đến Cao)',
    'Giá (Cao đến Thấp)',
    'Thời gian chuẩn bị',
    'Lượng Calo',
  ];
  String _currentSortOption = 'Tên (A-Z)';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProductsAndCategories();
  }

  Future<void> _fetchProductsAndCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch products with categories
      final products = await _productService.getProductsWithCategories();

      // Fetch categories
      final categoriesSnapshot =
      await FirebaseFirestore.instance.collection('categories').get();

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _categories = categoriesSnapshot.docs
            .map((doc) => Category.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi không thể tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            product.productName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        // Category filter
        bool matchesCategory = _selectedCategoryId == null ||
            product.categoryId == _selectedCategoryId;

        return matchesSearch && matchesCategory;
      }).toList();

      // Sorting
      switch (_currentSortOption) {
        case 'Tên (A-Z)':
          _filteredProducts
              .sort((a, b) => a.productName.compareTo(b.productName));
          break;
        case 'Tên (Z-A)':
          _filteredProducts
              .sort((a, b) => b.productName.compareTo(a.productName));
          break;
        case 'Giá (Thấp đến Cao)':
          _filteredProducts
              .sort((a, b) => a.productPrice.compareTo(b.productPrice));
          break;
        case 'Giá (Cao đến Thấp)':
          _filteredProducts
              .sort((a, b) => b.productPrice.compareTo(a.productPrice));
          break;
        case 'Thời gian chuẩn bị':
          _filteredProducts.sort((a, b) =>
              a.productPreparationTime.compareTo(b.productPreparationTime));
          break;
        case 'Lượng Calo':
          _filteredProducts
              .sort((a, b) => a.productCalo.compareTo(b.productCalo));
          break;
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: mainColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Category Filter
                Text(
                  'Phân loại',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All Categories Chip
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('Tất cả'),
                          selected: _selectedCategoryId == null,
                          selectedColor: lightColor,
                          labelStyle: TextStyle(
                            color: _selectedCategoryId == null
                                ? Colors.white
                                : mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: ultraLightColor,
                          onSelected: (bool selected) {
                            setSheetState(() {
                              _selectedCategoryId = null;
                            });
                            setState(() {
                              _filterProducts();
                            });
                          },
                        ),
                      ),
                      // Dynamic Category Chips
                      ..._categories.map(
                            (category) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category.categoryName),
                            selected: _selectedCategoryId == category.categoryId,
                            backgroundColor: Color(
                                int.parse('0xFF${category.categoryColor}')),
                            selectedColor: Color(
                                int.parse('0xFF${category.categoryColor}'))
                                .withOpacity(0.7),
                            labelStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (bool selected) {
                              setSheetState(() {
                                _selectedCategoryId =
                                selected ? category.categoryId : null;
                              });
                              setState(() {
                                _filterProducts();
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Sorting
                Text(
                  'Sắp xếp theo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: lightColor),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _currentSortOption,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: mainColor),
                      items: _sortOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(color: mainColor),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setSheetState(() {
                            _currentSortOption = newValue;
                          });
                          setState(() {
                            _filterProducts();
                          });
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Apply Button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Áp dụng',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showProductDetailsDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: product.productImg,
                  height: 250,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 250,
                    color: ultraLightColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: ultraLightColor,
                    child: Icon(Icons.error, color: mainColor),
                  ),
                ),
              ),

              // Product Details
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    SizedBox(height: 8),

                    // Price and Category
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Utils.formatCurrency(product.productPrice),
                          style: TextStyle(
                            fontSize: 18,
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (product.category != null)
                          Chip(
                            label: Text(
                              product.category!.categoryName,
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Color(int.parse(
                                '0xFF${product.category!.categoryColor}')),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Additional Details
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ultraLightColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer, color: accentColor),
                              SizedBox(width: 8),
                              Text(
                                'Thời gian chuẩn bị: ${product.productPreparationTime} phút',
                                style: TextStyle(color: mainColor),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.local_fire_department, color: accentColor),
                              SizedBox(width: 8),
                              Text(
                                'Lượng Calo: ${product.productCalo} calo',
                                style: TextStyle(color: mainColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Description
                    SizedBox(height: 16),
                    Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      product.productDescription,
                      style: TextStyle(color: accentColor),
                    ),

                    // Sizes
                    if (product.sizes.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Các kích cỡ có sẵn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: ultraLightColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: product.sizes.map((size) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  size.sizeName,
                                  style: TextStyle(color: mainColor),
                                ),
                                Text(
                                  '+${Utils.formatCurrency(size.extraPrice)}',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: mainColor,
            ),
            child: Text(
              'Đóng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Menu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: mainColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back, color: Colors.white, size: 28),
        ),
        actions: [
          // Filter Button
          IconButton(
            icon: Icon(Icons.filter_list_rounded, color: Colors.white),
            onPressed: _showFilterBottomSheet,
          ),
          // Add Product Button
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AdminAddProductScreen()),
            ).then((_) => _fetchProductsAndCategories()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filterProducts();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white, width: 1.5),
                ),
                filled: true,
                fillColor: accentColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterProducts();
                });
              },
            ),
          ),

          // Product Count and Sort Info
          Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ultraLightColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredProducts.length} Sản phẩm',
                    style: TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Sắp xếp: $_currentSortOption',
                  style: TextStyle(
                    color: lightColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(mainColor),
              ),
            )
                : _filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 100,
                    color: ultraLightColor,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Không tìm thấy sản phẩm',
                    style: TextStyle(
                      fontSize: 18,
                      color: lightColor,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                Product product = _filteredProducts[index];
                return GestureDetector(
                  onTap: () {
                    _showProductDetailsDialog(product);
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(0.08),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: ultraLightColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: product.productImg,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 80,
                                height: 80,
                                color: ultraLightColor,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 80,
                                height: 80,
                                color: ultraLightColor,
                                child: Icon(Icons.error, color: mainColor),
                              ),
                            ),
                          ),
                          title: Text(
                            product.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: mainColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                Utils.formatCurrency(product.productPrice),
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: lightColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${product.productPreparationTime} phút',
                                    style: TextStyle(color: lightColor),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.local_fire_department,
                                    size: 16,
                                    color: lightColor,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '${product.productCalo} calo',
                                    style: TextStyle(color: lightColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: accentColor),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminEditProductScreen(product: product),
                                    ),
                                  ).then((_) => _fetchProductsAndCategories());
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400]),
                                onPressed: () => _deleteProduct(product),
                              ),
                            ],
                          ),
                        ),
                        if (product.category != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${product.category!.categoryColor}')).withOpacity(0.2),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(int.parse('0xFF${product.category!.categoryColor}')),
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  product.category!.categoryName,
                                  style: TextStyle(
                                    color: Color(int.parse('0xFF${product.category!.categoryColor}')),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
            ),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(Product product) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Xóa Sản Phẩm',
          style: TextStyle(color: mainColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${product.productName}" không?',
          style: TextStyle(color: accentColor),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Hủy',
              style: TextStyle(color: lightColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Xóa',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _productService.deleteProduct(product.productId);
        _fetchProductsAndCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.productName} đã được xóa thành công'),
            backgroundColor: accentColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa sản phẩm: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}