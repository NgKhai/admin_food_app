import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Notify {
  final String title;
  final String body;
  final DateTime dateCreated;
  final VoidCallback? onTap;

  Notify(
      {required this.title,
      required this.body,
      required this.dateCreated,
      this.onTap});

  factory Notify.fromJson(Map<String, dynamic> json) {
    return Notify(
      title: json['title'],
      body: json['body'],
      dateCreated: (json['dateCreated'] as Timestamp).toDate(),
    );
  }
}
