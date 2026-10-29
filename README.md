# EJScreen SQL reconstruction

EJScreen was the U.S. Environmental Protection Agency screening tool that scored each census block group on environmental and demographic indicators. This repository rebuilds the version 2.3 Demographic Index, Supplemental Demographic Index, percentiles, and EJ indexes in SQL from the archived 2024 block group tables, so the published method can be rerun and compared with the published scores. On this run, every rebuilt percentile matches the published integer where both values exist, and every demographic index and EJ index is within 1e-8 of the published value on those rows. Exact bit equality fails for the continuous indexes, and null agreement fails for 27 state file columns on island territory rows whose inputs are blank in the national extract.

Tier 2 rebuilds the demographic rates from the Census Bureau ACS 2018-2022 5-year block group tables for the 50 states, the District of Columbia, and Puerto Rico. Low income, people of color, limited English, less than high school, unemployment, age, disability, and both demographic indexes match the Harvard extract within 1e-8. Low life expectancy uses 97.5, a 2020 block population weight for multi-parent tracts, and the Geocorr 2022 population crosswalk for Connecticut. It is within 1e-8 on 220243 of 224546 compared rows, a tolerance rate of 0.980837, which is under the 99 percent bar. The supplemental demographic index is built from the same five factor formula and does not meet that bar. The national median absolute gap is 0.0255130803693. The four island territories are not in the ACS dataset and are left out.

This is an independent reproduction. It is not affiliated with EPA. The indicator definitions and formulas follow EPA EJScreen Technical Documentation for Version 2.3 (July 31, 2024). The block group tables are the Harvard Dataverse archive of that EPA release, dataset DOI 10.7910/DVN/RLR5AX. The Environmental Data and Governance Initiative also archived the EPA FTP drop. The ACS variables and the life expectancy file are listed in `docs/data_sources.md`.

## How the tables fit

```
raw.ejscreen_reference
raw.ejscreen_reference_state_pct
        |
        v
staging.block_group_inputs
        |
        v
marts.demographic_index
marts.block_group_score
marts.indicator_percent_rank
```

`raw` keeps the published column names and the downloaded Census extracts. `staging` types the national extract and normalizes the block group id to 12 characters. `marts` holds the rebuilt indexes. The percent rank view is a comparison only. The published percentile is the cutoff lookup described in the technical documentation.

```
raw.acs2022_block_group
raw.acs2022_tract_b18101
raw.pl2020_block_group
raw.pl2020_block
raw.block_rel_2010_2020
raw.geocorr_ct_2020_2022
        |
        v
staging.acs_indicator
        |
        v
marts.acs_block_group
```

## Status

| Tier | What it covers | Status |
| --- | --- | --- |
| Tier 1 | Demographic indexes, US and state percentiles, 13 EJ indexes, and 13 supplemental indexes from the published indicator values | Checked. See the validation summary below. |
| Tier 2 | Demographic rates, both demographic indexes, and the supplemental demographic index from ACS 2018-2022 and USALEEP | Checked. The rates other than life expectancy, and the two factor indexes, match within 1e-8. Low life expectancy tolerance rate is 0.980837. The supplemental index does not match within 1e-8. National median absolute gap 0.0255130803693. |
| Tier 3 | Lead paint from ACS B25034, Superfund proximity, hazardous waste proximity, and traffic proximity. | Checked. Lead paint tolerance rate 1, median absolute gap 2.22044604925e-16. Superfund tolerance rate 0.567679, median absolute gap 0. Hazardous waste tolerance rate 0.147319, median absolute gap 0.436139051761. Traffic tolerance rate 0.013991, median absolute gap 49054.47511849948. |

### Tier 1 validation summary

The loaded table has 243,022 rows. The 50 states, the District of Columbia, and Puerto Rico are 242,336 rows, which matches the technical documentation. Island territory place and estate records are 686.

Checks are defined in `sql/validation/metrics.sql`. A column passes when at least 99 percent of rows with both values present meet the rule. Continuous tolerance is an absolute difference of at most 1e-8. Percentile tolerance is 0. Null agreement passes at 99.9 percent. A low match rate is reported and does not stop the run. A failed data assertion does stop the run. Assertions passed.

| Family | Columns | Minimum exact rate | Minimum tolerance rate | Largest absolute difference |
| --- | --- | --- | --- | --- |
| Demographic indexes | 6 | 0.000033 | 1 | 1.33e-12 |
| EJ and supplemental indexes | 52 | 0.010025 | 1 | 1.32e-10 |
| Percentiles | 100 | 1 | 1 | 0 |

Reported checks: 391 passed, 85 failed. Exact checks: 100 passed, 58 failed. Tolerance checks: 158 passed, 0 failed. Null agreement: 131 passed, 27 failed. Geographic id alignment passed. The 242,336 count passed. The 58 exact failures are the continuous index columns. Their gaps are double precision residue, all far below 1e-8, and Pearson and Spearman correlations are 1. The 27 null failures are state file columns. On those rows the rebuild is null and the state extract has a value. The rows are island territory records whose inputs are blank in the national extract. Details are in `docs/validation_report.md` and `docs/data_profile.md`.

### Tier 2 validation summary

ACS block groups: 242336, the same ids as the national reference universe. Geographic id gaps: 0. American Samoa, Guam, the Northern Mariana Islands, and the U.S. Virgin Islands are not in this rebuild.

Thresholds are fixed in `sql/validation/tier2_metrics.sql`. Continuous tolerance is an absolute difference of at most 1e-8 on at least 99 percent of rows where both values are present. Exact equality uses the same 99 percent bar. Null agreement passes at 99.9 percent. A low match rate is reported and does not stop the run.

| Column | Tolerance | What the comparison shows |
| --- | --- | --- |
| Low income, people of color, limited English, less than high school, unemployment, under age 5, over age 64, disability | Pass | Absolute differences are at most about 1e-15. A zero denominator is stored as 0. Less than high school includes B15002.027. Disability is the tract rate assigned to each block group. Exact equality still fails the 99 percent bar on double precision residue. Unemployment is null when the labor force is 0 and the population is greater than 0, so the 424 blank reference rows agree. One block group remains a null disagreement. |
| Demographic Index, national and state | Pass | All 242336 rows are within 1e-8. The largest national absolute difference is 4.38e-13. Zero denominators are included as 0 in the rates and in the moments. |
| Low life expectancy | Fail | 220243 of 224546 compared rows are within 1e-8. Tolerance rate 0.980837. The denominator is 97.5. Multi-parent tracts use the 2020 block population weight. Connecticut uses the Geocorr 2022 pop20 crosswalk. Null agreement still fails. |
| Supplemental Demographic Index, national | Fail | 0 of 242336 rows are within 1e-8. Median absolute difference 0.0255130803693. On rows whose life expectancy matches, the median absolute gap is 0.0255135714308. |
| Supplemental Demographic Index, state | Fail | 3559 of 242336 rows are within 1e-8. Tolerance rate 0.014686. Median absolute difference 0.00206558363478. |

The supplemental index uses the five adopted factors, or four where low life expectancy is missing. The formula was not changed. Low life expectancy is still null on 384 rows that have a published value: 279 multi-parent block groups the weight could not fill, and 105 single-parent block groups whose parent has no USALEEP value. Connecticut block groups with a published value are filled. No other weight and no other maximum were tried. Details are in `docs/validation_report.md` and `docs/assumptions.md`.

### Tier 3 validation summary

Thresholds are the same as Tier 1 and Tier 2. Distance uses kilometers. Superfund cap is 11 inside 0.1 km. Hazardous waste and traffic use a cap of 10 inside 0.1 km. Traffic multiplies that capped inverse distance by AADT. Those were not changed after the comparison. 97.5 and the supplemental formula were not retuned.

| Column | Tolerance | Median absolute gap | Source |
| --- | --- | --- | --- |
| PRE1960PCT, lead paint | Pass, rate 1 on 242336 rows | 2.22044604925e-16 | ACS 2022 5-year B25034, Census API. Zero housing-unit totals are stored as 0. |
| PNPL, Superfund proximity | Fail, rate 0.567679 on 240939 rows | 0 | U.S. EPA Superfund public site boundaries, current FeatureServer, not the February 26, 2024 extract. Final and proposed polygons, reviewed SAA boundaries, and 28 point-only sites buffered by 1 meter. |
| PTRAF, traffic proximity | Fail, rate 0.013991 on 240939 rows | 49054.47511849948 | 2020 HPMS file geodatabase, layers `HPMS_FULL_{ST}_2020`, field `AADT`. Kilometers, cap 10 inside 0.1 km, then multiplied by AADT. Publisher: Federal Highway Administration. |
| PTSDF, hazardous waste proximity | Fail, rate 0.147319 on 240939 rows | 0.436139051761 | RCRAInfo `BR_REPORTING_2021.zip` and `HD_REPORTING.zip`, export dated 2026-10-18. Operating TSDFs plus 2021 large quantity generators. |

Exact equality fails the 99 percent bar on all four built columns. Lead paint misses it on double precision residue. Traffic misses it except on shared zeros. Details are in `docs/validation_report.md`.

## Setup

You need Docker with Compose, Python 3.11, and the packages in `requirements.txt`. Copy `.env.example` to `.env`. The example uses local database credentials and `STATE_FIPS=06` for the California pilot tables in the validation report.

```
python3.11 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env
make all
```

`make all` runs `make load`, `make build`, and `make validate`. `make load` creates schemas, downloads the Harvard files into `data/reference/` if they are not already there, loads them, then downloads the ACS, 2020 redistricting, USALEEP, and 2010 to 2020 block relationship files into `data/census/` if they are not already there. The two Harvard CSV files are large. They are stored as ordered parts, and the loader joins the parts. Those files are not committed. `make build` creates the staging and mart tables for Tier 1 and Tier 2, including the ACS indicators. `make build-tier3` runs the lead paint, Superfund, hazardous waste, and traffic SQL after those site and road tables are loaded separately. HPMS, RCRAInfo handler exports, and Superfund site extracts are not committed and are not downloaded by `make load`. See `docs/data_sources.md` and `docs/publish-disclaimer.md`. `make validate` writes `docs/data_profile.md` and `docs/validation_report.md`. Postgres data lives in a Docker named volume, not in this directory. Census API requests read `CENSUS_API_KEY` from the environment. The example file leaves that value blank.

`make validate` exits with a nonzero status if an assertion fails. It exits 0 when assertions pass, even if a match rate check fails. The report states which checks failed.

## Optional docs site

`site/` is a minimal static page that links to the GitHub docs. For Vercel, create a project from this repository and set the Root Directory to `site`. No build step is required.

## Known limitations

The technical documentation does not state a rounding rule. Values are computed in full precision, so a published field stored at 15 decimal places is not always bit identical to the rebuilt double.

The national extract leaves demographic and environmental inputs blank for the 686 island territory records. The state extract has values for many of those inputs. Tier 1 does not copy them. National percentiles stay null for those records, which is what the technical documentation says. Supplemental indexes are null there as well.

The supplemental index uses percent persons with disabilities as the fifth factor. Tier 1 uses the published indicator values. Tier 2 rebuilds the rates. A zero ACS denominator is stored as 0. Unemployment is null when the civilian labor force is 0 and the block group population is greater than 0. Less than high school includes B15002.027. Disability assigns the tract rate to each block group. Low life expectancy uses 97.5, which is not printed in the technical documentation. A 2020 tract with more than one 2010 parent uses the 2020 block population weight from the Census 2010 to 2020 block relationship file. Blocks that meet more than one 2010 tract stay out of that weight. The file's arealand_int column was compared and not used. Connecticut 2022 tracts use the Missouri Census Data Center Geocorr 2022 crosswalk, weight column pop20. The supplemental index is built from the adopted factors and does not match the reference within 1e-8.

There is no cap at 100 on an EJ index. In the California pilot, the highest rebuilt national PM2.5 EJ index is about 383.

`marts.indicator_percent_rank` is not the published percentile. On the national file the largest gap versus the cutoff percentile is under 1 point. On the state file the largest column maximum is about 95.8 points, for PM2.5.

## Example queries

Top 20 California block groups by the rebuilt national PM2.5 EJ index:

```sql
SELECT geoid, d2_pm25, p_pm25, st_p_pm25
FROM marts.block_group_score
WHERE state_fips = '06'
ORDER BY d2_pm25 DESC NULLS LAST
LIMIT 20;
```

US percentile and state percentile for PM2.5 in the same state:

```sql
SELECT geoid, p_pm25 AS us_percentile, st_p_pm25 AS state_percentile
FROM marts.block_group_score
WHERE state_fips = '06'
ORDER BY p_pm25 DESC NULLS LAST
LIMIT 20;
```

Rebuilt Demographic Index next to the published national value:

```sql
SELECT s.geoid,
       s.demogidx_2 AS rebuilt,
       r."DEMOGIDX_2"::double precision AS published
FROM marts.block_group_score s
JOIN staging.block_group_inputs b ON b.geoid = s.geoid
JOIN raw.ejscreen_reference r ON r."ID" = b.source_id
WHERE s.state_fips = '06'
ORDER BY abs(s.demogidx_2 - r."DEMOGIDX_2"::double precision) DESC NULLS LAST
LIMIT 20;
```

Rebuilt national supplemental PM2.5 index next to the published value:

```sql
SELECT s.geoid,
       s.d5_pm25 AS rebuilt,
       r."D5_PM25"::double precision AS published
FROM marts.block_group_score s
JOIN staging.block_group_inputs b ON b.geoid = s.geoid
JOIN raw.ejscreen_reference r ON r."ID" = b.source_id
WHERE s.state_fips = '06'
ORDER BY s.d5_pm25 DESC NULLS LAST
LIMIT 20;
```

Cutoff percentile next to the percent rank comparison, for national PM2.5:

```sql
SELECT p.geoid,
       p.value AS cutoff_percentile,
       r.percent_rank_0_100
FROM marts.rebuilt p
JOIN marts.indicator_percent_rank r
  ON r.scope = p.scope
 AND r.percentile_column = p.column_name
 AND r.geoid = p.geoid
WHERE p.scope = 'national_file'
  AND p.column_name = 'P_PM25'
ORDER BY abs(r.percent_rank_0_100 - p.value) DESC
LIMIT 20;
```
