class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const []});

  final String message;
  final int? statusCode;
  final List<String> fieldErrors;

  bool get isNetworkError => statusCode == null && message.isEmpty;

  @override
  String toString() => message;
}
