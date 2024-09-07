import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider que controla el estado de desplazamiento de una lista o pantalla.
/// 
/// Este provider almacena un valor booleano que indica si una lista o una 
/// pantalla se ha desplazado (`true`) o no (`false`).
final scrolledProvider = StateProvider<bool>((ref) => false);
