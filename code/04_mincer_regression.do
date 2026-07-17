********************************************************************************
* 04_mincer_regression.do     SEGMENT 5 of the session  |  time budget ~25 min
* -----------------------------------------------------------------------------
* Goal    : estimate the return to a year of schooling; then ask whether it
*           is the same for people who grew up poor. The session's payoff.
* Data in : data/simulated/wage_survey_clean.dta
* Context : this mirrors the OLS benchmark in Febriady, Postepska & Angelini
*           (2026), GLO DP No. 1731 -- the paper this dataset is modeled on.
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

*-------------------------------------------------------- callback to segment 2
/*
Before any regression, settle the score. In segment 2 you asked, on the
raw data, how wages and schooling move together, and Stata said -0.0003:
nothing. Since then you deleted fifteen impossible wages -- ten typed a
thousand times too large, five at one rupiah. Same people, same question,
same units:
*/

correlate hwage schooling

/*
0.34. That is segment 3 in one number. Fifteen rows out of eight
thousand were the whole difference between "education is worthless"
and this -- correlation is computed on the actual values, so ten
wages in the millions dominated every covariance they touched.
One more step -- the log wage you built in segment 4:
*/

correlate lhwage schooling

/*
0.39. Logs are not hiding anything; they match how wages actually
scale -- in percentages, not rupiah -- so the straight-line summary
fits better. The full bridge: -0.0003 raw, 0.34 with the errors
deleted, 0.39 in the units economics uses. The relationship was
there the whole time, under fifteen bad rows.
Could you stop here and report 0.39? No -- and say why before
reading on.
A correlation is one number for the whole cloud. It holds nothing
constant, it is only about straight lines, and it cannot tell you what
a year of schooling is WORTH. For that, a regression.
*/

* The Mincer regression is the workhorse of labor economics: log wage
* on years of schooling. The coefficient is (approximately) the percent
* wage gain from one more year of school.

*------------------------------------------------------------------ bivariate
regress lhwage schooling

/*
READ THE OUTPUT, top to bottom:
  - Number of obs: NOT 8,000. Why? (Missings dropped silently --
    segment 3 predicted exactly this.)
  - Coefficient on schooling: about 0.08 -- each year of schooling is
    associated with roughly 8 percent higher wages.
  - Standard error, t, p-value: precision of that estimate.
  - R-squared: share of wage variation explained.
*/

* "Associated with" was deliberate. This is a comparison of different
* people, not an experiment on the same person.

*------------------------------------------------------------------ controls
* People with more schooling also differ in gender mix, location, age.
* Controls hold observable differences fixed.

regress lhwage schooling female urban age c.age#c.age i.province

/*
c.age#c.age is Stata's way to add age squared -- wages rise with age
at a decreasing rate. i.province adds a dummy for every province.
The return to schooling barely moves: still about 8 percent. Note
the coefficient on female, by the way -- and file it away as a
question for another course.
*/

*------------------------------------------------------------- postestimation
* After ANY estimation command, Stata keeps the fitted model in memory.
* -predict- spends it: it builds new variables out of the regression
* you just ran. Two are worth knowing on day one.

capture drop lhwage_hat
predict lhwage_hat

* With no option, -predict- gives the FITTED value: what the model
* thinks this person's log wage should be, given their characteristics.

capture drop lhwage_resid
predict lhwage_resid, residuals

* The RESIDUAL is what the model missed -- actual minus fitted. You
* will often see these two called yhat and uhat.
* -capture drop- first is housekeeping: it lets you re-run these lines
* without Stata complaining that the variable already exists.

summarize lhwage_hat lhwage_resid

/*
What is the mean of the residuals? (Zero, to many decimal places.)
That is NOT evidence the model is good. OLS picks the coefficients
that force the residuals to average zero -- it is arithmetic, not
validation.
Now look at the two N columns in that table. They are NOT equal.
Why? (Sit with it -- the answer is the whole lesson.)
The regression ran on 7,785 people. But -predict- handed out 7,800
fitted values, because it predicts for anyone whose RIGHT-hand
variables are present -- including the 15 people whose wage we
deleted as implausible back in segment 3. The model is happy to
guess their wage; it just never learned from them. A residual needs
the ACTUAL wage to subtract, so it exists for only 7,785.
That is why you will see this written everywhere:
    predict yhat if e(sample)
-e(sample)- means "only the observations this estimation actually
used". Get in the habit now; it will save you a wrong table later.
*/

*------------------------------------------------------------------ by group
* Now the real question. Same regression, run separately by childhood
* poverty status.

regress lhwage schooling female urban age c.age#c.age i.province ///
    if cpoor == 0
* Note the schooling coefficient: about 0.09.

regress lhwage schooling female urban age c.age#c.age i.province ///
    if cpoor == 1
* And this one: about 0.06. Put the two side by side.

* Same school system. Same labor market. Who gets more out of a year
* of schooling? By how much?

*------------------------------------------------------------------ interaction
* Two separate regressions cannot tell us whether the gap is
* statistically meaningful. An interaction term can.

regress lhwage c.schooling##i.cpoor female urban age c.age#c.age i.province

/*
READ IT:
  - schooling            : the return for the never-poor (about 0.09)
  - cpoor#c.schooling    : the DIFFERENCE for the childhood poor
                           (about -0.03, and statistically significant)
  - So the childhood poor earn roughly 3 percentage points LESS per year
    of schooling: about 6 percent instead of about 9.
*/

/*
In the real IFLS data, the paper behind this session finds the same
OLS pattern: 8.8 percent for the never-poor, 5.8 for the childhood
poor. And then it shows OLS is not the end of the story: schooling is
not randomly assigned, and correcting for who selects into education
nearly DOUBLES the gap -- to 6.8 versus 1.5 percent. How can you
correct for something you cannot observe? In THIS dataset you can
actually see it happen, because the unobservable was built in -- that
is Module C in the extensions folder, and the paper is linked in the
README.
*/

/*
And that is the arc: set up, look, clean, build, estimate. Every step
was code, which means every step can be rerun, checked and improved
by someone who was not in this room. That is the whole game.
One thing deliberately not done today: getting these results out of
Stata and into a document. Never retype regression numbers by hand --
Module D in the extensions folder shows you the two commands that do
it for you. Read it before your first paper.
*/

exit
