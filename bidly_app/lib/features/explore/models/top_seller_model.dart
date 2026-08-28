import 'package:flutter/material.dart';

class TopSellerModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String initials;
  final String colorHex;
  final int listingsCount;
  final double rating;

  const TopSellerModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.initials,
    this.colorHex = '#004E54',
    this.listingsCount = 0,
    this.rating = 4.8,
  });

  factory TopSellerModel.fromJson(Map<String, dynamic> json) {
    return TopSellerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Seller',
      avatarUrl: json['avatarUrl'] as String?,
      initials: json['initials'] as String? ?? 'S',
      colorHex: json['colorHex'] as String? ?? '#004E54',
      listingsCount: json['listingsCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }

  Color get avatarColor {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF004E54);
    }
  }
}
