# ecoroute

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Versiones de Android

`pubspec.yaml` conserva la versión visible `2.0.0` y fija el código de compilación en `4009`. El APK universal usa ese código directamente. Los APK anteriores generados con `--split-per-abi` recibieron un incremento por arquitectura. Para futuras distribuciones, usa el APK universal y aumenta el código por encima del mayor `versionCode` que hayas distribuido.

### Actualizar instalaciones de prueba

Los APK de prueba anteriores se firmaron con el certificado de depuración de la máquina que los generó. Para actualizar esas instalaciones, el nuevo APK debe conservar ese certificado y el identificador `com.example.ecoroute`. En esa máquina, puedes ejecutar `flutter build apk --debug` o generar un APK optimizado para la prueba del curso desde PowerShell.

```powershell
$env:ECOROUTE_ANDROID_LEGACY_SIGNING = 'true'
try {
    flutter build apk --release
} finally {
    Remove-Item Env:ECOROUTE_ANDROID_LEGACY_SIGNING
}
```

### Firma para publicación

En las compilaciones de publicación, Gradle usa el almacén de claves indicado en el archivo local `android/key.properties`. Configúralo con la clave de firma que corresponda al canal de distribución, o con la clave de carga si usas Play App Signing. El repositorio excluye ese archivo y los almacenes de claves.

```properties
storeFile=C:/ruta-privada/ecoroute-upload.jks
storePassword=CONTRASEÑA_DEL_ALMACÉN
keyAlias=upload
keyPassword=CONTRASEÑA_DE_LA_CLAVE
```

Con esa configuración, ejecuta `flutter build appbundle --release` para Google Play o `flutter build apk --release` para distribución directa. Android requiere un certificado compatible para actualizar una instalación existente. Si los APK del curso y la publicación usan certificados distintos, las instalaciones de prueba requieren una instalación nueva de la versión publicada. Consulta la [guía de firma de Android](https://developer.android.com/studio/publish/app-signing) y la [guía de publicación de Flutter](https://docs.flutter.dev/deployment/android).

## Perfil ciudadano, comunidad y notificaciones

- El perfil guarda el nombre y el teléfono en `users/{uid}`. El avatar comprimido se guarda en `users/{uid}/media/avatar` con hasta 96 KiB.
- Los reportes y las evidencias guardan solo las referencias en `reports/{id}` y una imagen JPEG por documento en `reports/{id}/media`, con hasta 256 KiB por imagen. La app carga las imágenes cuando se muestran y sigue leyendo las URLs y fotos Base64 de los documentos anteriores. Las imágenes nuevas solo necesitan Cloud Firestore y funcionan en Spark dentro de sus cuotas.
- Los apoyos y las calificaciones usan transacciones de Firestore. Cada vecino puede apoyar una vez mientras el reporte esté activo. El autor y quienes lo apoyaron pueden calificar la limpieza una vez al resolverse. El municipio ve el conteo y el promedio, y decide la prioridad.
- Asignar, iniciar la atención o resolver un reporte registra el cambio de estado y, si el autor habilitó las actualizaciones, crea un aviso en `users/{uid}/notifications` en la misma transacción. La bandeja funciona en Android y web con Spark. Las preferencias de cercanía y campañas ya se guardan por cuenta y están pendientes de sus fuentes de eventos.

### Firebase

Las [reglas de Firestore](firebase/citizen.firestore.rules) limitan la edición de roles, reportes, conteos y avisos a las operaciones permitidas en cada flujo. Coordina su publicación con la migración y la actualización de los clientes.

Para ejecutar el análisis y las pruebas de Flutter usa `flutter analyze` y `flutter test`. Para probar las transacciones y los permisos nuevos localmente ejecuta lo siguiente desde la raíz.

```sh
firebase emulators:exec --config firebase.emulator.json --only firestore,auth --project demo-ecoroute "node firebase/tests/firestore.test.mjs"
node firebase/tests/push-worker.test.mjs
```

### Separación de equipos y flota

Firestore guarda los equipos en `crews` y los camiones en `vehicles`. El equipo referencia al camión con `vehicleId` y el camión asignado apunta al equipo con `assignedCrewId`.

Para actualizar un proyecto existente, respalda Firestore y pausa las escrituras de Equipos y Flota mientras coordinas el cambio de reglas y la actualización de los clientes. Usa una cuenta con acceso a Firestore y el token temporal `ECOROUTE_MIGRATION_ACCESS_TOKEN`.

1. Ejecuta `node firebase/migrate-report-operations.mjs --project <id-del-proyecto> --vehicles-only` para revisar el traslado. Si detecta referencias o placas ambiguas, corrige los registros indicados antes de aplicar.
2. Publica las reglas con `firebase deploy --only firestore:rules --project <id-del-proyecto>`.
3. Repite la migración con `--vehicles-only --apply`. Los camiones independientes conservan su ID. Los camiones que antes estaban integrados en un equipo reciben un documento propio y conservan la asignación.
4. Actualiza los clientes de administración antes de reanudar las escrituras. Las versiones anteriores leen y escriben los camiones en `crews`.

### Carga de reportes

- **Municipio.** La bandeja y el mapa cargan 30 reportes por página, ordenados del más reciente al más antiguo. Firestore devuelve como máximo 31 documentos por solicitud para comprobar si hay otra página. El buscador y los filtros se aplican a los reportes cargados. Los totales municipales se consultan por separado con agregaciones de Firestore.
- **Ciudadanía.** El mapa y la lista de cercanos muestran hasta 100 incidencias creadas durante los últimos 30 días. La consulta acotada usa la colección comunitaria. El historial personal se sigue consultando desde **Mis reportes**.

La prueba local de Firestore compara las consultas con y sin límites sobre 180 reportes sintéticos e imprime la cantidad de documentos y el tiempo de respuesta. Los tiempos dependen de la máquina y los recuentos de documentos devueltos no incluyen las lecturas de índices ni otros cargos de producción.

### Migración del mapa comunitario y el despacho

`reports/{id}` guarda el contacto y el historial privado. El mapa consulta `communityReports/{id}`, que conserva la ubicación, el estado y las fotos compartidas. El historial de cambios queda disponible para el autor y el personal autorizado.

Para actualizar una base con reportes existentes, prepara las nuevas versiones de Android y web y coordina una ventana de mantenimiento.

1. Crea un respaldo de Firestore. Configura `ECOROUTE_MIGRATION_ACCESS_TOKEN` con un token OAuth temporal de una cuenta con permisos para leer y escribir documentos. Ejecuta `node firebase/migrate-report-operations.mjs --project <id-del-proyecto>` para revisar cuántos reportes y cuadrillas se migrarán.
2. Publica las reglas y los índices de asignaciones con `firebase deploy --only firestore:rules,firestore:indexes --project <id-del-proyecto>`. Durante la ventana, mantén pausados los despachos y las actualizaciones de reportes y equipos en los clientes. Las versiones anteriores son incompatibles con las nuevas reglas de escritura.
3. Ejecuta `node firebase/migrate-report-operations.mjs --project <id-del-proyecto> --apply`. El script crea las copias comunitarias, reconstruye los conteos de cuadrillas, registra las tareas en curso y conserva las dotaciones existentes de hasta cinco personas para que sus asignaciones puedan liberarse al eliminar el equipo. Los equipos nuevos admiten entre 2 y 5 integrantes. La migración también normaliza las referencias antiguas de fotos y retira los vínculos operativos a cuadrillas que ya no existen. Se puede repetir mientras las escrituras de los clientes sigan pausadas.
4. Revisa los IDs de `unattendedActiveReports` que devuelve el script. Son reportes en curso sin un trabajador activo que pueda cerrarlos. Publica las versiones actualizadas para iniciar la prueba manual.

### Despacho a personal de limpieza

En **Admin → Equipos**, selecciona un líder entre los integrantes al crear el equipo. Puedes cambiarlo en **Editar equipo** durante la atención de un reporte. Solo el líder actual puede iniciar la tarea y cerrarla con evidencia. Los demás integrantes pueden consultar el detalle, el estado y la ruta activa. El historial conserva quién inició y quién cerró el reporte. Las asignaciones directas a personal mantienen su flujo.

Los equipos con una lista de integrantes anterior a este cambio conservan la primera persona de la lista como responsable hasta que se guarde una elección explícita. Si el equipo anterior solo tiene integrantes vinculados desde sus perfiles, elige un líder en Admin antes de despachar reportes. Coordina la publicación de las reglas de Firestore con la actualización de los clientes para habilitar ambas vistas y los permisos.

Firestore permite iniciar una sola tarea por trabajador. El cierre libera la tarea activa y guarda la evidencia, el historial y el aviso que corresponda en la misma operación. Para dar de baja una cuadrilla, primero reasigna sus reportes abiertos y su personal. Revisa desde Admin cualquier reporte antiguo que figure asignado sin cuadrilla ni responsable y vuelve a despacharlo a la cuadrilla correspondiente.

Inicio y Perfil muestran la zona y el vehículo de la cuadrilla registrada. En **Mi perfil → Mis estadísticas**, el trabajador inicia, pausa, reanuda o termina su turno. Admin ve el estado de cada persona y cuántos miembros tienen un turno activo por cuadrilla. La disponibilidad de la unidad se sigue gestionando desde Admin.

El tiempo efectivo suma los intervalos en turno, descontando las pausas. Los cierres nuevos se guardan con hora del servidor y aparecen ordenados por fecha en el historial personal. Los cierres anteriores sin fecha registrada aparecen al final del historial.

El mapa propone paradas por prioridad y cercanía geográfica. OSRM traza por calles hacia la tarea activa. Si el servicio vial no está disponible, el mapa identifica la aproximación con un trazado punteado. El botón **Abrir en Google Maps** usa las coordenadas registradas de la tarea activa.

### Push de Android con Spark

El [Worker programado](firebase/push-worker/worker.mjs) usa el plan Free de Cloudflare y FCM HTTP v1. Revisa la cola cada cinco minutos. En Android, activa el permiso desde **Perfil → Notificaciones**. Para compilar un entorno de desarrollo con solo la bandeja usa `--dart-define=ECOROUTE_PUSH_ENABLED=false`.

1. En Firestore, crea un índice ascendente de ámbito **grupo de colecciones** para el campo `pushPending` de la colección `notifications`. La [definición del índice](firebase/push-worker/indexes.json) permite integrarlo con los índices existentes.
2. En el mismo proyecto de Google Cloud habilita FCM HTTP v1 y crea una cuenta de servicio dedicada con permisos de lectura y actualización en Firestore y envío de mensajes FCM. Carga su JSON como secreto `GOOGLE_SERVICE_ACCOUNT` de Cloudflare. Mantén esa clave fuera del repositorio y de Flutter.
3. Desde `firebase/push-worker` autentica Wrangler, publica el Worker en Workers Free con `npx wrangler deploy` y agrega el secreto con `npx wrangler secret put GOOGLE_SERVICE_ACCOUNT`. Verifica que el identificador de proyecto en `wrangler.jsonc` coincida con tu entorno. Usa un dispositivo Android con Google Play services para comprobar la recepción.
