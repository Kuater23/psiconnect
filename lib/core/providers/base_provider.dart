import 'package:flutter/foundation.dart';
import '../services/error_logger.dart';

/// Estado de carga común para providers
enum LoadingState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider base con manejo de estados de carga y errores
abstract class BaseProvider extends ChangeNotifier {
  LoadingState _loadingState = LoadingState.initial;
  String? _errorMessage;

  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isLoaded => _loadingState == LoadingState.loaded;
  bool get isInitial => _loadingState == LoadingState.initial;

  /// Establecer estado de carga
  void setLoading() {
    _loadingState = LoadingState.loading;
    _errorMessage = null;
    notifyListeners();
  }

  /// Establecer estado de cargado
  void setLoaded() {
    _loadingState = LoadingState.loaded;
    _errorMessage = null;
    notifyListeners();
  }

  /// Establecer estado de error
  void setError(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _errorMessage = null;
    if (_loadingState == LoadingState.error) {
      _loadingState = LoadingState.initial;
    }
    notifyListeners();
  }

  /// Ejecutar operación asíncrona con manejo automático de estados
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool silent = false,
  }) async {
    try {
      if (!silent) setLoading();
      
      final result = await operation();
      
      if (!silent) setLoaded();
      return result;
    } catch (e, st) {
      final message = errorMessage ?? 'Ocurrió un error: ${e.toString()}';
      setError(message);
      ErrorLogger.logError(message, e, st);
      return null;
    }
  }

  /// Ejecutar operación asíncrona sin cambiar estados (útil para operaciones en background)
  Future<T?> executeSilent<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e, st) {
      ErrorLogger.logError('Error en operación silenciosa', e, st);
      return null;
    }
  }

  @override
  void dispose() {
    _loadingState = LoadingState.initial;
    _errorMessage = null;
    super.dispose();
  }
}