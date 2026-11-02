# EJScreen version 2.3 validation

This report compares the SQL reconstruction with the Harvard Dataverse EJScreen 2024 block group extracts (DOI 10.7910/DVN/RLR5AX).

- **Tier 1** (through the pilot area): indexes built from the published environmental and demographic indicator values.
- **Tier 2**: demographic indicators rebuilt from the American Community Survey, compared with the same extract.
- **Tier 3**: lead paint and proximity scores from public environmental inputs.

Match rates are reported checks. A low match rate does not stop the build. The build stops if an assertion fails. Assertions cover id uniqueness, 12-character ids, population, percentile bounds, the non-negative shift, and the index product. The tech doc states no maximum of 100 for an EJ index or supplemental index, so no such maximum is asserted.

For open gaps that need non-public vintages (hazardous waste, RMP, drinking water) and the remaining life-expectancy disagreement, see [`docs/publish-disclaimer.md`](publish-disclaimer.md).

## Thresholds

These thresholds are fixed in `sql/validation/metrics.sql` before the comparison runs.

Continuous values pass the tolerance check when the absolute difference is at most 1e-8 on at least 99 percent of rows where both sides are present. The reference stores those fields at 15 decimal places. 1e-8 is above ordinary double-precision residue and below a one-point percentile error.

Percentile values are integers. Their tolerance is 0, so the tolerance check is the exact check. The pass bar is 99 percent.

Null agreement passes when at least 99.9 percent of rows agree on whether the value is null.

Exact equality is double-precision equality. Spearman correlation is the Pearson correlation of `rank()` values, and ties share the minimum rank.

## Result

| Check family | Passed | Failed |
| --- | ---: | ---: |
| Reported checks (all) | 391 | 85 |
| Exact | 100 | 58 |
| Tolerance | 158 | 0 |
| Null agreement | 131 | 27 |
| Geographic id alignment | pass |  |
| Tech doc block group count (242,336) | pass |  |

The 58 exact failures are continuous index columns whose gaps are double-precision residue, all far below 1e-8. Pearson and Spearman correlations are 1. The 27 null failures are state-file columns on island-territory rows (see below).

Assertions ran before this report was written. A failed assertion stops the run and does not produce this file.

## Universe

| Slice | Rows |
| --- | ---: |
| Total | 243,022 |
| States, District of Columbia, and Puerto Rico | 242,336 |
| Island territories (place and estate records) | 686 |

## Geographic ids

No source id is missing from either side. Unmatched count is 0 for the national extract and for the state percentile extract.

## Columns that are not uniform

“Not uniform” means a column failed at least one Tier 1 reported check: exact equality under the 99% bar, tolerance under the 99% bar, or null agreement under the 99.9% bar. The tables below list every such column for the national file and the state file.

### How to read these rates

- **Exact match rate** is the share of both-present rows where rebuilt equals published as double-precision numbers. Continuous indexes often show low exact rates because tiny floating-point differences remain after the formula. That alone is not a substantive gap when the tolerance rate is 1.0.
- **Tolerance match rate** is the share within absolute difference 1e-8 (or exact for integer percentiles). Every continuous column in this list has tolerance rate **1.0**, so values agree for practical purposes where both sides are present.
- **Null disagreements** count rows where one side is null and the other is not. National-file columns in this list have zero null disagreements. State-file null disagreements cluster on island-territory rows (about 440, 446, 679, or 685 rows) whose inputs are blank in the national extract while the state extract still carries values. Staging uses the national extract only, so the rebuild stays null there.

Percentile columns that appear only under the state file (exact rate 1.0, nonzero null disagreements) fail null agreement only. Where both sides have a value, the integers match.

### National file

| Column | Exact match rate | Tolerance match rate | Null disagreements |
| --- | ---: | ---: | ---: |
| D2_DSLPM | 0.014274 | 1.000000 | 0 |
| D2_DWATER | 0.735878 | 1.000000 | 0 |
| D2_LDPNT | 0.153704 | 1.000000 | 0 |
| D2_NO2 | 0.017397 | 1.000000 | 0 |
| D2_OZONE | 0.019576 | 1.000000 | 0 |
| D2_PM25 | 0.019560 | 1.000000 | 0 |
| D2_PNPL | 0.563664 | 1.000000 | 0 |
| D2_PRMP | 0.287031 | 1.000000 | 0 |
| D2_PTRAF | 0.018274 | 1.000000 | 0 |
| D2_PTSDF | 0.158872 | 1.000000 | 0 |
| D2_PWDIS | 0.080985 | 1.000000 | 0 |
| D2_RSEI_AIR | 0.017278 | 1.000000 | 0 |
| D2_UST | 0.275466 | 1.000000 | 0 |
| D5_DSLPM | 0.010040 | 1.000000 | 0 |
| D5_DWATER | 0.734807 | 1.000000 | 0 |
| D5_LDPNT | 0.153048 | 1.000000 | 0 |
| D5_NO2 | 0.010037 | 1.000000 | 0 |
| D5_OZONE | 0.010034 | 1.000000 | 0 |
| D5_PM25 | 0.010025 | 1.000000 | 0 |
| D5_PNPL | 0.561349 | 1.000000 | 0 |
| D5_PRMP | 0.283826 | 1.000000 | 0 |
| D5_PTRAF | 0.014028 | 1.000000 | 0 |
| D5_PTSDF | 0.154925 | 1.000000 | 0 |
| D5_PWDIS | 0.076901 | 1.000000 | 0 |
| D5_RSEI_AIR | 0.010033 | 1.000000 | 0 |
| D5_UST | 0.269779 | 1.000000 | 0 |
| DEMOGIDX_2 | 0.009990 | 1.000000 | 0 |
| DEMOGIDX_2ST | 0.039140 | 1.000000 | 0 |
| DEMOGIDX_5 | 0.000033 | 1.000000 | 0 |
| DEMOGIDX_5ST | 0.003784 | 1.000000 | 0 |

### State file

| Column | Exact match rate | Tolerance match rate | Null disagreements |
| --- | ---: | ---: | ---: |
| D2_DSLPM | 0.052317 | 1.000000 | 0 |
| D2_DWATER | 0.746782 | 1.000000 | 0 |
| D2_LDPNT | 0.184694 | 1.000000 | 679 |
| D2_NO2 | 0.055071 | 1.000000 | 0 |
| D2_OZONE | 0.057877 | 1.000000 | 0 |
| D2_PM25 | 0.057781 | 1.000000 | 0 |
| D2_PNPL | 0.578124 | 1.000000 | 440 |
| D2_PRMP | 0.315369 | 1.000000 | 440 |
| D2_PTRAF | 0.059317 | 1.000000 | 0 |
| D2_PTSDF | 0.190290 | 1.000000 | 440 |
| D2_PWDIS | 0.117585 | 1.000000 | 0 |
| D2_RSEI_AIR | 0.059654 | 1.000000 | 679 |
| D2_UST | 0.306825 | 1.000000 | 679 |
| D5_DSLPM | 0.013966 | 1.000000 | 0 |
| D5_DWATER | 0.736326 | 1.000000 | 0 |
| D5_LDPNT | 0.156361 | 1.000000 | 0 |
| D5_NO2 | 0.014212 | 1.000000 | 0 |
| D5_OZONE | 0.013644 | 1.000000 | 0 |
| D5_PM25 | 0.013594 | 1.000000 | 0 |
| D5_PNPL | 0.563104 | 1.000000 | 0 |
| D5_PRMP | 0.286259 | 1.000000 | 0 |
| D5_PTRAF | 0.020698 | 1.000000 | 0 |
| D5_PTSDF | 0.158224 | 1.000000 | 0 |
| D5_PWDIS | 0.081992 | 1.000000 | 0 |
| D5_RSEI_AIR | 0.018474 | 1.000000 | 0 |
| D5_UST | 0.273129 | 1.000000 | 0 |
| DEMOGIDX_2 | 0.039214 | 1.000000 | 679 |
| DEMOGIDX_5 | 0.003784 | 1.000000 | 0 |
| P_D2_LDPNT | 1.000000 | 1.000000 | 679 |
| P_D2_PNPL | 1.000000 | 1.000000 | 440 |
| P_D2_PRMP | 1.000000 | 1.000000 | 440 |
| P_D2_PTSDF | 1.000000 | 1.000000 | 440 |
| P_D2_RSEI_AIR | 1.000000 | 1.000000 | 679 |
| P_D2_UST | 1.000000 | 1.000000 | 679 |
| P_DEMOGIDX_2 | 1.000000 | 1.000000 | 679 |
| P_LDPNT | 1.000000 | 1.000000 | 679 |
| P_LESSHSPCT | 1.000000 | 1.000000 | 679 |
| P_LINGISOPCT | 1.000000 | 1.000000 | 679 |
| P_LOWINCPCT | 1.000000 | 1.000000 | 679 |
| P_OVER64PCT | 1.000000 | 1.000000 | 685 |
| P_PEOPCOLORPCT | 1.000000 | 1.000000 | 685 |
| P_PNPL | 1.000000 | 1.000000 | 446 |
| P_PRMP | 1.000000 | 1.000000 | 446 |
| P_PTSDF | 1.000000 | 1.000000 | 446 |
| P_RSEI_AIR | 1.000000 | 1.000000 | 685 |
| P_UNDER5PCT | 1.000000 | 1.000000 | 685 |
| P_UNEMPPCT | 1.000000 | 1.000000 | 679 |
| P_UST | 1.000000 | 1.000000 | 685 |

## All columns

| Scope | Column | Kind | Both present | Exact | Exact rate | Within tolerance | Tolerance rate | Null disagreements | Pearson | Spearman | Abs min | Abs median | Abs p95 | Abs max | Exact | Tolerance | Nulls |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| national_file | D2_DSLPM | continuous | 240438 | 3432 | 0.014274 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 5.62749846722e-12 | 2.82227574644e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D2_DWATER | continuous | 223128 | 164195 | 0.735878 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 2.38458142121e-11 | 4.44515535492e-11 | fail | pass | pass |
| national_file | D2_LDPNT | continuous | 242336 | 37248 | 0.153704 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 5.30064880877e-12 | 2.66027200269e-11 | 4.53042048321e-11 | fail | pass | pass |
| national_file | D2_NO2 | continuous | 241704 | 4205 | 0.017397 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 5.75539615966e-12 | 2.89048784907e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D2_OZONE | continuous | 238194 | 4663 | 0.019576 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 5.22959453519e-12 | 2.66311417363e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D2_PM25 | continuous | 238194 | 4659 | 0.019560 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 5.57065504836e-12 | 2.71143107966e-11 | 4.40536496171e-11 | fail | pass | pass |
| national_file | D2_PNPL | continuous | 240943 | 135811 | 0.563664 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 2.70290456683e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D2_PRMP | continuous | 240943 | 69158 | 0.287031 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 5.07327513333e-12 | 2.88764567813e-11 | 4.49063009e-11 | fail | pass | pass |
| national_file | D2_PTRAF | continuous | 240943 | 4403 | 0.018274 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 5.83355586059e-12 | 2.81090706267e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D2_PTSDF | continuous | 240943 | 38279 | 0.158872 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 5.63460389458e-12 | 2.78532752418e-11 | 4.44515535492e-11 | fail | pass | pass |
| national_file | D2_PWDIS | continuous | 240439 | 19472 | 0.080985 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 5.45696821064e-12 | 2.67732502834e-11 | 4.49063009e-11 | fail | pass | pass |
| national_file | D2_RSEI_AIR | continuous | 241692 | 4176 | 0.017278 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 5.50670620214e-12 | 2.6147972676e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D2_UST | continuous | 241776 | 66601 | 0.275466 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 4.6256332098e-12 | 2.78248535324e-11 | 4.48494574812e-11 | fail | pass | pass |
| national_file | D5_DSLPM | continuous | 240438 | 2414 | 0.010040 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 2.48689957516e-11 | 5.82645043323e-11 | 1.25652377392e-10 | fail | pass | pass |
| national_file | D5_DWATER | continuous | 223128 | 163956 | 0.734807 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 5.99698068982e-11 | 1.31535671244e-10 | fail | pass | pass |
| national_file | D5_LDPNT | continuous | 242336 | 37089 | 0.153048 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 2.61550781033e-11 | 6.41477981844e-11 | 1.15562670544e-10 | fail | pass | pass |
| national_file | D5_NO2 | continuous | 241704 | 2426 | 0.010037 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 2.45847786573e-11 | 6.00834937359e-11 | 1.16699538921e-10 | fail | pass | pass |
| national_file | D5_OZONE | continuous | 238194 | 2390 | 0.010034 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 2.53521648119e-11 | 5.72697445023e-11 | 1.08428821477e-10 | fail | pass | pass |
| national_file | D5_PM25 | continuous | 238194 | 2388 | 0.010025 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 2.60911292571e-11 | 5.90603121964e-11 | 1.08684616862e-10 | fail | pass | pass |
| national_file | D5_PNPL | continuous | 240943 | 135253 | 0.561349 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 5.98845417699e-11 | 1.2323653209e-10 | fail | pass | pass |
| national_file | D5_PRMP | continuous | 240943 | 68386 | 0.283826 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 2.51887399827e-11 | 6.40909547656e-11 | 1.22042820294e-10 | fail | pass | pass |
| national_file | D5_PTRAF | continuous | 240943 | 3380 | 0.014028 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 2.46132003667e-11 | 5.7582383306e-11 | 1.20564891404e-10 | fail | pass | pass |
| national_file | D5_PTSDF | continuous | 240943 | 37328 | 0.154925 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 2.49471554525e-11 | 5.82645043323e-11 | 1.24373400467e-10 | fail | pass | pass |
| national_file | D5_PWDIS | continuous | 240439 | 18490 | 0.076901 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 2.56505927609e-11 | 6.05950845056e-11 | 1.25652377392e-10 | fail | pass | pass |
| national_file | D5_RSEI_AIR | continuous | 241692 | 2425 | 0.010033 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 2.53521648119e-11 | 6.38351593807e-11 | 1.18802745419e-10 | fail | pass | pass |
| national_file | D5_UST | continuous | 241776 | 65226 | 0.269779 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 2.58779664364e-11 | 6.38067376713e-11 | 1.20166987472e-10 | fail | pass | pass |
| national_file | DEMOGIDX_2 | continuous | 242336 | 2421 | 0.009990 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 1.34559030585e-13 | 3.64153152077e-13 | 4.53859172467e-13 | fail | pass | pass |
| national_file | DEMOGIDX_2ST | continuous | 242336 | 9485 | 0.039140 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 1.7763568394e-15 | 1.64313007645e-14 | 9.94759830064e-14 | fail | pass | pass |
| national_file | DEMOGIDX_5 | continuous | 242336 | 8 | 0.000033 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 5.64881474929e-13 | 8.23341395062e-13 | 1.32827082666e-12 | fail | pass | pass |
| national_file | DEMOGIDX_5ST | continuous | 242336 | 917 | 0.003784 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 2.0650148258e-14 | 1.39444011893e-13 | 4.7251091928e-13 | fail | pass | pass |
| national_file | P_D2_DSLPM | percentile | 240438 | 240438 | 1.000000 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_DWATER | percentile | 223128 | 223128 | 1.000000 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_LDPNT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_NO2 | percentile | 241704 | 241704 | 1.000000 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_OZONE | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_PM25 | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_PNPL | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_PRMP | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_PTRAF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_PTSDF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_PWDIS | percentile | 240439 | 240439 | 1.000000 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_RSEI_AIR | percentile | 241692 | 241692 | 1.000000 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D2_UST | percentile | 241776 | 241776 | 1.000000 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_DSLPM | percentile | 240438 | 240438 | 1.000000 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_DWATER | percentile | 223128 | 223128 | 1.000000 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_LDPNT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_NO2 | percentile | 241704 | 241704 | 1.000000 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_OZONE | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_PM25 | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_PNPL | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_PRMP | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_PTRAF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_PTSDF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_PWDIS | percentile | 240439 | 240439 | 1.000000 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_RSEI_AIR | percentile | 241692 | 241692 | 1.000000 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_D5_UST | percentile | 241776 | 241776 | 1.000000 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_DEMOGIDX_2 | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_DEMOGIDX_5 | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_DISABILITYPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_DSLPM | percentile | 240438 | 240438 | 1.000000 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_DWATER | percentile | 223128 | 223128 | 1.000000 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_LDPNT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_LESSHSPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_LIFEEXPPCT | percentile | 224930 | 224930 | 1.000000 | 224930 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_LINGISOPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_LOWINCPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_NO2 | percentile | 241704 | 241704 | 1.000000 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_OVER64PCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_OZONE | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PEOPCOLORPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PM25 | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PNPL | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PRMP | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PTRAF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PTSDF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_PWDIS | percentile | 240439 | 240439 | 1.000000 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_RSEI_AIR | percentile | 241692 | 241692 | 1.000000 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_UNDER5PCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_UNEMPPCT | percentile | 241912 | 241912 | 1.000000 | 241912 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| national_file | P_UST | percentile | 241776 | 241776 | 1.000000 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | D2_DSLPM | continuous | 240438 | 12579 | 0.052317 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 7.1054273576e-14 | 1.10844666779e-12 | 9.66338120634e-12 | fail | pass | pass |
| state_file | D2_DWATER | continuous | 223128 | 166628 | 0.746782 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 5.11590769747e-13 | 2.95585778076e-12 | fail | pass | pass |
| state_file | D2_LDPNT | continuous | 242336 | 44758 | 0.184694 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 6.39488462184e-14 | 1.05160324892e-12 | 9.77706804406e-12 | fail | pass | fail |
| state_file | D2_NO2 | continuous | 241704 | 13311 | 0.055071 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 7.1054273576e-14 | 1.13686837722e-12 | 9.77706804406e-12 | fail | pass | pass |
| state_file | D2_OZONE | continuous | 238194 | 13786 | 0.057877 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 7.1054273576e-14 | 9.37916411203e-13 | 2.8990143619e-12 | fail | pass | pass |
| state_file | D2_PM25 | continuous | 238194 | 13763 | 0.057781 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 7.1054273576e-14 | 9.94759830064e-13 | 2.95585778076e-12 | fail | pass | pass |
| state_file | D2_PNPL | continuous | 240943 | 139295 | 0.578124 | 240943 | 1.000000 | 440 | 1 | 1 | 0 | 0 | 9.37916411203e-13 | 9.77706804406e-12 | fail | pass | fail |
| state_file | D2_PRMP | continuous | 240943 | 75986 | 0.315369 | 240943 | 1.000000 | 440 | 1 | 1 | 0 | 4.97379915032e-14 | 1.10844666779e-12 | 9.77706804406e-12 | fail | pass | fail |
| state_file | D2_PTRAF | continuous | 240943 | 14292 | 0.059317 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 7.1054273576e-14 | 1.10844666779e-12 | 9.7202246252e-12 | fail | pass | pass |
| state_file | D2_PTSDF | continuous | 240943 | 45849 | 0.190290 | 240943 | 1.000000 | 440 | 1 | 1 | 0 | 6.39488462184e-14 | 1.08002495836e-12 | 9.77706804406e-12 | fail | pass | fail |
| state_file | D2_PWDIS | continuous | 240439 | 28272 | 0.117585 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 7.1054273576e-14 | 1.05160324892e-12 | 9.66338120634e-12 | fail | pass | pass |
| state_file | D2_RSEI_AIR | continuous | 241692 | 14418 | 0.059654 | 241692 | 1.000000 | 679 | 1 | 1 | 0 | 7.1054273576e-14 | 1.02318153949e-12 | 9.66338120634e-12 | fail | pass | fail |
| state_file | D2_UST | continuous | 241776 | 74183 | 0.306825 | 241776 | 1.000000 | 679 | 1 | 1 | 0 | 3.90798504668e-14 | 8.24229573482e-13 | 2.8990143619e-12 | fail | pass | fail |
| state_file | D5_DSLPM | continuous | 240438 | 3358 | 0.013966 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 7.95807864051e-13 | 7.90123522165e-12 | 3.87672116631e-11 | fail | pass | pass |
| state_file | D5_DWATER | continuous | 223128 | 164295 | 0.736326 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 3.43902684108e-12 | 2.62048160948e-11 | fail | pass | pass |
| state_file | D5_LDPNT | continuous | 242336 | 37892 | 0.156361 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 7.24753590475e-13 | 8.24229573482e-12 | 4.06998879043e-11 | fail | pass | pass |
| state_file | D5_NO2 | continuous | 241704 | 3435 | 0.014212 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 7.95807864051e-13 | 7.92965693108e-12 | 4.21778167947e-11 | fail | pass | pass |
| state_file | D5_OZONE | continuous | 238194 | 3250 | 0.013644 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 8.10018718767e-13 | 7.87281351222e-12 | 3.69482222595e-11 | fail | pass | pass |
| state_file | D5_PM25 | continuous | 238194 | 3238 | 0.013594 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 8.24229573482e-13 | 7.60280727263e-12 | 4.44515535492e-11 | fail | pass | pass |
| state_file | D5_PNPL | continuous | 240943 | 135676 | 0.563104 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 7.67386154621e-12 | 4.21778167947e-11 | fail | pass | pass |
| state_file | D5_PRMP | continuous | 240943 | 68972 | 0.286259 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 6.53699316899e-13 | 8.00071120466e-12 | 3.29691829393e-11 | fail | pass | pass |
| state_file | D5_PTRAF | continuous | 240943 | 4987 | 0.020698 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 7.95807864051e-13 | 7.70228325564e-12 | 4.2064129957e-11 | fail | pass | pass |
| state_file | D5_PTSDF | continuous | 240943 | 38123 | 0.158224 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 7.53175299906e-13 | 7.78754838393e-12 | 3.16617843055e-11 | fail | pass | pass |
| state_file | D5_PWDIS | continuous | 240439 | 19714 | 0.081992 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 7.74491581979e-13 | 7.7591266745e-12 | 3.91082721762e-11 | fail | pass | pass |
| state_file | D5_RSEI_AIR | continuous | 241692 | 4465 | 0.018474 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 8.02913291409e-13 | 7.73070496507e-12 | 4.35420588474e-11 | fail | pass | pass |
| state_file | D5_UST | continuous | 241776 | 66036 | 0.273129 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 5.11590769747e-13 | 4.6753712013e-12 | 4.04725142289e-11 | fail | pass | pass |
| state_file | DEMOGIDX_2 | continuous | 242336 | 9503 | 0.039214 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 1.7763568394e-15 | 1.64313007645e-14 | 9.94759830064e-14 | fail | pass | fail |
| state_file | DEMOGIDX_5 | continuous | 242336 | 917 | 0.003784 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 2.0650148258e-14 | 1.39444011893e-13 | 4.7251091928e-13 | fail | pass | pass |
| state_file | P_D2_DSLPM | percentile | 240438 | 240438 | 1.000000 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_DWATER | percentile | 223128 | 223128 | 1.000000 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_LDPNT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_D2_NO2 | percentile | 241704 | 241704 | 1.000000 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_OZONE | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_PM25 | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_PNPL | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 440 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_D2_PRMP | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 440 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_D2_PTRAF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_PTSDF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 440 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_D2_PWDIS | percentile | 240439 | 240439 | 1.000000 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D2_RSEI_AIR | percentile | 241692 | 241692 | 1.000000 | 241692 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_D2_UST | percentile | 241776 | 241776 | 1.000000 | 241776 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_D5_DSLPM | percentile | 240438 | 240438 | 1.000000 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_DWATER | percentile | 223128 | 223128 | 1.000000 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_LDPNT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_NO2 | percentile | 241704 | 241704 | 1.000000 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_OZONE | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_PM25 | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_PNPL | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_PRMP | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_PTRAF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_PTSDF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_PWDIS | percentile | 240439 | 240439 | 1.000000 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_RSEI_AIR | percentile | 241692 | 241692 | 1.000000 | 241692 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_D5_UST | percentile | 241776 | 241776 | 1.000000 | 241776 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_DEMOGIDX_2 | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_DEMOGIDX_5 | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_DISABILITYPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_DSLPM | percentile | 240438 | 240438 | 1.000000 | 240438 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_DWATER | percentile | 223128 | 223128 | 1.000000 | 223128 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_LDPNT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_LESSHSPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_LIFEEXPPCT | percentile | 224930 | 224930 | 1.000000 | 224930 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_LINGISOPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_LOWINCPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_NO2 | percentile | 241704 | 241704 | 1.000000 | 241704 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_OVER64PCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 685 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_OZONE | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_PEOPCOLORPCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 685 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_PM25 | percentile | 238194 | 238194 | 1.000000 | 238194 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_PNPL | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 446 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_PRMP | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 446 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_PTRAF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_PTSDF | percentile | 240943 | 240943 | 1.000000 | 240943 | 1.000000 | 446 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_PWDIS | percentile | 240439 | 240439 | 1.000000 | 240439 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | pass |
| state_file | P_RSEI_AIR | percentile | 241692 | 241692 | 1.000000 | 241692 | 1.000000 | 685 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_UNDER5PCT | percentile | 242336 | 242336 | 1.000000 | 242336 | 1.000000 | 685 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_UNEMPPCT | percentile | 241912 | 241912 | 1.000000 | 241912 | 1.000000 | 679 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |
| state_file | P_UST | percentile | 241776 | 241776 | 1.000000 | 241776 | 1.000000 | 685 | 1 | 1 | 0 | 0 | 0 | 0 | pass | pass | fail |

## Absolute difference and percentile rank difference

The absolute difference columns are in the table above. Percentile rank difference is the absolute gap, on a 0 to 100 scale, between `percent_rank()` of the rebuilt value and `percent_rank()` of the reference value among rows where both are present.

| Scope | Column | Rank diff min | Rank diff median | Rank diff p95 | Rank diff max |
| --- | --- | --- | --- | --- | --- |
| national_file | D2_DSLPM | 0 | 0 | 0 | 0.00207954682516 |
| national_file | D2_DWATER | 0 | 0 | 0 | 0 |
| national_file | D2_LDPNT | 0 | 0 | 0 | 0 |
| national_file | D2_NO2 | 0 | 0 | 0 | 0.000827461802294 |
| national_file | D2_OZONE | 0 | 0 | 0 | 0.00125948285634 |
| national_file | D2_PM25 | 0 | 0 | 0 | 0.00125948285634 |
| national_file | D2_PNPL | 0 | 0 | 0 | 0.000415037643919 |
| national_file | D2_PRMP | 0 | 0 | 0 | 0.000415037643919 |
| national_file | D2_PTRAF | 0 | 0 | 0 | 0.00124511293175 |
| national_file | D2_PTSDF | 0 | 0 | 0 | 0.000415037643919 |
| national_file | D2_PWDIS | 0 | 0 | 0 | 0.000415907635234 |
| national_file | D2_RSEI_AIR | 0 | 0 | 0 | 0.00124125432887 |
| national_file | D2_UST | 0 | 0 | 0 | 0.00124082307932 |
| national_file | D5_DSLPM | 0 | 0 | 0 | 0 |
| national_file | D5_DWATER | 0 | 0 | 0 | 0 |
| national_file | D5_LDPNT | 0 | 0 | 0 | 0 |
| national_file | D5_NO2 | 0 | 0 | 0 | 0 |
| national_file | D5_OZONE | 0 | 0 | 0 | 0 |
| national_file | D5_PM25 | 0 | 0 | 0 | 0 |
| national_file | D5_PNPL | 0 | 0 | 0 | 0 |
| national_file | D5_PRMP | 0 | 0 | 0 | 0 |
| national_file | D5_PTRAF | 0 | 0 | 0 | 0 |
| national_file | D5_PTSDF | 0 | 0 | 0 | 0 |
| national_file | D5_PWDIS | 0 | 0 | 0 | 0 |
| national_file | D5_RSEI_AIR | 0 | 0 | 0 | 0 |
| national_file | D5_UST | 0 | 0 | 0 | 0 |
| national_file | DEMOGIDX_2 | 0 | 0 | 0 | 0 |
| national_file | DEMOGIDX_2ST | 0 | 0 | 0 | 0 |
| national_file | DEMOGIDX_5 | 0 | 0 | 0 | 0 |
| national_file | DEMOGIDX_5ST | 0 | 0 | 0 | 0 |
| national_file | P_D2_DSLPM | 0 | 0 | 0 | 0 |
| national_file | P_D2_DWATER | 0 | 0 | 0 | 0 |
| national_file | P_D2_LDPNT | 0 | 0 | 0 | 0 |
| national_file | P_D2_NO2 | 0 | 0 | 0 | 0 |
| national_file | P_D2_OZONE | 0 | 0 | 0 | 0 |
| national_file | P_D2_PM25 | 0 | 0 | 0 | 0 |
| national_file | P_D2_PNPL | 0 | 0 | 0 | 0 |
| national_file | P_D2_PRMP | 0 | 0 | 0 | 0 |
| national_file | P_D2_PTRAF | 0 | 0 | 0 | 0 |
| national_file | P_D2_PTSDF | 0 | 0 | 0 | 0 |
| national_file | P_D2_PWDIS | 0 | 0 | 0 | 0 |
| national_file | P_D2_RSEI_AIR | 0 | 0 | 0 | 0 |
| national_file | P_D2_UST | 0 | 0 | 0 | 0 |
| national_file | P_D5_DSLPM | 0 | 0 | 0 | 0 |
| national_file | P_D5_DWATER | 0 | 0 | 0 | 0 |
| national_file | P_D5_LDPNT | 0 | 0 | 0 | 0 |
| national_file | P_D5_NO2 | 0 | 0 | 0 | 0 |
| national_file | P_D5_OZONE | 0 | 0 | 0 | 0 |
| national_file | P_D5_PM25 | 0 | 0 | 0 | 0 |
| national_file | P_D5_PNPL | 0 | 0 | 0 | 0 |
| national_file | P_D5_PRMP | 0 | 0 | 0 | 0 |
| national_file | P_D5_PTRAF | 0 | 0 | 0 | 0 |
| national_file | P_D5_PTSDF | 0 | 0 | 0 | 0 |
| national_file | P_D5_PWDIS | 0 | 0 | 0 | 0 |
| national_file | P_D5_RSEI_AIR | 0 | 0 | 0 | 0 |
| national_file | P_D5_UST | 0 | 0 | 0 | 0 |
| national_file | P_DEMOGIDX_2 | 0 | 0 | 0 | 0 |
| national_file | P_DEMOGIDX_5 | 0 | 0 | 0 | 0 |
| national_file | P_DISABILITYPCT | 0 | 0 | 0 | 0 |
| national_file | P_DSLPM | 0 | 0 | 0 | 0 |
| national_file | P_DWATER | 0 | 0 | 0 | 0 |
| national_file | P_LDPNT | 0 | 0 | 0 | 0 |
| national_file | P_LESSHSPCT | 0 | 0 | 0 | 0 |
| national_file | P_LIFEEXPPCT | 0 | 0 | 0 | 0 |
| national_file | P_LINGISOPCT | 0 | 0 | 0 | 0 |
| national_file | P_LOWINCPCT | 0 | 0 | 0 | 0 |
| national_file | P_NO2 | 0 | 0 | 0 | 0 |
| national_file | P_OVER64PCT | 0 | 0 | 0 | 0 |
| national_file | P_OZONE | 0 | 0 | 0 | 0 |
| national_file | P_PEOPCOLORPCT | 0 | 0 | 0 | 0 |
| national_file | P_PM25 | 0 | 0 | 0 | 0 |
| national_file | P_PNPL | 0 | 0 | 0 | 0 |
| national_file | P_PRMP | 0 | 0 | 0 | 0 |
| national_file | P_PTRAF | 0 | 0 | 0 | 0 |
| national_file | P_PTSDF | 0 | 0 | 0 | 0 |
| national_file | P_PWDIS | 0 | 0 | 0 | 0 |
| national_file | P_RSEI_AIR | 0 | 0 | 0 | 0 |
| national_file | P_UNDER5PCT | 0 | 0 | 0 | 0 |
| national_file | P_UNEMPPCT | 0 | 0 | 0 | 0 |
| national_file | P_UST | 0 | 0 | 0 | 0 |
| state_file | D2_DSLPM | 0 | 0 | 0 | 0 |
| state_file | D2_DWATER | 0 | 0 | 0 | 0 |
| state_file | D2_LDPNT | 0 | 0 | 0 | 0 |
| state_file | D2_NO2 | 0 | 0 | 0 | 0.000413730901139 |
| state_file | D2_OZONE | 0 | 0 | 0 | 0 |
| state_file | D2_PM25 | 0 | 0 | 0 | 0.000419827618775 |
| state_file | D2_PNPL | 0 | 0 | 0 | 0 |
| state_file | D2_PRMP | 0 | 0 | 0 | 0 |
| state_file | D2_PTRAF | 0 | 0 | 0 | 0 |
| state_file | D2_PTSDF | 0 | 0 | 0 | 0 |
| state_file | D2_PWDIS | 0 | 0 | 0 | 0 |
| state_file | D2_RSEI_AIR | 0 | 0 | 0 | 0.000413751442963 |
| state_file | D2_UST | 0 | 0 | 0 | 0 |
| state_file | D5_DSLPM | 0 | 0 | 0 | 0 |
| state_file | D5_DWATER | 0 | 0 | 0 | 0 |
| state_file | D5_LDPNT | 0 | 0 | 0 | 0 |
| state_file | D5_NO2 | 0 | 0 | 0 | 0 |
| state_file | D5_OZONE | 0 | 0 | 0 | 0 |
| state_file | D5_PM25 | 0 | 0 | 0 | 0 |
| state_file | D5_PNPL | 0 | 0 | 0 | 0 |
| state_file | D5_PRMP | 0 | 0 | 0 | 0 |
| state_file | D5_PTRAF | 0 | 0 | 0 | 0 |
| state_file | D5_PTSDF | 0 | 0 | 0 | 0 |
| state_file | D5_PWDIS | 0 | 0 | 0 | 0 |
| state_file | D5_RSEI_AIR | 0 | 0 | 0 | 0 |
| state_file | D5_UST | 0 | 0 | 0 | 0 |
| state_file | DEMOGIDX_2 | 0 | 0 | 0 | 0 |
| state_file | DEMOGIDX_5 | 0 | 0 | 0 | 0 |
| state_file | P_D2_DSLPM | 0 | 0 | 0 | 0 |
| state_file | P_D2_DWATER | 0 | 0 | 0 | 0 |
| state_file | P_D2_LDPNT | 0 | 0 | 0 | 0 |
| state_file | P_D2_NO2 | 0 | 0 | 0 | 0 |
| state_file | P_D2_OZONE | 0 | 0 | 0 | 0 |
| state_file | P_D2_PM25 | 0 | 0 | 0 | 0 |
| state_file | P_D2_PNPL | 0 | 0 | 0 | 0 |
| state_file | P_D2_PRMP | 0 | 0 | 0 | 0 |
| state_file | P_D2_PTRAF | 0 | 0 | 0 | 0 |
| state_file | P_D2_PTSDF | 0 | 0 | 0 | 0 |
| state_file | P_D2_PWDIS | 0 | 0 | 0 | 0 |
| state_file | P_D2_RSEI_AIR | 0 | 0 | 0 | 0 |
| state_file | P_D2_UST | 0 | 0 | 0 | 0 |
| state_file | P_D5_DSLPM | 0 | 0 | 0 | 0 |
| state_file | P_D5_DWATER | 0 | 0 | 0 | 0 |
| state_file | P_D5_LDPNT | 0 | 0 | 0 | 0 |
| state_file | P_D5_NO2 | 0 | 0 | 0 | 0 |
| state_file | P_D5_OZONE | 0 | 0 | 0 | 0 |
| state_file | P_D5_PM25 | 0 | 0 | 0 | 0 |
| state_file | P_D5_PNPL | 0 | 0 | 0 | 0 |
| state_file | P_D5_PRMP | 0 | 0 | 0 | 0 |
| state_file | P_D5_PTRAF | 0 | 0 | 0 | 0 |
| state_file | P_D5_PTSDF | 0 | 0 | 0 | 0 |
| state_file | P_D5_PWDIS | 0 | 0 | 0 | 0 |
| state_file | P_D5_RSEI_AIR | 0 | 0 | 0 | 0 |
| state_file | P_D5_UST | 0 | 0 | 0 | 0 |
| state_file | P_DEMOGIDX_2 | 0 | 0 | 0 | 0 |
| state_file | P_DEMOGIDX_5 | 0 | 0 | 0 | 0 |
| state_file | P_DISABILITYPCT | 0 | 0 | 0 | 0 |
| state_file | P_DSLPM | 0 | 0 | 0 | 0 |
| state_file | P_DWATER | 0 | 0 | 0 | 0 |
| state_file | P_LDPNT | 0 | 0 | 0 | 0 |
| state_file | P_LESSHSPCT | 0 | 0 | 0 | 0 |
| state_file | P_LIFEEXPPCT | 0 | 0 | 0 | 0 |
| state_file | P_LINGISOPCT | 0 | 0 | 0 | 0 |
| state_file | P_LOWINCPCT | 0 | 0 | 0 | 0 |
| state_file | P_NO2 | 0 | 0 | 0 | 0 |
| state_file | P_OVER64PCT | 0 | 0 | 0 | 0 |
| state_file | P_OZONE | 0 | 0 | 0 | 0 |
| state_file | P_PEOPCOLORPCT | 0 | 0 | 0 | 0 |
| state_file | P_PM25 | 0 | 0 | 0 | 0 |
| state_file | P_PNPL | 0 | 0 | 0 | 0 |
| state_file | P_PRMP | 0 | 0 | 0 | 0 |
| state_file | P_PTRAF | 0 | 0 | 0 | 0 |
| state_file | P_PTSDF | 0 | 0 | 0 | 0 |
| state_file | P_PWDIS | 0 | 0 | 0 | 0 |
| state_file | P_RSEI_AIR | 0 | 0 | 0 | 0 |
| state_file | P_UNDER5PCT | 0 | 0 | 0 | 0 |
| state_file | P_UNEMPPCT | 0 | 0 | 0 | 0 |
| state_file | P_UST | 0 | 0 | 0 | 0 |

## Largest mismatches

| Scope | Column | GEOID | Area | Rebuilt | Reference | Absolute difference | Life expectancy missing |
| --- | --- | --- | --- | --- | --- | --- | --- |
| national_file | D5_DWATER | 540459569001 | WV | 364.025300703 | 364.025300703 | 1.31535671244e-10 | False |
| national_file | D5_DWATER | 540459569002 | WV | 357.591795783 | 357.591795783 | 1.29148247652e-10 | False |
| national_file | D5_DSLPM | 360610238023 | NY | 241.457835382 | 241.457835382 | 1.25652377392e-10 | False |
| national_file | D5_PWDIS | 360610238023 | NY | 241.457835382 | 241.457835382 | 1.25652377392e-10 | False |
| national_file | D5_PTSDF | 360610238023 | NY | 239.018867348 | 239.018867348 | 1.24373400467e-10 | False |
| national_file | D5_PNPL | 517100042002 | VA | 378.36821943 | 378.36821943 | 1.2323653209e-10 | False |
| national_file | D5_PNPL | 120310016002 | FL | 385.815198364 | 385.815198364 | 1.22668097902e-10 | False |
| national_file | D5_PRMP | 390950029002 | OH | 425.120325152 | 425.120325152 | 1.22042820294e-10 | False |
| national_file | D5_PRMP | 120310016002 | FL | 381.918075148 | 381.918075148 | 1.21474386106e-10 | False |
| national_file | D5_PRMP | 721279801031 | PR | 569.330635046 | 569.330635046 | 1.20849108498e-10 | True |
| national_file | D5_PTRAF | 360610238023 | NY | 231.701963246 | 231.701963246 | 1.20564891404e-10 | False |
| national_file | D5_UST | 120310016002 | FL | 378.020951932 | 378.020951932 | 1.20166987472e-10 | False |
| national_file | D5_PWDIS | 245100803011 | MD | 353.323632219 | 353.323632219 | 1.19712240121e-10 | False |
| national_file | D5_UST | 517100042002 | VA | 366.292637959 | 366.292637959 | 1.1925749277e-10 | False |
| national_file | D5_PNPL | 391130017001 | OH | 332.933885174 | 332.933885174 | 1.18802745419e-10 | False |
| national_file | D5_RSEI_AIR | 391130017001 | OH | 332.933885174 | 332.933885174 | 1.18802745419e-10 | False |
| national_file | D5_PRMP | 220330006011 | LA | 353.56642503 | 353.56642503 | 1.18404841487e-10 | False |
| national_file | D5_RSEI_AIR | 220330006011 | LA | 353.56642503 | 353.56642503 | 1.18404841487e-10 | False |
| national_file | D5_PNPL | 360610238023 | NY | 226.824027177 | 226.824027177 | 1.18035359264e-10 | False |
| national_file | D5_PNPL | 120310016001 | FL | 365.915209948 | 365.915209948 | 1.17097442853e-10 | False |

### Reading the largest gaps

The 20 largest absolute differences are at most 1e-8. That is the size of double precision residue for these calculations, not a separate formula.

## Pilot area, state FIPS 06

national_file D2_DSLPM: exact 0.008726, tolerance 1.000000, null disagreements 0.
national_file D2_DWATER: exact 0.959839, tolerance 1.000000, null disagreements 0.
national_file D2_LDPNT: exact 0.153864, tolerance 1.000000, null disagreements 0.
national_file D2_NO2: exact 0.006920, tolerance 1.000000, null disagreements 0.
national_file D2_OZONE: exact 0.070215, tolerance 1.000000, null disagreements 0.
national_file D2_PM25: exact 0.003749, tolerance 1.000000, null disagreements 0.
national_file D2_PNPL: exact 0.451031, tolerance 1.000000, null disagreements 0.
national_file D2_PRMP: exact 0.201197, tolerance 1.000000, null disagreements 0.
national_file D2_PTRAF: exact 0.007317, tolerance 1.000000, null disagreements 0.
national_file D2_PTSDF: exact 0.019995, tolerance 1.000000, null disagreements 0.
national_file D2_PWDIS: exact 0.167312, tolerance 1.000000, null disagreements 0.
national_file D2_RSEI_AIR: exact 0.012899, tolerance 1.000000, null disagreements 0.
national_file D5_DSLPM: exact 0.006887, tolerance 1.000000, null disagreements 0.
national_file D5_DWATER: exact 0.959799, tolerance 1.000000, null disagreements 0.
national_file D5_LDPNT: exact 0.153708, tolerance 1.000000, null disagreements 0.
national_file D5_NO2: exact 0.004183, tolerance 1.000000, null disagreements 0.
national_file D5_OZONE: exact 0.067169, tolerance 1.000000, null disagreements 0.
national_file D5_PM25: exact 0.000078, tolerance 1.000000, null disagreements 0.
national_file D5_PNPL: exact 0.449818, tolerance 1.000000, null disagreements 0.
national_file D5_PRMP: exact 0.199867, tolerance 1.000000, null disagreements 0.
national_file D5_PTRAF: exact 0.005478, tolerance 1.000000, null disagreements 0.
national_file D5_PTSDF: exact 0.018116, tolerance 1.000000, null disagreements 0.
national_file D5_PWDIS: exact 0.165708, tolerance 1.000000, null disagreements 0.
national_file D5_RSEI_AIR: exact 0.010241, tolerance 1.000000, null disagreements 0.
national_file DEMOGIDX_2: exact 0.003749, tolerance 1.000000, null disagreements 0.
national_file DEMOGIDX_2ST: exact 0.003749, tolerance 1.000000, null disagreements 0.
national_file DEMOGIDX_5: exact 0.000117, tolerance 1.000000, null disagreements 0.
national_file DEMOGIDX_5ST: exact 0.000039, tolerance 1.000000, null disagreements 0.
state_file D2_DSLPM: exact 0.011856, tolerance 1.000000, null disagreements 0.
state_file D2_DWATER: exact 0.959839, tolerance 1.000000, null disagreements 0.
state_file D2_LDPNT: exact 0.153864, tolerance 1.000000, null disagreements 0.
state_file D2_NO2: exact 0.012784, tolerance 1.000000, null disagreements 0.
state_file D2_OZONE: exact 0.013434, tolerance 1.000000, null disagreements 0.
state_file D2_PM25: exact 0.013551, tolerance 1.000000, null disagreements 0.
state_file D2_PNPL: exact 0.451031, tolerance 1.000000, null disagreements 0.
state_file D2_PRMP: exact 0.201197, tolerance 1.000000, null disagreements 0.
state_file D2_PTRAF: exact 0.011934, tolerance 1.000000, null disagreements 0.
state_file D2_PTSDF: exact 0.019995, tolerance 1.000000, null disagreements 0.
state_file D2_PWDIS: exact 0.167312, tolerance 1.000000, null disagreements 0.
state_file D2_RSEI_AIR: exact 0.012742, tolerance 1.000000, null disagreements 0.
state_file D5_DSLPM: exact 0.010056, tolerance 1.000000, null disagreements 0.
state_file D5_DWATER: exact 0.959799, tolerance 1.000000, null disagreements 0.
state_file D5_LDPNT: exact 0.153708, tolerance 1.000000, null disagreements 0.
state_file D5_NO2: exact 0.010047, tolerance 1.000000, null disagreements 0.
state_file D5_OZONE: exact 0.009919, tolerance 1.000000, null disagreements 0.
state_file D5_PM25: exact 0.009958, tolerance 1.000000, null disagreements 0.
state_file D5_PNPL: exact 0.449779, tolerance 1.000000, null disagreements 0.
state_file D5_PRMP: exact 0.199789, tolerance 1.000000, null disagreements 0.
state_file D5_PTRAF: exact 0.010056, tolerance 1.000000, null disagreements 0.
state_file D5_PTSDF: exact 0.018116, tolerance 1.000000, null disagreements 0.
state_file D5_PWDIS: exact 0.165669, tolerance 1.000000, null disagreements 0.
state_file D5_RSEI_AIR: exact 0.010084, tolerance 1.000000, null disagreements 0.
state_file DEMOGIDX_2: exact 0.003749, tolerance 1.000000, null disagreements 0.
state_file DEMOGIDX_5: exact 0.000039, tolerance 1.000000, null disagreements 0.

Top 20 block groups in this state by the rebuilt national PM2.5 EJ index:

| GEOID | Rebuilt D2_PM25 | Reference D2_PM25 | Rebuilt national PM2.5 percentile | Rebuilt state PM2.5 percentile |
| --- | --- | --- | --- | --- |
| 060190034011 | 383.078594878 | 383.078594878 | 99 | 97 |
| 060290023041 | 378.923141321 | 378.923141321 | 99 | 93 |
| 060190027024 | 378.633782769 | 378.633782769 | 99 | 98 |
| 060770007003 | 378.189465819 | 378.189465819 | 98 | 86 |
| 060590876026 | 377.267701486 | 377.267701486 | 96 | 74 |
| 060470003063 | 376.501259218 | 376.501259218 | 98 | 92 |
| 060290012023 | 375.563565812 | 375.563565812 | 99 | 94 |
| 060390009011 | 374.146741672 | 374.146741672 | 99 | 95 |
| 060290026001 | 371.053942049 | 371.053942049 | 99 | 94 |
| 060290012021 | 370.484100218 | 370.484100218 | 99 | 94 |
| 060390008023 | 369.813577686 | 369.813577686 | 99 | 95 |
| 060190009021 | 369.554784123 | 369.554784123 | 99 | 97 |
| 060379800331 | 369.407957705 | 369.407957705 | 94 | 60 |
| 060190027021 | 368.863752427 | 368.863752427 | 99 | 98 |
| 060290048013 | 368.817820439 | 368.817820439 | 99 | 96 |
| 061090042013 | 368.679642055 | 368.679642055 | 98 | 92 |
| 061070002033 | 368.618663453 | 368.618663453 | 99 | 98 |
| 060190013015 | 367.946593365 | 367.946593365 | 99 | 98 |
| 060190083031 | 367.874833133 | 367.874833133 | 95 | 66 |
| 060290044022 | 365.840132965 | 365.840132966 | 99 | 94 |

## Worked example block group 410510068022

Tech doc pp. 36 to 39 use this block group. The reference values below are the published full precision fields, not the rounded figures in the narrative.

| Scope | Column | Rebuilt | Reference |
| --- | --- | --- | --- |
| national_file | D2_PNPL | 49.5320015423 | 49.5320015423 |
| national_file | D5_PNPL | 59.9208377983 | 59.9208377984 |
| national_file | DEMOGIDX_2 | 0.839525449869 | 0.839525449869 |
| national_file | DEMOGIDX_2ST | 1.29048820117 | 1.29048820117 |
| national_file | DEMOGIDX_5 | 1.01560742031 | 1.01560742031 |
| national_file | DEMOGIDX_5ST | 1.00169970821 | 1.00169970821 |
| national_file | P_PNPL | 59 | 59 |
| state_file | D2_PNPL | 90.3341740816 | 90.3341740816 |
| state_file | D5_PNPL | 70.1189795749 | 70.1189795749 |
| state_file | DEMOGIDX_2 | 1.29048820117 | 1.29048820117 |
| state_file | DEMOGIDX_5 | 1.00169970821 | 1.00169970821 |
| state_file | P_PNPL | 70 | 70 |

## Percent rank compared with the cutoff percentile

`marts.indicator_percent_rank` uses `percent_rank()` times 100. The table below compares it with the cutoff percentile on the same rows.

| Scope | Columns | Smallest column minimum | Median of column medians | Largest column maximum | Mean of column means |
| --- | --- | --- | --- | --- | --- |
| national_file | 50 | 0 | 0.45991066304 | 0.999995862691 | 0.416579217407 |
| state_file | 50 | 0 | 2.82064084841 | 95.7756944998 | 6.22486563226 |

Largest column maximums:

| Scope | Percentile column | Rows | Min | Median | P95 | Max | Mean |
| --- | --- | --- | --- | --- | --- | --- | --- |
| state_file | P_PM25 | 238194 | 0 | 15.7607738263 | 60.1852993161 | 95.7756944998 | 21.0962753286 |
| state_file | P_DEMOGIDX_2 | 242336 | 0 | 6.02134441991 | 19.6401314296 | 93.9529783151 | 7.81009965871 |
| state_file | P_LINGISOPCT | 242336 | 0 | 0 | 20.3488559226 | 92.0868219613 | 5.05557189697 |
| state_file | P_PEOPCOLORPCT | 242336 | 0 | 9.30468153589 | 32.5459642643 | 86.8172571028 | 12.4281003061 |
| state_file | P_PTSDF | 240943 | 0 | 9.4879680587 | 39.2686829195 | 84.7019531672 | 13.0772276246 |
| state_file | P_OZONE | 238194 | 0 | 19.1415406834 | 52.8187478221 | 84.4991246594 | 22.5504645597 |
| state_file | P_PTRAF | 240943 | 0 | 9.41148492168 | 35.3936798068 | 81.8363589578 | 12.4479164239 |
| state_file | P_DSLPM | 240438 | 0 | 9.05193668196 | 31.3537533741 | 78.7191197694 | 12.4039923392 |
| state_file | P_PWDIS | 240439 | 0 | 9.33772531796 | 33.665728379 | 76.5987988587 | 11.8878191698 |
| state_file | P_RSEI_AIR | 241692 | 0 | 9.89767513064 | 34.4392447381 | 73.8232619336 | 12.1349132596 |
| state_file | P_UST | 241776 | 0 | 4.37224692379 | 20.7047099576 | 71.5654017165 | 6.53913830968 |
| state_file | P_LOWINCPCT | 242336 | 0 | 4.46453256855 | 17.542693998 | 67.2792002806 | 6.09229137165 |
| state_file | P_DEMOGIDX_5 | 242336 | 0 | 2.43417170446 | 15.8949181918 | 65.9871871583 | 4.78704113835 |
| state_file | P_PRMP | 240943 | 0 | 5.86581832972 | 23.3757153174 | 60.10815881 | 7.04824595715 |
| state_file | P_DWATER | 223128 | 0 | 0 | 28.6266431225 | 57.4255334406 | 3.64181692341 |

## Raw indicator agreement between the two extracts

Staging uses the national extract for indicator inputs. Rows below are indicator columns whose numeric values are not identical in the state extract.

| Column | Rows that differ | Maximum absolute difference |
| --- | --- | --- |
| OVER64PCT | 685 | 0 |
| PEOPCOLORPCT | 685 | 0 |
| RSEI_AIR | 685 | 0 |
| UNDER5PCT | 685 | 0 |
| UST | 685 | 0 |
| LESSHSPCT | 679 | 0 |
| LINGISOPCT | 679 | 0 |
| LOWINCPCT | 679 | 0 |
| PRE1960PCT | 679 | 0 |
| UNEMPPCT | 679 | 0 |
| PNPL | 446 | 0 |
| PRMP | 446 | 0 |
| PTSDF | 446 | 0 |

## Tier 2, ACS demographic rebuild

Thresholds are fixed in `sql/validation/tier2_metrics.sql`. Continuous tolerance is an absolute difference of at most 1e-8 on at least 99 percent of rows where both values are present. Null agreement passes at 99.9 percent. A low match rate is reported. It does not stop the run. The ACS assertions cover 12 character ids, exclusion of the four island territories, non-negative population, 52 state codes, and the non-negative demographic shift.

ACS block groups loaded: 242336.
Negative ACS count values set to null: 0.
Tier 2 column checks passed: 0. Tier 2 column checks failed: 13.

The four island territories are not in the 2022 ACS 5-year API, so they are not in this rebuild.
A zero ACS denominator is stored as 0. Unemployment is null when the civilian labor force is 0 and the block group population is greater than 0. Less than high school includes B15002.027. Disability is the tract rate assigned to each block group in the tract. Low life expectancy is 1 minus life expectancy at birth divided by 97.5. Connecticut 2022 tracts use the Geocorr 2022 pop20 crosswalk. The supplemental demographic index is the five factor average, or the four factor average where low life expectancy is missing.

### Geographic ids

Every ACS block group id is in the reference extract, and every reference block group in the states, the District of Columbia, and Puerto Rico is in the ACS rebuild.

### Columns

| Column | Rows | Both present | Exact rate | Tolerance rate | Null disagreements | Pearson | Spearman | Abs min | Abs median | Abs p95 | Abs max | Exact | Tolerance | Nulls |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DEMOGIDX_2 | 242336 | 242336 | 0.009990 | 1.000000 | 0 | 1 | 1 | 0 | 1.31228361511e-13 | 3.72590847064e-13 | 4.38316050122e-13 | fail | pass | pass |
| DEMOGIDX_2ST | 242336 | 242336 | 0.021631 | 1.000000 | 0 | 1 | 1 | 0 | 3.77475828373e-15 | 3.64153152077e-14 | 9.01501095996e-14 | fail | pass | pass |
| DEMOGIDX_5 | 242336 | 242336 | 0.000004 | 0.000017 | 0 | 0.999555886941 | 0.999433822752 | 0 | 0.000904734492 | 0.00128413927921 | 0.907035216797 | fail | fail | pass |
| DEMOGIDX_5ST | 242336 | 242336 | 0.001936 | 0.024185 | 0 | 0.999500044995 | 0.999411646482 | 0 | 0.000684052443873 | 0.00411761788342 | 0.880889303512 | fail | fail | pass |
| DISABILITYPCT | 242336 | 242336 | 0.029839 | 1.000000 | 0 | 1 | 1 | 0 | 2.49800180541e-16 | 4.71844785466e-16 | 5.55111512313e-16 | fail | pass | pass |
| LESSHSPCT | 242336 | 242336 | 0.129845 | 1.000000 | 0 | 1 | 1 | 0 | 2.22044604925e-16 | 4.71844785466e-16 | 5.55111512313e-16 | fail | pass | pass |
| LIFEEXPPCT | 242336 | 224207 | 0.024669 | 0.981049 | 996 | 0.996506785671 | 0.996325822572 | 0 | 2.77555756156e-16 | 4.85722573274e-16 | 0.181538461538 | fail | fail | fail |
| LINGISOPCT | 242336 | 242336 | 0.581548 | 1.000000 | 0 | 1 | 1 | 0 | 0 | 4.4408920985e-16 | 6.66133814775e-16 | fail | pass | pass |
| LOWINCPCT | 242336 | 242336 | 0.080289 | 1.000000 | 0 | 1 | 1 | 0 | 2.22044604925e-16 | 4.71844785466e-16 | 6.66133814775e-16 | fail | pass | pass |
| OVER64PCT | 242336 | 242336 | 0.058984 | 1.000000 | 0 | 1 | 1 | 0 | 2.49800180541e-16 | 4.71844785466e-16 | 5.55111512313e-16 | fail | pass | pass |
| PEOPCOLORPCT | 242336 | 242336 | 0.115823 | 1.000000 | 0 | 1 | 1 | 0 | 2.22044604925e-16 | 4.57966997658e-16 | 6.66133814775e-16 | fail | pass | pass |
| UNDER5PCT | 242336 | 242336 | 0.142760 | 1.000000 | 0 | 1 | 1 | 0 | 2.08166817117e-16 | 4.71844785466e-16 | 4.99600361081e-16 | fail | pass | pass |
| UNEMPPCT | 242336 | 241911 | 0.248438 | 1.000000 | 1 | 1 | 1 | 0 | 1.70002900646e-16 | 4.68375338514e-16 | 5.55111512313e-16 | fail | pass | pass |

### Pilot slice state_fips_06

Same thresholds as the national table. This slice is the state set in `STATE_FIPS`.

| Column | Rows | Both present | Exact rate | Tolerance rate | Null disagreements | Pearson | Spearman | Abs median | Abs max | Exact | Tolerance | Nulls |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DEMOGIDX_2 | 25607 | 25607 | 0.003749 | 1.000000 | 0 | 1 | 1 | 2.31592522937e-13 | 4.38316050122e-13 | fail | pass | pass |
| DEMOGIDX_2ST | 25607 | 25607 | 0.005155 | 1.000000 | 0 | 1 | 1 | 2.975397706e-14 | 5.86197757002e-14 | fail | pass | pass |
| DEMOGIDX_5 | 25607 | 25607 | 0.000000 | 0.000000 | 0 | 0.999256351938 | 0.999295466375 | 0.0255177454527 | 0.802184231898 | fail | fail | pass |
| DEMOGIDX_5ST | 25607 | 25607 | 0.000000 | 0.000000 | 0 | 0.999264861788 | 0.999292672886 | 0.00899738402685 | 0.928625540668 | fail | fail | pass |
| DISABILITYPCT | 25607 | 25607 | 0.023470 | 1.000000 | 0 | 1 | 1 | 2.49800180541e-16 | 5.55111512313e-16 | fail | pass | pass |
| LESSHSPCT | 25607 | 25607 | 0.120123 | 1.000000 | 0 | 1 | 1 | 2.22044604925e-16 | 5.55111512313e-16 | fail | pass | pass |
| LIFEEXPPCT | 25607 | 24263 | 0.023245 | 0.986976 | 333 | 0.999199867202 | 0.999179715492 | 2.49800180541e-16 | 0.0493971660541 | fail | fail | fail |
| LINGISOPCT | 25607 | 25607 | 0.311126 | 1.000000 | 0 | 1 | 1 | 1.45716771982e-16 | 5.55111512313e-16 | fail | pass | pass |
| LOWINCPCT | 25607 | 25607 | 0.067833 | 1.000000 | 0 | 1 | 1 | 2.22044604925e-16 | 5.55111512313e-16 | fail | pass | pass |
| OVER64PCT | 25607 | 25607 | 0.048385 | 1.000000 | 0 | 1 | 1 | 2.49800180541e-16 | 5.55111512313e-16 | fail | pass | pass |
| PEOPCOLORPCT | 25607 | 25607 | 0.122349 | 1.000000 | 0 | 1 | 1 | 2.22044604925e-16 | 6.66133814775e-16 | fail | pass | pass |
| UNDER5PCT | 25607 | 25607 | 0.121490 | 1.000000 | 0 | 1 | 1 | 2.22044604925e-16 | 4.99600361081e-16 | fail | pass | pass |
| UNEMPPCT | 25607 | 25558 | 0.169458 | 1.000000 | 0 | 1 | 1 | 2.01227923213e-16 | 5.55111512313e-16 | fail | pass | pass |

### Rates outside 0 to 1

This is a reported check. It does not stop the run.

| Column | Rows outside 0 to 1 |
| --- | --- |
| pct_disability | 0 |
| pct_less_than_hs | 0 |
| pct_limited_english | 0 |
| pct_low_income | 0 |
| pct_low_life_expectancy | 0 |
| pct_over_64 | 0 |
| pct_people_of_color | 0 |
| pct_under_5 | 0 |
| pct_unemployed | 0 |

### Largest mismatches

| Column | GEOID | Area | Rebuilt | Reference | Absolute difference |
| --- | --- | --- | --- | --- | --- |
| DEMOGIDX_5 | 360810918001 | NY | 4.20316964205 | 5.26882000201 | 1.06565035996 |
| DEMOGIDX_5ST | 360810918001 | NY | 4.26194022325 | 5.2976212494 | 1.03568102615 |
| DEMOGIDX_5 | 400013769003 | OK | 3.68840469969 | 2.75791470035 | 0.93048999934 |
| DEMOGIDX_5 | 400013769001 | OK | 3.58764802525 | 2.65715802591 | 0.93048999934 |
| DEMOGIDX_5 | 400013769002 | OK | 3.64208914229 | 2.71159914295 | 0.93048999934 |
| DEMOGIDX_5ST | 060730099011 | CA | 4.19502183722 | 5.12364737789 | 0.928625540668 |
| DEMOGIDX_5 | 360276100001 | NY | 3.45966861037 | 4.38418180603 | 0.924513195654 |
| DEMOGIDX_5 | 260499801001 | MI | 1.30890879613 | 0.385545010846 | 0.923363785279 |
| DEMOGIDX_5ST | 060719801001 | CA | 5.48390935176 | 6.38951094592 | 0.905601594162 |
| DEMOGIDX_5ST | 550090016004 | WI | 4.88878325196 | 5.79226998194 | 0.903486729982 |
| DEMOGIDX_5 | 011010009002 | AL | 1.99496297001 | 1.10250729111 | 0.892455678893 |
| DEMOGIDX_5ST | 040134203041 | AZ | 1.57395559654 | 0.684543432553 | 0.889412163986 |
| DEMOGIDX_5 | 360810918000 | NY | 3.49698402879 | 4.38608798543 | 0.88910395664 |
| DEMOGIDX_5 | 011010009001 | AL | 2.0171534446 | 1.13024538435 | 0.886908060245 |
| DEMOGIDX_5ST | 260499801001 | MI | 1.10722069652 | 0.223065760548 | 0.884154935973 |
| DEMOGIDX_5ST | 400013769003 | OK | 3.35632813951 | 2.47228172626 | 0.884046413246 |
| DEMOGIDX_5ST | 400013769002 | OK | 3.23744245805 | 2.3533960448 | 0.884046413246 |
| DEMOGIDX_5ST | 400013769001 | OK | 3.21066931087 | 2.32662289763 | 0.884046413246 |
| DEMOGIDX_5ST | 360276100001 | NY | 3.4528122778 | 4.33422111404 | 0.881408836245 |
| DEMOGIDX_5ST | 511790102011 | VA | 5.34648954329 | 6.22250590088 | 0.876016357588 |

### Reading the largest gaps

DEMOGIDX_2: exact rate 0.009990, tolerance rate 1.000000, median absolute difference 1.31228361511e-13, maximum absolute difference 4.38316050122e-13. Where both values are present, the gap is double precision residue.
DEMOGIDX_2ST: exact rate 0.021631, tolerance rate 1.000000, median absolute difference 3.77475828373e-15, maximum absolute difference 9.01501095996e-14. Where both values are present, the gap is double precision residue.
DEMOGIDX_5: exact rate 0.000004, tolerance rate 0.000017, median absolute difference 0.000904734492, maximum absolute difference 0.907035216797. Pearson is 0.999555886941. The index is the average of the five adopted z-scores, or four where low life expectancy is missing, then the non-negative shift. The parent count was corrected and the score was kept. Before that correction the median absolute difference was 0.0255130803693 and Pearson was 0.998996597126, with 0 rows within 1e-8. On the 219958 rows whose life expectancy matches within 1e-8, the median absolute gap is 0.000919326984 and Pearson is 0.999999976104. The national shift is 1.64011566503. The reference shift, from the published factors, is 1.63925342141. 97.5 and the factor weights were not changed.
DEMOGIDX_5ST: exact rate 0.001936, tolerance rate 0.024185, median absolute difference 0.000684052443873, maximum absolute difference 0.880889303512. Pearson is 0.999500044995. Before the parent-count correction the median absolute difference was 0.00206558363478 and Pearson was 0.996105464877, with 3559 rows within 1e-8. On the rows whose life expectancy matches within 1e-8, 1523 state supplemental values are within 1e-8 and the median absolute gap is 0.000690271102. The state_fips_06 table and the largest-mismatch list above are the previous assignment.
DISABILITYPCT: exact rate 0.029839, tolerance rate 1.000000, median absolute difference 2.49800180541e-16, maximum absolute difference 5.55111512313e-16. Where both values are present, the gap is double precision residue.
LESSHSPCT: exact rate 0.129845, tolerance rate 1.000000, median absolute difference 2.22044604925e-16, maximum absolute difference 5.55111512313e-16. Where both values are present, the gap is double precision residue.
LIFEEXPPCT: exact rate 0.024669, tolerance rate 0.981049, median absolute difference 2.77555756156e-16, maximum absolute difference 0.181538461538. Null disagreements are 996. Pearson is 0.996506785671. Before the parent-count correction, 220243 of 224546 rows were within 1e-8 and null disagreements were 3733. The rate is 1 minus life expectancy divided by 97.5. 97.5 is the maximum in US_A.CSV and is not printed in the technical documentation. A 2022 tract with no direct 2010 id and one 2010 parent takes that parent's life expectancy. A 2022 tract with more than one 2010 parent takes the population-weighted average of the parent life expectancies. The weight is 2020 P.L. 94-171 block population from Census API dataset 2020/dec/pl, variable P1_001N, summed through the Census 2010 to 2020 block relationship file. A 2020 block that meets more than one 2010 tract is left out. The file's arealand_int column partitions those blocks, and allocating population by that column did not match the published rate, so it is not used. Connecticut 2022 tracts use the Missouri Census Data Center Geocorr 2022 crosswalk, weight column pop20. Rows whose implied maximum is not 97.5 stay in the comparison. 97.5 was not changed. Outside 1e-8, the rebuild is lower on 2086 rows and higher on 2217 rows. Median of reference minus rebuilt on those rows: -1.21357119325e-05.
LINGISOPCT: exact rate 0.581548, tolerance rate 1.000000, median absolute difference 0, maximum absolute difference 6.66133814775e-16. Where both values are present, the gap is double precision residue.
LOWINCPCT: exact rate 0.080289, tolerance rate 1.000000, median absolute difference 2.22044604925e-16, maximum absolute difference 6.66133814775e-16. Where both values are present, the gap is double precision residue.
OVER64PCT: exact rate 0.058984, tolerance rate 1.000000, median absolute difference 2.49800180541e-16, maximum absolute difference 5.55111512313e-16. Where both values are present, the gap is double precision residue.
PEOPCOLORPCT: exact rate 0.115823, tolerance rate 1.000000, median absolute difference 2.22044604925e-16, maximum absolute difference 6.66133814775e-16. Where both values are present, the gap is double precision residue.
UNDER5PCT: exact rate 0.142760, tolerance rate 1.000000, median absolute difference 2.08166817117e-16, maximum absolute difference 4.99600361081e-16. Where both values are present, the gap is double precision residue.
UNEMPPCT: exact rate 0.248438, tolerance rate 1.000000, median absolute difference 1.70002900646e-16, maximum absolute difference 5.55111512313e-16. Where both values are present, the gap is double precision residue. Null disagreements: 1 rows have an ACS denominator of 0 and a reference value of 0. Unemployment is null where the civilian labor force is 0 and the block group population is greater than 0. A zero labor force in a block group with population 0 stays 0. Other zero denominators stay 0.

### Low life expectancy

File `US_A.CSV` from the National Center for Health Statistics is loaded. Rows in the file: 67148. Life expectancy at birth ranges from 56.3 to 97.5. Block groups whose 2022 tract id matches a zero padded 2010 tract id: 170261 (55948 tracts). Published low life expectancy rows with no matching 2010 tract id: 54842.

On rows where both a life expectancy and a published low life expectancy between 0 and 1 are present, the implied maximum (life expectancy divided by 1 minus the published rate) has minimum 74.1790540541, 5th percentile 97.5, median 97.5, 95th percentile 97.5, maximum 115.818912237, and sample standard deviation 0.345974230235. Usable rows: 170084. Rows within 1e-6 of the file maximum life expectancy (97.5): 169236. Rows more than one year from that file maximum: 716.

97.5 is the file maximum and the center of the implied maximum. It is not printed in the technical documentation. It is used as the denominator because the rows whose implied maximum is within 1e-6 of 97.5 then match the published rate within 1e-8. Rows farther from 97.5 stay in the comparison and are the exceptions.

Block groups whose 2022 tract id is a 2010 tract id in the file: 170261. Block groups filled from a single 2010 parent in `tab20_tract20_tract10_natl.txt`: 36348. Block groups in a 2020 tract with more than one 2010 parent: 22019. Of those, 18663 have a life expectancy and 3356 stay null. The tract relationship file has land area only. The weight is 2020 block population from the Census 2010 to 2020 block relationship file, summed to each 2010 tract inside the 2020 tract. A block in more than one 2010 tract is left out. arealand_int sums to the 2020 land area on each of those blocks. Allocating block population by arealand_int was compared with the published rate and was not kept. The whole-block population weight is applied only where that tract has more than one 2010 parent and neither a direct 2010 id nor a single parent supplied a value.

Block relationship rows: 12689707. 2020 blocks with population: 8174955. Population total: 334735155.0. Blocks in one 2010 tract: 8115751, population 331089230.0. Blocks in more than one 2010 tract, left out of the weight: 59204, population 3645925.0. Multi-parent 2020 tracts: 28273. Tracts with a weighted life expectancy: 25181. Tracts left null: 3092.

Block groups whose 2022 tract id is not in the 2020 tract relationship: 2717. Connecticut block groups assigned: 2623. Connecticut block groups left unassigned: 94. Geocorr rows: 886. 2022 tracts in the crosswalk: 885. Tracts with a life expectancy: 842. Tracts without one: 43. The publisher is the Missouri Census Data Center. The file is geocorr2022_2629507182.csv, downloaded from https://mcdc.missouri.edu/temp/geocorr2022_2629507182.csv. The weight column is pop20, total population from the 2020 Census. The Census 2022 relationship page, https://www.census.gov/geographies/reference-files/2022/geo/relationship-files.html, and the file directory https://www2.census.gov/geo/docs/maps-data/data/rel2022/ list seven Connecticut files. None links a 2020 tract to a 2022 tract or a 2020 block to a 2022 block. NHGIS geographic crosswalks do not include a 2020 to 2022 pair. No county-name crosswalk is used. The 2010 to 2015 tract relationship table named in the technical documentation was searched again in the Census archive, the NCHS USALEEP documentation, and the Internet Archive. No Census or NCHS file was found. US_A.CSV is already keyed by 2010 tract ids, so that step is not applied again. The URLs are listed with the universe paragraph below.

Where the reference has a life expectancy and the rebuild is null: 723 block groups, of which 618 are multi-parent and 105 are single-parent. Where the rebuild has a life expectancy and the reference is null: 273 block groups, of which 173 are a direct 2010 tract id, 47 are multi-parent, 46 are single-parent, and 7 are Connecticut. CDC PLACES was not used.

Multi-parent block groups filled by the block population weight and compared with a published rate: 14345. Within 1e-8: 11378. Rows whose implied maximum is within 1e-6 of 97.5: 11378. Of those, 11378 are within 1e-8 and 0 are not.

Rows where rebuilt life expectancy is null and the reference has a value: 723. Rows whose life expectancy matches within 1e-8: 219958 of 224207, tolerance rate 0.981049. Null disagreements: 996. A single parent is one 2010 tract in the relationship file, and parents with no USALEEP row still count. On the 219958 matching life expectancy rows the national supplemental median absolute gap is 0.000919326984 and the state supplemental median absolute gap is 0.000690271102. The supplemental score from that parent count was kept.

The remaining universe difference was not closed. The 723 reference-only block groups are 618 multi-parent block groups in 229 tracts and 105 single-parent block groups in 55 tracts. On 195 of those multi-parent tracts a populated parent has no USALEEP value. On all 55 single-parent tracts the one 2010 parent is absent from `US_A.CSV`, and 21 of them are water tracts with land area 0. The 273 rebuilt-only block groups are 173 direct tract ids in 58 tracts, 47 multi-parent block groups in 22 tracts, 46 single-parent block groups in 18 tracts, and 7 Connecticut block groups in 3 tracts. The direct extras are parents of themselves in the 2010 to 2020 relationship, and their standard errors sit inside the range of the tracts that match, so there is no standard-error cutoff. Page 55 describes the 2015 to 2010 to 2020 to 2022 relationship chain and assignment to block groups. Page 35 uses four factors where life expectancy is missing. Neither page says to impute a parent that is absent from the file or to drop a direct USALEEP tract. The 2010 to 2015 relationship table was searched again and was not found. The p. 48 zero-population rule is for proximity, and 1120 zero-population block groups already match. No further life expectancy change was made. The national shift remains 1.64011566503 against the reference shift 1.63925342141. Low income, limited English, less than high school, and disability stay within 1e-8 on all 242336 rows.

No Census or NCHS 2010 to 2015 tract relationship file was found, so the supplemental index was not rescored. The national median absolute gap stays 0.000904734492. The four rates were not recomputed. 97.5, the factor weights, Superfund, hazardous waste, and the nearest-piece traffic score were left as they are.

Census relationship archive, checked 2026-10-27. `https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.html` HTTP 200, 337945 bytes. Year pages linked: 2000, 2010, 2020, 2022, 2023, 2024. No 2015 page. `https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.2010.html` HTTP 200, 2627399 bytes. Tract files compare Census 2000 with 2010. `https://www.census.gov/geographies/reference-files/time-series/geo/relationship-files.2020.html` HTTP 200, 2692125 bytes. Tract file compares 2020 with 2010. `https://www.census.gov/geographies/reference-files/2015/geo/relationship-files.html` HTTP 404, 0 bytes. `https://www2.census.gov/geo/docs/maps-data/data/` HTTP 200, 18059 bytes. Directories: `rel/`, `rel2020/`, `rel2022/`, `rel2024/`. No `rel2015/`. `https://www2.census.gov/geo/docs/maps-data/data/rel/` HTTP 200, 20886 bytes. Contents are 2000 to 2010 headers, `2010_Census_Tract_to_2010_PUMA.txt`, `centract_aia.txt`, `centract_military.txt`, and 2010 urban area and ZCTA files. `https://www2.census.gov/geo/docs/maps-data/data/rel2015/` HTTP 404, 0 bytes. `https://www2.census.gov/geo/docs/maps-data/data/rel/2015/` HTTP 404, 0 bytes. `https://www2.census.gov/geo/docs/maps-data/data/rel2010/` HTTP 404, 0 bytes. `https://www.census.gov/programs-surveys/acs/geography-acs/geography-boundaries-by-year/2015.html` HTTP 200, 308488 bytes. The 2015 ACS census tract vintage is the 2010 Census. `https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes/2015/geography-changes.html` HTTP 200, 332389 bytes. Two county renames only. Not a tract relationship table.

Internet Archive. Capture of `https://www.census.gov/geo/maps-data/data/relationship.html` at 2015-07-17 14:04:11 UTC, CDX status 200, recorded length 20172 bytes. The tract section is the 2000 to 2010 relationship. CDX returned no captures for `https://www.census.gov/geographies/reference-files/2015/geo/relationship-files.html`, for `https://www2.census.gov/geo/docs/maps-data/data/rel2015/`, for `www2.census.gov/geo/docs/maps-data/data/rel/*tract*2015*`, for `www.census.gov/geo/maps-data/data/rel/*2015*`, and for `www2.census.gov/geo/pdfs/*2015*tract*rel*`. An Internet Archive title search for census tract relationship 2010 2015 returned 0 items.

NCHS. Live `https://www.cdc.gov/nchs/nvss/usaleep/usaleep.html` returned HTTP 403 on 2026-10-27. Wayback capture 2018-09-22 12:20:13, CDX status 200, recorded length 13327 bytes, identity download 70166 bytes. It links the methodology, the record layout, and life expectancy files, not a relationship file. `https://www.cdc.gov/nchs/data/series/sr_02/sr02_181.pdf` returned HTTP 403. Wayback capture 2018-10-11 21:13:44, CDX status 200, length 7965790 bytes. Vital Health Stat 2(181), September 2018, uses 2010 census population and 2011 to 2015 ACS population. It does not name a 2010 to 2015 tract relationship table. `https://www.cdc.gov/nchs/data/nvss/usaleep/Record_Layout_CensusTract_Life_Expectancy.pdf` returned HTTP 403. Wayback capture 2020-07-15 14:07:43, CDX status 200, length 66894 bytes. File A and File B are life table layouts. `https://ftp.cdc.gov/pub/health_statistics/nchs/Datasets/NVSS/USALEEP/CSV/` HTTP 200, listing 13382 bytes. `US_A.CSV` dated 2023-08-29 17:34, 2594158 bytes. `US_B.CSV` same date, 62271386 bytes. `https://ftp.cdc.gov/pub/health_statistics/nchs/Datasets/NVSS/USALEEP/XLSX/` HTTP 200, listing 13455 bytes. Both directories are life tables. Wayback copies of `US_A.CSV` are the life expectancy file, including 2020-07-15 at 664926 bytes and 2023-12-25 at 625426 bytes.

`https://www.nhgis.org/geographic-crosswalks` HTTP 200 on 2026-10-27, 507172 bytes. The page describes 2015 county, tract, and block group changes in Alaska and South Dakota, and it says crosswalks cover only pairs of years from different decades. No link is a 2010 to 2015 tract file. The tract files that include 2015 are `nhgis_tr1990_tr2015.zip`, `nhgis_tr2000_tr2015.zip`, `nhgis_tr2015_tr2020.zip`, `nhgis_tr2015_tr2022.zip`, `nhgis_tr2020_tr2015.zip`, and `nhgis_tr2022_tr2015.zip` at `https://secure-assets.ipums.org/nhgis/crosswalks/`. `nhgis_tr2010_tr2015.zip` and `nhgis_tr2015_tr2010.zip` are not linked. Requests for those names, and for `nhgis_tr2010_tr2015_02.zip` and `nhgis_tr2010_tr2015_46.zip`, redirected to an IPUMS login on 2026-10-27 with content-length 0. The 2010 to 2015 tract crosswalk is a description, not a downloadable file. It was not applied. The supplemental index was not rescored. The national median absolute gap stays 0.000904734492. Low income, limited English, less than high school, and disability were not recomputed.

## Tier 3, lead paint, Superfund proximity, hazardous waste proximity, and traffic proximity

Thresholds are fixed in `sql/validation/tier3_metrics.sql` and are the same bars as Tier 1 and Tier 2. Continuous tolerance is an absolute difference of at most 1e-8 on at least 99 percent of rows where both values are present. Exact equality uses the same 99 percent bar. Null agreement passes at 99.9 percent. A low match rate is reported. The distance unit and the cap were not changed after the comparison.

Traffic proximity uses the 2020 HPMS file geodatabase. The annual average daily traffic field is AADT. Distance is kilometers, from the inverse-distance equation on p. 48 and the traffic steps on pp. 50 to 51. Page 21 says AADT divided by distance in meters. That sentence was not used. The maximum score of 10 applies to distances under 0.1 km, and that capped inverse distance is then multiplied by AADT. The roads are interstates, other freeways and expressways, other principal arterials, and minor arterials in urban areas. Within each state, segments that share Route_ID and AADT contribute once, through the minimum distance to the group.

Tier 3 column checks passed: 0. Tier 3 column checks failed: 4.

### Geographic ids

Every rebuilt block group id is in the national reference universe, and every national reference id is in each rebuilt table.

### Column comparison

| Column | Rows | Both present | Exact rate | Tolerance rate | Null agreement | Pearson | Spearman | Median absolute gap | P95 | Max | Exact | Tolerance | Null |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PNPL | 242336 | 240939 | 0.558390 | 0.567679 | 0.999983 | 0.938579900173 | 0.982043573588 | 0 | 0.0992889619025 | 21.8139227866 | fail | fail | pass |
| PRE1960PCT | 242336 | 242336 | 0.216716 | 1.000000 | 1.000000 | 1 | 1 | 2.22044604925e-16 | 4.51028103754e-16 | 6.66133814775e-16 | fail | pass | pass |
| PTRAF | 242336 | 240939 | 0.013991 | 0.013991 | 0.999983 | 0.997413381066 | 0.997049004941 | 49054.4751185 | 504825.3465 | 4114549.93252 | fail | fail | pass |
| PTSDF | 242336 | 240939 | 0.147319 | 0.147319 | 0.999983 | 0.93541854321 | 0.930271367698 | 0.436139051761 | 7.68801929299 | 38.8502002961 | fail | fail | pass |

State slice for the configured state FIPS:

| Column | Rows | Tolerance rate | Median absolute gap | Max | Tolerance |
| --- | --- | --- | --- | --- | --- |
| PNPL | 25607 | 0.462809 | 3.98184716865e-08 | 21.8139227866 | fail |
| PRE1960PCT | 25607 | 1.000000 | 2.22044604925e-16 | 5.55111512313e-16 | pass |
| PTRAF | 25607 | 0.005400 | 292398.100261 | 3178721.91329 | fail |
| PTSDF | 25607 | 0.017569 | 5.02467650113 | 34.4947221453 | fail |

### Difference distribution

| Column | Min | P25 | Median | P75 | P95 | Max | Mean |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PNPL | 0 | 0 | 0 | 0.000419696699048 | 0.0992889619025 | 21.8139227866 | 0.0378201303931 |
| PRE1960PCT | 0 | 5.55111512313e-17 | 2.22044604925e-16 | 3.33066907388e-16 | 4.51028103754e-16 | 6.66133814775e-16 | 2.07303018443e-16 |
| PTRAF | 0 | 13093.17156 | 49054.4751185 | 123118.510827 | 504825.3465 | 4114549.93252 | 119015.034278 |
| PTSDF | 0 | 0.074482137625 | 0.436139051761 | 1.65391865555 | 7.68801929299 | 38.8502002961 | 1.60524299616 |

### Twenty largest mismatches in each column

| Column | GEOID | State | Rebuilt | Reference | Absolute gap |
| --- | --- | --- | --- | --- | --- |
| PNPL | 060371233011 | CA | 11.1860772134 | 33 | 21.8139227866 |
| PNPL | 060371224101 | CA | 11.199127836 | 33 | 21.800872164 |
| PNPL | 060371224102 | CA | 11.2095426053 | 33 | 21.7904573947 |
| PNPL | 060371232041 | CA | 11.2264110189 | 33 | 21.7735889811 |
| PNPL | 060371224203 | CA | 11.2314986712 | 33 | 21.7685013288 |
| PNPL | 060371232031 | CA | 11.2363602803 | 33 | 21.7636397197 |
| PNPL | 060371232032 | CA | 11.251181714 | 33 | 21.748818286 |
| PNPL | 060371232033 | CA | 11.2640283667 | 33 | 21.7359716333 |
| PNPL | 060371232052 | CA | 11.2871230609 | 33 | 21.7128769391 |
| PNPL | 060371232051 | CA | 11.3108084022 | 33 | 21.6891915978 |
| PNPL | 060371232061 | CA | 11.3614853301 | 33 | 21.6385146699 |
| PNPL | 060371219001 | CA | 11.2055785036 | 32.8266666667 | 21.6210881631 |
| PNPL | 060371242013 | CA | 11.3989927874 | 33 | 21.6010072126 |
| PNPL | 060371232042 | CA | 11.2374688983 | 32.8235294118 | 21.5860605135 |
| PNPL | 060371231032 | CA | 11.4335215566 | 33 | 21.5664784434 |
| PNPL | 060371231031 | CA | 11.4884381278 | 33 | 21.5115618722 |
| PNPL | 060371241031 | CA | 11.3269146148 | 32.8352180937 | 21.5083034789 |
| PNPL | 060373016023 | CA | 11.4979388849 | 33 | 21.5020611151 |
| PNPL | 060371219002 | CA | 11.1115909234 | 32.5884908895 | 21.4768999661 |
| PNPL | 060373016021 | CA | 11.5261083279 | 33 | 21.4738916721 |
| PRE1960PCT | 340350503001 | NJ | 0.647668393782 | 0.647668393782 | 6.66133814775e-16 |
| PRE1960PCT | 391535088004 | OH | 0.944170771757 | 0.944170771757 | 6.66133814775e-16 |
| PRE1960PCT | 010730051031 | AL | 0.818518518519 | 0.818518518519 | 5.55111512313e-16 |
| PRE1960PCT | 010830206002 | AL | 0.434444444444 | 0.434444444444 | 5.55111512313e-16 |
| PRE1960PCT | 010970077002 | AL | 0.74449339207 | 0.74449339207 | 5.55111512313e-16 |
| PRE1960PCT | 040131089013 | AZ | 0.687804878049 | 0.687804878049 | 5.55111512313e-16 |
| PRE1960PCT | 040131171002 | AZ | 0.491987179487 | 0.491987179487 | 5.55111512313e-16 |
| PRE1960PCT | 050450309002 | AR | 0.320866141732 | 0.320866141732 | 5.55111512313e-16 |
| PRE1960PCT | 050510115003 | AR | 0.677339901478 | 0.677339901478 | 5.55111512313e-16 |
| PRE1960PCT | 051399507003 | AR | 0.406698564593 | 0.406698564593 | 5.55111512313e-16 |
| PRE1960PCT | 060014018001 | CA | 0.771428571429 | 0.771428571429 | 5.55111512313e-16 |
| PRE1960PCT | 060014078001 | CA | 0.690594059406 | 0.690594059406 | 5.55111512313e-16 |
| PRE1960PCT | 060014087005 | CA | 0.674157303371 | 0.674157303371 | 5.55111512313e-16 |
| PRE1960PCT | 060014102002 | CA | 0.858638743455 | 0.858638743455 | 5.55111512313e-16 |
| PRE1960PCT | 060014103001 | CA | 0.643916913947 | 0.643916913947 | 5.55111512313e-16 |
| PRE1960PCT | 060014239022 | CA | 0.728571428571 | 0.728571428571 | 5.55111512313e-16 |
| PRE1960PCT | 060014321003 | CA | 0.979069767442 | 0.979069767442 | 5.55111512313e-16 |
| PRE1960PCT | 060014373001 | CA | 0.690647482014 | 0.690647482014 | 5.55111512313e-16 |
| PRE1960PCT | 060014515034 | CA | 0.866449511401 | 0.866449511401 | 5.55111512313e-16 |
| PRE1960PCT | 060070011003 | CA | 0.489148580968 | 0.489148580968 | 5.55111512313e-16 |
| PTRAF | 150030052002 | HI | 3439905.63065 | 7554455.56317 | 4114549.93252 |
| PTRAF | 150030051001 | HI | 3717709.53895 | 7777618.52094 | 4059908.98199 |
| PTRAF | 150030050003 | HI | 2917370.85055 | 6838870.29131 | 3921499.44076 |
| PTRAF | 150030051002 | HI | 3874692.08965 | 7591477.09786 | 3716785.00822 |
| PTRAF | 150030050004 | HI | 4168833.96665 | 7847467.87088 | 3678633.90423 |
| PTRAF | 150030040002 | HI | 3496115.01294 | 7171888.19131 | 3675773.17837 |
| PTRAF | 150030042011 | HI | 3971550.41865 | 7637618.96023 | 3666068.54158 |
| PTRAF | 150030042012 | HI | 4145054.68536 | 7729824.38884 | 3584769.70348 |
| PTRAF | 150030053002 | HI | 4765150.76375 | 8344013.83735 | 3578863.0736 |
| PTRAF | 150030049001 | HI | 2654920.61022 | 6170081.7581 | 3515161.14788 |
| PTRAF | 150030052001 | HI | 3365488.11131 | 6814433.44367 | 3448945.33237 |
| PTRAF | 150030049002 | HI | 3945595.15413 | 7388947.78394 | 3443352.62981 |
| PTRAF | 150030053001 | HI | 3736855.54717 | 7148233.12341 | 3411377.57624 |
| PTRAF | 150030040001 | HI | 3596364.1996 | 7005200.39775 | 3408836.19815 |
| PTRAF | 150030042021 | HI | 4273609.16866 | 7657013.42622 | 3383404.25756 |
| PTRAF | 150030024013 | HI | 2646369.92151 | 5982983.03001 | 3336613.10851 |
| PTRAF | 150030050002 | HI | 4054186.90557 | 7359358.1721 | 3305171.26653 |
| PTRAF | 150030041023 | HI | 4437995.08531 | 7681060.44377 | 3243065.35847 |
| PTRAF | 150030021011 | HI | 2090921.00698 | 5333887.18747 | 3242966.18049 |
| PTRAF | 150030049003 | HI | 2920031.28024 | 6148379.13014 | 3228347.8499 |
| PTSDF | 250250202001 | MA | 33.1614517049 | 72.0116520009 | 38.8502002961 |
| PTSDF | 250173546011 | MA | 13.1118400449 | 50.5959628684 | 37.4841228235 |
| PTSDF | 250250701043 | MA | 27.1828744685 | 64.2671695578 | 37.0842950893 |
| PTSDF | 250250703011 | MA | 27.1146840825 | 63.6379235056 | 36.5232394231 |
| PTSDF | 250173531012 | MA | 44.7126845257 | 80.837672632 | 36.1249881063 |
| PTSDF | 250250203021 | MA | 33.0063288196 | 69.0808177706 | 36.074488951 |
| PTSDF | 250250701023 | MA | 31.9477305763 | 67.7507347562 | 35.8030041799 |
| PTSDF | 110010108001 | DC | 17.854111526 | 53.2857708604 | 35.4316593344 |
| PTSDF | 250250203042 | MA | 25.8912841817 | 61.2851722837 | 35.393888102 |
| PTSDF | 250250102061 | MA | 31.2647396813 | 66.6447902936 | 35.3800506124 |
| PTSDF | 250250702021 | MA | 31.343304944 | 66.6150443208 | 35.2717393768 |
| PTSDF | 250250107021 | MA | 27.8513076804 | 63.08296677 | 35.2316590896 |
| PTSDF | 250250701021 | MA | 26.9267701681 | 62.08027278 | 35.1535026119 |
| PTSDF | 250173523002 | MA | 40.5577165389 | 75.607418821 | 35.0497022821 |
| PTSDF | 250250107012 | MA | 28.1448697395 | 63.0273139163 | 34.8824441767 |
| PTSDF | 360010011001 | NY | 9.49229560575 | 44.3246130032 | 34.8323173974 |
| PTSDF | 250250107011 | MA | 28.0846583526 | 62.8490926778 | 34.7644343252 |
| PTSDF | 250173530002 | MA | 34.4764156062 | 69.2001262237 | 34.7237106175 |
| PTSDF | 250250711012 | MA | 31.5666450822 | 66.2184728275 | 34.6518277453 |
| PTSDF | 250250106003 | MA | 27.4306029616 | 61.9520755693 | 34.5214726077 |

### Hypothesis for each mismatch cluster

Lead paint zero denominators: 2698. Stored as 0: 2698. Null denominators: 0.
Superfund sites scored: boundary 1413, point_buffer_1m 28.
Hazardous waste sites scored: 10645. Operating TSDFs: 633. 2021 large quantity generators: 10530. Counted in both: 518.

PNPL. Superfund uses kilometers and a cap of 11 inside 0.1 km, from the inverse-distance equation on p. 48 and the Superfund steps on pp. 49 to 50. The current public boundary service is not the February 26, 2024 extract. Final and proposed polygons are included, plus Superfund Alternative Approach boundaries matched to the EPA enforcement list, plus final and proposed points that have no polygon, buffered by 1 meter. The block group score is the population-weighted average of block scores. The unit and the cap were not flipped to chase the reference.
Cluster both_zero: 134342 rows. State-weighted median absolute gap 0.
Cluster rebuilt_lower: 71663 rows. State-weighted median absolute gap 0.00716330629955.
Cluster rebuilt_higher: 31249 rows. State-weighted median absolute gap 0.0045280661077.
Cluster rebuilt_zero_reference_positive: 2581 rows. State-weighted median absolute gap 0.0889922121554.
Cluster reference_zero_rebuilt_positive: 908 rows. State-weighted median absolute gap 0.152999325655.
Cluster other: 196 rows. State-weighted median absolute gap 0.
Hypothesis: the kilometer score with cap 11 is the same scale as the reference. On rows where both values are positive, the median ratio of rebuilt to reference is about 1. The tolerance misses are small boundary differences plus universe differences, not a meters-versus-kilometers switch. Rows where the reference is 0 and the rebuild is positive are sites in the current file that were outside the February 26, 2024 universe. Rows where the rebuild is 0 and the reference is positive are sites from that vintage that are not in the current public boundaries, including SAA names with no polygon. The largest gaps are California block groups whose reference is 33, three times the cap, and whose rebuild is about 11, one site inside 0.1 km. Four Connecticut block groups are null here and filled in the reference: three are the split 2020 tract 09009343101, which was not assigned, and one is a zero-population tract the reference stores as 0. The cap stays 11 and the unit stays kilometers.

May 20, 2024 boundary test, not adopted. The February 26, 2024 boundary extract was not found. The closest dated public copy is the Internet Archive capture of EPA EDG `NPL_Boundaries.zip` at 2024-05-20 12:44:37 UTC, HTTP 200, 11,601,789 bytes. The previous capture is 2023-10-10. The latest last-change date in the file is 2024-05-16, and 287 dated final or proposed site boundaries changed after 2024-02-26. Scored features are site feature class 5 with status F or P: 1542 features, 1340 EPA IDs, dissolved by EPA ID. Kilometers, the cap of 11 inside 0.1 km, the 10 km radius, and the block population weights were unchanged. The February 26 SEMS point file and the February 2024 SAA name list are not in the archive and were not filled in from later pages. This comparison is from SQL on the same 240939 rows where both values are present. Within 1e-8: 137598 rows, tolerance rate 0.571091. Median absolute gap 0. Pearson 0.929886719342, down from 0.938579900173. Positive-row median ratio 0.999993473666 on 97386 rows, against the current score's ratio of about 1. Four rebuilt nulls remain. Pearson fell, so the current public boundary score remains. The PNPL figures above are that current score.

PRE1960PCT. Lead paint is (B25034_009E + B25034_010E + B25034_011E) / B25034_001E from ACS 2022 5-year table B25034. The reference stores the ratio, which is the printed percent divided by 100. A zero housing-unit total is stored as 0, the same rule as the demographic rates that matched. A null total stays null.
Cluster rebuilt_higher: 95233 rows. State-weighted median absolute gap 2.64514955622e-16.
Cluster rebuilt_lower: 94585 rows. State-weighted median absolute gap 2.6965319984e-16.
Cluster both_zero: 37082 rows. State-weighted median absolute gap 0.
Cluster other: 15436 rows. State-weighted median absolute gap 0.
Hypothesis: exact equality fails on double precision residue. The zero-denominator rows agree with the reference value 0, so no separate null rule was added.

PTRAF. Traffic uses kilometers and a cap of 10 on the inverse distance inside 0.1 km, then multiplies by AADT, from pp. 48 and 50 to 51. Page 21's meters sentence was not used. The road classes are HPMS functional systems 1, 2, and 3, plus system 4 when the urban code is not 99999. The block group score is the population-weighted average of block scores. The minimum distance within a state, Route_ID, and AADT group is the dissolve. The unit and the cap were not flipped to chase the reference. An overlap-only dissolve was tested and not adopted. That test is reported with the PTRAF hypothesis below. The column figures in this section are the minimum-distance score.
Cluster rebuilt_lower: 233361 rows. State-weighted median absolute gap 86695.8106796.
Cluster both_zero: 3371 rows. State-weighted median absolute gap 0.
Cluster rebuilt_higher: 3168 rows. State-weighted median absolute gap 795.0140848.
Cluster rebuilt_zero_reference_positive: 1039 rows. State-weighted median absolute gap 4342.77627534.
Hypothesis: the kilometer score, with the cap of 10 applied before multiplying by AADT, is the same scale as the reference. Pearson is about 0.997 and the median ratio on positive rows is about 0.932. The tolerance misses are not a meters-versus-kilometers switch. Page 21's meters sentence was not used. The only rows within 1e-8 are shared zeros. Most other rows are a little lower here. The largest gaps are Hawaii, where the median ratio is about 0.43 in Honolulu and about 0.30 on the other islands. A block there can sit within 10 km of many segments of one route, so one distance per Route_ID and AADT is lower than a score that still adds those segments. 1039 rows are 0 here and positive in the reference. They are spread across states, with the most in Alabama, Arizona, and Minnesota. Four Connecticut block groups are null here and filled in the reference: three are the split 2020 tract 09009343101, which was not assigned, and one is a zero-population tract the reference stores as 0. The cap stays 10 on the inverse distance and the unit stays kilometers.

Overlap dissolve test, not adopted: segments that share Route_ID and AADT were dissolved only when their intersection has positive length, and pieces that do not overlap each contributed. This comparison is from SQL on the same 240939 rows. The positive-row median ratio moved from 0.932053855 to 5.337095747, farther from 1. Pearson moved from 0.997413381066 to 0.876356573302. The tolerance rate stayed 0.013991. Honolulu's positive-row median ratio moved from 0.430 to 11.373 on 767 rows, and the other Hawaii islands moved from 0.298 to 12.079 on 250 rows. The minimum-distance score remains.

PTSDF. Hazardous waste uses the same inverse-distance method: kilometers, cap 10 inside 0.1 km, radius 10 km, population-weighted from block centroids. Operating TSDFs are the current RCRAInfo handler universe, not the February 5, 2024 pull. Large quantity generators are handlers whose 2021 Biennial Report calculated generator status is L. A handler that is both is one point. Locations come from the current handler file.
Cluster rebuilt_lower: 170148 rows. State-weighted median absolute gap 1.69229592167.
Cluster both_zero: 35495 rows. State-weighted median absolute gap 0.
Cluster rebuilt_higher: 18099 rows. State-weighted median absolute gap 0.093787178191.
Cluster rebuilt_zero_reference_positive: 15372 rows. State-weighted median absolute gap 0.282714348147.
Cluster reference_zero_rebuilt_positive: 1825 rows. State-weighted median absolute gap 0.136421587294.
Hypothesis: the scores are the same order of magnitude as the reference, so the unit is kilometers and the cap of 10 is on the inverse distance, not a meters formula. On rows where both values are positive, the median ratio of rebuilt to reference is about 0.6, and no both-positive row is within 1e-8. The rebuild is the October 18, 2026 RCRAInfo handler file for operating TSDF status and coordinates, joined to 2021 Biennial Report calculated generator status L. The technical documentation pull was February 5, 2024. Thousands of block groups are 0 here and positive in the reference, which is facilities present in that pull and absent from this public pair. The largest gaps are Massachusetts and the District of Columbia, in the same direction as the national ratio. The cap stays 10 and the unit stays kilometers.

February 5, 2024 hazardous waste file, not found. The score was not rebuilt. The public export API serves only the current run. Historical S3 keys for the nights around February 5, 2024 return the same AccessDenied response as a missing key. Export history routes return 404. The Internet Archive has no capture of that zip or of the downloads page between January and March 2024, and no ECHO RCRA download or EDG RCRA path in the first half of 2024. The PTSDF figures above stay the October 18, 2026 export. Pearson on that score is 0.93541854321 and the positive-row median ratio is about 0.6, on 240939 rows where both values are present.

October 25, 2026 handler file, not adopted. Google Drive file id `1bUbZoLshAZaAHBd7TmDeYs4mbVLJItB6` is `HD_REPORTING.zip`, 169593899 bytes. The members are dated 2026-10-25 03:12 and 2026-10-25 03:13, and the byte size matches public run `CSV-2026-10-25T03-00-00-0400`. The zip has 1632825 handler rows and no `BR_REPORTING`, so it is not the February 5, 2024 pair. Large quantity generators are the same run's `BR_REPORTING_2021.zip`, 42796899 bytes, 1829587 rows, 10573 handler ids with calculated generator status L. Scored facilities: 10645, of which 633 are operating TSDFs, 10530 are large quantity generators, and 518 are both. The comparison is SQL on 240939 rows where both values are present, with 188246 both positive. Pearson is 0.935419671679. The positive-row median ratio is 0.596409641319. Pearson does not fall below 0.93541854321. The ratio does not move closer to 1 than about 0.6, so the score was not kept. The PTSDF figures above stay the October 18, 2026 export.

Google Drive file id `1WNmjn3qCjZOlz9aKrSqM5Sx2wDrziZTw` is `HD.zip`, 634605351 bytes, dated 2026-10-25 inside the archive. It is the handler module: 38 members, `HD_REPORTING` with 1632825 records, and no `BR_REPORTING_2021`. The nested handler summary is the same 169593899 byte file already compared above. It is not the February 5, 2024 export. No score was changed. The PTSDF figures stay the October 18, 2026 export.

Google Drive file id `1q6fOfazYAhX6O16F6RuZ2X7KTbNbk0Ig` is `BR_REPORTING_2021.zip`, 42796899 bytes. The members are dated 2026-10-25 03:25 and 03:26 and are 460739498 and 384681843 bytes. It is the same October 25, 2026 biennial-report file already used in the comparison above, 1829587 rows and 10573 handler ids with calculated generator status L. There is no `HD_REPORTING`. It is not the February 5, 2024 export. No score was changed. The PTSDF figures stay the October 18, 2026 export. The February 5, 2024 RCRAInfo export is still required for that indicator.

PWDIS. Wastewater discharge was rebuilt from the public December 27, 2023 flowline file and the score was kept. The version 2.3 technical documentation names a February 2024 OPPT and Office of Water delivery of 2021 RSEI toxicity-weighted concentrations on NHD flowlines. The scored file is that polyline product, and its date is December 27, 2023. It is not the February 2024 delivery. The method is inverse distance within 10 kilometers, cap 10 inside 0.1 kilometers, then multiplied by `TOXCONC`, then the population-weighted average of block scores. The page 15 summary says stream segments within 500 meters. That radius was not used. The unit and the cap were not retuned.

The file is `https://gaftp.epa.gov/rsei/temp/EJS/v2311_water/EJScreen2021.gdb.zip`, HTTP 200 on 2026-10-28, content-length 43741896, last-modified 2023-12-27 18:40:14 GMT. Zip members are dated 2023-01-30 and 2023-12-27. Layer `EJScreen2021` is a multiline, 250985 features, one row per `COMID`, fields `COMID`, `REACHECODE`, and `TOXCONC`. The northern extent is latitude 49.364066, so Alaska is outside the file. Alaska block groups are null. All 504 are null here and in the reference. This comparison is SQL on 242336 rows. Both present: 240435. Both null: 1897. Rebuilt null where the reference has a value: 4, the Connecticut ids `091403431011`, `091403431012`, `091403431013`, and `091909900000`. Reference null where the rebuild has a value: 0. Rows within 1e-8: 19054, tolerance rate 0.079248. Both positive: 220585. Positive-row median ratio 0.956633944441. Pearson 0.999203979821. Spearman 0.983752530337. Median absolute gap 1.35989269957. The ratio is closer to 1 than a meters-versus-kilometers scale, and Pearson is reported, so the score was kept. It does not meet the 99 percent tolerance bar. Superfund, traffic, life expectancy, 97.5, the factor weights, and the October 18, 2026 hazardous-waste score were left unchanged.

No February 2024 public copy was found. `EJScreen2024.gdb.zip` and `v2312_water/` returned HTTP 404. Version 2.3.11 on `https://gaftp.epa.gov/rsei/Older_Versions/Version2311_RY2021/` is air grid-cell data dated 2023-03-16. Current `V2312_RY2022` is reporting year 2022, public-release zip dated 2024-03-21. The annual water shapefile names in the August 2024 RSEI geographic-microdata documentation, `NHDMicroResults_Onsite_2021.zip` and `NHDMicroResults_Offsite_2021.zip`, are absent from those trees: the on-site 2021 name returned HTTP 404 at the four paths checked. `https://edg.epa.gov/data/public/OPPT/` returned HTTP 404, and `https://edg.epa.gov/data/public/OCSPP/OPPT/` lists CDR, metadata, and TSCA. `RSEI.json` there is 4822 bytes with coverage through 2014. `https://gaftp.epa.gov/EJScreen/` returned HTTP 404. A data.gov catalog search for EJScreen returned three datasets, none a wastewater flowline geodatabase. Internet Archive CDX for `gaftp.epa.gov/rsei/temp/EJS/` from 2024-01-01 through 2024-03-15 returned no captures. The earliest `v2311_water` capture is 2024-09-28, and the earliest `EJScreen2021.gdb.zip` capture is 2024-10-04, recorded length 43746276. Older `v238` water zips are dated 2021-01-22 (663633470 bytes) and 2021-05-01 (646748009 bytes). None of those files was scored. The PWDIS figures in this section are the December 27, 2023 score.

RSEI_AIR. Toxic releases to air was rebuilt from the May 16, 2023 OPPT polygon delivery and the score was kept. The version 2.3 technical documentation names that date for average annual toxicity-weighted air concentrations already aggregated from 2021 RSEI grid cells to block groups and island areas. The March 16, 2023 version 2.3.11 aggregated grid is not that polygon and was not scored for this indicator. PM 2.5 remains an Office of Air Quality Planning and Standards spreadsheet that was not found. Ozone uses the OAQPS tract CSV. Diesel particulate matter uses the AirToxScreen 2020 AMBCONC pollutant-summary zips.

The file is `https://gaftp.epa.gov/rsei/temp/EJS/v2311_air/EJ_Census2020_BG_Air_Indicator_GIS_File.zip`, HTTP 200 on 2026-10-28, content-length 949977650, last-modified 2023-05-16 17:29:36 GMT. Zip members are dated 2023-05-12. Layer `EJ_Census2020_BG_Air_Indicator` is a multipolygon, 242747 features, fields `BGID` and `TOXCONC`. The toxicity field is `TOXCONC`. The score assigns that value to each Harvard row whose 12-digit id equals `BGID`. No distance formula was applied. This comparison is SQL on 243022 Harvard rows. Both present: 238981. Both null: 692. Rebuilt null where the reference has a value: 2711, all Connecticut, where the May 16 file still uses 2020 county codes and the extract uses 2022 planning-region codes. No 2020 to 2022 remapping was invented. Reference null where the rebuild has a value: 638. Rows within 1e-8: 75511, tolerance rate 0.3159707257062277. Both positive: 236965. Positive-row median ratio 1. Pearson 1.0000000000000002. Spearman 0.9999999982141216. Median absolute gap 3.00000237984932e-08. The positive-row median ratio is at 1 and Pearson is reported, so the score was kept. It does not meet the 99 percent tolerance bar. Sibling `EJ2023_AS_GU_CNMI_VI_2021_ToxConc.gdb.zip` dated 2023-06-13 was not mixed in. Wastewater remains the December 27, 2023 score. Superfund, traffic, hazardous waste, life expectancy, 97.5, and the factor weights were left unchanged.

PRMP. RMP facility proximity was rebuilt from the current public FRS RMP interest layer and the score was not kept. The version 2.3 technical documentation selects active RMP facilities from Facility Registry Service on February 5, 2024, then uses inverse distance within 10 kilometers, cap 10 inside 0.1 kilometers, and the population-weighted average of block scores. That February 5 extract was not found. The unit and the cap were not retuned.

The file is `https://services.arcgis.com/cJ9YHowT8TU7DUyn/arcgis/rest/services/FRS_INTERESTS_RMP/FeatureServer/0`, downloaded 2026-10-28. Layer `dataLastEditDate` 2026-10-26 00:57:17 UTC. Features: 21855. Active: 21836. Blank status: 19. Scored after one point per `REGISTRY_ID` and dropping island territories: 21543. Block centroids are the same TIGER/Line 2020 geometric centroids and 2020 block populations used for Superfund and hazardous waste. This comparison is SQL on 242336 national rows. Both present: 240939. Both null: 1393. Rebuilt null where the reference has a value: 4. Reference null where the rebuild has a value: 0. Rows within 1e-8: 28797, tolerance rate 0.11951987847546475. Both positive: 171446. Positive-row median ratio 2.0939259982049303. Pearson 0.8337008027964584. Spearman 0.7898967031069142. Median absolute gap 0.456710985262113. The median ratio is not near 1, so the score was not kept.

Scale diagnosis on 2026-10-29 (km and cap unchanged). Multiple PGM rows: 21855 unique `PGM_SYS_ID`, only 266 registries with more than one interest row; scoring already used one point per `REGISTRY_ID`. Co-located points: 70 shared coordinates to five decimals after that collapse (71 extras). Active definition: EPA March 2024 states 11740 regulated RMP facilities; FRS scored 21543 (ratio ≈ 1.835, same order as median ratio 2.09). FRS `LAST_REPORTED_DATE` / `UPDATE_DATE` are null on every interest row, so `ACTIVE_STATUS` does not implement the documented not-deregistered filter. No public active-only bulk list was found. The RMP proximity score remains not kept.

PM25. Particulate matter 2.5 was rebuilt from the public FAQSD 2020 daily fused tract file as the documented annual average, and the score was kept. The version 2.3 technical documentation names a 2020 OAQPS tract spreadsheet (monitor and CMAQ fusion, EPA-454/S-15-001), annual average in µg/m³, copied to child block groups and remapped from 2020 to 2022. `EJscreen.pm25_2020.csv` remains HTTP 404. Named FAQSD annual paths still return `FAILED` (7 bytes). The annual mean of the public daily fused file is the documented OAQPS product form (`AnnualMeanPM25` in the prior-year sibling). No weight or unit was retuned.

The file is `https://ofmpub.epa.gov/rsig/rsigserver?data/FAQSD/outputs/2020_pm25_daily_average.txt.gz`, HTTP 200 on 2026-10-29, content-length 532375506, gzip member dated 2023-08-16 00:01:13 UTC. SHA256 `d90572344dabea13a787c6544e7271a1b07ff0513a9776064aeeb5bded5059f3`. Daily rows: 30662016. Tracts: 83776, each with 366 days. Annual mean per tract from `pm25_daily_average(ug/m3)`. Tract range 3.2885737704918037 to 25.61210655737705. Assignment: tract to child block groups; Connecticut Geocorr 2022. This comparison is on 243022 Harvard rows. Both present: 238193. Both null: 4828. Rebuilt null where the reference has a value: 1. Reference null where the rebuild has a value: 0. Both positive: 238193. Positive-row median ratio 1. Pearson 0.9999999999725282. Spearman 0.9999999994301453. Tolerance rate 0.0063435953197617054. Median absolute gap about 1.04e-5. The positive-row median ratio is at 1 and Pearson is reported, so the score was kept. Prior-year `EJscreen.pm25.csv` (72283 tracts) had positive-row median ratio 1.060360180018207 and Pearson 0.852169816311898 and was not kept. Hazardous waste stays pinned. Drinking water stays unscored. RMP stays not kept. Wastewater, Superfund, traffic, RSEI_AIR, ozone, diesel, NO2, UST, life expectancy, 97.5, and the factor weights were left unchanged.

OZONE. Ozone was rebuilt from the public 2020 OAQPS tract file and the score was kept. The version 2.3 technical documentation defines the indicator as the annual mean of the 10 highest daily maximum 8-hour ozone concentrations, from the OAQPS monitor and CMAQ fusion, copied to child block groups and remapped from 2020 to 2022. The field is `O3Top10Mean`. `SummerMeanO3` in the same file is the pre-patch summer average and was not kept.

The file is `https://gaftp.epa.gov/Air/aqmg/RH_DataRequest/EJscreen.ozone_2020.csv`, HTTP 200 on 2026-10-28, content-length 3146380, last-modified 2023-11-06 17:50:53 GMT. Tract rows: 83776. `O3Top10Mean` range 38.77842 to 112.81276. No Alaska, Hawaii, or Puerto Rico tracts. Assignment: left-pad `FIPs` to 11 digits, copy to each child block group, and remap Connecticut with Geocorr 2022 (single 2020 parent copy, or `pop20` weight when more than one parent has positive population). This comparison is on 243022 Harvard rows. Both present: 238193. Both null: 4828. Rebuilt null where the reference has a value: 1 (`091309901000`, two 2020 parents with `pop20` 0). Reference null where the rebuild has a value: 0. Rows within 1e-8: 238193, tolerance rate 1. Both positive: 238193. Positive-row median ratio 1. Pearson 1.0000000000000002. Median absolute gap 0. The positive-row median ratio is at 1 and Pearson is reported, so the score was kept. `SummerMeanO3` on the same join had positive-row median ratio about 0.668 and Pearson about 0.845 and was not kept. No weight or unit was retuned. PM 2.5 stays unscored. Wastewater, Superfund, traffic, hazardous waste, RSEI_AIR, RMP, life expectancy, 97.5, and the factor weights were left unchanged.

DSLPM. Diesel particulate matter was rebuilt from the public 2020 AirToxScreen diesel ambient concentration pollutant-summary zips and the score was kept. The version 2.3 technical documentation names a March 2024 OAQPS spreadsheet of 2020 AirToxScreen diesel PM in µg/m³. Page 14 calls the source block-group level. Page 19 says tract values are repeated for each block group. No OAQPS `EJscreen.diesel*` CSV was found. The unit was not retuned.

The files are `https://gaftp.epa.gov/rtrmodeling_public/AirToxScreen/2020/Pollutant%20Summaries/Region{1-10}/DIESEL_PM10_AMBCONC_R{1-10}.zip`, HTTP 200 on 2026-10-28, combined content-length 172408133, last-modified 2024-10-10 (14:30:58 to 16:10:14 GMT). Block rows: 5808484. Field `Total Conc`. Assignment: population-weighted mean of blocks to the block group, Alaska and island territories AS, GU, MP, and VI null, Connecticut remapped with Geocorr 2022. Published Harvard `DSLPM` differs across block groups inside most tracts, so tract-repeat was not used for the kept score. This comparison is on 243024 Harvard rows. Both present: 240410. Both null: 2584. Rebuilt null where the reference has a value: 30. Reference null where the rebuild has a value: 0. Rows within 1e-8: 401, tolerance rate 0.0016679838609042884. Both positive: 240410. Positive-row median ratio 0.9840077576952359. Pearson 0.9939538189404407. Median absolute gap 0.00400443624157909. The positive-row median ratio is near 1 and Pearson is reported, so the score was kept. No weight or unit was retuned. Ozone stays kept. PM 2.5 stays unscored. Wastewater, Superfund, traffic, hazardous waste, RSEI_AIR, RMP, life expectancy, 97.5, and the factor weights were left unchanged.

NO2. Nitrogen dioxide was rebuilt from the public HAQAST 2020 ~1 km surface NO2 grid and the score was kept. The version 2.3 technical documentation names 2020 block-group HAQAST data in ppb from a regression model, satellite data, and large-scale models, aggregated by mean pixel value (pp. 14, 18 to 19). No `EJscreen.NO2*` CSV was found. GES DISC `SFC_NITROGEN_DIOXIDE_CONC` requires Earthdata login. The unit was not retuned.

The file is `https://ndownloader.figshare.com/files/26064350` (`2020_final_1km.tif`, figshare DOI 10.6084/m9.figshare.12968114), HTTP 200 on 2026-10-28, content-length 419315078, last-modified 2021-04-25 19:43:03 GMT. SHA256 `473bf2e9170fead07a12121e6fab3aaac8771101bbfc3cd7c0acacb1da27cf8d`. Array 43080 by 16200, EPSG:4326, nodata -999, matching the HAQAST GES DISC product dimensions. Block groups: Census `cb_2020_us_bg_500k.zip`, 104212096 bytes. Assignment: mean of intersecting pixels with `all_touched`, island territories AS, GU, MP, and VI null, Connecticut remapped with Geocorr 2022. This comparison is on 243023 Harvard rows. Both present: 241654. Both null: 1158. Rebuilt null where the reference has a value: 51. Reference null where the rebuild has a value: 160. Rows within 1e-8: 1012, tolerance rate 0.004187805705678367. Both positive: 241654. Positive-row median ratio 1.0000003795016006. Pearson 0.9976910129436063. Median absolute gap 0.021541432330482557. The positive-row median ratio is near 1 and Pearson is reported, so the score was kept. No weight or unit was retuned. Diesel particulate matter stays kept. Ozone stays kept. PM 2.5 stays unscored. Wastewater, Superfund, traffic, hazardous waste, RSEI_AIR, RMP, life expectancy, 97.5, and the factor weights were left unchanged.

DWATER. Drinking water non-compliance was retried from public ECHO SDWA latest plus ORD CWS boundaries and was not kept. The version 2.3 technical documentation scores unresolved SDWA violations from 2019 Q4 through 2023 Q4 from EPA’s internal ETT (SDWIS 2023 Q4), weights them by severity and years out of compliance (10 / 5 / 1 plus year increments capped at 5 for health-based types), joins them to ORD CWS service areas, then population-weights intersecting blocks to the block group. The internal ETT extract is still not public. Severity weights were not invented.

Public retry (2026-10-29). ECHO `SDWA_latest_downloads.zip` last-modified 2026-10-14, submission quarter 2026Q3, 15.55M enforcement rows, 3094207 unique CWS violations after PWSID+VIOLATION_ID dedupe. Printed tiers applied with `VIOLATION_CODE`, `VIOLATION_CATEGORY_CODE`, `IS_HEALTH_BASED_IND`, `CONTAMINANT_CODE`, `RULE_CODE`, noncompliance and RTC dates. `SEVERITY_IND_CNT` was not used (sparse; not the printed tier). ORD `PWS_Boundaries_Latest.zip` version 3.0 block crosswalk: 4464702 intersecting blocks. Reconstructed window 2019Q4 to 2023Q4 (open as of 2023-12-31): 58078 open violations, 11957 CWS with positive PWS score. Closest dated current window 2021Q4 to 2026Q3 (Unaddressed+Addressed as of 2026-09-30): 40170 open violations, 12655 CWS with positive PWS score.

Harvard comparison (reconstructed 2019Q4 to 2023Q4, intersect-pop weights): both present 222081; both null 12304; both positive 33877; positive-row median ratio 1.0; Pearson 0.13753045262732258; Spearman 0.6355451427634835. Current 2021Q4 to 2026Q3: both positive 31318; median ratio 1.0; Pearson 0.155387180706439. Rebuild max about 325 versus published max 899. The positive-row median ratio is near 1 and Pearson is reported, but Pearson is far from identity, so the score was not kept. No weight was retuned. PM 2.5 stays kept. Hazardous waste stays pinned. RMP stays not kept. NO2, DSLPM, ozone, and UST stay kept. Wastewater, Superfund, traffic, RSEI_AIR, life expectancy, 97.5, and the factor weights were left unchanged.

UST. Underground storage tanks and leaking UST were rebuilt from the public UST Finder inventory and the score was kept. The version 2.3 technical documentation names ORD/OUST scores supplied March 5, 2024 at 2022 block group level, formula `(LUST × 7.7 + UST count) / km²` of the block group buffered by 1,500 feet. No March 5, 2024 precomputed BG score table was found. The 7.7 factor and 1,500-foot buffer were not retuned.

The service is `https://services.arcgis.com/cJ9YHowT8TU7DUyn/arcgis/rest/services/UST_Finder_Feature_Layer_2eb/FeatureServer`, downloaded 2026-10-28. State data vintage 2018 to 2021; tribal data October 2025. Layer `dataLastEditDate` 2026-02-13. Facilities: 742844 (Open_USTs 503630, TOS_USTs 32494). Releases: 530798 (Open 70097). Active numerator: Open_USTs + TOS_USTs at facility points. LUST numerator: Open-status release points. Geography: `cb_2022_us_bg_500k`, 242297 polygons, buffered 457.2 m in regional projected CRS. This comparison is on 243022 Harvard rows. Both present: 241748. Both null: 1102. Rebuilt null where the reference has a value: 28. Reference null where the rebuild has a value: 144. Both positive: 176394. Positive-row median ratio 1.0001488832517622. Pearson 0.9898386174024473. Spearman 0.9971602098738673. Tolerance rate 6.236039774595507e-05. The positive-row median ratio is near 1 and Pearson is reported, so the score was kept. Open-only tanks (no TOS) had median ratio 0.9990261871923211 and Pearson 0.9885825824203869. All releases including NFA had median ratio about 4.01 and Pearson about 0.693 and were not kept. PM 2.5 stays kept. NO2, DSLPM, and ozone stay kept. Hazardous waste stays pinned. Drinking water stays not kept after the ECHO retry. RMP stays not kept. Wastewater, Superfund, traffic, RSEI_AIR, life expectancy, 97.5, and the factor weights were left unchanged.

