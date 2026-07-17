********************************************************************************
* 02_cleaning_missings.do     SEGMENT 3 of the session  |  time budget ~20 min
* -----------------------------------------------------------------------------
* Goal    : (1) understand how Stata stores and handles missing values --
*               the session's designated "gotcha";
*           (2) find and neutralize implausible values;
*           (3) save a cleaned dataset for the rest of the session.
* Data in : data/simulated/wage_survey_raw.dta
* Data out: data/simulated/wage_survey_clean.dta
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

*==============================================================================
* PART 1 -- THE GOTCHA: missing is the LARGEST value
*==============================================================================

* Suppose your research question needs people with more than a high-school
* education. More than twelve years of schooling. Easy, right?

count if schooling > 12

* Note that number. Now:

count if schooling > 12 & !missing(schooling)

/*
Why did the count just fall by 200? Who were they?
In Stata, missing (".") is stored as the LARGEST possible number.
So "schooling > 12" is TRUE for every missing value. Stata did not
warn you. It never will. This is the single most common source of
silently wrong results in beginner Stata code.
THE RULE, worth memorizing today:
     EVERY  >  >=  !=  comparison must carry  & !missing(var)
     unless you have personally verified there are no missings.
*/

* Where do the missings live?
count if missing(schooling)
count if schooling == .

/*
-missing(schooling)- and -schooling == .- agree here, but they are
not the same thing. Stata has 27 kinds of missing: . and .a to .z
(surveys use them to distinguish "refused" from "not applicable").
All of them are bigger than any real number, and .a to .z are even
bigger than plain "." -- so -schooling == .- can MISS some of them,
while -missing()- catches all 27. Use -missing()-.
*/

display . < .a

* That printed 1 -- "true". Even missings have an ordering.

/*
Different commands treat missings differently, and none of them asks
your permission:
  - summarize, tabulate, regress DROP missings silently. Watch the
    N in every regression you ever run (segment 5 does).
  - gen/replace PROPAGATE them: ln(missing) is missing. Sensible.
  - but a LOGICAL expression treats missing as huge, so:
*/

gen byte finished_hs = schooling >= 12
tabulate finished_hs if missing(schooling)

* The 200 mystery people just became high-school graduates. See it?
* Fix it -- and always write it this way:

replace finished_hs = . if missing(schooling)
drop finished_hs      // we only made it to see the trap; segment 4 does it right

*==============================================================================
* PART 2 -- implausible values
*==============================================================================

* Back to that suspicious maximum wage from segment 2.

summarize hwage, detail

* Look at p99 versus max. A max thousands of times the p99 is not a rich
* person; it is a data-entry error (classic: extra zeros from a typo).

list id hwage schooling province if hwage > 1000000, clean

* How many are there? And do you believe a wage of 1 Rupiah per hour?

count if hwage <= 100

* The rule for cleaning: do NOT delete rows. Set impossible values to
* missing -- now that you know exactly how missing behaves, you can use
* it deliberately. Deleting rows throws away the person's other,
* perfectly good variables.

replace hwage = . if hwage > 1000000
replace hwage = . if hwage <= 100

* Count the repair job:
count if missing(hwage)

* One more thing -- and this catches even experienced people. This
* dataset also ships lhwage, the LOG of the wage. We cleaned hwage.
* Did lhwage clean itself?

count if missing(hwage) & !missing(lhwage)

/*
Fifteen zombies. What happened?
Derived variables do NOT update when their source changes. When you
clean a variable, every variable built from it is now stale. We could
patch lhwage -- but the safer habit is to REBUILD derived variables
after cleaning, which is exactly what the next segment does.
*/

drop lhwage

* Dropping it entirely is the honest move: no stale copy can haunt us.

*==============================================================================
* PART 3 -- save the cleaned data
*==============================================================================

* Never overwrite the raw file. Cleaning is code, so anyone can rerun it
* from the original. That is what "reproducible" means.

save "data/simulated/wage_survey_clean.dta", replace

* -, replace- overwrites an existing file of that name -- fine here,
* because this file is a product of our code, not an original.

/*
RECAP:
  1. Missing = biggest number in Stata. Guard every comparison.
  2. missing() beats "== ." -- it catches .a to .z too.
  3. summarize/regress drop missings silently; logical expressions
     misclassify them; gen/replace propagate them.
  4. Clean by replacing with missing, not by deleting rows.
  5. Rebuild derived variables after cleaning.
*/

exit
