# KeyTrace

[简体中文](README.md) | [繁體中文](README.zh-Hant.md) | [English](README.en.md) | [日本語](README.ja.md) | **Español** | [Français](README.fr.md) | [Deutsch](README.de.md)

Herramienta local para macOS que registra la actividad del teclado y el ratón y exporta vídeos animados con mapas de calor 3D.

Adaptada de las funciones e ideas de [xuhk/XAssistant](https://github.com/xuhk/XAssistant), reimplementada de forma nativa en Swift. Es una versión no oficial para macOS, sin afiliación con el autor original. No se copió código ni material del proyecto de Windows. Disponible bajo la [licencia MIT](LICENSE).

Desactiva **Mostrar textos del vídeo** para ocultar títulos, fechas y notas, conservando las etiquetas y los contadores. La última pulsación baja con más peso y vuelve lentamente sin alargar la duración elegida. Al abrir las estadísticas desde la barra de menús, la ventana aparece en el escritorio actual y en la pantalla del puntero.

## Funciones

- Registro en segundo plano desde la barra de menús, con estadísticas diarias y mapas de calor del teclado.
- Detección de teclados integrados y externos, con distribuciones MacBook y Mac de tamaño completo y selección manual.
- Selección de inicio y fin, con accesos a la primera grabación y a la hora actual.
- Exportación de pulsaciones animadas y mapas acumulativos como MP4 de 1080p a 30 fps en Descargas, comprimiendo automáticamente los intervalos inactivos.
- Inclusión o exclusión del ratón; velocidades de 0.5× a 1024×, incluida 128× / 256× / 512×.
- Escala de color dinámica según el mayor recuento acumulado actual, o fija según el mayor total final del intervalo seleccionado.
- La imagen final permanece cinco segundos mientras la cámara gira lentamente.
- Sonido sincronizado en cada pulsación, distinto para cada tecla física, con perfiles de teclado, mecánico, suave o silencio.

## Instalación

Versión publicada **v1.0.0**; app **1.0.0, build 16**. Requiere **Apple Silicon (arm64), macOS 13+**. Intel no es compatible. **Firma ad hoc, sin notarización de Apple; las actualizaciones pueden requerir autorización otra vez.**

Descarga el [ZIP de la app](https://github.com/nope-gao/KeyTrace/releases/download/v1.0.0/KeyTrace-arm64.zip) y [SHA256SUMS](https://github.com/nope-gao/KeyTrace/releases/download/v1.0.0/SHA256SUMS) de la [versión publicada](https://github.com/nope-gao/KeyTrace/releases/tag/v1.0.0) y comprueba la suma con el comando siguiente. El archivo Source code ZIP no es la app. Descomprime y mueve **KeyTrace.app** a `~/Applications` antes de abrirla.

```bash
# In the folder containing the downloaded ZIP and SHA256SUMS
awk '$2 == "KeyTrace-arm64.zip"' SHA256SUMS | shasum -a 256 -c -
```

Instalación por terminal de esta versión concreta, sin usar `/latest`:

```bash
curl -fsSL https://raw.githubusercontent.com/nope-gao/KeyTrace/v1.0.0/install.sh -o /tmp/keytrace-install.sh
bash /tmp/keytrace-install.sh --version v1.0.0
```

El instalador comprueba SHA-256, versión y firma sin sudo. Se detiene si la app está abierta, no cambia instalaciones idénticas y rechaza firmas incompatibles antes de reemplazar. Para migrar, cierra y respalda la app anterior, reemplázala manualmente y autoriza de nuevo. Se conservan los registros.

Si macOS bloquea el primer inicio, revisa el origen y usa **Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente** solo para esta app. No desactives Gatekeeper, SIP ni las protecciones globales. Detén la instalación si la política del equipo impide excepciones.

En **Privacidad y seguridad → Monitorización de entrada**, añade la app desde su ubicación instalada y actívala; cierra y vuelve a abrir. Reanuda si está pausada. Pulsa teclas y haz clic; comprueba que aumenten la hora del último registro y los contadores. El interruptor por sí solo no basta. Si falla tras actualizar, cierra, elimina la entrada antigua y añade la app nueva. Si hace falta, ejecuta el reinicio de permisos limitado a esta app que aparece abajo y autoriza manualmente.

```bash
tccutil reset ListenEvent app.keytrace.mac
```

KeyTrace usa una carpeta de datos independiente y no importa automáticamente registros de otras apps. Activa Supervisión de entrada en la primera instalación.

## Duración fija

Elige **Duración fija** para definir la duración total, por defecto **60 segundos (1 minuto)**, incluidos los **5 segundos finales de giro**. Las acciones se aceleran o ralentizan automáticamente tras eliminar las pausas. Admite de 6 a 86400 segundos.

## Idioma

El ajuste inicial es **Seguir el sistema**. La aplicación recorre la lista de idiomas preferidos de macOS y elige uno compatible: **简体中文, 繁體中文, English, 日本語, Español, Français, Deutsch**. Si no hay coincidencias, utiliza inglés. Puedes elegir otro idioma o volver al sistema en la parte inferior de la ventana; la preferencia se guarda.

El idioma se aplica a la interfaz, menús, mensajes existentes, fechas y números, etiquetas del ratón, nombres de teclas de función y subtítulos del vídeo. Las letras conservan la distribución física ANSI. El vídeo mantiene el idioma seleccionado al iniciar la exportación; durante ella no se permite cambiarlo manualmente. macOS controla el idioma de sus propios diálogos de permisos y de los detalles de errores del sistema.

## Sonido del vídeo

Elige **Teclado** (predeterminado), **Mecánico**, **Suave** o **Silencio**. Cada tecla física tiene un timbre corto y distinto, que se activa solo al pulsarla y coincide con el primer fotograma que muestra la pulsación. Las pulsaciones densas se mezclan a velocidades altas. Excluir el ratón también excluye sus clics. La última pulsación tiene un tono más grave cuya breve resonancia puede continuar al inicio del giro final de cinco segundos.

El audio se sintetiza localmente: no utiliza el micrófono, no graba tu teclado real ni requiere archivos de sonido externos. Los vídeos con sonido incluyen una pista AAC de 48 kHz; el modo Silencio no genera pista de audio.

## Compilar desde el código

```bash
xcode-select --install
bash build.sh
```

Las compilaciones locales usan firma ad hoc; reemplazar la app instalada puede requerir autorización de nuevo.

## Uso

Selecciona el intervalo, velocidad, ratón, escala de calor y sonido, y pulsa **Exportar a Descargas**. No se puede recuperar actividad de periodos sin grabación.

## Datos locales y privacidad

Los datos se guardan en `~/Library/Application Support/KeyTrace/`. La aplicación no los sube ni incluye telemetría. El instalador accede a GitHub para descargar versiones.

Para reproducir animaciones se guardan las horas de pulsación y liberación, identificadores de teclas físicas, información del dispositivo y orden de eventos. También se registran nombres de aplicaciones, Bundle ID y tiempo de uso. No se lee el texto final de los métodos de entrada, títulos de ventanas, direcciones web ni coordenadas del ratón. **La secuencia de teclas puede permitir inferir el texto escrito. Las grabaciones son datos sensibles; no publiques la carpeta de datos.**

Pausar detiene los nuevos eventos y las estadísticas de tiempo, pero conserva el historial. Los datos son texto sin cifrar, almacenado localmente y sin caducidad automática. Cierra la app antes de mover datos, cachés y vídeos no deseados a la Papelera.

`~/Library/Application Support/KeyTrace/` · `~/Library/Caches/KeyTrace/VideoJobs/` · `~/Downloads/KeyTrace-*.mp4`

## Limitaciones conocidas

- Principalmente distribuciones ANSI. ISO/JIS no están totalmente adaptadas y la detección automática puede no reconocer todos los dispositivos de terceros.
- Las teclas Fn, multimedia y la entrada segura pueden no registrarse por completo. Touch ID no se registra como una tecla normal.
- El origen de los eventos puede ser ambiguo al usar varios teclados. La repetición automática al mantener una tecla no se cuenta como pulsaciones independientes.
- Los vídeos se generan directamente con SceneKit, Metal y AVFoundation; no requieren Blender.
