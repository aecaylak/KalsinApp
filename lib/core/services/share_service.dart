import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  /// Verilen GlobalKey'in bağlı olduğu widget'ı PNG olarak kaydedip paylaşır.
  Future<void> shareWidget(GlobalKey repaintKey, String subject) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kalsin_paylasim.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: subject,
        text: '💚 KalsınApp ile tasarruf ediyorum! #KalsınApp',
      );
    } catch (_) {}
  }
}
