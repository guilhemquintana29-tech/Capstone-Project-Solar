
# Capstone-Project-Solar

**Photovoltaic power plants in the Drôme (2017–2025): installed capacity, energy per area and remaining potential, compared with the five neighbouring departments.**

> **Status:** data preparation, validation and first indicators are complete. The projection, the definition of "remaining potential", the SQL layer and the Power BI dashboard are still to do.

---

## 1. Project at a glance

**Research question**

> Between 2017 and 2025, how has electricity production from photovoltaic power plants (installations of 36 kW and above) evolved in the Drôme department, relative to the department's land area (MWh per hectare per year), compared with its five neighbouring departments (Ardèche, Isère, Hautes-Alpes, Alpes-de-Haute-Provence and Vaucluse)? And what share of the Drôme's theoretical solar potential remains to be exploited over the next 5 to 10 years?

| Item            | Choice                                                                                                                          |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Area studied    | Drôme (26) and its five neighbours: Ardèche (07), Isère (38), Hautes-Alpes (05), Alpes-de-Haute-Provence (04), Vaucluse (84) |
| Period          | 2017–2025 (one edition of the register per year); the 2026 file is a partial-year snapshot and is kept apart                   |
| Installations   | Photovoltaic plants of 36 kW and above, one line per plant                                                                      |
| Main indicators | Capacity per area (kW/ha), energy injected per area (MWh/ha), empirical yield (kWh/kW), PVGIS theoretical yield                 |
| Tools           | Python (pandas, Jupyter) for preparation; SQL and Power BI planned for analysis and dashboard                                   |

---

## 2. Repository structure

```
Capstone-Project-Solar/
├── dataset/
│   ├── data raw/                      # original CSV files, never modified
│   └── data clean/                    # outputs of the notebooks
├── csv_check.ipynb                    # data preparation, validation, area indicators
├── pvgis_potentiel_solaire.ipynb      # PVGIS theoretical yield and comparison
└── README.md
```

**Files produced in `dataset/data clean/`**

| File                                | Content                                                                                                                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `centrales_pv_6dep.csv`           | One line per plant and per edition (2017–2026): department, commune, connection date, power in kW, source of the power value, energy injected in kWh                                 |
| `synthese_dep_edition.csv`        | One line per department and per year (2017–2025): number of plants, power (MW), energy injected (GWh), reference yield, normalised productible, area, power and productible per km² |
| `potentiel_solaire_PVGIS.csv`     | PVGIS yield and irradiation for one reference point per department                                                                                                                    |
| `comparaison_PVGIS_empirique.csv` | Empirical reference yield against PVGIS yield, per department                                                                                                                         |

---

## 3. Data sources

| Source                                                                                                                                                                                                                                                                                 | Use                                                                                                     |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **National register of electricity production and storage installations** (Open Data Réseaux Énergies / Agence ORE, published on [data.gouv.fr](https://www.data.gouv.fr/datasets/registre-national-des-installations-de-production-et-de-stockage-delectricite-au-31-08-2026)) | Plant-level data: location, connection date, power, energy injected. One edition per year, 2017 to 2026 |
| **PVGIS** (European Commission, [API documentation](https://joint-research-centre.ec.europa.eu/photovoltaic-geographical-information-system-pvgis/using-pvgis-5/api-non-interactive-service_en))                                                                                  | Theoretical annual yield per kWp (tool PVcalc, API v5.3)                                                |
| **Department areas**                                                                                                                                                                                                                                                             | Entered by hand in `csv_check.ipynb` (see Limitations)                                                |

**How to find the other years.** The 2026 file is the snapshot at **31 August 2026**. The 2017–2025 editions are year-end snapshots, published under titles of the form **"Registre national des installations de production et de stockage d'électricité (au 31/12/20XX)"** (older ones read "au 31 décembre 20XX"), on data.gouv.fr and on the ODRE portal. Avoid datasets marked as no longer maintained.

The raw files are saved as `YYYY-installation-production-stockage-electricite-agrege.csv` (separator `;`, UTF-8) in `dataset/data raw/`. They are large (the 2026 file is about 43 MB), so download them from the sources above if they are not in the repository.

---

## 4. What has been done

**Stage 1: data preparation and validation (`csv_check.ipynb`)**

1. Downloaded the 10 yearly editions and checked their structure (separator, encoding, number of rows and columns, column names).
2. Kept only solar lines in the six departments.
3. Separated **individual plants** (one line per plant) from **aggregated lines** (10–20 small installations grouped in one line) and kept only the individual plants.
4. Kept only photovoltaic technology.
5. Built one **power value per plant**: installed power, or connection power when the first is empty.
6. Chose one **energy column**: energy injected into the grid, whatever the name used in each edition.
7. Stacked the 10 editions into one table (a panel) and ran the validation checks below.
8. Built a **department-by-year summary** (2017–2025).
9. Computed a **reference yield** per department (energy per kW for plants that had a full year of operation).
10. Added **department areas** and computed capacity and productible per km².

**Stage 2: theoretical yield (`pvgis_potentiel_solaire.ipynb`)**

1. Queried PVGIS for one reference point per department (its prefecture), with the same settings everywhere: 1 kWp, crystalline silicon, fixed mounting, 35° tilt, south-facing, 14% losses.
2. Compared the PVGIS yield with the empirical reference yield.

---

## 5. What the data showed, and the rules that follow

| Finding                                                                                                                                                                         | Decision                                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| The register mixes individual plants and aggregated lines. In 2026, individual plants carry about 79% of solar capacity in the six departments.                                 | Keep individual plants (36 kW and above). Exclude aggregated lines.                                              |
| Connection dates of aggregated lines are not credible (2001–2023, median 2009), and their total power changes definition between editions (46.6 MW in 2019, 149.8 MW in 2020). | Aggregated lines are not used for any trend. A residential study would need a separate source.                   |
| The 36 kW threshold is already applied: no individual plant is below 36.96 kW.                                                                                                  | No extra power filter.                                                                                           |
| Installed power is empty for many plants in old editions (26% in 2017, 19% in 2018, 11% in 2019, 4% in 2020, under 0.2% afterwards).                                            | Complete it with connection power and record the origin in a `source_puis` column.                             |
| Energy columns are named differently before 2020, and one of them is almost empty.                                                                                              | Use the "injected" column in all editions.                                                                       |
| Editions are not exact 31 December snapshots: 48 plant-lines (about 10.8 MW) have a connection date after the end of their edition.                                             | Keep them (at most 0.35% of an edition's capacity). Index the series on the edition, not on the connection date. |
| Decommissioned plants do not appear in a later edition.                                                                                                                         | Effect looks small: 97% of the 2017 plants are still in the 2026 file.                                           |
| Plants connected during the year have produced only part of a year.                                                                                                             | Compute reference yields on "mature" plants only (connected before 1 January of the year before the edition).    |

---

## 6. Validation checks

| Check                                                                      | Result                                                                                             |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| Panel capacity against an independent reconstruction from connection dates | Difference of 2.1% in 2017, under 1% in every later year                                           |
| Duplicate lines (same plant, same edition)                                 | None                                                                                               |
| Missing energy values on mature plants                                     | 0.7% to 2.5%                                                                                       |
| Unit of energy and power                                                   | kWh and kW; median yields of about 1,250–1,380 kWh/kW                                             |
| Department codes                                                           | Kept as text (so that "04", "05", "07" keep their zero)                                            |
| Summary file                                                               | 54 rows (6 departments × 9 years), no duplicate department–year                                  |
| Missing values in area indicators                                          | None                                                                                               |
| Recalculated power and productible per km² against the exported values    | Identical (differences of about 1e-16). This confirms the arithmetic of the export, not the inputs |

---

## 7. Early results (preliminary)

**Installed capacity of plants of 36 kW and above**

| Department                 | 2017 (MW)      | 2025 (MW)       | Gain (MW)        | 2025 density (kW/ha) | Rank 2025   |
| -------------------------- | -------------- | --------------- | ---------------- | -------------------- | ----------- |
| 84 Vaucluse                | 81.3           | 316.8           | +235.5           | 0.888                | 1           |
| 04 Alpes-de-Haute-Provence | 289.0          | 486.9           | +197.9           | 0.703                | 2           |
| **26 Drôme**        | **81.2** | **367.1** | **+285.9** | **0.562**      | **3** |
| 05 Hautes-Alpes            | 52.5           | 229.3           | +176.8           | 0.413                | 4           |
| 38 Isère                  | 27.6           | 306.5           | +278.9           | 0.412                | 5           |
| 07 Ardèche                | 40.9           | 153.6           | +112.7           | 0.278                | 6           |

The Drôme is third in 2017 and in 2025. It has the largest absolute gain. Compared with the average of its five neighbours, its density went from 73% (2017) to 104% (2025).

**Empirical yield against PVGIS (kWh per kW or kWp, per year)**

| Department | Reference point | Empirical | PVGIS | PVGIS above empirical |
| ---------- | --------------- | --------- | ----- | --------------------- |
| 04         | Digne-les-Bains | 1,492     | 1,508 | +1.1%                 |
| 05         | Gap             | 1,410     | 1,536 | +9.0%                 |
| 07         | Privas          | 1,292     | 1,397 | +8.1%                 |
| 26         | Valence         | 1,278     | 1,392 | +8.9%                 |
| 38         | Grenoble        | 1,184     | 1,362 | +15.0%                |
| 84         | Avignon         | 1,342     | 1,560 | +16.3%                |

PVGIS is higher everywhere. This is not a measure of under-performance: one prefecture point represents a whole department, PVGIS uses a standard orientation, and the register gives energy injected, not energy produced.

**A point to investigate.** The yield of mature plants fell by 8% to 15% in 2024–2025 compared with 2017–2023 in all six departments. The fall also appears on the same 2,078 plants followed from 2022 to 2025, so it is not a change in the sample. The cause is not identified yet.

---

## 8. Limitations

- **Energy injected is not total production.** Self-consumption is not included.
- **Period of the annual energy** (calendar year or last 12 months) is not yet confirmed in the dataset documentation.
- **Department areas are typed in the notebook.** The values for Hautes-Alpes, Ardèche and Drôme match published sources; the others still need checking, and one official source (INSEE or IGN) must be cited.
- **PVGIS uses one point per department**, not an area-weighted average.
- **The reference yield is constant over time**, so the normalised productible follows the same trend as capacity.
- **Density uses the total department area**, including mountains and land that cannot host plants. Alpine departments are penalised mechanically.
- **2026 is a partial year** and is not used in trends.

---

## 9. Next steps

1. Cite one official source for the department areas and fix the area table in the notebook.
2. Query PVGIS at several points per department.
3. Analyse yields by plant size and by commune.
4. Check the documentation of the energy field and look into the 2024–2025 decline.
5. Define "remaining potential" and build low and high scenarios over 5 to 10 years.
6. Load the clean tables into SQL, build the Tableau dashboard and write the final report.

---

## 10. How to reproduce

1. Clone the repository and install the tools: `pip install pandas requests matplotlib jupyter`.
2. Download the 10 CSV files (see section 3) into `dataset/data raw/`, keeping the file names.
3. Run `csv_check.ipynb` from top to bottom. It writes `centrales_pv_6dep.csv` and `synthese_dep_edition.csv` to `dataset/data clean/`.
4. Run `pvgis_potentiel_solaire.ipynb` (internet access is needed for the PVGIS API). It writes `potentiel_solaire_PVGIS.csv` and `comparaison_PVGIS_empirique.csv`.
