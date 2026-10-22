# PFAS in U.S. Drinking Water: Final EPA UCMR 5 Data

An analysis of the final national PFAS monitoring results from EPA's Fifth Unregulated Contaminant Monitoring Rule (UCMR 5), built in SAS with an interactive Tableau Public dashboard.

UCMR 5 was published in December 2021. Water systems collected samples from 2023 to 2025, and EPA released the final dataset in August 2026.

**Dashboard:** [PASTE YOUR TABLEAU PUBLIC LINK HERE]

![PFAS dashboard](PFAS%20Dashboard.png)

## Questions

1. How common are PFAS in U.S. public water systems?
2. Which PFAS were detected most often?
3. How many systems had PFOA or PFOS above EPA's 4.0 ppt limit, and does this differ by system size, water source, or state?

## Data

| Item | Detail |
|---|---|
| Source | U.S. EPA, UCMR 5 Occurrence Data Text Files |
| Release | Final dataset, August 2026 |
| Downloaded | October 22, 2026 |
| File used | `UCMR5_All.txt` (tab delimited, about 320 MB) |
| Monitoring period | 2023 to 2025 |
| Contaminants | 29 PFAS and lithium |

The raw data is not included in this repository because of its size. Download it from EPA's UCMR occurrence data page.

## Methods

* Imported about 2 million results into SAS with a DATA step, reading ID codes as text to keep leading zeros.
* Converted results from µg/L to ng/L (ppt). Results below the minimum reporting level were set to 0 when averaging.
* Averaged PFOA and PFOS at each sample point. A system was flagged **above benchmark** if the average at any sample point was above 4.0 ppt.
* Compared exceedance by system size and water source with chi square tests (PROC FREQ).
* Exported summary tables to CSV for Tableau.

## Quality checks

| Check | Result |
|---|---|
| Results read | 1,991,977 (all records read, no invalid data) |
| Water systems | 10,313 |
| Samples | 85,781 |
| Contaminants | 30 |
| Units | One unit (µg/L) |
| "=" sign with no value | 0 |
| "<" sign with a value | 0 |
| Unreadable dates | 0 |

**Validation against EPA:** EPA's July 2026 Data Summary (Table 4) reports 1,136 of 10,129 systems with a full set of results (11.2%) had an average above an MCL. This analysis found 1,175 of 10,313 systems (11.4%), within 0.2 percentage points. By size, this analysis found 15.8% for large systems (EPA: 15.5%) and 8.1% for systems serving 10,000 or fewer (EPA medium and small combined: 8.1%).

## Key findings

**National**

| Measure | Systems | % of 10,313 |
|---|---|---|
| At least one PFAS detected | 3,595 | 34.9% |
| PFOA or PFOS average above 4.0 ppt | 1,175 | 11.4% |
| Lithium detected | 3,773 | 36.6% |

**Most frequently detected PFAS**

| PFAS | Systems with a detection | % of systems |
|---|---|---|
| PFPeA | 2,066 | 20.0% |
| PFBA | 1,935 | 18.8% |
| PFHxA | 1,807 | 17.5% |
| PFBS | 1,707 | 16.6% |
| PFOS | 1,352 | 13.1% |
| PFOA | 1,305 | 12.7% |
| PFHxS | 1,037 | 10.1% |

The two PFAS with federal 4.0 ppt limits (PFOS and PFOA) ranked 5th and 6th. Four short chain PFAS were detected in more systems. Four of the 29 PFAS were never detected.

**By system size and water source**

| Group | Above 4.0 ppt | Test |
|---|---|---|
| Large (more than 10,000 served) | 697 of 4,399 (15.8%) | Chi square = 150.5, p < 0.0001, Cramér's V = 0.12 |
| 10,000 or fewer served | 478 of 5,914 (8.1%) | |
| Groundwater | 578 of 5,109 (11.3%) | Chi square = 0.06, p = 0.80 |
| Surface water (any SW, GU, or mixed facility) | 597 of 5,204 (11.5%) | |

**Top states (20 or more systems)**

| State | Above 4.0 ppt |
|---|---|
| Connecticut | 29 of 63 (46.0%) |
| New Jersey | 119 of 266 (44.7%) |
| Delaware | 12 of 36 (33.3%) |
| Florida | 132 of 409 (32.3%) |
| South Carolina | 53 of 165 (32.1%) |
| Massachusetts | 79 of 263 (30.0%) |
| Rhode Island | 8 of 29 (27.6%) |
| North Carolina | 76 of 291 (26.1%) |
| Pennsylvania | 93 of 390 (23.8%) |
| Alabama | 60 of 307 (19.5%) |

All ten are in the eastern and southeastern U.S.

## Limitations

* **Screening measure, not compliance.** Official compliance uses a running annual average of compliance monitoring data, and the federal compliance deadline has not yet arrived. Systems above 4.0 ppt here are not "in violation."
* **Unweighted.** Percentages describe the UCMR 5 systems tested. EPA's weighted estimate for all U.S. systems nationwide is 7.8%, lower because UCMR 5 tested all large and medium systems but only a sample of small ones.
* **Any sample point rule.** Larger systems have more sample points, which gives them more chances to exceed. This may partly explain the size difference.
* **Detection depends on reporting limits.** Minimum reporting levels differ by chemical, which affects how often each PFAS can be detected.
* **Full set of results not required.** Unlike EPA's Table 4, this analysis includes systems without a complete set of results.
* **6 systems** had no PFOA or PFOS results and were counted as not above benchmark (under 0.1% of systems).
* **Small states and territories.** State comparisons are limited to places with 20 or more systems. Tribal systems are included in national totals but not in state summaries.
* Detection in water is not the same as individual exposure. This is a descriptive analysis and does not explain why some places are higher.

## A data issue worth noting

The first frequency check failed on one character: the µ in "µg/L." EPA's file uses Windows encoding, while SAS OnDemand runs in UTF-8. Adding `encoding="wlatin1"` to the FILENAME statement fixed it.

## How to reproduce

1. Download the UCMR 5 Occurrence Data Text Files zip from EPA and extract `UCMR5_All.txt`.
2. In SAS OnDemand for Academics, create `PFAS_Project/raw_data` and `PFAS_Project/output`, and upload the file to `raw_data`.
3. Open `pfas_ucmr5_part1.sas`, set your path in Section 0, and run one section at a time.
4. Load the three CSV files from `output` into Tableau.

## Files

| File | Contents |
|---|---|
| `pfas_ucmr5_part1.sas` | Full SAS program: import, QA, summaries, tests, export |
| `tableau_states.csv` | State summary |
| `tableau_contaminants.csv` | Detections by contaminant |
| `tableau_systems.csv` | One row per water system |
| `PFAS Dashboard.png` | Dashboard screenshot |

## Next steps

Part 2 will link water systems to counties using the UCMR 5 ZIP code file and compare exceedance by county Social Vulnerability Index (SVI).

## Author

Satwika Muddasani, MPH (Environmental Health)
