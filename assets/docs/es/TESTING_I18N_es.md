# Guía de pruebas de internacionalización

Esta guía explica cómo probar la implementación de internacionalización en Aquarium AI.

## Requisitos previos

- Flutter SDK instalado
- Proyecto Aquarium AI clonado
- Dependencias instaladas: `flutter pub get`

## Generar código de localización

Antes de realizar pruebas, genere el código de localización:

```bash
flutter gen-l10n
```

Este comando:

- Lee los archivos ARB de `lib/l10n/`
- Genera código Dart en `.dart_tool/flutter_gen/gen_l10n/`
- Crea la clase `AppLocalizations` e implementaciones específicas por idioma

## Métodos de prueba

### 1. Cambiar el idioma del dispositivo

**En el emulador de Android:**

1. Abrir Ajustes
2. Navegar a Sistema > Idioma e introducción de texto > Idiomas
3. Agregar y seleccionar el idioma de prueba (p. ej., español, francés, alemán)
4. Reiniciar la aplicación
5. Verificar que las cadenas traducidas aparecen correctamente

**En el simulador de iOS:**

1. Abrir Ajustes
2. Navegar a General > Idioma y región
3. Seleccionar el idioma de prueba
4. Reiniciar la aplicación
5. Verificar las traducciones

### 2. Forzar un idioma específico en el código (para pruebas)

Modificar temporalmente `lib/main.dart` para forzar un idioma:

```dart
return MaterialApp(
  locale: const Locale('es'), // Force Spanish
  localizationsDelegates: const [
    AppLocalizations.delegate,
    // ...
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('es'),
    // ...
  ],
  // ...
);
```

**¡Recuerde eliminar esto después de las pruebas!**

### 3. Probar el comportamiento de reserva

Probar qué ocurre cuando falta una traducción:

1. Eliminar una clave de un archivo ARB que no sea inglés
2. Configurar el dispositivo en ese idioma
3. La aplicación debe volver al inglés para esa cadena

### 4. Probar valores de marcadores de posición

Para cadenas con marcadores de posición (p. ej., `{count}`):

1. Navegar a la sección "Mis acuarios"
2. Crear varios acuarios
3. Verificar que el recuento se muestra correctamente en su idioma
4. Comprobar el formato: `"Total: {count}"` debe mostrar `"Total: 3"` (o el equivalente traducido)

### 5. Verificar idiomas RTL (si se añaden)

Para idiomas de derecha a izquierda como el árabe:

1. Configurar el idioma del dispositivo en árabe
2. Verificar que la interfaz se refleja correctamente
3. Comprobar que el texto se alinea a la derecha
4. Asegurarse de que los iconos y la navegación están reflejados

## Qué probar

### Pantalla de bienvenida

- [ ] Título de bienvenida
- [ ] Subtítulo de bienvenida
- [ ] Todos los nombres de funciones (Herramienta de compatibilidad IA, Chatbot IA, etc.)
- [ ] Todas las descripciones de funciones
- [ ] Botón "Crear tu primer acuario"

### Cajón de la aplicación

- [ ] Título "Mis acuarios"
- [ ] Mensaje "Aún no hay acuarios"
- [ ] Todos los títulos de elementos del menú
- [ ] Todas las descripciones de elementos del menú

### Pantalla de ajustes

- [ ] Título de ajustes
- [ ] Texto del botón Guardar
- [ ] Mensaje de éxito al guardar
- [ ] Mensajes de error por claves API ausentes
- [ ] Todos los nombres de proveedores (cuando corresponda)

### Elementos comunes

- [ ] Indicadores de carga
- [ ] Mensajes de error
- [ ] Mensajes de éxito
- [ ] Etiquetas de botones (Guardar, Cancelar, Eliminar, etc.)

## Lista de verificación de pruebas

### Para cada idioma

- [ ] Generar código de localización: `flutter gen-l10n`
- [ ] Ejecutar la aplicación: `flutter run`
- [ ] Cambiar el idioma del dispositivo
- [ ] Navegar por todas las pantallas
- [ ] Comprobar que todo el texto está traducido
- [ ] Verificar que no aparece texto en inglés (excepto términos técnicos)
- [ ] Comprobar que el texto cabe en los elementos de la interfaz
- [ ] Verificar que los marcadores de posición funcionan correctamente
- [ ] Probar que los caracteres especiales se muestran correctamente
- [ ] Comprobar que el texto no desborda los contenedores

### Casos extremos

- [ ] Traducciones muy largas (p. ej., palabras compuestas en alemán)
- [ ] Traducciones muy cortas
- [ ] Caracteres especiales (é, ñ, ü, etc.)
- [ ] Subíndices/superíndices (CO₂)
- [ ] Números y marcadores de posición

## Pruebas de compilación

### Compilación de depuración

```bash
flutter build apk --debug
# or
flutter build ios --debug
```

Verificar que las traducciones funcionan en la aplicación compilada.

### Compilación de lanzamiento

```bash
flutter build apk --release
# or
flutter build ios --release
```

Asegurarse de que no se eliminan datos de traducción en el modo de lanzamiento.

## Herramientas de validación

### 1. Validación de archivos ARB

Validar la sintaxis JSON:

```bash
# Install jq if not already installed
# macOS: brew install jq
# Ubuntu: sudo apt-get install jq

# Validate ARB files
jq empty lib/l10n/app_en.arb
jq empty lib/l10n/app_es.arb
jq empty lib/l10n/app_fr.arb
jq empty lib/l10n/app_de.arb
```

### 2. Comprobar traducciones faltantes

Comparar recuentos de claves:

```bash
# Count keys in English (template)
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in other languages
grep -c '"[a-zA-Z]' lib/l10n/app_es.arb
grep -c '"[a-zA-Z]' lib/l10n/app_fr.arb
grep -c '"[a-zA-Z]' lib/l10n/app_de.arb
```

¡Todos deben coincidir!

### 3. Script para encontrar claves faltantes

Crear `scripts/check_translations.sh`:

```bash
#!/bin/bash

TEMPLATE="lib/l10n/app_en.arb"
TRANSLATIONS=(lib/l10n/app_*.arb)

for TRANS in "${TRANSLATIONS[@]}"; do
  if [ "$TRANS" != "$TEMPLATE" ]; then
    echo "Checking $TRANS..."
    TEMPLATE_KEYS=$(jq -r 'keys[]' "$TEMPLATE" | grep -v "^@")
    TRANS_KEYS=$(jq -r 'keys[]' "$TRANS" | grep -v "^@")
    
    echo "$TEMPLATE_KEYS" | while read key; do
      if ! echo "$TRANS_KEYS" | grep -q "^$key$"; then
        echo "  Missing: $key"
      fi
    done
  fi
done
```

Ejecutarlo:

```bash
chmod +x scripts/check_translations.sh
./scripts/check_translations.sh
```

## Problemas comunes y soluciones

### Problema: AppLocalizations not found

**Solución:** Ejecutar `flutter gen-l10n` y reiniciar el IDE

### Problema: La traducción no aparece

**Solución:**

1. Comprobar la sintaxis del archivo ARB
2. Verificar que la clave coincide exactamente (distingue mayúsculas de minúsculas)
3. Ejecutar `flutter gen-l10n`
4. Realizar un reinicio en caliente de la aplicación (no recarga en caliente)

### Problema: El marcador de posición no funciona

**Solución:**

1. Verificar la sintaxis del marcador de posición: `{variableName}`
2. Comprobar que el archivo ARB tiene la sección de marcadores de posición
3. Asegurarse de que el código pasa el parámetro correcto

### Problema: Desbordamiento de texto

**Solución:**

1. Usar widgets `Flexible` o `Expanded`
2. Activar el ajuste de texto: `overflow: TextOverflow.ellipsis`
3. Considerar abreviaciones en la traducción

### Problema: Los caracteres especiales se muestran como cuadros

**Solución:**

1. Asegurarse de que la fuente admite el conjunto de caracteres
2. Comprobar la configuración de fuentes en `pubspec.yaml`
3. Verificar que la codificación del archivo es UTF-8

## Pruebas automatizadas

### Pruebas de widgets

```dart
testWidgets('Welcome screen shows translated text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WelcomeScreen(),
    ),
  );
  
  expect(find.text('Bienvenido'), findsOneWidget);
});
```

### Pruebas de integración

```dart
testWidgets('Language switches correctly', (tester) async {
  // Test language switching functionality
});
```

## Pruebas de rendimiento

Verificar que la localización no afecta al rendimiento:

1. Ejecutar la aplicación en modo de perfil: `flutter run --profile`
2. Comprobar que las tasas de fotogramas se mantienen consistentes
3. Supervisar el uso de memoria
4. Probar en dispositivos de gama baja

## Pruebas de accesibilidad

Asegurarse de que las traducciones son accesibles:

- [ ] Los lectores de pantalla funcionan correctamente
- [ ] El escalado de texto funciona
- [ ] El modo de alto contraste funciona
- [ ] Las etiquetas semánticas están localizadas si es necesario

## Documentación

Documentar los resultados de las pruebas:

1. Crear un informe de pruebas para cada idioma
2. Anotar los problemas encontrados
3. Documentar soluciones alternativas o correcciones necesarias
4. Actualizar esta guía con nuevos hallazgos

## Integración continua

Añadir al pipeline de CI/CD:

```yaml
# .github/workflows/test.yml
- name: Validate ARB files
  run: |
    for file in lib/l10n/app_*.arb; do
      jq empty "$file" || exit 1
    done

- name: Generate localizations
  run: flutter gen-l10n

- name: Run tests
  run: flutter test
```

## Antes del lanzamiento

- [ ] Todos los archivos ARB validados
- [ ] Todas las traducciones completas
- [ ] Generación de código exitosa
- [ ] Aplicación probada en todos los idiomas admitidos
- [ ] Capturas de pantalla tomadas para cada idioma (para los listados de la tienda)
- [ ] Créditos de traducción actualizados en la sección Acerca de
- [ ] Las notas de lanzamiento mencionan los nuevos idiomas

## Recopilación de comentarios

Después del lanzamiento:

- Supervisar los comentarios de los usuarios sobre la calidad de la traducción
- Comprobar las analíticas de uso por idioma
- Crear issues para los problemas de traducción reportados
- Actualizar las traducciones según los comentarios recibidos

## Recursos

- [Documentación de internacionalización de Flutter](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Formato de archivo ARB](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification)
- [Guía de traducción](TRANSLATION_GUIDE.md)
- [Guía para desarrolladores](LOCALIZATION_DEV_GUIDE.md)

## Obtener ayuda

Si las pruebas fallan o encuentra problemas:

1. Consultar esta guía
2. Revisar la documentación de i18n de Flutter
3. Buscar en los issues existentes de GitHub
4. Crear un nuevo issue con:
   - Mensaje de error
   - Pasos para reproducir
   - Contenido del archivo ARB (si es relevante)
   - Información del dispositivo/emulador

¡Felices pruebas! 🧪
