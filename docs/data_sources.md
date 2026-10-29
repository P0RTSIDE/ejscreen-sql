# Tier 2 data sources

Vintage: American Community Survey 2018-2022 5-year estimates. The Census API dataset is `2022/acs/acs5`. The technical documentation calls this ACS 2022 (p. 4, p. 6).

Geography requested: block groups in the 50 states, the District of Columbia, and Puerto Rico. The state list is the `2022/acs/acs5` state query. American Samoa, Guam, the Northern Mariana Islands, and the U.S. Virgin Islands are not in that dataset and were not requested.

Variable labels below were read from `https://api.census.gov/data/2022/acs/acs5/groups/{table}.json`. The API estimate code uses an underscore and an `E` suffix. The technical documentation prints the same line with a dot.

## People of color

Technical documentation p. 7 and p. 32. Table B03002, Hispanic or Latino Origin by Race.

| Tech doc line | API code | Census label |
| --- | --- | --- |
| B03002.001 | B03002_001E | Total |
| B03002.003 | B03002_003E | Not Hispanic or Latino: White alone |

Formula: `(B03002.001 - B03002.003) / B03002.001`.

## Low income

Technical documentation pp. 8 to 9, p. 32, and p. 34. Table C17002, Ratio of Income to Poverty Level in the Past 12 Months.

| Tech doc line | API code | Census label |
| --- | --- | --- |
| C17002.001 | C17002_001E | Total |
| C17002.008 | C17002_008E | 2.00 and over |

Formula: `(C17002.001 - C17002.008) / C17002.001`.

## Limited English speaking households

Technical documentation p. 10 and p. 34. Table C16002, Household Language by Household Limited English Speaking Status.

| Tech doc line | API code | Census label |
| --- | --- | --- |
| C16002.001 | C16002_001E | Total |
| C16002.004 | C16002_004E | Spanish: Limited English speaking household |
| C16002.007 | C16002_007E | Other Indo-European languages: Limited English speaking household |
| C16002.010 | C16002_010E | Asian and Pacific Island languages: Limited English speaking household |
| C16002.013 | C16002_013E | Other languages: Limited English speaking household |

Formula: `(C16002.004 + C16002.007 + C16002.010 + C16002.013) / C16002.001`.

## Less than high school education

Technical documentation pp. 11 to 12 and pp. 34 to 35. Table B15002, Sex by Educational Attainment for the Population 25 Years and Over. The printed sum omits B15002.027. Table 5 lists that line. The comparison matched the reference only after the line was added, so it is requested.

| Tech doc line | API code | Census label |
| --- | --- | --- |
| B15002.001 | B15002_001E | Total |
| B15002.003 | B15002_003E | Male: No schooling completed |
| B15002.004 | B15002_004E | Male: Nursery to 4th grade |
| B15002.005 | B15002_005E | Male: 5th and 6th grade |
| B15002.006 | B15002_006E | Male: 7th and 8th grade |
| B15002.007 | B15002_007E | Male: 9th grade |
| B15002.008 | B15002_008E | Male: 10th grade |
| B15002.009 | B15002_009E | Male: 11th grade |
| B15002.010 | B15002_010E | Male: 12th grade, no diploma |
| B15002.020 | B15002_020E | Female: No schooling completed |
| B15002.021 | B15002_021E | Female: Nursery to 4th grade |
| B15002.022 | B15002_022E | Female: 5th and 6th grade |
| B15002.023 | B15002_023E | Female: 7th and 8th grade |
| B15002.024 | B15002_024E | Female: 9th grade |
| B15002.025 | B15002_025E | Female: 10th grade |
| B15002.026 | B15002_026E | Female: 11th grade |
| B15002.027 | B15002_027E | Female: 12th grade, no diploma |

Formula: the sum of B15002.003 through B15002.010, B15002.020 through B15002.026, and B15002.027, divided by B15002.001. A zero denominator is stored as 0.

## Unemployment

Technical documentation pp. 9 to 10. Table B23025, Employment Status for the Population 16 Years and Over. This indicator is not an input to either demographic index.

| Tech doc line | API code | Census label |
| --- | --- | --- |
| B23025.003 | B23025_003E | In labor force: Civilian labor force |
| B23025.005 | B23025_005E | In labor force: Civilian labor force: Unemployed |

Formula: `B23025.005 / B23025.003`.

## Under age 5 and over age 64

Technical documentation pp. 12 to 13. Table B01001, Sex by Age. These indicators are not inputs to either demographic index.

| Tech doc line | API code | Census label |
| --- | --- | --- |
| B01001.001 | B01001_001E | Total |
| B01001.003 | B01001_003E | Male: Under 5 years |
| B01001.027 | B01001_027E | Female: Under 5 years |
| B01001.020 | B01001_020E | Male: 65 and 66 years |
| B01001.021 | B01001_021E | Male: 67 to 69 years |
| B01001.022 | B01001_022E | Male: 70 to 74 years |
| B01001.023 | B01001_023E | Male: 75 to 79 years |
| B01001.024 | B01001_024E | Male: 80 to 84 years |
| B01001.025 | B01001_025E | Male: 85 years and over |
| B01001.044 | B01001_044E | Female: 65 and 66 years |
| B01001.045 | B01001_045E | Female: 67 to 69 years |
| B01001.046 | B01001_046E | Female: 70 to 74 years |
| B01001.047 | B01001_047E | Female: 75 to 79 years |
| B01001.048 | B01001_048E | Female: 80 to 84 years |
| B01001.049 | B01001_049E | Female: 85 years and over |

Under age 5: `(B01001.003 + B01001.027) / B01001.001`.

Over age 64: the sum of B01001.020 through B01001.025 and B01001.044 through B01001.049, divided by B01001.001.

## Persons with disabilities

Technical documentation p. 34 and p. 55. Table B18101, Sex by Age by Disability Status, requested for census tracts, not block groups. The technical documentation does not list cells. The lines below are the estimate variables whose fetched Census label is "With a disability", plus the table total.

| API code | Census label |
| --- | --- |
| B18101_001E | Total |
| B18101_004E | Male: Under 5 years: With a disability |
| B18101_007E | Male: 5 to 17 years: With a disability |
| B18101_010E | Male: 18 to 34 years: With a disability |
| B18101_013E | Male: 35 to 64 years: With a disability |
| B18101_016E | Male: 65 to 74 years: With a disability |
| B18101_019E | Male: 75 years and over: With a disability |
| B18101_023E | Female: Under 5 years: With a disability |
| B18101_026E | Female: 5 to 17 years: With a disability |
| B18101_029E | Female: 18 to 34 years: With a disability |
| B18101_032E | Female: 35 to 64 years: With a disability |
| B18101_035E | Female: 65 to 74 years: With a disability |
| B18101_038E | Female: 75 years and over: With a disability |

The tract rate is the sum of the "With a disability" lines divided by B18101_001E. That rate is assigned to each block group in the tract. A zero tract total is stored as 0. See `docs/assumptions.md`. The 2020 population file is still loaded. It is not used in the disability rate.

Block group population: 2020 Decennial Census P.L. 94-171, Census API dataset `2020/dec/pl`, variable `P1_001N`. The variables endpoint label is `!!Total:` and the concept is `RACE`. Geography: block group.

## Low life expectancy

Technical documentation p. 33 and p. 55. The source named there is the U.S. Small-area Life Expectancy Estimates Project (USALEEP), from the National Center for Health Statistics, the National Association for Public Health Statistics and Information Systems, and the Robert Wood Johnson Foundation.

File obtained: `US_A.CSV`, published by the National Center for Health Statistics. The NCHS page links the national life expectancy CSV on the CDC FTP server. The file header is `Tract ID,STATE2KX,CNTY2KX,TRACT2KX,e(0),se(e(0)),Abridged life table flag`. `e(0)` is life expectancy at birth for 2010-2015. The tract id is a 2010 census tract. The technical documentation does not give this file name or a numeric maximum life expectancy. The maximum used here, 97.5, is the maximum `e(0)` in the file and the center of the implied maximum from the reference. It is not a technical documentation figure. See `docs/assumptions.md`.

Relationship file used for the single 2010 parent: `tab20_tract20_tract10_natl.txt`, the national 2020 Census Tract to 2010 Census Tract Relationship File, published by the U.S. Census Bureau. The columns are geographic identifiers and land and water area. The file has no population or housing weight. A 2022 tract whose id is not a 2010 tract id, and that has one 2010 parent in the join to USALEEP, takes that parent's life expectancy. Land area is not used as a weight.

Multi-parent 2020 tracts use the Census Bureau 2010 Census Tabulation Block to 2020 Census Tabulation Block relationship files. The publisher page is `https://www.census.gov/geographies/reference-files/2020/geo/relationship-files.html`. The files are `TAB2010_TAB2020_ST##.zip` for the 50 states, the District of Columbia, and Puerto Rico, from `https://www2.census.gov/geo/docs/maps-data/data/rel2020/t10t20/`. The record layout is `https://www.census.gov/programs-surveys/geography/technical-documentation/records-layout/2020-census-block-record-layout.html`. Each zip holds one pipe-delimited text file with 18 fields: 2010 and 2020 state, county, tract, block, block suffix, land area, water area, and block part flag, plus the intersection land and water area. The layout has no population or housing count. Loaded rows: 12689707, table `raw.block_rel_2010_2020`.

The weight is 2020 Decennial Census P.L. 94-171 population at block geography. Census API dataset `2020/dec/pl`, variable `P1_001N`, the same variable already requested for block groups. Geography: `block:*` inside each state and county. Loaded rows: 8174955, table `raw.pl2020_block`. A 2020 block that the relationship places in one 2010 tract contributes its whole population. A 2020 block placed in more than one 2010 tract is left out of the weight. The relationship file has no part-population column. It does have `arealand_int`, the intersection land area shared by the 2010 and 2020 blocks. That column sums to `arealand_2020` on every one of those blocks. Allocating `P1_001N` by `arealand_int` was compared with the published life expectancy and was not kept. See `docs/assumptions.md`. The tract value is the population-weighted average of the 2010 parent life expectancies, used only when the tract has more than one 2010 parent and the direct and single-parent rules did not already supply a value.

Tracts with no USALEEP value stay null. CDC PLACES was not used. It is a different life expectancy estimate.

The technical documentation also names a Census 2010 to 2015 relationship table. That file was not found on the Census relationship-file site. `US_A.CSV` is already keyed by 2010 tract ids, so the 2015 to 2010 step is not applied again.

Connecticut after the 2022 county change: the Census page checked is `https://www.census.gov/geographies/reference-files/2022/geo/relationship-files.html`. The directory `https://www2.census.gov/geo/docs/maps-data/data/rel2022/` contains seven files, all for Connecticut: `acs22_cd11822_county22_st09.txt`, `acs22_cousub22_blkgrp20_st09.txt`, `acs22_cousub22_puma520_st09.txt`, `acs22_cousub22_tract22_st09.txt`, `acs22_cousub22_zcta520_st09.txt`, `acs22_sldl202222_county22_st09.txt`, and `acs22_sldu202222_county22_st09.txt`. The record layout is `https://www.census.gov/programs-surveys/geography/technical-documentation/records-layout/2022-connecticut-record-layout.html`. None of those files links a 2020 tract to a 2022 tract or a 2020 block to a 2022 block. A search outside that directory, including the 2022 population-estimates geography files, did not find a Census tract or block relationship for this county change. Those seven files are not used. No county-name crosswalk is used.

NHGIS at the University of Minnesota publishes geographic crosswalks only for pairs of years from different decades. The page `https://www.nhgis.org/geographic-crosswalks` does not offer a 2020 to 2022 crosswalk, so that source was not downloaded.

The crosswalk used is Geocorr 2022 from the Missouri Census Data Center. The application page is `https://mcdc.missouri.edu/applications/geocorr2022.html`. The file that downloaded is `geocorr2022_2629507182.csv`, from `https://mcdc.missouri.edu/temp/geocorr2022_2629507182.csv`. It is loaded as `raw.geocorr_ct_2020_2022`, 886 data rows. The request was Connecticut, 2020 census tract to the 2022 planning-region county, weight `pop20` ("Total population (2020 Census)"). The 2020 tract id is `CTcounty` plus the tract code with the decimal removed. The 2022 tract id is `county` plus that same tract code. `pop20` is the weight. `afact` is the tract-to-old-county allocation factor and is not used as the weight. A 2022 Connecticut tract takes the life expectancy of its 2020 tract. Where `pop20` is positive on more than one 2020 parent, the parents would be averaged with `pop20`. The only 2022 tract with two 2020 parents has `pop20` 0 on both rows, so it stays null. No account was required.

# Tier 3 data sources

## Lead paint

Publisher: U.S. Census Bureau. API dataset `2022/acs/acs5`, table B25034, Year Structure Built, block group, 50 states, the District of Columbia, and Puerto Rico. Loaded as `raw.acs2022_bg_b25034`, 242336 rows, from `data/census/acs2022_bg_b25034/`.

Labels from `https://api.census.gov/data/2022/acs/acs5/groups/B25034.json`:

| Tech doc line | API code | Census label |
| --- | --- | --- |
| B25034.001 | B25034_001E | Total |
| B25034.009 | B25034_009E | Built 1950 to 1959 |
| B25034.010 | B25034_010E | Built 1940 to 1949 |
| B25034.011 | B25034_011E | Built 1939 or earlier |

Table 8 in the technical documentation labels the newer bins with an older vintage. Codes 009 through 011 are the pre-1960 cells used in the printed formula.

## Block centroids

Publisher: U.S. Census Bureau, TIGER/Line 2020 tabulation blocks. Files `tl_2020_{fips}_tabblock20.zip` from `https://www2.census.gov/geo/tiger/TIGER2020/TABBLOCK20/`. The 2020 block gazetteer national zip returns HTTP 404, so TIGER is the centroid source. The point is `ST_Centroid` of the block polygon. Census internal points (`INTPTLAT20`, `INTPTLON20`) are not used. Loaded as `raw.tiger2020_block_centroid`, 8174955 rows. Population is the already loaded `raw.pl2020_block` variable `P1_001N`.

Connecticut block groups use the Geocorr 2022 file already loaded as `raw.geocorr_ct_2020_2022`. A 2020 tract with more than one 2022 tract is left unassigned.

## Superfund proximity

The technical documentation vintage is February 26, 2024. That snapshot was not available. The file used is the current public service.

Publisher: U.S. EPA. Service: National NPL Superfund Site Boundaries, U.S. EPA (Public). URL: `https://services.arcgis.com/cJ9YHowT8TU7DUyn/arcgis/rest/services/FAC_Superfund_Site_Boundaries_EPA_Public/FeatureServer/0`. Downloaded 2026-10-22. Query: site feature class 5 (site boundary) and NPL status F or P. 1452 features, 1354 EPA IDs. Last change dates in that extract run from 2008-12-01 to 2026-10-02. Of 1315 features with a date, 490 changed after 2024-02-26.

Superfund Alternative Approach boundaries are the same service, limited to EPA IDs matched to the current and construction-complete lists at `https://www.epa.gov/enforcement/sites-superfund-alternative-approach-agreements` (page updated March 19, 2026). 59 additional boundaries. Former agreements on that page were not included. Names on the list with no boundary were not assigned coordinates. Several of those names are already proposed sites in the F and P extract.

Point file for sites with no polygon: U.S. EPA, `https://services.arcgis.com/cJ9YHowT8TU7DUyn/arcgis/rest/services/Superfund_National_Priorities_List_(NPL)_Sites_with_Status_Information/FeatureServer/0`. Final status "NPL Site" and "Proposed NPL Site". 28 of those points are not in the boundary extract and are buffered by 1 meter. The technical documentation counted 37 SEMS points on February 26, 2024.

## Traffic proximity

Publisher: Federal Highway Administration, U.S. Department of Transportation. The file read is the 2020 HPMS file geodatabase supplied for this run, Google Drive file id `1xWwZuqu-VF_orBg_jrgeoSSYMtcDeAIt`. It opened with the OpenFileGDB driver. `Year_Record` is 2020. There are 52 layers, named `HPMS_FULL_{ST}_2020`, one for each of the 50 states, the District of Columbia, and Puerto Rico. The annual average daily traffic field used is `AADT`.

The zip is 6,264,583,550 bytes. This filesystem rejected a single file near 100 MB, so the zip is stored as `data/reference/HPMS_2020.gdb.zip.part000` through `data/reference/HPMS_2020.gdb.zip.part066`. The parts are 90 MB except the last, and they concatenate to that byte total.

The public catalog record `https://doi.org/10.21949/1522114` is non-public. `Hosted/HPMS_FULL_TX_2020`, `Hosted/HPMS_FULL_LA_2020`, and `Hosted/HPMS_FULL_SD_2020` on `https://geo.dot.gov/server/rest/services` return Token Required. Those states are layers in the supplied geodatabase. The FHWA public shapefile page `https://www.fhwa.dot.gov/policyinformation/hpms/shapefiles.cfm` lists 2018 services.

## RMP facility proximity

The technical documentation vintage is Facility Registry Service on February 5, 2024. That snapshot was not found. The score uses the current public FRS RMP interest layer and was not kept. A 2026-10-29 scale diagnosis found the ~2× median ratio is not from PGM-row or co-location double-counting; FRS `ACTIVE_STATUS` counts about twice EPA’s documented regulated RMP facility total (~11,740), and no public active-only bulk list was available to re-score. See `docs/assumptions.md` and `internal/rmp-diagnosis-notes.md`.

Publisher: U.S. EPA, Facility Registry Service. Service: `https://services.arcgis.com/cJ9YHowT8TU7DUyn/arcgis/rest/services/FRS_INTERESTS_RMP/FeatureServer/0`. Downloaded 2026-10-28 (rechecked 2026-10-29). Layer `dataLastEditDate` 2026-10-26 00:57:17 UTC. 21855 features. Active rows (`ACTIVE_STATUS` = `ACTIVE`): 21836. Blank status: 19. Interest type is `RMP REPORTER` on every row. Unique `PGM_SYS_ID`: 21855. Unique `REGISTRY_ID`: 21569. Scored facilities after one point per `REGISTRY_ID`, valid coordinates, and dropping AS, GU, MP, and VI: 21543. Loaded as `raw.rmp_facility_frs`. The block-group score is `staging.tier3_rmp`. Method: inverse distance within 10 kilometers, cap 10 inside 0.1 kilometers, population-weighted from 2020 block centroids. On 242336 national rows, both values are present for 240939 and both are positive for 171446. The positive-row median ratio is 2.0939259982049303 and Pearson is 0.8337008027964584. The score was not kept.

Also checked on 2026-10-28 / 2026-10-29, and none is the February 5, 2024 pull or an active-only RMP bulk export: Internet Archive CDX for the RMP FeatureServer from 2024-02-01 through 2024-02-10 returned no captures; CDX for `edg.epa.gov/data/public/OEI/FRS/` from 2024-01-01 through 2024-03-01 returned no captures; `https://www.epa.gov/frs/geospatial-data-download-service` lists national products with data as of October 1, 2026, posted October 12, 2026; `https://ordsext.epa.gov/FLA/www3/state_files/national_single.zip` is 353958347 bytes, last-modified 2026-10-12; `https://edg.epa.gov/data/public/OEI/FRS/FRS_Interests_Download.zip` is 1908418733 bytes, last-modified 2026-10-25; RMP Public Data Service redirects without a bulk download; HIFLD “US EPA Risk Management Plan Facilities” has 341 rows.

## Hazardous waste proximity

Built in place of traffic. Publisher: U.S. EPA, RCRAInfo public downloads, `https://rcrapublic.epa.gov/rcra-hwip/data-access/csv-downloads`. The export info endpoint reports `createdDate` 2026-10-18. That is not the February 5, 2024 pull in the technical documentation.

2021 Biennial Report: `BR_REPORTING_2021.zip`, `https://s3.amazonaws.com/rcrainfo-ftp/Production/CSV-2026-10-18T03-00-00-0400/BR/BR_REPORTING_2021/BR_REPORTING_2021.zip`. Report cycle 2021. Large quantity generators are distinct handler ids whose calculated generator status is L. 10573 handler ids.

Handler locations and operating TSDF status: `HD_REPORTING.zip`, `https://s3.amazonaws.com/rcrainfo-ftp/Production/CSV-2026-10-18T03-00-00-0400/HD/HD_REPORTING/HD_REPORTING.zip`. The operating TSDF field is the six-character universe code. L, I, B, S, or T means operating. Dashes, or H alone, do not. Coordinates are `LOCATION LATITUDE` and `LOCATION LONGITUDE`. Loaded as `raw.rcra_facility_2021`. After dropping missing coordinates and island territories, 10645 facilities are scored: 633 operating TSDFs, 10530 large quantity generators, 518 in both.

A supplied Google Drive file, id `1bUbZoLshAZaAHBd7TmDeYs4mbVLJItB6`, is also named `HD_REPORTING.zip` and is 169593899 bytes. Its members are dated 2026-10-25 03:12 and 2026-10-25 03:13. That size matches `https://s3.amazonaws.com/rcrainfo-ftp/Production/CSV-2026-10-25T03-00-00-0400/HD/HD_REPORTING/HD_REPORTING.zip` from public run `CSV-2026-10-25T03-00-00-0400`. The zip contains 1632825 handler rows and no Biennial Report. It is not the February 5, 2024 export. The same run's `BR_REPORTING_2021.zip` is 42796899 bytes. That test was scored and not adopted. See `docs/assumptions.md`.

`data/WT_AR_2024.zip` is 1145475 bytes. Its one member is `WT_AR_2024_0.csv`, 79368159 bytes, dated 2026-10-25 03:27. The columns are export-notice fields: `NOTICE ID`, `EXPORTER EPA ID`, foreign receiver names and addresses, `EPA WASTE CODES`, `BASEL WASTE CODES`, and quantities. There is no latitude or longitude. This is the current RCRAInfo waste-export annual report. It is not the February 5, 2024 handler export and it is not the 2021 Biennial Report. The hazardous-waste score remains the October 18, 2026 export.

Google Drive file id `1WNmjn3qCjZOlz9aKrSqM5Sx2wDrziZTw` is named `HD.zip` and is 634605351 bytes. It is the handler module from 2026-10-25: 38 members, all dated that day, and `METADATA.txt` lists handler tables only. Nested `HD_REPORTING.zip` is 169593899 bytes, with `HD_REPORTING_0.csv` and `HD_REPORTING_1.csv` dated 2026-10-25 03:12 and 03:13 and 1632825 records. There is no `BR_REPORTING_2021`. It is not the February 5, 2024 export. No score was changed.

Google Drive file id `1q6fOfazYAhX6O16F6RuZ2X7KTbNbk0Ig` is named `BR_REPORTING_2021.zip` and is 42796899 bytes. Members: `BR_REPORTING_2021_0.csv`, 460739498 bytes, dated 2026-10-25 03:25, and `BR_REPORTING_2021_1.csv`, 384681843 bytes, dated 2026-10-25 03:26. It is the same October 25, 2026 public biennial-report file already counted at 1829587 rows, 24836 handler ids, and 10573 calculated generator status L. There is no `HD_REPORTING`. It is not the February 5, 2024 export. No score was changed.

## Wastewater discharge proximity

The version 2.3 technical documentation names a February 2024 delivery from EPA OPPT and the Office of Water: 2021 RSEI toxicity-weighted concentrations on National Hydrography Dataset flowlines, as a polyline feature class in a file geodatabase. That February 2024 file was not found. The score uses the public December 27, 2023 polyline of the same kind.

The file is `https://gaftp.epa.gov/rsei/temp/EJS/v2311_water/EJScreen2021.gdb.zip`. HTTP 200 on 2026-10-28, content-length 43741896, last-modified 2023-12-27 18:40:14 GMT. The layer is `EJScreen2021`, a multiline, 250985 features, fields `COMID`, `REACHECODE`, and `TOXCONC`. Zip members are dated 2023-01-30 and 2023-12-27. The extent stops at latitude 49.364066, so Alaska is outside it, and Alaska block groups are null. The same directory lists `EJScreenFields.txt`, 748 bytes, 2023-12-27 13:41, and `QA_Summary_RSEI_WaterIndicator_EJscreen_20231223.xlsx`, 2885899 bytes, last-modified 2023-12-27 18:41:08 GMT. Loaded as `raw.ww_flowline_20231227`. The block-group score is `staging.tier3_wastewater_20231227`. On 242336 rows, both values are present for 240435 and both are positive for 220585. The positive-row median ratio is 0.956633944441 and Pearson is 0.999203979821. The score was kept. See `docs/assumptions.md`.

Also checked on 2026-10-28, and none is that delivery: `https://gaftp.epa.gov/rsei/temp/EJS/` (directories `V235`, `V237`, `V2310`, `v238`, `v239`, `v2311_air`, `v2311_water`, directory stamps 2024-12-30); earlier geodatabases `EJScreen2017.gdb.zip` 49560868 bytes (2019-05-10), `EJScreen2018.gdb.zip` 57381217 bytes (2020-07-03), `EJScreen2019.gdb.zip` 57584815 bytes (2022-11-23), `EJScreen2020.gdb.zip` 43387948 bytes (2022-11-23); `https://gaftp.epa.gov/rsei/Older_Versions/Version2311_RY2021/` air grid cells dated 2023-03-16 and `RSEIv2311_Public_Release_Data.zip` dated 2023-03-16; `https://gaftp.epa.gov/rsei/Current_Version/V2312_RY2022/` reporting year 2022, public-release zip dated 2024-03-21; `NHDMicroResults_Onsite_2021.zip` HTTP 404 at Version 2.3.11, `v2311_water`, `rsei/temp`, and `rsei/Shapefiles`; `https://gaftp.epa.gov/rsei/temp/EJS/v2311_water/EJScreen2024.gdb.zip` and `https://gaftp.epa.gov/rsei/temp/EJS/v2312_water/` HTTP 404; `https://edg.epa.gov/data/public/OPPT/` HTTP 404; `https://edg.epa.gov/data/public/OCSPP/OPPT/` contains CDR, metadata, and TSCA, and `RSEI.json` is 4822 bytes with coverage through 2014; `https://gaftp.epa.gov/EJScreen/` HTTP 404. A data.gov catalog search for EJScreen returned three datasets, none a wastewater flowline file. Internet Archive CDX for `gaftp.epa.gov/rsei/temp/EJS/` from 2024-01-01 through 2024-03-15 returned no captures. The earliest `v2311_water` capture is 2024-09-28. The earliest `EJScreen2021.gdb.zip` capture is 2024-10-04, recorded length 43746276. `https://gaftp.epa.gov/rsei/temp/EJS/v238/WaterMicrodataForEJS_v238.zip` is 663633470 bytes, dated 2021-01-22. `NHDMicroResults_concEJScreen_stata_format..zip` in that directory is 646748009 bytes, dated 2021-05-01. The RSEI results page `https://www.epa.gov/rsei/ways-get-rsei-results` links the same current and version 2.3.11 FTP trees. None of those other files was scored.

## Toxic releases to air

Publisher: U.S. EPA, Office of Pollution Prevention and Toxics, 2021 RSEI modeled results. The version 2.3 technical documentation names a May 16, 2023 polygon feature class already aggregated from RSEI grid cells to block groups and island areas. The scored file is that delivery.

The file is `https://gaftp.epa.gov/rsei/temp/EJS/v2311_air/EJ_Census2020_BG_Air_Indicator_GIS_File.zip`. HTTP 200 on 2026-10-28, content-length 949977650, last-modified 2023-05-16 17:29:36 GMT. The downloaded zip is 949977650 bytes. Layer `EJ_Census2020_BG_Air_Indicator` in `Geodatabase/EJ_Census2020_BG_Air_Indicator.gdb` is a multipolygon, 242747 features, fields `BGID` and `TOXCONC`. Zip members are dated 2023-05-12. The toxicity field is `TOXCONC`. Loaded as `raw.rsei_air_toxconc_20230516`. The block-group score is `staging.tier3_rsei_air_20230516`, which assigns `TOXCONC` by matching `BGID` to the Harvard 12-digit id. On 243022 Harvard rows, both values are present for 238981 and both are positive for 236965. The positive-row median ratio is 1 and Pearson is 1.0000000000000002. The score was kept. See `docs/assumptions.md`.

The version 2.3.11 aggregated air grid dated 2023-03-16 is not that polygon and was not scored for this indicator. Directory `https://gaftp.epa.gov/rsei/Older_Versions/Version2311_RY2021/Aggregated_Grid_Cell_Data/`. `aggmicro2021_2021_gc14.csv.gz` is 207769580 bytes, last-modified 2023-03-16 15:15:26 GMT. `gc24` is 3022005 bytes, `gc34` is 913431, `gc44` is 688112, `gc54` is 166383, and `gc64` is 27701, all last-modified 2023-03-16. Those files have no header and 10 numeric columns. They do not contain particulate matter 2.5. PM 2.5 remains an Office of Air Quality Planning and Standards spreadsheet that was not found. Ozone uses the OAQPS tract CSV. Diesel particulate matter uses the AirToxScreen 2020 pollutant-summary AMBCONC zips.

Sibling `https://gaftp.epa.gov/rsei/temp/EJS/v2311_air/EJ2023_AS_GU_CNMI_VI_2021_ToxConc.gdb.zip` is 293285 bytes, last-modified 2023-06-13. Layer `EJ2023_AS_GU_CNMI_VI_2021_ToxConc` has 685 features and field `TOXCONC`. It was inspected and not mixed into the May 16 score.

## Ozone

Publisher: U.S. EPA, Office of Air Quality Planning and Standards, 2020 fused monitor and CMAQ tract values. The version 2.3 technical documentation defines the indicator as the annual mean of the 10 highest daily maximum 8-hour ozone concentrations, copied to child block groups and remapped from 2020 to 2022 (pp. 16 to 17).

The file is `https://gaftp.epa.gov/Air/aqmg/RH_DataRequest/EJscreen.ozone_2020.csv`. HTTP 200 on 2026-10-28, content-length 3146380, last-modified 2023-11-06 17:50:53 GMT. Local copy: `data/ozone/EJscreen.ozone_2020.csv`, SHA256 `555a4cbeeb3871e6a63a1f9e84505a0ad1dbab160d20d4b2d1a7f983f1bad1cd`. Rows: 83776. Columns: `FIPs`, `SummerMeanO3`, `O3Top10Mean`. The scored field is `O3Top10Mean`. Tract ids are left-padded to 11 digits and assigned to each child block group. Connecticut 2022 tracts use Geocorr 2022 (`raw.geocorr_ct_2020_2022`) as above. On 243022 Harvard rows, both values are present for 238193 and both are positive for 238193. The positive-row median ratio is 1 and Pearson is 1.0000000000000002. The score was kept. See `docs/assumptions.md`.

`SummerMeanO3` in the same file is the summer seasonal average. It was compared and not kept. PM 2.5 stays unscored. The FAQSD daily ozone dumps were not used.

## Nitrogen dioxide

Publisher: NASA Health and Air Quality Applied Sciences Team (HAQAST) / Anenberg surface NO2. The version 2.3 technical documentation names 2020 block-group source data in ppb from a regression model, satellite data, and large-scale models, an approximately one-kilometer grid projected to 2020 Census block groups and aggregated by mean pixel value (pp. 14, 18 to 19).

No `EJscreen.NO2*` CSV was found under `RH_DataRequest/` (HTTP 404). GES DISC `SFC_NITROGEN_DIOXIDE_CONC` (DOI 10.5067/J99FI2U38YRN) requires Earthdata login. The scored public file is `https://ndownloader.figshare.com/files/26064350` (`2020_final_1km.tif`, figshare DOI 10.6084/m9.figshare.12968114). HTTP 200 on 2026-10-28, content-length 419315078, last-modified 2021-04-25 19:43:03 GMT. SHA256 `473bf2e9170fead07a12121e6fab3aaac8771101bbfc3cd7c0acacb1da27cf8d`. Array 43080 by 16200. Block-group polygons: `https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_bg_500k.zip`, 104212096 bytes. Assignment: mean of intersecting pixels with `all_touched`, Connecticut Geocorr 2022. On 243023 Harvard rows, both values are present for 241654 and both are positive for 241654. The positive-row median ratio is 1.0000003795016006 and Pearson is 0.9976910129436063. The score was kept. See `docs/assumptions.md`.

## Diesel particulate matter

Publisher: U.S. EPA, 2020 AirToxScreen diesel PM ambient concentrations. The version 2.3 technical documentation names a March 2024 OAQPS spreadsheet in µg/m³, with page 14 calling the source block-group level and page 19 saying tract values are repeated to child block groups (pp. 14, 19). No OAQPS `EJscreen.diesel*` CSV was found under `RH_DataRequest/` (HTTP 404).

The scored files are `DIESEL_PM10_AMBCONC_R{1-10}.zip` under `https://gaftp.epa.gov/rtrmodeling_public/AirToxScreen/2020/Pollutant%20Summaries/Region{1-10}/`. HTTP 200 on 2026-10-28. Combined content-length 172408133 bytes. Last-modified 2024-10-10 (14:30:58 to 16:10:14 GMT). Local copies: `data/diesel/`. Block rows: 5808484. Field: `Total Conc`. Block values are population-weighted to block groups. Alaska and island territories AS, GU, MP, and VI are null. Connecticut uses Geocorr 2022 (`raw.geocorr_ct_2020_2022`). On 243024 Harvard rows, both values are present for 240410 and both are positive for 240410. The positive-row median ratio is 0.9840077576952359 and Pearson is 0.9939538189404407. The score was kept. See `docs/assumptions.md`.

## Particulate matter 2.5

The version 2.3 technical documentation names a 2020 Census tract OAQPS spreadsheet, annual average PM 2.5 from monitor–CMAQ fusion (EPA-454/S-15-001), copied to child block groups and remapped from 2020 to 2022 (pp. 14 to 16). `EJscreen.pm25_2020.csv` remains HTTP 404. The score uses the public FAQSD 2020 daily fused tract file aggregated to the documented annual mean. See `docs/assumptions.md`.

Publisher: U.S. EPA OAQPS / RSIG FAQSD. File: `https://ofmpub.epa.gov/rsig/rsigserver?data/FAQSD/outputs/2020_pm25_daily_average.txt.gz`. HTTP 200 on 2026-10-29, content-length 532375506, gzip member dated 2023-08-16 00:01:13 UTC. SHA256 `d90572344dabea13a787c6544e7271a1b07ff0513a9776064aeeb5bded5059f3`. Daily rows: 30662016. Tracts: 83776, each with 366 days. Annual mean per tract: unweighted mean of `pm25_daily_average(ug/m3)`. Local annual table: `data/pm25/faqsd_2020_annual_mean.csv`. Score file: `data/pm25/pm25_scores.csv`. Assignment: tract value to child block groups; Connecticut Geocorr 2022. On 243022 Harvard rows, both values are present for 238193 and both are positive for 238193. The positive-row median ratio is 1 and Pearson is 0.9999999999725282. The score was kept.

Also checked, and not kept as the 2020 indicator:

| URL | Result |
| --- | --- |
| `https://gaftp.epa.gov/Air/aqmg/RH_DataRequest/EJscreen.pm25_2020.csv` | HTTP 404. |
| `https://ofmpub.epa.gov/rsig/rsigserver?data/FAQSD/outputs/2020_pm25_annual_average.csv` and sibling annual names | ofmpub `FAILED` body, 7 bytes. |
| `https://gaftp.epa.gov/Air/aqmg/cjang/NEXUS/2018_input_data/Fused_O3_PM25/EJscreen.pm25.csv` | HTTP 200, 2067509 bytes, last-modified 2022-06-27. Prior-year `FIPs,AnnualMeanPM25`, 72283 tracts. Positive-row median ratio 1.060360180018207, Pearson 0.852169816311898. Not kept. |
| `https://ofmpub.epa.gov/rsig/rsigserver?data/FAQSD/outputs/2020_pm25_daily_average_2010_census.txt.gz` | HTTP 200, 460519875 bytes. 2010-tract sibling; not used for the 2020-tract assignment. |

## Drinking water non-compliance

The version 2.3 technical documentation names an internal ETT violation extract for SDWIS submission year 2023 Q4 (open violations 2019 Q4–2023 Q4), scored onto ORD community water system service areas and population-weighted from blocks to block groups (pp. 27 to 29). That ETT extract remains unpublished. On 2026-10-29 the public ECHO SDWA latest zip plus ORD CWS block crosswalk were scored with the printed 10/5/1 severity tiers and year increments (no invented weights). Positive-row median ratio 1.0 and Pearson about 0.14 versus published `DWATER`; not kept. See `docs/assumptions.md` and `internal/drinking-water-echo-notes.md`.

| URL | Result |
| --- | --- |
| `https://echo.epa.gov/files/echodownloads/SDWA_latest_downloads.zip` | HTTP 200, 558010511 bytes, last-modified 2026-10-14 01:15:30 GMT. Submission quarter on all PWS rows: 2026Q3. Scored. |
| `https://github.com/USEPA/ORD_SAB_Model/raw/refs/heads/main/Version_History/PWS_Boundaries_Latest.zip` | HTTP 200, 544M. ORD SAB model version 3.0. Contains `Service_Areas_V_3_0.gpkg` and `Census_Tables/Blocks_V_3_0.csv` (4890288 block∩PWSID rows). |
| `https://services.arcgis.com/cJ9YHowT8TU7DUyn/ArcGIS/rest/services/Water_System_Boundaries/FeatureServer/0` | HTTP 200. 44615 CWS polygons, `dataLastEditDate` 2026-05-29. Same product family as the zip. |
| `https://echo.epa.gov/files/echodownloads/SDWA_system_search_download.zip` | HTTP 200, 34972222 bytes, last-modified 2026-10-23. Not used. |
| `https://echo.epa.gov/files/echodownloads/SDWA_downloads.zip` | HTTP 200, 155227022 bytes, last-modified 2022-01-14. Not used. |
| Envirofacts `SDW_VIOL_ENFORCEMENT` | Live query API. Not used. |
| `https://gaftp.epa.gov/EJScreen/` | HTTP 404. |

Local comparison artifact: `data/dwater/dwater_comparison.json`.

## Underground storage tanks (UST) and leaking UST (LUST)

The version 2.3 technical documentation names ORD / OUST scores supplied March 5, 2024 at 2022 block group level, formula `(LUST × 7.7 + UST count) / km²` of the block group buffered by 1,500 feet (pp. 25 to 26). No March 5, 2024 block-group score table was found. The scored public inventory is UST Finder Feature Layer 2eb. See `docs/assumptions.md`.

Publisher: U.S. EPA Office of Underground Storage Tanks / Office of Research and Development (UST Finder). Service: `https://services.arcgis.com/cJ9YHowT8TU7DUyn/arcgis/rest/services/UST_Finder_Feature_Layer_2eb/FeatureServer`. Downloaded 2026-10-28. State data vintage 2018–2021; tribal data October 2025. Layer `dataLastEditDate` 2026-02-13. Facilities layer: 742844 features, Open_USTs sum 503630, TOS_USTs sum 32494. Releases layer: 530798 features (Open 70097). USTs table: 2298870 rows (not used for coordinates). Local copies: `data/ust/facilities.csv`, `data/ust/releases.csv`. Score file: `data/ust/ust_scores.csv`. Block groups: Census `cb_2022_us_bg_500k.zip`. Method: `(Open LUST × 7.7 + Open_USTs + TOS_USTs) / buffered area km²`, buffer 1,500 feet. On 243022 Harvard rows, both values are present for 241748 and both are positive for 176394. The positive-row median ratio is 1.0001488832517622 and Pearson is 0.9898386174024473. The score was kept.

Also checked on 2026-10-28, and none is a March 5, 2024 precomputed BG score: `https://gaftp.epa.gov/EJScreen/` and `https://gaftp.epa.gov/OUST/` returned HTTP 404; `https://edg.epa.gov/data/public/OUST/` returned HTTP 404; `https://edg.epa.gov/data/public/ORD/` has no UST score geodatabase; sibling services `UST_Finder_Feature_Layer_2` and `US_Underground_Storage_Tank_2019` are older UST Finder composites; FRS has no `FRS_INTERESTS_UST` / `FRS_INTERESTS_LUST` FeatureServer on the EPA GeoPlatform catalog used here.

## Inputs that are not on a public API

No further API key is required. The Census API key already used for the 2022 American Community Survey and the 2020 census counts loaded the demographic tables, the disability table, lead paint, and the block populations. Those rates match the published extract.

The RCRAInfo download endpoint serves only the current export. The February 5, 2024 handler file named in the technical documentation is not on that API. The hazardous-waste score uses the export dated 2026-10-18. The Google Drive file checked on 2026-10-28 is the October 25, 2026 handler zip, not the February 5, 2024 pair, and that score was not kept. The February 5, 2024 file is still required.

The February 5, 2024 FRS active-RMP extract named in the technical documentation is not on the public ArcGIS RMP interest service or the current FRS geospatial downloads. The RMP proximity test used the layer dated 2026-10-26 and was not kept. See the RMP section above.

The February 2024 wastewater flowline geodatabase named in the technical documentation is not on the public RSEI FTP. The score uses the December 27, 2023 polyline in `v2311_water`. See the wastewater section above.

The March 16, 2023 RSEI version 2.3.11 air grid is not the May 16, 2023 polygon named for toxic releases to air, and it does not contain particulate matter 2.5. Toxic releases to air uses the May 16 polygon and field `TOXCONC`. See the toxic-releases section above.

The named 2020 OAQPS PM 2.5 tract spreadsheet `EJscreen.pm25_2020.csv` is not on the AQMG FTP path that holds `EJscreen.ozone_2020.csv`. The PM 2.5 score uses the public FAQSD 2020 daily fused tract file aggregated to the documented annual mean instead. See the particulate-matter section above.

The March 2024 OAQPS diesel spreadsheet named in the technical documentation is not under `RH_DataRequest/` as an `EJscreen.diesel*` CSV. The diesel score uses the public AirToxScreen 2020 `DIESEL_PM10_AMBCONC` pollutant-summary zips instead. See the diesel section above.

The HAQAST NO2 block-group extract is not published as an `EJscreen.NO2*` CSV. The GES DISC NetCDF requires Earthdata login. The NO2 score uses the public figshare `2020_final_1km.tif` surface grid instead. See the nitrogen dioxide section above.

The internal ETT 2023 Q4 drinking-water violation extract named in the technical documentation is not public. ECHO SDWA latest (2026Q3) plus ORD CWS block crosswalk were scored with the printed severity formula on 2026-10-29 and were not kept (positive-row median ratio 1.0, Pearson about 0.14). See the drinking-water section above.

The March 5, 2024 ORD/OUST block-group UST score table named in the technical documentation is not on EJScreen FTP, OUST FTP, or ORD EDG. The UST score uses the public UST Finder Feature Layer 2eb inventory instead. See the underground storage tanks section above.

The February 26, 2024 Superfund boundary extract is not on the public feature service. The score uses the current service. A May 20, 2024 archive of the same boundaries was scored and set aside. See `docs/assumptions.md`.

No Census, NCHS, or NHGIS page publishes a 2010 to 2015 tract relationship file. `US_A.CSV` is already keyed by 2010 tract ids. An IPUMS login does not add that year pair: the NHGIS catalog has no `nhgis_tr2010_tr2015` file.
