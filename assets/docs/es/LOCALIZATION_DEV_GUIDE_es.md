# Guía de uso de localización para desarrolladores

Esta guía explica cómo usar el sistema de localización en Aquarium AI para los desarrolladores que trabajan en el código fuente.

## Configuración

Después de obtener los cambios de i18n, debe:

1. **Instalar dependencias**:

   ```bash
   flutter pub get
   ```

2. **Generar archivos de localización**:

   ```bash
   flutter gen-l10n
   ```

   Esto genera el código Dart en `.dart_tool/flutter_gen/gen_l10n/`

   **Nota**: Este paso también se ejecuta automáticamente cuando usa `flutter run` o `flutter build`.

3. **Verificar los archivos generados**:
   Se deben generar los siguientes archivos:
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_en.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_es.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_fr.dart`
   - `.dart_tool/flutter_gen/gen_l10n/app_localizations_de.dart`

## Inicio rápido

### Acceder a traducciones en widgets

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Text(l10n.welcomeTitle);
  }
}
```

### Patrones comunes

#### 1. Texto simple

**Antes:**

```dart
Text('Welcome')
```

**Después:**

```dart
Text(AppLocalizations.of(context)!.welcomeTitle)
```

#### 2. Con marcadores de posición

**Antes:**

```dart
Text('Total: $count')
```

**Después (en el archivo ARB):**

```json
"totalTanks": "Total: {count}",
"@totalTanks": {
  "description": "Total number of tanks",
  "placeholders": {
    "count": {
      "type": "int"
    }
  }
}
```

**Después (en el código):**

```dart
Text(AppLocalizations.of(context)!.totalTanks(count))
```

#### 3. En AppBar

**Antes:**

```dart
AppBar(
  title: Text('Settings'),
)
```

**Después:**

```dart
AppBar(
  title: Text(AppLocalizations.of(context)!.settings),
)
```

#### 4. En diálogos

**Antes:**

```dart
AlertDialog(
  title: Text('Error'),
  content: Text('Something went wrong'),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('Close'),
    ),
  ],
)
```

**Después:**

```dart
final l10n = AppLocalizations.of(context)!;

AlertDialog(
  title: Text(l10n.error),
  content: Text('Something went wrong'), // Add to ARB if needed
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(l10n.close),
    ),
  ],
)
```

#### 5. En ListView/ListTile

**Antes:**

```dart
ListTile(
  title: Text('My Tanks'),
  subtitle: Text('Manage your aquariums'),
)
```

**Después:**

```dart
final l10n = AppLocalizations.of(context)!;

ListTile(
  title: Text(l10n.myTanks),
  subtitle: Text('Manage your aquariums'), // Add to ARB if needed
)
```

## Agregar nuevas cadenas

### Paso 1: Agregar a app_en.arb

```json
{
  "newStringKey": "English Text",
  "@newStringKey": {
    "description": "Description of what this string is for"
  }
}
```

### Paso 2: Ejecutar la generación de código

```bash
flutter gen-l10n
```

Esto genera el código Dart en `.dart_tool/flutter_gen/gen_l10n/`

### Paso 3: Usar en el código

```dart
Text(AppLocalizations.of(context)!.newStringKey)
```

### Paso 4: Actualizar otros idiomas

Agregar traducciones a `app_es.arb`, `app_fr.arb`, etc.

## Trabajar con plurales

Para cadenas que cambian según el recuento:

**En app_en.arb:**

```json
{
  "tankCount": "{count, plural, =0{No tanks} =1{1 tank} other{{count} tanks}}",
  "@tankCount": {
    "description": "Number of tanks",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

**En el código:**

```dart
Text(AppLocalizations.of(context)!.tankCount(tankList.length))
```

## Buenas prácticas

### 1. Extraer todas las cadenas visibles para el usuario

Cada cadena que los usuarios ven debe estar en los archivos ARB:

- ✅ Etiquetas de botones
- ✅ Títulos de pantallas
- ✅ Mensajes de error
- ✅ Descripciones
- ✅ Tooltips
- ❌ Registros de depuración
- ❌ Identificadores internos
- ❌ Puntos finales de API

### 2. Usar claves descriptivas

**Bueno:**

```json
"settingsUpdatedSuccess": "Settings updated successfully!"
```

**Malo:**

```json
"msg1": "Settings updated successfully!"
```

### 3. Proporcionar contexto

Siempre incluir `@description`:

```json
{
  "save": "Save",
  "@save": {
    "description": "Save button label"
  }
}
```

### 4. Gestionar la seguridad nula

Siempre usar el operador de aserción nula `!` al acceder a AppLocalizations:

```dart
final l10n = AppLocalizations.of(context)!;
```

Esto es seguro porque configuramos `localizationsDelegates` en `main.dart`.

### 5. Crear una variable auxiliar

Para múltiples usos en el mismo widget:

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  
  return Column(
    children: [
      Text(l10n.welcomeTitle),
      Text(l10n.welcomeSubtitle),
      ElevatedButton(
        onPressed: () {},
        child: Text(l10n.save),
      ),
    ],
  );
}
```

## Probar traducciones

### 1. Ejecutar la app en diferentes idiomas

Cambie el idioma de su dispositivo/emulador para probar las traducciones.

### 2. Forzar un idioma en el código (para pruebas)

```dart
MaterialApp(
  locale: Locale('es'), // Force Spanish
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  // ...
)
```

### 3. Verificar traducciones faltantes

Si falta una traducción, la app volverá al inglés.

## Problemas comunes

### Problema: "AppLocalizations not found"

**Solución:** Ejecutar la generación de código:

```bash
flutter gen-l10n
```

### Problema: "l10n.myNewString doesn't exist"

**Solución:**

1. Asegurarse de que la clave esté en `app_en.arb`
2. Ejecutar `flutter gen-l10n`
3. Reiniciar el IDE/editor

### Problema: El marcador de posición no funciona

**Solución:** Verificar la sintaxis del archivo ARB:

```json
{
  "message": "Hello {name}",
  "@message": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

## Guía de migración

Para migrar cadenas hardcodeadas existentes:

1. **Encontrar la cadena hardcodeada:**

   ```dart
   Text('Welcome')
   ```

2. **Agregar a app_en.arb:**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Ejecutar la generación:**

   ```bash
   flutter gen-l10n
   ```

4. **Actualizar el código:**

   ```dart
   Text(AppLocalizations.of(context)!.welcomeTitle)
   ```

5. **Agregar a otros archivos de idioma:**

   ```json
   // app_es.arb
   "welcomeTitle": "Bienvenido"
   ```

## Estructura de archivos

```text
lib/
│   ├── app_en.arb    (English - template)
│   ├── app_es.arb    (Spanish)
│   ├── app_fr.arb    (French)
│   └── ...
└── main.dart

.dart_tool/
└── flutter_gen/
    └── gen_l10n/
        ├── app_localizations.dart
        ├── app_localizations_en.dart
        ├── app_localizations_es.dart
        └── ...
```

## Recursos

- [Guía de internacionalización de Flutter](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Formato de archivo ARB](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Nuestra guía de traducción](TRANSLATION_GUIDE.md) – Para traductores

## Ejemplo: Migración completa de un widget

**Antes:**

```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      body: Column(
        children: [
          Text('Your intelligent assistant'),
          ElevatedButton(
            onPressed: () {},
            child: Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
```

**Después:**

```dart
class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle),
      ),
      body: Column(
        children: [
          Text(l10n.welcomeSubtitle),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }
}
```

¡Feliz localización! 🌍
