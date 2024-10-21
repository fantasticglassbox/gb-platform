import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class GbCacheManager {
  final Dio _dio = Dio();

  Future<File?> getCachedFile(String url) async {
    try {
      // Get the temporary directory for caching
      final Directory tempDir = await getTemporaryDirectory();
      String fileName = url.split('/').last;
      final File file = File('${tempDir.path}/$fileName');

      // Check if the file already exists
      if (await file.exists()) {
        return file; // Return the cached file
      }

      // Download the file
      final response = await _dio.download(url, file.path);
      if (response.statusCode == 200) {
        return file; // Return the newly downloaded file
      }
    } catch (e) {
      print('Error caching file: $e');
      throw e;
    }
    return null; // Return null in case of error
  }
  Future<void> deleteCacheDir() async {
    var tempDir = await getTemporaryDirectory();
    print('remove $tempDir');
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }

  Future<void> deleteAppDir() async {
    var appDocDir = await getApplicationDocumentsDirectory();

    if (appDocDir.existsSync()) {
      appDocDir.deleteSync(recursive: true);
    }
  }
}
