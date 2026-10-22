/*******************************************************************
  PFAS in U.S. Drinking Water: Final EPA UCMR 5 Data (Part 1)
  Author : Satwika Muddasani
  Tools  : SAS OnDemand for Academics (analysis), Tableau Public (dashboard)

  Data source:
    U.S. EPA, Fifth Unregulated Contaminant Monitoring Rule (UCMR 5)
    Occurrence Data Text Files, final release August 2026.
    Files used: UCMR5_All.txt
    Downloaded: October 22, 2026

  Key decisions:
    * EPA results are in ug/L. Converted to ng/L (ppt) by x 1000.
    * Non detects ("<" sign) are set to 0 when averaging.
    * Benchmark: federal MCL of 4.0 ppt for PFOA and for PFOS.
      A system is "above benchmark" if the average at ANY sample
      point is above 4.0 ppt. This is a screening measure, NOT a
      compliance determination.
    * 6 of 10,313 systems had no PFOA/PFOS results; they are
      counted as not above benchmark (effect under 0.1%).

  Run one section at a time and check the log before moving on.
*******************************************************************/


/*=================================================================
  SECTION 0. SETTINGS (change the path to your own folder)
=================================================================*/
%let root = /home/uXXXXXXXX/PFAS_Project;

libname pfas "&root/output";

%let mcl_pfoa = 4.0;   /* ng/L (ppt) */
%let mcl_pfos = 4.0;   /* ng/L (ppt) */


/*=================================================================
  SECTION 1. IMPORT RAW UCMR 5 RESULTS
=================================================================*/
/* EPA's file is Windows encoded (the micro sign in "ug/L"),
   so SAS must translate it into this session's UTF-8 */
filename ucmr "&root/raw_data/UCMR5_All.txt" encoding="wlatin1";

data pfas.ucmr5_clean;
  infile ucmr dlm='09'x dsd firstobs=2 truncover lrecl=32767;

  length PWSID $12 PWSName $120 Size $2 FacilityID $20 FacilityName $120
         FacilityWaterType $2 SamplePointID $20 SamplePointName $120
         SamplePointType $2 AssociatedFacilityID $20 AssociatedSamplePointID $20
         CollectionDate_c $10 SampleID $40 Contaminant $20 MRL 8 Units $10
         MethodID $20 AnalyticalResultsSign $1 AnalyticalResultValue 8
         SampleEventCode $5 MonitoringRequirement $5 Region $2 State $2
         UCMR1SampleType $5;

  input PWSID -- UCMR1SampleType;

  CollectionDate = input(CollectionDate_c, mmddyy10.);
  format CollectionDate mmddyy10.;

  /* 1 = detected, 0 = below minimum reporting level */
  detect = (AnalyticalResultsSign = '=');

  /* ug/L to ng/L (ppt); non detects set to 0 */
  if detect = 1 then result_ngl = AnalyticalResultValue * 1000;
  else result_ngl = 0;
  mrl_ngl = MRL * 1000;

  /* lithium is not a PFAS; keep it separate */
  is_lithium = (upcase(strip(Contaminant)) = 'LITHIUM');

  /* tribal systems use a numeric region code instead of a state */
  tribal = (notdigit(strip(State)) = 0);

  drop CollectionDate_c;
run;


/*=================================================================
  SECTION 2. QUALITY CHECKS
=================================================================*/
proc sql;
  title "QA 1. Overall counts";
  select count(*)                    as n_results      format=comma12.,
         count(distinct PWSID)       as n_systems      format=comma8.,
         count(distinct SampleID)    as n_samples      format=comma10.,
         count(distinct Contaminant) as n_contaminants
  from pfas.ucmr5_clean;

  title "QA 2. Sign and value consistency (both should be 0)";
  select sum(AnalyticalResultsSign = '=' and missing(AnalyticalResultValue))
             as equal_sign_but_no_value,
         sum(AnalyticalResultsSign = '<' and not missing(AnalyticalResultValue))
             as less_than_sign_with_value
  from pfas.ucmr5_clean;

  title "QA 3. Rows with an unreadable date (should be 0)";
  select sum(missing(CollectionDate)) as missing_dates
  from pfas.ucmr5_clean;
quit;

proc freq data=pfas.ucmr5_clean;
  title "QA 4. Category checks";
  tables Contaminant Units AnalyticalResultsSign Size FacilityWaterType
         MonitoringRequirement tribal / missing;
run;
title;


/*=================================================================
  SECTION 3. RESULTS BY CONTAMINANT
=================================================================*/
proc sql;
  create table pfas.contaminant_summary as
  select Contaminant,
         count(*)                                      as n_results,
         sum(detect)                                   as n_detects,
         calculated n_detects / calculated n_results   as prop_results_detected,
         count(distinct case when detect = 1 then PWSID end)
                                                       as n_systems_detected
  from pfas.ucmr5_clean
  group by Contaminant
  order by n_systems_detected desc;
quit;

proc print data=pfas.contaminant_summary noobs;
  title "Detections by contaminant";
  format prop_results_detected percent8.1;
run;
title;


/*=================================================================
  SECTION 4. ONE ROW PER WATER SYSTEM
=================================================================*/

/* 4a. Average PFOA and PFOS at each sample point */
proc sql;
  create table work.point_level as
  select PWSID, FacilityID, SamplePointID, upcase(Contaminant) as chem length=10,
         count(*)         as n_samples,
         mean(result_ngl) as mean_ngl,
         max(result_ngl)  as max_ngl
  from pfas.ucmr5_clean
  where upcase(Contaminant) in ('PFOA','PFOS')
  group by PWSID, FacilityID, SamplePointID, calculated chem;
quit;

/* 4b. Highest sample point average per system */
proc sql;
  create table work.sys_mcl as
  select PWSID,
         max(case when chem = 'PFOA' then mean_ngl else 0 end) as pfoa_point_avg_max,
         max(case when chem = 'PFOS' then mean_ngl else 0 end) as pfos_point_avg_max,
         max(case when chem = 'PFOA' then max_ngl  else 0 end) as pfoa_max_ngl,
         max(case when chem = 'PFOS' then max_ngl  else 0 end) as pfos_max_ngl
  from work.point_level
  group by PWSID;
quit;

/* 4c. System characteristics and any PFAS detection */
proc sql;
  create table work.sys_attr as
  select PWSID,
         max(PWSName)  as PWSName,
         max(State)    as State,
         max(Region)   as Region,
         max(Size)     as Size,
         max(tribal)   as tribal,
         max(FacilityWaterType in ('SW','GU','MX')) as any_surface,
         max(case when is_lithium = 0 then detect else 0 end) as any_pfas_detect,
         count(distinct case when is_lithium = 0 and detect = 1
                             then Contaminant end)            as n_pfas_detected,
         max(case when is_lithium = 1 then detect else 0 end) as lithium_detect,
         max(case when is_lithium = 1 and detect = 1
                  then AnalyticalResultValue end)             as lithium_max_ugl
  from pfas.ucmr5_clean
  group by PWSID;
quit;

/* 4d. Combine */
data pfas.system_level;
  merge work.sys_attr (in=a) work.sys_mcl;
  by PWSID;
  if a;

  array z pfoa_point_avg_max pfos_point_avg_max pfoa_max_ngl pfos_max_ngl;
  do over z; if missing(z) then z = 0; end;

  above_benchmark = (pfoa_point_avg_max > &mcl_pfoa or
                     pfos_point_avg_max > &mcl_pfos);

  length source_type $7;
  if any_surface = 1 then source_type = 'Surface';
  else source_type = 'Ground';
run;

proc freq data=pfas.system_level;
  title "National system level results";
  tables any_pfas_detect above_benchmark lithium_detect;
run;
title;


/*=================================================================
  SECTION 5. COMPARISONS AND TABLEAU EXPORT
=================================================================*/
proc freq data=pfas.system_level;
  title "Above benchmark by system size and water source";
  tables (Size source_type) * above_benchmark / chisq nocol nopercent;
run;
title;

proc sql;
  create table pfas.state_summary as
  select State,
         count(*)              as n_systems,
         sum(any_pfas_detect)  as n_any_detect,
         sum(above_benchmark)  as n_above_benchmark,
         mean(any_pfas_detect) as prop_any_detect,
         mean(above_benchmark) as prop_above_benchmark,
         mean(lithium_detect)  as prop_lithium_detect
  from pfas.system_level
  where tribal = 0
  group by State
  order by prop_above_benchmark desc;
quit;

proc export data=pfas.system_level        outfile="&root/output/tableau_systems.csv"      dbms=csv replace; run;
proc export data=pfas.state_summary       outfile="&root/output/tableau_states.csv"       dbms=csv replace; run;
proc export data=pfas.contaminant_summary outfile="&root/output/tableau_contaminants.csv" dbms=csv replace; run;
