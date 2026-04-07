import 'dart:io';

import 'package:path_provider/path_provider.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  Future<File> persistImage(File source) async {
    final appDir = await getApplicationDocumentsDirectory();
    final detectionDir = Directory('${appDir.path}/detections');

    if (!await detectionDir.exists()) {
      await detectionDir.create(recursive: true);
    }

    final extension = source.path.contains('.')
        ? source.path.split('.').last
        : 'jpg';
    final fileName = 'det_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final target = File('${detectionDir.path}/$fileName');

    return source.copy(target.path);
  }
}
