import 'package:hive/hive.dart';

part 'saving.g.dart';

/// Kullanıcının vazgeçtiği harcamayı temsil eden veri modeli.
/// Hive ile yerel veritabanına kaydedilir.
@HiveType(typeId: 0)
class Saving extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  final DateTime savedAt;

  @HiveField(5)
  final String? goalId;

  Saving({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.savedAt,
    this.goalId,
  });

  Saving copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? savedAt,
    String? goalId,
  }) {
    return Saving(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      savedAt: savedAt ?? this.savedAt,
      goalId: goalId ?? this.goalId,
    );
  }

  @override
  String toString() =>
      'Saving(id: $id, amount: $amount, category: $categoryId, savedAt: $savedAt)';
}
