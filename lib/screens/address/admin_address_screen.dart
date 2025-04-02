import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/address.dart';
import '../../services/admin_address_service.dart';
import 'address_map_view.dart';
import 'admin_address_form_screen.dart';

// Application color theme
class AppColors {
  static const Color mainColor = Color(0xFF162F4A); // Deep blue - primary
  static const Color accentColor = Color(0xFF3A5F82); // Medium blue - secondary
  static const Color lightColor = Color(0xFF718EA4); // Light blue - tertiary
  static const Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background
}

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  _AddressManagementScreenState createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final AddressService _addressService = AddressService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // Options: 'name', 'district'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressEditScreen(),
      ),
    );
  }

  void _navigateToEditAddress(Address address) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressEditScreen(address: address),
      ),
    );
  }

  Future<void> _confirmDelete(Address address) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa địa chỉ "${address.addressName}"?'),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy', style: TextStyle(color: AppColors.accentColor)),
            ),
            TextButton(
              onPressed: () {
                _addressService.deleteAddress(address.addressId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Xóa địa chỉ thành công'),
                    backgroundColor: AppColors.accentColor,
                  ),
                );
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  List<Address> _filterAddresses(List<Address> addresses) {
    if (_searchQuery.isEmpty) return addresses;

    return addresses.where((address) {
      return address.addressName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Address> _sortAddresses(List<Address> addresses) {
    if (_sortBy == 'name') {
      addresses.sort((a, b) => a.addressName.compareTo(b.addressName));
    } else if (_sortBy == 'district') {
      addresses.sort((a, b) {
        // Extract district from address (assuming format includes "Quận X" or "Huyện Y")
        final districtA = _extractDistrict(a.addressName);
        final districtB = _extractDistrict(b.addressName);
        return districtA.compareTo(districtB);
      });
    }
    return addresses;
  }

  String _extractDistrict(String address) {
    // Simple extraction, can be improved for more complex addresses
    final quarRegex = RegExp(r'Quận \d+|Quận [^,]+');
    final huyenRegex = RegExp(r'Huyện [^,]+');
    final quanMatch = quarRegex.firstMatch(address);
    final huyenMatch = huyenRegex.firstMatch(address);

    if (quanMatch != null) {
      return quanMatch.group(0) ?? '';
    } else if (huyenMatch != null) {
      return huyenMatch.group(0) ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ultraLightColor,
      appBar: AppBar(
        title: const Text(
          'Quản lý địa chỉ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.mainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightColor.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm địa chỉ...',
                      hintStyle: TextStyle(color: AppColors.lightColor),
                      prefixIcon: Icon(Icons.search, color: AppColors.accentColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.ultraLightColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: TextStyle(color: AppColors.mainColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.ultraLightColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        hint: Text('Sắp xếp theo', style: TextStyle(color: AppColors.lightColor)),
                        dropdownColor: Colors.white,
                        icon: Icon(Icons.arrow_drop_down, color: AppColors.accentColor),
                        style: TextStyle(color: AppColors.mainColor, fontSize: 14),
                        items: const [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('Tên địa chỉ'),
                          ),
                          DropdownMenuItem(
                            value: 'district',
                            child: Text('Quận/Huyện'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToAddAddress,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Thêm mới'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // Address list
          Expanded(
            child: StreamBuilder<List<Address>>(
              stream: _addressService.getAddresses(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style: TextStyle(color: AppColors.mainColor),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.accentColor),
                  );
                }

                var addresses = snapshot.data ?? [];

                if (addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: AppColors.lightColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có địa chỉ nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn nút "Thêm mới" để bắt đầu',
                          style: TextStyle(
                            color: AppColors.lightColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Apply filtering and sorting
                addresses = _filterAddresses(addresses);
                addresses = _sortAddresses(addresses);

                if (addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.lightColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy địa chỉ nào với từ khóa "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.accentColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return AddressCard(
                      address: address,
                      onEdit: () => _navigateToEditAddress(address),
                      onDelete: () => _confirmDelete(address),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: StreamBuilder<List<Address>>(
              stream: _addressService.getAddresses(),
              builder: (context, snapshot) {
                final addresses = snapshot.data ?? [];
                return AddressMapView(
                  addresses: addresses,
                  // onAddressSelected: () {print('');},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AddressCard({
    Key? key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.ultraLightColor, width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.ultraLightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.mainColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.addressName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.mainColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vĩ độ: ${address.latitude.toStringAsFixed(4)}, Kinh độ: ${address.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: AppColors.lightColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Sửa'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Xóa'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}