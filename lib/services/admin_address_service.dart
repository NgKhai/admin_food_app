// lib/services/address_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';

class AddressService {
  final CollectionReference addressCollection =
  FirebaseFirestore.instance.collection('addresses');

  // Lấy danh sách địa chỉ
  Stream<List<Address>> getAddresses() {
    return addressCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Address.fromJson(doc)).toList();
    });
  }

  // Thêm địa chỉ mới
  Future<void> addAddress(Address address) async {
    await addressCollection.doc(address.addressId).set(address.toJson());
  }

  // Cập nhật địa chỉ
  Future<void> updateAddress(Address address) async {
    await addressCollection.doc(address.addressId).update(address.toJson());
  }

  // Xóa địa chỉ
  Future<void> deleteAddress(String addressId) async {
    await addressCollection.doc(addressId).delete();
  }
}