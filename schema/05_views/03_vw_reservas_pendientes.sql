-- vw_reservas_pendientes -- reservas pendientes con cliente, vehiculo, tipo y marca de garantia activa
--
-- Etapa 2 (R3): vista para la cola de retiros pendientes en sucursal.
-- Combina reserva + cliente + vehiculo + tipo_reserva, y agrega una marca
-- garantia_activa via EXISTS sobre garantia_reserva (cualquier garantia con
-- activa=TRUE). La marca distingue entre "el tipo de reserva exige garantia"
-- (requiere_garantia) y "la garantia esta efectivamente cargada y vigente"
-- (garantia_activa).
--
-- Acceso: SELECT a staff, authenticated (el cliente final ve solo SUS reservas
-- via RLS sobre reserva), service_role y quique.

CREATE OR REPLACE VIEW vw_reservas_pendientes AS
SELECT
    r.id_reserva,
    r.fecha_inicio,
    r.fecha_fin_prevista,
    r.fecha_creacion,
    r.estado,
    -- Cliente
    c.id_cliente,
    c.nombre        AS cliente_nombre,
    c.apellido      AS cliente_apellido,
    c.dni           AS cliente_dni,
    -- Vehiculo
    v.id_vehiculo,
    v.patente,
    v.marca,
    v.modelo,
    -- Tipo de reserva
    tr.id_tipo_reserva,
    tr.nombre               AS tipo_reserva,
    tr.requiere_garantia,
    -- Flag garantia efectivamente cargada y activa
    EXISTS (
        SELECT 1
        FROM garantia_reserva g
        WHERE g.id_reserva = r.id_reserva
          AND g.activa = TRUE
    ) AS garantia_activa
FROM reserva r
JOIN cliente      c  ON c.id_cliente      = r.id_cliente
JOIN vehiculo     v  ON v.id_vehiculo     = r.id_vehiculo
JOIN tipo_reserva tr ON tr.id_tipo_reserva = r.id_tipo_reserva
WHERE r.estado = 'pendiente';

COMMENT ON VIEW vw_reservas_pendientes IS
'R3 Etapa 2: reservas pendientes con cliente + vehiculo + tipo_reserva y marca garantia_activa (EXISTS sobre garantia_reserva con activa=TRUE).';
