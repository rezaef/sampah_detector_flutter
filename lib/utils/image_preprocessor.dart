import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PreprocessingBundle {
  final img.Image modelImage;
  final img.Image edgeImage;
  final Uint8List clahePreview;
  final Uint8List processedPreview;
  final Uint8List edgePreview;

  const PreprocessingBundle({
    required this.modelImage,
    required this.edgeImage,
    required this.clahePreview,
    required this.processedPreview,
    required this.edgePreview,
  });
}

class ImagePreprocessor {
  static const int targetSize = 224;

  static Future<PreprocessingBundle> prepare(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw StateError('Gambar gagal diproses.');
    }

    final resized = img.copyResize(
      decoded,
      width: targetSize,
      height: targetSize,
    );
    final clahe = _applyClaheApproximation(resized);
    final smoothed = _boxBlur(clahe, radius: 1);
    final edges = _edgeDetect(smoothed);
    final blendedForModel = _blendEdges(smoothed, edges);

    return PreprocessingBundle(
      modelImage: blendedForModel,
      edgeImage: edges,
      clahePreview: Uint8List.fromList(img.encodeJpg(clahe, quality: 88)),
      processedPreview: Uint8List.fromList(img.encodeJpg(smoothed, quality: 88)),
      edgePreview: Uint8List.fromList(img.encodeJpg(edges, quality: 88)),
    );
  }

  static List<List<List<List<double>>>> buildInputTensor(img.Image image) {
    return [
      List<List<List<double>>>.generate(image.height, (y) {
        return List<List<double>>.generate(image.width, (x) {
          final pixel = image.getPixel(x, y);
          return <double>[
            pixel.r.toDouble() / 255.0,
            pixel.g.toDouble() / 255.0,
            pixel.b.toDouble() / 255.0,
          ];
        });
      }),
    ];
  }

  static img.Image _applyClaheApproximation(img.Image source, {int tileSize = 32}) {
    final result = img.Image(width: source.width, height: source.height);
    final tilesX = (source.width / tileSize).ceil();
    final tilesY = (source.height / tileSize).ceil();

    for (var tileY = 0; tileY < tilesY; tileY++) {
      for (var tileX = 0; tileX < tilesX; tileX++) {
        final startX = tileX * tileSize;
        final startY = tileY * tileSize;
        final endX = min(startX + tileSize, source.width);
        final endY = min(startY + tileSize, source.height);
        final tileArea = max(1, (endX - startX) * (endY - startY));
        final clipLimit = max(8, (tileArea / 16).round());

        final histogram = List<int>.filled(256, 0);
        for (var y = startY; y < endY; y++) {
          for (var x = startX; x < endX; x++) {
            final pixel = source.getPixel(x, y);
            final lum = _luminance(pixel.r, pixel.g, pixel.b);
            histogram[lum]++;
          }
        }

        var overflow = 0;
        for (var i = 0; i < histogram.length; i++) {
          if (histogram[i] > clipLimit) {
            overflow += histogram[i] - clipLimit;
            histogram[i] = clipLimit;
          }
        }

        final distribute = overflow ~/ 256;
        var remainder = overflow % 256;
        for (var i = 0; i < histogram.length; i++) {
          histogram[i] += distribute;
          if (remainder > 0) {
            histogram[i]++;
            remainder--;
          }
        }

        final cdf = List<int>.filled(256, 0);
        var running = 0;
        var cdfMin = 0;
        for (var i = 0; i < cdf.length; i++) {
          running += histogram[i];
          cdf[i] = running;
          if (cdfMin == 0 && running > 0) {
            cdfMin = running;
          }
        }

        final denominator = max(1, tileArea - cdfMin);

        for (var y = startY; y < endY; y++) {
          for (var x = startX; x < endX; x++) {
            final pixel = source.getPixel(x, y);
            final lum = _luminance(pixel.r, pixel.g, pixel.b);
            final mappedLum = _clamp255(
              (((cdf[lum] - cdfMin) / denominator) * 255).round(),
            );
            final safeLum = max(1, lum);
            final scale = mappedLum / safeLum;

            final r = _clamp255(pixel.r.toDouble() * scale);
            final g = _clamp255(pixel.g.toDouble() * scale);
            final b = _clamp255(pixel.b.toDouble() * scale);

            result.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
          }
        }
      }
    }

    return result;
  }

  static img.Image _boxBlur(img.Image source, {int radius = 1}) {
    final result = img.Image(width: source.width, height: source.height);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        var red = 0;
        var green = 0;
        var blue = 0;
        var alpha = 0;
        var count = 0;

        for (var ky = -radius; ky <= radius; ky++) {
          for (var kx = -radius; kx <= radius; kx++) {
            final nx = x + kx;
            final ny = y + ky;

            if (nx < 0 || ny < 0 || nx >= source.width || ny >= source.height) {
              continue;
            }

            final pixel = source.getPixel(nx, ny);
            red += pixel.r.toInt();
            green += pixel.g.toInt();
            blue += pixel.b.toInt();
            alpha += pixel.a.toInt();
            count++;
          }
        }

        result.setPixelRgba(
          x,
          y,
          red ~/ count,
          green ~/ count,
          blue ~/ count,
          alpha ~/ count,
        );
      }
    }

    return result;
  }

  static img.Image _edgeDetect(img.Image source) {
    final width = source.width;
    final height = source.height;
    final gray = List<List<int>>.generate(
      height,
      (_) => List<int>.filled(width, 0),
    );

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = source.getPixel(x, y);
        gray[y][x] = _luminance(pixel.r, pixel.g, pixel.b);
      }
    }

    final magnitudes = List<List<double>>.generate(
      height,
      (_) => List<double>.filled(width, 0),
    );

    double maxMagnitude = 0;

    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        final gx =
            -gray[y - 1][x - 1] + gray[y - 1][x + 1] -
            2 * gray[y][x - 1] + 2 * gray[y][x + 1] -
            gray[y + 1][x - 1] + gray[y + 1][x + 1];

        final gy =
            gray[y - 1][x - 1] + 2 * gray[y - 1][x] + gray[y - 1][x + 1] -
            gray[y + 1][x - 1] - 2 * gray[y + 1][x] - gray[y + 1][x + 1];

        final magnitude = sqrt((gx * gx + gy * gy).toDouble());
        magnitudes[y][x] = magnitude;
        if (magnitude > maxMagnitude) {
          maxMagnitude = magnitude;
        }
      }
    }

    final threshold = max(35.0, maxMagnitude * 0.25);
    final result = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final value = magnitudes[y][x] >= threshold ? 255 : 0;
        result.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    return result;
  }

  static img.Image _blendEdges(img.Image base, img.Image edges) {
    final result = img.Image(width: base.width, height: base.height);

    for (var y = 0; y < base.height; y++) {
      for (var x = 0; x < base.width; x++) {
        final pixel = base.getPixel(x, y);
        final edgePixel = edges.getPixel(x, y);
        final edgeStrength = edgePixel.r.toDouble() / 255.0;

        final r = _clamp255(pixel.r.toDouble() * 0.88 + edgeStrength * 60);
        final g = _clamp255(pixel.g.toDouble() * 0.88 + edgeStrength * 60);
        final b = _clamp255(pixel.b.toDouble() * 0.88 + edgeStrength * 60);

        result.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
      }
    }

    return result;
  }

  static int _luminance(num r, num g, num b) {
    return _clamp255((0.299 * r + 0.587 * g + 0.114 * b).round());
  }

  static int _clamp255(num value) {
    if (value < 0) {
      return 0;
    }
    if (value > 255) {
      return 255;
    }
    return value.round();
  }
}
