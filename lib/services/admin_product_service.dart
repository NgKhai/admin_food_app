import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';
import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Product>> getProductsWithCategories() async {
    try {
      QuerySnapshot productSnapshot = await _firestore.collection("products").get();

      List<Product> products = await Future.wait(productSnapshot.docs.map((doc) async {
        Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
        Product product = Product.fromJson(productData);

        // Fetch category details
        if (product.categoryId.isNotEmpty) {
          DocumentSnapshot categoryDoc = await _firestore
              .collection("categories")
              .doc(product.categoryId)
              .get();

          if (categoryDoc.exists) {
            product = Product(
              productId: product.productId,
              productName: product.productName,
              productImg: product.productImg,
              productPreparationTime: product.productPreparationTime,
              productCalo: product.productCalo,
              productPrice: product.productPrice,
              productDescription: product.productDescription,
              productStatus: product.productStatus,
              categoryId: product.categoryId,
              category: Category.fromJson(categoryDoc.data() as Map<String, dynamic>),
            );
          }
        }

        // Fetch sizes for the product
        QuerySnapshot sizeSnapshot = await _firestore
            .collection("products")
            .doc(product.productId)
            .collection("size")
            .get();

        product.sizes = sizeSnapshot.docs
            .map((doc) => ProductSize.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        return product;
      }));

      return products;
    } catch (e) {
      print("Error fetching products with categories: $e");
      return [];
    }
  }

  // Fetch products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      QuerySnapshot productSnapshot = await _firestore
          .collection("products")
          .where("categoryId", isEqualTo: categoryId)
          .get();

      List<Product> products = await Future.wait(productSnapshot.docs.map((doc) async {
        Map<String, dynamic> productData = doc.data() as Map<String, dynamic>;
        Product product = Product.fromJson(productData);

        // Fetch sizes for the product
        QuerySnapshot sizeSnapshot = await _firestore
            .collection("products")
            .doc(product.productId)
            .collection("size")
            .get();

        product.sizes = sizeSnapshot.docs
            .map((doc) => ProductSize.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        return product;
      }));

      return products;
    } catch (e) {
      print("Error fetching products by category: $e");
      return [];
    }
  }
  // Fetch all products
  Future<List<Product>> getProducts() async {
    try {
      QuerySnapshot productSnapshot = await _firestore.collection("products").get();

      List<Product> products = productSnapshot.docs.map((doc) {
        return Product.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();

      // Fetch sizes for each product
      for (var product in products) {
        QuerySnapshot sizeSnapshot = await _firestore
            .collection("products")
            .doc(product.productId)
            .collection("size")
            .get();

        product.sizes = sizeSnapshot.docs
            .map((doc) => ProductSize.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
      }

      return products;
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  // Create a new product
  Future<void> addProduct(Product product) async {
    try {
      DocumentReference productRef = await _firestore.collection("products").add({
        'productId': product.productId,
        'productName': product.productName,
        'productImg': product.productImg,
        'productPreparationTime': product.productPreparationTime,
        'productCalo': product.productCalo,
        'productPrice': product.productPrice,
        'productDescription': product.productDescription,
        'productStatus': product.productStatus,
        'categoryId': product.categoryId,
      });

      // Add sizes for the product
      for (var size in product.sizes) {
        await productRef.collection("size").add({
          'sizeId': size.sizeId,
          'sizeName': size.sizeName,
          'extraPrice': size.extraPrice,
        });
      }
    } catch (e) {
      print("Error adding product: $e");
    }
  }

  // Update an existing product
  Future<void> updateProduct(Product product) async {
    try {
      DocumentReference productRef = _firestore.collection("products").doc(product.productId);

      await productRef.update({
        'productName': product.productName,
        'productImg': product.productImg,
        'productPreparationTime': product.productPreparationTime,
        'productCalo': product.productCalo,
        'productPrice': product.productPrice,
        'productDescription': product.productDescription,
        'productStatus': product.productStatus,
        'categoryId': product.categoryId,
      });

      // Update sizes for the product
      for (var size in product.sizes) {
        await productRef.collection("size").doc(size.sizeId).update({
          'sizeName': size.sizeName,
          'extraPrice': size.extraPrice,
        });
      }
    } catch (e) {
      print("Error updating product: $e");
    }
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      DocumentReference productRef = _firestore.collection("products").doc(productId);

      // Delete sizes for the product
      QuerySnapshot sizeSnapshot = await productRef.collection("size").get();
      for (var doc in sizeSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the product itself
      await productRef.delete();
    } catch (e) {
      print("Error deleting product: $e");
    }
  }

  Future<List<Product>> filterAndSortProducts({
    String? searchQuery,
    String? categoryId,
    String sortOption = 'Tên (A-Z)',
  }) async {
    try {
      // Fetch all products with categories
      List<Product> products = await getProductsWithCategories();

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        products = products.where((product) =>
            product.productName.toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();
      }

      // Filter by category
      if (categoryId != null) {
        products = products.where((product) =>
        product.categoryId == categoryId
        ).toList();
      }

      // Sort products
      switch (sortOption) {
        case 'Tên (A-Z)':
          products.sort((a, b) => a.productName.compareTo(b.productName));
          break;
        case 'Tên (Z-A)':
          products.sort((a, b) => b.productName.compareTo(a.productName));
          break;
        case 'Giá (Thấp đến Cao)':
          products.sort((a, b) => a.productPrice.compareTo(b.productPrice));
          break;
        case 'Giá (Cao đến Thấp)':
          products.sort((a, b) => b.productPrice.compareTo(a.productPrice));
          break;
        case 'Thời gian chuẩn bị':
          products.sort((a, b) => a.productPreparationTime.compareTo(b.productPreparationTime));
          break;
        case 'Lượng Calo':
          products.sort((a, b) => a.productCalo.compareTo(b.productCalo));
          break;
      }

      return products;
    } catch (e) {
      print("Error filtering and sorting products: $e");
      return [];
    }
  }

  // Additional helper methods can be added here
  List<String> getSortOptions() {
    return [
      'Tên (A-Z)',
      'Tên (Z-A)',
      'Giá (Thấp đến Cao)',
      'Giá (Cao đến Thấp)',
      'Thời gian chuẩn bị',
      'Lượng Calo',
    ];
  }

  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final productData = doc.data() ?? {};
        final product = Product.fromJson(productData);

        // Fetch category if categoryId exists
        if (productData['categoryId'] != null) {
          final categoryDoc = await _firestore.collection('categories').doc(productData['categoryId']).get();
          if (categoryDoc.exists) {
            product.category = Category.fromJson(categoryDoc.data() ?? {});
          }
        }

        // Fetch product sizes
        final sizesSnapshot = await _firestore
            .collection('products')
            .doc(productId)
            .collection('sizes')
            .get();

        product.sizes = sizesSnapshot.docs
            .map((doc) => ProductSize.fromJson(doc.data()))
            .toList();

        return product;
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  Future<List<Product>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) => Product.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }

  Future<List<Product>> getTopSellingProducts({int limit = 5}) async {
    try {
      // Get order data to calculate product sales
      final ordersSnapshot = await _firestore.collection('orders').get();

      final productSales = <String, num>{};
      for (var order in ordersSnapshot.docs) {
        final items = order.data()['listCartItem'] as List;
        for (var item in items) {
          final productId = item['productId'];
          productSales[productId] = (productSales[productId] ?? 0) + item['quantity'];
        }
      }

      // Fetch all products and sort by sales
      final productsSnapshot = await _firestore.collection('products').get();
      final sortedProducts = productsSnapshot.docs
          .map((doc) => {
        ...doc.data(),
        'salesCount': productSales[doc.id] ?? 0
      })
          .toList()
        ..sort((a, b) => (b['salesCount'] as int).compareTo(a['salesCount']));

      return sortedProducts.take(limit)
          .map((productData) => Product.fromJson(productData))
          .toList();
    } catch (e) {
      print('Error getting top selling products: $e');
      return [];
    }
  }
}