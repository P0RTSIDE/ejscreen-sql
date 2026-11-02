# EJScreen 2024 reference profile

Counts, minima, and maxima from the loaded Postgres tables for the Harvard Dataverse EJScreen 2024 block group extracts. This profile describes the reference inputs, not the rebuilt scores. Match rates are in [`docs/validation_report.md`](validation_report.md).

## Files loaded

| Role | File | Bytes | Columns | Rows | SHA256 |
| --- | --- | --- | --- | --- | --- |
| national_csv | EJSCREEN_2024_BG_with_AS_CNMI_GU_VI.csv | 436936720 | 231 | 243022 | 641aa12598809379be417b43c917b397623ad7ac8fbe497aed9597464214cdd5 |
| state_csv | EJSCREEN_2024_BG_StatePct_with_AS_CNMI_GU_VI.csv | 428393381 | 229 | 243022 | 13a49a9dec368ccb10fd3612db83931f01494ccbf91981d6bdd8340642c81cc7 |

## Universe

Total rows: 243022.
States, the District of Columbia, and Puerto Rico: 242336.
Island territory place and estate records: 686.
The tech doc count of 242,336 block groups for the states, the District of Columbia, and Puerto Rico matches this extract.

Source id lengths:

| Length | Rows |
| --- | --- |
| 7 | 270 |
| 10 | 416 |
| 12 | 242336 |

Rows by area. Demographic index nulls are the rebuilt national Demographic Index.

| Area | Rows | Population null | PM2.5 null | Demographic Index null |
| --- | --- | --- | --- | --- |
| AK | 504 | 0 | 504 | 0 |
| AL | 3925 | 0 | 0 | 0 |
| AR | 2294 | 0 | 0 | 0 |
| AS | 77 | 77 | 77 | 77 |
| AZ | 4773 | 0 | 0 | 0 |
| CA | 25607 | 0 | 0 | 0 |
| CO | 4058 | 0 | 0 | 0 |
| CT | 2717 | 0 | 0 | 0 |
| DC | 571 | 0 | 0 | 0 |
| DE | 706 | 0 | 0 | 0 |
| FL | 13388 | 0 | 0 | 0 |
| GA | 7446 | 0 | 0 | 0 |
| GU | 58 | 58 | 58 | 58 |
| HI | 1083 | 0 | 1083 | 0 |
| IA | 2703 | 0 | 0 | 0 |
| ID | 1284 | 0 | 0 | 0 |
| IL | 9898 | 0 | 0 | 0 |
| IN | 5290 | 0 | 0 | 0 |
| KS | 2461 | 0 | 0 | 0 |
| KY | 3581 | 0 | 0 | 0 |
| LA | 4294 | 0 | 0 | 0 |
| MA | 5116 | 0 | 0 | 0 |
| MD | 4079 | 0 | 0 | 0 |
| ME | 1184 | 0 | 0 | 0 |
| MI | 8386 | 0 | 0 | 0 |
| MN | 4706 | 0 | 0 | 0 |
| MO | 5031 | 0 | 0 | 0 |
| MP | 135 | 135 | 135 | 135 |
| MS | 2445 | 0 | 0 | 0 |
| MT | 900 | 0 | 0 | 0 |
| NC | 7111 | 0 | 0 | 0 |
| ND | 632 | 0 | 0 | 0 |
| NE | 1648 | 0 | 0 | 0 |
| NH | 997 | 0 | 0 | 0 |
| NJ | 6599 | 0 | 0 | 0 |
| NM | 1614 | 0 | 0 | 0 |
| NV | 1963 | 0 | 0 | 0 |
| NY | 16070 | 0 | 0 | 0 |
| OH | 9472 | 0 | 0 | 0 |
| OK | 3374 | 0 | 0 | 0 |
| OR | 2970 | 0 | 0 | 0 |
| PA | 10173 | 0 | 0 | 0 |
| PR | 2555 | 0 | 2555 | 0 |
| RI | 792 | 0 | 0 | 0 |
| SC | 3408 | 0 | 0 | 0 |
| SD | 694 | 0 | 0 | 0 |
| TN | 4562 | 0 | 0 | 0 |
| TX | 18638 | 0 | 0 | 0 |
| UT | 2020 | 0 | 0 | 0 |
| VA | 5963 | 0 | 0 | 0 |
| VI | 416 | 416 | 416 | 416 |
| VT | 552 | 0 | 0 | 0 |
| WA | 5311 | 0 | 0 | 0 |
| WI | 4692 | 0 | 0 | 0 |
| WV | 1639 | 0 | 0 | 0 |
| WY | 457 | 0 | 0 | 0 |

## National extract columns

| Column | Workbook description | Nulls | Minimum | Maximum |
| --- | --- | --- | --- | --- |
| ACSDISABBAS | Disability base--civilian non-institutionalized population | 686 | 0 | 20778 |
| ACSEDUCBAS | Population 25 years and over | 686 | 0 | 12490 |
| ACSIPOVBAS | Population for whom poverty status is determined | 686 | 0 | 21535 |
| ACSTOTHH | Households (for limited English speaking) | 686 | 0 | 6887 |
| ACSTOTHU | Housing units (for % built pre-1960) | 686 | 0 | 8043 |
| ACSTOTPOP | Total population | 686 | 0 | 38907 |
| ACSUNEMPBAS | Unemployment base--persons in civilian labor force (unemployment rate) | 686 | 0 | 30910 |
| AREALAND | Land area in square meters | 686 | 0 | 158399813712 |
| AREAWATER | Water area in square meters | 686 | 0 | 25989695209 |
| B_D2_DSLPM | Map color bin for  Diesel particulate matter EJ Index | 2584 | 1 | 11 |
| B_D2_DWATER | Map color bin for Drinking Water Non-Compliance EJ Index | 19894 | 1 | 11 |
| B_D2_LDPNT | Map color bin for Lead paint EJ Index | 686 | 1 | 11 |
| B_D2_NO2 | Map color bin for Nitrogen Dioxide (NO2) EJ Index | 1318 | 1 | 11 |
| B_D2_OZONE | Map color bin for Ozone EJ Index | 4828 | 1 | 11 |
| B_D2_PM25 | Map color bin for Particulate Matter 2.5 EJ Index | 4828 | 1 | 11 |
| B_D2_PNPL | Map color bin for Superfund proximity EJ Index | 2079 | 1 | 11 |
| B_D2_PRMP | Map color bin for RMP Facility Proximity EJ Index | 2079 | 1 | 11 |
| B_D2_PTRAF | Map color bin for Traffic proximity EJ Index | 2079 | 1 | 11 |
| B_D2_PTSDF | Map color bin for Hazardous waste proximity EJ Index | 2079 | 1 | 11 |
| B_D2_PWDIS | Map color bin for Wastewater discharge EJ Index | 2583 | 1 | 11 |
| B_D2_RSEI_AIR | Map color bin for Toxic Releases to Air EJ Index | 1330 | 1 | 11 |
| B_D2_UST | Map color bin for Underground storage tanks EJ Index | 1246 | 1 | 11 |
| B_D5_DSLPM | Map color bin for  Diesel particulate matter Supplemental Index | 2584 | 1 | 11 |
| B_D5_DWATER | Map color bin for Drinking Water Non-Compliance Supplemental Index | 19894 | 1 | 11 |
| B_D5_LDPNT | Map color bin for Lead paint Supplemental Index | 686 | 1 | 11 |
| B_D5_NO2 | Map color bin for Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 1 | 11 |
| B_D5_OZONE | Map color bin for Ozone Supplemental Index | 4828 | 1 | 11 |
| B_D5_PM25 | Map color bin for Particulate Matter 2.5 Supplemental Index | 4828 | 1 | 11 |
| B_D5_PNPL | Map color bin for Superfund proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PRMP | Map color bin for RMP Facility Proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PTRAF | Map color bin for Traffic proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PTSDF | Map color bin for Hazardous waste proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PWDIS | Map color bin for Wastewater discharge Supplemental Index | 2583 | 1 | 11 |
| B_D5_RSEI_AIR | Map color bin for Toxic Releases to Air Supplemental Index | 1330 | 1 | 11 |
| B_D5_UST | Map color bin for Underground storage tanks Supplemental Index | 1246 | 1 | 11 |
| B_DEMOGIDX_2 | Map color bin for Demographic Index | 686 | 1 | 11 |
| B_DEMOGIDX_5 | Map color bin for Supplemental Demographic Index | 686 | 1 | 11 |
| B_DISABILITYPCT | Map color bin for % persons with disabilities | 686 | 1 | 11 |
| B_DSLPM | Map color bin for  Diesel particulate matter | 2584 | 1 | 11 |
| B_DWATER | Map color bin for Drinking Water Non-Compliance | 19894 | 1 | 11 |
| B_LDPNT | Map color bin for Lead paint | 686 | 1 | 11 |
| B_LESSHSPCT | Map color bin for % less than high school education | 686 | 1 | 11 |
| B_LIFEEXPPCT | Map color bin for Low Life Expectancy | 18092 | 1 | 11 |
| B_LINGISOPCT | Map color bin for % limited English speaking | 686 | 1 | 11 |
| B_LOWINCPCT | Map color bin for % low income | 686 | 1 | 11 |
| B_NO2 | Map color bin for Nitrogen Dioxide (NO2) | 1318 | 1 | 11 |
| B_OVER64PCT | Map color bin for % over age 64 | 686 | 1 | 11 |
| B_OZONE | Map color bin for Ozone | 4828 | 1 | 11 |
| B_PEOPCOLORPCT | Map color bin for % people of color | 686 | 1 | 11 |
| B_PM25 | Map color bin for Particulate Matter 2.5 | 4828 | 1 | 11 |
| B_PNPL | Map color bin for Superfund proximity | 2079 | 1 | 11 |
| B_PRMP | Map color bin for RMP facility proximity | 2079 | 1 | 11 |
| B_PTRAF | Map color bin for Traffic proximity | 2079 | 1 | 11 |
| B_PTSDF | Map color bin for Hazardous waste proximity | 2079 | 1 | 11 |
| B_PWDIS | Map color bin for Wastewater discharge | 2583 | 1 | 11 |
| B_RSEI_AIR | Map color bin for Toxic Releases to Air | 1330 | 1 | 11 |
| B_UNDER5PCT | Map color bin for % under age 5 | 686 | 1 | 11 |
| B_UNEMPPCT | Map color bin for % unemployed | 1110 | 1 | 11 |
| B_UST | Map color bin for Underground storage tanks | 1246 | 1 | 11 |
| CNTY_NAME | County Name | 0 | Abbeville County | Ziebach County |
| D2_DSLPM | Diesel particulate matter EJ Index | 2584 | 0 | 389.0573171573667 |
| D2_DWATER | Drinking Water Non-Compliance EJ Index | 19894 | 0 | 385.1274452668883 |
| D2_LDPNT | Lead paint EJ Index | 686 | 0 | 392.98718904784516 |
| D2_NO2 | Nitrogen Dioxide (NO2) EJ Index | 1318 | 0 | 389.0573171573667 |
| D2_OZONE | Ozone EJ Index | 4828 | 0 | 389.0573171573667 |
| D2_PM25 | Particulate Matter 2.5 EJ Index | 4828 | 0 | 383.0785948777972 |
| D2_PNPL | Superfund Proximity EJ Index | 2079 | 0 | 389.0573171573667 |
| D2_PRMP | RMP Facility Proximity EJ Index | 2079 | 0 | 389.0573171573667 |
| D2_PTRAF | Traffic proximity EJ Index | 2079 | 0 | 389.0573171573667 |
| D2_PTSDF | Hazardous waste proximity EJ Index | 2079 | 0 | 385.1274452668883 |
| D2_PWDIS | Wastewater discharge EJ Index | 2583 | 0 | 389.0573171573667 |
| D2_RSEI_AIR | Toxic Releases to Air EJ Index | 1330 | 0 | 389.0573171573667 |
| D2_UST | Underground storage tanks EJ Index | 1246 | 0 | 389.0573171573667 |
| D5_DSLPM | Diesel particulate matter Supplemental Index | 2584 | 0 | 548.046122721995 |
| D5_DWATER | Drinking Water Non-Compliance Supplemental Index | 19894 | 0 | 541.4129355974754 |
| D5_LDPNT | Lead paint Supplemental Index | 686 | 0 | 586.5278974479972 |
| D5_NO2 | Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 0 | 583.0330786992341 |
| D5_OZONE | Ozone Supplemental Index | 4828 | 0 | 550.2179393910283 |
| D5_PM25 | Particulate Matter 2.5 Supplemental Index | 4828 | 0 | 582.8344457597437 |
| D5_PNPL | Superfund Proximity Supplemental Index | 2079 | 0 | 556.0374597478016 |
| D5_PRMP | RMP Facility Proximity Supplemental Index | 2079 | 0 | 594.7615661070648 |
| D5_PTRAF | Traffic proximity Supplemental Index | 2079 | 0 | 616.3306782746715 |
| D5_PTSDF | Hazardous waste proximity Supplemental Index | 2079 | 0 | 629.7291712806426 |
| D5_PWDIS | Wastewater discharge Supplemental Index | 2583 | 0 | 573.4153315000098 |
| D5_RSEI_AIR | Toxic Releases to Air Supplemental Index | 1330 | 0 | 595.3208958435002 |
| D5_UST | Underground storage tanks Supplemental Index | 1246 | 0 | 519.7963225816859 |
| DEMOGIDX_2 | Demographic Index | 686 | 0 | 3.929871890478452 |
| DEMOGIDX_2ST | State Demographic Index | 686 | 0 | 6.613493506410364 |
| DEMOGIDX_5 | Supplemental Demographic Index | 686 | 0 | 6.69924650298556 |
| DEMOGIDX_5ST | State Supplemental Demographic Index | 686 | 0 | 7.81074827711621 |
| DISABILITY | Persons with disabilities | 686 | 0 | 1532 |
| DISABILITYPCT | % persons with disabilities | 686 | 0 | 1 |
| DSLPM | Diesel particulate matter | 2584 | 0.000559335629 | 2.979265929869924 |
| DWATER | Drinking Water Non-Compliance | 19894 | 0 | 899 |
| EXCEED_COUNT_80 | Number of EJ Indexes exceeding 80 percentile | 686 | 0 | 13 |
| EXCEED_COUNT_80_SUP | Number of Supplemental Indexes exceeding 80 percentile | 686 | 0 | 13 |
| ID | Census FIPS code for block group | 0 | 010010201001 | 7803086200 |
| LESSHS | Less than high school education | 686 | 0 | 3206 |
| LESSHSPCT | % less than high school education | 686 | 0 | 1 |
| LIFEEXPPCT | % low life expectancy | 18092 | 0 | 0.416410256410256 |
| LINGISO | Limited English speaking households | 686 | 0 | 1246 |
| LINGISOPCT | % Limited English speaking households | 686 | 0 | 1 |
| LOWINCOME | Low income | 686 | 0 | 8676 |
| LOWINCPCT | % low income | 686 | 0 | 1 |
| NO2 | Nitrogen Dioxide (NO2) | 1318 | 0.036833893507719 | 25.269199371337887 |
| NPL_CNT | Number of Superfund facilities in the block group | 686 | 0 | 5 |
| OVER64 | Over age 64 | 686 | 0 | 8672 |
| OVER64PCT | % over age 64 | 686 | 0 | 1 |
| OZONE | Ozone | 4828 | 38.77842 | 112.81276 |
| P_D2_DSLPM | Percentile for Diesel particulate matter EJ Index | 2584 | 0 | 100 |
| P_D2_DWATER | Percentile for Drinking Water Non-Compliance EJ Index | 19894 | 0 | 100 |
| P_D2_LDPNT | Percentile for Lead paint EJ Index | 686 | 0 | 100 |
| P_D2_NO2 | Percentile for Nitrogen Dioxide (NO2) EJ Index | 1318 | 0 | 100 |
| P_D2_OZONE | Percentile for Ozone EJ Index | 4828 | 0 | 100 |
| P_D2_PM25 | Percentile for Particulate Matter 2.5 EJ Index | 4828 | 0 | 100 |
| P_D2_PNPL | Percentile for Superfund proximity EJ Index | 2079 | 0 | 100 |
| P_D2_PRMP | Percentile for RMP Facility Proximity EJ Index | 2079 | 0 | 100 |
| P_D2_PTRAF | Percentile for Traffic proximity EJ Index | 2079 | 0 | 100 |
| P_D2_PTSDF | Percentile for Hazardous waste proximity EJ Index | 2079 | 0 | 100 |
| P_D2_PWDIS | Percentile for Wastewater discharge EJ Index | 2583 | 0 | 100 |
| P_D2_RSEI_AIR | Percentile for Toxic Releases to Air EJ Index | 1330 | 0 | 100 |
| P_D2_UST | Percentile for Underground storage tanks EJ Index | 1246 | 0 | 100 |
| P_D5_DSLPM | Percentile for Diesel particulate matter Supplemental Index | 2584 | 0 | 100 |
| P_D5_DWATER | Percentile for Drinking Water Non-Compliance Supplemental Index | 19894 | 0 | 100 |
| P_D5_LDPNT | Percentile for Lead paint Supplemental Index | 686 | 0 | 100 |
| P_D5_NO2 | Percentile for Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 0 | 100 |
| P_D5_OZONE | Percentile for Ozone Supplemental Index | 4828 | 0 | 100 |
| P_D5_PM25 | Percentile for Particulate Matter 2.5 Supplemental Index | 4828 | 0 | 100 |
| P_D5_PNPL | Percentile for Superfund proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PRMP | Percentile for RMP Facility Proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PTRAF | Percentile for Traffic proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PTSDF | Percentile for Hazardous waste proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PWDIS | Percentile for Wastewater discharge Supplemental Index | 2583 | 0 | 100 |
| P_D5_RSEI_AIR | Percentile for Toxic Releases to Air Supplemental Index | 1330 | 0 | 100 |
| P_D5_UST | Percentile for Underground storage tanks Supplemental Index | 1246 | 0 | 100 |
| P_DEMOGIDX_2 | Percentile for Demographic Index | 686 | 0 | 100 |
| P_DEMOGIDX_5 | Percentile for Supplemental Demographic Index | 686 | 0 | 100 |
| P_DISABILITYPCT | Percentile for % persons with disabilities | 686 | 0 | 100 |
| P_DSLPM | Percentile for  Diesel particulate matter | 2584 | 0 | 100 |
| P_DWATER | Percentile for Drinking Water Non-Compliance | 19894 | 0 | 100 |
| PEOPCOLOR | People of color | 686 | 0 | 20706 |
| PEOPCOLORPCT | % people of color | 686 | 0 | 1 |
| P_LDPNT | Percentile for Lead paint | 686 | 0 | 100 |
| P_LESSHSPCT | Percentile for % less than high school education | 686 | 0 | 100 |
| P_LIFEEXPPCT | Percentile for Low Life Expectancy | 18092 | 0 | 100 |
| P_LINGISOPCT | Percentile for % limited English speaking | 686 | 0 | 100 |
| P_LOWINCPCT | Percentile for % low income | 686 | 0 | 100 |
| PM25 | Particulate Matter 2.5 | 4828 | 3.2885781420765 | 25.6121191256831 |
| P_NO2 | Percentile for Nitrogen Dioxide (NO2) | 1318 | 0 | 100 |
| PNPL | Superfund proximity | 2079 | 0 | 46.08231291805108 |
| P_OVER64PCT | Percentile for % over age 64 | 686 | 0 | 100 |
| P_OZONE | Percentile for Ozone | 4828 | 0 | 100 |
| P_PEOPCOLORPCT | Percentile for % people of color | 686 | 0 | 98 |
| P_PM25 | Percentile for Particulate Matter 2.5 | 4828 | 0 | 100 |
| P_PNPL | Percentile for Superfund proximity | 2079 | 0 | 100 |
| P_PRMP | Percentile for RMP facility proximity | 2079 | 0 | 100 |
| P_PTRAF | Percentile for Traffic proximity | 2079 | 0 | 100 |
| P_PTSDF | Percentile for Hazardous waste proximity | 2079 | 0 | 100 |
| P_PWDIS | Percentile for Wastewater discharge | 2583 | 0 | 100 |
| PRE1960 | Housing units built before 1960 | 686 | 0 | 1792 |
| PRE1960PCT | Lead Paint | 686 | 0 | 1 |
| PRMP | RMP facility proximity | 2079 | 0 | 18.059732219424905 |
| P_RSEI_AIR | Percentile for Toxic Releases to Air | 1330 | 0 | 100 |
| PTRAF | Traffic proximity | 2079 | 0 | 30181802.55011463 |
| PTSDF | Hazardous waste proximity | 2079 | 0 | 82.28211898556825 |
| P_UNDER5PCT | Percentile for % under age 5 | 686 | 0 | 100 |
| P_UNEMPPCT | Percentile for % unemployed | 1110 | 0 | 100 |
| P_UST | Percentile for Underground storage tanks | 1246 | 0 | 100 |
| PWDIS | Wastewater discharge | 2583 | 0 | 7709094779.014755 |
| REGION | US EPA region number | 0 | 1 | 10 |
| RSEI_AIR | Toxic Releases to Air | 1330 | 0 | 4512172.081 |
| Shape_Area | Shape area | 0 | 1.2538e-08 | 37.01564475661505 |
| Shape_Length | Shape length | 0 | 0.000458585667595 | 57.93368256967248 |
| ST_ABBREV | Two-letter abbreviation for state | 0 | AK | WY |
| STATE_NAME | Name of state | 0 | Alabama | Wyoming |
| T_D2_DSLPM | Map popup text for  Diesel particulate matter EJ Index | 2584 | 0 %ile | 9 %ile |
| T_D2_DWATER | Map popup text for Drinking Water Non-Compliance EJ Index | 19894 | 0 %ile | 99 %ile |
| T_D2_LDPNT | Map popup text for Lead paint EJ Index | 686 | 0 %ile | 99 %ile |
| T_D2_NO2 | Map popup text for Nitrogen Dioxide (NO2) EJ Index | 1318 | 0 %ile | 9 %ile |
| T_D2_OZONE | Map popup text for Ozone EJ Index | 4828 | 0 %ile | 9 %ile |
| T_D2_PM25 | Map popup text for Particulate Matter 2.5 EJ Index | 4828 | 0 %ile | 9 %ile |
| T_D2_PNPL | Map popup text for Superfund proximity EJ Index | 2079 | 0 %ile | 99 %ile |
| T_D2_PRMP | Map popup text for RMP Facility Proximity EJ Index | 2079 | 0 %ile | 99 %ile |
| T_D2_PTRAF | Map popup text for Traffic proximity EJ Index | 2079 | 0 %ile | 9 %ile |
| T_D2_PTSDF | Map popup text for Hazardous waste proximity EJ Index | 2079 | 0 %ile | 99 %ile |
| T_D2_PWDIS | Map popup text for Wastewater discharge EJ Index | 2583 | 0 %ile | 9 %ile |
| T_D2_RSEI_AIR | Map popup text for Toxic Releases to Air EJ Index | 1330 | 0 %ile | 9 %ile |
| T_D2_UST | Map popup text for Underground storage tanks EJ Index | 1246 | 0 %ile | 99 %ile |
| T_D5_DSLPM | Map popup text for  Diesel particulate matter Supplemental Index | 2584 | 0 %ile | 9 %ile |
| T_D5_DWATER | Map popup text for Drinking Water Non-Compliance Supplemental Index | 19894 | 0 %ile | 99 %ile |
| T_D5_LDPNT | Map popup text for Lead paint Supplemental Index | 686 | 0 %ile | 99 %ile |
| T_D5_NO2 | Map popup text for Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 0 %ile | 9 %ile |
| T_D5_OZONE | Map popup text for Ozone Supplemental Index | 4828 | 0 %ile | 9 %ile |
| T_D5_PM25 | Map popup text for Particulate Matter 2.5 Supplemental Index | 4828 | 0 %ile | 9 %ile |
| T_D5_PNPL | Map popup text for Superfund proximity Supplemental Index | 2079 | 0 %ile | 99 %ile |
| T_D5_PRMP | Map popup text for RMP Facility Proximity Supplemental Index | 2079 | 0 %ile | 99 %ile |
| T_D5_PTRAF | Map popup text for Traffic proximity Supplemental Index | 2079 | 0 %ile | 9 %ile |
| T_D5_PTSDF | Map popup text for Hazardous waste proximity Supplemental Index | 2079 | 0 %ile | 99 %ile |
| T_D5_PWDIS | Map popup text for Wastewater discharge Supplemental Index | 2583 | 0 %ile | 9 %ile |
| T_D5_RSEI_AIR | Map popup text for Toxic Releases to Air Supplemental Index | 1330 | 0 %ile | 9 %ile |
| T_D5_UST | Map popup text for Underground storage tanks Supplemental Index | 1246 | 0 %ile | 99 %ile |
| T_DEMOGIDX_2 | Map popup text for Demographic Index | 686 | 0 %ile | 9 %ile |
| T_DEMOGIDX_5 | Map popup text for Supplemental Demographic Index | 686 | 0 %ile | 9 %ile |
| T_DISABILITYPCT | Map popup text for % persons with disabilities | 686 | 0 %ile | 9 %ile |
| T_DSLPM | Map popup text for  Diesel particulate matter | 2584 | 0 %ile | 9 %ile |
| T_DWATER | Map popup text for Drinking Water Non-Compliance | 19894 | 0 %ile | 99 %ile |
| T_LDPNT | Map popup text for Lead paint | 686 | 0 %ile | 99 %ile |
| T_LESSHSPCT | Map popup text for % less than high school education | 686 | 0 %ile | 9 %ile |
| T_LIFEEXPPCT | Map popup text for Low Life Expectancy | 18092 | 0 %ile | 9 %ile |
| T_LINGISOPCT | Map popup text for % limited English speaking | 686 | 0 %ile | 99 %ile |
| T_LOWINCPCT | Map popup text for % low income | 686 | 0 %ile | 9 %ile |
| T_NO2 | Map popup text for Nitrogen Dioxide (NO2) | 1318 | 0 %ile | 9 %ile |
| T_OVER64PCT | Map popup text for % over age 64 | 686 | 0 %ile | 9 %ile |
| T_OZONE | Map popup text for Ozone | 4828 | 0 %ile | 9 %ile |
| T_PEOPCOLORPCT | Map popup text for % people of color | 686 | 0 %ile | 9 %ile |
| T_PM25 | Map popup text for Particulate Matter 2.5 | 4828 | 0 %ile | 9 %ile |
| T_PNPL | Map popup text for Superfund proximity | 2079 | 0 %ile | 99 %ile |
| T_PRMP | Map popup text for RMP facility proximity | 2079 | 0 %ile | 99 %ile |
| T_PTRAF | Map popup text for Traffic proximity | 2079 | 0 %ile | 9 %ile |
| T_PTSDF | Map popup text for Hazardous waste proximity | 2079 | 0 %ile | 99 %ile |
| T_PWDIS | Map popup text for Wastewater discharge | 2583 | 0 %ile | 9 %ile |
| T_RSEI_AIR | Map popup text for Toxic Releases to Air | 1330 | 0 %ile | 9 %ile |
| TSDF_CNT | Number of Hazardous waste facilities in the block group | 686 | 0 | 33 |
| T_UNDER5PCT | Map popup text for % under age 5 | 686 | 0 %ile | 99 %ile |
| T_UNEMPPCT | Map popup text for % unemployed | 1110 | 0 %ile | 99 %ile |
| T_UST | Map popup text for Underground storage tanks | 1246 | 0 %ile | 99 %ile |
| UNDER5 | Under age 5 | 686 | 0 | 3732 |
| UNDER5PCT | % under age 5 | 686 | 0 | 0.574468085106383 |
| UNEMPLOYED | Unemployed in civilian labor force | 686 | 0 | 978 |
| UNEMPPCT | % unemployed | 1110 | 0 | 1 |
| UST | Underground storage tanks | 1246 | 0 | 137.87167060186903 |

## State percentile extract columns

| Column | Workbook description | Nulls | Minimum | Maximum |
| --- | --- | --- | --- | --- |
| ACSDISABBAS | Disability base--civilian non-institutionalized population | 686 | 0 | 20778 |
| ACSEDUCBAS | Population 25 years and over | 7 | 0 | 12490 |
| ACSIPOVBAS | Population for whom poverty status is determined | 7 | 0 | 21535 |
| ACSTOTHH | Households (for limited English speaking) | 7 | 0 | 6949 |
| ACSTOTHU | Housing units (for % built pre-1960) | 7 | 0 | 8043 |
| ACSTOTPOP | Total population | 1 | 0 | 38907 |
| ACSUNEMPBAS | Unemployment base--persons in civilian labor force (unemployment rate) | 7 | 0 | 30910 |
| AREALAND | Land area in square meters | 1 | 0 | 158399813712 |
| AREAWATER | Water area in square meters | 1 | 0 | 25989695209 |
| B_D2_DSLPM | Map color bin for  Diesel particulate matter EJ Index | 2584 | 1 | 11 |
| B_D2_DWATER | Map color bin for Drinking Water Non-Compliance EJ Index | 19894 | 1 | 11 |
| B_D2_LDPNT | Map color bin for Lead paint EJ Index | 7 | 1 | 11 |
| B_D2_NO2 | Map color bin for Nitrogen Dioxide (NO2) EJ Index | 1318 | 1 | 11 |
| B_D2_OZONE | Map color bin for Ozone EJ Index | 4828 | 1 | 11 |
| B_D2_PM25 | Map color bin for Particulate Matter 2.5 EJ Index | 4828 | 1 | 11 |
| B_D2_PNPL | Map color bin for Superfund proximity EJ Index | 1639 | 1 | 11 |
| B_D2_PRMP | Map color bin for RMP Facility Proximity EJ Index | 1639 | 1 | 11 |
| B_D2_PTRAF | Map color bin for Traffic proximity EJ Index | 2079 | 1 | 11 |
| B_D2_PTSDF | Map color bin for Hazardous waste proximity EJ Index | 1639 | 1 | 11 |
| B_D2_PWDIS | Map color bin for Wastewater discharge EJ Index | 2583 | 1 | 11 |
| B_D2_RSEI_AIR | Map color bin for Toxic Releases to Air EJ Index | 651 | 1 | 11 |
| B_D2_UST | Map color bin for Underground storage tanks EJ Index | 567 | 1 | 11 |
| B_D5_DSLPM | Map color bin for  Diesel particulate matter Supplemental Index | 2584 | 1 | 11 |
| B_D5_DWATER | Map color bin for Drinking Water Non-Compliance Supplemental Index | 19894 | 1 | 11 |
| B_D5_LDPNT | Map color bin for Lead paint Supplemental Index | 686 | 1 | 11 |
| B_D5_NO2 | Map color bin for Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 1 | 11 |
| B_D5_OZONE | Map color bin for Ozone Supplemental Index | 4828 | 1 | 11 |
| B_D5_PM25 | Map color bin for Particulate Matter 2.5 Supplemental Index | 4828 | 1 | 11 |
| B_D5_PNPL | Map color bin for Superfund proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PRMP | Map color bin for RMP Facility Proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PTRAF | Map color bin for Traffic proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PTSDF | Map color bin for Hazardous waste proximity Supplemental Index | 2079 | 1 | 11 |
| B_D5_PWDIS | Map color bin for Wastewater discharge Supplemental Index | 2583 | 1 | 11 |
| B_D5_RSEI_AIR | Map color bin for Toxic Releases to Air Supplemental Index | 1330 | 1 | 11 |
| B_D5_UST | Map color bin for Underground storage tanks Supplemental Index | 1246 | 1 | 11 |
| B_DEMOGIDX_2 | Map color bin for Demographic Index | 7 | 1 | 11 |
| B_DEMOGIDX_5 | Map color bin for Supplemental Demographic Index | 686 | 1 | 11 |
| B_DISABILITYPCT | Map color bin for % persons with disabilities | 686 | 1 | 11 |
| B_DSLPM | Map color bin for  Diesel particulate matter | 2584 | 1 | 11 |
| B_DWATER | Map color bin for Drinking Water Non-Compliance | 19894 | 1 | 11 |
| B_LDPNT | Map color bin for Lead paint | 7 | 1 | 11 |
| B_LESSHSPCT | Map color bin for % less than high school education | 7 | 1 | 11 |
| B_LIFEEXPPCT | Map color bin for Low Life Expectancy | 18092 | 1 | 11 |
| B_LINGISOPCT | Map color bin for % limited English speaking | 7 | 1 | 11 |
| B_LOWINCPCT | Map color bin for % low income | 7 | 1 | 11 |
| B_NO2 | Map color bin for Nitrogen Dioxide (NO2) | 1318 | 1 | 11 |
| B_OVER64PCT | Map color bin for % over age 64 | 1 | 1 | 11 |
| B_OZONE | Map color bin for Ozone | 4828 | 1 | 11 |
| B_PEOPCOLORPCT | Map color bin for % people of color | 1 | 1 | 11 |
| B_PM25 | Map color bin for Particulate Matter 2.5 | 4828 | 1 | 11 |
| B_PNPL | Map color bin for Superfund proximity | 1633 | 1 | 11 |
| B_PRMP | Map color bin for RMP facility proximity | 1633 | 1 | 11 |
| B_PTRAF | Map color bin for Traffic proximity | 2079 | 1 | 11 |
| B_PTSDF | Map color bin for Hazardous waste proximity | 1633 | 1 | 11 |
| B_PWDIS | Map color bin for Wastewater discharge | 2583 | 1 | 11 |
| B_RSEI_AIR | Map color bin for Toxic Releases to Air | 645 | 1 | 11 |
| B_UNDER5PCT | Map color bin for % under age 5 | 1 | 1 | 11 |
| B_UNEMPPCT | Map color bin for % unemployed | 431 | 1 | 11 |
| B_UST | Map color bin for Underground storage tanks | 561 | 1 | 11 |
| CNTY_NAME | County Name | 0 | Abbeville County | Ziebach County |
| D2_DSLPM | Diesel particulate matter EJ Index | 2584 | 0 | 575.7237962179322 |
| D2_DWATER | Drinking Water Non-Compliance EJ Index | 19894 | 0 | 493.3735487672049 |
| D2_LDPNT | Lead paint EJ Index | 7 | 0 | 597.5057658899185 |
| D2_NO2 | Nitrogen Dioxide (NO2) EJ Index | 1318 | 0 | 647.6892707451736 |
| D2_OZONE | Ozone EJ Index | 4828 | 0 | 453.4210084009232 |
| D2_PM25 | Particulate Matter 2.5 EJ Index | 4828 | 0 | 518.6631551827692 |
| D2_PNPL | Superfund Proximity EJ Index | 1639 | 0 | 528.409782935418 |
| D2_PRMP | RMP Facility Proximity EJ Index | 1639 | 0 | 543.0122168873678 |
| D2_PTRAF | Traffic proximity EJ Index | 2079 | 0 | 582.2661120840451 |
| D2_PTSDF | Hazardous waste proximity EJ Index | 1639 | 0 | 595.3507438162708 |
| D2_PWDIS | Wastewater discharge EJ Index | 2583 | 0 | 514.82982634177 |
| D2_RSEI_AIR | Toxic Releases to Air EJ Index | 651 | 0 | 594.9185571598326 |
| D2_UST | Underground storage tanks EJ Index | 567 | 0 | 628.0623231468351 |
| D5_DSLPM | Diesel particulate matter Supplemental Index | 2584 | 0 | 716.0499472545921 |
| D5_DWATER | Drinking Water Non-Compliance Supplemental Index | 19894 | 0 | 612.2981180664476 |
| D5_LDPNT | Lead paint Supplemental Index | 686 | 0 | 721.8765508284778 |
| D5_NO2 | Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 0 | 749.8318346031562 |
| D5_OZONE | Ozone Supplemental Index | 4828 | 0 | 632.5615836463112 |
| D5_PM25 | Particulate Matter 2.5 Supplemental Index | 4828 | 0 | 718.5888414946913 |
| D5_PNPL | Superfund Proximity Supplemental Index | 2079 | 0 | 749.8318346031562 |
| D5_PRMP | RMP Facility Proximity Supplemental Index | 2079 | 0 | 658.9107387328278 |
| D5_PTRAF | Traffic proximity Supplemental Index | 2079 | 0 | 716.0499472545921 |
| D5_PTSDF | Hazardous waste proximity Supplemental Index | 2079 | 0 | 716.0499472545921 |
| D5_PWDIS | Wastewater discharge Supplemental Index | 2583 | 0 | 695.1565966633427 |
| D5_RSEI_AIR | Toxic Releases to Air Supplemental Index | 1330 | 0 | 677.0008633629768 |
| D5_UST | Underground storage tanks Supplemental Index | 1246 | 0 | 718.5888414946913 |
| DEMOGIDX_2 | Demographic Index | 7 | 0 | 7.310874427527117 |
| DEMOGIDX_5 | Supplemental Demographic Index | 686 | 0 | 7.81074827711621 |
| DISABILITY | Persons with disabilities | 686 | 0 | 1532 |
| DISABILITYPCT | % persons with disabilities | 686 | 0 | 1 |
| DSLPM | Diesel particulate matter | 2584 | 0.000559335629 | 2.979265929869924 |
| DWATER | Drinking Water Non-Compliance | 19894 | 0 | 899 |
| EXCEED_COUNT_80 | Number of EJ Indexes exceeding 80 percentile | 0 | 0 | 13 |
| EXCEED_COUNT_80_SUP | Number of Supplemental Indexes exceeding 80 percentile | 686 | 0 | 13 |
| ID | Census FIPS code for block group | 0 | 010010201001 | 7803086200 |
| LESSHS | Less than high school education | 7 | 0 | 3206 |
| LESSHSPCT | % less than high school education | 7 | 0 | 1 |
| LIFEEXPPCT | % low life expectancy | 18092 | 0 | 0.416410256410256 |
| LINGISO | Limited English speaking households | 7 | 0 | 3475 |
| LINGISOPCT | % Limited English speaking households | 7 | 0 | 1 |
| LOWINCOME | Low income | 7 | 0 | 8676 |
| LOWINCPCT | % low income | 7 | 0 | 1 |
| NO2 | Nitrogen Dioxide (NO2) | 1318 | 0.036833893507719 | 25.269199371337887 |
| NPL_CNT | Number of Superfund facilities in the block group | 676 | 0 | 5 |
| OVER64 | Over age 64 | 1 | 0 | 8672 |
| OVER64PCT | % over age 64 | 1 | 0 | 1 |
| OZONE | Ozone | 4828 | 38.77842 | 112.81276 |
| P_D2_DSLPM | Percentile for Diesel particulate matter EJ Index | 2584 | 0 | 100 |
| P_D2_DWATER | Percentile for Drinking Water Non-Compliance EJ Index | 19894 | 0 | 100 |
| P_D2_LDPNT | Percentile for Lead paint EJ Index | 7 | 0 | 100 |
| P_D2_NO2 | Percentile for Nitrogen Dioxide (NO2) EJ Index | 1318 | 0 | 100 |
| P_D2_OZONE | Percentile for Ozone EJ Index | 4828 | 0 | 100 |
| P_D2_PM25 | Percentile for Particulate Matter 2.5 EJ Index | 4828 | 0 | 100 |
| P_D2_PNPL | Percentile for Superfund proximity EJ Index | 1639 | 0 | 100 |
| P_D2_PRMP | Percentile for RMP Facility Proximity EJ Index | 1639 | 0 | 100 |
| P_D2_PTRAF | Percentile for Traffic proximity EJ Index | 2079 | 0 | 100 |
| P_D2_PTSDF | Percentile for Hazardous waste proximity EJ Index | 1639 | 0 | 100 |
| P_D2_PWDIS | Percentile for Wastewater discharge EJ Index | 2583 | 0 | 100 |
| P_D2_RSEI_AIR | Percentile for Toxic Releases to Air EJ Index | 651 | 0 | 100 |
| P_D2_UST | Percentile for Underground storage tanks EJ Index | 567 | 0 | 100 |
| P_D5_DSLPM | Percentile for Diesel particulate matter Supplemental Index | 2584 | 0 | 100 |
| P_D5_DWATER | Percentile for Drinking Water Non-Compliance Supplemental Index | 19894 | 0 | 100 |
| P_D5_LDPNT | Percentile for Lead paint Supplemental Index | 686 | 0 | 100 |
| P_D5_NO2 | Percentile for Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 0 | 100 |
| P_D5_OZONE | Percentile for Ozone Supplemental Index | 4828 | 0 | 100 |
| P_D5_PM25 | Percentile for Particulate Matter 2.5 Supplemental Index | 4828 | 0 | 100 |
| P_D5_PNPL | Percentile for Superfund proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PRMP | Percentile for RMP Facility Proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PTRAF | Percentile for Traffic proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PTSDF | Percentile for Hazardous waste proximity Supplemental Index | 2079 | 0 | 100 |
| P_D5_PWDIS | Percentile for Wastewater discharge Supplemental Index | 2583 | 0 | 100 |
| P_D5_RSEI_AIR | Percentile for Toxic Releases to Air Supplemental Index | 1330 | 0 | 100 |
| P_D5_UST | Percentile for Underground storage tanks Supplemental Index | 1246 | 0 | 100 |
| P_DEMOGIDX_2 | Percentile for Demographic Index | 7 | 0 | 100 |
| P_DEMOGIDX_5 | Percentile for Supplemental Demographic Index | 686 | 0 | 100 |
| P_DISABILITYPCT | Percentile for % persons with disabilities | 686 | 0 | 100 |
| P_DSLPM | Percentile for  Diesel particulate matter | 2584 | 0 | 100 |
| P_DWATER | Percentile for Drinking Water Non-Compliance | 19894 | 0 | 100 |
| PEOPCOLOR | People of color | 1 | 0 | 20706 |
| PEOPCOLORPCT | % people of color | 1 | 0 | 1 |
| P_LDPNT | Percentile for Lead paint | 7 | 0 | 100 |
| P_LESSHSPCT | Percentile for % less than high school education | 7 | 0 | 100 |
| P_LIFEEXPPCT | Percentile for Low Life Expectancy | 18092 | 0 | 100 |
| P_LINGISOPCT | Percentile for % limited English speaking | 7 | 0 | 100 |
| P_LOWINCPCT | Percentile for % low income | 7 | 0 | 100 |
| PM25 | Particulate Matter 2.5 | 4828 | 3.2885781420765 | 25.6121191256831 |
| P_NO2 | Percentile for Nitrogen Dioxide (NO2) | 1318 | 0 | 100 |
| PNPL | Superfund proximity | 1633 | 0 | 46.08231291805108 |
| P_OVER64PCT | Percentile for % over age 64 | 1 | 0 | 100 |
| P_OZONE | Percentile for Ozone | 4828 | 0 | 100 |
| P_PEOPCOLORPCT | Percentile for % people of color | 1 | 0 | 100 |
| P_PM25 | Percentile for Particulate Matter 2.5 | 4828 | 0 | 100 |
| P_PNPL | Percentile for Superfund proximity | 1633 | 0 | 100 |
| P_PRMP | Percentile for RMP facility proximity | 1633 | 0 | 100 |
| P_PTRAF | Percentile for Traffic proximity | 2079 | 0 | 100 |
| P_PTSDF | Percentile for Hazardous waste proximity | 1633 | 0 | 100 |
| P_PWDIS | Percentile for Wastewater discharge | 2583 | 0 | 100 |
| PRE1960 | Housing units built before 1960 | 7 | 0 | 1792 |
| PRE1960PCT | Lead Paint | 7 | 0 | 1 |
| PRMP | RMP facility proximity | 1633 | 0 | 18.059732219424905 |
| P_RSEI_AIR | Percentile for Toxic Releases to Air | 645 | 0 | 100 |
| PTRAF | Traffic proximity | 2079 | 0 | 30181802.55011463 |
| PTSDF | Hazardous waste proximity | 1633 | 0 | 82.28211898556825 |
| P_UNDER5PCT | Percentile for % under age 5 | 1 | 0 | 100 |
| P_UNEMPPCT | Percentile for % unemployed | 431 | 0 | 100 |
| P_UST | Percentile for Underground storage tanks | 561 | 0 | 100 |
| PWDIS | Wastewater discharge | 2583 | 0 | 7709094779.014755 |
| REGION | US EPA region number | 0 | 1 | 10 |
| RSEI_AIR | Toxic Releases to Air | 645 | 0 | 4512172.081 |
| Shape_Area | Shape area | 0 | 1.2538e-08 | 37.01564475661505 |
| Shape_Length | Shape length | 0 | 0.000458585667595 | 57.93368256967248 |
| ST_ABBREV | Two-letter abbreviation for state | 0 | AK | WY |
| STATE_NAME | Name of state | 0 | Alabama | Wyoming |
| T_D2_DSLPM | Map popup text for  Diesel particulate matter EJ Index | 2584 | 0 %ile | 9 %ile |
| T_D2_DWATER | Map popup text for Drinking Water Non-Compliance EJ Index | 19894 | 0 %ile | 99 %ile |
| T_D2_LDPNT | Map popup text for Lead paint EJ Index | 7 | 0 %ile | 9 %ile |
| T_D2_NO2 | Map popup text for Nitrogen Dioxide (NO2) EJ Index | 1318 | 0 %ile | 9 %ile |
| T_D2_OZONE | Map popup text for Ozone EJ Index | 4828 | 0 %ile | 9 %ile |
| T_D2_PM25 | Map popup text for Particulate Matter 2.5 EJ Index | 4828 | 0 %ile | 9 %ile |
| T_D2_PNPL | Map popup text for Superfund proximity EJ Index | 1639 | 0 %ile | 9 %ile |
| T_D2_PRMP | Map popup text for RMP Facility Proximity EJ Index | 1639 | 0 %ile | 9 %ile |
| T_D2_PTRAF | Map popup text for Traffic proximity EJ Index | 2079 | 0 %ile | 9 %ile |
| T_D2_PTSDF | Map popup text for Hazardous waste proximity EJ Index | 1639 | 0 %ile | 9 %ile |
| T_D2_PWDIS | Map popup text for Wastewater discharge EJ Index | 2583 | 0 %ile | 9 %ile |
| T_D2_RSEI_AIR | Map popup text for Toxic Releases to Air EJ Index | 651 | 0 %ile | 9 %ile |
| T_D2_UST | Map popup text for Underground storage tanks EJ Index | 567 | 0 %ile | 9 %ile |
| T_D5_DSLPM | Map popup text for  Diesel particulate matter Supplemental Index | 2584 | 0 %ile | 9 %ile |
| T_D5_DWATER | Map popup text for Drinking Water Non-Compliance Supplemental Index | 19894 | 0 %ile | 99 %ile |
| T_D5_LDPNT | Map popup text for Lead paint Supplemental Index | 686 | 0 %ile | 9 %ile |
| T_D5_NO2 | Map popup text for Nitrogen Dioxide (NO2) Supplemental Index | 1318 | 0 %ile | 9 %ile |
| T_D5_OZONE | Map popup text for Ozone Supplemental Index | 4828 | 0 %ile | 9 %ile |
| T_D5_PM25 | Map popup text for Particulate Matter 2.5 Supplemental Index | 4828 | 0 %ile | 9 %ile |
| T_D5_PNPL | Map popup text for Superfund proximity Supplemental Index | 2079 | 0 %ile | 9 %ile |
| T_D5_PRMP | Map popup text for RMP Facility Proximity Supplemental Index | 2079 | 0 %ile | 9 %ile |
| T_D5_PTRAF | Map popup text for Traffic proximity Supplemental Index | 2079 | 0 %ile | 9 %ile |
| T_D5_PTSDF | Map popup text for Hazardous waste proximity Supplemental Index | 2079 | 0 %ile | 9 %ile |
| T_D5_PWDIS | Map popup text for Wastewater discharge Supplemental Index | 2583 | 0 %ile | 9 %ile |
| T_D5_RSEI_AIR | Map popup text for Toxic Releases to Air Supplemental Index | 1330 | 0 %ile | 9 %ile |
| T_D5_UST | Map popup text for Underground storage tanks Supplemental Index | 1246 | 0 %ile | 9 %ile |
| T_DEMOGIDX_2 | Map popup text for Demographic Index | 7 | 0 %ile | 9 %ile |
| T_DEMOGIDX_5 | Map popup text for Supplemental Demographic Index | 686 | 0 %ile | 9 %ile |
| T_DISABILITYPCT | Map popup text for % persons with disabilities | 686 | 0 %ile | 9 %ile |
| T_DSLPM | Map popup text for  Diesel particulate matter | 2584 | 0 %ile | 9 %ile |
| T_DWATER | Map popup text for Drinking Water Non-Compliance | 19894 | 0 %ile | 99 %ile |
| T_LDPNT | Map popup text for Lead paint | 7 | 0 %ile | 9 %ile |
| T_LESSHSPCT | Map popup text for % less than high school education | 7 | 0 %ile | 9 %ile |
| T_LIFEEXPPCT | Map popup text for Low Life Expectancy | 18092 | 0 %ile | 9 %ile |
| T_LINGISOPCT | Map popup text for % limited English speaking | 7 | 0 %ile | 9 %ile |
| T_LOWINCPCT | Map popup text for % low income | 7 | 0 %ile | 9 %ile |
| T_NO2 | Map popup text for Nitrogen Dioxide (NO2) | 1318 | 0 %ile | 9 %ile |
| T_OVER64PCT | Map popup text for % over age 64 | 1 | 0 %ile | 9 %ile |
| T_OZONE | Map popup text for Ozone | 4828 | 0 %ile | 9 %ile |
| T_PEOPCOLORPCT | Map popup text for % people of color | 1 | 0 %ile | 9 %ile |
| T_PM25 | Map popup text for Particulate Matter 2.5 | 4828 | 0 %ile | 9 %ile |
| T_PNPL | Map popup text for Superfund proximity | 1633 | 0 %ile | 9 %ile |
| T_PRMP | Map popup text for RMP facility proximity | 1633 | 0 %ile | 9 %ile |
| T_PTRAF | Map popup text for Traffic proximity | 2079 | 0 %ile | 9 %ile |
| T_PTSDF | Map popup text for Hazardous waste proximity | 1633 | 0 %ile | 9 %ile |
| T_PWDIS | Map popup text for Wastewater discharge | 2583 | 0 %ile | 9 %ile |
| T_RSEI_AIR | Map popup text for Toxic Releases to Air | 645 | 0 %ile | 9 %ile |
| TSDF_CNT | Number of Hazardous waste facilities in the block group | 680 | 0 | 33 |
| T_UNDER5PCT | Map popup text for % under age 5 | 1 | 0 %ile | 9 %ile |
| T_UNEMPPCT | Map popup text for % unemployed | 431 | 0 %ile | 9 %ile |
| T_UST | Map popup text for Underground storage tanks | 561 | 0 %ile | 9 %ile |
| UNDER5 | Under age 5 | 1 | 0 | 3732 |
| UNDER5PCT | % under age 5 | 1 | 0 | 0.574468085106383 |
| UNEMPLOYED | Unemployed in civilian labor force | 7 | 0 | 978 |
| UNEMPPCT | % unemployed | 431 | 0 | 1 |
| UST | Underground storage tanks | 561 | 0 | 378.5862105 |
