********************************************************************************
* 03_generate_variables.do    SEGMENT 4 of the session  |  time budget ~15 min
* -----------------------------------------------------------------------------
* Goal    : create variables correctly: gen, replace, egen, labels --
*           including rebuilding the log wage we dropped while cleaning.
* Data in : data/simulated/wage_survey_clean.dta
* Data out: data/simulated/wage_survey_clean.dta  (extended)
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

use "data/simulated/wage_survey_clean.dta", clear

* Segment 3 ended with a promise: rebuild the log wage, properly, from
* clean ingredients.

*------------------------------------------------------------------ gen
gen double lhwage = ln(hwage)
label variable lhwage "Log hourly wage (rebuilt after cleaning)"

* What happened to the 15 missing wages?
count if missing(lhwage)

* ln(missing) is missing -- propagation working FOR us this time.
* No zombies. This is why we rebuild instead of patch.

* Why log? Because a 0.01 change in log wage is about a 1 percent
* change in the wage -- and "percent per year of school" is exactly
* how economists talk about returns. Segment 5 cashes this in.

*------------------------------------------------------------------ gen + if
* Potential labor-market experience, the classic proxy: years since
* leaving school.

gen byte exper = age - schooling - 6
label variable exper "Potential experience (age - schooling - 6)"

* What is exper for the 200 missing-schooling people?
count if missing(exper)
* Missing minus anything is missing. Propagation, again, is sensible.

*------------------------------------------------------------------ replace
* An indicator done RIGHT this time -- remember the gotcha rule.

gen byte finished_hs = schooling >= 12 if !missing(schooling)
label variable finished_hs "Completed senior secondary (12+ years)"

tabulate finished_hs, missing

* -tabulate, missing- shows the missing category explicitly. The 200
* are a visible column now, not silent members of category 1. That
* "if !missing()" at the end of -gen- is the pattern to memorize.

*------------------------------------------------------------------ egen
* -egen- is gen's big sibling: statistics within groups.

egen double prov_wage = mean(hwage), by(province)
label variable prov_wage "Province mean hourly wage"

* See it:
tabulate province, summarize(prov_wage)

* Every person in a province carries the same value: a group mean
* merged onto individuals. egen has dozens of functions -- help egen.

*------------------------------------------------------------------ labels
* Value labels turn numbers into words, so the output reads without a
* codebook.

gen byte agegroup = 1 if age < 22
replace agegroup = 2 if age >= 22 & age < 29
replace agegroup = 3 if age >= 29 & !missing(age)
label variable agegroup "Age group"

label define agelbl 1 "15-21" 2 "22-28" 3 "29-35"
label values agegroup agelbl

tabulate agegroup

* Why the "& !missing(age)" on the last replace, when age has no
* missings? (Habit. The guard costs nothing; forgetting it costs a
* retraction.)

* Save the extended file.
save "data/simulated/wage_survey_clean.dta", replace

* RECAP: gen creates, replace modifies, egen aggregates, labels document.
*        And every indicator built from a comparison carries !missing().

exit
