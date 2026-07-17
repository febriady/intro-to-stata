********************************************************************************
* 01_open_inspect.do          SEGMENT 2 of the session  |  time budget ~25 min
* -----------------------------------------------------------------------------
* Goal    : open a dataset and get to know it: use, describe, summarize,
*           tabulate, browse, a first graph, and correlate.
* Data    : data/simulated/wage_survey_raw.dta  (simulated; see README)
* How to  : run this file line by line -- read a comment block, run the
*           command below it, look at the output. The comments are the
*           narration.
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

* Everything in Stata is one pattern: commands acting on the dataset in
* memory. So first, put a dataset in memory.

use "data/simulated/wage_survey_raw.dta", clear

* -clear- throws away whatever was in memory before. Stata refuses to
* overwrite unsaved data otherwise -- it is protecting you.

* -describe- is the dataset's table of contents.
describe

/*
How many observations? How many variables? (Check yourself: 8,000 and 11.)
Variable labels tell you what things ARE. Storage types (byte, int,
double) matter later; today just notice they exist.
One variable is special: "ability" is something a real survey could
never measure -- remember it exists, we return to it at the very end
of the course materials (Module C). Ignore it today.
*/

* -summarize- is the numbers' first handshake.
summarize

* What is the mean of schooling? The max of hwage? Does that max look...
* plausible? Park that thought -- it is the star of the next segment.
* Look at the N column, too: schooling has FEWER observations than the
* rest. Park that thought as well.

summarize hwage, detail

* -, detail- adds percentiles. Compare the median to the max. A median
* hourly wage around 8,000-10,000 Rupiah is sensible for Indonesia in
* 2014; check what the maximum says.

* -tabulate- is for categorical variables.
tabulate province
tabulate cpoor
tabulate cpoor female

* Roughly 28 percent of this sample grew up poor. Two-way tabulate gives
* you a cross-table; add options later, keep it simple now.

* -browse-: LOOK at your data. Always look at your data.
browse

/*
This is the spreadsheet view. Red text = string, black = numeric,
blue = numeric with value labels. You can leave it open and keep
typing commands, but close it when you are done looking -- an open
browser window is the classic way to forget what is in memory.
You can also browse a subset -- three variables, one province:
*/

browse id hwage schooling if province == 5

* A picture beats a table. Two graph commands carry most of day one,
* and both are worth meeting before anything gets cleaned.

histogram hwage, frequency

* That is not a broken graph. Nearly every worker is crushed into the
* first bar because a few wages are enormous -- so a histogram is also
* the fastest outlier detector you own. Remember this shape; it gets
* redrawn after cleaning and becomes a different picture.

histogram schooling, discrete frequency

* -discrete- puts one bar per value, which is what you want for whole
* years of schooling. Note the bar at zero: people with no schooling.

twoway scatter hwage schooling

/*
-scatter- asks whether two variables move together. Y first, then X:
-scatter hwage schooling- puts wage on the vertical axis. Again the
outliers flatten everything into the floor of the graph.
To keep a graph, export it:
    graph export "myfigure.png", replace
(Not run here -- it would drop a file in your folder.)
*/

* The scatter shows a relationship. -correlate- puts one number on it:
* +1 is a perfect straight line up, -1 perfect down, 0 none.

correlate hwage schooling

/*
Read that number out loud. About -0.0003 -- essentially ZERO, and if
anything slightly negative. Taken at face value it says schooling has
nothing to do with wages. Do you believe that?
In two segments you will estimate that each extra year of schooling
goes with roughly 8 percent higher wages -- from THIS dataset. Both
numbers are correct arithmetic on the same 8,000 rows.
The difference is ten wages that were typed in a thousand times too
large. Correlation is computed from the actual values, so a handful
of absurd ones is enough to drown a real signal completely. Uncleaned,
these data say education does not pay.
Also remember what correlation is even asking: how close the cloud
sits to a STRAIGHT line. A strong curved relationship can show up
here as nearly zero.
-correlate- drops any row missing either variable. -pwcorr- keeps
each pair separately, so different cells can rest on different
samples. Know which one you ran before you quote the number.
*/

* Before moving on, name one thing that looked WRONG in this dataset.
* (There are at least two: that maximum wage, and schooling's shrunken N.)
* That is exactly where the next segment goes: cleaning.

exit
