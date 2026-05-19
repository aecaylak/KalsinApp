import 'package:flutter/material.dart';

/// Harcama kategorilerini temsil eden model.
class SavingCategory {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  const SavingCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
  });
}

/// Uygulama genelinde kullanılan sabit kategori listesi.
class AppCategories {
  AppCategories._();

  static const List<SavingCategory> all = [
    SavingCategory(
      id: 'coffee',
      name: 'Kahve',
      emoji: '☕',
      color: Color(0xFF8B6343),
    ),
    SavingCategory(
      id: 'food',
      name: 'Dışarıda Yemek',
      emoji: '🍔',
      color: Color(0xFFE06C4A),
    ),
    SavingCategory(
      id: 'transport',
      name: 'Ulaşım',
      emoji: '🚌',
      color: Color(0xFF4A9EE0),
    ),
    SavingCategory(
      id: 'shopping',
      name: 'Online Alışveriş',
      emoji: '🛍',
      color: Color(0xFF9B59B6),
    ),
    SavingCategory(
      id: 'clothing',
      name: 'Giyim',
      emoji: '👗',
      color: Color(0xFFE91E8C),
    ),
    SavingCategory(
      id: 'entertainment',
      name: 'Eğlence',
      emoji: '🎮',
      color: Color(0xFF27AE60),
    ),
    SavingCategory(
      id: 'gift',
      name: 'Hediye',
      emoji: '🎁',
      color: Color(0xFFF39C12),
    ),
    SavingCategory(
      id: 'bad_habit',
      name: 'Kötü Alışkanlık',
      emoji: '🚭',
      color: Color(0xFFE74C3C),
    ),
    SavingCategory(
      id: 'snack',
      name: 'Abur Cubur',
      emoji: '🍫',
      color: Color(0xFFD35400),
    ),
    SavingCategory(
      id: 'subscriptions',
      name: 'Abonelik',
      emoji: '📺',
      color: Color(0xFF8E44AD),
    ),
    SavingCategory(
      id: 'cosmetics',
      name: 'Kozmetik',
      emoji: '💄',
      color: Color(0xFFE84393),
    ),
    SavingCategory(
      id: 'tech',
      name: 'Teknoloji',
      emoji: '💻',
      color: Color(0xFF34495E),
    ),
    SavingCategory(
      id: 'other',
      name: 'Diğer',
      emoji: '📦',
      color: Color(0xFF7F8C8D),
    ),
  ];

  static SavingCategory findById(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}
