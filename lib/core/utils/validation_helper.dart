class ValidationHelper {
  /// Validates if the input is not empty.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su $fieldName';
    }
    return null;
  }

  /// Validates if the input is a valid phone number.
  static String? validatephoneN(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su número de teléfono';
    }
    // Basic regex to validate phone number format
    final phoneRegExp = RegExp(r'^\+?[\d\s]+$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Por favor ingrese un número de teléfono válido';
    }
    return null;
  }

  /// Validates if the input is a valid document number.
  static String? validateDocumentNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su número de documento';
    }
    // Additional document number validation can be added here if needed
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un email válido';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < minLength) {
      return 'La contraseña debe tener al menos $minLength caracteres';
    }
    
    return null;
  }

  // Strong password validation
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Debe contener al menos una minúscula';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener al menos un carácter especial';
    }
    
    return null;
  }

  // Phone validation (formato argentino/internacional)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    
    // Remover espacios y guiones
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Validar que solo contenga números y opcionalmente +
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned)) {
      return 'Ingrese un teléfono válido';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Min length validation
  static String? validateMinLength(String? value, int minLength, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    
    return null;
  }

  // Max length validation
  static String? validateMaxLength(String? value, int maxLength, {String fieldName = 'Este campo'}) {
    if (value != null && value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }
    
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName debe ser un número válido';
    }
    
    return null;
  }

  // Range validation
  static String? validateRange(String? value, double min, double max, {String fieldName = 'Este campo'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    
    if (number < min || number > max) {
      return '$fieldName debe estar entre $min y $max';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? value, {String fieldName = 'Fecha'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerida';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Ingrese una fecha válida';
    }
  }

  // Future date validation
  static String? validateFutureDate(DateTime? date, {String fieldName = 'Fecha'}) {
    if (date == null) {
      return '$fieldName es requerida';
    }
    
    if (date.isBefore(DateTime.now())) {
      return '$fieldName debe ser futura';
    }
    
    return null;
  }

  // Past date validation
  static String? validatePastDate(DateTime? date, {String fieldName = 'Fecha'}) {
    if (date == null) {
      return '$fieldName es requerida';
    }
    
    if (date.isAfter(DateTime.now())) {
      return '$fieldName debe ser pasada';
    }
    
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'La URL es requerida';
    }
    
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Ingrese una URL válida';
      }
      return null;
    } catch (e) {
      return 'Ingrese una URL válida';
    }
  }

  // DNI/CUIL validation (Argentina)
  static String? validateDNI(String? value) {
    if (value == null || value.isEmpty) {
      return 'El DNI es requerido';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleaned.length < 7 || cleaned.length > 8) {
      return 'Ingrese un DNI válido (7-8 dígitos)';
    }
    
    return null;
  }

  // Combine multiple validators
  static String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  // Sanitize input (remove scripts, trim, etc.)
  static String sanitize(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags
  }
}
