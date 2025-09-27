CALL gen_timeseries('2025-04-01'::DATE, 7, 'WIDGETS', 123)
->> SELECT f.value:date::date AS TS_DATE,
f.value:category::STRING AS category,
f.value:value::FLOAT AS value,
f.value:moving_avg::FLOAT AS moving_avg,
f.value:day_index::INT AS day_index
FROM $1,LATERAL FLATTEN(input => "GEN_TIMESERIES":rows) f;