// lib/widgets/address_map_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/address.dart';

class AddressMapView extends StatelessWidget {
  final List<Address> addresses;
  final Function(Address)? onAddressSelected;

  const AddressMapView({
    Key? key,
    required this.addresses,
    this.onAddressSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Bản đồ địa chỉ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: addresses.isNotEmpty
                      ? LatLng(addresses[0].latitude, addresses[0].longitude)
                      : LatLng(10.7769, 106.7009), // Tọa độ mặc định của TP.HCM
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: addresses.map((address) {
                      return Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(address.latitude, address.longitude),
                        child: GestureDetector(
                          onTap: () {
                            if (onAddressSelected != null) {
                              onAddressSelected!(address);
                            }
                          },
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
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