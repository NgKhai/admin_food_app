import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String addressId;
  final String addressName;
  final double latitude;
  final double longitude;

  Address({
    required this.addressId,
    required this.addressName,
    required this.latitude,
    required this.longitude,
  });

  factory Address.fromJson(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Address(
      addressId: data['addressId'] ?? '',
      addressName: data['addressName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      'addressName': addressName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static Address fromMap(Map<String, dynamic> map) {
    return Address(
      addressId: map['addressId'] as String,
      addressName: map['addressName'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }
}
