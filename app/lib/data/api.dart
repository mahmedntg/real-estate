import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../core/session.dart';
import 'models.dart';

class AqarApi {
  AqarApi(
    this._token, {
    required String baseUrl,
    required void Function() onUnauthorized,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final value = _token();
          if (value != null) {
            options.headers['Authorization'] = 'Bearer $value';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401 && _token() != null) {
            onUnauthorized();
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  final String? Function() _token;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      throw _asApiException(error);
    }
  }

  ApiException _asApiException(DioException error) {
    final response = error.response;
    final data = response?.data;
    String? detail;
    final fieldErrors = <String>[];
    if (data is Map) {
      final rawDetail = data['detail'];
      if (rawDetail is String) {
        detail = rawDetail;
      }
      final rawErrors = data['errors'];
      if (rawErrors is List) {
        for (final item in rawErrors) {
          if (item is Map && item['message'] is String) {
            fieldErrors.add(item['message'] as String);
          }
        }
      }
    }
    return ApiException(
      fieldErrors.isNotEmpty ? fieldErrors.join('\n') : (detail ?? ''),
      statusCode: response?.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  Future<Session> login(String email, String password) => _guard(() async {
        final response = await _dio.post(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        final body = response.data as Map<String, dynamic>;
        return Session(
          token: body['token'] as String,
          user: User.fromJson(body['user'] as Map<String, dynamic>),
        );
      });

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) =>
      _guard(() async {
        final response = await _dio.post(
          '/auth/register',
          data: {
            'full_name': fullName,
            'email': email,
            'phone': (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
            'password': password,
          },
        );
        return RegisterResult.fromJson(response.data as Map<String, dynamic>);
      });

  Future<Session> verifyEmail(String email, String code) => _guard(() async {
        final response = await _dio.post(
          '/auth/verify',
          data: {'email': email, 'code': code},
        );
        final body = response.data as Map<String, dynamic>;
        return Session(
          token: body['token'] as String,
          user: User.fromJson(body['user'] as Map<String, dynamic>),
        );
      });

  Future<RegisterResult> resendCode(String email) => _guard(() async {
        final response = await _dio.post(
          '/auth/resend',
          data: {'email': email},
        );
        return RegisterResult.fromJson(response.data as Map<String, dynamic>);
      });

  Future<PageResult<PropertySummary>> search({
    String query = '',
    PropertyType? type,
    ListingType? listingType,
    String countryCode = 'EG',
    String? governorateCode,
    String? areaCode,
    num? minPrice,
    num? maxPrice,
    int? bedrooms,
    bool? furnished,
    String sort = 'newest',
    int page = 0,
    int size = 12,
  }) =>
      _guard(() async {
        final response = await _dio.get(
          '/properties',
          queryParameters: {
            if (query.trim().isNotEmpty) 'q': query.trim(),
            'type': ?type?.apiValue,
            'listingType': ?listingType?.apiValue,
            'country': countryCode,
            'governorate': ?governorateCode,
            'area': ?areaCode,
            'minPrice': ?minPrice,
            'maxPrice': ?maxPrice,
            'bedrooms': ?bedrooms,
            'furnished': ?furnished,
            'sort': sort,
            'page': page,
            'size': size,
          },
        );
        return PageResult.fromJson(
          response.data as Map<String, dynamic>,
          PropertySummary.fromJson,
        );
      });

  Future<List<Country>> locations() => _guard(() async {
        final response = await _dio.get('/locations');
        return [
          for (final item in response.data as List)
            Country.fromJson(item as Map<String, dynamic>),
        ];
      });

  Future<PropertyDetail> property(String id) => _guard(() async {
        final response = await _dio.get('/properties/$id');
        return PropertyDetail.fromJson(response.data as Map<String, dynamic>);
      });

  Future<PropertyDetail> createProperty(PropertyDraft draft) => _guard(() async {
        final response = await _dio.post('/properties', data: draft.toJson());
        return PropertyDetail.fromJson(response.data as Map<String, dynamic>);
      });

  Future<PropertyDetail> updateProperty(String id, PropertyDraft draft) =>
      _guard(() async {
        final response = await _dio.put('/properties/$id', data: draft.toJson());
        return PropertyDetail.fromJson(response.data as Map<String, dynamic>);
      });

  Future<void> deleteProperty(String id) => _guard(() async {
        await _dio.delete('/properties/$id');
      });

  Future<void> setFavorite(String id, bool favorite) => _guard(() async {
        if (favorite) {
          await _dio.put('/properties/$id/favorite');
        } else {
          await _dio.delete('/properties/$id/favorite');
        }
      });

  Future<List<PropertySummary>> favorites({int page = 0, int size = 50}) =>
      _guard(() async {
        final response = await _dio.get(
          '/me/favorites',
          queryParameters: {'page': page, 'size': size},
        );
        return PageResult.fromJson(
          response.data as Map<String, dynamic>,
          PropertySummary.fromJson,
        ).items;
      });

  Future<List<PropertySummary>> myListings({int page = 0, int size = 50}) =>
      _guard(() async {
        final response = await _dio.get(
          '/me/properties',
          queryParameters: {'page': page, 'size': size},
        );
        return PageResult.fromJson(
          response.data as Map<String, dynamic>,
          PropertySummary.fromJson,
        ).items;
      });

  Future<List<PropertyImage>> uploadImages(
    String propertyId,
    List<XFile> files,
  ) =>
      _guard(() async {
        final form = FormData();
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final name = file.name.isEmpty ? 'image.jpg' : file.name;
          final extension =
              name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
          final subtype = switch (extension) {
            'png' => 'png',
            'webp' => 'webp',
            _ => 'jpeg',
          };
          form.files.add(
            MapEntry(
              'files',
              MultipartFile.fromBytes(
                bytes,
                filename: name,
                contentType: DioMediaType('image', subtype),
              ),
            ),
          );
        }
        final response = await _dio.post(
          '/properties/$propertyId/images',
          data: form,
          options: Options(
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
        return [
          for (final item in response.data as List)
            PropertyImage.fromJson(item as Map<String, dynamic>),
        ];
      });

  Future<void> deleteImage(String propertyId, String imageId) => _guard(() async {
        await _dio.delete('/properties/$propertyId/images/$imageId');
      });

  Future<String> uploadVideo(String propertyId, XFile file) => _guard(() async {
        final bytes = await file.readAsBytes();
        final name = file.name.isEmpty ? 'video.mp4' : file.name;
        final extension =
            name.contains('.') ? name.split('.').last.toLowerCase() : 'mp4';
        final subtype = switch (extension) {
          'webm' => 'webm',
          'mov' => 'quicktime',
          _ => 'mp4',
        };
        final form = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: name,
            contentType: DioMediaType('video', subtype),
          ),
        });
        final response = await _dio.post(
          '/properties/$propertyId/video',
          data: form,
          options: Options(
            sendTimeout: const Duration(minutes: 3),
            receiveTimeout: const Duration(minutes: 3),
          ),
        );
        return (response.data as Map<String, dynamic>)['url'] as String;
      });

  Future<void> deleteVideo(String propertyId) => _guard(() async {
        await _dio.delete('/properties/$propertyId/video');
      });

  Future<List<Conversation>> conversations({int page = 0, int size = 50}) =>
      _guard(() async {
        final response = await _dio.get(
          '/conversations',
          queryParameters: {'page': page, 'size': size},
        );
        return PageResult.fromJson(
          response.data as Map<String, dynamic>,
          Conversation.fromJson,
        ).items;
      });

  Future<Conversation> conversation(String id) => _guard(() async {
        final response = await _dio.get('/conversations/$id');
        return Conversation.fromJson(response.data as Map<String, dynamic>);
      });

  Future<Conversation> startConversation(String propertyId, String message) =>
      _guard(() async {
        final response = await _dio.post(
          '/properties/$propertyId/conversations',
          data: {'message': message},
        );
        return Conversation.fromJson(response.data as Map<String, dynamic>);
      });

  Future<List<Message>> messages(String conversationId, {int size = 100}) =>
      _guard(() async {
        final response = await _dio.get(
          '/conversations/$conversationId/messages',
          queryParameters: {'page': 0, 'size': size},
        );
        return PageResult.fromJson(
          response.data as Map<String, dynamic>,
          Message.fromJson,
        ).items;
      });

  Future<Message> sendMessage(String conversationId, String body) =>
      _guard(() async {
        final response = await _dio.post(
          '/conversations/$conversationId/messages',
          data: {'body': body},
        );
        return Message.fromJson(response.data as Map<String, dynamic>);
      });

  Future<void> markRead(String conversationId) => _guard(() async {
        await _dio.post('/conversations/$conversationId/read');
      });
}

final apiProvider = Provider<AqarApi>((ref) {
  final sessionController = ref.read(sessionProvider.notifier);
  return AqarApi(
    () => ref.read(sessionProvider)?.token,
    baseUrl: apiBaseUrl,
    onUnauthorized: sessionController.signOut,
  );
});

final locationsProvider = FutureProvider<LocationCatalog>((ref) async {
  final countries = await ref.watch(apiProvider).locations();
  return LocationCatalog(countries);
});
