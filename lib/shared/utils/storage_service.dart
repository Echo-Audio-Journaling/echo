import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Method to upload XFile to Firebase Storage
  Future<String?> uploadXFile(XFile xFile, String uid) async {
    try {
      // Create a unique file path using timestamp and original filename
      final ref = _storage.ref().child('profile/$uid');

      // Convert XFile to File or Uint8List based on platform
      UploadTask uploadTask;

      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile platforms, convert to File
        final file = File(xFile.path);
        uploadTask = ref.putFile(file);
      } else {
        // For web platform, use Uint8List
        final bytes = await xFile.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/${xFile.name.split('.').last}'),
        );
      }

      // Wait for the upload to complete
      final snapshot = await uploadTask;

      // Get and return the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Method to delete a file from Firebase Storage using its reference path
  Future<bool> deleteFile(String referencePath) async {
    try {
      // Get a reference to the file
      final ref = _storage.ref().child(referencePath);

      // Delete the file
      await ref.delete();

      return true;
    } catch (e) {
      return false;
    }
  }

  // Helper method to get the reference path from a download URL
  Future<String?> getReferencePathFromUrl(String downloadUrl) async {
    try {
      // Create a reference from the download URL
      final ref = _storage.refFromURL(downloadUrl);

      // Return the full path
      return ref.fullPath;
    } catch (e) {
      return null;
    }
  }
}
