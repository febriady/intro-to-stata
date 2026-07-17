********************************************************************************
* solutions.do -- worked solutions to exercises/exercises.html
* Run from the repo root AFTER the session files through 03 (so that
* data/simulated/wage_survey_clean.dta exists).
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

capture confirm file "data/simulated/wage_survey_clean.dta"
if _rc {
    di as error "wage_survey_clean.dta not found. Run the session do-files"
    di as error "02 and 03 first (they create the cleaned dataset)."
    exit 601
}
use "data/simulated/wage_survey_clean.dta", clear

capture confirm variable lhwage
if _rc {
    di as error "The cleaned dataset exists but is missing the variables that"
    di as error "session file 03 adds (re-running 02 on its own resets it)."
    di as error "Run 02 and then 03 again, then retry this file."
    exit 111
}

*==============================================================================
* Exercise 1 -- The trap, one more time
*==============================================================================

* 1.1 Naive vs correct count of 9+ years of schooling
count if schooling >= 9
count if schooling >= 9 & !missing(schooling)
* The difference is exactly 200: every missing value satisfies ">= 9"
* because missing is stored as the largest possible value. All 200 missings
* are silently included by the naive version.

* 1.2 Where the missings live
count if missing(schooling) & cpoor == 1 & urban == 0
count if missing(schooling) & cpoor == 0 & urban == 1
/*
Missing schooling is far more common among rural childhood-poor
respondents than among urban never-poor ones. That pattern is realistic
(survey nonresponse is rarely random) and it matters: commands that drop
missings silently -- like regress -- are then quietly dropping MORE of
one group than another, so "the sample" is no longer who you think it is.
*/

*==============================================================================
* Exercise 2 -- Build variables without stepping on the rake
*==============================================================================

* 2.1 Tertiary indicator with the missing guard
gen byte tertiary = schooling >= 13 if !missing(schooling)
tabulate tertiary, missing
* The "if !missing(schooling)" clause makes gen assign missing (not 0/1)
* to the 200. Without it, they would all be classified as tertiary = 1.

* 2.2 Median province wage
egen double prov_p50 = median(hwage), by(province)
tabulate province, summarize(prov_p50)
* Read the table: the province with the largest mean of prov_p50 has the
* highest median wage (every resident of a province shares one value, so
* the "mean" column just displays that province's median).

* 2.3 Labels
label variable tertiary "Completed any tertiary education (13+ years)"
label define tertlbl 0 "No tertiary" 1 "Tertiary"
label values tertiary tertlbl
tabulate tertiary
* tabulate now shows words, not bare 0/1.

*==============================================================================
* Exercise 3 -- Your first heterogeneity result
*==============================================================================

* 3.1 Separate regressions by gender
regress lhwage schooling urban age c.age#c.age i.province if female == 0
regress lhwage schooling urban age c.age#c.age i.province if female == 1
* Note each schooling coefficient; in these simulated data the two are
* close (the data-generating process did not build in a gender gap in
* RETURNS, only in wage LEVELS -- compare your two coefficients).

* 3.2 The difference, tested directly
regress lhwage c.schooling##i.female urban age c.age#c.age i.province
/*
The coefficient on female#c.schooling is the female-minus-male difference
in returns. Check its p-value against 0.05. In these simulated data it
should be small and statistically insignificant -- a useful lesson in
itself: not every subgroup split yields a significant difference, and
a null result is a result.
*/

/*
3.3 Interpretation (one sentence each)
(i)  The interaction coefficient, multiplied by 100, is the difference in
     the percent wage gain per additional year of schooling for women
     relative to men.
(ii) Schooling is not randomly assigned -- people who differ in unobserved
     ways (ability, family background) choose different schooling -- so
     these are associations; see Module C for what happens when one such
     unobservable becomes visible.
*/

di as result _n "Solutions ran to the end. Compare each block with your own."
exit
