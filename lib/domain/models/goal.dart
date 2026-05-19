import 'package:hive/hive.dart';

part 'goal.g.dart';

/// Kullanıcının biriktirdiği parayla ulaşmak istediği hedef.
@HiveType(typeId: 1)
class Goal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final String emoji;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.emoji,
  });

  Goal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    String? emoji,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  String toString() => 'Goal(title: $title, target: $targetAmount TL)';
}

/// Preset hedef önerileri
class GoalPresets {
  GoalPresets._();

  static const List<Map<String, dynamic>> suggestions = [
    {'title': 'Yeni Telefon', 'emoji': '📱', 'amount': 25000.0},
    {'title': 'Tatil', 'emoji': '✈️', 'amount': 15000.0},
    {'title': 'Laptop', 'emoji': '💻', 'amount': 30000.0},
    {'title': 'Kurs / Eğitim', 'emoji': '📚', 'amount': 5000.0},
    {'title': 'Acil Fon', 'emoji': '🛡️', 'amount': 10000.0},
    {'title': 'Oyun Konsolu', 'emoji': '🎮', 'amount': 20000.0},
    {'title': 'Araba Peşinatı', 'emoji': '🚙', 'amount': 150000.0},
    {'title': 'Ev Eşyası', 'emoji': '🛋️', 'amount': 40000.0},
    {'title': 'Yatırım', 'emoji': '📈', 'amount': 100000.0},
    {'title': 'Evcil Hayvan', 'emoji': '🐶', 'amount': 15000.0},
    {'title': 'Bisiklet / Motor', 'emoji': '🛵', 'amount': 35000.0},
    {'title': 'Spor Ekipmanı', 'emoji': '🏋️', 'amount': 8000.0},
    {'title': 'Konser / Festival', 'emoji': '🎟️', 'amount': 6000.0},
    {'title': 'Diğer', 'emoji': '✍️', 'amount': 0.0},
  ];
}
