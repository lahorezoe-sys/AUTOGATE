BASE DE DATOS PARA EL SISTEMA DE CONTROL DE ACCESOS DEL VICTOR
  Guía de Estudio y Defensa: Base de Datos AutoGate

Esta guía explica en detalle cómo está diseñada la base de datos de **AutoGate**, cómo se conectan sus tablas a través de **Claves Foráneas (Foreign Keys)**, por qué se eligieron ciertas reglas de borrado (`CASCADE`, `SET NULL`, `RESTRICT`) y cómo defender cada decisión técnica frente a los profesores o el tribunal examinador.


## 2. Conceptos Teóricos Clave para el Examen

### A. Clave Primaria (Primary Key - PK)
* **¿Qué es?** Es la columna que identifica de forma única, irrepetible y no nula (`NOT NULL`) a cada fila dentro de una tabla.
* **Nuestra elección:** En casi todas las tablas usamos una **clave artificial o subrogada**: `id INT UNSIGNED AUTO_INCREMENT`.
* **¿Por qué la defendemos así?** En lugar de usar claves naturales (como el DNI, el email o la patente), usamos un número autoincremental porque los números enteros ocupan solo 4 bytes en memoria, hacen que los índices B-Tree sean ultra rápidos al buscar y no dependen de datos del mundo real que podrían cambiar o escribirse con errores.

---

### B. Claves Foráneas (Foreign Keys - FK) y Relaciones
* **¿Qué es?** Una Clave Foránea es una columna en una tabla (hija) que apunta directamente a la Clave Primaria de otra tabla (padre).
* **Propósito:** Evitar que existan **datos huérfanos** o incoherentes. Por ejemplo, la base de datos no te va a permitir guardar una tarjeta RFID asignada a un usuario `999` si el usuario `999` no existe en la tabla `usuarios`.

---

### C. Reglas de Integridad Referencial: `ON DELETE` y `ON UPDATE`

Cuando en la tabla **padre** se borra o se modifica un registro que ya tiene hijos vinculados, la base de datos necesita saber qué hacer con esos registros hijos. En AutoGate aplicamos 3 comportamientos según el caso de negocio:

#### 1. `ON DELETE CASCADE` (Borrado en Cascada)
* **Cómo funciona:** Si se borra el padre, la base de datos **elimina automáticamente** todos los registros hijos relacionados.
* **Dónde lo usamos en AutoGate:**
  * `sesiones` -> vinculada a `usuarios`.
  * `password_resets` -> vinculada a `usuarios`.
* **Justificación para el tribunal:** Si un usuario es eliminado del sistema, no tiene ningún sentido que queden guardados sus tokens de sesión web activos o sus solicitudes de reseteo de contraseña. Son datos temporales y descartables que deben limpiarse solos.

#### 2. `ON DELETE SET NULL` (Poner en Nulo)
* **Cómo funciona:** Si se borra el registro padre, el registro hijo **no se elimina**, sino que la columna que apuntaba al padre pasa a valer `NULL`. Para que esto funcione, la columna FK debe declararse explícitamente como `NULL` (no puede ser `NOT NULL`).
* **Dónde lo usamos en AutoGate:**
  * `eventos_acceso` (en las columnas `usuario_id`, `tarjeta_id`, `porton_id`, `dispositivo_id`).
  * `logs_auditoria` (en la columna `usuario_actor_id`).
  * `alertas` (en `dispositivo_id`, `porton_id`, `reconocida_por`).
  * `pagos` (en `usuario_id`, `empresa_id`, `producto_id`).
* **Justificación para el tribunal (Muy importante para la defensa):**  
  **Preservación de la evidencia histórica y legal.**  
  *Imaginate que un empleado comete un delito o es despedido y el administrador borra su usuario del sistema. Si hubiésemos usado `CASCADE`, se borrarían automáticamente todas las entradas y salidas que hizo esa persona en el portón.*  
  Con `SET NULL`, la fila de `eventos_acceso` **sigue existiendo**: queda guardado el `uid_leido` de la tarjeta, el día y la hora exacta del ingreso, el mensaje de respuesta y el portón, garantizando que el historial forense no se pierda nunca.

#### 3. `RESTRICT` o `NO ACTION` (Por defecto si no se pone nada)
* **Cómo funciona:** La base de datos **prohíbe y rechaza** que se borre el registro padre mientras tenga al menos un hijo dependiendo de él. Si intentás hacer un `DELETE` te tira un error de restricción de clave foránea.
* **Dónde lo usamos en AutoGate:**
  * `usuarios` respecto a `empresas`.
  * `portones` respecto a `empresas`.
  * `tarjetas_rfid` respecto a `usuarios`.
* **Justificación para el tribunal:** Protección de consistencia del negocio. No podés borrar una empresa entera de un plumazo si todavía tiene empleados dados de alta, portones activos o tarjetas funcionando; primero tenés que reasignar o dar de baja ordenadamente sus componentes.

#### 4. `ON UPDATE CASCADE` (Actualización en Cascada)
* **Cómo funciona:** Si por alguna razón cambia el valor de la clave primaria en la tabla padre (por ejemplo, en una migración de IDs), el nuevo valor se propaga automáticamente a todas las tablas hijas sin romper los vínculos.
* Lo tenemos activado en prácticamente **todas las relaciones** del proyecto como buena práctica estándar de SQL.

---

### D. Restricciones de Unicidad (`UNIQUE KEY`)
* Son reglas que le ordenan al motor que en esa columna **no puede haber dos filas con el mismo valor**.
* En AutoGate se usan para:
  * `tarjetas_rfid.uid`: No pueden existir dos tarjetas físicas con el mismo código hexadecimal.
  * `dispositivos_iot.mac`: No pueden existir dos placas ESP32 conectadas con la misma dirección MAC de fábrica.
  * `usuarios.username` y `usuarios.email`: Dos personas no pueden registrarse con el mismo usuario o correo.
  * `empresas.codigo_empresa`: Cada organización tiene un código identificador irrepetible.

---

## 3. Explicación Detallada de Cada Tabla (Módulo por Módulo)

```
                 ┌──────────────────────────────────────────────────────────┐
                 │                        EMPRESAS/PERSONA                          │
                 └──────────────┬────────────────────────────┬──────────────┘
                                │                            │
                ┌───────────────┴─────────────┐     ┌────────┴──────────────┐
                │           ROLES             │     │       PORTONES        │
                └───────────────┬─────────────┘     └────────┬──────────────┘
                                │                            │
                 ┌──────────────▼─────────────┐              │
                 │          USUARIOS          │              │
                 └──────┬──────────────┬──────┘              │
                        │              │                     │
       ┌────────────────▼──────┐  ┌────▼──────────┐   ┌──────▼──────────────┐
       │     TARJETAS_RFID     │  │ VINCULACIONES │   │   DISPOSITIVOS_IOT  │
       └────────────────┬──────┘  └────┬──────────┘   └──────┬──────────────┘
                        │              │                     │
                        └──────────────┼─────────────────────┘
                                       │
                        ┌──────────────▼──────────────┐
                        │       EVENTOS_ACCESO        │
                        └──────────────┬──────────────┘
                                       │
                        ┌──────────────▼──────────────┐
                        │           ALERTAS           │
                        └─────────────────────────────┘
```

---

### 🏢 MÓDULO 1: Organizaciones, Usuarios y Permisos

#### 1. `empresas`
* **¿Qué representa en la vida real?** Cada cliente que contrata el servicio de AutoGate. Puede ser un barrio cerrado, un consorcio de edificios, una fábrica o un colegio.
* **¿Qué datos guarda?**
  * `id`: Clave primaria única.
  * `codigo_empresa`: Identificador corto (ej: `BARRIO_LOS_ALAMOS`, `COLEGIO_SAN_MARTIN`).
  * `nombre_empresa`: Razón social o nombre visible.
  * `max_dispositivos`: Cantidad máxima de placas ESP32 que tienen contratadas para su cuenta.
  * `estado`: `activa`, `inactiva` o `suspendida` (permite cortar el acceso al sistema si no pagan).
  * `configuracion_json`: Ajustes particulares de esa empresa (colores del panel, tiempos por defecto, etc.).
* **Rol en el sistema:** Es la tabla padre de la arquitectura multi-inquilino. Casi todas las demás tablas tienen un `empresa_id` para que el sistema sepa a quién le pertenece cada dato.

#### 2. `roles`
* **¿Qué representa en la vida real?** Los perfiles de autorización dentro del panel web (por ejemplo: Administrador General, Administrador de Barrio, Guardia de Seguridad, Operador Técnico).
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `empresa_id` (FK): Si tiene valor, es un rol personalizado creado por esa empresa. Si vale `NULL`, es un rol global del sistema que pueden usar todos.
  * `nombre`: Nombre del rol.
  * `es_admin`: Si tiene privilegios totales dentro de su empresa.
  * `permisos_json`: Listado de permisos específicos guardados en formato JSON (ej: `["abrir_porton", "ver_reportes", "crear_usuarios"]`).
* **Claves Foráneas:**
  * `empresa_id -> empresas(id)` con `ON DELETE SET NULL`: Si se borra la empresa, los roles no se destruyen violentamente, quedan como plantillas generales.

#### 3. `usuarios`
* **¿Qué representa en la vida real?** Las personas reales registradas en la plataforma. Incluye tanto a los que inician sesión en la web (guardias, administradores) como a los vecinos o empleados a quienes se les otorga acceso por el portón.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `rol_id` (FK) y `empresa_id` (FK): A qué organización pertenece y qué rol cumple.
  * `username` y `email`: Credenciales de acceso únicas.
  * `password_hash`: Contraseña encriptada de forma segura con algoritmo `BCrypt` (nunca en texto plano).
  * `estado`: `activo`, `inactivo` o `suspendido`.
  * `restringir_horario`: Un booleano (`1` o `0`). Si está en `1`, el usuario no puede entrar a cualquier hora.
  * `hora_entrada_permitida` y `hora_salida_permitida`: Rango de horario en que se le permite el acceso (ej: personal de limpieza de 08:00 a 16:00).
  * `dias_permitidos`: Tipo `SET('1','2','3','4','5','6','7')` donde cada número representa un día de la semana (1 = Lunes, 7 = Domingo).
* **Claves Foráneas:**
  * `empresa_id -> empresas(id)` con `RESTRICT`.
  * `rol_id -> roles(id)` con `RESTRICT`.
* **Cómo interactúa con el ESP32:** Cuando el ESP32 lee una tarjeta, la API (`ApiController::verificarAcceso`) hace un `JOIN` con esta tabla para chequear si el dueño de la tarjeta está activo y si la hora y día actuales caen dentro de su horario permitido.

---

### 🚗 MÓDULO 2: Portones, Hardware e Inventario IoT

#### 4. `portones`
* **¿Qué representa en la vida real?** El portón corredizo, levadizo, barrera o puerta física que se desea controlar y monitorear.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `empresa_id` (FK): Empresa a la que pertenece el portón.
  * `nombre` y `ubicacion`: Nombre visible (ej: "Portón Principal Entrada", "Barrera Norte").
  * `estado`: `cerrado`, `abierto`, `abriendo`, `cerrando`, `mantenimiento` o `error`.
  * `duracion_apertura_seg`: Tiempo en segundos que el portón tarda en abrirse completamente (para calcular tiempos de espera con el servo/relé).
  * `retardo_cierre_seg`: Segundos que se queda abierto antes de empezar a cerrarse automáticamente.
  * `ultima_apertura` y `ultimo_cierre`: Timestamps para registrar la última vez que operó.
* **Claves Foráneas:**
  * `empresa_id -> empresas(id)` con `RESTRICT`.

#### 5. `productos`
* **¿Qué representa en la vida real?** El stock e inventario de hardware que fabrica o ensambla AutoGate en su taller antes de entregárselo a un cliente.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `codigo_serial` (UNIQUE): Número de serie impreso en la caja o placa (ej: `AG-PRO-2026-001`).
  * `mac` (UNIQUE): Dirección MAC de la placa ESP32 grabada de fábrica.
  * `modelo`: Variante del hardware (`autogate_mini`, `autogate_pro`, etc.).
  * `version_firmware`: Versión del sketch cargado en la placa al momento de salir de fábrica.
  * `estado`: `disponible` (en depósito), `activado` (ya funcionando en un cliente), `mantenimiento` o `baja`.
* **Diferencia clave con `dispositivos_iot`:** `productos` es la placa física como bien de inventario/fábrica. Todavía no está asignada a ningún portón.

#### 6. `vinculaciones_producto`
* **¿Qué representa en la vida real?** El contrato o acta de asignación de un producto. Registra en qué fecha y qué usuario técnico vinculó una placa de fábrica a una empresa determinada.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `producto_id` (FK), `empresa_id` (FK), `usuario_id` (FK): Qué producto se le asignó a qué empresa y qué usuario hizo la operación.
  * `estado`: Si la vinculación está vigente o fue dada de baja.
  * `activado_en`, `desvinculado_en`, `desvinculado_por` (FK), `motivo_desvinculacion`: Trazabilidad completa de cuándo y por qué se retiró un equipo.
* **Claves Foráneas:**
  * Vincula `productos`, `empresas` y `usuarios` garantizando trazabilidad total del hardware.

#### 7. `dispositivos_iot`
* **¿Qué representa en la vida real?** La placa ESP32 ya instalada físicamente en el portón, conectada al WiFi y comunicándose con el servidor en tiempo real.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `producto_id` (FK) y `vinculacion_id` (FK): De qué equipo de fábrica proviene.
  * `empresa_id` (FK): A qué cliente le responde.
  * `porton_id` (FK, nullable): A qué portón físico acciona el relé o servo.
  * `nombre`: Nombre del dispositivo (ej: "ESP32 Principal - Entrada").
  * `tipo_dispositivo`: `esp32_master` (la Main con relé/servo), `esp32_esclavo` (la Slave remota con lector PN532).
  * `direccion`: `entrada` o `salida` (para saber en qué sentido circuló el vehículo/persona).
  * `mac` (UNIQUE): Dirección MAC que la placa envía en cada petición JSON.
  * `ip`: Dirección IP asignada en la red local (obtenida en el último heartbeat).
  * `estado`: `en_linea`, `fuera_de_linea`, `mantenimiento` o `error`.
  * `ultimo_visto`: Fecha y hora exacta del último heartbeat recibido (si pasa más de 2 minutos sin enviar, el sistema lo marca fuera de línea).
* **Claves Foráneas:**
  * `porton_id -> portones(id)` con `ON DELETE SET NULL`: Si se borra un portón, la placa física no se borra de la base de datos; simplemente queda desasignada lista para ponerse en otro portón.

---

### 💳 MÓDULO 3: Credenciales, Accesos y Seguridad

#### 8. `tarjetas_rfid`
* **¿Qué representa en la vida real?** Las tarjetas plásticas o llaveros de 13.56 MHz que se le entregan a las personas para abrir los portones.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `usuario_id` (FK): Persona titular a la que le pertenece la tarjeta.
  * `uid` (UNIQUE): El identificador único hexadecimal que lee la antena PN532 (ej: `222BCD04`, `8C2FCD04`).
  * `etiqueta`: Apodo o descripción (ej: "Llavero auto Facundo", "Tarjeta de repuesto").
  * `estado`: `activa`, `inactiva`, `perdida`, `revocada` o `suspendida`.
  * `asignada_en`, `revocada_en`, `notas`: Fechas de entrega y motivos si se bloquea por extravío.
* **Claves Foráneas:**
  * `usuario_id -> usuarios(id)` con `ON UPDATE CASCADE` y `RESTRICT`: Una tarjeta siempre debe pertenecer a un usuario registrado.
* **Relación:** Un usuario puede tener varias tarjetas (por ejemplo, una para cada miembro de la familia o para dos autos), pero cada tarjeta (`uid`) pertenece a una sola persona.

#### 9. `eventos_acceso` (La tabla transaccional más importante de la tesis)
* **¿Qué representa en la vida real?** La bitácora en tiempo real. Cada vez que alguien apoya una tarjeta en el lector PN532 de la Main o de la Slave, se inserta una fila en esta tabla.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `empresa_id` (FK): Contexto del cliente.
  * `porton_id` (FK, nullable): Por cuál portón se intentó pasar.
  * `dispositivo_id` (FK, nullable): Cuál ESP32 capturó la lectura.
  * `tarjeta_id` (FK, nullable): Qué tarjeta del sistema coincide con el UID (si está registrada).
  * `usuario_id` (FK, nullable): Quién era el dueño de la tarjeta en ese momento.
  * `uid_leido`: El código crudo leído por la antena (ej: `222BCD04`). Se guarda siempre como texto aunque la tarjeta no esté registrada, para que quede constancia de qué tarjeta desconocida intentó abrir.
  * `direccion`: `entrada` o `salida`.
  * `resultado`: `permitido` o `denegado`.
  * `motivo`: Explicación técnica precisa (`tarjeta_autorizada`, `tarjeta_no_registrada`, `tarjeta_inactiva`, `fuera_de_horario`, `porton_bloqueado`, `dispositivo_no_registrado`, `error_dispositivo`).
  * `detectado_en`, `respondido_en`, `porton_abierto_en`, `porton_cerrado_en`: Timestamps de precisión que miden la latencia de respuesta del sistema y la duración de apertura.
  * `mensaje_respuesta`: Mensaje amigable enviado de vuelta al ESP32 (ej: "¡Bienvenido, Facundo Llorens!").
* **Regla de Claves Foráneas (`ON DELETE SET NULL`):**
  * Todas las FKs (`usuario_id`, `tarjeta_id`, `porton_id`, `dispositivo_id`) tienen `SET NULL`. Si dentro de 3 años se elimina un usuario o se cambia una placa, el registro del evento no desaparece: el historial de ingresos permanece intacto para responder ante cualquier auditoría o pericia de seguridad.

#### 10. `alertas`
* **¿Qué representa en la vida real?** Notificaciones automáticas de seguridad que se disparan en el panel del guardia o administrador cuando ocurre algo anómalo.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `evento_acceso_id` (FK, nullable): Evento que originó la alerta (si aplica).
  * `dispositivo_id` (FK, nullable) y `porton_id` (FK, nullable): Origen del incidente.
  * `tipo`: Motivo de la alerta (ej: tarjeta denegada reiteradas veces, placa desconectada, portón trabado).
  * `severidad`: `baja`, `media`, `alta` o `critica`.
  * `titulo` y `mensaje`: Texto explicativo del problema.
  * `reconocida`: Booleano que indica si el guardia vio y atendió la alerta.
  * `reconocida_por` (FK, nullable) y `reconocida_en`: Quién y cuándo se hizo cargo de la alerta.
  * `resuelta_en`: Momento en que el problema quedó solucionado.

---

### 📝 MÓDULO 4: Auditoría, Pagos y Seguridad Web

#### 11. `logs_auditoria`
* **¿Qué representa en la vida real?** El libro de actas digital de lo que hacen los operadores en la web.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `empresa_id` (FK, nullable): Empresa afectada.
  * `usuario_actor_id` (FK, nullable): Quién hizo la acción (el administrador o guardia).
  * `accion`: Qué hizo (`crear_usuario`, `modificar_horario`, `vincular_dispositivo`, `iniciar_sesion`, etc.).
  * `tipo_entidad` y `entidad_id`: Sobre qué elemento actuó (ej: tabla `usuarios`, fila `15`).
  * `detalles`: Un JSON con el detalle completo de qué cambió (ej: valores antes y después).
  * `ip_origen`: Desde qué dirección IP pública o local se realizó el cambio.
* **Claves Foráneas:**
  * `usuario_actor_id -> usuarios(id)` con `ON DELETE SET NULL`. Si el administrador renuncia y lo borran del sistema, el log de auditoría no se pierde; queda constancia de todo lo que hizo.

#### 12. `pagos`
* **¿Qué representa en la vida real?** El registro de transacciones comerciales de la plataforma (por ejemplo, pagos de suscripción mensual o compra de kits de hardware a través de la pasarela de PayPal).
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `empresa_id` (FK), `usuario_id` (FK), `producto_id` (FK).
  * `monto` y `moneda`: Importe cobrado (ej: `150.00` `USD`).
  * `estado`: `pendiente`, `completado`, `fallido` o `reembolsado`.
  * `metodo_pago`: Pasarela utilizada (ej: `paypal`).
  * `paypal_order_id` y `referencia_externa`: Códigos de transacción devueltos por el proveedor de pagos para conciliación bancaria.
* **Claves Foráneas:**
  * Todas usan `ON DELETE SET NULL` para cumplir con las normas contables y fiscales (los comprobantes de cobro no deben borrarse nunca).

#### 13. `sesiones`
* **¿Qué representa en la vida real?** Registro de inicios de sesión de los usuarios que entran por el navegador web o API móvil, permitiendo ver dispositivos conectados y cerrar sesiones remotas.
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `usuario_id` (FK): Usuario que inició sesión.
  * `token_hash` (UNIQUE): Token criptográfico que identifica la sesión.
  * `ip` y `user_agent`: Dirección IP y navegador/dispositivo desde el que entró.
  * `creado_en`, `ultima_actividad`, `expira_en`, `revocada_en`.
* **Claves Foráneas:**
  * `usuario_id -> usuarios(id)` con **`ON DELETE CASCADE`**. Si se elimina la cuenta de un usuario, todas sus sesiones activas se borran al instante por seguridad.

#### 14. `ci_sessions`
* **¿Qué representa en la vida real?** Es la tabla de sesiones propia del framework **CodeIgniter 4**.
* **¿Por qué existe?** Por defecto, PHP guarda las sesiones en archivos de texto temporales en el disco del servidor (`session.save_path`). Para mejorar el rendimiento, evitar problemas de permisos y permitir balanceo de carga, CodeIgniter está configurado con su driver `DatabaseHandler`, lo que hace que cada sesión web de usuario se guarde directamente en esta tabla de la base de datos (`data` en formato binario/blob e `ip_address`).

#### 15. `password_resets`
* **¿Qué representa en la vida real?** La tabla de "Olvidé mi contraseña".
* **¿Qué datos guarda?**
  * `id`: Clave primaria.
  * `usuario_id` (FK): Usuario que solicitó recuperar su cuenta.
  * `email`: Correo al que se le envió el enlace.
  * `token_hash` (UNIQUE): Token aleatorio de un solo uso que viaja en el enlace enviado por mail.
  * `expira_en` y `usado_en`: Control temporal para que el enlace expire a las pocas horas y no pueda reutilizarse.
* **Claves Foráneas:**
  * `usuario_id -> usuarios(id)` con **`ON DELETE CASCADE`**.

#### 16. `configuraciones_sistema`
* **¿Qué representa en la vida real?** Parámetros globales y variables del sistema en formato Clave-Valor.
* **¿Qué datos guarda?**
  * `clave` (UNIQUE): Identificador del ajuste (ej: `url_servidor_notificaciones`, `tiempo_gracia_heartbeat`, `limite_intentos_fallidos`).
  * `valor`: El contenido del ajuste (texto, número o JSON).
  * `tipo_valor`: Tipo de dato para que el backend lo castee correctamente (`string`, `int`, `boolean`, `json`).
  * `actualizado_por` (FK, nullable): Usuario administrador que modificó el parámetro por última vez.

---

## 4. Matriz Rápida de Claves Foráneas

| Tabla Hija | Columna FK | Tabla Padre Referenciada | Regla ON DELETE | Justificación para Defender en Examen |
| :--- | :--- | :--- | :--- | :--- |
| **`usuarios`** | `empresa_id` | `empresas(id)` | RESTRICT | Un usuario no puede existir en el aire sin pertenecer a una empresa. |
| **`usuarios`** | `rol_id` | `roles(id)` | RESTRICT | No puede haber usuarios sin privilegios ni rol asignado. |
| **`roles`** | `empresa_id` | `empresas(id)` | **SET NULL** | Si se borra la empresa, el rol personalizado puede desligarse sin destruirse. |
| **`portones`** | `empresa_id` | `empresas(id)` | RESTRICT | Cada portón pertenece a un predio de una empresa específica. |
| **`dispositivos_iot`**| `empresa_id` | `empresas(id)` | RESTRICT | La placa ESP32 pertenece a una empresa. |
| **`dispositivos_iot`**| `porton_id` | `portones(id)` | **SET NULL** | Si un portón se desmantela, la placa queda disponible para otro portón. |
| **`dispositivos_iot`**| `producto_id` | `productos(id)` | RESTRICT | La placa debe coincidir con un equipo fabricado legítimo. |
| **`dispositivos_iot`**| `vinculacion_id`| `vinculaciones_producto(id)`| RESTRICT | Trazabilidad del contrato de activación del equipo. |
| **`tarjetas_rfid`** | `usuario_id` | `usuarios(id)` | RESTRICT | Cada tarjeta activa debe tener un titular humano responsable. |
| **`eventos_acceso`** | `empresa_id` | `empresas(id)` | RESTRICT | Contexto obligatorio de a qué predio corresponde el acceso. |
| **`eventos_acceso`** | `porton_id` | `portones(id)` | **SET NULL** | Se conserva el historial de entradas aunque se retire el portón físico. |
| **`eventos_acceso`** | `dispositivo_id`| `dispositivos_iot(id)` | **SET NULL** | Se conserva el historial aunque se reemplace la placa ESP32. |
| **`eventos_acceso`** | `tarjeta_id` | `tarjetas_rfid(id)` | **SET NULL** | Se conserva el historial aunque la tarjeta física se destruya o dé de baja. |
| **`eventos_acceso`** | `usuario_id` | `usuarios(id)` | **SET NULL** | **Seguridad forense:** No se borra la evidencia de quién entró si se va de la empresa. |
| **`alertas`** | `evento_acceso_id`| `eventos_acceso(id)` | **SET NULL** | La alerta de incidente no se rompe si se depuran eventos antiguos. |
| **`alertas`** | `dispositivo_id`| `dispositivos_iot(id)` | **SET NULL** | Preservación de alertas históricas de fallas en el hardware. |
| **`alertas`** | `porton_id` | `portones(id)` | **SET NULL** | Preservación de alertas históricas del portón. |
| **`alertas`** | `reconocida_por`| `usuarios(id)` | **SET NULL** | Constancia de qué guardia atendió la alerta, aunque ya no trabaje allí. |
| **`logs_auditoria`** | `empresa_id` | `empresas(id)` | **SET NULL** | Bitácora legal que sobrevive a cambios organizacionales. |
| **`logs_auditoria`** | `usuario_actor_id`| `usuarios(id)` | **SET NULL** | Constancia inalterable de qué administrador ejecutó cada cambio. |
| **`pagos`** | `empresa_id` | `empresas(id)` | **SET NULL** | Trazabilidad impositiva y fiscal de cobros. |
| **`pagos`** | `usuario_id` | `usuarios(id)` | **SET NULL** | Trazabilidad impositiva y fiscal de cobros. |
| **`pagos`** | `producto_id` | `productos(id)` | **SET NULL** | Trazabilidad impositiva y fiscal de cobros. |
| **`sesiones`** | `usuario_id` | `usuarios(id)` | **CASCADE** | Al eliminar un usuario se destruyen todas sus sesiones web activas. |
| **`password_resets`** | `usuario_id` | `usuarios(id)` | **CASCADE** | Al eliminar un usuario se destruyen sus solicitudes de cambio de clave. |

---

## 5. Preguntas Clave para Defender la Tesis

### 1. ¿Por qué en `eventos_acceso` no usaron `ON DELETE CASCADE` para el usuario y la tarjeta?
> **Respuesta modelo:**  
> "Porque `eventos_acceso` cumple una función de **auditoría forense y seguridad legal**. Si utilizáramos borrado en cascada, al dar de baja a un empleado, alumno o residente se eliminarían automáticamente todas las entradas y salidas que hizo en el establecimiento, lo cual destruiría la evidencia histórica. Al usar `ON DELETE SET NULL`, el registro del evento permanece con su fecha y hora exactas, el portón, el resultado y el código de tarjeta leído (`uid_leido`), preservando la integridad del historial."

### 3. ¿Qué diferencia conceptual hay entre la tabla `productos` y `dispositivos_iot`?
> **Respuesta modelo:**  
> "Representan dos etapas diferentes del ciclo de vida del hardware. `productos` es el **inventario de fábrica**: la placa ESP32 recién ensamblada con su número de serie y MAC, sin dueño ni portón asignado. En cambio, `dispositivos_iot` representa la **placa en operación activa**, ya vinculada a un cliente, asociada a un portón físico, con un rol específico (lector de entrada o de salida) y reportando su estado y dirección IP en tiempo real mediante heartbeats."

### 4. ¿Qué ocurre internamente en la base de datos cuando se acerca una tarjeta al lector RFID?
> **Respuesta modelo:**  
> "El lector PN532 captura el UID físico (ej: `222BCD04`) y el ESP32 hace un `POST` a `/api/rfid/verificar` enviando la MAC del dispositivo y el UID. La API primero busca en `dispositivos_iot` para validar que la placa esté registrada y no esté en mantenimiento. Luego consulta `tarjetas_rfid` haciendo un `JOIN` con `usuarios` para validar si la tarjeta está activa y si el usuario tiene restricciones horarias vigentes para el día y hora actuales. Finalmente, registra todo el resultado en `eventos_acceso` y le responde al ESP32 si autoriza la apertura y por cuántos segundos."

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# ⚡ GUÍA COMPLETA DEL FIRMWARE: ESP32 MAIN Y ESP32 SLAVE

Esta sección complementa la base de datos explicando **cómo funciona el hardware y el código C++ en los dos microcontroladores ESP32** (`esp32_main.ino` y `esp32_slave.ino`), detallando su arquitectura, protocolos, funciones y argumentos técnicos para defender el proyecto ante los profesores.

---

## 1. ¿Por qué usamos Dos Placas ESP32? (Arquitectura Main-Slave)

En un portón automático real de un barrio, colegio o empresa, existe una limitación física fundamental:
* Se necesita un lector de tarjetas en el **exterior** (poste de entrada/acceso vehicular) y la central de control o el motor se encuentran adentro, en el **gabinete del portón**.
* Si tiráramos cables largos (de 10 o 15 metros) para comunicar el sensor RFID con el microcontrolador principal:
  1. La señal del bus de datos (SPI o I2C) se degradaría drásticamente por la resistencia del cable.
  2. Los motores de portón generan **ruido electromagnético (EMI)** severo al arrancar que induciría lecturas falsas o colgaría el lector.
* **Solución de ingeniería AutoGate:**  
  * **ESP32 SLAVE (Esclavo):** Se ubica en el pilar externo. Su único trabajo es alimentar la antena RFID exterior, leer el UID de la tarjeta y transmitirlo de forma inalámbrica ultrarrápida.
  * **ESP32 MAIN (Maestro):** Se ubica en el gabinete del portón. Recibe la lectura inalámbrica (o de su propio lector local interno), consulta la API web mediante WiFi, toma la decisión de seguridad, acciona el relé/servo continuo y le envía la respuesta de vuelta al Slave.

---

## 2. Protocolos de Comunicación y Tecnologías del Firmware

### A. Bus SPI por Software (Adafruit_PN532)
* **Pines asignados (idénticos en ambas placas):**
  * `SCK`  -> GPIO 18 (Señal de reloj / Clock).
  * `MISO` -> GPIO 19 (Master In, Slave Out: datos del sensor al ESP32).
  * `MOSI` -> GPIO 23 (Master Out, Slave In: comandos del ESP32 al sensor).
  * `SS` / `NSS` -> GPIO 27 (Slave Select: habilita la comunicación con el PN532).
* **Configuración del Sensor:** DIP Switches en modo SPI: `SET0 = 0 (OFF)` y `SET1 = 1 (ON)`.
* **¿Por qué usamos SPI y no I2C? (Pregunta fija de examen):**  
  El bus I2C utiliza solo 2 cables, pero las librerías estándar de I2C (`Wire.h`) son **bloqueantes**: si hay un falso contacto o ruido eléctrico, la función `Wire.endTransmission()` se congela esperando una respuesta y tilda todo el ESP32.  
  El bus **SPI por software** es inmune a bloqueos totales, permite definir los pines a medida, es Full-Duplex (transmite y recibe al mismo tiempo) y lee la tarjeta con una latencia significativamente menor.

---

### B. Protocolo Inalámbrico ESP-NOW
* **¿Qué es?** Es un protocolo de comunicación inalámbrica desarrollado por Espressif que opera en la banda de 2.4 GHz (la misma del WiFi), pero **en la capa de enlace de datos (Data Link Layer)**, prescindiendo de las capas superiores TCP/IP.
* **Ventajas frente a WiFi tradicional:**
  1. **Velocidad instantánea:** La transmisión toma entre **4 y 10 milisegundos**, comparado con los 150-300 ms de una petición HTTP convencional.
  2. **Independencia del router:** Main y Slave se comunican directamente placa a placa sin necesidad de que el router del colegio o barrio esté funcionando.
* **Mecanismo de Auto-Vinculación (Pairing Inteligente):**
  1. La primera vez que el Slave enciende, transmite por **Broadcast** (`FF:FF:FF:FF:FF:FF`) el mensaje reservado `"__AUTOGATE_PAIR__"`.
  2. La Main escucha el anuncio, registra la MAC del Slave como par de confianza y le responde confirmando.
  3. Ambas placas guardan la MAC del otro en su memoria no volátil (`Preferences` / NVS) en el namespace `"autogate_now"`.
  4. A partir de ese momento, todas las lecturas posteriores se envían de forma **Unicast** (punto a punto directa), optimizando el ancho de banda y la seguridad.

---

### C. Aprovisionamiento WiFi por Portal Cautivo y Memoria Flash NVS
* **¿Qué problema resuelve?** Si cambiamos de red WiFi (por ejemplo, al llevar la maqueta de la casa al colegio), no es necesario abrir el código en Arduino IDE para cambiar el SSID y la contraseña.
* **Cómo funciona:**
  1. Al arrancar, el ESP32 busca credenciales en la memoria flash interna (`Preferences` en el namespace `"autogate"`).
  2. Si no hay red guardada (o si la red guardada no responde tras 25 segundos), levanta su propio punto de acceso WiFi llamado:
     * **SSID:** `AutoGate-SETUP`
     * **Contraseña:** `autogate123`
  3. Inicia un servidor DNS (`DNSServer`) en el puerto 53 que redirige todas las peticiones a la IP `192.168.4.1`.
  4. Al conectarte con el celular, se abre automáticamente la pantalla de configuración web (`WebServer` puerto 80) donde podés ver las redes 2.4 GHz detectadas o escribirla manualmente.
  5. **Prevención de recargas:** Responde con código HTTP 200 en las rutas de detección de portales cautivos de Android e iOS (`/generate_204`, `/hotspot-detect.html`), impidiendo que el celular refresque la página y borre lo que estás escribiendo.
* **Botón de Reset de Fábrica (Boton BOOT en GPIO 0):**  
  Si mantenés apretado el botón físico `BOOT` durante **5 segundos**, la función `gestionarResetWiFiConBoot()` borra la memoria flash (`borrarCredencialesWiFi()`), emite 3 beeps de confirmación y reinicia el microcontrolador en modo portal.

---

### D. Control del Motor (Servo Continuo MG996R) y Relé
* **Relé (GPIO 4):** Se activa para accionar cerraduras electromagnéticas o simular el pulsador de contacto seco de una central de portón industrial.
* **Servo de Rotación Continua MG996R (GPIO 13):**  
  A diferencia de un servomotor estándar de 0° a 180°, el servo continuo gira en 360° indefinidamente según el ancho del pulso PWM (librería `ESP32Servo`):
  * `servoMotor.writeMicroseconds(1550)` -> **Detenido** (Punto neutro calibrado).
  * `servoMotor.writeMicroseconds(2000)` -> **Apertura** (Giro en un sentido).
  * `servoMotor.writeMicroseconds(1000)` -> **Cierre** (Giro en sentido inverso).

---

## 3. Análisis en Detalle de la Placa MAIN (`esp32_main.ino`)

La Main es el **cerebro central** del sistema. Contiene 972 líneas de código estructuradas de manera modular y no bloqueante.

### A. Estructuras de Datos Compartidas
```cpp
// Paquete que recibe la Main desde el Slave
typedef struct struct_mensaje_rfid {
  char uid[32];
} struct_mensaje_rfid;

// Paquete de respuesta que la Main envía de regreso al Slave
typedef struct struct_respuesta_rfid {
  bool autorizado;
  uint8_t tiempoApertura;
} struct_respuesta_rfid;
```

---

### B. Máquina de Estados Finitos del Portón (`enum EstadoPorton`)
Para no congelar la recepción de tarjetas ni el WiFi, el movimiento del portón se gestiona con una **máquina de estados no bloqueante** basada en `millis()`:

```
  ┌────────────────────────────────────────────────────────┐
  │                    PORTON_CERRADO                      │◄──────┐
  └──────────────────────────┬─────────────────────────────┘       │
                             │ (Acceso Autorizado)                 │
                             ▼                                     │
  ┌────────────────────────────────────────────────────────┐       │
  │                    PORTON_ABRIENDO                     │       │
  │    (Giro de apertura durante SERVO_TIEMPO_APERTURA)    │       │
  └──────────────────────────┬─────────────────────────────┘       │
                             │ (Fin del tiempo de carrera)         │
                             ▼                                     │
  ┌────────────────────────────────────────────────────────┐       │
  │                    PORTON_ABIERTO                      │       │
  │    (Espera detenido según duracionEsperaAbierto)       │       │
  └──────────────────────────┬─────────────────────────────┘       │
                             │ (Fin del tiempo de espera)          │
                             ▼                                     │
  ┌────────────────────────────────────────────────────────┐       │
  │                    PORTON_CERRANDO                     │       │
  │    (Giro de cierre durante SERVO_TIEMPO_CIERRE)        │       │
  └──────────────────────────┬─────────────────────────────┘       │
                             │                                     │
                             └─────────────────────────────────────┘
```

* **`PORTON_CERRADO`:** Estado de reposo. El servo está frenado y el relé desactivado. El lector está activo escuchando tarjetas.
* **`PORTON_ABRIENDO`:** Se activa el servo hacia adelante y el relé. Se calcula `tiempoFinMovimientoServo = millis() + 5000`.
* **`PORTON_ABIERTO`:** El servo se frena. El portón permanece abierto durante el tiempo configurado en la base de datos (por ejemplo, 5 segundos).
* **`PORTON_CERRANDO`:** El servo invierte el giro durante 5 segundos para volver a la posición de cerrado.
* **Ventaja fundamental:** Mientras el portón se mueve o espera, el ESP32 **sigue atendiendo peticiones web, enviando heartbeats y respondiendo al portal** sin usar `delay()` largos.

---

### C. Funciones Principales de la Placa Main

#### 1. `onDataRecv(macRemitente, incomingData, len)`
* **Qué hace:** Es la función de interrupción (callback) que se ejecuta en milisegundos cuando entra un paquete ESP-NOW desde el Slave.
* **Comportamiento:**
  * Si el mensaje dice `"__AUTOGATE_PAIR__"`, activa la bandera `haySolicitudVinculacion` para confirmar al Slave.
  * Si es una tarjeta, copia el UID recibido al buffer volátil `bufferUidRecibido` y pone `hayUidPendiente = true`.
  * **Importante:** No ejecuta peticiones HTTP pesadas dentro de esta función para no bloquear la pila de interrupciones del WiFi. La consulta se delega al `loop()`.

#### 2. `verificarTarjetaEnServidor(uidHex, macConsultar, macSlaveOrigen)`
* **Qué hace:** Es la función clave de enlace con la base de datos.
* **Flujo:**
  1. Verifica que haya conexión WiFi (si se cayó, intenta reconectar).
  2. Arma un JSON: `{"mac": "...", "uid": "222BCD04"}` y hace un `POST` a:  
     `http://192.168.2.160:80/tesis/public/api/rfid/verificar`
  3. Parsea la respuesta del servidor (`autorizado`, `tiempo_apertura`, `motivo`, `usuario`).
  4. **Fallback Inteligente:** Si la consulta se hizo con la MAC del Slave y la base de datos devuelve `dispositivo_no_registrado`, la función automáticamente reintenta la consulta con la MAC de la Main antes de denegar. Esto asegura que la tarjeta funcione aunque el administrador no haya dado de alta el Slave por separado en el sistema web.
  5. Si el acceso es **autorizado**:
     * Llama a `senalAccesoPermitido(tiempo)`.
     * Activa el relé y arranca el ciclo del servo.
     * Si la lectura vino del Slave, llama a `responderAlSlave(..., true, tiempo)` para que el Slave también confirme.
  6. Si es **denegado**:
     * Llama a `senalAccesoDenegado()`.
     * Emite los 3 tonos descendentes de rechazo y avisa al Slave con `autorizado = false`.

#### 3. `senalAccesoPermitido()` y `senalAccesoDenegado()`
* **Qué hacen:** Modulan el Buzzer en GPIO 15 generando frecuencias sonoras con `tonoFrecuencia(frecuenciaHz, duracionMs)`:
  * **Autorizado:** Tono alegre ascendente (1800 Hz durante 110ms + 2600 Hz durante 260ms) y enciende LED verde.
  * **Denegado:** Tono triple descendente de alerta (1100 Hz -> 700 Hz -> 380 Hz) y enciende LED rojo.

#### 4. `enviarHeartbeat()`
* **Qué hace:** Cada 60 segundos (`INTERVALO_HEARTBEAT`), envía un `POST` al endpoint `/api/dispositivos/heartbeat` con su MAC.
* **Propósito:** Informar a la base de datos que la placa está viva (`en_linea`) y actualizar su IP local en la tabla `dispositivos_iot`.

---

## 4. Análisis en Detalle de la Placa SLAVE (`esp32_slave.ino`)

La Slave tiene un código más liviano (699 líneas) optimizado para ser un **nodo periférico de lectura rápida**.

### A. Funciones Principales de la Placa Slave

#### 1. `setup()`
* Inicializa el sensor PN532 mediante Software SPI (pines 18, 19, 23, 27).
* Lee la MAC física del microcontrolador con `esp_read_mac()`.
* Carga la MAC de la Main asociada desde la memoria flash NVS con `cargarMainAsociada()`.
* Si ya conoce a la Main, la registra como peer de ESP-NOW directo; si no, lanza la solicitud de vinculación broadcast (`enviarSolicitudVinculacionMain()`).

#### 2. `loop()`
* Gestiona el portal cautivo y el botón `BOOT` por si se necesita cambiarle el WiFi.
* Envía su propio heartbeat para figurar como dispositivo en línea en el mapa web.
* Ejecuta `nfc.readPassiveTargetID()` con timeout corto (500ms):
  * Cuando detecta una tarjeta, aplica un debounce de 2 segundos (`DEBOUNCE_LECTURA = 2000`) para no enviar 10 veces la misma tarjeta si el usuario la deja apoyada.
  * Convierte los bytes del UID a formato hexadecimal en mayúsculas (ej: `222BCD04`).
  * Llama a `enviarUidAMain(uidHex)` a través de ESP-NOW.

#### 3. `enviarUidAMain(String uidHex)`
* Empaqueta el UID en un `struct_mensaje_rfid`.
* Lo envía directamente a la dirección MAC de la Main con `esp_now_send()`.
* Muestra en el Monitor Serie:  
  `[ESP-NOW] Enviando UID a MAIN -> 222BCD04`  
  `[ESP-NOW] ✔️ UID transmitido a la MAIN!`

#### 4. `onDataRecv()` en el Slave
* Cuando la Main termina de consultar la API en el servidor, le envía al Slave la estructura `struct_respuesta_rfid`.
* El Slave recibe el resultado:
  * Si `autorizado == true`: Imprime `[SLAVE] ✅ Acceso autorizado confirmado por Main`.
  * Si `autorizado == false`: Imprime `[SLAVE] ❌ Acceso denegado confirmado por Main`.

---

## 5. El Camino Completo de una Tarjeta (Flujo Integral de Punta a Punta)

Este es el recorrido exacto para explicar frente al pizarrón o diapositiva:

```
 [TARJETA RFID]
       │
       ▼ (1) Lectura magnética 13.56 MHz
 [ESP32 SLAVE (Pilar Exterior)]
       │
       ▼ (2) Trama inalámbrica ESP-NOW (~6 ms)
 [ESP32 MAIN (Gabinete Portón)]
       │
       ▼ (3) HTTP POST /api/rfid/verificar vía WiFi
 [SERVIDOR APACHE / CODEIGNITER 4]
       │
       ▼ (4) Consulta SQL con JOIN a `tarjetas_rfid` y `usuarios`
 [BASE DE DATOS MYSQL (InnoDB)]
       │
       ▲ (5) Valida: Tarjeta activa + Horario válido + Portón operativo
 [SERVIDOR API]
       │
       ▼ (6) HTTP 200 JSON { "autorizado": true, "tiempo_apertura": 5 }
 [ESP32 MAIN]
       ├──► (7a) Abre Relé (GPIO 4) + Gira Servo MG996R (GPIO 13)
       ├──► (7b) Melodía de éxito en Buzzer (GPIO 15) + LED Verde
       └──► (7c) Trama ESP-NOW de confirmación al SLAVE
                  │
                  ▼
            [ESP32 SLAVE] (Recibe confirmación y finaliza ciclo)
```

---

## 6. Preguntas Típicas de Examen sobre el Hardware y Firmware

### ❓ 1. ¿Qué pasa si se corta el suministro de Internet exterior?
> **Respuesta:**  
> "El sistema sigue funcionando al 100% de manera local. La placa Main consulta a la IP local del servidor XAMPP en la red interna (`192.168.2.160`) y la comunicación entre Main y Slave ocurre por ESP-NOW sin cables. No se requiere conexión a internet hacia la nube para que el portón abra; únicamente se necesita que el router local o switch mantenga la red de área local (LAN) activa."

### ❓ 2. ¿Cómo evitaron que la lectura continua de tarjetas congele el microcontrolador?
> **Respuesta:**  
> "Utilizamos un escaneo con timeout ultra corto (40 milisegundos en la Main mediante `nfc.readPassiveTargetID(..., 40)`). Esto hace que si no hay una tarjeta presente, la función devuelve el control de inmediato al `loop()`, permitiendo que el WiFi, el portal cautivo y el servo continúen ejecutándose sin interrupciones ni trabas perceptibles."

### ❓ 3. ¿Por qué en el `setup()` tienen la línea `WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);`?
> **Respuesta:**  
> "Es la desactivación del detector de Brownout (caída de tensión momentánea). Cuando el ESP32 enciende el transmisor de radio WiFi o cuando el servomotor MG996R arranca bruscamente, se produce un pico de consumo de corriente que puede provocar una micro-caída de milivoltios en la línea de 3.3V/5V. Sin esa instrucción, el ESP32 interpretaría esa pequeña fluctuación como una falla crítica de energía y se reiniciaría en bucle. Desactivándolo, el sistema se mantiene completamente estable ante picos de carga inductiva del motor."

### ❓ 4. ¿Por qué usan ESP-NOW en lugar de hacer que ambas placas se conecten por HTTP al servidor web por separado?
> **Respuesta:**  
> "Por tres razones técnicas:  
> 1. **Latencia:** ESP-NOW transmite en 5 milisegundos; hacer dos peticiones HTTP independientes a través del router tardaría más de 400 milisegundos.  
> 2. **Sincronización:** Si el Slave consultara a la web por su cuenta, el servidor tendría que notificar a la Main mediante WebSockets o sondeo (polling), lo cual sobrecarga el servidor. Con ESP-NOW, la Main concentra la toma de decisiones y acciona los motores directamente.  
> 3. **Robustez:** Si el router WiFi se satura o cae momentáneamente, las dos placas siguen enlazadas entre sí."
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# 🌐 GUÍA DEFINITIVA DE DESARROLLO WEB (CODEIGNITER 4): CÓMO HACER UN BOTÓN QUE REDIRECCIONE A OTRA VISTA

> **OBJETIVO DE ESTA SECCIÓN:**  
> En una mesa de examen o defensa de tesis, es una pregunta clásica de los profesores pedirte:  
> *"Parate en la computadora o en el pizarrón y mostrame cómo hacés un botón para ir de una pantalla a otra en tu sistema. Explicame línea por línea qué hace cada parte tanto en el frontend como en el backend"*.  
> Siguiendo esta guía paso a paso **no tenés ningún margen de error**.

---

## 1. Conceptos Básicos Fundamentales (Para no dudar)

Antes de tocar código, tenés que tener claros estos 3 términos del patrón **MVC (Modelo - Vista - Controlador)**:

1. **La Vista (`app/Views/`):** Es el archivo con extensión `.php` que contiene el código visual: **HTML, CSS y JavaScript**. Es lo que el usuario ve en su pantalla (los textos, tablas, colores y botones).
2. **La Ruta (`app/Config/Routes.php`):** Es el **mapa de direcciones** del sistema. Le dice al servidor: *"Cuando el navegador pida la URL `/usuarios`, ejecutá tal función en tal controlador"*.
3. **El Controlador (`app/Controllers/`):** Es el **cerebro o intermediario**. Recibe la orden del navegador, decide si tiene que consultar la base de datos y finalmente decide qué vista poner en pantalla mediante la función `return view('nombre_vista')`.

> ⚠️ **REGLA DE ORO DE MVC:**  
> **Un botón NUNCA apunta directamente a un archivo de vista** (por ejemplo, nunca se pone `href="usuarios.php"`). En un framework profesional como CodeIgniter 4, **todo pasa obligatoriamente por una Ruta y un Controlador**.

---

## 2. El Flujo Completo de un "Click" (Explicado paso a paso)

Cuando un usuario hace click en un botón para cambiar de pantalla, ocurre este ciclo exacto de 5 pasos:

```
 [1. NAVEGADOR] El usuario hace click en el botón en la Vista actual (ej: panel.php).
       │
       ▼
 [2. PETICIÓN HTTP GET] El navegador solicita la URL: `http://localhost/tesis/public/usuarios`
       │
       ▼
 [3. ROUTER (app/Config/Routes.php)]
     El framework busca a quién le toca atender esa dirección:
     `$routes->get('usuarios', 'UsuarioController::usuarios');`
       │
       ▼
 [4. CONTROLADOR (app/Controllers/UsuarioController.php)]
     Se ejecuta el método `public function usuarios()`:
     - Consulta la base de datos mediante el Modelo (si hace falta).
     - Prepara los datos en un array `$data`.
     - Ejecuta: `return view('usuarios', $data);`
       │
       ▼
 [5. RESPUESTA AL NAVEGADOR]
     El servidor compila el HTML final y el navegador renderiza la nueva pantalla `usuarios.php`.
```

---

## 3. Las 3 Formas de Programar el Botón (con código exacto)

### 🥇 FORMA 1: Enlace `<a>` estilizado como Botón (La forma correcta y estándar de la Web)

Esta es la forma que se utiliza en el 90% de los casos en AutoGate (por ejemplo, en el menú superior y en las tarjetas de acceso del archivo `app/Views/panel.php`).

#### Código exacto:
```html
<a href="<?= base_url('usuarios') ?>" class="btn btn-primary">
    Ver Listado de Usuarios
</a>
```

#### 🔬 Desglose anatómico línea por línea (por si te piden explicar cada palabra):
* `<a`: Abre la etiqueta de hipervínculo nativa de HTML.
* `href="..."`: (*Hypertext Reference*) Especifica la URL de destino hacia donde debe navegar el navegador.
* `<?=`: Es la etiqueta corta de PHP (Short Echo Tag). Equivale exactamente a escribir `<?php echo`.
* `base_url('usuarios')`: **Función helper nativa de CodeIgniter 4**. Concatena la dirección raíz de tu proyecto (configurada en `app/Config/App.php`) con la ruta `'usuarios'`.
  * Si estás en tu máquina local genera: `http://localhost/tesis/public/usuarios`
  * Si estás conectado por la red del colegio genera: `http://192.168.2.160/tesis/public/usuarios`
  * Si mañana lo subís a internet genera: `https://miautogate.com/usuarios`
* `class="btn btn-primary"`: Clases de CSS. Hacen que el enlace visualmente no parezca un texto subrayado, sino un **botón moderno** con color azul, esquinas redondeadas, relleno (*padding*) y efecto de sombra al pasar el cursor.
* `Ver Listado de Usuarios`: El texto legible que ve el usuario.
* `</a>`: Cierre de la etiqueta de hipervínculo.

---

### 🥈 FORMA 2: Etiqueta `<button>` accionada con JavaScript (`window.location.href`)

Se utiliza cuando necesitás que el botón sea un `<button>` de HTML pero que redirija mediante código JavaScript (por ejemplo, si antes de redirigir querés mostrar una alerta de confirmación o validar algo).

#### Opción A: Directamente con el evento `onclick` en línea
```html
<button type="button" class="btn btn-secondary" onclick="window.location.href='<?= base_url('tarjetas') ?>'">
    Ir a Tarjetas RFID
</button>
```
* `type="button"`: Le avisa al navegador que es un botón genérico (no envía ningún formulario).
* `onclick="..."`: Evento de JavaScript que se dispara al hacer click.
* `window.location.href = '...'`: Propiedad de JavaScript que le ordena al navegador cambiar la URL actual por la nueva dirección.

#### Opción B: Con un escuchador de eventos (*Event Listener*) en un archivo `.js`
En el HTML de tu vista ponés el botón con un `id` único:
```html
<button type="button" id="btnIrDispositivos" class="btn btn-success">
    Configurar Dispositivos
</button>
```

Y en tu archivo JavaScript (`public/js/...`) o al final de la vista dentro de `<script>`:
```javascript
document.getElementById('btnIrDispositivos').addEventListener('click', function() {
    // Redirige al usuario
    window.location.href = '<?= base_url('dispositivos') ?>';
});
```

---

### 🥉 FORMA 3: Botón dentro de un Formulario HTML (`<form>`)

Se utiliza cuando la redirección **necesita enviar información hacia el servidor** (por ejemplo, una barra de búsqueda, un filtro de fechas o un formulario de datos).

```html
<!-- Formulario con método GET para navegar enviando parámetros en la URL -->
<form action="<?= base_url('usuarios') ?>" method="get">
    <input type="text" name="buscar" placeholder="Buscar por nombre...">
    <button type="submit" class="btn btn-primary">
        Buscar y Ver Resultados
    </button>
</form>
```
* `action="<?= base_url('usuarios') ?>"`: Dirección a la que se envían los datos.
* `method="get"`: Los datos viajan visibles en la URL (ej: `/usuarios?buscar=Facundo`).
* `type="submit"`: Este botón sí envía el formulario y dispara la navegación.

---

## 4. Ejercicio Práctico "En Vivo": Cómo agregar un botón y una vista desde cero

Si en la mesa de examen el profesor te dice:  
*"Quiero que agregues un botón en el Panel que me lleve a una pantalla nueva llamada 'Reportes'"*.

Estos son los **4 pasos exactos** que tenés que realizar:

### Paso 1: Crear la nueva Vista HTML
Creás un archivo nuevo en: `app/Views/reportes.php`
```php
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>AutoGate | Reportes</title>
</head>
<body>
    <h1>Pantalla de Reportes de Acceso</h1>
    <p>Bienvenido al módulo de reportes.</p>
    <!-- Botón para volver al panel -->
    <a href="<?= base_url('panel') ?>">Volver al Panel</a>
</body>
</html>
```

### Paso 2: Declarar la Ruta en el Router
Abrís el archivo `app/Config/Routes.php` y agregás esta línea:
```php
$routes->get('reportes', 'DashboardController::reportes');
```
* *Traducción:* "Cuando alguien pida la URL `/reportes` por método `GET`, ejecutá el método `reportes()` dentro de `DashboardController`".

### Paso 3: Crear el Método en el Controlador
Abrís el archivo `app/Controllers/DashboardController.php` y agregás la función:
```php
public function reportes()
{
    // Retorna y renderiza el archivo app/Views/reportes.php
    return view('reportes');
}
```

### Paso 4: Colocar el Botón en la pantalla de origen
En la vista donde querés que aparezca el botón (por ejemplo, en `app/Views/panel.php`), agregás:
```html
<a href="<?= base_url('reportes') ?>" class="btn btn-info">
    Ir a Reportes
</a>
```

¡Listo! Al hacer click en el botón en `panel.php`, el navegador viajará a `/reportes` y se abrirá la nueva pantalla sin ningún error.

---

## 5. Diferencia Crucial: `return view()` vs `return redirect()->to()`

Esta es una pregunta conceptual clásica que le hacen a los alumnos para saber si realmente entienden la diferencia entre **mostrar una vista** y **redireccionar**.

| Característica | `return view('nombre_vista')` | `return redirect()->to(base_url('ruta'))` |
| :--- | :--- | :--- |
| **¿Qué hace?** | Carga y dibuja el archivo HTML directamente en la respuesta actual. | Le ordena al navegador que haga una **nueva petición HTTP** a otra URL. |
| **¿Cambia la URL del navegador?** | **NO.** La URL en la barra de direcciones sigue siendo la misma. | **SÍ.** La barra de direcciones cambia a la nueva URL. |
| **¿Cuándo se usa?** | Al inicio, cuando el usuario simplemente quiere entrar a ver una pantalla (ej: ver el dashboard o el listado de tarjetas). | **Después de procesar un formulario** (ej: después de iniciar sesión, guardar un usuario o borrar una tarjeta). |
| **Patrón de diseño:** | Renderizado directo. | **Post-Redirect-Get (PRG)**: Evita que si el usuario aprieta F5 se reenvíe el formulario y se duplique un registro en la base de datos. |

#### Ejemplo de `redirect()` en el controlador:
```php
public function guardarUsuario()
{
    // 1. Guardamos los datos en la base de datos...
    $this->usuarioModel->insert([ ... ]);

    // 2. REDIRECCIONAMOS con un mensaje flash de éxito:
    return redirect()->to(base_url('usuarios'))->with('mensaje', 'Usuario guardado con éxito');
}
```

---

## 6. Preguntas Trampa del Tribunal de Examen (Con respuestas modelo)

### ❓ 1. "¿Por qué no pones directamente `<a href="usuarios.php">` en el botón?"
> **Respuesta:**  
> "Porque nuestro sistema está construido bajo el patrón de arquitectura **MVC (Modelo-Vista-Controlador)**. En este patrón, las vistas no son archivos accesibles de forma directa desde la web por motivos de seguridad y organización. Si pusiéramos `usuarios.php`, el servidor ignoraría la lógica del framework: no se validarían las sesiones de usuario, no se consultarían los modelos de datos y el archivo daría error por no tener las variables que le inyecta el controlador."

### ❓ 2. "¿Qué pasa si en el botón pongo `href="/usuarios"` en vez de `href="<?= base_url('usuarios') ?>"`?"
> **Respuesta:**  
> "Si ponemos `href="/usuarios"`, el navegador buscará la ruta en la raíz del servidor web (`http://localhost/usuarios`). Pero en entornos locales de XAMPP, el proyecto se encuentra dentro de una subcarpeta (`http://localhost/tesis/public/usuarios`). Por lo tanto, el botón arrojaría un error **404 Not Found**. El helper `base_url()` garantiza portabilidad absoluta: concatena automáticamente la ruta base configurada sin importar en qué subcarpeta o IP esté corriendo el proyecto."

### ❓ 3. "¿Qué diferencia técnica hay entre usar `<a class="btn">` y `<button>` para cambiar de pantalla?"
> **Respuesta:**  
> "La diferencia radica en la **semántica de HTML5**:  
> * Las etiquetas `<a>` (*anchor*) representan hipervínculos cuya función nativa es navegar entre recursos o URLs distintas mediante peticiones HTTP `GET`.  
> * Las etiquetas `<button>` están concebidas para ejecutar acciones o comportamientos dentro del documento actual (como disparar una función JavaScript, abrir un modal emergente o enviar un formulario por método `POST`).  
> Al aplicarle estilos CSS (`class="btn"`), un enlace `<a>` se visualiza exactamente como un botón pero mantiene la navegación nativa del navegador sin requerir código JavaScript adicional."

### ❓ 4. "¿Qué ocurre si creas el botón y el controlador, pero te olvidas de escribir la línea en `app/Config/Routes.php`?"
> **Respuesta:**  
> "Al hacer click en el botón, el framework CodeIgniter 4 intercepta la URL solicitada, revisa su tabla de rutas y, al no encontrar ninguna coincidencia registrada para esa dirección, lanza una excepción `PageNotFoundException` con código de estado HTTP **404 Not Found** (Página no encontrada)."