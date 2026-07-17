********************************************************************************
* module_B_merge_append.do        OPTIONAL self-study module B  |  ~30 min
* -----------------------------------------------------------------------------
* Topic   : combining datasets -- append (stack rows) and merge (join columns).
* Needs   : data/simulated/wage_survey_clean.dta (run session files 02-03).
* Note    : this module creates and deletes small temporary files inside
*           data/simulated/ -- everything is cleaned up at the end.
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
    di as error "Run session do-files 02 and 03 first (repo root as working dir)."
    exit 601
}

*==============================================================================
* B1. append: stacking rows (same variables, more people)
*==============================================================================

* Real projects often receive data in installments: this year's wave, last
* year's wave, region A, region B. -append- stacks them.

* Manufacture the situation: split our data into urban and rural files.
use "data/simulated/wage_survey_clean.dta", clear
keep if urban == 1
save "data/simulated/tmp_urban.dta", replace

use "data/simulated/wage_survey_clean.dta", clear
keep if urban == 0
save "data/simulated/tmp_rural.dta", replace

* Now pretend they arrived separately, and combine:
use "data/simulated/tmp_urban.dta", clear
append using "data/simulated/tmp_rural.dta"

count
* Back to 8,000. Append is that simple -- WHEN the variables match. If one
* file calls it "wage" and the other "hwage", you get two half-empty
* columns and no error. Always -describe- both files first.

*==============================================================================
* B2. merge: joining columns (same people, more variables)
*==============================================================================

* The workhorse: attach province-level information to individuals.
* Manufacture a province-level dataset (in real life this arrives from
* a statistics office):

use "data/simulated/wage_survey_clean.dta", clear
collapse (median) prov_medwage = hwage (count) prov_n = id, by(province)
label variable prov_medwage "Province median hourly wage"
label variable prov_n       "Respondents in province"
save "data/simulated/tmp_province.dta", replace
list, clean noobs    // 13 rows -- one per province

* Merge it onto individuals. Grammar: merge <type> <keys> using <file>.
* Here: many individuals share one province row, so "m:1 province".
use "data/simulated/wage_survey_clean.dta", clear
merge m:1 province using "data/simulated/tmp_province.dta"

* READ THE MERGE TABLE. Stata reports how rows matched:
*   _merge == 3  matched            (should be all 8,000 here)
*   _merge == 1  only in master     (individual with unknown province?)
*   _merge == 2  only in using      (province with no individuals?)
tabulate _merge

* Rule: NEVER proceed past a merge without inspecting _merge. Silent
* mismatches (typos in keys, differing storage types, trailing spaces in
* string keys) are how wrong datasets are born. When satisfied:
assert _merge == 3
drop _merge

* The m:1 vs 1:m vs 1:1 declaration is a safety net, not decoration:
* if you claim 1:1 and the keys are not unique, Stata refuses. Let it.
* (There is also m:m. Pretend there is not. It almost never does what
* anyone wants; if you think you need it, you want -joinby- instead.)

*==============================================================================
* B3. Clean up the temporary files
*==============================================================================

erase "data/simulated/tmp_urban.dta"
erase "data/simulated/tmp_rural.dta"
erase "data/simulated/tmp_province.dta"

di as result _n "Module B done. (Temporary files removed.)"
exit
