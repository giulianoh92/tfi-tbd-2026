-- Bootstrap de tareas programadas (demo / datos iniciales).
--
-- Las tareas R12 y R13 normalmente las dispara pg_cron (diaria / mensual).
-- Para que, recien aplicado el schema con seeds, los informes muestren
-- resultados SIN esperar a que el cron corra, se invocan una vez aca al final
-- del seeding. apply.sh procesa 08_seeds/ en ultimo lugar, por lo que en este
-- punto ya estan cargados clientes, reservas, alquileres y facturas.
--
-- Ambas son idempotentes: como apply.sh recrea el schema en cada corrida, no
-- hay riesgo de doble efecto entre despliegues.
--   * pa_cerrar_facturacion_mensual: consolida el mes anterior en
--     resumen_mensual_sucursal (alimenta /admin/reportes-mensuales).
--   * pa_expirar_reservas_vencidas: cancela las reservas pendientes vencidas
--     (no-show) de los seeds y desactiva sus garantias; el efecto queda
--     trazado en audit_log.
CALL pa_cerrar_facturacion_mensual();
CALL pa_expirar_reservas_vencidas();
