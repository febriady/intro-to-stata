********************************************************************************
* module_D_export_results.do  OPTIONAL self-study module D (SHORT) | ~15 min
* -----------------------------------------------------------------------------
* Topic   : getting regression results OUT of Stata and into a document,
*           without retyping a single number.
* Why it  : this was originally the last segment of the live session. It moved
* is here   here for two reasons: it is the one step that needs to install a
*           package, which can fail on a locked-down university computer with
*           no write access; and it loses nothing by being read unhurried, at
*           home, on the day you actually need a table. No part of the
*           session depends on it.
* Needs   : data/simulated/wage_survey_clean.dta (run session files 02-03),
*           and, the first time only, an internet connection to fetch -estout-.
* Output  : results/mincer_table.rtf  (opens in Word)
* Full recipe (decimals, wide tables, LaTeX): docs/esttab_recipe.html
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
use "data/simulated/wage_survey_clean.dta", clear

capture confirm variable lhwage
if _rc {
    di as error "The cleaned dataset exists but is missing the variables that"
    di as error "session file 03 adds (re-running 02 on its own resets it)."
    di as error "Run 02 and then 03 again, then retry this module."
    exit 111
}

*==============================================================================
* D1. The rule
*==============================================================================

* Never retype regression numbers into a document. It is the least
* reproducible act in empirical work, and typos love it. Every number in a
* table should be able to point back at the command that produced it.

* -esttab- is not part of Stata. It lives in the user-written -estout-
* package, which you install once and then have forever. If the next two
* lines fail, you are probably on a machine that will not let you write to
* Stata's package folder -- try it on your own laptop instead.

capture which esttab
if _rc ssc install estout

*==============================================================================
* D2. Store models, then print them side by side
*==============================================================================

* -eststo- parks the results of a regression under a name. -esttab- then
* prints any set of parked models as one table.

eststo clear
eststo m1: regress lhwage schooling
eststo m2: regress lhwage schooling female urban age c.age#c.age i.province
eststo m3: regress lhwage c.schooling##i.cpoor female urban age ///
    c.age#c.age i.province

esttab m1 m2 m3, se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(schooling 1.cpoor#c.schooling) ///
    mtitles("Bivariate" "Controls" "Interaction")

* -keep()- hides the nuisance coefficients so the table shows only what a
* reader needs; the province dummies are still in the regression, just not
* on the page. The stars are a convention, not a verdict.

*==============================================================================
* D3. The same table, as a file
*==============================================================================

capture mkdir "results"
esttab m1 m2 m3 using "results/mincer_table.rtf", replace ///
    se star(* 0.10 ** 0.05 *** 0.01) ///
    keep(schooling 1.cpoor#c.schooling) ///
    mtitles("Bivariate" "Controls" "Interaction") ///
    title("Returns to schooling by childhood poverty (simulated data)") ///
    note("Simulated data. OLS estimates; see GLO DP 1731 for the real thing.")

* Same command, plus -using filename-. Swap .rtf for .tex if you write in
* LaTeX, or .csv to open it in a spreadsheet. Everything else -- decimal
* places, wide tables, appendix variants -- is in docs/esttab_recipe.html.

di as result _n "Module D done. Table written to results/mincer_table.rtf"
exit
