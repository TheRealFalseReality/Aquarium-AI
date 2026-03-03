# Guía de traducción para Aquarium AI

¡Gracias por tu interés en traducir Aquarium AI! Esta guía te ayudará a contribuir con traducciones para que la app sea accesible a usuarios de todo el mundo.

## Descripción general

Aquarium AI utiliza el sistema de internacionalización (i18n) integrado de Flutter con archivos ARB (Application Resource Bundle). Cada idioma tiene su propio archivo ARB que contiene todas las cadenas de texto traducibles.

## Primeros pasos

### Requisitos previos

- Conocimientos básicos del formato JSON
- Familiaridad con el idioma de destino
- Un editor de texto (VS Code, Sublime Text o cualquier editor que prefieras)

### Estructura de archivos

Los archivos de traducción se encuentran en:

```text
lib/l10n/
├── app_en.arb    (English - template)
├── app_es.arb    (Spanish - example)
├── app_fr.arb    (French - example)
└── app_XX.arb    (Your language)
```

## Cómo añadir un nuevo idioma

### Paso 1: Crear tu archivo ARB

1. Copia el archivo `app_en.arb`
2. Renómbralo como `app_XX.arb`, donde `XX` es el código de tu idioma (p. ej., `app_de.arb` para alemán, `app_ja.arb` para japonés)
3. Actualiza el valor `@@locale` con el código de tu idioma

**Códigos de idioma comunes:**

- `de` - Alemán
- `ja` - Japonés
- `zh` - Chino (simplificado)
- `pt` - Portugués
- `it` - Italiano
- `ru` - Ruso
- `ko` - Coreano
- `ar` - Árabe
- `hi` - Hindi
- `nl` - Neerlandés

Encuentra más códigos de idioma aquí: <https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes>

### Paso 2: Traducir las cadenas de texto

Traduce el valor de cada cadena (pero NO las claves). Aquí tienes un ejemplo:

**Inglés (app_en.arb):**

```json
{
  "@@locale": "en",
  "welcomeTitle": "Welcome",
  "myTanks": "My Tanks"
}
```

**Alemán (app_de.arb):**

```json
{
  "@@locale": "de",
  "welcomeTitle": "Willkommen",
  "myTanks": "Meine Aquarien"
}
```

### Paso 3: Gestionar los marcadores de posición

Algunas cadenas contienen marcadores de posición como `{count}`. Mantén estos marcadores sin cambios:

**Inglés:**

```json
"totalTanks": "Total: {count}"
```

**Alemán:**

```json
"totalTanks": "Gesamt: {count}"
```

### Paso 4: Conservar los caracteres especiales

Mantén los caracteres especiales y el formato:

- Emojis: 🐠, 🤖, 📷, etc.
- Símbolos especiales: CO₂, ₂, etc.
- Entidades HTML y secuencias de escape

### Paso 5: Actualizar main.dart

Después de crear tu archivo ARB, añade tu idioma a la lista `supportedLocales` en `lib/main.dart`:

```dart
supportedLocales: const [
  Locale('en'), // English
  Locale('es'), // Spanish
  Locale('fr'), // French
  Locale('de'), // German (your new language)
],
```

## Consejos de traducción

### 1. El contexto importa

- Lee los campos `@description` del archivo ARB en inglés para obtener contexto
- Si no estás seguro, comprueba dónde se usa la cadena en la app

### 2. Mantener la coherencia

- Usa una terminología coherente en todo el texto
- Mantén un tono profesional pero cercano
- Adapta tu estilo a las traducciones existentes

### 3. Adaptación cultural

- Adapta modismos y expresiones a tu cultura
- Ten en cuenta las diferencias regionales de tu idioma

### 4. Términos técnicos

Algunos términos técnicos deben mantenerse en inglés o usar traducciones comúnmente aceptadas:

- API Key
- AI (Artificial Intelligence)
- Nombres de modelos (Gemini, OpenAI, Groq)
- Tank (terminología de acuario)

### 5. Consideraciones de longitud

- Intenta que las traducciones tengan una longitud similar al original
- Las traducciones muy largas pueden no caber en la interfaz de usuario
- Si es necesario, usa abreviaturas habituales en tu idioma

## Probar tu traducción

Aunque no es necesario que compiles y pruebes la app tú mismo, aquí te indicamos cómo verificar tu trabajo:

1. **Verificar la sintaxis JSON**: Usa un validador JSON (<https://jsonlint.com/>)
2. **Comprobar la completitud**: Asegúrate de que todas las claves de `app_en.arb` estén traducidas
3. **Verificar los marcadores**: Comprueba que los marcadores como `{count}` se hayan conservado

## Referencia de la estructura del archivo ARB

Cada archivo ARB contiene:

1. **Identificador de configuración regional:**

   ```json
   "@@locale": "en"
   ```

2. **Clave y valor de traducción:**

   ```json
   "welcomeTitle": "Welcome"
   ```

3. **Metadatos (opcional, de la plantilla):**

   ```json
   "@welcomeTitle": {
     "description": "Title for the welcome screen"
   }
   ```

**Importante:** Solo traduce los valores (lado derecho), nunca las claves (lado izquierdo).

## Enviar tu traducción

### Mediante Pull Request (recomendado)

1. Haz un fork del repositorio
2. Crea una nueva rama: `git checkout -b translation/your-language`
3. Añade tu archivo ARB a `lib/l10n/`
4. Actualiza `lib/main.dart` para incluir tu configuración regional
5. Confirma tus cambios: `git commit -m "Add [Language] translation"`
6. Envía a tu fork: `git push origin translation/your-language`
7. Crea un Pull Request en GitHub

### Mediante Issue

Si no estás familiarizado con Git:

1. Crea un nuevo issue en GitHub
2. Título: "Translation: [Your Language]"
3. Adjunta tu archivo ARB completado
4. ¡Nosotros lo integraremos por ti!

## Lista de verificación de traducción

Antes de enviar, comprueba:

- [ ] El archivo ARB tiene el nombre correcto (`app_XX.arb`)
- [ ] El valor `@@locale` coincide con el nombre del archivo
- [ ] Se incluyen todas las cadenas de `app_en.arb`
- [ ] Los marcadores de posición se han conservado (p. ej., `{count}`)
- [ ] Los caracteres especiales se mantienen
- [ ] La sintaxis JSON es válida
- [ ] El idioma se ha añadido a `supportedLocales` en `main.dart`

## ¿Necesitas ayuda?

- **¿Preguntas?** Abre un issue en GitHub con la etiqueta "translation"
- **¿No estás seguro de una cadena?** Pregunta en el issue antes de traducir
- **¿Encontraste un error?** Repórtalo o envía una corrección

## Idiomas de ejemplo

Consulta estos ejemplos como referencia:

- Inglés: `lib/l10n/app_en.arb` (plantilla)
- Español: `lib/l10n/app_es.arb`
- Francés: `lib/l10n/app_fr.arb`

## Créditos

Todos los traductores serán mencionados en la sección Acerca de la app y en el README. ¡Gracias por hacer que Aquarium AI sea accesible para más personas!

## Estado de cobertura de idiomas

| Idioma | Código | Estado | Traductor |
| ------ | ------ | ------ | --------- |
| Inglés | en | ✅ Completo | Nativo |
| Español | es | ✅ Completo | Comunidad |
| Francés | fr | ✅ Completo | Comunidad |
| Alemán | de | ✅ Completo | Comunidad |
| Japonés | ja | 🔄 Necesario | - |
| Chino | zh | 🔄 Necesario | - |
| Portugués | pt | 🔄 Necesario | - |

¿Quieres añadir tu idioma? ¡Sigue esta guía y envía un PR!

## Avanzado: Añadir más cadenas de texto

A medida que la app evoluciona, se pueden añadir nuevas cadenas a `app_en.arb`. Para actualizar tu traducción:

1. Obtén los últimos cambios del repositorio principal
2. Comprueba si se añadieron nuevas cadenas a `app_en.arb`
3. Añade las traducciones de las nuevas cadenas a tu archivo ARB
4. Envía un PR de actualización

## Gracias

Tu contribución ayuda a los aficionados a la acuariofilia de todo el mundo a usar esta app en su idioma nativo. ¡Cada traducción marca la diferencia! 🌍🐠
