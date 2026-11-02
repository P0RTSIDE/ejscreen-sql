# EJScreen version 2.3 methodology

This note records the formulas used by the SQL reconstruction. Authority: U.S. Environmental Protection Agency, *EJScreen Technical Documentation for Version 2.3*, revised July 31, 2024. Local copy: `docs/sources/ejscreen-tech-doc-version-2-3.pdf`. Printed page numbers match the PDF page numbers. Quotations below are from that PDF.

Where EPA pages disagree, or the tech doc is silent, choices are recorded in [`docs/assumptions.md`](assumptions.md). Validation results are in [`docs/validation_report.md`](validation_report.md).

EJScreen combines environmental and socioeconomic indicators on Census block groups. It publishes a two-factor demographic index, a five-factor supplemental demographic index, 13 EJ indexes, and 13 supplemental indexes (p. 1, pp. 31 to 39).

## Geographic universe

The geographic framework is 2022 Census TIGER/Line data for all 50 states, the District of Columbia, and Puerto Rico. The socioeconomic source for that universe is the Census Bureau American Community Survey (ACS) 2018-2022 5-Year Estimates, which the tech doc also calls ACS 2022. "There are a total of 242,336 block groups." (p. 4)

Puerto Rico is included with the 50 states and the District of Columbia and uses ACS 2022. The word "territories" in the tech doc means American Samoa, the Commonwealth of the Northern Mariana Islands, Guam, and the U.S. Virgin Islands, and excludes Puerto Rico. Those four areas add 686 records. American Samoa, the Northern Mariana Islands, and Guam use 2022 Census Place boundaries. The U.S. Virgin Islands use 2022 Census Estate boundaries. Boundaries are from the 1:500,000 cartographic boundary files. Socioeconomic data for the four territories come from the Census 2020 Island Areas Demographic Profile, released in October 2022, not from ACS. Place and estate records are appended to the state, District of Columbia, and Puerto Rico block groups. The four territories have state percentiles and do not have national percentiles (pp. 4 to 5, pp. 53 to 54).

Block centroids and population weights used in the application come from the 2020 Decennial Census P.L. 94-171 Redistricting data (p. 5, p. 51).

## Demographic Index

### What it is

The Demographic Index is the average of two z-scores: percent low income and percent people of color. The tech doc names those two factors as the demographic factors in Executive Order 12898 (p. 31).

A z-score is `z = (x - μ) / σ`, with μ the mean and σ the standard deviation (p. 31). The worked example uses the national mean and the national standard deviation, and it states the values in decimals rather than percents (p. 36).

### Inputs and population universe

Percent low income uses ACS table C17002, Ratio of Income to Poverty Level in the Past 12 Months (pp. 8 to 9, p. 32):

`% low income = (C17002.001 - C17002.008) / C17002.001`

C17002.001 is the total population whose poverty status is known. C17002.008 is people with a ratio of income to poverty of 2.00 and over. The prose definition says low income is a household whose income is less than or equal to twice the federal poverty level (p. 8). The formula and that sentence are both printed. They are not reconciled in the tech doc. See `docs/assumptions.md`.

Percent people of color uses ACS table B03002, Hispanic or Latino Origin by Race (p. 7, p. 32):

`% people of color = (B03002.001 - B03002.003) / B03002.001`

B03002.001 is the total population. B03002.003 is non-Hispanic white alone. The tech doc defines people of color as everyone other than non-Hispanic white-alone individuals (p. 6, p. 7).

The index is calculated for block groups. For the four territories, the tech doc says the Demographic Index is `% low income z-score + % people of color z-score / 2`, using 2020 Island Areas Demographic Profile indicators rather than these ACS tables (p. 53).

### Formula

Z-scores for percent low income and percent people of color are calculated first. The Demographic Index is their average (p. 32):

`Demographic Index = (% low income z + % people of color z) / 2`

After that average, "the absolute value of the smallest demographic index value was added to individual demographic indexes to make them non-negative. This shift was applied to national and state levels." (p. 33)

The worked national example uses block group 410510068022. It states percent people of color 0.252511, national mean 0.395843, national standard deviation 0.315152, and z-score -0.454803. It states percent low income 0.1873, national average 0.30415, national standard deviation 0.213371, and z-score -0.547638. The average of those two z-scores is -0.501221. The example calls -1.34074 the smallest national demographic index and adds its absolute value: `-0.501221 + |-1.34074| = 0.8395` (pp. 36 to 37). The displayed low-income subtraction in that example reprints the people-of-color inputs. See `docs/assumptions.md`.

The tech doc does not publish a state-level minimum. It says the same shift was applied at state level (p. 33).

### Null, suppression, and rounding

Checked pp. 31 to 33 and the worked example on pp. 36 to 37.

- Tech doc silent on ACS suppression, margins of error, and what to do if percent low income or percent people of color is missing. A whole-document search found no use of "suppress" or "margin of error."
- Tech doc silent on a rounding rule for the Demographic Index. The example prints 0.8395 and does not state a rule that produced that display.
- Tech doc silent on whether the z-score mean and standard deviation are population-weighted. The percentile section separately says percentile calculations are unweighted and that the national or state mean is the average of block groups with data for that indicator (p. 36, p. 41). It does not say that this mean is the μ in the demographic z-score.

## Supplemental Demographic Index

### The five factors

Page 33 states:

> The five socioeconomic indicators considered are low life expectancy, percent low income, percent persons with disabilities, percent limited English speaking, and percent less than high school education.

Page 31 lists the same five factors as the inputs to an average of z-scores: percent low income, percent limited English speaking, percent less than high school education, percent persons with disabilities, and low life expectancy.

Unemployment is one of the seven socioeconomic indicators in the tool (pp. 6 to 10, table B23025). It is not one of these five factors. Version 2.3 uses percent persons with disabilities.

### Each factor

1. Low life expectancy. An inverse of normalized life expectancy at birth from CDC National Center for Health Statistics: `% low life expectancy = 1 - (Life Expectancy / Max Life Expectancy)` (p. 33). Source, vintage, and the missing maximum are in the section below.
2. Percent low income. Same C17002 formula as the Demographic Index (p. 34).
3. Percent persons with disabilities. "Percent of all persons with disabilities. This data is derived from 2022 ACS 'Sex by Age by Disability Status' table (B18101) for Census tracts. Block group values are calculated by multiplying the tract value by the block group population weights." The weights are from 2020 Decennial Census P.L. 94-171 Redistricting data (p. 34, repeated p. 55). The tech doc does not give B18101 cell numbers or a weight equation.
4. Percent limited English speaking households. ACS table C16002 (p. 10, p. 34):

`% limited English speaking = (C16002.004 + C16002.007 + C16002.010 + C16002.013) / C16002.001`

C16002.001 is total households. The four numerator cells are limited-English households in Spanish, other Indo-European languages, Asian and Pacific Island languages, and other languages.

5. Percent less than high school education. People age 25 or older. ACS table B15002 (pp. 11 to 12, pp. 34 to 35). The printed numerator is:

`B15002.003 + .004 + .005 + .006 + .007 + .008 + .009 + .010 + .020 + .021 + .022 + .023 + .024 + .025 + .026`

divided by `B15002.001`. Table 5 also lists B15002.027, female 12th grade with no diploma. The printed sum does not include .027. See `docs/assumptions.md`.

### Formula

Z-scores of the five factors are averaged (p. 35):

`Supplemental Demographic Index = (low income z + limited English z + less than high school z + disability z + low life expectancy z) / 5`

"The low life expectancy data are available for about 90% of the country." Where it is missing, the index is the average of the other four z-scores, divided by 4 (p. 35).

The same non-negative shift is then applied at national and state levels: add the absolute value of the smallest supplemental demographic index (p. 35). The worked national example adds `|-1.6392|` to an unshifted value of -0.6236438 and prints 1.0156 (p. 38). No state minimum is printed. No rounding rule is stated.

## How an EJ index is calculated

There is one EJ index for each of the 13 environmental indicators. The printed equation is (p. 36):

`EJ Index = Demographic Index × Normalized Environmental Indicator`

The same page says the Demographic Index in that equation is the average of the two z-scores, and the normalized environmental indicator is the percentile of the environmental indicator. Percentile calculations are unweighted. Ties use a floor method (p. 36).

The worked example multiplies the shifted demographic index, not the raw z-score average. For block group 410510068022, the national Superfund proximity percentile is 59 and the shifted demographic index is 0.8395, so `59 × 0.8395 = 49.532`. That product is then looked up, and the example reports a national EJ index percentile of 66 (p. 37).

From that example, the percentile enters the product on a 0 to 100 scale. The example does not divide 59 by 100.

Checked pp. 36 to 39:

- Tech doc silent on a cap. The version 2.3 equation and example do not limit the product.
- Tech doc silent on a low-population rule for the EJ index itself. The low-population rule that is written applies to proximity indicators: only non-zero population block groups are included in the proximity calculation, and block groups with no residential population are assigned null for proximity indicators (p. 48, p. 49). Null indicator values are left out of percentile calculations (p. 40).
- The example is a national percentile and a national EJ index. The tech doc also says state EJ index percentiles are built from the two-factor Demographic Index (p. 43) and that a normalized indicator can differ at state and national level in the older appendix, but version 2.3 does not print a separate state multiplication equation. State percentiles are defined on pp. 41 to 42.

## The 13 environmental indicators

Names from the summary list (p. 15):

1. Particulate Matter 2.5
2. Ozone
3. Nitrogen Dioxide (NO2)
4. Diesel Particulate Matter
5. Toxic releases to air
6. Traffic proximity and volume
7. Lead paint
8. Superfund proximity
9. RMP facility proximity
10. Hazardous waste proximity
11. Underground storage tanks (UST) and leaking UST (LUST)
12. Wastewater discharge
13. Drinking Water Non-Compliance

### Source and method, by indicator

Particulate Matter 2.5. The 2020 tract values come from EPA's Office of Air Quality Planning and Standards as a spreadsheet. The method is a fusion of monitor data and Community Multiscale Air Quality (CMAQ) modeling, documented in EPA report EPA-454/S-15-001. Tract values are copied to child block groups, and 2020 block groups are remapped to 2022 block groups (p. 14, p. 16).

Ozone. The version 2.3 indicator is the annual mean of the 10 highest daily maximum 8-hour ozone concentrations. The source is the same 2020 OAQPS tract spreadsheet, fusion of monitor data and CMAQ, EPA-454/S-15-001, copied to child block groups and remapped from 2020 to 2022 block groups (pp. 16 to 17).

Nitrogen dioxide. Source data are from NASA's Health and Air Quality Applied Sciences Team for 2020 at block group level. The method is a regression model using satellite data and large-scale models, not EPA monitor-fused modeling. The product is about a 1 kilometer grid, projected to 2020 Census block groups with a high-resolution NASA satellite product, then aggregated to block groups by mean pixel value (p. 14, pp. 18 to 19).

Diesel particulate matter. The indicator is the 2020 AirToxScreen diesel PM concentration, in micrograms per cubic meter, from an EPA OAQPS spreadsheet. Page 14 calls the source block group level. Page 19 says the source data are compiled by Census tract and the tract value is repeated for each block group, with 2020 block groups remapped to 2022. Both statements are printed. See `docs/assumptions.md`.

Toxic releases to air. Chemical releases reported to the Toxics Release Inventory are run through EPA's Risk-Screening Environmental Indicators (RSEI) model. The Office of Pollution Prevention and Toxics supplied average annual toxicity-weighted air concentrations on May 16, 2023, from 2021 RSEI modeled results, as a polygon feature class. Values are aggregated from RSEI grid cells to block groups and island areas. The Office of Environmental Justice and External Civil Rights then builds percentiles (pp. 19 to 20).

Traffic proximity and volume. Source is 2020 Highway Performance Monitoring System annual average daily traffic from the Federal Highway Administration. The method is an inverse-distance score inside 10 kilometers, multiplied by traffic counts, calculated at populated 2020 Census blocks and aggregated to the block group with block population weights. The road subset is interstates, other freeways and expressways, other principal arterials, and minor arterials in urban areas. Overlapping 2020 segments were dissolved on a Route_ID plus AADT key before scoring (pp. 21 to 22, pp. 50 to 51). Page 15 says distance in kilometers. Page 21 says distance in meters. See `docs/assumptions.md`.

Lead paint. Percent of housing units built before 1960, from ACS 2018-2022 table B25034, Year Structure Built (pp. 22 to 23):

`% lead paint = (B25034.009 + B25034.010 + B25034.011) / B25034.001`

Superfund proximity. Sites are proposed and final National Priorities List sites plus Superfund Alternative Approach sites. Boundaries were taken from the Superfund public map service on February 26, 2024, and the remaining sites from the Superfund Enterprise Management System on the same date. The method is inverse distance within 10 kilometers, with a maximum score of 11 inside 0.1 kilometers, population-weighted from 2020 block centroids to the block group (p. 23, pp. 49 to 50).

RMP facility proximity. Active facilities in the Risk Management Plan program, selected from EPA's Facility Registry Service on February 5, 2024. Inverse distance within 10 kilometers, maximum score 10 inside 0.1 kilometers, population-weighted from block centroids (p. 24, p. 49).

Hazardous waste proximity. Operating Treatment, Storage, and Disposal Facilities from RCRAInfo, plus Large Quantity Generators from the 2021 Biennial Report, both pulled February 5, 2024. Inverse distance within 10 kilometers, maximum score 10, population-weighted from block centroids (pp. 24 to 25, p. 49).

Underground storage tanks and leaking underground storage tanks. Scores were provided by EPA's Office of Research and Development. The Office of Underground Storage Tanks supplied the source on March 5, 2024, at 2022 block group level. The printed formula divides the count of leaking tanks times 7.7, plus the count of active tanks, by the area in square kilometers of the block group buffered by 1,500 feet. The 7.7 factor is the average number of active tanks divided by the average leaking-tank backlog over 2011 to 2020 (pp. 25 to 26). The one-line summary on p. 15 names the counts and the buffer and does not restate the division by area.

Wastewater discharge. Discharge monitoring reports and Toxics Release Inventory data are run through RSEI. The Office of Pollution Prevention and Toxics, with the Office of Water, supplied February 2024 results from 2021 RSEI as toxicity-weighted concentrations on National Hydrography Dataset flowlines. The detailed method is the traffic method: inverse distance within 10 kilometers, multiplied by the toxicity-weighted concentration, population-weighted from block centroids, maximum score 10 inside 0.1 kilometers (pp. 26 to 27, pp. 50 to 51). The summary on p. 15 says stream segments within 500 meters. See `docs/assumptions.md`.

Drinking water non-compliance. A score for community water system violations that have not returned to compliance, over 2019 quarter 4 through 2023 quarter 4. The violation extract is from EPA's internal Enforcement and Targeting Tool, which draws on the Safe Drinking Water Information System, submission year 2023 quarter 4. Service-area boundaries are from the Office of Research and Development. Violations are weighted by severity tier and by years out of compliance, summed to a service-area score, then population-weighted from blocks to the block group. If no service area intersects the block group, the score is null (pp. 27 to 29).

## The 13 supplemental indexes

There is one supplemental index for each of the same 13 environmental indicators. The equation is (p. 38):

`Supplemental Index = Supplemental Demographic Index × Normalized Environmental Indicator`

The normalized environmental indicator is again the percentile of the environmental indicator. The worked example multiplies the shifted supplemental demographic index by the national Superfund percentile of 59: `59 × 1.0156 = 59.92`, which looks up to a national supplemental index percentile of 60 (pp. 38 to 39).

They differ from the EJ indexes in the demographic factor: supplemental indexes use the five-factor supplemental demographic index, and EJ indexes use the two-factor demographic index. They use the same environmental percentile in the printed equations. Where low life expectancy is missing, the supplemental demographic piece is a four-factor average, so the supplemental index moves with that four-factor value (p. 35, p. 38).

Coverage also differs. Page 58 prints both sets. Ozone and PM 2.5 indexes are absent for Alaska, Hawaii, and Puerto Rico. Diesel PM indexes are absent for Alaska. Wastewater indexes are absent for Alaska. Drinking water indexes are absent for Puerto Rico. On the four island territories, some EJ indexes are present (toxic releases to air, lead paint, and underground storage tanks on all four; other proximity indexes only on some). Every supplemental index is marked No for American Samoa, the Northern Mariana Islands, Guam, and the U.S. Virgin Islands (p. 53, p. 58).

## Percentiles

A percentile lookup table was built for the United States and for each state, the District of Columbia, and Puerto Rico. Raw values for percentiles 0 through 100, in steps of one percentile, were stored, which is 101 cutoff values. A value is compared with those 101 cutoffs. "Once a range is detected, the percentile for the lower range value will be assigned." (pp. 41 to 42)

Ties use a floor method. "If an indicator value of 0 is assigned percentiles from 0 to 10, the reported percentile will be 0 instead of 10." (p. 40, repeated p. 42) The EJ index notes give the same rule and the limited-English example: a value of 0 yields percentile 0 rather than the 50th percentile when more than half of the values are zero (p. 36).

The lookup and the EJ index example use a 0 to 100 scale. The example multiplies by 59, not by 0.59 (p. 37). Indicator writeups also say percentiles "range from 0 to 100%" (for example p. 16).

"Percentiles calculations are unweighted." (p. 36) U.S. percentiles use block groups nationwide. State percentiles are calculated inside each state, and the same way for the District of Columbia and Puerto Rico. Within one state the U.S. and state percentiles rank block groups in the same order. The national or state mean is the average of the block groups that have data for that indicator in that geography (p. 41).

"Block group indicator null values are not included in percentile calculation." Ozone and PM 2.5 are not available for Alaska, Hawaii, and Puerto Rico, and those block groups are excluded. Only block groups with valid values are included (p. 40). That is the statement on the denominator: nulls are out of the calculation. The four island territories are not in the national percentiles (p. 53).

Checked pp. 40 to 42: tech doc silent on a minimum population for a block group to enter a percentile. The only population screen written for inputs is the proximity rule that zero-population block groups are null and are not included in the proximity calculation (p. 48, p. 49). Those nulls then fall under the null-exclusion sentence on p. 40.

Map colors are a separate binning of places above the 50th percentile: 50 to 80, 80 to 90, 90 to 95, and 95 to 100. The tech doc says these bins have no official policy meaning (p. 40). An earlier screening filter, the 80th percentile on any of the 13 EJ indexes nationally, is described as an internal EPA starting point, not as part of the percentile formula (pp. 43 to 44).

One sentence on p. 40 says that the 80th percentile nationwide means 20 percent of the U.S. population has a higher value. The next sentences define the percentile by block groups, and p. 36 says the calculations are unweighted. See `docs/assumptions.md`.

## ACS vintage and demographic tables

ACS 2018-2022 5-year estimates, called ACS 2022 in the tech doc (p. 4, p. 6).

| Input | Table | Where it is used |
| --- | --- | --- |
| People of color | B03002 | Demographic Index (p. 7, p. 32) |
| Low income | C17002 | Both demographic indexes (p. 8, p. 32, p. 34) |
| Limited English speaking households | C16002 | Supplemental Demographic Index (p. 10, p. 34) |
| Less than high school, age 25 and over | B15002 | Supplemental Demographic Index (p. 11, p. 34) |
| Persons with disabilities | B18101, tract, 2022 ACS | Supplemental Demographic Index (p. 34, p. 55) |
| Unemployment, civilian labor force | B23025 | Socioeconomic indicator only. Not a version 2.3 supplemental factor (pp. 9 to 10) |
| Under age 5 and over age 64 | B01001 | Socioeconomic indicators only. Not inputs to either demographic index (pp. 12 to 13) |
| Lead paint, year structure built | B25034 | Environmental indicator (p. 22) |

The tech doc says these ACS tables can be downloaded from the Census Bureau FTP server. It does not print the FTP URL.

## Low life expectancy

Low life expectancy is from the U.S. Small-area Life Expectancy Estimates Project (USALEEP), described as a collaboration of the National Center for Health Statistics, the National Association for Public Health Statistics and Information Systems, and the Robert Wood Johnson Foundation. The measure is life expectancy at birth. The formula is `1 - (Life Expectancy / Max Life Expectancy)` (p. 33, p. 55).

Vintage and processing, as printed (p. 55): the source is Census 2015 tract-level data. It was converted to 2010 tracts with the Census 2010 to 2015 relationship table, then to 2020 tracts with the Census 2010 to 2020 relationship table, then to Census 2022 tracts. The tract value was assigned to each child 2022 block group.

Checked p. 33 and p. 55: tech doc silent on the numeric value of Max Life Expectancy, and it does not give a download URL for the USALEEP file.
