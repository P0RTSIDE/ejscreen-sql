# EJScreen SQL

Independent SQL reconstruction of EPA EJScreen 2.3.

This repository rebuilds the version 2.3 Demographic Index, Supplemental Demographic Index, percentiles, and EJ indexes in SQL from the archived 2024 block group tables, then compares the results with the published Harvard Dataverse extracts.

It is not affiliated with the U.S. Environmental Protection Agency. It is not an official EPA product, dataset, or map.

Formulas follow EPA, *EJScreen Technical Documentation for Version 2.3* (July 31, 2024). Reference tables: Harvard Dataverse DOI [10.7910/DVN/RLR5AX](https://doi.org/10.7910/DVN/RLR5AX).

## What this is

- A reproducible Postgres pipeline (`raw` → `staging` → `marts`) that scores census block groups from public inputs
- A validation harness that compares rebuilt columns with the published national and state extracts
- Written methodology, assumptions, source pins, and a small client-side sample playground

## What this is not

- Not EPA EJScreen and not a substitute for regulatory screening
- Not a live national API or hosted database
- Not a bit-identical clone of every environmental indicator (several public vintages differ from the February 2024 pins in the tech doc)

## Quick start

You need Docker with Compose, Python 3.11, and the packages in `requirements.txt`.

```bash
python3.11 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env
make all
```

`make all` runs `make load`, `make build`, and `make validate`.

- `make load` creates schemas and downloads the Harvard reference files (and ACS / census inputs) when they are not already present. Large CSVs are not committed.
- `make build` builds Tier 1 and Tier 2 staging and mart tables.
- `make build-tier3` runs lead paint, Superfund, hazardous waste, and traffic SQL after those site and road tables are loaded separately.
- `make validate` writes `docs/data_profile.md` and `docs/validation_report.md`. It exits nonzero only if an assertion fails. A low match rate is reported and does not fail the run.

The `.env.example` file uses local database credentials and `STATE_FIPS=06` (California) for the pilot slice. Set `CENSUS_API_KEY` if you need Census API downloads. Postgres data lives in a Docker named volume.

## Architecture

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

`raw` keeps published column names and downloaded Census extracts. `staging` types the national extract and normalizes the block group id to 12 characters. `marts` holds the rebuilt indexes. The percent-rank view is a comparison only. The published percentile is the cutoff lookup in the technical documentation.

Tier 2 demographics follow a parallel path:

```
raw.acs2022_block_group
raw.acs2022_tract_b18101
raw.pl2020_block_group / raw.pl2020_block
raw.block_rel_2010_2020
raw.geocorr_ct_2020_2022
        |
        v
staging.acs_indicator
        |
        v
marts.acs_block_group
```

| Tier | Scope | Status |
| --- | --- | --- |
| Tier 1 | Indexes and percentiles from published indicator values | Checked. Continuous indexes within 1e-8 where both sides have values. Integer percentiles match exactly. |
| Tier 2 | Demographic rates and indexes from ACS 2018-2022 and USALEEP | Rates other than low life expectancy, and the two-factor indexes, match within 1e-8. Low life expectancy and the supplemental index miss the 99% bar. |
| Tier 3 | Lead paint, Superfund, hazardous waste, traffic (and related public environmental scores) | Lead paint matches. Several proximity and vintage-sensitive indicators miss the 99% bar. See known gaps. |

## Validation highlights

A column passes when at least 99% of rows with both values present meet the rule (absolute difference ≤ 1e-8 for continuous fields; exact for integer percentiles). Null agreement uses a 99.9% bar. Full tables live in [`docs/validation_report.md`](docs/validation_report.md).

**Tier 1 (indexes from published inputs)**

- Every rebuilt percentile matches the published integer where both values exist.
- Every demographic index and EJ index is within 1e-8 of the published value on those rows.
- Exact bit equality often fails on continuous fields because of ordinary double-precision residue. Tolerance rates are 1.0.
- Null agreement fails on 27 state-file columns for island-territory rows whose inputs are blank in the national extract.

**Tier 2 (ACS rebuild)**

- Low income, people of color, limited English, less than high school, unemployment, age, disability, and both two-factor demographic indexes match within 1e-8 on the 242,336 state / DC / Puerto Rico block groups.
- Low life expectancy tolerance rate is about 0.981 (under the 99% bar). The five-factor supplemental index inherits that gap.

**Tier 3 (public environmental inputs)**

- Lead paint (pre-1960 housing share) matches within tolerance.
- Superfund, hazardous waste, traffic, and several other public-file scores miss the 99% absolute-difference bar. Some still track the published scale (median ratio near 1, high correlation). Others need a non-public vintage. Details and the “not uniform” column tables are in the validation report.

## Known gaps and disclaimers

Read [`docs/publish-disclaimer.md`](docs/publish-disclaimer.md) before treating any rebuilt score as EPA-equivalent.

Open gaps that matter for recruiters and reviewers:

| Topic | Situation |
| --- | --- |
| Hazardous waste proximity | Needs the February 5, 2024 RCRAInfo handler export. The public export pinned here is later and does not close the gap. |
| RMP facility proximity | Needs an active-only facility list or the February 5, 2024 FRS pull. Current FRS interest scores sit about 2× the published values. |
| Drinking water non-compliance | Needs EPA’s internal ETT extract for SDWIS submission year 2023 Q4. Public ECHO SDWA files do not reproduce the published ranks. |
| Low life expectancy | Disagrees on 996 block groups (723 reference-only, 273 rebuild-only). The supplemental demographic index still fails the 99% within-1e-8 bar. |
| Other proximity / air scores | Traffic, Superfund, wastewater, and diesel PM miss the 99% absolute-difference bar on the public files used here. |

Rounding: the tech doc does not state a rounding rule. Continuous fields are computed in full precision, so a published field stored at 15 decimal places is not always bit-identical to the rebuild.

Island territories: the national extract leaves many demographic and environmental inputs blank for 686 place and estate records. This rebuild does not copy filled values from the state extract. National percentiles stay null there, matching the tech doc.

## Sample playground

[`site/`](site/) is a static page with a client-side playground over **250 block groups** from the Harvard 2024 archive. There is no live database behind the page.

- **Simple filters** (default): plain-language justice topics and sample percentiles. No SQL box.
- **Advanced**: GEOID, state, county, and indicator column tools.

Values are from the reconstruction sample. In Simple filters, “near” means a high proximity or percentile-style score in that sample, not a live EPA distance or a custom mile radius.

Open `site/index.html` locally, or the deployed Vercel URL if you have one.

## Optional Vercel deploy

The root [`vercel.json`](vercel.json) forces a static deploy of `site/` (Framework Preset Other, no Python runtime). No build step is required. If you set a Dashboard Root Directory, use `site`.

## Example queries

Top California block groups by the rebuilt national PM2.5 EJ index:

```sql
SELECT geoid, d2_pm25, p_pm25, st_p_pm25
FROM marts.block_group_score
WHERE state_fips = '06'
ORDER BY d2_pm25 DESC NULLS LAST
LIMIT 20;
```

US and state percentiles for PM2.5:

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

## Documentation

| Doc | Contents |
| --- | --- |
| [`docs/publish-disclaimer.md`](docs/publish-disclaimer.md) | What matches, open gaps, how to read the work |
| [`docs/methodology.md`](docs/methodology.md) | Version 2.3 formulas from the tech doc |
| [`docs/assumptions.md`](docs/assumptions.md) | Choices where the tech doc is silent or sources disagree |
| [`docs/validation_report.md`](docs/validation_report.md) | Thresholds, match rates, “not uniform” tables, tier results |
| [`docs/data_sources.md`](docs/data_sources.md) | Source files, vintages, and DOIs |
| [`docs/data_profile.md`](docs/data_profile.md) | Loaded-table counts and column ranges |
