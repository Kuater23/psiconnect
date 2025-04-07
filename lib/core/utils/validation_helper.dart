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

  /// Validates if the input is a valid email address.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su correo electrónico';
    }
    // Basic regex to validate email format
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Por favor ingrese un correo electrónico válido';
    }
    return null;
  }

  /// Validates if the input is a valid license number (numeric only).
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su número de matrícula';
    }
    // Only allow digits for license numbers
    final licenseRegExp = RegExp(r'^\d+$');
    if (!licenseRegExp.hasMatch(value)) {
      return 'El número de matrícula debe ser un número válido';
    }
    return null;
  }

  /// Method to check if all mandatory fields are present in user data
  static bool checkMandatoryData(Map<String, dynamic> data) {
    return data['firstName'] != null && // Cambiar 'name' a 'firstName'
        data['lastName'] != null &&
        data['address'] != null &&
        data['phoneN'] != null && // Cambiar 'phone' a 'phoneN'
        data['dni'] != null && // Cambiar 'documentNumber' a 'dni'
        data['license'] != null && // Cambiar 'n_matricula' a 'license'
        data['documentType'] != null;
  }
}
