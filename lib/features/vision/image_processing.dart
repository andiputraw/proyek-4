import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:camera/camera.dart';
import 'dart:isolate';

class ImageProcessing {
  static Uint8List _generateErrorImageBytes(String errorMessage) {
    cv.Mat? errorMat;
    try {
      errorMat = cv.Mat.zeros(480, 640, cv.MatType.CV_8UC3);
      cv.putText(
        errorMat,
        "ERROR: $errorMessage",
        cv.Point(20, 240),
        cv.FONT_HERSHEY_SIMPLEX,
        0.8,
        cv.Scalar(0, 0, 255),
        thickness: 2,
      );

      final (success, bytes) = cv.imencode(".jpg", errorMat);

      if (success) return bytes;

      return Uint8List(0);
    } catch (e) {
      return Uint8List(0);
    } finally {
      errorMat?.dispose();
    }
  }

  static Future<Uint8List> grayscaleImage(XFile xfile) async {
    final imagePath = xfile.path;

    return await Isolate.run<Uint8List>(() {
      cv.Mat? src;
      cv.Mat? grayMat;

      try {
        src = cv.imread(imagePath);
        grayMat = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
        final (success, processedBytes) = cv.imencode(".jpg", grayMat);

        if (success) {
          return (processedBytes);
        } else {
          throw Exception("Failed to encode OpenCV Mat to bytes");
        }
      } catch (e) {
        print("OpenCV Error: $e");
        return _generateErrorImageBytes("$e");
      } finally {
        src?.dispose();
        grayMat?.dispose();
      }
    });
  }

  static Future<Uint8List> lowpassFilter(XFile xfile, {int ksize = 15}) async {
    return await Isolate.run<Uint8List>(() {
      final mats = <cv.Mat>[];
      try {
        final src = cv.imread(xfile.path);
        mats.add(src);
        if (src.isEmpty) throw Exception("Could not read image file");

        final result = cv.gaussianBlur(src, (ksize, ksize), 0);
        mats.add(result);

        final (success, bytes) = cv.imencode(".jpg", result);
        if (success) return bytes;
        throw Exception("Failed to encode Mat");
      } catch (e) {
        return _generateErrorImageBytes("$e");
      } finally {
        for (final m in mats) {
          m.dispose();
        }
      }
    });
  }

  static Future<Uint8List> highpassFilter(XFile xfile) async {
    return await Isolate.run<Uint8List>(() {
      final mats = <cv.Mat>[];
      try {
        final src = cv.imread(xfile.path);
        mats.add(src);

        final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
        mats.add(gray);

        final laplacian = cv.laplacian(gray, cv.MatType.CV_16S);
        mats.add(laplacian);

        final result = cv.convertScaleAbs(laplacian);
        mats.add(result);

        final (success, bytes) = cv.imencode(".jpg", result);
        if (success) return bytes;
        throw Exception("Failed to encode Mat");
      } catch (e) {
        return _generateErrorImageBytes("$e");
      } finally {
        for (final m in mats) {
          m.dispose();
        }
      }
    });
  }

  static Future<Uint8List> bandpassFilter(XFile xfile) async {
    return await Isolate.run<Uint8List>(() {
      final mats = <cv.Mat>[];

      try {
        final src = cv.imread(xfile.path);
        mats.add(src);

        if (src.isEmpty) {
          throw Exception("Could not read image file");
        }

        final kernelData = [
          [0.0, -1.0, 0.0],
          [-1.0, 5.0, -1.0],
          [0.0, -1.0, 0.0],
        ];

        final kernel = cv.Mat.from2DList(kernelData, cv.MatType.CV_32FC1);
        mats.add(kernel);

        final result = cv.filter2D(src, -1, kernel);
        mats.add(result);

        final (success, bytes) = cv.imencode(".jpg", result);

        if (!success) {
          throw Exception("Failed to encode Mat");
        }

        return bytes;
      } catch (e) {
        return _generateErrorImageBytes("Custom Kernel Error: $e");
      } finally {
        for (final m in mats) {
          m.dispose();
        }
      }
    });
  }

  static Future<Uint8List> medianFilter(XFile xfile, {int ksize = 5}) async {
    return await Isolate.run<Uint8List>(() {
      final mats = <cv.Mat>[];
      try {
        final src = cv.imread(xfile.path);
        mats.add(src);

        final result = cv.medianBlur(src, ksize);
        mats.add(result);

        final (success, bytes) = cv.imencode(".jpg", result);
        if (success) return bytes;
        throw Exception("Failed to encode Mat");
      } catch (e) {
        return _generateErrorImageBytes("$e");
      } finally {
        for (final m in mats) {
          m.dispose();
        }
      }
    });
  }

  static Future<Uint8List> equalizeHistogram(XFile xfile) async {
    return await Isolate.run<Uint8List>(() {
      final mats = <cv.Mat>[];

      try {
        final src = cv.imread(xfile.path);
        mats.add(src);

        if (src.isEmpty) {
          throw Exception("Could not read image file");
        }

        final ycrcb = cv.cvtColor(src, cv.COLOR_BGR2YCrCb);
        mats.add(ycrcb);

        final channels = cv.split(ycrcb);
        mats.addAll(channels);

        final yEqualized = cv.equalizeHist(channels[0]);
        mats.add(yEqualized);

        channels[0] = yEqualized;

        final merged = cv.merge(channels);
        mats.add(merged);

        final result = cv.cvtColor(merged, cv.COLOR_YCrCb2BGR);
        mats.add(result);

        final (success, bytes) = cv.imencode(".jpg", result);
        if (!success) throw Exception("Failed to encode Mat");

        return bytes;
      } catch (e) {
        return _generateErrorImageBytes("Equalize Error: $e");
      } finally {
        for (final m in mats) {
          m.dispose();
        }
      }
    });
  }

  static Future<Uint8List> gammaCorrection(
    XFile xfile, {
    double gamma = 2.0,
  }) async {
    return await Isolate.run<Uint8List>(() {
      final mats = <cv.Mat>[];
      try {
        final src = cv.imread(xfile.path);
        mats.add(src);
        if (src.isEmpty) throw Exception("Could not read image file");

        final scaled = src.convertTo(cv.MatType.CV_32FC3, alpha: 1.0 / 255.0);
        mats.add(scaled);

        final powered = cv.pow(scaled, gamma);
        mats.add(powered);

        final result = powered.convertTo(cv.MatType.CV_8UC3, alpha: 255.0);
        mats.add(result);

        final (success, bytes) = cv.imencode(".jpg", result);
        if (success) return bytes;
        throw Exception("Failed to encode Mat");
      } catch (e) {
        return _generateErrorImageBytes("Gamma Error: $e");
      } finally {
        for (final m in mats) {
          m.dispose();
        }
      }
    });
  }
}
