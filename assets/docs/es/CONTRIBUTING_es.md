# Contribuir a Aquarium AI

¡Gracias por tu interés en contribuir a Aquarium AI! Este documento proporciona pautas para contribuir al proyecto.

## Formas de Contribuir

### 🌍 Traducciones (¡Sin necesidad de programar!)

Una de las formas más fáciles e impactantes de contribuir es traducir la app a tu idioma. Consulta nuestra [Guía de Traducción](TRANSLATION_GUIDE.md) para obtener instrucciones detalladas.

**Inicio rápido para traducciones:**

1. Consulta la [Referencia Rápida de Traducción](TRANSLATION_QUICK_REF.md)
2. Copia el [archivo de plantilla](lib/l10n_template.arb)
3. Traduce las cadenas a tu idioma
4. Envía un pull request o abre un issue con tu traducción

### 🐛 Informes de Errores

¿Encontraste un error? Ayúdanos a solucionarlo:

1. Comprueba si el error ya ha sido reportado en [Issues](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. Si no, crea un nuevo issue con:
   - Descripción clara del error
   - Pasos para reproducirlo
   - Comportamiento esperado vs. comportamiento real
   - Capturas de pantalla si corresponde
   - Información del dispositivo/plataforma

### 💡 Solicitudes de Funciones

¿Tienes una idea para una nueva función?

1. Revisa las [solicitudes de funciones existentes](https://github.com/TheRealFalseReality/Aquarium-AI/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
2. Si es nueva, crea un issue describiendo:
   - El problema que tu función resolvería
   - Cómo imaginas que funcionaría la función
   - Ejemplos de otras aplicaciones

### 💻 Contribuciones de Código

¿Quieres contribuir con código? ¡Genial!

**Antes de empezar:**

1. Revisa los [issues abiertos](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
2. Comenta en el issue en el que quieres trabajar
3. Espera aprobación para evitar trabajo duplicado

**Configuración del entorno de desarrollo:**

1. Haz un fork del repositorio
2. Clona tu fork: `git clone https://github.com/YOUR_USERNAME/Aquarium-AI.git`
3. Crea una rama: `git checkout -b feature/your-feature-name`
4. Realiza tus cambios
5. Prueba tus cambios a fondo
6. Haz commit con mensajes claros: `git commit -m "Add feature: description"`
7. Sube a tu fork: `git push origin feature/your-feature-name`
8. Crea un Pull Request

**Pautas de código:**

- Sigue el estilo de código existente
- Escribe mensajes de commit claros y descriptivos
- Agrega comentarios para la lógica compleja
- Actualiza la documentación si es necesario
- Prueba tus cambios en múltiples plataformas si es posible

### 📖 Documentación

Ayuda a mejorar nuestra documentación:

- Corregir errores tipográficos o instrucciones poco claras
- Agregar ejemplos
- Traducir documentación
- Escribir tutoriales o guías

## Proceso de Pull Request

1. **Actualizar la documentación**: Si tu cambio afecta funciones visibles para el usuario, actualiza los documentos relevantes
2. **Seguir las convenciones**: Mantén el estilo y la estructura de código existentes
3. **Probar exhaustivamente**: Asegúrate de que tus cambios funcionen según lo esperado
4. **PRs pequeños**: Mantén los pull requests enfocados en una sola función/corrección
5. **Describir tus cambios**: Escribe una descripción clara de qué y por qué

## Pautas Específicas de Traducción

### Estructura de Archivos

```text
├── app_en.arb    (English - template, always complete)
├── app_es.arb    (Spanish)
├── app_fr.arb    (French)
├── app_de.arb    (German)
└── app_XX.arb    (Your language)
```

### Agregar un Nuevo Idioma

1. Crea `lib/l10n/app_XX.arb` (XX = código de idioma)
2. Traduce todas las cadenas de `app_en.arb`
3. Actualiza `lib/main.dart`:

   ```dart
   supportedLocales: const [
     Locale('en'),
     Locale('XX'), // Add your language here
   ],
   ```

4. Prueba cambiando el idioma de tu dispositivo
5. Envía un PR

### Actualizar Traducciones Existentes

1. Revisa `app_en.arb` para nuevas cadenas
2. Agrega las traducciones faltantes a tu archivo de idioma
3. Envía un PR con las actualizaciones

## Pautas de la Comunidad

- **Sé respetuoso**: Trata a todos con respeto y amabilidad
- **Sé paciente**: Recuerda que todos están aprendiendo
- **Sé útil**: Ayuda a los demás cuando puedas
- **Mantente en el tema**: Mantén las discusiones enfocadas en Aquarium AI

## ¿Preguntas?

- **Preguntas generales**: Abre una [Discusión](https://github.com/TheRealFalseReality/Aquarium-AI/discussions)
- **Informes de errores**: Abre un [Issue](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
- **Ayuda con traducciones**: Consulta la [Guía de Traducción](TRANSLATION_GUIDE.md)

## Reconocimiento

Todos los contribuidores son reconocidos en:

- La sección Acerca de la app
- Página de contribuidores de GitHub
- Notas de la versión (para contribuciones significativas)

## Licencia

Al contribuir, aceptas que tus contribuciones serán licenciadas bajo la misma licencia que el proyecto (Licencia MIT).

## ¿Primera vez contribuyendo?

¡Bienvenido! Aquí hay algunos buenos primeros issues:

- Traducir a un nuevo idioma
- Corregir errores tipográficos en la documentación
- Agregar ejemplos a las guías
- Issues etiquetados como "good first issue"

¡Gracias por hacer que Aquarium AI sea mejor para todos! 🐠
