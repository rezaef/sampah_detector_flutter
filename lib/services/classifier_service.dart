import 'dart:math';

        import 'package:flutter/services.dart';
        import 'package:image/image.dart' as img;
        import 'package:tflite_flutter/tflite_flutter.dart';

        import '../models/classification_result.dart';
        import '../utils/image_preprocessor.dart';

        class ClassifierService {
          ClassifierService._();

          static final ClassifierService instance = ClassifierService._();

          Interpreter? _interpreter;
          List<String> _labels = const ['Organik', 'Anorganik'];
          bool _initialized = false;

          bool get isUsingModel => _interpreter != null;

          Future<void> initialize() async {
            if (_initialized) {
              return;
            }

            _initialized = true;
            await _loadLabels();
            await _loadModel();
          }

          Future<void> _loadLabels() async {
            try {
              final content = await rootBundle.loadString('assets/models/labels.txt');
              final labels = content
                  .split(RegExp(r'\r?\n'))
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList();
              if (labels.isNotEmpty) {
                _labels = labels;
              }
            } catch (_) {
              _labels = const ['Organik', 'Anorganik'];
            }
          }

          Future<void> _loadModel() async {
            try {
              _interpreter =
                  await Interpreter.fromAsset('assets/models/waste_classifier.tflite');
            } catch (_) {
              _interpreter = null;
            }
          }

          Future<ClassificationResult> classify(PreprocessingBundle bundle) async {
            await initialize();
            final stopwatch = Stopwatch()..start();

            ClassificationResult result;

            if (_interpreter != null) {
              try {
                result = _classifyWithTflite(bundle.modelImage);
              } catch (_) {
                result = _classifyWithHeuristic(bundle.modelImage, bundle.edgeImage);
              }
            } else {
              result = _classifyWithHeuristic(bundle.modelImage, bundle.edgeImage);
            }

            stopwatch.stop();
            return result.copyWith(latencyMs: stopwatch.elapsedMilliseconds);
          }

          ClassificationResult _classifyWithTflite(img.Image image) {
            final input = ImagePreprocessor.buildInputTensor(image);
            final rawOutput = [List<double>.filled(_labels.length, 0.0)];

            _interpreter!.run(input, rawOutput);

            final normalized = _normalizeScores(rawOutput.first);
            final maxIndex = _argMax(normalized);
            final bestLabel = _labels[maxIndex];

            final scoreMap = <String, double>{};
            for (var i = 0; i < _labels.length; i++) {
              scoreMap[_labels[i]] = normalized[i];
            }

            return ClassificationResult(
              category: _mapCategory(bestLabel),
              confidence: normalized[maxIndex],
              scores: scoreMap,
              isDemo: false,
              engine: 'CNN TFLite',
              latencyMs: 0,
            );
          }

          ClassificationResult _classifyWithHeuristic(img.Image image, img.Image edges) {
            final features = _extractFeatures(image, edges);

            final organicScore =
                (0.50 * features.naturalColorRatio) +
                (0.25 * features.edgeDensity) +
                (0.15 * (1 - features.brightness)) +
                (0.10 * features.textureScore);

            final inorganicScore =
                (0.45 * features.reflectiveRatio) +
                (0.35 * (1 - features.naturalColorRatio)) +
                (0.20 * (1 - (features.edgeDensity * 0.6)));

            final total = organicScore + inorganicScore;
            final organicProbability = total == 0 ? 0.5 : organicScore / total;
            final inorganicProbability = total == 0 ? 0.5 : inorganicScore / total;

            final isOrganic = organicProbability >= inorganicProbability;
            final confidence = _clampProbability(
              isOrganic ? organicProbability : inorganicProbability,
              minValue: 0.51,
              maxValue: 0.95,
            );

            return ClassificationResult(
              category: isOrganic ? WasteCategory.organik : WasteCategory.anorganik,
              confidence: confidence,
              scores: <String, double>{
                'Organik': organicProbability,
                'Anorganik': inorganicProbability,
              },
              isDemo: true,
              engine: 'Analisis Lokal',
              latencyMs: 0,
            );
          }

          WasteCategory _mapCategory(String label) {
            final value = label.toLowerCase();

            if ((value.contains('organik') && !value.contains('anorganik')) ||
                (value.contains('organic') &&
                    !value.contains('inorganic') &&
                    !value.contains('anorganic'))) {
              return WasteCategory.organik;
            }

            if (value.contains('anorganik') ||
                value.contains('inorganik') ||
                value.contains('anorganic') ||
                value.contains('inorganic')) {
              return WasteCategory.anorganik;
            }

            return WasteCategory.tidakDiketahui;
          }

          List<double> _normalizeScores(List<double> rawScores) {
            final safeScores = rawScores.map((value) => value.toDouble()).toList();
            final sum = safeScores.fold<double>(0, (total, value) => total + value);
            final alreadyProbability =
                safeScores.every((value) => value >= 0 && value <= 1) &&
                    sum > 0.9 &&
                    sum < 1.1;

            if (alreadyProbability) {
              return safeScores;
            }

            final maxValue = safeScores.reduce(max);
            final exps = safeScores.map((value) => exp(value - maxValue)).toList();
            final expSum = exps.fold<double>(0, (total, value) => total + value);

            return exps.map((value) => value / expSum).toList();
          }

          int _argMax(List<double> values) {
            var bestIndex = 0;
            var bestValue = values.first;

            for (var i = 1; i < values.length; i++) {
              if (values[i] > bestValue) {
                bestValue = values[i];
                bestIndex = i;
              }
            }

            return bestIndex;
          }

          _ImageFeatures _extractFeatures(img.Image image, img.Image edges) {
            var naturalPixels = 0;
            var reflectivePixels = 0;
            var edgePixels = 0;
            double brightnessSum = 0;
            double luminanceSum = 0;
            double luminanceSquaredSum = 0;
            final totalPixels = image.width * image.height;

            for (var y = 0; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                final pixel = image.getPixel(x, y);
                final red = pixel.r.toDouble() / 255.0;
                final green = pixel.g.toDouble() / 255.0;
                final blue = pixel.b.toDouble() / 255.0;
                final hsv = _rgbToHsv(red, green, blue);
                final luminance = 0.299 * red + 0.587 * green + 0.114 * blue;

                final isBrown =
                    hsv.h >= 15 && hsv.h <= 55 && hsv.s >= 0.20 && hsv.v <= 0.85;
                final isGreen = hsv.h >= 55 && hsv.h <= 170 && hsv.s >= 0.18;
                if (isBrown || isGreen) {
                  naturalPixels++;
                }

                if (hsv.v >= 0.72 && hsv.s <= 0.22) {
                  reflectivePixels++;
                }

                if (edges.getPixel(x, y).r > 0) {
                  edgePixels++;
                }

                brightnessSum += hsv.v;
                luminanceSum += luminance;
                luminanceSquaredSum += luminance * luminance;
              }
            }

            final meanLuminance = luminanceSum / totalPixels;
            final variance = max(
              0.0,
              (luminanceSquaredSum / totalPixels) -
                  (meanLuminance * meanLuminance),
            );
            final textureScore = _clampProbability(sqrt(variance) * 2.4);

            return _ImageFeatures(
              naturalColorRatio: naturalPixels / totalPixels,
              reflectiveRatio: reflectivePixels / totalPixels,
              edgeDensity: edgePixels / totalPixels,
              brightness: brightnessSum / totalPixels,
              textureScore: textureScore,
            );
          }

          _HsvColor _rgbToHsv(double red, double green, double blue) {
            final maxValue = max(red, max(green, blue));
            final minValue = min(red, min(green, blue));
            final delta = maxValue - minValue;

            double hue;
            if (delta == 0) {
              hue = 0;
            } else if (maxValue == red) {
              hue = 60 * (((green - blue) / delta) % 6);
            } else if (maxValue == green) {
              hue = 60 * (((blue - red) / delta) + 2);
            } else {
              hue = 60 * (((red - green) / delta) + 4);
            }

            if (hue < 0) {
              hue += 360;
            }

            final saturation = maxValue == 0 ? 0 : delta / maxValue;
            final value = maxValue;

            return _HsvColor(
              hue.toDouble(),
              saturation.toDouble(),
              value.toDouble(),
            );
          }

          double _clampProbability(
            double value, {
            double minValue = 0.0,
            double maxValue = 1.0,
          }) {
            if (value < minValue) {
              return minValue;
            }
            if (value > maxValue) {
              return maxValue;
            }
            return value;
          }
        }

        class _ImageFeatures {
          final double naturalColorRatio;
          final double reflectiveRatio;
          final double edgeDensity;
          final double brightness;
          final double textureScore;

          const _ImageFeatures({
            required this.naturalColorRatio,
            required this.reflectiveRatio,
            required this.edgeDensity,
            required this.brightness,
            required this.textureScore,
          });
        }

        class _HsvColor {
          final double h;
          final double s;
          final double v;

          const _HsvColor(this.h, this.s, this.v);
        }
