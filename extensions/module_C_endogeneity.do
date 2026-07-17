********************************************************************************
* module_C_endogeneity.do     OPTIONAL self-study module C (ADVANCED) | ~40 min
* -----------------------------------------------------------------------------
* Topic   : why OLS is not the end of the story -- endogeneity in the returns
*           to education, made visible.
* The trick: in real data, "ability" is unobservable, and OLS is stuck with
*           the bias it causes. In SIMULATED data, we built ability -- so you
*           can estimate with and without it and watch the bias appear.
* Needs   : data/simulated/wage_survey_clean.dta (run session files 02-03).
* Context : this reproduces, in miniature, the core move of Febriady,
*           Postepska & Angelini (2026), GLO DP No. 1731 -- the paper this
*           repository accompanies. Their OLS: 8.8 percent (never poor) vs
*           5.8 (childhood poor). Corrected: 6.8 vs 1.5.
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
* C1. The problem, stated in one regression
*==============================================================================

* From the session: OLS says a year of schooling pays about 9 percent for
* the never poor, about 6 percent for the childhood poor.

regress lhwage schooling female urban age c.age#c.age i.province ///
    if cpoor == 0
di as text "OLS, never poor : " as result %6.4f _b[schooling]

regress lhwage schooling female urban age c.age#c.age i.province ///
    if cpoor == 1
di as text "OLS, poor       : " as result %6.4f _b[schooling]

* But schooling is CHOSEN, not randomly assigned. People with more drive,
* sharper minds, better-connected families get more schooling AND earn more
* at any schooling level. OLS bundles those two things into one number.
* Economists call the bundled-in part OMITTED VARIABLE BIAS (OVB).

*==============================================================================
* C2. The magic these data allow: observe the unobservable
*==============================================================================

* This dataset ships with the confounder itself: -ability-, the latent
* trait that raised both schooling and wages in the data-generating
* process. No real survey has this column. Add it to the regression:

regress lhwage schooling ability female urban age c.age#c.age i.province ///
    if cpoor == 0
di as text "With ability, never poor : " as result %6.4f _b[schooling]

regress lhwage schooling ability female urban age c.age#c.age i.province ///
    if cpoor == 1
di as text "With ability, poor       : " as result %6.4f _b[schooling]

/*
Watch what happened:
  never poor : about 0.09  ->  about 0.07   (bias ~ 2 percentage points)
  poor       : about 0.06  ->  about 0.01   (bias ~ 4-5 percentage points)
The gap between the groups roughly DOUBLED once ability was controlled.
OLS was not just wrong -- it was wrong by a different amount for each
group, which made the groups look more similar than they are.
*/

*==============================================================================
* C3. Why is the bias bigger for the poor? Look at selection.
*==============================================================================

* OVB arithmetic: bias = (effect of ability on wages) x (how strongly
* ability predicts schooling). The first piece is the same for everyone
* here; the second is not:

pwcorr ability schooling if cpoor == 0
pwcorr ability schooling if cpoor == 1

/*
The correlation is much stronger among the childhood poor. The economics:
for a poor child, barriers to schooling are high -- only the unusually
able (or driven, or lucky in family support) push through to high
attainment. Among the never poor, schooling is closer to a default, so
it carries less information about ability. Highly schooled poor
individuals are therefore a strongly SELECTED group, and OLS credits
their exceptional traits to their diplomas.
The paper finds the same asymmetry. Its control-function coefficient --
the correlation between the wage and schooling equations' errors -- is
0.230 for the poor against 0.077 for the never poor, which the paper calls
"roughly three times". Ours here is 0.51 against 0.20, a ratio of about
2.5. Not the same object as a raw correlation of ability and schooling,
but the same story: selection into schooling bites harder for the poor.
*/

*==============================================================================
* C4. But real data have no ability column. Now what?
*==============================================================================

/*
Everything above cheated: we controlled for a variable that does not
exist outside simulations. Real research needs other strategies. Two of
the main ones, in one paragraph each -- as a pointer, not a lesson:

INSTRUMENTAL VARIABLES (IV). Find something that shifts schooling but
has no independent path to wages -- distance to the nearest school, a
school-construction program, a compulsory-schooling law. Use only the
schooling variation induced by that instrument, which is (by assumption)
clean of ability. The catch: instruments satisfying this "exclusion
restriction" are rare, and each identifies the return only for the
people the instrument actually moved.

CONTROL FUNCTIONS via heteroskedasticity (Klein & Vella 2010) -- the
approach used in the paper behind this repo. When no credible instrument
exists, identification can come from a different feature of the data:
how the VARIANCE of schooling differs across observable groups. The
method builds an estimate of the selection pressure from the schooling
equation's residuals and inserts it into the wage equation as an extra
regressor -- a "control function" standing in for the ability channel we
just simulated. That is how the paper turns 8.8-vs-5.8 into 6.8-vs-1.5
without an instrument. (Implementation: the author's -kvpara- Stata
package, github.com/febriady/KV-para.)

The one-line takeaway: whenever a regressor is chosen by the people you
study, ask what unobservable is doing the choosing -- and what it would
take to see your estimate survive its arrival.
*/

di as result _n "Module C done. Now read the paper's Section on identification."
exit
