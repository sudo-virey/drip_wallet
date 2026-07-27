import 'package:flutter/material.dart';
import 'package:drip_ui/drip_ui.dart';

/// Helper extension para acceder al tema de drip_ui de forma centralizada.
/// 
/// Facilita el acceso a la extensión [DripThemeExtension] desde cualquier widget
/// de forma más limpia y concisa que acceder directamente a Theme.of(context).
/// 
/// ## Uso:
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Container(
///       color: context.dripBackground,  // Color de fondo
///       child: Text(
///         'Hello',
///         style: TextStyle(color: context.dripLabel),  // Color de label
///       ),
///     );
///   }
/// }
/// ```
/// 
/// ## Propiedades disponibles:
/// - [dripTheme] - Acceso directo a la extensión completa de DripThemeExtension
/// - [dripPrimary] - Color primario (botones, links, acentos)
/// - [dripBackground] - Color de fondo de la pantalla
/// - [dripInputBackground] - Color de fondo de campos de entrada
/// - [dripLabel] - Color de etiquetas de formularios
/// - [dripHint] - Color de texto de ayuda (hints)
/// 
/// Si no hay extensión de tema disponible, el helper automáticamente elige
/// entre DripThemeExtension.light() o DripThemeExtension.dark() según el
/// brightness del tema actual.
extension DripThemeHelper on BuildContext {
  /// Obtiene la extensión de tema de drip_ui del contexto actual.
  /// Si no está disponible, utiliza el tema por defecto (light o dark según el modo).
  DripThemeExtension get dripTheme {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return Theme.of(this).extension<DripThemeExtension>() ?? 
        (isDark ? DripThemeExtension.dark() : DripThemeExtension.light());
  }

  /// Acceso directo al color primario de drip_ui.
  /// Típicamente usado para botones, links y acentos.
  Color get dripPrimary => dripTheme.primaryColor;

  /// Acceso directo al color de fondo de drip_ui.
  /// Color de fondo de las pantallas y scaffolds.
  Color get dripBackground => dripTheme.backgroundColor;

  /// Acceso directo al color de fondo de inputs de drip_ui.
  /// Color usado en campos de texto y otros inputs.
  Color get dripInputBackground => dripTheme.inputBackground;

  /// Acceso directo al color de labels de drip_ui.
  /// Color usado en etiquetas de formularios.
  Color get dripLabel => dripTheme.labelColor;

  /// Acceso directo al color de hints de drip_ui.
  /// Color usado en texto de ayuda y placeholders.
  Color get dripHint => dripTheme.hintColor;
}
