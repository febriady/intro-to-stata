**# Intro to Stata -- session.do
/*
This is the finished version of the do-file we build together in class. The
numbered **# lines are bookmarks: the Do-file Editor lists them, so you can
jump between tasks. The numbers match the tasks on the exercise page.

How to use it: run it line by line (select a line, then Ctrl+D on Windows or
Cmd+Shift+D on a Mac), read the output, then move on. Lines starting with *
or // are notes; Stata skips them. A note between /* and */ can run over
several lines, like this one.
*/

clear all                           // start with nothing in memory

**# 0. Folder and log (the first four lines of every do-file)
*   Change the next line to your own folder. Find it once: File > Change
*   Working Directory, pick the folder, then type  display c(pwd)  in the
*   Command window and copy what it prints.
cd "C:/Users/YOUR-NAME/Downloads/intro_to_stata"

capture log close                   // close a log if one is open; say nothing if not
log using "session.log", replace    // from here on, everything is written down

**# 1. Open the data
* File > Open prints this same line in the Results window; copy it from there.
use "wage_survey.dta", clear

* When data arrive as a spreadsheet the command differs, the idea does not:
*   import excel "file.xlsx", firstrow clear
*   import delimited "file.csv", clear

**# 2. How many people, and what is in the file
describe            // every variable, its label, how many rows: 8,000 and 10

**# 3. What do they look like
summarize           // mean, min, max, N of every number. Two things should bother you:
                    // the maximum age, and the N of schooling
tabulate cpoor      // how many grew up poor. Value labels print as words
browse              // the spreadsheet view. Close it again before you go on

**# 4. But first, those ages
histogram age       // one crushed bar: a picture shows a wrong value before any table does
list id age birthyr if age > 100
/*
Ten people aged 150 to 320. The survey was in 2014, so someone born in 1994
is 20, not 200: each age was typed with an extra zero. The file itself knows
the right value, so repair instead of throwing away. Setting them to missing,
  replace age = . if age > 100
would also work; it costs ten people in every regression that uses age.
*/
replace age = 2014 - birthyr if age > 100
summarize age       // 15 to 35 again

**# 5. What does a typical worker earn
summarize hwage, detail
/*
Mean 11,218 Rupiah an hour, median 8,571. A few high earners pull the mean
up; the median is what a typical worker earns. Report the median and say so.
(At the 2014 exchange rate that is about half a euro an hour.)
*/

**# 6. Share who finished secondary school, by background
generate high = schooling >= 12     // 1 if true, 0 if not
tabulate high, missing
/*
Wrong. Two hundred people never answered the schooling question, yet every
one of them got a 1. Stata stores a missing value as larger than any number,
so ". >= 12" is true. Say what you mean:
*/
drop high
generate high = schooling >= 12 if !missing(schooling)
tabulate high, missing              // 5,220 zeros, 2,580 ones, 200 missing
tabulate cpoor high, row            // 38 percent never poor, 21 percent grew up poor
/*
Every > or >= on a variable that can be missing needs & !missing(...) after
it. This is a Stata rule, not a law of nature. SAS does the opposite: there
a missing value is smaller than any number, so the same mistake hides in
"schooling < 12" instead. In a new program, check what it does with a
missing value before you trust any comparison.
*/

**# 7. The return to a year of schooling, with controls
generate lhwage = ln(hwage)         // the log of the wage: a change of 0.01 is about 1 percent
regress lhwage schooling female urban age i.province
/*
i.province turns one variable into a dummy per province, the first left out
as the comparison. Read two numbers. N is 7,800: the 200 without a schooling
answer are silently left out, and the N is the only place it shows. The
coefficient on schooling is 0.079: a year of schooling is associated with an
8 percent higher wage, the controls held fixed.
*/

**# 8. Did the model behave
predict yhat                        // the fitted value, from the regression in memory
predict uhat, residuals             // actual minus fitted
summarize yhat uhat
* The residuals average zero to many decimals. That is arithmetic, not a sign
* the model is good: OLS chooses the coefficients that make it so.

**# 9. One number for the relationship
correlate hwage schooling           // 0.34: no units, nothing held fixed

**# 10. Different for people who grew up poor?
regress lhwage schooling female urban age i.province if cpoor == 1
* 0.060 against 0.079 in task 7, on 2,166 people. Whether the difference is
* causal is a question for another course.

**# 11. Close the log, write the reply
log close
* Open session.log in any text editor. Every number for the reply is in it,
* next to the command that produced it.

**# When you are stuck
* help knows every command; search finds a command when you do not know its
* name. Try the first one now.
help regress
