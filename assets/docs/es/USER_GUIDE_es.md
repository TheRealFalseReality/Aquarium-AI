# Aquarium AI – Guía del usuario

¡Bienvenido a **Aquarium AI**! Esta guía explica todas las herramientas de la aplicación
y cómo sacarles el máximo partido.

---

## Tabla de contenidos

1. [Primeros pasos – Claves API de AI](#primeros-pasos--claves-api-de-ai)
2. [Gestión de acuarios](#gestión-de-acuarios)
3. [Herramienta de compatibilidad AI](#herramienta-de-compatibilidad-ai)
4. [Chatbot AI](#chatbot-ai)
5. [Analizador de fotos](#analizador-de-fotos)
6. [Análisis de parámetros del agua](#análisis-de-parámetros-del-agua)
7. [Búsqueda de información de peces](#búsqueda-de-información-de-peces)
8. [Generador de scripts de automatización](#generador-de-scripts-de-automatización)
9. [Asistente de población AI](#asistente-de-población-ai)
10. [Calculadoras de acuario](#calculadoras-de-acuario)
11. [Registro de parámetros](#registro-de-parámetros)
12. [Registro de dosificación](#registro-de-dosificación)
13. [Historial de análisis](#historial-de-análisis)
14. [Comunidad](#comunidad)
15. [Configuración y apariencia](#configuración-y-apariencia)

---

## Primeros pasos – Claves API de AI

La mayoría de las herramientas con IA requieren una clave API de un proveedor
compatible.

**Nivel gratuito (sin clave requerida):**

Aquarium AI incluye un nivel gratuito limitado impulsado por una clave de desarrollador
integrada. Este nivel admite un pequeño número de solicitudes por día con una ventana
de historial de chat más corta. Puede reducirse o desactivarse en cualquier momento.

**Usa tu propia clave (recomendado):**

Para acceso ilimitado, añade tu propia clave API en **Configuración → Claves API de AI**.
Proveedores compatibles:

| Proveedor | Dónde obtener una clave |
| --------- | ----------------------- |
| **Groq** (predeterminado) | [console.groq.com](https://console.groq.com) |
| **Google Gemini** | [aistudio.google.com](https://aistudio.google.com) |
| **OpenAI (ChatGPT)** | [platform.openai.com](https://platform.openai.com) |

Puedes cambiar el proveedor de AI activo en cualquier momento en
**Configuración → Proveedor de AI**.

---

## Gestión de acuarios

**Ruta:** Menú principal → *Gestión de acuarios*

La gestión de acuarios es el centro principal para realizar un seguimiento de tus
acuarios.

### Crear un acuario

1. Toca el botón **+** (abajo a la derecha).
2. Rellena el **Nombre**, **Tipo** (Agua dulce / Marina) y **Volumen** (galones o litros).
3. Opcionalmente añade una **Descripción**, indicador apto para arrecife, y una **foto**
   o **imagen de banner**.
4. Toca **Guardar**.

### Tarjetas de acuario

Cada tarjeta muestra:

- Foto / imagen de banner del acuario
- Nombre, tipo y volumen
- Recuento de habitantes y puntuación de armonía
- Botones de acción rápida (Añadir habitante, Registro de parámetros, Registro de
  dosificación, Análisis AI)
- Herramientas del menú de la tarjeta, incluida la **Calculadora de volumen de cambio de agua** (por defecto al 20 % y con porcentaje ajustable para ver galones/litros a reemplazar)

### Ordenar y filtrar

Usa el botón de **ordenar / filtrar** (arriba a la derecha) para ordenar los acuarios
por nombre, tipo, tamaño o fecha, y filtrar por tipo de acuario o etiquetas.

### Etiquetas de acuario

Asigna **etiquetas** de colores a los acuarios para una fácil agrupación. Toca un chip
de etiqueta para filtrar la lista. Gestiona tu biblioteca de etiquetas global en
**Configuración → Etiquetas de especies**.

### Detalles del acuario

Toca cualquier tarjeta de acuario para abrir sus detalles, organizados en pestañas:

- **Resumen** – editar información del acuario, ver puntuación de armonía
- **Habitantes** – gestionar peces y otros residentes
- **Parámetros** – registro y gráficos de parámetros del agua
- **Dosificación** – registro de tratamientos / suplementos
- **Actividad** – eventos recientes

Si un habitante fallece, abre su pantalla de detalles y usa
**Registrar fallecimiento** para moverlo a la lista conmemorativa del acuario
sin perder su foto, notas ni fechas.

### Herramientas AI desde un acuario

Desde una tarjeta de acuario o su pantalla de detalles puedes lanzar herramientas AI
precargadas con los datos de tu acuario:

- **Verificación de compatibilidad AI** – analizar todos los habitantes actuales
- **Recomendaciones de población** – obtener sugerencias AI para nuevas adiciones
- **Análisis de fotos** – analizar una foto del acuario

### Copia de seguridad y restauración

Usa **Configuración → Copia de seguridad / Restauración** para exportar e importar todos los datos del acuario.

#### Copia de seguridad y restauración local

Guarda un archivo de copia de seguridad JSON completo en tu dispositivo y restáuralo en cualquier dispositivo.

#### Copia de seguridad y restauración en la nube *(Acuarista Fundador en móvil/escritorio; todos los usuarios en web)*

Guarda tus datos de forma segura en la nube, vinculados a tu cuenta. Requiere inicio de sesión. En móvil/escritorio requiere estado de **Acuarista Fundador**; en web está disponible para todos los usuarios con sesión iniciada. Restaura desde la nube en cualquier momento — ideal para cambiar de dispositivo sin gestionar archivos.

---

## Herramienta de compatibilidad AI

**Ruta:** Menú principal → *Herramienta de compatibilidad AI*
**Requiere:** Clave API o nivel gratuito

La herramienta de compatibilidad te permite seleccionar especies de una base de datos
de más de 69 especies de agua dulce y marina y generar un informe AI detallado.

### Cómo usar

1. Elige la pestaña **Agua dulce** o **Marina**.
2. Navega o **busca** en la lista de peces. Usa el filtro apto para arrecife para
   acuarios marinos.
3. **Toca las tarjetas de peces** para seleccionar las especies que quieres verificar
   juntas (las tarjetas seleccionadas muestran una marca de verificación).
4. Toca **Verificar compatibilidad** para generar el informe AI.

### Leer el informe

El informe incluye:

- **Valoración general de compatibilidad** con puntuación de armonía
- **Notas de cuidado por especie** (pH, temperatura, agresividad)
- **Advertencias de conflictos potenciales**
- **Tamaño de acuario recomendado** para el grupo seleccionado

---

## Chatbot AI

**Ruta:** Menú principal → *Chatbot AI*
**Requiere:** Clave API o nivel gratuito

El Chatbot es un asistente de acuario de propósito general. Pregunta cualquier cosa
sobre el cuidado de peces, química del agua, identificación de enfermedades,
equipamiento y más.

### Chips de herramientas AI integrados

En la parte superior de la pantalla de chat encontrarás chips de inicio rápido para
herramientas AI especializadas:

- **Analizador de fotos** – lanzar sin salir del chat
- **Análisis de parámetros del agua**
- **Info de peces**
- **Generador de scripts de automatización**

### Consejos de chat

- Las conversaciones ahora se conservan entre sesiones de la app.
- Usa el menú **Conversaciones** en la parte superior derecha para crear
  conversaciones con nombre.
- Puedes asignar opcionalmente cada conversación a un acuario específico y luego
  filtrarla y cargarla desde el gestor de conversaciones.
- Toca el icono de **compartir** en cualquier respuesta para compartir o copiar el texto.
- Crea una **nueva conversación** desde el menú cuando quieras empezar de cero.

---

## Analizador de fotos

**Ruta:** Chatbot AI → *Chip Analizador de fotos* o Menú principal → *Analizador de
fotos*

**Requiere:** Clave API o nivel gratuito (Gemini u OpenAI para mejores resultados)

Analiza fotos de acuarios para identificar peces, detectar enfermedades, evaluar la
claridad del agua y obtener recomendaciones.

### Cómo usar

1. Toca **Elegir de galería** o **Tomar foto**.
2. (Opcional) Añade una nota describiendo lo que buscas (p.ej. "¿Es esto ich?").
3. Toca **Analizar foto**.
4. La pantalla de resultados muestra los hallazgos de la IA con acciones sugeridas.

---

## Análisis de parámetros del agua

**Ruta:** Chatbot AI → *Chip Análisis de parámetros del agua*
**Requiere:** Clave API o nivel gratuito

Introduce tus parámetros del agua actuales y recibe una interpretación AI con consejos
específicos.

### Entradas

- **Tipo de acuario** (agua dulce / marina)
- **pH**
- **Temperatura** (°F o °C)
- **Salinidad / Gravedad específica** (solo marina)
- **Notas adicionales** (amoniaco, nitrito, nitrato, KH, etc.)

La IA marcará los valores fuera de rangos saludables y sugerirá acciones correctivas.

---

## Búsqueda de información de peces

**Ruta:** Chatbot AI → *Chip Info de peces*
**Requiere:** Clave API o nivel gratuito

Obtén una hoja de cuidados completa para cualquier especie de peces.

### Cómo usar

1. Introduce uno o más nombres de especies (comunes o científicos).
2. Opcionalmente introduce el tamaño de tu acuario para consejos apropiados al tamaño.
3. Toca **Obtener info**.

El resultado incluye:

- Nombres comunes y científicos
- Hábitat natural y origen
- Requisitos de temperatura, pH y dureza del agua
- Notas sobre dieta y alimentación
- Compañeros de acuario compatibles
- Curiosidades

---

## Generador de scripts de automatización

**Ruta:** Chatbot AI → *Chip Script de automatización*
**Requiere:** Clave API o nivel gratuito

Genera scripts de automatización para controladores de acuario (p.ej. Apex, GHL,
Hydros).

### Cómo usar

1. Describe la automatización que necesitas en lenguaje natural (p.ej. "Encender la
   bomba de sump a las 8 AM, apagar a las 10 PM y activar alarma si el pH baja de
   7,8").
2. Toca **Generar script**.
3. El resultado muestra un script listo para usar con comentarios explicativos.

---

## Asistente de población AI

**Ruta:** Menú principal → *Asistente de población AI*
**Requiere:** Clave API o nivel gratuito

Obtén recomendaciones de población personalizadas para un acuario nuevo o existente.

### Cómo usar

1. Selecciona **Agua dulce** o **Marina**.
2. Introduce el **tamaño de tu acuario** (opcional pero mejora la precisión).
3. (Opcional) Selecciona los peces que ya tienes o quieres usando el
   **selector de especies**.
4. Añade cualquier nota adicional (preferencia de biotopo, nivel de experiencia, etc.).
5. Toca **Obtener recomendaciones**.

El informe lista especies adecuadas con una breve nota de cuidado para cada una, más
orientación sobre densidad de población.

---

## Calculadoras de acuario

**Ruta:** Menú principal → *Calculadoras*

Un conjunto de calculadoras instantáneas sin conexión — no se necesita clave API.

| Calculadora | Qué hace |
| ----------- | -------- |
| **Salinidad** | Convierte entre PPT, PSU y gravedad específica |
| **CO₂** | Estima CO₂ disuelto a partir del pH y KH |
| **Alcalinidad** | Convierte entre dKH, meq/L y ppm |
| **Temperatura** | Convierte entre °F y °C |

### Calculadora de volumen de acuario

**Ruta:** Menú principal → *Calculadora de volumen de acuario*

Calcula el volumen de agua de acuarios rectangulares, cilíndricos o hexagonales
usando dimensiones internas.

---

## Registro de parámetros

**Ruta:** Detalles del acuario → pestaña *Parámetros*

(También accesible desde el botón de acción rápida de la tarjeta del acuario)

Rastrea la calidad del agua a lo largo del tiempo con gráficos y registros.

### Registrar una lectura

1. Toca **+ Añadir parámetro**.
2. Selecciona el tipo de parámetro (pH, Amoniaco, Nitrito, Nitrato, Temperatura,
   Salinidad, KH, etc.) o introduce un nombre personalizado.
3. Introduce el valor y la unidad.
4. Toca **Guardar**.

### Gráficos

Toca la flecha de **expandir** en un grupo de parámetros para ver un gráfico de serie
temporal. Útil para detectar tendencias y validar el impacto de los cambios de agua.

### Alertas proactivas de tendencia con IA

Cuando se detecta un patrón de riesgo en los registros recientes, el Registro de
parámetros ahora muestra una tarjeta de **Alertas de tendencia con IA** en la parte
superior. Por ejemplo, si el nitrato sigue subiendo durante varios días, la app
sugiere de forma proactiva considerar un cambio de agua.

---

## Registro de dosificación

**Ruta:** Detalles del acuario → pestaña *Dosificación*

(También accesible desde el botón de acción rápida de la tarjeta del acuario)

Mantén un registro de tratamientos, suplementos y aditivos.

### Añadir una entrada

1. Toca **+ Añadir entrada de dosificación**.
2. Introduce el nombre del producto, la dosis y la unidad.
3. Opcionalmente añade notas (motivo, número de lote, etc.).
4. Toca **Guardar**.

Las entradas se agrupan por producto para facilitar el seguimiento de los tratamientos
recurrentes.

---

## Historial de análisis

**Ruta:** Menú principal → *Historial de análisis*

Cada resultado de AI (informe de compatibilidad, recomendación de población, análisis
de parámetros del agua, info de peces, análisis de fotos) se guarda aquí
automáticamente.

- **Favoritos** marcando con el icono de estrella.
- **Reproducir** cualquier resultado para verlo completo.
- **Eliminar** entradas individuales o borrar todo el historial.

---

## Comunidad

**Ruta:** Menú principal → *Comunidad*

Navega y comparte publicaciones con otros usuarios de Aquarium AI. Inicia sesión
(anónimamente o con Google/Facebook) para publicar, comentar y reaccionar.

### Tipos de publicación

- **General** – discusión abierta
- **Pregunta** – pregunta a la comunidad
- **Presentación** – muestra tu acuario
- **Consejos** – comparte conocimiento

### Iniciar sesión

Toca **Iniciar sesión** en la parte superior de la pantalla de Comunidad. Puedes usar
Google, Facebook o permanecer anónimo. Las cuentas anónimas pueden actualizarse a una
cuenta con nombre más tarde en **Perfil**.

### Notificaciones de interacción en la comunidad

Cuando las notificaciones están activadas en tu dispositivo, Aquarium AI envía alertas
locales tipo push cuando alguien **da me gusta**, **guarda** o **comenta** una de tus
publicaciones de la comunidad.

---

## Configuración y apariencia

**Ruta:** Menú principal → *Configuración*

| Configuración | Descripción |
| ------------- | ----------- |
| **Proveedor de AI** | Elige entre Groq, Gemini y OpenAI |
| **Claves API de AI** | Almacena tus claves API personales |
| **Modelos recomendados** | Sección de consejos desplegable con nombres de modelos recomendados para Gemini, Groq y OpenAI |
| **Límite de historial de chat** | Número de mensajes anteriores enviados con cada solicitud |
| **Visualización del acuario** | Mostrar/ocultar fotos, métricas, habitantes, notas, etc. |
| **Copia de seguridad / Restauración** | Exportar e importar todos los datos del acuario; la copia/restauración en la nube es para Acuaristas Fundadores en móvil/escritorio y para todos los usuarios con sesión iniciada en web |
| **Copia de seguridad automática en la nube** | Subir automáticamente una copia de seguridad en la nube según un horario (solo Acuaristas Fundadores — ver abajo) |
| **Notificaciones** | Programar recordatorios para cambios de agua, alimentación, etc. |

### Copia de seguridad automática en la nube

**Requisitos:** Estado de Acuarista Fundador + sesión iniciada en Firebase

Cuando está activada, la app sube silenciosamente una copia de seguridad en la nube cada vez que se inicia, siempre que haya transcurrido el intervalo configurado desde la última copia exitosa.

**Configuración:**

| Configuración | Opciones | Descripción |
| ------------- | -------- | ----------- |
| **Copia de seguridad automática en la nube** | Activado / Desactivado | Habilita o deshabilita las copias de seguridad automáticas programadas |
| **Frecuencia de copia de seguridad** | Diariamente / Semanalmente (predeterminado) / Mensualmente | Con qué frecuencia se sube una nueva copia |
| **Última copia de seguridad automática** | Marca de tiempo | Cuándo se completó la última copia automática |

**Cómo funciona:**

1. En cada inicio de la app, el programador verifica si ha transcurrido el intervalo configurado desde la última copia exitosa.
2. Si la copia está pendiente y el usuario ha iniciado sesión como Acuarista Fundador, se sube silenciosamente a la nube.
3. La marca de tiempo «última copia automática» solo se actualiza en caso de éxito; un intento fallido se reintentará en el próximo inicio.

### Apariencia

**Ruta:** Menú principal → *Apariencia* (o Configuración → Apariencia)

- Elige entre **15 temas de color** incluyendo Material You (color dinámico de tu
  fondo de pantalla)
- Selecciona un color semilla personalizado con el selector de color
- Selecciona una **familia de fuentes** (Poppins, Karla, Noto Sans)
- Alterna el modo **claro / oscuro / sistema**

---

*Para documentación para desarrolladores, guías de contribución y ayuda con la
traducción, consulta los otros documentos en la sección de Información.*
