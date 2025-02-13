class ValidationHelper {
  /// Validates if the input is not empty.
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese su $fieldName';
    }
    return null;
  }

  /// Validates if the input is a valid phone number.
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese su número de teléfono';
    }
    // Basic regex to validate phone number format
    final phoneRegExp = RegExp(r'^(\+?[0-9]{7,15})\$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Por favor ingrese un número de teléfono válido';
    }
    return null;
  }

  /// Validates if the input is a valid document number.
  static String? validateDocumentNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese su número de documento';
    }
    // Ensure it contains only numbers
    final documentRegExp = RegExp(r'^\d{7,15}\$');
    if (!documentRegExp.hasMatch(value)) {
      return 'Ingrese un número de documento válido';
    }
    return null;
  }

  /// Validates if the input is a valid email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese su correo electrónico';
    }
    // Improved regex to validate email format
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Por favor ingrese un correo electrónico válido';
    }
    return null;
  }

  /// Validates if the input is a valid license number (numeric only).
  static String? validateLicenseNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingrese su número de matrícula';
    }
    // Only allow digits for license numbers
    final licenseRegExp = RegExp(r'^\d{5,10}\$');
    if (!licenseRegExp.hasMatch(value)) {
      return 'El número de matrícula debe ser un número válido';
    }
    return null;
  }

  /// Method to check if all mandatory fields are present in user data
  static bool checkMandatoryData(Map<String, dynamic> data) {
    return data['name'] != null &&
        data['lastName'] != null &&
        data['address'] != null &&
        data['phone'] != null &&
        data['dni'] != null && // Updated key to match document field
        data['n_matricula'] != null &&
        data['specialty'] != null;
  }
}
