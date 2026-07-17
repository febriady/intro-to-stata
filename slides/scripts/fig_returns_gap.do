********************************************************************************
* fig_returns_gap.do          Figure for the session deck (slide: "You just
*                             reproduced the OLS benchmark of a real paper")
* -----------------------------------------------------------------------------
* What it shows : the return to one year of schooling, estimated separately
*                 for the never-poor and the childhood-poor, with 95 percent
*                 confidence intervals -- the session's own segment-5 numbers.
* Needs         : data/simulated/wage_survey_clean.dta (run session files
*                 02 and 03 first). Run THIS file from the repo root:
*                     do "slides/scripts/fig_returns_gap.do"
* Output        : slides/figures/fig_returns_gap.pdf
* Palette       : deck colors ("The Prompt" theme) -- maroon 140 47 57,
*                 slate teal 62 107 116, ink 34 48 63, paper 250 248 243.
********************************************************************************

version 14
clear all
set more off

capture confirm file "data/simulated/wage_survey_clean.dta"
if _rc {
    di as error "Run session do-files 02 and 03 first (repo root as working dir)."
    exit 601
}
use "data/simulated/wage_survey_clean.dta", clear

capture confirm variable lhwage
if _rc {
    di as error "The cleaned dataset is missing the segment-03 variables."
    di as error "Run 02 and then 03 again, then retry."
    exit 111
}

* --- the two segment-5 regressions, coefficients and 95 percent CIs ----------
tempname B
matrix `B' = J(2, 3, .)

quietly regress lhwage schooling female urban age c.age#c.age i.province ///
    if cpoor == 0
matrix `B'[1,1] = _b[schooling]
matrix `B'[1,2] = _b[schooling] - invttail(e(df_r), .025)*_se[schooling]
matrix `B'[1,3] = _b[schooling] + invttail(e(df_r), .025)*_se[schooling]

quietly regress lhwage schooling female urban age c.age#c.age i.province ///
    if cpoor == 1
matrix `B'[2,1] = _b[schooling]
matrix `B'[2,2] = _b[schooling] - invttail(e(df_r), .025)*_se[schooling]
matrix `B'[2,3] = _b[schooling] + invttail(e(df_r), .025)*_se[schooling]

di as text "never poor : " as result %6.4f `B'[1,1] ///
   as text "  [" as result %6.4f `B'[1,2] as text ", " ///
   as result %6.4f `B'[1,3] as text "]"
di as text "child poor : " as result %6.4f `B'[2,1] ///
   as text "  [" as result %6.4f `B'[2,2] as text ", " ///
   as result %6.4f `B'[2,3] as text "]"

* --- tiny plotting dataset ----------------------------------------------------
clear
quietly set obs 2
gen byte  x    = _n                  // 1 = never poor, 2 = childhood poor
gen double b   = .
gen double lo  = .
gen double hi  = .
replace b  = `B'[1,1] in 1
replace lo = `B'[1,2] in 1
replace hi = `B'[1,3] in 1
replace b  = `B'[2,1] in 2
replace lo = `B'[2,2] in 2
replace hi = `B'[2,3] in 2

gen str12 blab = string(b, "%6.4f")

* --- draw --------------------------------------------------------------------
* One message: the same year of schooling pays visibly less for the childhood
* poor. Direct labels, no legend, deck palette, paper background.

* -mlabposition(4)- (lower right) keeps the 0.0896 label off the 0.09
* gridline it would otherwise sit on; both series use it for consistency.
* NOTE: never put a comment line inside a /// continuation block -- Stata
* reads it as part of the command and fails with r(198).

graph twoway ///
    (rcap hi lo x if x == 1, lcolor("140 47 57")  lwidth(medthick))       ///
    (rcap hi lo x if x == 2, lcolor("62 107 116") lwidth(medthick))       ///
    (scatter b x if x == 1, mcolor("140 47 57")  msymbol(circle)          ///
        msize(vlarge) mlabel(blab) mlabposition(4) mlabgap(2)             ///
        mlabcolor("140 47 57") mlabsize(vlarge))                          ///
    (scatter b x if x == 2, mcolor("62 107 116") msymbol(circle)          ///
        msize(vlarge) mlabel(blab) mlabposition(4) mlabgap(2)             ///
        mlabcolor("62 107 116") mlabsize(vlarge))                         ///
    , legend(off)                                                         ///
    xlabel(1 `""Never poor" "in childhood""'                              ///
           2 `""Poor" "in childhood""'                                    ///
           , labsize(vlarge) labcolor("34 48 63") noticks nogrid)         ///
    xscale(range(0.5 2.6) lcolor("250 248 243"))                          ///
    ylabel(0.05 "0.05" 0.07 "0.07" 0.09 "0.09"                            ///
           , labsize(vlarge) labcolor("107 101 96") angle(horizontal)     ///
           glcolor("220 214 201") glwidth(vthin) noticks)                 ///
    yscale(range(0.045 0.098) lcolor("250 248 243"))                      ///
    ytitle("Return to one year of schooling", size(vlarge)                ///
           color("34 48 63") margin(right))                               ///
    xtitle("")                                                            ///
    graphregion(color("250 248 243") margin(medium))                      ///
    plotregion(color("250 248 243") margin(medium))                       ///
    xsize(6.4) ysize(4.2)

capture mkdir "slides"
capture mkdir "slides/figures"
graph export "slides/figures/fig_returns_gap.pdf", replace

di as result _n "Wrote slides/figures/fig_returns_gap.pdf"
exit
