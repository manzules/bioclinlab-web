-- =====================================================
-- SCRIPT SQL CORREGIDO PARA BIOCLINLAB
-- Ejecutar esto en el SQL Editor de Supabase
-- =====================================================

-- 1. Limpiar TODO (politicas, tablas, vista)
DROP POLICY IF EXISTS "Allow public read pacientes" ON pacientes;
DROP POLICY IF EXISTS "Allow public insert pacientes" ON pacientes;
DROP POLICY IF EXISTS "Allow public delete pacientes" ON pacientes;
DROP POLICY IF EXISTS "Allow public read resultados" ON resultados;
DROP POLICY IF EXISTS "Allow public insert resultados" ON resultados;
DROP POLICY IF EXISTS "Allow public delete resultados" ON resultados;
DROP POLICY IF EXISTS "Allow anon read pacientes" ON pacientes;
DROP POLICY IF EXISTS "Allow anon insert pacientes" ON pacientes;
DROP POLICY IF EXISTS "Allow anon delete pacientes" ON pacientes;
DROP POLICY IF EXISTS "Allow anon read resultados" ON resultados;
DROP POLICY IF EXISTS "Allow anon insert resultados" ON resultados;
DROP POLICY IF EXISTS "Allow anon delete resultados" ON resultados;

DROP VIEW IF EXISTS vista_resultados;

DROP TABLE IF EXISTS resultados;
DROP TABLE IF EXISTS pacientes;

-- 2. Crear tabla de pacientes (con columna password para login)
CREATE TABLE IF NOT EXISTS pacientes (
    id SERIAL PRIMARY KEY,
    cedula VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    telefono VARCHAR(20),
    password VARCHAR(255),
    fecha_registro TIMESTAMP DEFAULT NOW()
);

-- 3. Crear tabla de resultados
CREATE TABLE IF NOT EXISTS resultados (
    id SERIAL PRIMARY KEY,
    paciente_id INTEGER REFERENCES pacientes(id) ON DELETE CASCADE,
    numero_orden VARCHAR(20) NOT NULL,
    fecha_examen DATE NOT NULL,
    examenes TEXT NOT NULL,
    estado VARCHAR(20) DEFAULT 'proceso' CHECK (estado IN ('listo', 'proceso')),
    pdf_url TEXT,
    fecha_subida TIMESTAMP DEFAULT NOW()
);

-- 4. Insertar pacientes de ejemplo (incluyendo password)
INSERT INTO pacientes (cedula, nombre, email, telefono, password) VALUES
('1234567890', 'MARIO ANDRES ANZULES MERO', 'mario@email.com', '0997724489', '123456'),
('0987654321', 'JUAN PEREZ LOPEZ', 'juan@email.com', '0988500533', '123456');

-- 5. Insertar resultados de ejemplo
INSERT INTO resultados (paciente_id, numero_orden, fecha_examen, examenes, estado) VALUES
(1, '260615001', '2026-06-15', 'Hemograma Completo, Glucosa', 'listo'),
(1, '260610005', '2026-06-10', 'Perfil Lipidico, Creatinina', 'listo'),
(1, '260605012', '2026-06-05', 'TSH, T4 Libre', 'proceso'),
(2, '260620003', '2026-06-20', 'Urocultivo, Antibiograma', 'listo');

-- 6. Activar Row Level Security
ALTER TABLE pacientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE resultados ENABLE ROW LEVEL SECURITY;

-- 7. Crear politicas EXPLICITAS para rol ANON (usuarios no autenticados)
-- Esto es lo mas importante: usar TO anon en lugar de depender del rol PUBLIC

-- PACIENTES: SELECT para anon
CREATE POLICY "Allow anon read pacientes" ON pacientes
    FOR SELECT
    TO anon
    USING (true);

-- PACIENTES: INSERT para anon (registro desde la web)
CREATE POLICY "Allow anon insert pacientes" ON pacientes
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- PACIENTES: DELETE para anon
CREATE POLICY "Allow anon delete pacientes" ON pacientes
    FOR DELETE
    TO anon
    USING (true);

-- RESULTADOS: SELECT para anon
CREATE POLICY "Allow anon read resultados" ON resultados
    FOR SELECT
    TO anon
    USING (true);

-- RESULTADOS: INSERT para anon
CREATE POLICY "Allow anon insert resultados" ON resultados
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- RESULTADOS: DELETE para anon
CREATE POLICY "Allow anon delete resultados" ON resultados
    FOR DELETE
    TO anon
    USING (true);

-- 8. Crear vista
CREATE OR REPLACE VIEW vista_resultados AS
SELECT 
    r.id,
    r.numero_orden,
    r.fecha_examen,
    r.examenes,
    r.estado,
    r.pdf_url,
    p.cedula,
    p.nombre as paciente_nombre
FROM resultados r
JOIN pacientes p ON r.paciente_id = p.id;

-- 9. Verificar que todo quedo bien
SELECT 'Tablas creadas: ' || COUNT(*)::text as status 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name IN ('pacientes', 'resultados');

SELECT 'Politicas activas: ' || COUNT(*)::text as status 
FROM pg_policies 
WHERE tablename IN ('pacientes', 'resultados');

SELECT 'Pacientes registrados: ' || COUNT(*)::text as status FROM pacientes;
SELECT 'Resultados registrados: ' || COUNT(*)::text as status FROM resultados;

SELECT 'Base de datos BIOCLINLAB configurada correctamente!' as mensaje;
