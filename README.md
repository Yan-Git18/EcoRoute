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

## Perfil ciudadano, comunidad y notificaciones

- El perfil guarda el nombre y el teléfono en `users/{uid}`. El avatar comprimido se guarda en `users/{uid}/media/avatar` con hasta 96 KiB.
- Los reportes y las evidencias guardan solo las referencias en `reports/{id}` y una imagen JPEG por documento en `reports/{id}/media`, con hasta 256 KiB por imagen. La app carga las imágenes cuando se muestran y sigue leyendo las URLs y fotos Base64 de los documentos anteriores. Las imágenes nuevas solo necesitan Cloud Firestore y funcionan en Spark dentro de sus cuotas.
- Los apoyos y las calificaciones usan transacciones de Firestore. Cada vecino puede apoyar una vez mientras el reporte esté activo. El autor y quienes lo apoyaron pueden calificar la limpieza una vez al resolverse. El municipio ve el conteo y el promedio, y decide la prioridad.
- Asignar, iniciar la atención o resolver un reporte registra el cambio de estado y, si el autor habilitó las actualizaciones, crea un aviso en `users/{uid}/notifications` en la misma transacción. La bandeja funciona en Android y web con Spark. Las preferencias de cercanía y campañas ya se guardan por cuenta y están pendientes de sus fuentes de eventos.

### Firebase

Las [reglas de Firestore](firebase/citizen.firestore.rules) limitan la edición de roles, reportes, conteos y avisos a las operaciones permitidas en cada flujo. Para publicar las reglas usa `firebase deploy --only firestore:rules --project <id-del-proyecto>`. Publica esta versión de las reglas antes de habilitar el cierre de tareas con más de una foto de evidencia.

Para ejecutar el análisis y las pruebas de Flutter usa `flutter analyze` y `flutter test`. Para probar las transacciones y los permisos nuevos localmente ejecuta lo siguiente desde la raíz.

```sh
firebase emulators:exec --config firebase.emulator.json --only firestore,auth --project demo-ecoroute "node --test firebase/tests/*.test.mjs"
```

### Despacho a personal de limpieza

En **Admin → Gestión de Personal**, selecciona una cuadrilla al promover una cuenta o usa el botón de cuadrilla para cambiar la asignación de un trabajador existente. En **Reportes**, despacha el reporte a una cuadrilla. Un miembro puede iniciar la tarea disponible y queda como responsable del cierre con evidencia, incluso si después cambia de cuadrilla. El personal sin cuadrilla puede consultar sus tareas personales.

Coordina la publicación de las reglas con la actualización de la app de Staff. Las reglas nuevas requieren consultas por asignación y una fecha de cierre generada por Firestore. Revisa desde Admin cualquier reporte antiguo que figure asignado sin cuadrilla ni responsable y vuelve a despacharlo a la cuadrilla correspondiente.

Inicio y Perfil muestran la zona y el vehículo de la cuadrilla registrada. En **Mi perfil → Mis estadísticas**, el trabajador inicia, pausa, reanuda o termina su turno. Admin ve el estado de cada persona y cuántos miembros tienen un turno activo por cuadrilla. La disponibilidad de la unidad se sigue gestionando desde Admin.

El tiempo efectivo suma los intervalos en turno, descontando las pausas. Los cierres nuevos se guardan con hora del servidor y aparecen ordenados por fecha en el historial personal. Los cierres anteriores sin fecha registrada aparecen al final del historial.

El mapa propone paradas por prioridad y cercanía geográfica. OSRM traza por calles hacia la tarea activa. Si el servicio vial no está disponible, el mapa identifica la aproximación con un trazado punteado. El botón **Abrir en Google Maps** usa las coordenadas registradas de la tarea activa.

### Push de Android con Spark

El [Worker programado](firebase/push-worker/worker.mjs) usa el plan Free de Cloudflare y FCM HTTP v1. Revisa la cola cada cinco minutos. En Android, activa el permiso desde **Perfil → Notificaciones**. Para compilar un entorno de desarrollo con solo la bandeja usa `--dart-define=ECOROUTE_PUSH_ENABLED=false`.

1. En Firestore, crea un índice ascendente de ámbito **grupo de colecciones** para el campo `pushPending` de la colección `notifications`. La [definición del índice](firebase/push-worker/indexes.json) permite integrarlo con los índices existentes.
2. En el mismo proyecto de Google Cloud habilita FCM HTTP v1 y crea una cuenta de servicio dedicada con permisos de lectura y actualización en Firestore y envío de mensajes FCM. Carga su JSON como secreto `GOOGLE_SERVICE_ACCOUNT` de Cloudflare. Mantén esa clave fuera del repositorio y de Flutter.
3. Desde `firebase/push-worker` autentica Wrangler, publica el Worker en Workers Free con `npx wrangler deploy` y agrega el secreto con `npx wrangler secret put GOOGLE_SERVICE_ACCOUNT`. Verifica que el identificador de proyecto en `wrangler.jsonc` coincida con tu entorno. Usa un dispositivo Android con Google Play services para comprobar la recepción.
