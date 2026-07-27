/// # Guía de uso: DripThemeHelper
/// 
/// Este archivo documenta cómo usar el theme helper de drip_ui en nuevas pantallas.
/// 
/// ## ¿Por qué usar DripThemeHelper?
/// 
/// La librería `drip_ui` proporciona componentes que se personalizan automáticamente
/// según el tema de la app. Para que esto funcione, necesitamos asegurar que
/// [DripThemeExtension] está disponible en el [ThemeData] de la app.
/// 
/// El helper [DripThemeHelper] simplifica el acceso a los colores del tema sin
/// necesidad de escribir código repetitivo.
/// 
/// ## Instalación
/// 
/// 1. El helper ya está disponible en [lib/core/theme/drip_theme_helper.dart]
/// 2. Importa el archivo en tu pantalla:
/// 
/// ```dart
/// import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
/// ```
/// 
/// ## Uso en una pantalla
/// 
/// ### Ejemplo básico:
/// ```dart
/// class MyScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       backgroundColor: context.dripBackground,  // ← Color de fondo del tema
///       body: Column(
///         children: [
///           Text(
///             'Title',
///             style: TextStyle(color: context.dripLabel),  // ← Color de etiqueta
///           ),
///           TextField(
///             decoration: InputDecoration(
///               fillColor: context.dripInputBackground,  // ← Color de input
///               hintStyle: TextStyle(color: context.dripHint),  // ← Color de hint
///             ),
///           ),
///           ElevatedButton(
///             onPressed: () {},
///             style: ElevatedButton.styleFrom(
///               backgroundColor: context.dripPrimary,  // ← Color primario
///             ),
///             child: const Text('Save'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// 
/// ### En un StatefulWidget:
/// ```dart
/// class MyStatefulScreen extends StatefulWidget {
///   @override
///   State<MyStatefulScreen> createState() => _MyStatefulScreenState();
/// }
/// 
/// class _MyStatefulScreenState extends State<MyStatefulScreen> {
///   @override
///   Widget build(BuildContext context) {
///     // Acceso disponible desde cualquier método
///     return Scaffold(
///       backgroundColor: context.dripBackground,
///       body: _buildContent(),
///     );
///   }
///   
///   Widget _buildContent() {
///     // ← También disponible aquí
///     return Container(
///       color: context.dripBackground,
///       child: Text('Hello', style: TextStyle(color: context.dripLabel)),
///     );
///   }
/// }
/// ```
/// 
/// ## Colores disponibles
/// 
/// | Propiedad | Uso típico |
/// |-----------|-----------|
/// | `dripPrimary` | Botones, links, acentos principales |
/// | `dripBackground` | Fondo de pantallas y scaffolds |
/// | `dripInputBackground` | Fondo de campos de texto y inputs |
/// | `dripLabel` | Etiquetas de formularios |
/// | `dripHint` | Texto de ayuda y placeholders |
/// | `dripTheme` | Acceso directo a la extensión completa |
/// 
/// ## Configuración del tema en app_theme.dart
/// 
/// Los temas light y dark están configurados en [lib/core/theme/app_theme.dart]:
/// 
/// ```dart
/// extensions: [
///   DripThemeExtension(
///     primaryColor: const Color(0xFF000666),
///     backgroundColor: const Color(0xFFF7F9FC),
///     inputBackground: const Color(0xFFFFFFFF),
///     labelColor: const Color(0xFF191c1e),
///     hintColor: const Color(0xFF999999),
///   ),
/// ],
/// ```
/// 
/// Para cambiar colores globales de la app, modifica estos valores.
/// Los cambios se aplicarán automáticamente a todos los widgets que usen el helper.
/// 
/// ## Cambio automático de tema (Light/Dark)
/// 
/// La app está configurada con `themeMode: ThemeMode.system`, lo que significa
/// que cambia automáticamente entre temas light y dark según la preferencia
/// del dispositivo. El helper detecta automáticamente el modo actual y aplica
/// los colores correctos.
/// 
/// ## Deprecation: withOpacity()
/// 
/// Los métodos `withOpacity()` están deprecated en versiones recientes de Flutter.
/// Usa `withValues()` en su lugar:
/// 
/// ```dart
/// // ❌ Evita
/// context.dripHint.withOpacity(0.5);
/// 
/// // ✅ Usa en su lugar
/// context.dripHint.withValues(alpha: 0.5);
/// ```
/// 
/// ## Ejemplo completo: LoginScreen
/// 
/// Ver [lib/features/auth/presentation/pages/login_screen.dart] para un
/// ejemplo completo de cómo usar el helper en una pantalla real.
