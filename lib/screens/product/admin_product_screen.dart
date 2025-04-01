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
  final ProductService _productService = ProductService();
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bộ lọc',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),

                // Category Filter
                Text(
                  'Phân loại',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All Categories Chip
                      ChoiceChip(
                        label: Text('Tất cả'),
                        selected: _selectedCategoryId == null,
                        onSelected: (bool selected) {
                          setSheetState(() {
                            _selectedCategoryId = null;
                          });
                          setState(() {
                            _filterProducts();
                          });
                        },
                      ),
                      // Dynamic Category Chips
                      ..._categories.map(
                        (category) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category.categoryName),
                            selected:
                                _selectedCategoryId == category.categoryId,
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
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _currentSortOption,
                  items: _sortOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
                SizedBox(height: 16),

                // Apply Button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 12),
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
                SizedBox(height: 30),
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
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: CachedNetworkImage(
                  imageUrl: product.productImg,
                  height: 250,
                  fit: BoxFit.fitHeight,
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
                        color: Colors.deepPurple,
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
                            color: Colors.green,
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
                    SizedBox(height: 8),

                    // Additional Details
                    Row(
                      children: [
                        Icon(Icons.timer, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                            'Thời gian chuẩn bị: ${product.productPreparationTime} phút'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Lượng Calo: ${product.productCalo} calo'),
                      ],
                    ),

                    // Description
                    SizedBox(height: 16),
                    Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      product.productDescription,
                      style: TextStyle(color: Colors.grey[700]),
                    ),

                    // Sizes
                    if (product.sizes.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Các kích cỡ có sẵn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...product.sizes.map((size) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(size.sizeName),
                                Text(
                                  '+${Utils.formatCurrency(size.extraPrice)}',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ],
                            ),
                          )),
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
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.deepPurple[400],
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(CupertinoIcons.back, color: Colors.white, size: 32,)),
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
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.deepPurple),
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
                  borderSide: BorderSide(color: Colors.deepPurple.shade100),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.deepPurple.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProducts.length} Sản phẩm',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sắp xếp theo: $_currentSortOption',
                  style: TextStyle(
                    color: Colors.grey[700],
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy sản phẩm',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
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
                                    color: Colors.grey.withOpacity(0.2),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(12),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: product.productImg,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  ),
                                ),
                                title: Text(
                                  product.productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Utils.formatCurrency(product.productPrice),
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.timer, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          '${product.productPreparationTime} phút',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                        SizedBox(width: 4),
                                        Text(
                                          '${product.productCalo} calo',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    if (product.category != null)
                                      Chip(
                                        label: Text(
                                          product.category!.categoryName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                        backgroundColor: Color(int.parse('0xFF${product.category!.categoryColor}')),
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.blue),
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
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteProduct(product),
                                    ),
                                  ],
                                ),
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
        title: Text('Xóa Sản Phẩm'),
        content:
        Text('Bạn có chắc chắn muốn xóa "${product.productName}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Xóa'),
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
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xóa sản phẩm: $e'),
            backgroundColor: Colors.red,
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
