CREATE SEQUENCE IF NOT EXISTS seq_numero_factura START WITH 1;

CREATE TABLE IF NOT EXISTS factura (
    id_factura                  BIGSERIAL      PRIMARY KEY,
    id_alquiler                 BIGINT         NOT NULL UNIQUE,
    id_cliente                  BIGINT         NOT NULL,
    numero_factura              VARCHAR(30)    NOT NULL UNIQUE,
    fecha_emision               TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Campos Snapshot (Datos históricos de la tarifa)
    precio_por_dia_aplicado     NUMERIC(12, 2) NOT NULL,
    porcentaje_recargo_aplicado NUMERIC(5, 2)  NOT NULL, 
    
    -- Totales económicos
    costo_base                  NUMERIC(12, 2) NOT NULL,
    horas_excedidas             INT            NOT NULL DEFAULT 0,
    recargo_excedente           NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total                       NUMERIC(12, 2) NOT NULL,
    
    CONSTRAINT chk_factura_montos CHECK (
        precio_por_dia_aplicado     >= 0
        AND porcentaje_recargo_aplicado >= 0
        AND costo_base              >= 0
        AND horas_excedidas         >= 0
        AND recargo_excedente       >= 0
        AND total                   >= 0
    ),
    CONSTRAINT fk_factura_alquiler FOREIGN KEY (id_alquiler) REFERENCES alquiler(id_alquiler),
    CONSTRAINT fk_factura_cliente  FOREIGN KEY (id_cliente)  REFERENCES cliente(id_cliente)
);