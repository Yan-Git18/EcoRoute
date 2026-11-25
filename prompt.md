Quiero rediseñar y corregir integralmente el módulo de Gestión de Equipos de mi aplicación. He adjuntado capturas de las vistas actuales y una referencia visual de cómo quiero simplificar el listado.

El objetivo es conseguir una experiencia más limpia, moderna, intuitiva y organizada, mejorando el flujo de navegación, creación, visualización y edición de equipos.

No quiero limitarme a cambiar los colores o los componentes visuales. También necesito revisar y corregir la lógica de funcionamiento, las validaciones y los errores de persistencia en Firebase.

### 1. Rediseño del listado de equipos

Quiero simplificar considerablemente la pantalla principal de Gestión de Equipos.

Actualmente, cada equipo se muestra en una tarjeta demasiado grande que contiene información que considero innecesaria para el listado general.

Tomar como referencia la última imagen adjunta, donde los equipos aparecen organizados en una lista sencilla.

Cada elemento debe mostrar solamente:

- Icono de varias personas que represente al equipo, no un camión.
- Nombre del equipo.
- Cantidad de integrantes.
- Camión asignado y número de placa.
- Estado del equipo mediante una etiqueta visual discreta.

**Interacción:**

Al pulsar cualquier elemento de la lista, se debe navegar a una nueva pantalla de Detalle del Equipo.

Mantener:

- Buscador de equipos.
- Filtros por estado, siempre que correspondan a los estados reales del sistema.
- Botón flotante «Nuevo equipo».

Reducir o eliminar las tarjetas estadísticas superiores si no aportan información indispensable. Priorizar el espacio disponible para mostrar más equipos en pantalla.

### 2. Nueva pantalla: Detalle del Equipo

Crear una pantalla independiente para consultar toda la información de un equipo.

Organizarla mediante las siguientes secciones:

**A. Encabezado**

- Nombre del equipo.
- Estado actual.
- Cantidad de integrantes.

**B. Información del equipo**

- Sector asignado.
- Camión asignado.
- Tipo de vehículo.
- Placa del vehículo.

**C. Integrantes**
Mostrar el listado de integrantes con:

- Nombre completo.
- Correo electrónico.
- Rol dentro del equipo.

**D. Información operativa**

Si existen estos datos en el sistema, mostrar:

- Incidente o tarea actualmente asignada.
- Estado operativo.
- Información de ubicación o última actualización.

No inventar información cuando no existan registros.

**E. Acciones**

Incorporar dos acciones principales:

1. «Editar equipo»: abrir el formulario de edición con los datos actuales precargados.
2. «Ver en mapa»: mostrar la ubicación del equipo, siempre que existan coordenadas válidas.

No utilizar un botón genérico llamado «Gestionar». Las acciones deben ser explícitas y fáciles de entender.

### 3. Rediseño de creación de equipos

Rediseñar completamente el formulario «Nuevo equipo».

Actualmente, los campos están distribuidos de manera poco organizada y el formulario ocupa demasiado espacio.

Organizarlo en el siguiente orden:

**Sección 1. Información general**

- Nombre del equipo.
- Sector.

**Sección 2. Recursos asignados**

- Selector de camiones disponibles.
- Mostrar modelo o tipo de vehículo y placa.
- No permitir seleccionar un camión que ya esté asignado a otro equipo.

**Sección 3. Configuración del equipo**
Permitir seleccionar el tamaño del equipo mediante tres opciones:

- 2 integrantes.
- 3 integrantes.
- 4 integrantes.

Utilizar selectores visuales sencillos y claros.

**Sección 4. Selección de integrantes**

- Mostrar exclusivamente usuarios con rol de Personal de limpieza.
- Mostrar únicamente usuarios que no pertenezcan a otro equipo.
- Incorporar buscador de integrantes.
- Utilizar checkboxes circulares para seleccionar personas.
- Mostrar nombre y correo electrónico.
- Mostrar un contador dinámico, por ejemplo: «Integrantes seleccionados (2/3)».

Validar que no se supere la cantidad de integrantes establecida.

**Sección 5. Confirmación**
Antes de crear el equipo, permitir verificar un pequeño resumen con:

- Nombre.
- Sector.
- Camión.
- Integrantes seleccionados.

Incorporar los botones «Cancelar» y «Crear equipo».

El formulario debe tener desplazamiento vertical cuando sea necesario, sin que los botones principales queden ocultos o se superpongan al contenido.

### 4. Rediseño de edición de equipos

Utilizar la misma estructura visual del formulario de creación, pero con los datos del equipo precargados.

Permitir:

- Modificar el nombre.
- Cambiar el sector.
- Cambiar el camión, siempre que esté disponible.
- Agregar integrantes disponibles.
- Retirar integrantes actuales.
- Modificar el tamaño del equipo entre 2, 3 y 4 integrantes.

**Consideraciones:**

- Los integrantes que ya pertenecen al equipo deben aparecer seleccionados.
- Los integrantes de otros equipos no deben aparecer como disponibles.
- Al retirar a una persona, actualizar correctamente su disponibilidad.
- No permitir guardar si la cantidad de integrantes supera el tamaño seleccionado.
- Validar que el equipo tenga la cantidad de integrantes requerida antes de guardar, de acuerdo con las reglas definidas para los equipos.

Agregar una acción independiente para eliminar el equipo, solicitando confirmación antes de ejecutar esta operación.

### 5. Corrección de errores de Firebase y lógica de negocio

En las capturas se observa el siguiente error al intentar actualizar un equipo:

cloud_firestore/permission-denied: PERMISSION_DENIED: Missing or insufficient permissions.

Necesito que investigues y soluciones el origen del problema.

También revisar que las operaciones de actualización sean consistentes para evitar que un equipo se actualice parcialmente.

### 6. Reglas de negocio

Mantener las siguientes reglas:

- Un usuario solamente puede pertenecer a un equipo a la vez.
- Un camión solamente puede estar asignado a un equipo a la vez.
- No mostrar personal que pertenezca a otros equipos como disponible.
- No permitir duplicar integrantes.
- Al retirar a un integrante, actualizar su relación con el equipo.
- Al cambiar de camión, liberar correctamente el vehículo anterior.
- La información del equipo y sus relaciones deben mantenerse sincronizadas.
- Los cambios deben reflejarse correctamente en el listado y en el detalle.

El estado operativo del equipo debe respetar la lógica existente. No introducir nuevos estados ni cambiar el significado de los estados actuales sin revisar previamente cómo se utilizan.

### 7. Consideraciones de diseño y desarrollo

- Mantener la identidad visual actual de la aplicación, especialmente su paleta verde y sus componentes.
- Utilizar un diseño minimalista, moderno y profesional.
- Evitar tarjetas innecesariamente grandes, información repetida y elementos decorativos excesivos.
- Mantener una jerarquía visual clara.
- Priorizar la experiencia en dispositivos móviles.
- Utilizar componentes reutilizables.
- Mantener la arquitectura y los patrones de desarrollo existentes.
- No duplicar servicios ni modelos.

###
