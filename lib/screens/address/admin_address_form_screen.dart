import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/address.dart';
import '../../services/admin_address_service.dart';

class AddressEditScreen extends StatefulWidget {
  final Address? address;

  const AddressEditScreen({Key? key, this.address}) : super(key: key);

  @override
  _AddressEditScreenState createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  // New color scheme
  final Color mainColor = Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background

  final AddressService _addressService = AddressService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  late double _latitude;
  late double _longitude;
  late MapController _mapController;
  bool _isMarkerDraggable = true;

  // Store marker key to access its position
  final GlobalKey _markerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.address != null) {
      // Edit mode
      _addressNameController.text = widget.address!.addressName;
      _latitude = widget.address!.latitude;
      _longitude = widget.address!.longitude;
    } else {
      // Create mode - default to Ho Chi Minh City center
      _latitude = 10.7769;
      _longitude = 106.7009;
    }

    // Initialize text controllers with current values
    _latitudeController.text = _latitude.toString();
    _longitudeController.text = _longitude.toString();
  }

  @override
  void dispose() {
    _addressNameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      try {
        final address = Address(
          addressId: widget.address?.addressId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          addressName: _addressNameController.text,
          latitude: _latitude,
          longitude: _longitude,
        );

        if (widget.address != null) {
          await _addressService.updateAddress(address);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật địa chỉ thành công'),
              backgroundColor: accentColor,
            ),
          );
        } else {
          await _addressService.addAddress(address);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thêm địa chỉ thành công'),
              backgroundColor: accentColor,
            ),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _updateCoordinates(LatLng point) {
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;

      // Update the text controllers to reflect the new coordinates
      _latitudeController.text = _latitude.toStringAsFixed(6);
      _longitudeController.text = _longitude.toStringAsFixed(6);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ultraLightColor.withOpacity(0.3),
      appBar: AppBar(
        title: Text(
          widget.address != null ? 'Chỉnh sửa địa chỉ' : 'Thêm địa chỉ mới',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: mainColor,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
      body: Row(
        children: [
          // Form panel
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: ultraLightColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: lightColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: mainColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Nhấp vào bản đồ để chọn vị trí hoặc nhập thủ công tọa độ',
                              style: TextStyle(
                                color: mainColor,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Thông tin địa chỉ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên địa chỉ',
                        labelStyle: TextStyle(color: accentColor),
                        hintText: 'Nhập tên hoặc mô tả địa chỉ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: lightColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accentColor, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: lightColor),
                        ),
                        prefixIcon: Icon(Icons.location_city, color: accentColor),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên địa chỉ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tọa độ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: mainColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            decoration: InputDecoration(
                              labelText: 'Vĩ độ',
                              labelStyle: TextStyle(color: accentColor),
                              hintText: 'Vĩ độ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: accentColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: lightColor),
                              ),
                              prefixIcon: Icon(Icons.north, color: accentColor),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final newLat = double.tryParse(value);
                                if (newLat != null) {
                                  setState(() {
                                    _latitude = newLat;
                                    _mapController.moveAndRotate(LatLng(_latitude, _longitude), 14, 0);
                                  });
                                }
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập vĩ độ';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Vĩ độ phải là số';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            decoration: InputDecoration(
                              labelText: 'Kinh độ',
                              labelStyle: TextStyle(color: accentColor),
                              hintText: 'Kinh độ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: accentColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: lightColor),
                              ),
                              prefixIcon: Icon(Icons.east, color: accentColor),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final newLng = double.tryParse(value);
                                if (newLng != null) {
                                  setState(() {
                                    _longitude = newLng;
                                    _mapController.moveAndRotate(LatLng(_latitude, _longitude), 14, 0);
                                  });
                                }
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập kinh độ';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Kinh độ phải là số';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: lightColor),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Cho phép kéo đánh dấu',
                          style: TextStyle(
                            color: mainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Bật để có thể kéo đánh dấu trên bản đồ',
                          style: TextStyle(
                            color: lightColor,
                            fontSize: 13,
                          ),
                        ),
                        value: _isMarkerDraggable,
                        activeColor: mainColor,
                        activeTrackColor: lightColor,
                        onChanged: (value) {
                          setState(() {
                            _isMarkerDraggable = value;
                          });
                        },
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveAddress,
                            icon: const Icon(Icons.save),
                            label: const Text(
                              'Lưu địa chỉ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text(
                              'Hủy',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: mainColor,
                              side: BorderSide(color: mainColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Map panel
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: ultraLightColor),
                ),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_latitude, _longitude),
                      initialZoom: 14.0,
                      onTap: (_, point) => _updateCoordinates(point),
                      // Use the onMapEvent callback to handle dragging if needed
                      onMapEvent: (MapEvent event) {
                        // You can handle map events here if needed
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            alignment: const Alignment(0, -0.75),
                            width: 40.0,
                            height: 40.0,
                            point: LatLng(_latitude, _longitude),
                            child: _isMarkerDraggable
                                ? Draggable<LatLng>(
                              key: _markerKey,
                              feedback: Icon(
                                Icons.location_on,
                                color: mainColor,
                                size: 40,
                              ),
                              childWhenDragging: Icon(
                                Icons.location_on,
                                color: lightColor.withOpacity(0.5),
                                size: 40,
                              ),
                              data: LatLng(_latitude, _longitude),
                              onDragEnd: (details) {
                                // Convert screen position to map coordinates
                                final RenderBox renderBox = context.findRenderObject() as RenderBox;
                                final localPosition = renderBox.globalToLocal(details.offset);

                                // Calculate the map's bounds
                                final mapBounds = _mapController.camera.visibleBounds;

                                // Calculate the approximate lat/lng based on screen position
                                final mapWidth = renderBox.size.width;
                                final mapHeight = renderBox.size.height;

                                // Simple linear interpolation between bounds based on screen position
                                final percentX = localPosition.dx / mapWidth;
                                final percentY = localPosition.dy / mapHeight;

                                final newLat = mapBounds.north - (mapBounds.north - mapBounds.south) * percentY;
                                final newLng = mapBounds.west + (mapBounds.east - mapBounds.west) * percentX;

                                _updateCoordinates(LatLng(newLat, newLng));
                              },
                              child: Icon(
                                Icons.location_on,
                                color: mainColor,
                                size: 40,
                              ),
                            )
                                : Icon(
                              Icons.location_on,
                              color: mainColor,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Map controls
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.add, color: mainColor),
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.moveAndRotate(LatLng(_latitude, _longitude), currentZoom + 1, 0);
                            },
                          ),
                          Divider(height: 1, color: ultraLightColor),
                          IconButton(
                            icon: Icon(Icons.remove, color: mainColor),
                            onPressed: () {
                              final currentZoom = _mapController.camera.zoom;
                              _mapController.moveAndRotate(LatLng(_latitude, _longitude), currentZoom - 1, 0);
                            },
                          ),
                          Divider(height: 1, color: ultraLightColor),
                          IconButton(
                            icon: Icon(Icons.my_location, color: mainColor),
                            onPressed: () {
                              _mapController.moveAndRotate(LatLng(_latitude, _longitude), 16, 0);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Caption for the map
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                        border: Border.all(color: ultraLightColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pin_drop, color: mainColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isMarkerDraggable
                                  ? 'Nhấp vào bản đồ hoặc kéo điểm đánh dấu để chọn vị trí'
                                  : 'Nhấp vào bản đồ để chọn vị trí',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}