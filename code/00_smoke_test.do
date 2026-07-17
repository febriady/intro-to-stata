********************************************************************************
* 00_smoke_test.do            SEGMENT 1 of the session  |  time budget ~15 min
* -----------------------------------------------------------------------------
* Purpose : One-command check that your setup works BEFORE the session starts.
*           If this file runs without error, you are ready. It then shows you
*           the one habit every Stata user needs on day one: the LOG FILE.
* Usage   : Set Stata's working directory to the repo root (the folder that
*           contains README.md), then:  do "code/00_smoke_test.do"
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

di as text "Stata version : " as result c(stata_version)
di as text "Working dir   : " as result c(pwd)

* --- Check 1: are we in the right folder? -------------------------------
capture confirm file "data/simulated/wage_survey_raw.dta"
if _rc {
    di as error _n "PROBLEM: I cannot find data/simulated/wage_survey_raw.dta" ///
        _n "Stata is looking in: " c(pwd)                                   ///
        _n "That is probably not the unzipped folder."                     ///
        _n "Fix: File > Change Working Directory, then select the folder"  ///
        _n "that contains README.md (and make sure you UNZIPPED it)."      ///
        _n
    exit 601
}

* --- Check 2: can we load the data? --------------------------------------
use "data/simulated/wage_survey_raw.dta", clear

* --- Check 3: is it the right data? ---------------------------------------
capture assert _N == 8000
if _rc {
    di as error "PROBLEM: the dataset loaded but does not have 8,000 rows."
    di as error "Re-download the repo ZIP, or regenerate the data by running:"
    di as error "  do code/simulate_data.do"
    exit 9
}

di as result _n "SMOKE TEST PASSED. You are ready for the session."
di as text "Loaded: " as result "wage_survey_raw.dta" ///
   as text " with " as result _N as text " observations."

/*
--- The screen you are looking at ----------------------------------------
Stata is four windows and one editor:
  command   (bottom center) : type one command, Enter runs it
  results   (center)        : Stata answers here
  history   (left)          : everything you have typed; click a line to
                              reuse it (older Stata calls this pane Review)
  variables (right)         : what is in memory; click a name to insert it
(The small pane labeled "properties": ignore it today.)

The window that matters most today is none of these. The DO-FILE EDITOR,
its own window, is where you write commands, run them in blocks, and keep
them. Typing in the Command window is fine for a quick look; a do-file is
how you keep work.
*/

/*
--- Three kinds of files, and how to write notes -------------------------
This whole project is three kinds of files working together:

    .do    the DO-FILE   -- your commands, plus notes like this one
    .dta   the DATA FILE -- what -use- loads into memory
    .log   the LOG FILE  -- the transcript Stata writes back (made below)

You are inside a note right now: Stata ignores everything between the
slash-star that opened this block and the star-slash that closes it.
That is the cleanest way to write a LONG note. There are two more ways:
*/

* a star at the start of a line makes that one line a note

di as text "commands still run normally between notes"   // and two slashes
                                                         // comment out the
                                                         // rest of a line

/*
--- Your first log file --------------------------------------------------
A DO-FILE records the commands you asked for. A LOG FILE records what
Stata printed back: results, tables, error messages, everything. Open a
log at the start of a piece of work, close it at the end, and you have a
transcript you can reread next week or send to a co-author.

The file extension chooses the format:
    .log   plain text  -- opens in any editor. Use this.
    .smcl  Stata's own formatted version -- only Stata reads it nicely.
*/

capture log close mylog
log using "my_first_log.log", replace name(mylog)

di as text "Everything printed while the log is open lands in the log file."
summarize hwage schooling

log close mylog

/*
Note on -name(mylog)-: in your own work you will normally just write
    log using mywork.log, replace
    ... your commands ...
    log close
We attach a name here only so this demo cannot collide with another log
Stata may already have open. -capture- before -log close- means "try this,
and do not stop the file if it fails" -- here, if the log was not open yet.
*/

di as text _n "Wrote my_first_log.log to " as result c(pwd)
di as text "Open it and read it: that file is what a log file IS."

exit
