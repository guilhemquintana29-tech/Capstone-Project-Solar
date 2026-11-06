-- 01_data_checks.sql : verify the tables loaded from Python
SET search_path TO s_guilhemquintana;

-- 1. Row counts (expected: ~54 for the summary)
SELECT 'centrales_pv' AS table_name, COUNT(*) AS n FROM centrales_pv
UNION ALL SELECT 'synthese_dep_edition', COUNT(*) FROM synthese_dep_edition
UNION ALL SELECT 'comparaison_pvgis', COUNT(*) FROM comparaison_pvgis;

-- 2. Exact column names and types
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = current_schema()
  AND table_name IN ('centrales_pv', 'synthese_dep_edition', 'comparaison_pvgis')
ORDER BY table_name, ordinal_position;

-- 3. Is the primary key already there?
SELECT table_name, constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = current_schema() AND constraint_type = 'PRIMARY KEY';

-- 4. Duplicate keys and missing keys in the summary (both should return 0 rows / 0)
SELECT code_departement, edition, COUNT(*) AS n
FROM synthese_dep_edition
GROUP BY code_departement, edition
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS null_keys
FROM synthese_dep_edition
WHERE code_departement IS NULL OR edition IS NULL;

-- 5. Department codes must be text with their leading zero
SELECT DISTINCT code_departement FROM synthese_dep_edition ORDER BY 1;

-- 6. Reference values: 2025 density in kW/ha (1 MW/km2 = 10 kW/ha)
SELECT code_departement, departement,
       ROUND((puissance_mw_km2 * 10)::numeric, 3) AS kw_par_ha_2025
FROM synthese_dep_edition
WHERE edition = 2025
ORDER BY kw_par_ha_2025 DESC;