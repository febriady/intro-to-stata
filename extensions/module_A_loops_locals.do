********************************************************************************
* module_A_loops_locals.do        OPTIONAL self-study module A  |  ~30 min
* -----------------------------------------------------------------------------
* Topic   : locals and loops -- the moment Stata stops being a calculator
*           and starts being a programming language.
* Needs   : data/simulated/wage_survey_clean.dta (run session files 02-03).
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
* A1. Locals: named scraps of text or numbers
*==============================================================================

* A local holds a value; you get it back with `name' -- note the quotes:
* a BACKTICK (`) on the left and an APOSTROPHE (') on the right. Typing
* two apostrophes is the classic first error.

local myvar schooling
summarize `myvar'

local cutoff 12
count if schooling > `cutoff' & !missing(schooling)

* Locals really shine inside do-files: change the value once at the top,
* and every use downstream updates. (The simulation file that built your
* dataset does exactly this with its parameters.)

* Locals can also hold results. After summarize, r() holds the numbers:
quietly summarize hwage
local wbar = r(mean)
di as text "Mean hourly wage: " as result %9.0fc `wbar'

* IMPORTANT: locals evaporate when the do-file ends. Run a do-file line by
* line and locals defined earlier are already gone -- run whole blocks.

*==============================================================================
* A2. foreach: loop over variables or lists
*==============================================================================

* Same summarize for four variables, without copy-paste:
foreach v of varlist hwage schooling age exper {
    quietly summarize `v'
    di as text "`v'" _col(12) as result %9.2f r(mean)
}

* Loop over arbitrary words:
foreach grp in 0 1 {
    quietly count if cpoor == `grp'
    di as text "cpoor = `grp': " as result r(N) as text " respondents"
}

*==============================================================================
* A3. forvalues: loop over numbers
*==============================================================================

* The return to schooling, province by province -- 13 regressions, 6 lines:
di as text _n "Return to schooling by province:"
forvalues p = 1/13 {
    quietly regress lhwage schooling female urban age c.age#c.age ///
        if province == `p'
    local lbl : label provlbl `p'
    di as text %-20s "`lbl'" as result %7.4f _b[schooling]
}

/*
Three things worth noticing:
 - `p' takes values 1, 2, ..., 13;
 - -local lbl : label provlbl `p'- fetches the value label (the province
   name) for the current number -- loops and labels compose;
 - the coefficients bounce around the pooled 0.08: much of that is noise
   from splitting 8,000 people into 13 cells. Small samples are loud.
*/

*==============================================================================
* A4. Putting it together: a tiny robustness table
*==============================================================================

* How stable is the return to schooling as controls pile up?
local spec1 ""
local spec2 "female urban"
local spec3 "female urban age c.age#c.age"
local spec4 "female urban age c.age#c.age i.province"

forvalues s = 1/4 {
    quietly regress lhwage schooling `spec`s''
    di as text "Specification `s': " as result %6.4f _b[schooling]
}

* (Yes, that is a local INSIDE a local: `spec`s'' resolves `s' first, then
* fetches spec1...spec4. When this stops looking scary, you are no longer
* a beginner.)

di as result _n "Module A done."
exit
