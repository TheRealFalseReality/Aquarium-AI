# Referencia rápida de traducción

Esta es una referencia rápida para los escenarios de traducción más comunes en Aquarium AI.

## Convención de nomenclatura de archivos

| Idioma | Nombre de archivo | Código de configuración regional |
| ------ | ----------------- | -------------------------------- |
| Inglés | app_en.arb | en |
| Español | app_es.arb | es |
| Francés | app_fr.arb | fr |
| Alemán | app_de.arb | de |
| Japonés | app_ja.arb | ja |
| Chino (simplificado) | app_zh.arb | zh |
| Portugués | app_pt.arb | pt |
| Italiano | app_it.arb | it |
| Ruso | app_ru.arb | ru |
| Coreano | app_ko.arb | ko |
| Árabe | app_ar.arb | ar |
| Hindi | app_hi.arb | hi |
| Neerlandés | app_nl.arb | nl |

## Ejemplos de traducción

### Texto simple

```json
"welcomeTitle": "Welcome"
```

**Alemán**: `"welcomeTitle": "Willkommen"`
**Japonés**: `"welcomeTitle": "ようこそ"`
**Español**: `"welcomeTitle": "Bienvenido"`

### Texto con marcadores de posición

```json
"totalTanks": "Total: {count}"
```

**Alemán**: `"totalTanks": "Gesamt: {count}"`
**Japonés**: `"totalTanks": "合計: {count}"`
**Español**: `"totalTanks": "Total: {count}"`

**Nota**: ¡Mantén `{count}` sin cambios, es un marcador de posición!

### Caracteres especiales

```json
"aquariumCalculatorsDescription": "Essential tools for salinity, CO₂, alkalinity and more."
```

Conserva los caracteres especiales como `CO₂`, ya que son términos técnicos.

### Términos técnicos

Algunos términos deben permanecer en inglés o usar traducciones comúnmente aceptadas:

- API Key (generalmente se mantiene como está)
- AI (Artificial Intelligence)
- Nombres de modelos: Gemini, OpenAI, Groq

### Elementos de la interfaz de usuario

```json
"save": "Save",
"cancel": "Cancel",
"delete": "Delete"
```

Estos deben traducirse para que coincidan con el idioma nativo de la interfaz de la plataforma.

## Probar tu traducción

### 1. Validación de JSON

Usa <https://jsonlint.com/> para validar la sintaxis JSON.

### 2. Comprobación de completitud

Compara tu archivo ARB con `app_en.arb`:

```bash
# Count keys in English file
grep -c '"[a-zA-Z]' lib/l10n/app_en.arb

# Count keys in your translation
grep -c '"[a-zA-Z]' lib/l10n/app_XX.arb
```

¡Ambos deben tener el mismo número!

### 3. Comprobación de marcadores de posición

Busca todos los marcadores de posición en tu archivo:

```bash
grep '{' lib/l10n/app_XX.arb
```

Asegúrate de que todos los `{count}`, `{name}`, etc. estén presentes y sin cambios.

## Errores comunes que debes evitar

❌ **Incorrecto**: Traducir las claves

```json
"bienvenue": "Bienvenue"  // DON'T translate the key!
```

✅ **Correcto**: Traducir solo los valores

```json
"welcomeTitle": "Bienvenue"  // Only the value is translated
```

❌ **Incorrecto**: Eliminar los marcadores de posición

```json
"totalTanks": "Total: 5"  // Lost the {count} placeholder!
```

✅ **Correcto**: Conservar los marcadores de posición

```json
"totalTanks": "Total: {count}"
```

❌ **Incorrecto**: JSON no válido

```json
{
  "save": "Save"  // Missing comma
  "cancel": "Cancel"
}
```

✅ **Correcto**: JSON válido

```json
{
  "save": "Save",
  "cancel": "Cancel"
}
```

## ¿Necesitas ayuda?

1. Consulta la [Guía de traducción](TRANSLATION_GUIDE.md) completa
2. Mira las traducciones existentes: [Español](lib/l10n/app_es.arb) o [Francés](lib/l10n/app_fr.arb)
3. Usa el [archivo de plantilla](lib/l10n_template.arb)
4. Abre un issue en GitHub si estás atascado

## Pasos de inicio rápido

1. Copia `lib/l10n_template.arb` a `lib/l10n/app_XX.arb`
2. Cambia `@@locale` al código de tu idioma
3. Reemplaza todos los textos "TRANSLATE: " con tus traducciones
4. Valida el JSON en <https://jsonlint.com/>
5. Actualiza `lib/main.dart` para añadir tu configuración regional a `supportedLocales`
6. ¡Envía un Pull Request!

¡Gracias por tu contribución! 🌍
