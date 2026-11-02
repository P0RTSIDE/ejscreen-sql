# Publish disclaimer: EJScreen SQL reconstruction

This is an independent reconstruction of EPA EJScreen version 2.3. It is not affiliated with the U.S. Environmental Protection Agency, and it is not an official EPA product, dataset, or map.

## What matches

Where both the rebuild and the published Harvard extract have a value:

- Tier 1 indexes and percentiles built from the published environmental and demographic indicator values. Continuous indexes are within 1e-8. Integer percentiles match exactly.
- Tier 2 demographic rates from ACS 2018-2022: low income, people of color, limited English, less than high school, unemployment, age, disability, and both two-factor demographic indexes, on all 242,336 block groups in the 50 states, the District of Columbia, and Puerto Rico.
- Lead paint (pre-1960 housing share from ACS B25034).
- Ozone (2020 OAQPS peak metric).
- Nitrogen dioxide (HAQAST ~1 km surface product).
- Particulate matter 2.5 (FAQSD 2020 annual mean).
- Toxic releases to air (May 2023 RSEI block-group delivery).
- Underground storage tanks and leaking UST (public UST Finder inventory).

## Open gaps

These gaps are intentional publish limits, not unfinished cleanup:

- **Hazardous waste proximity** still needs the February 5, 2024 RCRAInfo handler export. The public run pinned here is later and does not close the gap.
- **RMP facility proximity** needs an active-only facility list, or the February 5, 2024 FRS pull. The current FRS interest layer scores about twice the published values.
- **Drinking water non-compliance** needs EPA’s internal Enforcement and Targeting Tool extract for SDWIS submission year 2023 Q4. Public ECHO SDWA files do not reproduce the published ranks.
- **Low life expectancy** disagrees with the published extract on 996 block groups (723 reference-only, 273 rebuild-only). The supplemental demographic index still fails the 99 percent within-1e-8 bar.
- **Traffic proximity, Superfund proximity, wastewater discharge, and diesel particulate matter** miss the 99 percent absolute-difference bar. They were scored from public files and kept where the scale matched (median ratio near 1 and high Pearson), not as bit-identical rebuilds.

## How to read the work

Formulas follow EPA, *EJScreen Technical Documentation for Version 2.3*, revised July 31, 2024. Reference tables are the Harvard Dataverse archive of that EPA release, DOI 10.7910/DVN/RLR5AX.

| Doc | Contents |
| --- | --- |
| [`docs/methodology.md`](methodology.md) | Version 2.3 formulas |
| [`docs/assumptions.md`](assumptions.md) | Choices and known gaps |
| [`docs/validation_report.md`](validation_report.md) | Thresholds and match rates |
| [`docs/data_sources.md`](data_sources.md) | Source files and DOIs |

A column passes when at least 99 percent of rows with both values present are within 1e-8 (continuous) or exact (percentiles). A low match rate is reported. It does not stop the build. Assertions about ids, bounds, the non-negative shift, and the index product do stop the build.
