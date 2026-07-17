********************************************************************************
* simulate_data.do
* Purpose : Generate the SIMULATED wage-survey dataset used in the
*           "Intro to Stata" session (University of Groningen).
*
*           STUDENTS: you can RUN this file safely to (re)generate the data:
*               do "code/simulate_data.do"        (from the repo root)
*           but be warned that READING the code below spoils some of the
*           in-class exercises. Run it, do not study it, until after class.
*
*           The data mimic the STRUCTURE of the IFLS-based sample in:
*             Febriady, A., A. Postepska, and V. Angelini (2026), "The Long
*             Shadow: Childhood Poverty and the Returns to Education",
*             GLO Discussion Paper No. 1731.
*           NO real IFLS microdata are used or included anywhere in this
*           repository. RAND's IFLS user agreement prohibits redistribution.
*           Every observation is drawn from random number generators, and the
*           fixed seed below makes the output identical on every machine.
*
* Output  : data/simulated/wage_survey_raw.dta
* Checks  : instructors, run code/99_instructor_check.do after this file.
********************************************************************************

version 14
clear all
set more off

********************************************************************************
* 0. Where is the project on THIS computer?   (edit one line, once)
* -----------------------------------------------------------------------------
* Stata reads files relative to its working directory, so the first job of
* any do-file is to say where the project lives. This block does it for you,
* based on who is logged in, so the same file works on different computers.
*
* Two things you may need to look up:
*   your username      type in the Command window:   display c(username)
*   the folder's path  File > Change Working Directory, pick the unzipped
*                      folder, then type:            display c(pwd)
*                      and copy what Stata prints.
********************************************************************************

if c(username) == "adefebriady" {                              // instructor
    cd "/Users/adefebriady/OneDrive/PhD/Teaching/intro-to-stata"
}
else if c(username) == "YOUR-USERNAME" {                       // you: edit both
    cd "C:/Users/YOUR-USERNAME/Downloads/intro-to-stata-main"  // lines here
}
else {
    di as error _n "This file does not know this computer yet."               ///
        _n "1. Type:  display c(username)   and copy the answer."            ///
        _n "2. Replace YOUR-USERNAME at the top of this file with it,"        ///
        _n "   in both places."                                              ///
        _n "3. Replace the path on the same line with your unzipped folder." ///
        _n "   (File > Change Working Directory, then:  display c(pwd))"     ///
        _n
    exit 601
}
di as text "Working in: " as result c(pwd)
set seed 20260709

*--------------------------------------------------------------------------
* 0. Parameters (calibrated to the OLS and control-function columns of the
*    returns table in GLO DP No. 1731; see 99_instructor_check.do)
*--------------------------------------------------------------------------
local N        8000        // sample size
local p_cpoor  0.28        // share with childhood poverty
local surveyyr 2014        // pseudo survey year (IFLS wave 5 was 2014/15)

* Structural wage equation
local b_np     0.068       // return to schooling, never poor
local b_p      0.015       // return to schooling, childhood poor
local d_cpoor  0.45        // level effect of childhood poverty
local g_abil   0.30        // wage return to one SD of "ability"

* Schooling equation
local mu_np    10.5        // mean latent schooling, never poor
local mu_p      8.5        // mean latent schooling, childhood poor
local lam_np   0.78        // ability loading, never poor
local lam_p    1.88        // ability loading, childhood poor
local sd_u_np  3.5         // idiosyncratic schooling noise, never poor
local sd_u_p   3.2         // idiosyncratic schooling noise, childhood poor

* Wage equation controls and noise
local b_fem   -0.15
local b_urb    0.10
local b_age    0.030
local b_age2  -0.0004
local sd_eps   0.60
local alpha    7.90

*--------------------------------------------------------------------------
* 1. Individuals and background characteristics
*--------------------------------------------------------------------------
set obs `N'
gen long id = _n
label variable id "Respondent identifier"

gen byte cpoor = runiform() < `p_cpoor'
label variable cpoor "Grew up poor (childhood poverty indicator)"

gen byte female = runiform() < 0.40
label variable female "Female"

gen byte urban = runiform() < (0.62 - 0.25*cpoor)
label variable urban "Lives in urban area"

gen int birthyr = 1979 + floor(21*runiform())     // cohorts 1979-1999
label variable birthyr "Year of birth (cohort)"

gen byte age = `surveyyr' - birthyr               // ages 15-35, as in the paper
label variable age "Age at survey"

gen byte province = 1 + floor(13*runiform())      // 13 provinces, as in IFLS
label variable province "Province of residence"

label define provlbl  1 "North Sumatra"     2 "West Sumatra"      ///
                      3 "South Sumatra"     4 "Lampung"           ///
                      5 "DKI Jakarta"       6 "West Java"         ///
                      7 "Central Java"      8 "DI Yogyakarta"     ///
                      9 "East Java"        10 "Bali"              ///
                     11 "West Nusa Tenggara" 12 "South Kalimantan" ///
                     13 "South Sulawesi"
label values province provlbl

label define yesno 0 "No" 1 "Yes"
label values cpoor female urban yesno

*--------------------------------------------------------------------------
* 2. Ability and schooling
*--------------------------------------------------------------------------
gen double ability = rnormal()
label variable ability "Latent ability (UNOBSERVABLE in real data; Module C only)"

gen double educ_star =                                        ///
      cond(cpoor,                                             ///
           `mu_p'  + `lam_p'*ability  + rnormal(0, `sd_u_p'), ///
           `mu_np' + `lam_np'*ability + rnormal(0, `sd_u_np')) ///
    + 0.80*urban

gen byte schooling = round(educ_star)
replace schooling = 0 if schooling < 0
replace schooling = 18 if schooling > 18
* Schooling must be feasible given age (school entry at age 6):
replace schooling = age - 6 if schooling > age - 6
label variable schooling "Years of schooling completed"
drop educ_star

*--------------------------------------------------------------------------
* 3. Wages (Mincer equation)
*--------------------------------------------------------------------------
gen double lhwage = `alpha'                                   ///
    + `b_np'*schooling*(1 - cpoor)                            ///
    + `b_p' *schooling*cpoor                                  ///
    + `d_cpoor'*cpoor                                         ///
    + `g_abil'*ability                                        ///
    + `b_fem'*female                                          ///
    + `b_urb'*urban                                           ///
    + `b_age'*age + `b_age2'*age*age                          ///
    + 0.005*(province - 7)                                    ///
    + rnormal(0, `sd_eps')

gen double hwage = exp(lhwage)
label variable hwage  "Hourly wage (Rupiah)"
label variable lhwage "Log hourly wage"

*--------------------------------------------------------------------------
* 4. Data problems used in the cleaning segment (SPOILERS - see header)
*--------------------------------------------------------------------------
* 4a. Implausible wages
gen double sortkey1 = runiform()
sort sortkey1
gen byte wageflag = _n <= 15
replace hwage  = hwage*1000    in 1/10
replace hwage  = 1             in 11/15
replace lhwage = ln(hwage)     in 1/15
drop sortkey1

* 4b. Missing schooling, concentrated among rural and childhood-poor
*     respondents; kept disjoint from the rows touched in 4a so the two
*     problems are independent no matter which one students clean first.
gen double w = 1 + 2*cpoor + 1.5*(1 - urban)
gen double sortkey2 = -ln(runiform())/w
replace sortkey2 = 999999 if wageflag
sort sortkey2
replace schooling = . in 1/200
drop w sortkey2 wageflag

*--------------------------------------------------------------------------
* 5. Finalize and save
*--------------------------------------------------------------------------
sort id
order id hwage lhwage schooling cpoor female urban age birthyr province ability
compress

label data "SIMULATED wage survey - Intro to Stata session (NOT real IFLS data)"
notes: All observations in this file are simulated. No real IFLS microdata    ///
       are included. Generated by code/simulate_data.do with seed 20260709.
notes: Calibrated so that OLS returns match Febriady, Postepska and Angelini  ///
       (2026), GLO DP No. 1731 (OLS columns of the returns table).

capture mkdir "data"
capture mkdir "data/simulated"
save "data/simulated/wage_survey_raw.dta", replace

di as result _n "Done. Saved data/simulated/wage_survey_raw.dta (N = " _N ")."
di as text "See you in class."

exit
