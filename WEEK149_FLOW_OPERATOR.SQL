CREATE OR REPLACE PROCEDURE gen_timeseries(start_date DATE, days INTEGER, category STRING, seed INTEGER)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python', 'numpy')
HANDLER = 'run'
AS
$$
import numpy as np
import datetime

def run(session, start_date, days, category, seed):
    # Make the RNG deterministic for reproducibility
    rng = np.random.default_rng(int(seed) if seed is not None else 42)

    base = datetime.date.fromisoformat(str(start_date))
    rows = []

    # Start at 100 and add small Gaussian noise each day
    value = 100.0
    for i in range(int(days)):
        day = base + datetime.timedelta(days=i)
        value = max(0.0, value + float(rng.normal(0, 3)))  # keep non-negative
        rows.append({
            "date": str(day),
            "category": category,
            "value": round(value, 2)
        })

    # Compute a 3-day trailing moving average
    for i, r in enumerate(rows):
        window = rows[max(0, i-2):i+1]
        ma = sum(x["value"] for x in window) / len(window)
        r["moving_avg"] = round(ma, 2)
        r["day_index"] = i + 1

    return {
        "meta": {
            "start_date": str(base),
            "days": int(days),
            "category": category
        },
        "rows": rows
    }
$$;

--SOLUTION

CALL gen_timeseries('2025-04-01'::DATE, 7, 'WIDGETS', 123)
->> SELECT f.value:date::date AS TS_DATE,
f.value:category::STRING AS category,
f.value:value::FLOAT AS value,
f.value:moving_avg::FLOAT AS moving_avg,
f.value:day_index::INT AS day_index
FROM $1,LATERAL FLATTEN(input => "GEN_TIMESERIES":rows) f;
