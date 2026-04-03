import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Backend allows max [maxBytes] for [POST /users/me/profile/photo].
/// Returns [original] when already small enough; otherwise a new JPEG file in
/// system temp (caller should delete after upload if path differs from original).
Future<File> prepareProfilePhotoForUpload(
  String filePath, {
  int maxBytes = 2 * 1024 * 1024,
}) async {
  final original = File(filePath);
  if (!await original.exists()) {
    throw const FormatException('File does not exist');
  }
  final len = await original.length();
  if (len == 0) {
    throw const FormatException('File is empty');
  }
  if (len <= maxBytes) {
    return original;
  }

  final tempDir = Directory.systemTemp;
  var quality = 88;
  var maxSide = 2048;

  for (var attempt = 0; attempt < 18; attempt++) {
    final outPath =
        '${tempDir.path}/vacanza_profile_${DateTime.now().microsecondsSinceEpoch}_$attempt.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: quality,
      minWidth: maxSide,
      minHeight: maxSide,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      quality = (quality - 8).clamp(20, 100);
      continue;
    }

    final outFile = File(result.path);
    final outLen = await outFile.length();
    if (outLen <= maxBytes) {
      return outFile;
    }

    await outFile.delete();

    quality -= 6;
    if (quality < 28) {
      quality = 78;
      maxSide = (maxSide * 0.72).round().clamp(480, 2048);
    }
  }

  throw const FormatException(
    'Could not compress image to under 2 MB — try another photo.',
  );
}
