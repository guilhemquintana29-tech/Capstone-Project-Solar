-- 03_views_tableau.sql : views read by Tableau (no calculation needed in Tableau)
SET search_path TO s_guilhemquintana;

-- 1. One row per department and year
CREATE OR REPLACE VIEW vw_pv_evolution AS
SELECT s.code_departement, s.departement, s.edition, s.centrales, s.puissance_mw,
       s.puissance_mw - LAG(s.puissance_mw) OVER w                              AS ajout_mw,
       100 * (s.puissance_mw - LAG(s.puissance_mw) OVER w)
           / NULLIF(LAG(s.puissance_mw) OVER w, 0)                              AS croissance_pct,
       s.puissance_mw_km2 * 10                                                  AS kw_par_ha,
       RANK() OVER (PARTITION BY s.edition ORDER BY s.puissance_mw_km2 DESC)    AS rang_densite,
       s.injectee_gwh, s.injectee_gwh_km2 * 10                                  AS injectee_mwh_par_ha,
       s.productible_gwh_km2 * 10                                               AS productible_mwh_par_ha,
       s.part_prod_renseignee, s.superficie_km2,
       CASE WHEN s.code_departement = '26' THEN 'Drôme' ELSE 'Voisin' END      AS groupe
FROM synthese_dep_edition s
WINDOW w AS (PARTITION BY s.code_departement ORDER BY s.edition);

-- 2. Drôme versus neighbours and Vaucluse, one row per year
CREATE OR REPLACE VIEW vw_pv_drome_vs_voisins AS
WITH d AS (
  SELECT edition,
         MAX(puissance_mw_km2) FILTER (WHERE code_departement = '26') AS drome,
         MAX(puissance_mw_km2) FILTER (WHERE code_departement = '84') AS vaucluse,
         AVG(puissance_mw_km2) FILTER (WHERE code_departement <> '26') AS moy_voisins
  FROM synthese_dep_edition GROUP BY edition
)
SELECT edition,
       drome * 10 AS drome_kw_ha, moy_voisins * 10 AS voisins_kw_ha, vaucluse * 10 AS vaucluse_kw_ha,
       100 * drome / moy_voisins AS drome_pct_voisins,
       100 * drome / vaucluse    AS drome_pct_vaucluse,
       (vaucluse - drome) * 10   AS ecart_vaucluse_kw_ha
FROM d;

-- 3. Empirical yield versus PVGIS
CREATE OR REPLACE VIEW vw_pv_pvgis AS
SELECT code_departement, departement, rend_ref_kwh_kw, productible_pvgis_kwh_kwc,
       irradiation_plan_kwh_m2, ecart_pct
FROM comparaison_pvgis;

-- 4. Remaining potential: INDICATIVE benchmark (Vaucluse 2025 density applied to the Drôme)
CREATE OR REPLACE VIEW vw_pv_potentiel_benchmark AS
WITH p AS (
  SELECT MAX(puissance_mw) FILTER (WHERE edition = 2017) AS p2017,
         MAX(puissance_mw) FILTER (WHERE edition = 2022) AS p2022,
         MAX(puissance_mw) FILTER (WHERE edition = 2024) AS p2024,
         MAX(puissance_mw) FILTER (WHERE edition = 2025) AS p2025,
         MAX(superficie_km2) AS superficie_km2, MAX(rend_ref_kwh_kw) AS rend_ref
  FROM synthese_dep_edition WHERE code_departement = '26'
), v AS (
  SELECT puissance_mw_km2 AS dens_vaucluse
  FROM synthese_dep_edition WHERE code_departement = '84' AND edition = 2025
), g AS (SELECT p.*, v.dens_vaucluse * p.superficie_km2 AS benchmark_mw FROM p CROSS JOIN v)
SELECT s.scenario,
       ROUND(g.p2025::numeric, 1)                                      AS drome_2025_mw,
       ROUND(g.benchmark_mw::numeric, 1)                               AS benchmark_mw,
       ROUND((g.benchmark_mw - g.p2025)::numeric, 1)                   AS ecart_mw,
       ROUND(((g.benchmark_mw - g.p2025) * g.rend_ref / 1000)::numeric, 0) AS ecart_gwh_par_an,
       ROUND(s.rythme_mw_an::numeric, 1)                               AS rythme_mw_par_an,
       ROUND(((g.benchmark_mw - g.p2025) / s.rythme_mw_an)::numeric, 1) AS annees_pour_combler
FROM g CROSS JOIN LATERAL (VALUES
  ('Moyenne 2018-2025', (g.p2025 - g.p2017) / 8),
  ('Moyenne 2023-2025', (g.p2025 - g.p2022) / 3),
  ('2025 seul',         g.p2025 - g.p2024)
) AS s(scenario, rythme_mw_an);