
DROP SCHEMA IF EXISTS pascualina CASCADE;
CREATE SCHEMA pascualina;
SET search_path TO pascualina;

-- ---------------------------- CATALOGOS ------------------------------
CREATE TABLE rol (
  id_rol INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo'))
);
CREATE TABLE tipo_usuario (
  id_tipo_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo'))
);
CREATE TABLE tipo_servicio (
  id_tipo_servicio INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo'))
);
CREATE TABLE tipo_producto (
  id_tipo_producto INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo'))
);
CREATE TABLE tipo_evento (
  id_tipo_evento INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo'))
);
CREATE TABLE tipo_reaccion (
  id_tipo_reaccion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT
);
CREATE TABLE tipo_notificacion (
  id_tipo_notificacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT
);
CREATE TABLE tipo_denuncia (
  id_tipo_denuncia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT
);

-- ----------------------------- USUARIOS ------------------------------
CREATE TABLE usuario (
  id_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_rol INTEGER NOT NULL,
  id_tipo_usuario INTEGER NOT NULL,
  nombres VARCHAR(50) NOT NULL,
  apellidos VARCHAR(50) NOT NULL,
  correo VARCHAR(255) NOT NULL UNIQUE CHECK (correo LIKE '%_@_%._%'),
  contrasena VARCHAR(255) NOT NULL,           -- guardar HASH, nunca texto plano
  telefono VARCHAR(20) NOT NULL UNIQUE,
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(30) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo','Suspendido')),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol (id_rol) ON DELETE RESTRICT,
  CONSTRAINT fk_usuario_tipo_usuario FOREIGN KEY (id_tipo_usuario)
    REFERENCES tipo_usuario (id_tipo_usuario) ON DELETE RESTRICT
);
CREATE TABLE perfil (
  id_perfil INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL UNIQUE,
  informacion JSONB,
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_perfil_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE
);

-- ----------------------------- CONTENIDO -----------------------------
CREATE TABLE publicacion (
  id_publicacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,
  contenido TEXT NOT NULL,
  tipo_contenido VARCHAR(20) NOT NULL DEFAULT 'Texto'
    CHECK (tipo_contenido IN ('Texto','Imagen','Video','Enlace','Archivo')),
  fecha_publicacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_publicacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE RESTRICT
);
CREATE TABLE comentario (
  id_comentario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_publicacion INTEGER NOT NULL,            -- publicacion comentada
  id_usuario INTEGER NOT NULL,                -- usuario que COMENTA (no el autor)
  contenido TEXT NOT NULL,
  fecha_comentario TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_comentario_publicacion FOREIGN KEY (id_publicacion)
    REFERENCES publicacion (id_publicacion) ON DELETE CASCADE,
  CONSTRAINT fk_comentario_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario) ON DELETE RESTRICT
);
CREATE TABLE reaccion (
  id_reaccion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,
  id_publicacion INTEGER NOT NULL,
  id_tipo_reaccion INTEGER NOT NULL,
  fecha_reaccion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reaccion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_reaccion_publicacion FOREIGN KEY (id_publicacion)
    REFERENCES publicacion (id_publicacion) ON DELETE CASCADE,
  CONSTRAINT fk_reaccion_tipo FOREIGN KEY (id_tipo_reaccion)
    REFERENCES tipo_reaccion (id_tipo_reaccion) ON DELETE RESTRICT,
  CONSTRAINT uq_reaccion_usuario_publicacion UNIQUE (id_usuario, id_publicacion)
);
CREATE TABLE grupo (
  id_grupo INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario_creador INTEGER NOT NULL,
  id_perfil INTEGER NOT NULL,                 -- "Perfil" asociado al grupo
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT,
  categoria VARCHAR(30),
  privacidad VARCHAR(30) NOT NULL DEFAULT 'Publico' CHECK (privacidad IN ('Publico','Privado','Secreto')),
  fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(30) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Inactivo')),
  CONSTRAINT fk_grupo_usuario_creador FOREIGN KEY (id_usuario_creador)
    REFERENCES usuario (id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_grupo_perfil FOREIGN KEY (id_perfil) REFERENCES perfil (id_perfil) ON DELETE RESTRICT
);

CREATE TABLE grupo_usuario (
  id_grupo_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_grupo INTEGER NOT NULL,
  id_usuario INTEGER NOT NULL,
  rol_en_grupo VARCHAR(20) NOT NULL DEFAULT 'Miembro'
    CHECK (rol_en_grupo IN ('Administrador','Moderador','Miembro')),
  fecha_ingreso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Pendiente','Activo','Retirado')),
  CONSTRAINT fk_gu_grupo FOREIGN KEY (id_grupo) REFERENCES grupo (id_grupo) ON DELETE CASCADE,
  CONSTRAINT fk_gu_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT uq_grupo_usuario UNIQUE (id_grupo, id_usuario)
);

-- ------------------------ SERVICIOS Y PRODUCTOS ----------------------
CREATE TABLE servicio (
  id_servicio INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- quien OFRECE el servicio
  id_tipo_servicio INTEGER NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT,
  precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
  duracion_minutos INTEGER CHECK (duracion_minutos > 0),
  ubicacion VARCHAR(100),
  fecha_publicacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_servicio_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_servicio_tipo_servicio FOREIGN KEY (id_tipo_servicio)
    REFERENCES tipo_servicio (id_tipo_servicio) ON DELETE RESTRICT
);
CREATE TABLE producto (
  id_producto INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- quien VENDE
  id_tipo_producto INTEGER NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT,
  precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
  cantidad INTEGER NOT NULL CHECK (cantidad >= 0),
  estado VARCHAR(30) NOT NULL DEFAULT 'Disponible' CHECK (estado IN ('Disponible','Vendido')),
  fecha_publicacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_producto_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_producto_tipo_producto FOREIGN KEY (id_tipo_producto)
    REFERENCES tipo_producto (id_tipo_producto) ON DELETE RESTRICT
);
CREATE TABLE servicio_solicitud (
  id_solicitud INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- quien SOLICITA
  id_servicio INTEGER NOT NULL,
  fecha_solicitud TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente'
    CHECK (estado IN ('Pendiente','Aceptada','Rechazada','Completada')),
  CONSTRAINT fk_servicio_solicitud_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_servicio_solicitud_servicio FOREIGN KEY (id_servicio)
    REFERENCES servicio (id_servicio) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX uq_solicitud_servicio_pendiente
  ON servicio_solicitud (id_usuario, id_servicio) WHERE estado = 'Pendiente';
CREATE TABLE producto_transaccion (
  id_adquisicion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- quien COMPRA
  id_producto INTEGER NOT NULL,
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),  -- precio al momento de la compra
  fecha_adquisicion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_producto_transaccion_usuario FOREIGN KEY (id_usuario)
    REFERENCES usuario (id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_producto_transaccion_producto FOREIGN KEY (id_producto)
    REFERENCES producto (id_producto) ON DELETE RESTRICT
);

-- ------------------------------ EVENTOS ------------------------------
CREATE TABLE evento (
  id_evento INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- ORGANIZADOR
  id_tipo_evento INTEGER NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  descripcion TEXT,
  fecha TIMESTAMP NOT NULL,
  lugar VARCHAR(50),
  estado VARCHAR(30) NOT NULL DEFAULT 'Activo' CHECK (estado IN ('Activo','Cancelado')),
  CONSTRAINT fk_evento_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE RESTRICT,
  CONSTRAINT fk_evento_tipo_evento FOREIGN KEY (id_tipo_evento)
    REFERENCES tipo_evento (id_tipo_evento) ON DELETE RESTRICT
);

CREATE TABLE evento_usuario (
  id_evento_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_evento INTEGER NOT NULL,
  id_usuario INTEGER NOT NULL,
  fecha_inscripcion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(20) NOT NULL DEFAULT 'Inscrito'
    CHECK (estado IN ('Inscrito','Asistio','No asistio','Cancelo')),
  calificacion SMALLINT CHECK (calificacion BETWEEN 1 AND 5),
  me_gusta BOOLEAN NOT NULL DEFAULT FALSE,
  comentario TEXT,
  fecha_comentario TIMESTAMP,
  CONSTRAINT fk_eu_evento FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON DELETE CASCADE,
  CONSTRAINT fk_eu_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT uq_evento_usuario UNIQUE (id_evento, id_usuario),
  CONSTRAINT ck_eu_comentario_fecha CHECK ((comentario IS NULL) = (fecha_comentario IS NULL))
);

-- ------------------------ INTERACCION SOCIAL -------------------------
CREATE TABLE notificacion (
  id_notificacion INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- destinatario
  id_usuario_creador INTEGER,                
  id_tipo_notificacion INTEGER NOT NULL,
  mensaje TEXT NOT NULL,
  fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_notificacion_creador FOREIGN KEY (id_usuario_creador)
    REFERENCES usuario (id_usuario) ON DELETE SET NULL,
  CONSTRAINT fk_notificacion_tipo FOREIGN KEY (id_tipo_notificacion)
    REFERENCES tipo_notificacion (id_tipo_notificacion) ON DELETE RESTRICT
);
CREATE TABLE solicitud_amistad (
  id_solicitud INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario_emisor INTEGER NOT NULL,
  id_usuario_receptor INTEGER NOT NULL,
  fecha_solicitud TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente' CHECK (estado IN ('Pendiente','Aceptada','Rechazada')),
  CONSTRAINT fk_amistad_emisor FOREIGN KEY (id_usuario_emisor) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_amistad_receptor FOREIGN KEY (id_usuario_receptor) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT ck_amistad_distintos CHECK (id_usuario_emisor <> id_usuario_receptor)
);

CREATE UNIQUE INDEX uq_amistad_pareja
  ON solicitud_amistad (LEAST(id_usuario_emisor, id_usuario_receptor),
                        GREATEST(id_usuario_emisor, id_usuario_receptor));
CREATE TABLE mensaje_chat (
  id_mensaje INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario_emisor INTEGER NOT NULL,
  id_usuario_receptor INTEGER NOT NULL,
  contenido TEXT NOT NULL,
  tipo_contenido VARCHAR(30) NOT NULL DEFAULT 'Texto' CHECK (tipo_contenido IN ('Texto','Imagen','Archivo')),
  fecha_envio TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_lectura TIMESTAMP,                    -- NULL = sin leer
  CONSTRAINT fk_mensaje_emisor FOREIGN KEY (id_usuario_emisor) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_mensaje_receptor FOREIGN KEY (id_usuario_receptor) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT ck_mensaje_distintos CHECK (id_usuario_emisor <> id_usuario_receptor),
  CONSTRAINT ck_mensaje_lectura CHECK (fecha_lectura IS NULL OR fecha_lectura >= fecha_envio)
);
CREATE TABLE denuncia (
  id_denuncia INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_usuario INTEGER NOT NULL,                -- quien denuncia
  id_publicacion INTEGER NOT NULL,
  id_tipo_denuncia INTEGER NOT NULL,
  evidencia TEXT,
  fecha_reporte TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  estado VARCHAR(30) NOT NULL DEFAULT 'Pendiente' CHECK (estado IN ('Pendiente','Revisada','Cerrada')),
  accion_tomada TEXT,
  CONSTRAINT fk_denuncia_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE,
  CONSTRAINT fk_denuncia_publicacion FOREIGN KEY (id_publicacion)
    REFERENCES publicacion (id_publicacion) ON DELETE CASCADE,
  CONSTRAINT fk_denuncia_tipo FOREIGN KEY (id_tipo_denuncia)
    REFERENCES tipo_denuncia (id_tipo_denuncia) ON DELETE RESTRICT,
  CONSTRAINT uq_denuncia_usuario_publicacion UNIQUE (id_usuario, id_publicacion)
);

-- ------------------------------ INDICES ------------------------------
CREATE INDEX ix_usuario_rol ON usuario (id_rol);
CREATE INDEX ix_usuario_tipo ON usuario (id_tipo_usuario);
CREATE INDEX ix_publicacion_usuario ON publicacion (id_usuario);
CREATE INDEX ix_publicacion_fecha ON publicacion (fecha_publicacion DESC);
CREATE INDEX ix_comentario_pub ON comentario (id_publicacion);
CREATE INDEX ix_comentario_usuario ON comentario (id_usuario);
CREATE INDEX ix_reaccion_pub ON reaccion (id_publicacion);
CREATE INDEX ix_grupo_creador ON grupo (id_usuario_creador);
CREATE INDEX ix_grupo_usuario_user ON grupo_usuario (id_usuario);
CREATE INDEX ix_servicio_usuario ON servicio (id_usuario);
CREATE INDEX ix_servicio_tipo ON servicio (id_tipo_servicio);
CREATE INDEX ix_producto_usuario ON producto (id_usuario);
CREATE INDEX ix_producto_tipo ON producto (id_tipo_producto);
CREATE INDEX ix_ss_servicio ON servicio_solicitud (id_servicio);
CREATE INDEX ix_pt_producto ON producto_transaccion (id_producto);
CREATE INDEX ix_pt_usuario ON producto_transaccion (id_usuario);
CREATE INDEX ix_evento_usuario ON evento (id_usuario);
CREATE INDEX ix_evento_tipo ON evento (id_tipo_evento);
CREATE INDEX ix_eu_usuario ON evento_usuario (id_usuario);
CREATE INDEX ix_notif_usuario ON notificacion (id_usuario);
CREATE INDEX ix_mensaje_receptor ON mensaje_chat (id_usuario_receptor);
CREATE INDEX ix_denuncia_pub ON denuncia (id_publicacion);
CREATE INDEX ix_perfil_info_gin ON perfil USING GIN (informacion);

SET search_path TO pascualina;

INSERT INTO rol (nombre, descripcion) VALUES
  ('Administrador','Tiene acceso a todos los elementos de la base de datos de manera irrestricta'),
  ('Auxiliar','Tiene acceso al BackOffice de manera limitada'),
  ('Miembro','Es miembro de la Red Social. Puede publicar, generar eventos, vender/comprar productos y vender/consumir servicios; puede tener restricciones segun el tipo de usuario'),
  ('Visitante','Puede acceder a la Red Social pero no puede interactuar de ninguna forma');

INSERT INTO tipo_usuario (nombre, descripcion) VALUES
  ('Estudiante',NULL),('Docente',NULL),('Egresado',NULL),('Empleado',NULL),
  ('Empresario',NULL),('Ex-Empleado',NULL),('Ex-Estudiante',NULL),('Ex-Docente',NULL),
  ('Guess','Usuario amigo de la Red Social con algunas limitaciones');

INSERT INTO tipo_servicio (nombre, descripcion) VALUES
  ('Asesoría académica',NULL),('Asesoría Laboral',NULL),('Curso Tecnológico',NULL),
  ('Mantenimiento Moto',NULL),('Reparación artículo electrónico',NULL),('Corte de Cabello',NULL),
  ('Manicure y Pedicure',NULL),('Reparación PC',NULL),('Masaje terapéutico',NULL),
  ('Declaración de impuestos',NULL),('Asesoría Trabajo de Grado',NULL),('Viaje turístico',NULL),
  ('Transporte',NULL),('Elaboración de Dulces',NULL),('Reparación de Calzado',NULL),
  ('Confección vestimenta',NULL),('Organización evento',NULL),
  ('Fotografía y video','Nuevo: propuesto por el equipo'),
  ('Diseño gráfico','Nuevo: propuesto por el equipo'),
  ('Clases de idiomas','Nuevo: propuesto por el equipo');

INSERT INTO tipo_producto (nombre, descripcion) VALUES
  ('Libro',NULL),('Motocicleta',NULL),('Vehículo',NULL),('Almuerzo',NULL),('Desayuno',NULL),
  ('Ropa',NULL),('Cosméticos',NULL),('Ticket de Concierto',NULL),('Bolso',NULL),('Zapato',NULL),
  ('Postres',NULL),('Dulces',NULL),('Patineta Eléctrica',NULL),('Teléfono móvil',NULL),
  ('Computador',NULL),('Artículo Deportivo',NULL),('Alimentos','Arroz, Pasta, entre otros'),
  ('Electrodoméstico','Nuevo: propuesto por el equipo'),
  ('Instrumento musical','Nuevo: propuesto por el equipo'),
  ('Accesorio tecnológico','Nuevo: propuesto por el equipo');

INSERT INTO tipo_evento (nombre, descripcion) VALUES
  ('Congreso',NULL),('Conferencia',NULL),('Taller',NULL),('Baile',NULL),('Fiesta',NULL),
  ('Conformación de Grupo',NULL),('Viaje Turístico',NULL),('Concierto musical',NULL),
  ('Reunión Semillero',NULL),('Feria de comida',NULL),('Feria de ropa',NULL),('Paseo en moto',NULL),
  ('Feria Tecnológica',NULL),('Cine - Película',NULL),('Reunión grupo interés',NULL),
  ('Entrevista laboral',NULL),('Matrimonio',NULL),
  ('Torneo deportivo','Nuevo: propuesto por el equipo'),
  ('Feria de emprendimiento','Nuevo: propuesto por el equipo'),
  ('Hackatón','Nuevo: propuesto por el equipo');

INSERT INTO tipo_reaccion (nombre, descripcion) VALUES
  ('Me gusta','Aprobación'),('Me encanta','Gran aprobación'),('Me divierte','Gracioso'),
  ('Me entristece','Tristeza'),('Me asombra','Sorpresa');
INSERT INTO tipo_notificacion (nombre, descripcion) VALUES
  ('Comentario','Alguien comentó tu publicación'),('Reacción','Alguien reaccionó a tu publicación'),
  ('Amistad','Solicitud de amistad'),('Evento','Novedad de un evento'),
  ('Servicio','Solicitud de servicio'),('Producto','Compra de producto'),
  ('Sistema','Mensaje automático del sistema');
INSERT INTO tipo_denuncia (nombre, descripcion) VALUES
  ('Spam','Publicidad o contenido repetitivo'),('Acoso','Acoso o intimidación'),
  ('Contenido inapropiado','Contenido ofensivo o no apto'),
  ('Información falsa','Desinformación'),('Fraude','Estafa en producto o servicio');

SELECT 'rol' AS tabla, COUNT(*) AS registros FROM rol
UNION ALL SELECT 'tipo_usuario', COUNT(*) FROM tipo_usuario
UNION ALL SELECT 'tipo_servicio', COUNT(*) FROM tipo_servicio
UNION ALL SELECT 'tipo_producto', COUNT(*) FROM tipo_producto
UNION ALL SELECT 'tipo_evento', COUNT(*) FROM tipo_evento;

SELECT setseed(0.2026);

-- Estudiante 7000 | Docente 500 | Egresado 10000 | Empleado 500 | Empresario 50
-- Ex-Empleado 50 | Ex-Estudiante 300 | Ex-Docente 100 | Guess 50 = 18.550
INSERT INTO usuario (id_rol, id_tipo_usuario, nombres, apellidos, correo,
                     contrasena, telefono, fecha_registro, estado)
WITH dist(orden, tipo, cantidad) AS (VALUES
  (1,'Estudiante',7000),(2,'Docente',500),(3,'Egresado',10000),
  (4,'Empleado',500),(5,'Empresario',50),(6,'Ex-Empleado',50),
  (7,'Ex-Estudiante',300),(8,'Ex-Docente',100),(9,'Guess',50)),
rangos AS (
  SELECT tipo,
         SUM(cantidad) OVER (ORDER BY orden) - cantidad + 1 AS desde,
         SUM(cantidad) OVER (ORDER BY orden) AS hasta
    FROM dist),
nom AS (
  SELECT ARRAY['Juan','María','Carlos','Laura','Andrés','Camila','Santiago','Valentina',
               'Sebastián','Daniela','Felipe','Mariana','Diego','Natalia','Julián',
               'Paula','David','Sara','Esteban','Luisa','Mateo','Isabella','Nicolás',
               'Manuela','Samuel','Juliana','Alejandro','Catalina','Pablo','Melisa'] AS n,
         ARRAY['Gómez','Rodríguez','Martínez','López','García','Pérez','Sánchez','Ramírez',
               'Torres','Flórez','Díaz','Vargas','Castro','Ortiz','Rojas','Moreno',
               'Jiménez','Ruiz','Herrera','Medina','Aguilar','Londoño','Restrepo',
               'Cardona','Montoya','Zapata','Osorio','Mejía','Arango','Giraldo'] AS a),
base AS MATERIALIZED (
  SELECT g AS n, r.tipo,
         ROW_NUMBER() OVER (PARTITION BY r.tipo ORDER BY g) AS pos,
         nom.n[1 + floor(random()*cardinality(nom.n))::int] AS nombres,
         nom.a[1 + floor(random()*cardinality(nom.a))::int] || ' ' ||
         nom.a[1 + floor(random()*cardinality(nom.a))::int] AS apellidos,
         random() AS r_estado,
         TIMESTAMP '2022-01-01' + (random()*1400)::int * INTERVAL '1 day'
                                + (random()*86000)::int * INTERVAL '1 second' AS f_reg
    FROM generate_series(1,18550) g
    JOIN rangos r ON g BETWEEN r.desde AND r.hasta
    CROSS JOIN nom)
SELECT CASE WHEN b.tipo = 'Guess' THEN (SELECT id_rol FROM rol WHERE nombre='Visitante')
            WHEN b.tipo = 'Empleado' AND b.pos = 1 THEN (SELECT id_rol FROM rol WHERE nombre='Administrador')
            WHEN b.tipo = 'Empleado' AND b.pos <= 6 THEN (SELECT id_rol FROM rol WHERE nombre='Auxiliar')
            ELSE (SELECT id_rol FROM rol WHERE nombre='Miembro') END,
       tu.id_tipo_usuario,
       b.nombres,
       b.apellidos,
       translate(lower(b.nombres),'áéíóúñ','aeioun') || '.' ||
       translate(lower(split_part(b.apellidos,' ',1)),'áéíóúñ','aeioun') || b.n || '@' ||
       CASE WHEN b.tipo IN ('Estudiante','Docente','Empleado') THEN 'pascualbravo.edu.co'
            WHEN b.tipo = 'Empresario' THEN 'empresa.com'
            ELSE 'gmail.com' END,
       md5(b.n::text),                          
       '300' || lpad(b.n::text, 7, '0'),
       b.f_reg,
       CASE WHEN b.r_estado < 0.90 THEN 'Activo'
            WHEN b.r_estado < 0.97 THEN 'Inactivo'
            ELSE 'Suspendido' END
  FROM base b
  JOIN tipo_usuario tu ON tu.nombre = b.tipo
 ORDER BY b.n;

-- Eventos: 3.000 (2023-2026)
INSERT INTO evento (id_usuario, id_tipo_evento, nombre, descripcion, fecha, lugar, estado)
WITH org AS (   -- 30 organizadores institucionales (docentes, empleados, empresarios)
  SELECT array_agg(x.id_usuario ORDER BY x.id_usuario) AS ids
    FROM (SELECT u.id_usuario
            FROM usuario u
            JOIN rol r ON r.id_rol = u.id_rol
            JOIN tipo_usuario t ON t.id_tipo_usuario = u.id_tipo_usuario
           WHERE r.nombre IN ('Administrador','Auxiliar','Miembro')
             AND t.nombre IN ('Docente','Empleado','Empresario')
             AND u.estado = 'Activo'
           ORDER BY md5(u.id_usuario::text)
           LIMIT 30) x),
tip AS (SELECT array_agg(id_tipo_evento ORDER BY id_tipo_evento) AS ids FROM tipo_evento),
lug AS (SELECT ARRAY['Auditorio Principal','Aula 301','Biblioteca','Cancha Múltiple','Bloque 5',
                     'Sala de Sistemas','Cafetería','Virtual (Teams)','Parque Berrío',
                     'Plazoleta Central'] AS l),
base AS MATERIALIZED (
  SELECT g,
         org.ids[1 + floor(random()*cardinality(org.ids))::int] AS organizador,
         tip.ids[1 + floor(random()*cardinality(tip.ids))::int] AS tipo,
         lug.l[1 + floor(random()*cardinality(lug.l))::int] AS lugar,
         TIMESTAMP '2023-01-01' + (random()*1460)::int * INTERVAL '1 day'
                                + (8 + floor(random()*12)::int) * INTERVAL '1 hour' AS fecha,
         random() AS r_estado
    FROM org, tip, lug, generate_series(1,3000) g)
SELECT b.organizador, b.tipo,
       left(te.nombre, 40) || ' #' || b.g,
       'Evento de tipo ' || te.nombre || ' organizado en la Red Pascualina',
       b.fecha, b.lugar,
       CASE WHEN b.r_estado < 0.92 THEN 'Activo' ELSE 'Cancelado' END
  FROM base b JOIN tipo_evento te ON te.id_tipo_evento = b.tipo
 ORDER BY b.g;

SELECT 'usuario' AS tabla, COUNT(*) AS registros FROM usuario
UNION ALL SELECT 'evento', COUNT(*) FROM evento;

SELECT 'usuarios = 18550' AS control,
       COUNT(*) AS valor,
       CASE WHEN COUNT(*) = 18550 THEN 'PASS' ELSE 'FAIL' END AS resultado
  FROM usuario;

SELECT t.id_tipo_usuario AS codigo, t.nombre AS tipo_usuario, COUNT(u.id_usuario) AS usuarios,
       x.esperado,
       CASE WHEN COUNT(u.id_usuario) = x.esperado THEN 'PASS' ELSE 'FAIL' END AS resultado
  FROM tipo_usuario t
  LEFT JOIN usuario u ON u.id_tipo_usuario = t.id_tipo_usuario
  JOIN (VALUES ('Estudiante',7000),('Docente',500),('Egresado',10000),('Empleado',500),
               ('Empresario',50),('Ex-Empleado',50),('Ex-Estudiante',300),
               ('Ex-Docente',100),('Guess',50)) x(nombre, esperado) ON x.nombre = t.nombre
 GROUP BY t.id_tipo_usuario, t.nombre, x.esperado
 ORDER BY t.id_tipo_usuario;
SELECT r.nombre AS rol, COUNT(*) AS usuarios
  FROM usuario u JOIN rol r ON r.id_rol = u.id_rol GROUP BY r.nombre ORDER BY usuarios DESC;

SELECT 'usuario sin rol' AS verificacion, COUNT(*) AS huerfanos
  FROM usuario u LEFT JOIN rol r ON r.id_rol = u.id_rol WHERE r.id_rol IS NULL
UNION ALL SELECT 'usuario sin tipo_usuario', COUNT(*)
  FROM usuario u LEFT JOIN tipo_usuario t ON t.id_tipo_usuario = u.id_tipo_usuario WHERE t.id_tipo_usuario IS NULL
UNION ALL SELECT 'evento sin organizador', COUNT(*)
  FROM evento e LEFT JOIN usuario u ON u.id_usuario = e.id_usuario WHERE u.id_usuario IS NULL
UNION ALL SELECT 'evento sin tipo_evento', COUNT(*)
  FROM evento e LEFT JOIN tipo_evento t ON t.id_tipo_evento = e.id_tipo_evento WHERE t.id_tipo_evento IS NULL
UNION ALL SELECT 'evento organizado por visitante', COUNT(*)
  FROM evento e JOIN usuario u ON u.id_usuario = e.id_usuario
  JOIN rol r ON r.id_rol = u.id_rol WHERE r.nombre = 'Visitante';


SELECT setseed(0.3033);

INSERT INTO servicio (id_usuario, id_tipo_servicio, nombre, descripcion, precio,
                      duracion_minutos, ubicacion, fecha_publicacion)
WITH own AS (
  SELECT array_agg(u.id_usuario ORDER BY u.id_usuario) AS ids
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
   WHERE r.nombre = 'Miembro' AND u.estado = 'Activo'),
tip AS (SELECT array_agg(id_tipo_servicio ORDER BY id_tipo_servicio) AS ids FROM tipo_servicio),
base AS MATERIALIZED (
  SELECT g,
         own.ids[1 + floor(random()*cardinality(own.ids))::int] AS uid,
         tip.ids[1 + floor(random()*cardinality(tip.ids))::int] AS tid,
         (10 + floor(random()*290)::int) * 1000 AS precio,
         (ARRAY[30,45,60,90,120,NULL])[1 + floor(random()*6)::int] AS duracion,
         (ARRAY['Campus Pascual Bravo','Virtual','Medellín','Bello','Envigado','Itagüí',NULL])
           [1 + floor(random()*7)::int] AS ubicacion,
         TIMESTAMP '2024-01-01' + (random()*1050)::int * INTERVAL '1 day' AS fecha
    FROM own, tip, generate_series(1,3000) g)
SELECT b.uid, b.tid,
       left(ts.nombre, 40) || ' #' || b.g,
       'Servicio de ' || lower(ts.nombre) || ' ofrecido por la comunidad Pascualina',
       b.precio, b.duracion, b.ubicacion, b.fecha
  FROM base b JOIN tipo_servicio ts ON ts.id_tipo_servicio = b.tid
 ORDER BY b.g;

INSERT INTO producto (id_usuario, id_tipo_producto, nombre, descripcion, precio,
                      cantidad, estado, fecha_publicacion)
WITH own AS (
  SELECT array_agg(u.id_usuario ORDER BY u.id_usuario) AS ids
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
   WHERE r.nombre = 'Miembro' AND u.estado = 'Activo'),
tip AS (SELECT array_agg(id_tipo_producto ORDER BY id_tipo_producto) AS ids FROM tipo_producto),
base AS MATERIALIZED (
  SELECT g,
         own.ids[1 + floor(random()*cardinality(own.ids))::int] AS uid,
         tip.ids[1 + floor(random()*cardinality(tip.ids))::int] AS tid,
         (5 + floor(power(random(),2) * 1995)::int) * 1000 AS precio,
         1 + floor(random()*50)::int AS cantidad,
         random() AS r_estado,
         TIMESTAMP '2024-01-01' + (random()*1050)::int * INTERVAL '1 day' AS fecha
    FROM own, tip, generate_series(1,3000) g)
SELECT b.uid, b.tid,
       left(tp.nombre, 40) || ' #' || b.g,
       'Producto de tipo ' || lower(tp.nombre) || ' publicado para la venta',
       b.precio,
       CASE WHEN b.r_estado < 0.85 THEN b.cantidad ELSE 0 END,
       CASE WHEN b.r_estado < 0.85 THEN 'Disponible' ELSE 'Vendido' END,
       b.fecha
  FROM base b JOIN tipo_producto tp ON tp.id_tipo_producto = b.tid
 ORDER BY b.g;

INSERT INTO servicio_solicitud (id_usuario, id_servicio, fecha_solicitud, estado)
WITH us AS (
  SELECT array_agg(u.id_usuario ORDER BY u.id_usuario) AS ids
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
   WHERE r.nombre = 'Miembro' AND u.estado = 'Activo'),
sv AS MATERIALIZED (
  SELECT id_servicio, id_usuario AS oferente, fecha_publicacion,
         ROW_NUMBER() OVER (ORDER BY id_servicio) AS rn
    FROM servicio),
gen AS MATERIALIZED (
  SELECT g,
         1 + floor(random()*(SELECT COUNT(*) FROM sv))::int AS rn,
         1 + floor(random()*cardinality(us.ids))::int AS ui,
         random() AS r_estado,
         random() AS r_fecha
    FROM us, generate_series(1,6000) g)
SELECT CASE WHEN us.ids[gen.ui] = sv.oferente
            THEN us.ids[(gen.ui % cardinality(us.ids)) + 1]
            ELSE us.ids[gen.ui] END,
       sv.id_servicio,
       GREATEST(sv.fecha_publicacion,
                LEAST(sv.fecha_publicacion + (gen.r_fecha * 300)::int * INTERVAL '1 day',
                      CURRENT_TIMESTAMP - gen.r_fecha * INTERVAL '20 days')),
       CASE WHEN gen.r_estado < 0.45 THEN 'Completada'
            WHEN gen.r_estado < 0.65 THEN 'Aceptada'
            WHEN gen.r_estado < 0.85 THEN 'Pendiente'
            ELSE 'Rechazada' END
  FROM gen JOIN sv ON sv.rn = gen.rn CROSS JOIN us
ON CONFLICT DO NOTHING;


INSERT INTO producto_transaccion (id_usuario, id_producto, cantidad, precio_unitario, fecha_adquisicion)
WITH us AS (
  SELECT array_agg(u.id_usuario ORDER BY u.id_usuario) AS ids
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
   WHERE r.nombre = 'Miembro' AND u.estado = 'Activo'),
pr AS MATERIALIZED (
  SELECT id_producto, id_usuario AS vendedor, precio, fecha_publicacion,
         ROW_NUMBER() OVER (ORDER BY id_producto) AS rn
    FROM producto),
gen AS MATERIALIZED (
  SELECT g,
         1 + floor(random()*(SELECT COUNT(*) FROM pr))::int AS rn,
         1 + floor(random()*cardinality(us.ids))::int AS ui,
         1 + floor(random()*3)::int AS cant,
         random() AS r_fecha
    FROM us, generate_series(1,6000) g)
SELECT CASE WHEN us.ids[gen.ui] = pr.vendedor
            THEN us.ids[(gen.ui % cardinality(us.ids)) + 1]
            ELSE us.ids[gen.ui] END,
       pr.id_producto,
       gen.cant,
       pr.precio,
       GREATEST(pr.fecha_publicacion,
                LEAST(pr.fecha_publicacion + (gen.r_fecha * 300)::int * INTERVAL '1 day',
                      CURRENT_TIMESTAMP - gen.r_fecha * INTERVAL '20 days'))
  FROM gen JOIN pr ON pr.rn = gen.rn CROSS JOIN us;

SELECT 'servicio' AS tabla, COUNT(*) AS registros FROM servicio
UNION ALL SELECT 'producto', COUNT(*) FROM producto
UNION ALL SELECT 'servicio_solicitud', COUNT(*) FROM servicio_solicitud
UNION ALL SELECT 'producto_transaccion', COUNT(*) FROM producto_transaccion;

SELECT 'servicio_solicitud >= 5000' AS control, COUNT(*) AS valor,
       CASE WHEN COUNT(*) >= 5000 THEN 'PASS' ELSE 'FAIL' END AS resultado
  FROM servicio_solicitud
UNION ALL SELECT 'producto_transaccion >= 5000', COUNT(*),
       CASE WHEN COUNT(*) >= 5000 THEN 'PASS' ELSE 'FAIL' END
  FROM producto_transaccion;

SELECT 'servicio sin oferente' AS verificacion, COUNT(*) AS problemas
  FROM servicio s LEFT JOIN usuario u ON u.id_usuario = s.id_usuario WHERE u.id_usuario IS NULL
UNION ALL SELECT 'servicio sin tipo', COUNT(*)
  FROM servicio s LEFT JOIN tipo_servicio t ON t.id_tipo_servicio = s.id_tipo_servicio WHERE t.id_tipo_servicio IS NULL
UNION ALL SELECT 'producto sin vendedor', COUNT(*)
  FROM producto p LEFT JOIN usuario u ON u.id_usuario = p.id_usuario WHERE u.id_usuario IS NULL
UNION ALL SELECT 'producto sin tipo', COUNT(*)
  FROM producto p LEFT JOIN tipo_producto t ON t.id_tipo_producto = p.id_tipo_producto WHERE t.id_tipo_producto IS NULL
UNION ALL SELECT 'solicitud sin servicio o usuario', COUNT(*)
  FROM servicio_solicitud ss
  LEFT JOIN servicio s ON s.id_servicio = ss.id_servicio
  LEFT JOIN usuario u ON u.id_usuario = ss.id_usuario
  WHERE s.id_servicio IS NULL OR u.id_usuario IS NULL
UNION ALL SELECT 'solicitud de su propio servicio', COUNT(*)
  FROM servicio_solicitud ss JOIN servicio s ON s.id_servicio = ss.id_servicio
  WHERE s.id_usuario = ss.id_usuario
UNION ALL SELECT 'transacción sin producto o comprador', COUNT(*)
  FROM producto_transaccion pt
  LEFT JOIN producto p ON p.id_producto = pt.id_producto
  LEFT JOIN usuario u ON u.id_usuario = pt.id_usuario
  WHERE p.id_producto IS NULL OR u.id_usuario IS NULL
UNION ALL SELECT 'compra de su propio producto', COUNT(*)
  FROM producto_transaccion pt JOIN producto p ON p.id_producto = pt.id_producto
  WHERE p.id_usuario = pt.id_usuario;

SELECT setseed(0.4044);

INSERT INTO evento_usuario (id_evento, id_usuario, fecha_inscripcion, estado,
                            calificacion, me_gusta, comentario, fecha_comentario)
WITH us AS (
  SELECT array_agg(u.id_usuario ORDER BY u.id_usuario) AS ids
    FROM usuario u JOIN rol r ON r.id_rol = u.id_rol
   WHERE r.nombre = 'Miembro' AND u.estado = 'Activo'),
ev AS MATERIALIZED (
  SELECT id_evento, id_usuario AS organizador, fecha, estado,
         ROW_NUMBER() OVER (ORDER BY id_evento) AS rn
    FROM evento),
gen AS MATERIALIZED (
  SELECT g,
         1 + floor(random()*(SELECT COUNT(*) FROM ev))::int AS rn,
         1 + floor(random()*cardinality(us.ids))::int AS ui,
         random() AS r_estado, random() AS r_cal, random() AS r_like,
         random() AS r_com, random() AS r_ins,
         1 + floor(random()*30)::int AS dias_antes,
         1 + floor(random()*72)::int AS horas_despues,
         1 + floor(random()*6)::int AS txt
    FROM us, generate_series(1,10000) g),
calc AS MATERIALIZED (
  SELECT ev.id_evento, ev.fecha,
         CASE WHEN us.ids[gen.ui] = ev.organizador
              THEN us.ids[(gen.ui % cardinality(us.ids)) + 1]
              ELSE us.ids[gen.ui] END AS participante,
         CASE WHEN ev.estado = 'Cancelado' THEN 'Cancelo'
              WHEN ev.fecha > CURRENT_TIMESTAMP THEN CASE WHEN gen.r_estado < 0.92 THEN 'Inscrito' ELSE 'Cancelo' END
              WHEN gen.r_estado < 0.70 THEN 'Asistio'
              WHEN gen.r_estado < 0.90 THEN 'No asistio'
              ELSE 'Cancelo' END AS estado,
         gen.*
    FROM gen JOIN ev ON ev.rn = gen.rn CROSS JOIN us)
SELECT c.id_evento,
       c.participante,
       LEAST(c.fecha - c.dias_antes * INTERVAL '1 day',
             CURRENT_TIMESTAMP - c.r_ins * INTERVAL '30 days'),
       c.estado,
       CASE WHEN c.estado = 'Asistio' AND c.r_cal < 0.70 THEN 2 + floor(c.r_cal/0.70*4)::int END,
       (c.estado = 'Asistio' AND c.r_like < 0.60),
       CASE WHEN c.estado = 'Asistio' AND c.r_com < 0.25
            THEN (ARRAY['Excelente organización.','Muy buen contenido.','Faltó tiempo para preguntas.',
                        'Gran espacio para conocer gente.','El lugar quedó pequeño.','Repetiría sin dudarlo.'])[c.txt]
       END,
  
       CASE WHEN c.estado = 'Asistio' AND c.r_com < 0.25
            THEN LEAST(c.fecha + c.horas_despues * INTERVAL '1 hour', CURRENT_TIMESTAMP)
       END
  FROM calc c
ON CONFLICT DO NOTHING;

SELECT COUNT(*) AS registros_evento_usuario FROM evento_usuario;
SELECT 'evento_usuario >= 5000' AS control, COUNT(*) AS valor,
       CASE WHEN COUNT(*) >= 5000 THEN 'PASS' ELSE 'FAIL' END AS resultado
  FROM evento_usuario;
SELECT estado, COUNT(*) AS participaciones FROM evento_usuario GROUP BY estado ORDER BY participaciones DESC;

SELECT 'participación sin evento o usuario' AS verificacion, COUNT(*) AS problemas
  FROM evento_usuario eu
  LEFT JOIN evento e ON e.id_evento = eu.id_evento
  LEFT JOIN usuario u ON u.id_usuario = eu.id_usuario
  WHERE e.id_evento IS NULL OR u.id_usuario IS NULL
UNION ALL SELECT 'organizador inscrito en su propio evento', COUNT(*)
  FROM evento_usuario eu JOIN evento e ON e.id_evento = eu.id_evento
  WHERE e.id_usuario = eu.id_usuario
UNION ALL SELECT 'comentario sin fecha (o fecha sin comentario)', COUNT(*)
  FROM evento_usuario WHERE (comentario IS NULL) <> (fecha_comentario IS NULL)
UNION ALL SELECT 'comentario anterior al evento', COUNT(*)
  FROM evento_usuario eu JOIN evento e ON e.id_evento = eu.id_evento
  WHERE eu.fecha_comentario < e.fecha
UNION ALL SELECT 'comentario con fecha futura', COUNT(*)
  FROM evento_usuario WHERE fecha_comentario > CURRENT_TIMESTAMP
UNION ALL SELECT 'calificación en participación que no asistió', COUNT(*)
  FROM evento_usuario WHERE calificacion IS NOT NULL AND estado <> 'Asistio';

INSERT INTO perfil (id_usuario, informacion)
SELECT u.id_usuario,
       '{"habilidades":[],"idiomas":[],"intereses":[],"proyectos":[]}'::jsonb
  FROM usuario u
 WHERE NOT EXISTS (SELECT 1 FROM perfil p WHERE p.id_usuario = u.id_usuario);

UPDATE perfil
   SET informacion = informacion || jsonb_build_object(
         'habilidades', jsonb_build_array('SQL','Python','PostgreSQL'),
         'idiomas',     jsonb_build_array('Español','Inglés'),
         'intereses',   jsonb_build_array('bases de datos','videojuegos','hackatones'),
         'proyectos',   jsonb_build_array(
             jsonb_build_object('nombre','Red Social Pascualina','rol','Diseñador de BD','anio',2026),
             jsonb_build_object('nombre','App de tutorías','rol','Desarrollador','anio',2025))),
       fecha_actualizacion = CURRENT_TIMESTAMP
 WHERE id_usuario IN (SELECT u.id_usuario
                        FROM usuario u
                        JOIN tipo_usuario t ON t.id_tipo_usuario = u.id_tipo_usuario
                       WHERE t.nombre = 'Estudiante'
                       ORDER BY u.id_usuario LIMIT 5);

UPDATE perfil
   SET informacion = jsonb_set(informacion, '{habilidades}',
                               (informacion->'habilidades') || '"Modelado ER"'::jsonb),
       fecha_actualizacion = CURRENT_TIMESTAMP
 WHERE id_usuario = (SELECT MIN(id_usuario) FROM usuario);

UPDATE perfil p
   SET informacion = informacion || jsonb_build_object(
         'habilidades', CASE p.id_usuario % 4
                          WHEN 0 THEN '["SQL","Java"]'::jsonb
                          WHEN 1 THEN '["Python","Excel"]'::jsonb
                          WHEN 2 THEN '["JavaScript","SQL"]'::jsonb
                          ELSE '["Redes","Linux"]'::jsonb END,
         'idiomas', CASE WHEN p.id_usuario % 3 = 0 THEN '["Español","Inglés"]'::jsonb
                         ELSE '["Español"]'::jsonb END,
         'intereses', CASE p.id_usuario % 3
                        WHEN 0 THEN '["videojuegos","música"]'::jsonb
                        WHEN 1 THEN '["programación","deportes"]'::jsonb
                        ELSE '["emprendimiento","lectura"]'::jsonb END,
         'proyectos', jsonb_build_array(jsonb_build_object(
                        'nombre','Proyecto '||p.id_usuario,'anio',2025))),
       fecha_actualizacion = CURRENT_TIMESTAMP
 WHERE p.id_usuario % 9 = 0 AND p.id_usuario <= 18000;

SELECT u.id_usuario,
       u.nombres || ' ' || u.apellidos AS usuario,
       p.informacion->'habilidades' AS habilidades,
       p.informacion->'idiomas' AS idiomas,
       p.informacion->'intereses'->>0 AS primer_interes,
       p.informacion->'proyectos'->0->>'nombre' AS primer_proyecto
  FROM perfil p
  JOIN usuario u ON u.id_usuario = p.id_usuario
 WHERE p.informacion->'habilidades' @> '["SQL"]'::jsonb
   AND p.informacion->'idiomas' @> '["Inglés"]'::jsonb
 ORDER BY u.id_usuario
 LIMIT 15;

SELECT h AS habilidad, COUNT(*) AS usuarios
  FROM perfil p, jsonb_array_elements_text(p.informacion->'habilidades') AS h
 GROUP BY h ORDER BY usuarios DESC, h;

SELECT id_producto,
       nombre,
       cantidad AS unidades_disponibles,
       precio AS precio_base,
       ROUND(precio * 1.05, 2) AS precio_con_recargo_5,
       ROUND(precio * 0.05, 2) AS valor_recargo,
       estado AS disponibilidad
  FROM producto
 WHERE estado = 'Disponible'
   AND cantidad > 0
   AND precio BETWEEN 50000 AND 500000
 ORDER BY precio DESC, nombre
 LIMIT 20;

SELECT t.nombre AS tipo_usuario,
       COUNT(u.id_usuario) AS total_usuarios,
       ROUND(100.0 * COUNT(u.id_usuario) / SUM(COUNT(u.id_usuario)) OVER (), 2) AS porcentaje
  FROM usuario u
  JOIN tipo_usuario t ON t.id_tipo_usuario = u.id_tipo_usuario
 GROUP BY t.nombre
 ORDER BY total_usuarios DESC;

-- 9. VIEW basada en la consulta del punto 7 (4 JOIN + GROUP BY + HAVING)
CREATE OR REPLACE VIEW v_reporte_ventas_consolidado AS
SELECT tu.nombre AS tipo_usuario,
       tp.nombre AS tipo_producto,
       COUNT(*) AS transacciones,
       SUM(pt.cantidad) AS unidades,
       SUM(pt.cantidad * pt.precio_unitario) AS total_vendido,
       ROUND(AVG(pt.cantidad * pt.precio_unitario),2) AS ticket_promedio
  FROM producto_transaccion pt
  JOIN producto p ON p.id_producto = pt.id_producto
  JOIN tipo_producto tp ON tp.id_tipo_producto = p.id_tipo_producto
  JOIN usuario u ON u.id_usuario = pt.id_usuario
  JOIN tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
 WHERE tu.nombre IN ('Estudiante','Egresado')
   AND pt.cantidad * pt.precio_unitario > 100000
 GROUP BY tu.nombre, tp.nombre
HAVING SUM(pt.cantidad * pt.precio_unitario) > 1000000;

SELECT * FROM v_reporte_ventas_consolidado ORDER BY total_vendido DESC;

ANALYZE;
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamano_base;
SELECT relname AS tabla, n_live_tup AS filas_estimadas
  FROM pg_stat_user_tables
 WHERE schemaname = 'pascualina' AND n_live_tup > 0
 ORDER BY n_live_tup DESC;

SELECT e.id_evento,
       e.nombre AS evento,
       te.nombre AS tipo_evento,
       e.fecha,
       u.nombres || ' ' || u.apellidos AS organizador,
       u.correo AS correo_organizador,
       e.lugar,
       e.estado
  FROM evento e
  JOIN tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
  JOIN usuario u ON u.id_usuario = e.id_usuario
 WHERE EXTRACT(YEAR FROM e.fecha) IN (2024, 2025)
 ORDER BY e.fecha
 LIMIT 50;

SELECT EXTRACT(YEAR FROM e.fecha)::int AS anio,
       te.nombre AS tipo_evento,
       COUNT(*) AS eventos,
       COUNT(DISTINCT e.id_usuario) AS organizadores_distintos
  FROM evento e
  JOIN tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
  JOIN usuario u ON u.id_usuario = e.id_usuario
 WHERE EXTRACT(YEAR FROM e.fecha) IN (2024, 2025)
 GROUP BY EXTRACT(YEAR FROM e.fecha)::int, te.nombre
 ORDER BY anio, eventos DESC;

SELECT setseed(0.11);
DROP TABLE IF EXISTS resultado_rendimiento;
DROP TABLE IF EXISTS usuario_1000;
DROP TABLE IF EXISTS usuario_100000;
DROP FUNCTION IF EXISTS fn_medir(TEXT, TEXT, TEXT);

CREATE TABLE usuario_1000 (
  id_usuario INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_tipo_usuario INTEGER NOT NULL,
  nombres VARCHAR(50) NOT NULL,
  correo VARCHAR(255) NOT NULL,
  fecha_registro TIMESTAMP NOT NULL,
  estado VARCHAR(30) NOT NULL
);
CREATE TABLE usuario_100000 (LIKE usuario_1000 INCLUDING ALL);

INSERT INTO usuario_1000 (id_tipo_usuario, nombres, correo, fecha_registro, estado)
SELECT 1 + floor(random()*9)::int,
       'Usuario ' || g,
       'u' || g || '@prueba.com',
       TIMESTAMP '2022-01-01' + (random()*1400)::int * INTERVAL '1 day'
                              + (random()*86000)::int * INTERVAL '1 second',
       (ARRAY['Activo','Inactivo','Suspendido'])[1 + floor(random()*3)::int]
  FROM generate_series(1,1000) g;
INSERT INTO usuario_100000 (id_tipo_usuario, nombres, correo, fecha_registro, estado)
SELECT 1 + floor(random()*9)::int,
       'Usuario ' || g,
       'u' || g || '@prueba.com',
       TIMESTAMP '2022-01-01' + (random()*1400)::int * INTERVAL '1 day'
                              + (random()*86000)::int * INTERVAL '1 second',
       (ARRAY['Activo','Inactivo','Suspendido'])[1 + floor(random()*3)::int]
  FROM generate_series(1,100000) g;
ANALYZE usuario_1000;
ANALYZE usuario_100000;

SELECT 'usuario_1000' AS tabla, COUNT(*) AS registros FROM usuario_1000
UNION ALL SELECT 'usuario_100000', COUNT(*) FROM usuario_100000;

CREATE FUNCTION fn_medir(p_prueba TEXT, p_tabla TEXT, p_sql TEXT)
RETURNS TABLE (prueba TEXT, tabla TEXT, estrategia_escaneo TEXT, costo_total NUMERIC,
               buffers_hit BIGINT, buffers_read BIGINT,
               planificacion_ms NUMERIC, ejecucion_ms NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE j JSONB;
BEGIN
  EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) ' || p_sql INTO j;
  RETURN QUERY SELECT p_prueba, p_tabla,
         COALESCE(jsonb_path_query_first(j->0->'Plan', '$.**."Node Type" ? (@ like_regex "Scan")') #>> '{}', 'n/a'),
         (j->0->'Plan'->>'Total Cost')::NUMERIC,
         COALESCE((j->0->'Plan'->>'Shared Hit Blocks')::BIGINT, 0),
         COALESCE((j->0->'Plan'->>'Shared Read Blocks')::BIGINT, 0),
         (j->0->>'Planning Time')::NUMERIC,
         (j->0->>'Execution Time')::NUMERIC;
END $$;

CREATE TABLE resultado_rendimiento (
  prueba TEXT, tabla TEXT, estrategia_escaneo TEXT, costo_total NUMERIC,
  buffers_hit BIGINT, buffers_read BIGINT, planificacion_ms NUMERIC, ejecucion_ms NUMERIC);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_1000
 WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
 GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_100000
 WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
 GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario;

INSERT INTO resultado_rendimiento
SELECT * FROM fn_medir('1. Rango de fechas SIN índice','1000',
$q$SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_1000
   WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
   GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario$q$);
INSERT INTO resultado_rendimiento
SELECT * FROM fn_medir('1. Rango de fechas SIN índice','100000',
$q$SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_100000
   WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
   GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario$q$);

CREATE INDEX ix_u1000_fecha ON usuario_1000 (fecha_registro);
CREATE INDEX ix_u100000_fecha ON usuario_100000 (fecha_registro);
ANALYZE usuario_1000;
ANALYZE usuario_100000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_1000
 WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
 GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_100000
 WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
 GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario;

INSERT INTO resultado_rendimiento
SELECT * FROM fn_medir('2. Rango de fechas CON índice','1000',
$q$SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_1000
   WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
   GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario$q$);
INSERT INTO resultado_rendimiento
SELECT * FROM fn_medir('2. Rango de fechas CON índice','100000',
$q$SELECT id_tipo_usuario, COUNT(*) AS usuarios FROM usuario_100000
   WHERE fecha_registro >= TIMESTAMP '2024-03-01' AND fecha_registro < TIMESTAMP '2024-04-01'
   GROUP BY id_tipo_usuario ORDER BY id_tipo_usuario$q$);


SELECT prueba, tabla AS registros, estrategia_escaneo, costo_total,
       buffers_hit AS buffers_shared_hit, buffers_read AS buffers_shared_read,
       ROUND(planificacion_ms, 3) AS planning_time_ms,
       ROUND(ejecucion_ms, 3) AS execution_time_ms
  FROM resultado_rendimiento
 ORDER BY prueba, CASE tabla WHEN '1000' THEN 1 ELSE 2 END;
 
SELECT u.id_usuario,
       u.nombres || ' ' || u.apellidos AS estudiante,
       ts.nombre AS tipo_servicio,
       s.nombre AS servicio,
       s.precio,
       ss.fecha_solicitud
  FROM servicio_solicitud ss
  JOIN servicio s ON s.id_servicio = ss.id_servicio
  JOIN tipo_servicio ts ON ts.id_tipo_servicio = s.id_tipo_servicio
  JOIN usuario u ON u.id_usuario = ss.id_usuario
 WHERE ss.estado = 'Completada'  
   AND u.estado = 'Activo'
   AND u.id_tipo_usuario = 1      
 ORDER BY ss.fecha_solicitud DESC
 LIMIT 30;

SELECT ts.nombre AS tipo_servicio,
       COUNT(*) AS solicitudes_completadas,
       COUNT(DISTINCT u.id_usuario) AS estudiantes,
       SUM(s.precio) AS valor_consumido
  FROM servicio_solicitud ss
  JOIN servicio s ON s.id_servicio = ss.id_servicio
  JOIN tipo_servicio ts ON ts.id_tipo_servicio = s.id_tipo_servicio
  JOIN usuario u ON u.id_usuario = ss.id_usuario
 WHERE ss.estado = 'Completada'
   AND u.estado = 'Activo'
   AND u.id_tipo_usuario = 1      
 GROUP BY ts.nombre
 ORDER BY valor_consumido DESC;


SELECT estado,
       COUNT(*) AS solicitudes,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS porcentaje
  FROM servicio_solicitud
 GROUP BY estado
 ORDER BY solicitudes DESC;

SELECT tp.nombre AS tipo_producto,
       COUNT(*) AS transacciones,
       SUM(pt.cantidad) AS unidades_vendidas,
       SUM(pt.cantidad * pt.precio_unitario) AS recaudo_total
  FROM producto_transaccion pt
  JOIN producto p ON p.id_producto = pt.id_producto
  JOIN tipo_producto tp ON tp.id_tipo_producto = p.id_tipo_producto
 WHERE tp.nombre IN ('Libro','Computador')
 GROUP BY tp.nombre
 ORDER BY recaudo_total DESC;


DROP TABLE IF EXISTS sel_acid;
CREATE TEMP TABLE sel_acid AS
  SELECT MIN(id_producto) AS id_producto
    FROM producto WHERE estado = 'Disponible' AND cantidad >= 5;

SELECT p.id_producto, p.nombre, p.cantidad AS stock_antes,
       (SELECT COUNT(*) FROM producto_transaccion) AS transacciones_antes
  FROM producto p JOIN sel_acid s ON s.id_producto = p.id_producto;


COMMIT;

BEGIN;
  -- Paso 1: registrar la compra de 2 unidades
  INSERT INTO producto_transaccion (id_usuario, id_producto, cantidad, precio_unitario)
  SELECT (SELECT MIN(u.id_usuario) FROM usuario u
           WHERE u.id_rol = (SELECT id_rol FROM rol WHERE nombre = 'Miembro')
             AND u.estado = 'Activo'
             AND u.id_usuario <> p.id_usuario),
         p.id_producto, 2, p.precio
    FROM producto p JOIN sel_acid s ON s.id_producto = p.id_producto;

  SAVEPOINT sp_compra_registrada;

  -- Paso 2: descontar inventario
  UPDATE producto SET cantidad = cantidad - 2
   WHERE id_producto = (SELECT id_producto FROM sel_acid);

  -- Dentro de la transaccion: stock -2 y +1 transaccion
  SELECT p.id_producto, p.cantidad AS stock_dentro_transaccion,
         (SELECT COUNT(*) FROM producto_transaccion) AS transacciones_dentro
    FROM producto p JOIN sel_acid s ON s.id_producto = p.id_producto;

  -- Falla simulada en el paso 2: se deshace SOLO hasta el SAVEPOINT
  ROLLBACK TO SAVEPOINT sp_compra_registrada;

  -- Stock vuelve al original, pero la compra (paso 1) sigue dentro de la transaccion
  SELECT p.id_producto, p.cantidad AS stock_tras_savepoint,
         (SELECT COUNT(*) FROM producto_transaccion) AS transacciones_tras_savepoint
    FROM producto p JOIN sel_acid s ON s.id_producto = p.id_producto;
ROLLBACK;   -- se deshace TODO: ya no queda ni la compra

-- Estado DESPUES: identico al ANTES
SELECT p.id_producto, p.nombre, p.cantidad AS stock_despues,
       (SELECT COUNT(*) FROM producto_transaccion) AS transacciones_despues
  FROM producto p JOIN sel_acid s ON s.id_producto = p.id_producto;

DROP TABLE IF EXISTS resultado_atomicidad;
CREATE TEMP TABLE resultado_atomicidad (
  evento TEXT, stock_antes INT, stock_despues INT, transacciones_antes BIGINT, transacciones_despues BIGINT);
DO $$
DECLARE
  v_prod INT; v_comprador INT;
  v_stock_a INT; v_stock_d INT; v_tx_a BIGINT; v_tx_d BIGINT; v_evento TEXT := 'SIN FALLA (revisar)';
BEGIN
  SELECT id_producto INTO v_prod FROM sel_acid;
  SELECT cantidad INTO v_stock_a FROM producto WHERE id_producto = v_prod;
  SELECT COUNT(*) INTO v_tx_a FROM producto_transaccion;
  SELECT MIN(u.id_usuario) INTO v_comprador FROM usuario u
   WHERE u.id_rol = (SELECT id_rol FROM rol WHERE nombre = 'Miembro')
     AND u.estado = 'Activo'
     AND u.id_usuario <> (SELECT id_usuario FROM producto WHERE id_producto = v_prod);
  BEGIN
    INSERT INTO producto_transaccion (id_usuario, id_producto, cantidad, precio_unitario)
    SELECT v_comprador, id_producto, 1000, precio FROM producto WHERE id_producto = v_prod;
    UPDATE producto SET cantidad = cantidad - 1000 WHERE id_producto = v_prod;   -- viola el CHECK
  EXCEPTION WHEN check_violation THEN
    v_evento := 'FALLA: stock insuficiente -> revertido el INSERT y el UPDATE';
  END;
  SELECT cantidad INTO v_stock_d FROM producto WHERE id_producto = v_prod;
  SELECT COUNT(*) INTO v_tx_d FROM producto_transaccion;
  INSERT INTO resultado_atomicidad VALUES (v_evento, v_stock_a, v_stock_d, v_tx_a, v_tx_d);
END $$;
SELECT * FROM resultado_atomicidad;  

DROP TABLE IF EXISTS resultados_acid;
CREATE TEMP TABLE resultados_acid (
  nro INT, restriccion TEXT, prueba TEXT, resultado TEXT, sqlstate TEXT, mensaje TEXT);

DO $$
DECLARE
  t TEXT[][] := ARRAY[
    ['NOT NULL','Usuario sin nombres',
     $q$INSERT INTO usuario(id_rol,id_tipo_usuario,nombres,apellidos,correo,contrasena,telefono)
        VALUES ((SELECT MIN(id_rol) FROM rol),(SELECT MIN(id_tipo_usuario) FROM tipo_usuario),NULL,'X','n1@x.co','h','3990000001')$q$],
    ['NOT NULL','Producto sin nombre',
     $q$INSERT INTO producto(id_usuario,id_tipo_producto,nombre,precio,cantidad)
        VALUES ((SELECT MIN(id_usuario) FROM usuario),(SELECT MIN(id_tipo_producto) FROM tipo_producto),NULL,1000,1)$q$],
    ['CHECK','Precio de producto negativo',
     $q$INSERT INTO producto(id_usuario,id_tipo_producto,nombre,precio,cantidad)
        VALUES ((SELECT MIN(id_usuario) FROM usuario),(SELECT MIN(id_tipo_producto) FROM tipo_producto),'Malo',-500,1)$q$],
    ['CHECK','Stock negativo al vender más de lo disponible',
     $q$UPDATE producto SET cantidad = cantidad - 100000 WHERE id_producto = (SELECT MIN(id_producto) FROM producto)$q$],
    ['CHECK','Estado inválido en servicio_solicitud',
     $q$UPDATE servicio_solicitud SET estado = 'Inventado' WHERE id_solicitud = (SELECT MIN(id_solicitud) FROM servicio_solicitud)$q$],
    ['CHECK','Compra con cantidad 0',
     $q$INSERT INTO producto_transaccion(id_usuario,id_producto,cantidad,precio_unitario)
        VALUES ((SELECT MIN(id_usuario) FROM usuario),(SELECT MIN(id_producto) FROM producto),0,1000)$q$],
    ['CHECK','Correo con formato inválido',
     $q$INSERT INTO usuario(id_rol,id_tipo_usuario,nombres,apellidos,correo,contrasena,telefono)
        VALUES ((SELECT MIN(id_rol) FROM rol),(SELECT MIN(id_tipo_usuario) FROM tipo_usuario),'X','Y','sin-arroba','h','3990000002')$q$],
    ['FOREIGN KEY','Solicitud a un servicio inexistente',
     $q$INSERT INTO servicio_solicitud(id_usuario,id_servicio,estado)
        VALUES ((SELECT MIN(id_usuario) FROM usuario),99999999,'Pendiente')$q$],
    ['FOREIGN KEY','Compra de un producto inexistente',
     $q$INSERT INTO producto_transaccion(id_usuario,id_producto,cantidad,precio_unitario)
        VALUES ((SELECT MIN(id_usuario) FROM usuario),99999999,1,1000)$q$],
    ['FOREIGN KEY','Usuario con rol inexistente',
     $q$INSERT INTO usuario(id_rol,id_tipo_usuario,nombres,apellidos,correo,contrasena,telefono)
        VALUES (99999,(SELECT MIN(id_tipo_usuario) FROM tipo_usuario),'X','Y','fk@x.co','h','3990000003')$q$],
    ['FOREIGN KEY (RESTRICT)','Borrar un usuario que ofrece servicios',
     $q$DELETE FROM usuario WHERE id_usuario = (SELECT id_usuario FROM servicio LIMIT 1)$q$],
    ['UNIQUE','Correo duplicado',
     $q$INSERT INTO usuario(id_rol,id_tipo_usuario,nombres,apellidos,correo,contrasena,telefono)
        SELECT id_rol,id_tipo_usuario,'X','Y',correo,'h','3990000004'
          FROM usuario WHERE id_usuario = (SELECT MIN(id_usuario) FROM usuario)$q$]
  ];
  i INT;
BEGIN
  FOR i IN 1 .. array_length(t, 1) LOOP
    BEGIN
      EXECUTE t[i][3];
      -- si llega aqui el dato invalido se acepto: se revierte y se reporta
      RAISE EXCEPTION 'PERMITIDO' USING ERRCODE = 'XX999';
    EXCEPTION
      WHEN SQLSTATE 'XX999' THEN
        INSERT INTO resultados_acid VALUES (i, t[i][1], t[i][2], 'NO BLOQUEADO (revisar)', 'XX999', 'La base aceptó un dato inválido');
      WHEN OTHERS THEN
        INSERT INTO resultados_acid VALUES (i, t[i][1], t[i][2], 'BLOQUEADO', SQLSTATE, SQLERRM);
    END;
  END LOOP;
END $$;

SELECT * FROM resultados_acid ORDER BY nro;
SELECT restriccion, COUNT(*) AS pruebas, COUNT(*) FILTER (WHERE resultado = 'BLOQUEADO') AS bloqueadas
  FROM resultados_acid GROUP BY restriccion ORDER BY restriccion;
SELECT pt.id_adquisicion AS id_transaccion,
       tu.nombre AS tipo_comprador,
       u.nombres || ' ' || u.apellidos AS comprador,
       tp.nombre AS tipo_producto,
       p.nombre AS producto,
       pt.cantidad,
       pt.precio_unitario,
       pt.cantidad * pt.precio_unitario AS total_compra,
       pt.fecha_adquisicion
  FROM producto_transaccion pt
  JOIN producto p ON p.id_producto = pt.id_producto
  JOIN tipo_producto tp ON tp.id_tipo_producto = p.id_tipo_producto
  JOIN usuario u ON u.id_usuario = pt.id_usuario
  JOIN tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
 WHERE tu.nombre IN ('Estudiante','Egresado')
   AND pt.cantidad * pt.precio_unitario > 100000
 ORDER BY total_compra DESC
 LIMIT 25;

SELECT tu.nombre AS tipo_usuario,
       tp.nombre AS tipo_producto,
       COUNT(*) AS transacciones,
       SUM(pt.cantidad) AS unidades,
       SUM(pt.cantidad * pt.precio_unitario) AS total_vendido,
       ROUND(AVG(pt.cantidad * pt.precio_unitario),2) AS ticket_promedio
  FROM producto_transaccion pt
  JOIN producto p ON p.id_producto = pt.id_producto
  JOIN tipo_producto tp ON tp.id_tipo_producto = p.id_tipo_producto
  JOIN usuario u ON u.id_usuario = pt.id_usuario
  JOIN tipo_usuario tu ON tu.id_tipo_usuario = u.id_tipo_usuario
 WHERE tu.nombre IN ('Estudiante','Egresado')
   AND pt.cantidad * pt.precio_unitario > 100000
 GROUP BY tu.nombre, tp.nombre
HAVING SUM(pt.cantidad * pt.precio_unitario) > 1000000
 ORDER BY total_vendido DESC;

DEALLOCATE ALL;
PREPARE stmt_analisis_participacion_eventos (INT, DATE) AS
SELECT o.id_usuario AS id_organizador,
       o.nombres || ' ' || o.apellidos AS organizador,
       tuo.nombre AS tipo_usuario_organizador,
       te.nombre AS tipo_evento,
       COUNT(*) AS participantes_confirmados
  FROM evento_usuario eu
  JOIN evento e ON e.id_evento = eu.id_evento
  JOIN tipo_evento te ON te.id_tipo_evento = e.id_tipo_evento
  JOIN usuario o ON o.id_usuario = e.id_usuario                -- organizador
  JOIN tipo_usuario tuo ON tuo.id_tipo_usuario = o.id_tipo_usuario
 WHERE e.id_tipo_evento = $1
   AND e.fecha >= $2
   AND eu.estado <> 'Cancelo'
 GROUP BY o.id_usuario, o.nombres, o.apellidos, tuo.nombre, te.nombre
HAVING COUNT(*) >= 10
 ORDER BY participantes_confirmados DESC, organizador;

EXECUTE stmt_analisis_participacion_eventos (3, DATE '2024-01-01');   -- Taller desde 2024
EXECUTE stmt_analisis_participacion_eventos (9, DATE '2023-01-01');   -- Reunion Semillero desde 2023

SELECT name, parameter_types FROM pg_prepared_statements;
DEALLOCATE stmt_analisis_participacion_eventos;
SELECT name FROM pg_prepared_statements WHERE name = 'stmt_analisis_participacion_eventos';  -- 0 filas

SELECT pg_current_wal_lsn() AS wal_antes;

BEGIN;
  INSERT INTO evento (id_usuario, id_tipo_evento, nombre, descripcion, fecha, lugar)
  VALUES ((SELECT MIN(u.id_usuario) FROM usuario u
            WHERE u.id_rol = (SELECT id_rol FROM rol WHERE nombre = 'Miembro')
              AND u.estado = 'Activo'),
          (SELECT id_tipo_evento FROM tipo_evento WHERE nombre = 'Taller'),
          'Taller Durabilidad ACID',
          'Evento creado para demostrar la durabilidad (COMMIT)',
          TIMESTAMP '2026-12-15 14:00', 'Aula 301');

  INSERT INTO evento_usuario (id_evento, id_usuario)
  SELECT e.id_evento,
         (SELECT MIN(u.id_usuario) FROM usuario u
           WHERE u.id_rol = (SELECT id_rol FROM rol WHERE nombre = 'Miembro')
             AND u.estado = 'Activo'
             AND u.id_usuario > e.id_usuario)
    FROM evento e WHERE e.nombre = 'Taller Durabilidad ACID';
COMMIT;   -- cambios CONFIRMADOS y grabados en disco (WAL)

SELECT e.id_evento, e.nombre, e.fecha, o.nombres AS organizador,
       p.nombres AS participante, eu.estado
  FROM evento e
  JOIN usuario o ON o.id_usuario = e.id_usuario
  JOIN evento_usuario eu ON eu.id_evento = e.id_evento
  JOIN usuario p ON p.id_usuario = eu.id_usuario
 WHERE e.nombre = 'Taller Durabilidad ACID';

SELECT pg_current_wal_lsn() AS wal_despues;   -- avanzo: el COMMIT quedo en el registro durable
SHOW synchronous_commit;                      -- 'on': COMMIT espera a que el WAL este en disco

SELECT
    current_schema() AS esquema_actual,
    current_setting('search_path') AS ruta_busqueda;