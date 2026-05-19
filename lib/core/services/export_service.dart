import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/category.dart';
import '../../domain/models/saving.dart';

class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  Future<void> exportCsv(List<Saving> savings) async {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Tarih,Kategori,Tutar (TL),Not,Hedef ID');

    for (final s in savings) {
      final cat = AppCategories.findById(s.categoryId);
      final date = formatter.format(s.savedAt);
      final note = (s.note ?? '').replaceAll(',', ';');
      buffer.writeln('$date,${cat.name},${s.amount.toStringAsFixed(2)},$note,${s.goalId ?? ''}');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kalsin_tasarruflar.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'KalsınApp Tasarruf Verileri',
    );
  }
}
