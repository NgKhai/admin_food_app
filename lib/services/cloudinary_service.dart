// import 'package:cloudinary/cloudinary.dart';
// import 'dart:typed_data';
// import 'dart:convert';
//
// class CloudinaryService {
//   final cloudinary = Cloudinary.signedConfig(
//     apiKey: '693597867127457',
//     apiSecret: 'l6nSZYalHYMHd4krB0TT8YqXX5g',
//     cloudName: 'dt1g4rxgw',
//   );
//
//   Future<String?> uploadImage(Uint8List imageBytes, {String? fileName}) async {
//     try {
//       // Generate a unique filename if not provided
//       fileName ??= 'product_image_${DateTime.now().millisecondsSinceEpoch}.png';
//
//       // Convert Uint8List to base64 encoded string
//       String base64Image = base64Encode(imageBytes);
//
//       // Perform the upload using base64 encoded string
//       final response = await cloudinary.upload(
//         file: 'data:image/png;base64,$base64Image',
//         fileName: fileName,
//         folder: 'FlutterFood',
//         resourceType: CloudinaryResourceType.image,
//         // Optional transformations
//         // transformations: [
//         //   Transformation().width(800).height(600).crop('limit')
//         // ],
//       );
//
//       // Check upload response
//       if (response.isSuccessful) {
//         // Return the secure URL of the uploaded image
//         print('Image uploaded successfully: ${response.secureUrl}');
//         return response.secureUrl;
//       } else {
//         // Log any errors during upload
//         print('Upload failed: ${response.error}');
//         print('Response: ${response.toString()}');
//         return null;
//       }
//     } catch (e) {
//       // Handle any exceptions during upload
//       print('Cloudinary upload error: $e');
//       return null;
//     }
//   }
// }

import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  final String cloudName = 'dt1g4rxgw';
  final String apiKey = '693597867127457';
  final String apiSecret = 'l6nSZYalHYMHd4krB0TT8YqXX5g';

  Future<String?> uploadImage(
      Uint8List imageFile, {
        required String fileName,
        String folder = 'products',
      }) async {
    try {
      // Generate timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Prepare signature parameters
      final signatureParams = {
        'timestamp': timestamp,
        'folder': folder,
        'public_id': fileName,
      };

      // Generate signature
      final signature = _generateSignature(signatureParams);

      // Prepare multipart request
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = folder
        ..fields['public_id'] = fileName;

      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageFile,
        filename: fileName,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Print full response for debugging
      print('Cloudinary Response Status: ${response.statusCode}');
      print('Cloudinary Response Body: ${response.body}');

      // Check response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['secure_url'];
      } else {
        print('Cloudinary upload error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Generate signature for Cloudinary upload
  String _generateSignature(Map<String, dynamic> params) {
    // Sort parameters alphabetically
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create signature string
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret
    final signatureBase = '$paramString$apiSecret';

    // Generate SHA-1 hash
    final bytes = utf8.encode(signatureBase);
    final digest = sha1.convert(bytes);

    return digest.toString();
  }
}
