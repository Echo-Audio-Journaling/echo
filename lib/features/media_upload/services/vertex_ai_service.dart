import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis_auth/auth_io.dart';

final vertexAiServiceProvider = Provider((ref) => VertexAIService());

class VertexAIService {
  static const String credentialsPath =
      'assets/credentials/vertex-ai-credentials.json';

  // Project and location details
  final String _projectId = dotenv.env['GCP_PROJECT_ID'] as String;
  final String _location = 'us-central1';

  // Use gemini-2.0-flash-lite as the primary model for faster, more efficient responses
  final String _modelPublisher = 'google';
  final String _primaryModel = 'gemini-2.0-flash-lite'; // Fastest Gemini model
  final String _fallbackModel =
      'gemini-pro'; // Fallback to standard Gemini if needed

  // Dio instance with configurations
  late final Dio _dio;

  // Cancel tokens for managing requests
  final Map<String, CancelToken> _cancelTokens = {};
  final int _maxCachedTokens = 20; // Limit for token map size

  // Cache for responses to reduce API calls
  final Map<String, dynamic> _responseCache = {};
  final Duration _cacheDuration = const Duration(minutes: 30);

  // Constructor
  VertexAIService() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Add the auth interceptor
    _dio.interceptors.add(AuthInterceptor(this));

    // Add a logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }
  }

  // Method to cancel ongoing requests
  void cancelRequests(String tag) {
    if (_cancelTokens.containsKey(tag)) {
      _cancelTokens[tag]?.cancel('Request cancelled by user');
      _cancelTokens.remove(tag);
    }

    // Clean up old tokens if we have too many
    if (_cancelTokens.length > _maxCachedTokens) {
      final oldestTags = _cancelTokens.keys.take(
        _cancelTokens.length - _maxCachedTokens ~/ 2,
      );
      for (final oldTag in oldestTags.toList()) {
        _cancelTokens.remove(oldTag);
      }
    }
  }

  // Clean up expired cache entries
  void _cleanCache() {
    final now = DateTime.now();
    final expiredKeys =
        _responseCache.keys.where((key) {
          final cacheEntry = _responseCache[key];
          if (cacheEntry == null || !cacheEntry.containsKey('timestamp')) {
            return true; // Remove if no timestamp
          }
          final timestamp = cacheEntry['timestamp'] as DateTime;
          return now.difference(timestamp) > _cacheDuration;
        }).toList();

    for (final key in expiredKeys) {
      _responseCache.remove(key);
    }
  }

  // Authentication
  Future<String> _getAccessToken() async {
    try {
      final credentialsJson = await rootBundle.loadString(credentialsPath);
      final credentials = ServiceAccountCredentials.fromJson(
        jsonDecode(credentialsJson),
      );

      // Create a custom client that uses Dio
      final authClient = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/cloud-platform',
      ]);

      final accessToken = authClient.credentials.accessToken.data;
      authClient.close();

      return accessToken;
    } catch (e) {
      debugPrint('❌ Error getting access token: $e');
      rethrow;
    }
  }

  // 1. Correct the transcription using Gemini model
  Future<String> correctTranscription(
    String originalTranscription, {
    String? tag,
    bool useCache = true,
  }) async {
    // Return early if empty input
    if (originalTranscription.isEmpty) {
      return originalTranscription;
    }

    // Check cache if enabled
    if (useCache) {
      _cleanCache(); // Clean expired entries

      final cacheKey = 'correction:${originalTranscription.hashCode}';
      if (_responseCache.containsKey(cacheKey)) {
        final cachedResult = _responseCache[cacheKey];
        if (cachedResult != null && cachedResult.containsKey('data')) {
          debugPrint('✓ Using cached transcription correction');
          return cachedResult['data'] as String;
        }
      }
    }

    final cancelToken = CancelToken();
    if (tag != null) {
      // Cancel any existing request with this tag
      cancelRequests(tag);
      _cancelTokens[tag] = cancelToken;
    }

    return _retry(() async {
      try {
        // Use Gemini directly with generateContent endpoint
        final url =
            'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models/$_primaryModel:generateContent';

        final response = await _dio.post(
          url,
          data: {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'text':
                        '''You are an expert text editor. Correct any grammatical errors, fix punctuation, and ensure this transcribed audio text flows naturally. Do not add new information or change the meaning. Only return the corrected text without any explanations.
                    
                        Original transcription: "$originalTranscription"''',
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 1024,
              'topK': 40,
              'topP': 0.95,
            },
          },
          cancelToken: cancelToken,
        );

        // Process Gemini response
        if (response.statusCode == 200) {
          if (response.data.containsKey('candidates') &&
              response.data['candidates'] is List &&
              response.data['candidates'].isNotEmpty) {
            final candidate = response.data['candidates'][0];
            if (candidate.containsKey('content') &&
                candidate['content'].containsKey('parts') &&
                candidate['content']['parts'] is List &&
                candidate['content']['parts'].isNotEmpty) {
              final part = candidate['content']['parts'][0];
              if (part.containsKey('text')) {
                final result = part['text'].toString().trim();

                // Cache successful result if enabled
                if (useCache) {
                  _responseCache['correction:${originalTranscription.hashCode}'] =
                      {'data': result, 'timestamp': DateTime.now()};
                }

                return result;
              }
            }
          }

          debugPrint(
            '❌ Unexpected Gemini response structure: ${response.data}',
          );
        } else {
          debugPrint(
            '⚠️ Correction API returned unexpected status: ${response.statusCode}',
          );
          debugPrint('Response data: ${response.data}');

          // If getting 404, try with fallback model
          if (response.statusCode == 404) {
            debugPrint('🔄 Trying with fallback Gemini model...');
            return await _correctWithFallbackModel(
              originalTranscription,
              cancelToken,
            );
          }
        }

        return originalTranscription; // Return original if correction fails
      } on DioException catch (e) {
        // Handle Dio errors specifically
        if (CancelToken.isCancel(e)) {
          debugPrint('Request canceled: ${e.message}');
          return originalTranscription;
        }

        debugPrint('❌ Dio Error correcting transcription: ${e.message}');
        if (e.response != null) {
          debugPrint('Response data: ${e.response?.data}');
          debugPrint('Response status: ${e.response?.statusCode}');

          // Try with fallback model if we get 404
          if (e.response?.statusCode == 404) {
            debugPrint('🔄 Trying with fallback Gemini model...');
            return await _correctWithFallbackModel(
              originalTranscription,
              cancelToken,
            );
          }
        }

        return originalTranscription; // Return original if correction fails
      } catch (e) {
        debugPrint('❌ Exception correcting transcription: $e');
        return originalTranscription; // Return original if correction fails
      }
    });
  }

  // Fallback correction using standard Gemini model
  Future<String> _correctWithFallbackModel(
    String originalTranscription,
    CancelToken? cancelToken,
  ) async {
    try {
      final url =
          'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models/$_fallbackModel:generateContent';

      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      '''You are an expert text editor. Correct any grammatical errors, fix punctuation, and ensure this transcribed audio text flows naturally. Do not add new information or change the meaning. Only return the corrected text without any explanations.
                  
                      Original transcription: "$originalTranscription"''',
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
            'topK': 40,
            'topP': 0.95,
          },
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        if (response.data.containsKey('candidates') &&
            response.data['candidates'] is List &&
            response.data['candidates'].isNotEmpty) {
          final candidate = response.data['candidates'][0];
          if (candidate.containsKey('content') &&
              candidate['content'].containsKey('parts') &&
              candidate['content']['parts'] is List &&
              candidate['content']['parts'].isNotEmpty) {
            final part = candidate['content']['parts'][0];
            if (part.containsKey('text')) {
              return part['text'].toString().trim();
            }
          }
        }

        debugPrint('❌ Unexpected Gemini response structure: ${response.data}');
      } else {
        debugPrint(
          '❌ Gemini API error: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error using fallback model: $e');
    }

    return originalTranscription;
  }

  // 2. Generate title and tags using Gemini model
  Future<Map<String, dynamic>> generateTitleAndTags(
    String transcription, {
    String? tag,
    bool useCache = true,
  }) async {
    // Return early if empty input
    if (transcription.isEmpty) {
      return {'title': '', 'tags': <String>[]};
    }

    // Check cache if enabled
    if (useCache) {
      _cleanCache(); // Clean expired entries

      final cacheKey = 'title-tags:${transcription.hashCode}';
      if (_responseCache.containsKey(cacheKey)) {
        final cachedResult = _responseCache[cacheKey];
        if (cachedResult != null && cachedResult.containsKey('data')) {
          debugPrint('✓ Using cached title and tags');
          return cachedResult['data'] as Map<String, dynamic>;
        }
      }
    }

    final cancelToken = CancelToken();
    if (tag != null) {
      // Cancel any existing request with this tag
      cancelRequests(tag);
      _cancelTokens[tag] = cancelToken;
    }

    return _retry(() async {
      try {
        // Use Gemini directly with generateContent endpoint
        final url =
            'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models/$_primaryModel:generateContent';

        final response = await _dio.post(
          url,
          data: {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {
                    'text':
                        '''Based on the following transcription, generate a concise, descriptive title (maximum 8 words) and exactly 5 relevant tags. The tags should be single words or short phrases that capture key topics, emotions, or themes in the content. Format your response as JSON with "title" and "tags" keys.

                        Transcription: "$transcription"

                        Only respond with the JSON. No other text.''',
                  },
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 1024,
              'topK': 40,
              'topP': 0.8,
            },
          },
          cancelToken: cancelToken,
        );

        // Process Gemini response
        if (response.statusCode == 200) {
          if (response.data.containsKey('candidates') &&
              response.data['candidates'] is List &&
              response.data['candidates'].isNotEmpty) {
            final candidate = response.data['candidates'][0];
            if (candidate.containsKey('content') &&
                candidate['content'].containsKey('parts') &&
                candidate['content']['parts'] is List &&
                candidate['content']['parts'].isNotEmpty) {
              final part = candidate['content']['parts'][0];
              if (part.containsKey('text')) {
                final text = part['text'].toString();

                // Extract JSON from the response
                final RegExp jsonRegExp = RegExp(
                  r'\{(?:[^{}]|(?:\{(?:[^{}]|(?:\{[^{}]*\}))*\}))*\}',
                );
                final match = jsonRegExp.firstMatch(text);

                if (match != null) {
                  final jsonStr = match.group(0);
                  try {
                    final parsedData = jsonDecode(jsonStr!);

                    if (parsedData.containsKey('title') &&
                        parsedData.containsKey('tags')) {
                      final result = {
                        'title': parsedData['title'] ?? '',
                        'tags': List<String>.from(parsedData['tags'] ?? []),
                      };

                      // Cache successful result if enabled
                      if (useCache) {
                        _responseCache['title-tags:${transcription.hashCode}'] =
                            {'data': result, 'timestamp': DateTime.now()};
                      }

                      return result;
                    }
                  } catch (e) {
                    debugPrint('❌ Error parsing JSON from response: $e');
                    debugPrint('JSON string was: $jsonStr');
                  }
                }
              }
            }
          }

          debugPrint(
            '❌ Unexpected Gemini response structure: ${response.data}',
          );
        } else {
          debugPrint(
            '⚠️ Title/Tags API returned unexpected status: ${response.statusCode}',
          );
          debugPrint('Response data: ${response.data}');

          // If getting 404, try with fallback model
          if (response.statusCode == 404) {
            debugPrint('🔄 Trying with fallback Gemini model...');
            return await _generateTitleAndTagsWithFallbackModel(
              transcription,
              cancelToken,
            );
          }
        }

        return _extractBasicTitleAndTags(transcription);
      } on DioException catch (e) {
        // Handle Dio errors specifically
        if (CancelToken.isCancel(e)) {
          debugPrint('Request canceled: ${e.message}');
          return _extractBasicTitleAndTags(transcription);
        }

        debugPrint('❌ Dio Error generating title and tags: ${e.message}');
        if (e.response != null) {
          debugPrint('Response data: ${e.response?.data}');
          debugPrint('Response status: ${e.response?.statusCode}');

          // Try with fallback model if we get 404
          if (e.response?.statusCode == 404) {
            debugPrint('🔄 Trying with fallback Gemini model...');
            return await _generateTitleAndTagsWithFallbackModel(
              transcription,
              cancelToken,
            );
          }
        }

        return _extractBasicTitleAndTags(transcription);
      } catch (e) {
        debugPrint('❌ Exception generating title and tags: $e');
        return _extractBasicTitleAndTags(transcription);
      }
    });
  }

  // Fallback title and tag generation using standard Gemini model
  Future<Map<String, dynamic>> _generateTitleAndTagsWithFallbackModel(
    String transcription,
    CancelToken? cancelToken,
  ) async {
    try {
      final url =
          'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models/$_fallbackModel:generateContent';

      final response = await _dio.post(
        url,
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      '''Based on the following transcription, generate a concise, descriptive title (maximum 8 words) and exactly 5 relevant tags. The tags should be single words or short phrases that capture key topics, emotions, or themes in the content. Format your response as JSON with "title" and "tags" keys.

                      Transcription: "$transcription"
                  
                      Only respond with the JSON. No other text.''',
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
            'topK': 40,
            'topP': 0.8,
          },
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200) {
        if (response.data.containsKey('candidates') &&
            response.data['candidates'] is List &&
            response.data['candidates'].isNotEmpty) {
          final candidate = response.data['candidates'][0];
          if (candidate.containsKey('content') &&
              candidate['content'].containsKey('parts') &&
              candidate['content']['parts'] is List &&
              candidate['content']['parts'].isNotEmpty) {
            final part = candidate['content']['parts'][0];
            if (part.containsKey('text')) {
              final text = part['text'].toString();

              // Extract JSON from the response
              final RegExp jsonRegExp = RegExp(
                r'\{(?:[^{}]|(?:\{(?:[^{}]|(?:\{[^{}]*\}))*\}))*\}',
              );
              final match = jsonRegExp.firstMatch(text);

              if (match != null) {
                final jsonStr = match.group(0);
                final parsedData = jsonDecode(jsonStr!);

                if (parsedData.containsKey('title') &&
                    parsedData.containsKey('tags')) {
                  return {
                    'title': parsedData['title'] ?? '',
                    'tags': List<String>.from(parsedData['tags'] ?? []),
                  };
                }
              }
            }
          }
        }

        debugPrint('❌ Unexpected Gemini response structure: ${response.data}');
      } else {
        debugPrint(
          '❌ Gemini API error: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error using fallback model: $e');
    }

    return _extractBasicTitleAndTags(transcription);
  }

  // Retry mechanism for API calls
  Future<T> _retry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await fn();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) rethrow;

        // Exponential backoff with jitter
        final delay = (1 << attempts) * 1000 + Random().nextInt(1000);
        await Future.delayed(Duration(milliseconds: delay));
        debugPrint('Retrying (${attempts + 1}/$maxRetries) after ${delay}ms');
      }
    }
    throw Exception('Retry failed after $maxRetries attempts');
  }

  // Test connectivity to Vertex AI
  Future<bool> testConnection() async {
    try {
      // Test with our primary model
      final url =
          'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models/$_primaryModel';

      final response = await _dio.get(url);

      debugPrint('Test connection response: ${response.statusCode}');
      debugPrint('Test connection data: ${response.data}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');

      // Try with fallback model
      try {
        final url =
            'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models/$_fallbackModel';

        final response = await _dio.get(url);
        return response.statusCode == 200;
      } catch (e) {
        debugPrint('Fallback connection test also failed: $e');
        return false;
      }
    }
  }

  // List available models to debug
  Future<List<String>> listAvailableModels() async {
    try {
      final url =
          'https://$_location-aiplatform.googleapis.com/v1/projects/$_projectId/locations/$_location/publishers/$_modelPublisher/models';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data.containsKey('models')) {
        final models =
            (response.data['models'] as List)
                .map((model) => model['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList();

        // Log models with specific filtering for Gemini models
        final geminiModels =
            models.where((name) => name.contains('gemini')).toList();
        debugPrint('Available Gemini models: $geminiModels');

        return models;
      }

      debugPrint(
        'Failed to list models: ${response.statusCode} - ${response.data}',
      );
      return [];
    } catch (e) {
      debugPrint('Error listing models: $e');
      return [];
    }
  }

  // Clear all caches and tokens (useful when restarting or resetting)
  void clearAll() {
    // Cancel all ongoing requests
    for (final tag in _cancelTokens.keys) {
      _cancelTokens[tag]?.cancel('Clearing all requests');
    }
    _cancelTokens.clear();

    // Clear response cache
    _responseCache.clear();

    debugPrint('✓ All caches and tokens cleared');
  }

  // Fallback method to extract title and tags if AI fails
  Map<String, dynamic> _extractBasicTitleAndTags(String transcription) {
    // Simple algorithm to extract title and tags
    final words = transcription.split(' ');

    // Title: First 5-7 words of transcription
    final titleWordCount = words.length > 7 ? 7 : words.length;
    final titleWords = words.sublist(0, titleWordCount);
    final title = '${titleWords.join(' ')}...';

    // Tags: Most frequent words excluding common words
    final commonWords = {
      'the',
      'and',
      'a',
      'to',
      'of',
      'in',
      'is',
      'it',
      'that',
      'for',
      'i',
      'you',
      'he',
      'she',
      'we',
      'they',
      'this',
      'there',
      'have',
      'has',
      'had',
      'was',
      'were',
      'am',
      'are',
      'be',
      'been',
      'being',
      'with',
      'from',
      'at',
      'by',
      'on',
      'about',
      'as',
      'into',
      'like',
      'through',
      'after',
      'over',
      'between',
      'out',
      'but',
      'not',
      'what',
      'all',
      'when',
      'up',
      'just',
      'him',
      'her',
      'them',
      'some',
      'can',
      'will',
      'my',
      'one',
      'would',
      'should',
      'could',
      'do',
      'does',
      'did',
      'make',
      'so',
      'no',
      'get',
      'time',
    };

    final wordFrequency = <String, int>{};

    for (final word in words) {
      final normalized = word.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (normalized.length > 3 && !commonWords.contains(normalized)) {
        wordFrequency[normalized] = (wordFrequency[normalized] ?? 0) + 1;
      }
    }

    final sortedWords =
        wordFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final tags = sortedWords.take(5).map((e) => e.key).toList();

    // Ensure we have 5 tags
    if (tags.length < 5) {
      // Add generic tags based on context if we don't have enough
      final genericTags = [
        'recording',
        'voice',
        'note',
        'memo',
        'audio',
        'speech',
        'transcript',
        'conversation',
        'meeting',
        'discussion',
        'thought',
        'idea',
        'reflection',
        'observation',
        'summary',
      ];

      // Add current date-based tag
      final now = DateTime.now();
      final dateTag = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Add random generic tags until we have 5
      final random = Random();
      while (tags.length < 5) {
        // Try to add date tag first
        if (!tags.contains(dateTag)) {
          tags.add(dateTag);
          continue;
        }

        // Then add random generic tags
        final tagIndex = random.nextInt(genericTags.length);
        final tag = genericTags[tagIndex];
        if (!tags.contains(tag)) {
          tags.add(tag);
        }

        // Fallback to ensure we don't get stuck in an infinite loop
        if (tags.length < 5 && tags.length >= genericTags.length + 1) {
          // If we've exhausted options, just add numbered tags
          tags.add('tag${tags.length + 1}');
        }
      }
    }

    return {'title': title, 'tags': tags.take(5).toList()};
  }
}

class AuthInterceptor extends Interceptor {
  final VertexAIService _service;
  String? _accessToken;
  DateTime? _expiryTime;

  AuthInterceptor(this._service);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if we need a new token
    if (_accessToken == null ||
        _expiryTime == null ||
        DateTime.now().isAfter(_expiryTime!)) {
      try {
        _accessToken = await _service._getAccessToken();
        // Tokens usually expire in 1 hour, set expiry to 50 minutes to be safe
        _expiryTime = DateTime.now().add(const Duration(minutes: 50));
      } catch (e) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Failed to acquire access token: $e',
          ),
        );
      }
    }

    options.headers['Authorization'] = 'Bearer $_accessToken';
    return handler.next(options);
  }
}
