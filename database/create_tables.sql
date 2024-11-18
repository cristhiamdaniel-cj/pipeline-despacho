-- Crear base de datos (ejecutar solo si no existe)
-- CREATE DATABASE alcaldia_db_local;

-- Eliminar tablas si ya existen para evitar conflictos
DO $$
DECLARE
    tbl RECORD;
BEGIN
    FOR tbl IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(tbl.tablename) || ' CASCADE';
    END LOOP;
END $$;

-- Crear tabla Perfiles
CREATE TABLE Perfiles (
    ID SERIAL PRIMARY KEY,
    NombrePerfil VARCHAR(100) NOT NULL UNIQUE
);

-- Crear tabla Areas
CREATE TABLE Areas (
    ID SERIAL PRIMARY KEY,
    NombreArea VARCHAR(100) NOT NULL UNIQUE
);

-- Crear tabla Subgrupos
CREATE TABLE Subgrupos (
    ID SERIAL PRIMARY KEY,
    NombreSubgrupo VARCHAR(100) NOT NULL UNIQUE,
    AreaID INT REFERENCES Areas(ID) ON DELETE CASCADE
);

-- Crear tabla Roles
CREATE TABLE Roles (
    ID SERIAL PRIMARY KEY,
    NombreRol VARCHAR(100) NOT NULL UNIQUE
);

-- Crear tabla Riesgos
CREATE TABLE Riesgos (
    ID SERIAL PRIMARY KEY,
    Nivel INT CHECK (Nivel BETWEEN 1 AND 5) NOT NULL
);

-- Crear tabla Estados
CREATE TABLE Estados (
    ID SERIAL PRIMARY KEY,
    EstadoProceso VARCHAR(100) NOT NULL UNIQUE
);

-- Crear tabla Movimientos
CREATE TABLE Movimientos (
    ID SERIAL PRIMARY KEY,
    TipoMovimiento VARCHAR(100) NOT NULL UNIQUE
);

-- Crear tabla Usuarios
CREATE TABLE Usuarios (
    ID SERIAL PRIMARY KEY,
    ApellidoPaterno VARCHAR(100) NOT NULL,
    ApellidoMaterno VARCHAR(100),
    Nombres VARCHAR(100) NOT NULL,
    Identificacion VARCHAR(50) UNIQUE NOT NULL,
    Telefono VARCHAR(10) NOT NULL CHECK (Telefono ~ '^\d{10}$' OR Telefono = '0'), -- Solo 10 dígitos o '0'
    PerfilID INT REFERENCES Perfiles(ID),
    AreaID INT REFERENCES Areas(ID),
    SubgrupoID INT REFERENCES Subgrupos(ID),
    RolID INT REFERENCES Roles(ID),
    RiesgoID INT REFERENCES Riesgos(ID),
    EstadoID INT REFERENCES Estados(ID) -- Estado actual del usuario
);

-- Crear tabla Contratos
CREATE TABLE Contratos (
    ID SERIAL PRIMARY KEY,
    NumeroContrato VARCHAR(100) NOT NULL UNIQUE,
    Honorarios NUMERIC NOT NULL,
    CodigoSIPSE VARCHAR(50),
    CodigoCDP VARCHAR(50),
    CodigoCRP VARCHAR(50),
    FechaInicio DATE NOT NULL,
    FechaFin DATE NOT NULL,
    UsuarioID INT REFERENCES Usuarios(ID) ON DELETE CASCADE,
    MovimientoID INT REFERENCES Movimientos(ID) ON DELETE SET NULL, -- Estado del contrato
    CHECK (FechaInicio <= FechaFin)
);

-- Crear tabla Notas
CREATE TABLE Notas (
    ID SERIAL PRIMARY KEY,
    UsuarioID INT REFERENCES Usuarios(ID) ON DELETE CASCADE,
    GrupoAlcaldia INT NOT NULL CHECK (GrupoAlcaldia > 0),
    NotaTexto TEXT
);

-- Crear tabla HojasDeVida
CREATE TABLE HojasDeVida (
    ID SERIAL PRIMARY KEY,
    UsuarioID INT REFERENCES Usuarios(ID) ON DELETE CASCADE,
    URL TEXT NOT NULL, -- Ajustamos a TEXT para URL largas
    FechaSubida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    EstadoDocumento VARCHAR(50) DEFAULT 'Activo'
);

-- Crear tabla RolesAplicacion
CREATE TABLE RolesAplicacion (
    ID SERIAL PRIMARY KEY,
    NombreRol VARCHAR(50) NOT NULL UNIQUE
);

-- Crear tabla UsuariosAplicacion
CREATE TABLE UsuariosAplicacion (
    ID SERIAL PRIMARY KEY,
    UsuarioAplicacion VARCHAR(100) NOT NULL UNIQUE,
    Correo VARCHAR(100) NOT NULL UNIQUE,
    Contraseña BYTEA NOT NULL,
    RolAplicacionID INT REFERENCES RolesAplicacion(ID)
);

-- Crear tabla Auditorias
CREATE TABLE Auditorias (
    ID SERIAL PRIMARY KEY,
    UsuarioAplicacionID INT REFERENCES UsuariosAplicacion(ID) ON DELETE CASCADE,
    Accion VARCHAR(100) NOT NULL,
    FechaHora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    RegistroModificado INT,
    TablaModificada VARCHAR(100)
);

-- Índices para optimizar consultas
CREATE INDEX idx_usuarios_identificacion ON Usuarios(Identificacion);
CREATE INDEX idx_contratos_fechas ON Contratos(FechaInicio, FechaFin);
CREATE INDEX idx_hojasdevida_url ON HojasDeVida(URL);
CREATE INDEX idx_usuariosaplicacion_correo ON UsuariosAplicacion(Correo);
CREATE INDEX idx_auditorias_fecha ON Auditorias(FechaHora);
