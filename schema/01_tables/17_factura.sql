-- Tabla factura (R10).
--
-- Documento contable emitido por fn_calcular_factura cuando finaliza un
-- alquiler. Materializa el resultado de la facturacion: precio aplicado,
-- recargo por horas excedidas, costo base y total. La secuencia
-- seq_numero_factura provee la numeracion correlativa (campo
-- numero_factura) independiente del id_factura interno.
--
-- Aporte original: Marcia Viera (commit 257d86f, "funcionalidad finalizar
-- alquiler"), adaptado al esquema actual.
CREATE SEQUENCE IF NOT EXISTS seq_numero_factura START WITH 1;

CREATE TABLE IF NOT EXISTS factura (
    id_factura                     BIGSERIAL      PRIMARY KEY,
    id_alquiler                    BIGINT         NOT NULL UNIQUE,
    id_cliente                     BIGINT         NOT NULL,
        -- DECISION DE DISENIO: id_cliente se duplica respecto
        -- de alquiler.id_cliente INTENCIONALMENTE. La factura es un documento
        -- contable inmutable: si en el futuro se reasigna el alquiler a otro
        -- cliente (caso corporativo, transferencia, error administrativo), la
        -- factura debe conservar al cliente que firmo y pago en su momento.
        -- Es una denormalizacion controlada que preserva la copia del valor
        -- vigente al momento de emision. Para obtener el cliente actual del
        -- alquiler, consultar via JOIN con alquiler.
    numero_factura                 VARCHAR(30)    NOT NULL UNIQUE,
    fecha_emision                  DATE           NOT NULL DEFAULT CURRENT_DATE,
    precio_por_dia_aplicado        NUMERIC(12, 2) NOT NULL,
    porcentaje_recargo_aplicado    NUMERIC(5, 2)  NOT NULL,
    costo_base                     NUMERIC(12, 2) NOT NULL,
    horas_excedidas                NUMERIC(6, 2)  NOT NULL DEFAULT 0,
    recargo_excedente              NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total                          NUMERIC(12, 2) NOT NULL,
    CONSTRAINT chk_factura_precio_dia    CHECK (precio_por_dia_aplicado >= 0),
    CONSTRAINT chk_factura_recargo_pct   CHECK (porcentaje_recargo_aplicado >= 0),
    CONSTRAINT chk_factura_costo_base    CHECK (costo_base >= 0),
    CONSTRAINT chk_factura_horas         CHECK (horas_excedidas >= 0),
    CONSTRAINT chk_factura_recargo_exc   CHECK (recargo_excedente >= 0),
    CONSTRAINT chk_factura_total         CHECK (total >= 0)
);
