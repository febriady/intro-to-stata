********************************************************************************
* module_E_project_structure.do  OPTIONAL self-study module E (SHORT) | ~10 min
* -----------------------------------------------------------------------------
* Topic   : how a real research project is organized -- and the file you are
*           reading IS the lesson: it is a MASTER DO-FILE, the one file that
*           runs a whole project from top to bottom.
* Needs   : run from the repo root (the folder containing README.md), like
*           everything else here. Nothing else -- this file does the rest.
* Why it  : the day you have a thesis with a supervisor, or a paper with a
* matters   coauthor, "can you re-run everything?" must be one command, not
*           an act of memory. This module is the bridge from class exercise
*           to that project.
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

*==============================================================================
* E1. The master do-file: the whole project, in order, one command
*==============================================================================

* A project is a PIPELINE: clean, then build, then estimate. The README
* warns what happens when you run the pieces out of order (a later file
* complains about a missing variable). A master do-file makes the order
* itself code -- so it can never be misremembered.

di as result _n "=== master: running the whole session pipeline ==="

do "code/02_cleaning_missings.do"
do "code/03_generate_variables.do"
do "code/04_mincer_regression.do"

di as result _n "=== master: pipeline done ==="

/*
Three lines. That was the entire empirical arc of the session -- and if
you edit anything in 02, rerunning THIS file guarantees 03 and 04 see
the change. (Note what is NOT here: simulate_data.do. The raw data are
an input to the project, not a product of it; regenerating them is a
separate, deliberate act.)
*/

*==============================================================================
* E2. Portable paths: why this repo runs on every computer unchanged
*==============================================================================

* Search every do-file in this repo for a path like the one below. You
* will find none -- and that absence is a design decision, not luck.

capture noisily use "C:/Users/somebody/thesis/data/wage_survey_raw.dta", clear

/*
That error is the fate of every ABSOLUTE path: it names one person's
machine, so it works on exactly one computer in the world. (The
-capture- swallowed the error so this file could continue; your data
in memory are untouched -- a failed -use, clear- clears nothing.)

THE RULE: inside a project, every path is RELATIVE to the project
root -- "data/simulated/...", "code/02_...". The root itself is the
one thing each person supplies, once, by setting the working
directory. That is what the smoke test was really checking on day
one: not whether Stata works, but whether you had told it where the
project lives.
*/

*==============================================================================
* E3. Multiple authors: the switchboard
*==============================================================================

/*
Relative paths are also how COAUTHORED projects work. You keep the
project in OneDrive, your coauthor keeps it in Dropbox, a student in
Downloads; nothing inside the project mentions any of those, so there
is nothing to coordinate.

When a team cannot rely on everyone setting the working directory by
hand (batch jobs, servers, forgetful coauthors), absolute paths are
allowed back in -- QUARANTINED to one block, in one file, keyed by
user. The top of a coauthored master do-file looks like this:

    if c(username) == "ade"          cd "/Users/ade/OneDrive/proj"
    else if c(username) == "agnieszka" cd "C:/Users/agnieszka/Dropbox/proj"
    else {
        di as error "Unknown user: add your project root above."
        exit 601
    }

Each coauthor adds one line, once, and never touches a path again.
The doctrine in one sentence: absolute paths appear at most once per
project, in the master, behind a username switch -- everything
downstream is author-blind. See who you are to Stata:
*/

di as text "This machine's username: " as result c(username)

*==============================================================================
* E4. The rest of the anatomy (you have been using it all along)
*==============================================================================

/*
code/ for do-files, data/ for data, results/ for outputs, docs/ for
references: this repo's folders are the standard anatomy of an
empirical project, at teaching scale. Two habits from the session
complete the picture: raw data are never overwritten (cleaning writes
a NEW file, and results/ plus the clean file are ignored by version
control, because products of code do not need saving), and everything
re-runs from a fixed seed. Copy this skeleton for your thesis and you
will never wonder where a file should go.
*/

di as result _n "Module E done. The pipeline above was the lesson."
exit
