-- 02_indicators.sql : trend indicators from synthese_dep_edition
SET search_path TO ton_schema;

-- A. Annual additions (MW) and growth rate
WITH base AS (
  SELECT code_departement, departement, edition, puissance_mw,
         LAG(puissance_mw) OVER (PARTITION BY code_departement ORDER BY edition) AS puissance_prec
  FROM synthese_dep_edition
)
SELECT code_departement, departement, edition,
       ROUND(puissance_mw::numeric, 1)                                   AS puissance_mw,
       ROUND((puissance_mw - puissance_prec)::numeric, 1)                AS ajout_mw,
       ROUND((100 * (puissance_mw - puissance_prec)
              / NULLIF(puissance_prec, 0))::numeric, 1)                  AS croissance_pct
FROM base
ORDER BY code_departement, edition;

-- B. Density ranking per edition (kW/ha = MW/km2 x 10)
SELECT edition, code_departement, departement,
       ROUND((puissance_mw_km2 * 10)::numeric, 3)                        AS kw_par_ha,
       RANK() OVER (PARTITION BY edition ORDER BY puissance_mw_km2 DESC) AS rang
FROM synthese_dep_edition
ORDER BY edition, rang;

-- C. Drome versus the average of its 5 neighbours and versus Vaucluse
WITH d AS (
  SELECT edition,
         MAX(puissance_mw_km2) FILTER (WHERE code_departement = '26') AS drome,
         MAX(puissance_mw_km2) FILTER (WHERE code_departement = '84') AS vaucluse,
         AVG(puissance_mw_km2) FILTER (WHERE code_departement <> '26') AS moy_voisins
  FROM synthese_dep_edition
  GROUP BY edition
)
SELECT edition,
       ROUND((drome * 10)::numeric, 3)                    AS drome_kw_ha,
       ROUND((moy_voisins * 10)::numeric, 3)              AS voisins_kw_ha,
       ROUND((vaucluse * 10)::numeric, 3)                 AS vaucluse_kw_ha,
       ROUND((100 * drome / moy_voisins)::numeric, 0)     AS drome_pct_voisins,
       ROUND((100 * drome / vaucluse)::numeric, 0)        AS drome_pct_vaucluse,
       ROUND(((vaucluse - drome) * 10)::numeric, 3)       AS ecart_vaucluse_kw_ha
FROM d
ORDER BY edition;

-- D. PVGIS comparison (already one row per department)
SELECT code_departement, departement, rend_ref_kwh_kw, productible_pvgis_kwh_kwc,
       ROUND(ecart_pct::numeric, 1) AS ecart_pct
FROM comparaison_pvgis
ORDER BY ecart_pct;