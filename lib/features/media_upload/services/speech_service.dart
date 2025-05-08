import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_speech/google_speech.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speechServiceProvider = Provider((ref) => SpeechService());

class SpeechService {
  // Cache the credentials to avoid reading the file multiple times
  ServiceAccount? _serviceAccount;

  Future<String> transcribeAudio(String filePath) async {
    try {
      // Initialize service account if not already done
      _serviceAccount ??= await _getServiceAccount();

      // Initialize Speech-to-Text with our service account
      final speechToText = SpeechToText.viaServiceAccount(_serviceAccount!);

      // Read audio file
      final File audioFile = File(filePath);
      final List<int> audioBytes = await audioFile.readAsBytes();

      // Get file info for debugging
      debugPrint('Audio file size: ${audioBytes.length} bytes');

      // Set up recognition config - make sure these match your recording settings
      final config = RecognitionConfig(
        encoding: AudioEncoding.LINEAR16,
        sampleRateHertz: 16000,
        languageCode: 'en-US',
        enableAutomaticPunctuation: true,
        model: RecognitionModel.basic,
        audioChannelCount: 1,
      );

      // Start recognition
      debugPrint('Starting audio recognition...');
      final response = await speechToText.recognize(config, audioBytes);

      // Build transcript from results
      String transcript = '';
      for (var result in response.results) {
        for (var alternative in result.alternatives) {
          transcript += alternative.transcript;
        }
      }

      debugPrint('Transcription complete: ${transcript.length} characters');
      return transcript;
    } catch (e) {
      debugPrint('Transcription error: $e');
      if (e is PlatformException) {
        debugPrint('PlatformException details: ${e.message}, ${e.details}');
      }
      throw Exception('Error transcribing audio: $e');
    }
  }

  // Helper method to load service account credentials
  Future<ServiceAccount> _getServiceAccount() async {
    try {
      final String credentialsJson = await rootBundle.loadString(
        'assets/credentials/service-account.json',
      );
      return ServiceAccount.fromString(credentialsJson);
    } catch (e) {
      debugPrint('Error loading service account: $e');
      rethrow;
    }
  }

  // Optional: method for longer audio files that handles timeouts better
  Future<String> transcribeLongAudio(String filePath) async {
    try {
      _serviceAccount ??= await _getServiceAccount();
      final speechToText = SpeechToText.viaServiceAccount(_serviceAccount!);

      final File audioFile = File(filePath);

      // For longer audio, we'll use streaming recognition
      final config = RecognitionConfig(
        encoding: AudioEncoding.FLAC,
        languageCode: 'en-US',
        enableAutomaticPunctuation: true,
        model: RecognitionModel.basic,
        audioChannelCount: 1,
      );

      // Read and stream the audio in chunks to avoid memory issues
      final audioStream = audioFile.openRead().asBroadcastStream();
      final chunks = <List<int>>[];

      await for (final chunk in audioStream) {
        chunks.add(chunk);
      }

      final completeAudio = chunks.expand((chunk) => chunk).toList();

      final response = await speechToText.recognize(config, completeAudio);

      String transcript = '';
      for (var result in response.results) {
        for (var alternative in result.alternatives) {
          transcript += alternative.transcript;
        }
      }

      return transcript;
    } catch (e) {
      debugPrint('Long transcription error: $e');
      throw Exception('Error transcribing long audio: $e');
    }
  }
}
