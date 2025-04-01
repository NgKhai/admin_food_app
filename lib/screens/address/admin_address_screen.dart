import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/address.dart';
import '../../services/admin_address_service.dart';
import 'address_map_view.dart';
import 'admin_address_form_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({Key? key}) : super(key: key);

  @override
  _AddressManagementScreenState createState() =>
      _AddressManagementScreenState();
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
          content: Text(
              'Bạn có chắc chắn muốn xóa địa chỉ "${address.addressName}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _addressService.deleteAddress(address.addressId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xóa địa chỉ thành công')),
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
      return address.addressName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
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
      appBar: AppBar(
        title: Text('Quản lý địa chỉ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              CupertinoIcons.back,
              color: Colors.white,
              size: 32,
            )),
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
                  color: Colors.grey.withOpacity(0.2),
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
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        hint: const Text('Sắp xếp theo'),
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
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                    child: Text('Lỗi: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var addresses = snapshot.data ?? [];

                if (addresses.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có địa chỉ nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Nhấn nút "Thêm mới" để bắt đầu',
                          style: TextStyle(
                            color: Colors.grey,
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
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy địa chỉ nào với từ khóa "$_searchQuery"',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
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
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red.shade700,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vĩ độ: ${address.latitude.toStringAsFixed(4)}, Kinh độ: ${address.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
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
                      foregroundColor: Colors.blue.shade700,
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
