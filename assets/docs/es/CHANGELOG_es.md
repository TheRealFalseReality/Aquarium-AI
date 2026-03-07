# Registro de cambios

Todos los cambios notables de este proyecto se documentan en este archivo.

## [3.1.03] - 2026-3-7 - UUID, principalmente comprobaciones de autorización, soporte de inicio de sesión de Facebook

### Cambió

### ***Tenga en cuenta:***
- **PUEDE que necesites restablecer tu almacenamiento para que se cargue un nuevo conjunto de datos. Agregué UUID a los tipos de peces para permitir mejores cambios en el futuro.**
- El resto son principalmente actualizaciones de backend.

**Registro de cambios completo**: https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.1.00...v3.1.03

## [3.1.00] - 2026-3-3 – Ventajas, funciones de comunidad y perfil

### Añadido

- **Sección de perfil de usuario con autenticación social**
- **Nivel Fundador Acuarista, imagen héroe moderna del Escaparate de Acuarios, sistema de ventajas para fundadores, correcciones de publicaciones de la comunidad**
- Familias de fuentes seleccionables por el usuario en la pantalla de apariencia
- Subtipo de acuario de arrecife para acuarios de agua salada con soporte de filtrado
- Clasificación de datos de peces y seguridad en arrecifes añadida
- Registro global de TankTag con soporte explícito de copia de seguridad/restauración
- Función de compartir/importar un solo acuario
- Pantalla de bienvenida: cuadrícula de 2 columnas con alternancia lista/cuadrícula + modo cuadrícula/mosaico de gestión de acuarios y personalización de tarjetas
- Foto de banner del acuario principal añadida a la pantalla de detalles del acuario
- Permite el cierre permanente del encabezado de la pantalla de bienvenida

### Modificado

- Chips de sugerencias del chatbot localizados, configuración de idioma de respuesta de IA añadida
- Localizados los idiomas de IA, calculadoras, pantallas de información y configuración del proveedor de IA
- Cadenas de texto codificadas de forma fija localizadas en ajustes, cajón, pantalla de bienvenida, diálogo de promoción de AquaPi, pantalla de historial y más

**Registro completo de cambios**: <https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.10...v3.1.00>

## [3.0.10] - 2026-2-27 – Actualizaciones visuales, correcciones de la herramienta Stocking

### Añadido

- Mejora del contraste visual en botones y chips de toda la aplicación
- Añadidos temas FlexColorScheme, selector de paleta AppColorTheme, pantalla de apariencia
  y selector de color personalizado

### Corregido

- Corregido el error por el que el popup de especies no reflejaba los nombres comunes
- Corregido el error de retroceso en la herramienta AI Stocking, mejorada la UX de
  selección de especies y el tamaño del acuario ahora es opcional

**Registro completo de cambios**:
<https://github.com/TheRealFalseReality/Aquarium-AI/compare/v3.0.03...v3.0.10>

## [3.0.03] - 2026-2-24 – Grandes actualizaciones

### Añadido

- **Clave API de Groq de desarrollador con limitación de velocidad; proveedor
  predeterminado → Groq**
  - **¡Funciones de AI gratuitas en la aplicación activadas!!** Son limitadas y pueden
    desactivarse en cualquier momento. Groq se usa por defecto; no es tan bueno como
    Gemini, pero funciona.
- **¡Invítame a un café!** Opción para eliminar anuncios por **0,99 USD** (por ahora).
  Son los *"Beneficios de Fundador"* para quienes apoyan el desarrollo.
- **Herramienta AI de información sobre peces añadida**, pantalla de resultados dedicada
  y chips de herramientas destacados en la tarjeta del chatbot AI
- Menú de compartir nativo para todos los resultados de análisis AI
- Colores de tema en toda la UI de la app con agrupación de secciones
- Registro de cambios en la app añadido a las pantallas de Configuración e Información
- Historial de análisis AI añadido: registro persistente con favoritos y reproducción
  completa de informes
- Diálogo de selección granular de especies añadido a la herramienta de compatibilidad
- Etiquetas de especies añadidas a los habitantes del acuario

### Modificado

- Pantallas de detalles y creación de acuarios convertidas a navegación por pestañas
- Descripciones de tarjetas en la pantalla de bienvenida mejoradas con detalles
  específicos de funciones
- Superposición de edición de habitantes rediseñada: selector de peces plegable,
  relleno superior, protección inteligente de nombres
- Reducido el consumo de tokens de AI en todos los proveedores
- Solucionado el crecimiento ilimitado de tokens en todos los proveedores de chat
- Manejo de errores de AI mejorado: diálogo moderno, accesos directos a claves API
  y reversión en caso de error por límite de velocidad

### Eliminado

- Eliminado "Incluir nombres personalizados" de los diálogos de informes AI

**Registro completo de cambios**:
<https://github.com/TheRealFalseReality/Aquarium-AI/compare/v2.1.04...v3.0.03>

## [Sin publicar]

### Por añadir

- Detalles específicos de peces, equipos y plantas con imágenes
- Mejor y más moderna UX/UI de parámetros y dosificación
- Métricas detalladas por acuario con métricas personalizadas (último cambio de agua,
  conteo de peces, nivel de algas?)
- Guías de poblamiento por acuario
- Notificaciones y registro de eventos en vista de calendario
- Gastos o P&G
- Compartir e importar acuarios con amigos
- Feed de exploración
- [**¡Sugiere más!**](https://github.com/TheRealFalseReality/Aquarium-AI/issues)
  Solicita una función o reporta un error

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
