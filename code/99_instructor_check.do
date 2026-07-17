********************************************************************************
* 99_instructor_check.do                                    INSTRUCTOR ONLY
* -----------------------------------------------------------------------------
* SPOILER WARNING: this file prints the complete answer key for the session
* (planted data problems, calibration targets, the missing-value gotcha).
* Students: close this file now and open it again after class.
* -----------------------------------------------------------------------------
* Purpose : Verify, before class, that data/simulated/wage_survey_raw.dta
*           carries the planted problems and reproduces the calibration
*           targets from GLO DP No. 1731 (OLS columns of the returns table,
*           and the control-function estimates for Module C).
* Usage   : run code/simulate_data.do first, then this file, from repo root.
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

use "data/simulated/wage_survey_raw.dta", clear

di as result _n "=== CHECK 1: planted data problems ==="

assert _N == 8000

quietly count if missing(schooling)
assert r(N) == 200
di as text "Missing schooling values planted : " as result r(N)

quietly count if hwage > 1000000 & !missing(hwage)
assert r(N) == 10
quietly count if hwage <= 100
assert r(N) == 5
di as text "Implausible wages planted        : " as result 15

* The two plants must be disjoint, so cleaning order never changes counts
quietly count if (hwage > 1000000 | hwage <= 100) & missing(schooling)
assert r(N) == 0
di as text "Overlap between the two plants   : " as result 0 as text " (disjoint)"

* No unplanted impossible values: schooling feasible given age (entry at 6)
quietly count if schooling > age - 6 & !missing(schooling)
assert r(N) == 0
di as text "Schooling > age - 6 violations   : " as result 0

* The missing-value gotcha (segment 3 shows this live):
quietly count if schooling > 12
local naive = r(N)
quietly count if schooling > 12 & !missing(schooling)
local correct = r(N)
di as text _n "Naive -count if schooling > 12-  : " as result `naive'
di as text    "Correct count (& !missing())     : " as result `correct'
di as text    "Difference (the 200 missings)    : " as result `naive' - `correct'

di as result _n "=== CHECK 2: calibration targets (clean sample) ==="

gen byte ok = !missing(schooling) & hwage > 100 & hwage <= 1000000

* (a) Pooled OLS return (target ~ 0.080)
quietly regress lhwage schooling female urban age c.age#c.age i.province ///
    if ok
local b_pool = _b[schooling]
di as text "Pooled OLS return        : " as result %6.4f `b_pool' ///
   as text "   (target 0.080)"
assert abs(`b_pool' - 0.080) < 0.006

* (b) OLS by childhood poverty (targets ~ 0.088 and ~ 0.058)
quietly regress lhwage schooling female urban age c.age#c.age i.province ///
    if ok & cpoor == 0
local b_np_hat = _b[schooling]
quietly regress lhwage schooling female urban age c.age#c.age i.province ///
    if ok & cpoor == 1
local b_p_hat = _b[schooling]
di as text "OLS return, never poor   : " as result %6.4f `b_np_hat' ///
   as text "   (target 0.088)"
di as text "OLS return, poor         : " as result %6.4f `b_p_hat' ///
   as text "   (target 0.058)"
assert abs(`b_np_hat' - 0.088) < 0.006
assert abs(`b_p_hat'  - 0.058) < 0.006

* Interaction form (target ~ -0.029)
quietly regress lhwage c.schooling##i.cpoor female urban age c.age#c.age ///
    i.province if ok
local b_int = _b[1.cpoor#c.schooling]
di as text "Interaction coefficient  : " as result %6.4f `b_int' ///
   as text "   (target -0.029)"
assert abs(`b_int' - (-0.029)) < 0.008

* Module C: controlling for ability recovers the structural returns
quietly regress lhwage schooling ability female urban age c.age#c.age ///
    i.province if ok & cpoor == 0
local b_np_true = _b[schooling]
quietly regress lhwage schooling ability female urban age c.age#c.age ///
    i.province if ok & cpoor == 1
local b_p_true = _b[schooling]
di as text "With ability, never poor : " as result %6.4f `b_np_true' ///
   as text "   (target 0.068)"
di as text "With ability, poor       : " as result %6.4f `b_p_true' ///
   as text "   (target 0.015)"
assert abs(`b_np_true' - 0.068) < 0.006
assert abs(`b_p_true'  - 0.015) < 0.006

di as result _n "=== ALL INSTRUCTOR CHECKS PASSED ==="
di as text "In-class cleaning thresholds: implausible if hwage > 1,000,000"
di as text "or hwage <= 100 Rupiah/hour; missing schooling handled with"
di as text "-!missing()- as shown in segment 3."

exit
