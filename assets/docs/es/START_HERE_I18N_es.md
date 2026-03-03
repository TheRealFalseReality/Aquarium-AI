# 🌍 Aquarium AI - Ahora Habla Tu Idioma

¡Aquarium AI ahora es traducible! Esto significa que cualquier persona en el mundo puede usar la app en su idioma nativo, y **tú puedes ayudar** - ¡sin necesidad de conocimientos de programación!

## 🎯 Enlaces Rápidos

### Para Traductores (¡Sin Necesidad de Programar!)

- **Comienza Aquí**: [Guía de Traducción](TRANSLATION_GUIDE.md) - Guía completa paso a paso
- **Inicio Rápido**: [Referencia Rápida](TRANSLATION_QUICK_REF.md) - Consejos rápidos y ejemplos
- **¿Necesitas Ayuda?**: [Guía de Contribución](CONTRIBUTING.md) - Toda la información que necesitas

### Para Desarrolladores

- **Usar i18n en el Código**: [Guía del Desarrollador](LOCALIZATION_DEV_GUIDE.md)
- **Pruebas**: [Guía de Pruebas](TESTING_I18N.md)
- **Detalles de Implementación**: [Resumen de Implementación](I18N_IMPLEMENTATION.md)

## 🌐 Idiomas Actualmente Soportados

| Bandera | Idioma | Estado | ¿Se Necesitan Colaboradores? |
| ------- | ------ | ------ | ----------------------------- |
| 🇬🇧 | Inglés | ✅ Completo | - |
| 🇪🇸 | Español | ✅ Completo | Mejoras bienvenidas |
| 🇫🇷 | Francés (Français) | ✅ Completo | Mejoras bienvenidas |
| 🇩🇪 | Alemán (Deutsch) | ✅ Completo | Mejoras bienvenidas |
| 🇵🇹 | Portugués | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇮🇹 | Italiano | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇯🇵 | Japonés | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇨🇳 | Chino | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇷🇺 | Ruso | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇰🇷 | Coreano | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇳🇱 | Neerlandés | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇸🇦 | Árabe | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |
| 🇮🇳 | Hindi | 🆕 Necesario | **¡Sí! ¡Ayúdanos!** |

¿Quieres agregar tu idioma? **¡Es más fácil de lo que piensas!**

## ⚡ Inicio Súper Rápido (¡5 Pasos!)

### Para Traductores

1. **Copia la plantilla**

   ```bash
   # En la carpeta del proyecto
   cp lib/l10n_template.arb lib/l10n/app_XX.arb
   # (Reemplaza XX con tu código de idioma, ej. app_pt.arb para Portugués)
   ```

2. **Edita el archivo**
   - Cambia `"@@locale": "CHANGE_THIS"` a tu código de idioma (ej. `"pt"`)
   - Reemplaza todos los textos "TRANSLATE: " con tus traducciones
   - Mantén los `{placeholders}` exactamente como están

3. **Valida**

   ```bash
   ./scripts/validate_translations.sh
   ```

4. **Actualiza main.dart** (¡o pregunta en el PR, podemos ayudar!)
   Agrega tu locale a la lista en `lib/main.dart`

5. **¡Envía!**
   Crea un Pull Request con tu traducción

**¡Eso es todo!** ¡Has hecho que Aquarium AI sea accesible para millones de personas más! 🎉

### Para Desarrolladores

1. **Agregar localización a un widget**

   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';

   // En el método build:
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.welcomeTitle) // Muestra texto localizado
   ```

2. **Configuración Inicial** (después de obtener los cambios):

   ```bash
   flutter pub get        # Install dependencies
   flutter gen-l10n       # Generate localization files
   ```

   **Nota**: `flutter gen-l10n` también se ejecuta automáticamente cuando haces `flutter run` o `flutter build`.

3. **Agregar nuevas cadenas**
   - Agrégalas a `lib/l10n/app_en.arb` con descripción
   - Ejecuta `flutter gen-l10n`
   - Actualiza otros archivos de idioma
   - ¡Úsalas en el código!

## 🔧 Solución de Problemas

### Errores de "Paquete no encontrado"

Si ves errores como:

- `'package:flutter_localizations/flutter_localizations.dart' not found`
- `'package:flutter_gen/gen_l10n/app_localizations.dart' not found`

**Solución:**

```bash
flutter pub get        # Install dependencies
flutter gen-l10n       # Generate localization files
```

Luego reinicia tu IDE/editor. Los archivos generados están en `.dart_tool/flutter_gen/gen_l10n/` y se crean automáticamente - no están en Git.

## 📊 Qué Está Incluido

Esta implementación proporciona:

### Infraestructura

- ✅ Sistema i18n oficial de Flutter
- ✅ Acceso a cadenas con seguridad de tipos
- ✅ Soporte para marcadores de posición
- ✅ Formato de archivo ARB profesional

### Documentación (Elige lo que necesitas)

- **Traductores**: [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md) + [Referencia Rápida](TRANSLATION_QUICK_REF.md)
- **Desarrolladores**: [LOCALIZATION_DEV_GUIDE.md](LOCALIZATION_DEV_GUIDE.md)
- **Probadores**: [TESTING_I18N.md](TESTING_I18N.md)
- **Todos**: [CONTRIBUTING.md](CONTRIBUTING.md)

### Herramientas

- Script de validación (verifica tus traducciones automáticamente)
- GitHub Actions (validación automática en PRs)
- Archivo de plantilla (inicio rápido para nuevos idiomas)

## 🎓 Ejemplo: Agregar Portugués en 10 Minutos

Veamos cómo agregar Portugués:

```bash
# 1. Copiar plantilla
cp lib/l10n_template.arb lib/l10n/app_pt.arb

# 2. Editar app_pt.arb - cambiar la primera línea:
"@@locale": "pt",

# 3. Traducir (ejemplo):
"welcomeTitle": "Bem-vindo",
"myTanks": "Meus Aquários",
"settings": "Configurações",
# ... y así sucesivamente

# 4. Validar
./scripts/validate_translations.sh

# 5. Probar (si tienes Flutter)
flutter gen-l10n
flutter run
# Cambiar el idioma del dispositivo a Portugués
```

¡Listo! ¡Envía un PR y conviértete en colaborador! 🌟

## 🤔 Preguntas Frecuentes

### P: No sé programar. ¿Puedo ayudar de todas formas?

**R:** ¡Absolutamente! La traducción requiere **cero conocimientos de programación**. ¡Si puedes editar un archivo de texto, puedes traducir!

### P: ¿Cuánto tiempo lleva?

**R:** Primera traducción: 1-2 horas. Actualizaciones: 5-10 minutos.

### P: ¿Qué pasa si cometo un error?

**R:** ¡No te preocupes! Nuestro script de validación detecta errores comunes. Revisamos todos los PRs y podemos ayudar a solucionar problemas.

### P: Solo conozco algo del idioma. ¿Puedo ayudar?

**R:** ¡Sí! Las traducciones parciales son mejores que ninguna. Alguien más puede completarlas después.

### P: ¿Recibiré crédito?

**R:** ¡Absolutamente! Todos los colaboradores aparecen en la sección Acerca de la app y en GitHub.

### P: ¿Qué herramientas necesito?

**R:** ¡Solo un editor de texto! VS Code, Notepad++, Sublime Text, o incluso el Bloc de notas funcionan bien.

## 🏆 ¿Por Qué Traducir?

### Impacto

- Ayuda a **millones** de entusiastas de los acuarios en todo el mundo
- Hace el hobby más accesible en tu idioma
- Preserva el conocimiento acuático en múltiples idiomas

### Reconocimiento

- Tu nombre en los créditos de la app
- Insignia de colaborador en GitHub
- Reconocimiento en las notas de versión
- Construye tu portafolio de código abierto

### Comunidad

- Únete a una comunidad global de amantes de los acuarios
- Ayuda a mejorar la app para todos
- Aprende sobre contribución a proyectos de código abierto

## 📞 Obtener Ayuda

¿Atascado? ¿Preguntas? ¡Estamos aquí para ayudar!

1. **Lee la documentación**: La mayoría de las respuestas están en [TRANSLATION_GUIDE.md](TRANSLATION_GUIDE.md)
2. **Revisa ejemplos**: Mira las traducciones existentes (Español, Francés, Alemán)
3. **Haz preguntas**: Abre un issue de GitHub con la etiqueta "translation"
4. **Únete a las discusiones**: Pestaña de GitHub Discussions

## 🙏 Gracias

¡Cada traducción hace que Aquarium AI sea mejor para todos! Ya sea que traduzcas una sola cadena o un idioma completo, ¡tu contribución importa!

**¿Listo para empezar?** ¡Elige una guía arriba y sumérgete! 🐠

---

### Referencia de Estructura de Directorios

```text
Aquarium-AI/
├── lib/
│   └── l10n/                    # Translation files here!
│       ├── app_en.arb          # English (template)
│       ├── app_es.arb          # Spanish
│       ├── app_fr.arb          # French
│       ├── app_de.arb          # German
│       └── README.md           # L10n guide
├── lib/l10n_template.arb        # Template file (copy to lib/l10n/app_XX.arb)
├── TRANSLATION_GUIDE.md         # START HERE for translators
├── TRANSLATION_QUICK_REF.md     # Quick tips
├── LOCALIZATION_DEV_GUIDE.md    # For developers
├── CONTRIBUTING.md              # General contribution info
└── scripts/
    └── validate_translations.sh # Test your translation
```

---

Hecho con ❤️ por la comunidad de Aquarium AI
