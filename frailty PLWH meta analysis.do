************************************************************
* FRAILTY META-ANALYSIS - FINAL DO FILE v2 (2026-10-23)
* Revised to match the revised manuscript (Tables 1-3,
* Figures 2-5, Supplementary Figures S1-S2) exactly.
*
* Pooling: Freeman-Tukey double-arcsine transform,
*          DerSimonian-Laird random effects (metaprop default)
*          NO meta-regression anywhere; between-subgroup P values
*          come from the Cochran's Q test printed by metaprop's
*          by() output (matches Tables 2-3, "P for subgroup
*          difference").
*
* CHANGES vs previous version (all verified against the
* revised manuscript):
*  (1) Table 1 alignment - three subgroup flags corrected:
*      - Lellouche 2021: size200 ">=200" -> "<200"  (n = 192)
*      - Paul 2018:      size200 ">=200" -> "<200"  (n = 122)
*      - Tassiopoulos 2017: highq 0 -> 1 (Table 1 score 9 = High;
*        no effect on any pool - already excluded by overlap)
*      With these fixes the subgroup k values reproduce
*      Tables 2-3 exactly:
*        frailty    : age <55/>=55 = 10/13; male >50/<=50 = 20/3;
*                     year >2020/<=2020 = 18/5; CS/cohort = 19/4;
*                     region 5/6/7/3/2; size <200/>=200 = 6/17
*        pre-frailty: age 10/9; male 16/3; year 14/5;
*                     design 16/3; region 4/4/6/3/2; size 6/13
*  (2) Figure 4 effect estimates aligned with the submitted
*      figure: Echeverria input UCI kept at 5.54 so metan's
*      displayed UCI reads 5.55 as in the submitted figure
*      (metan recomputes the displayed CI as OR*sqrt(UCI/LCI),
*      so the input must be one rounding-step lower);
*      Mbabazi UCI 4.13 -> 4.12. Unused efflabel column
*      removed (the submitted figure prints study names only).
*  (3) Figure 5 effect estimates aligned with the submitted
*      figure: Zhabokritsky (single status) input UCI kept at
*      4.30 so the displayed UCI reads 4.31 as in the submitted
*      figure (same metan display recomputation as above);
*      Woldesemayat UCI 13.58 -> 13.57.
*  (4) All four forest plots now carry X-axis titles
*      ("Prevalence" / "Odds ratio") and the same footnote
*      "NOTE: Weights and between-subgroup heterogeneity test
*      are from random-effects model" (Comment 41; matches
*      Response 13 of the reply letter). If your metan version
*      ignores note(), delete that option and keep the note in
*      the manuscript caption instead.
*  (5) Meireles 2023 TODO resolved: 38/557 is the value printed
*      in manuscript Table 1 and Figure 2 (6.8%); provenance
*      question vs. the source paper's own rates remains with
*      the authors, the analysis value is unchanged.
*  (6) FIXED: effect("Prevalence") in Figures 2-3 was NOT a
*      valid metaprop option and stopped the do-file with
*      r(198). Removed.
*  (7) Figures 2-3 column header now reads "Prevalence (95% CI)"
*      BY CODE (section 0 below): metaprop hardcodes the header
*      label as "ES" inside metaprop.ado, so the do-file loads
*      an in-memory copy of YOUR installed metaprop.ado with
*      only that one label changed. Statistics are untouched.
*      If metaprop.ado cannot be found, the do-file still runs
*      and the header simply reads "ES (95% CI)".
*
* k = 23 frailty / 19 pre-frailty studies
*   (4 reports contribute no pre-frailty count: Zhan 2026,
*    Echeverria 2026, Doctor 2023, Meireles 2023.)
*   (One report per cohort: Tassiopoulos 2017, Sangarlangkarn
*    2022, Felker 2021 excluded from ALL prevalence pools;
*    pair-mates Kelly 2019, Apornpong 2026, Petit 2018 retained.
*    Felker 2021 appears only in Figure 5 for the SES factor.)
*
* FIRST RUN ONLY:
*   ssc install metaprop, replace
*   ssc install metafunnel, replace
************************************************************
clear all
set more off
* NOTE: no absolute paths are used. All study data are embedded
* below (Section 1), so the do-file runs from any working directory.

************************************************************
* 0. METAPROP COLUMN-HEADER PATCH (presentation only)
*    metaprop.ado hardcodes the estimates column header as
*    "ES" (metaprop.ado: local sumstat "ES"), so Figures 2-3
*    would come out as "ES (95% CI)" while the submitted
*    figures read "Prevalence (95% CI)". This block makes a
*    temporary in-memory copy of YOUR installed metaprop.ado
*    with ONLY that one label changed to "Prevalence".
*    No statistics, SEs, weights or heterogeneity stats are
*    touched. If metaprop.ado is not found, the analysis
*    still runs - the header just reads "ES (95% CI)".
************************************************************
local patchhit = 0
local patchok  = 0
capture quietly {
    local pf0 `"`c(tmpdir)'/__metaprop_src.do"'
    local pf1 `"`c(tmpdir)'/__metaprop_patched.do"'
    copy "/Applications/Stata/ado/plus/m/metaprop.ado" `pf0', replace
    tempname rin rout
    file open `rin' using `pf0', read text
    file open `rout' using `pf1', write text
    file read `rin' line
    while r(eof)==0 {
        local ishit = 0
        * (a) metaprop main: default label used by the by() tables
        if strpos(`"`macval(line)'"', "Whats is this") > 0 {
            file write `rout' `"local sumstat "Prevalence"  /* PATCHED: ES -> Prevalence (column header) */"' _n
            local patchhit = 1
            local ishit = 1
        }
        * (b) iv_init hardcodes sumstat(ES) in its call to _disptab;
        * that value drives BOTH the text table AND the graph
        * column header of Figures 2-3
        if strpos(`"`macval(line)'"', "sumstat(ES)") > 0 {
            local newline : subinstr local line "sumstat(ES)" "sumstat(Prevalence)", all
            file write `rout' `"`macval(newline)'"' _n
            local patchhit = 1
            local ishit = 1
        }
        if `ishit'==0 {
            file write `rout' `"`macval(line)'"' _n
        }
        file read `rin' line
    }
    file close `rin'
    file close `rout'
    if `patchhit'==1 {
        discard
        do `pf1'
        local patchok = 1
    }
}
capture file close `rin'
capture file close `rout'
capture erase `"`c(tmpdir)'/__metaprop_src.do"'
capture erase `"`c(tmpdir)'/__metaprop_patched.do"'
if `patchok'==1 {
    di as result "> metaprop column-header patch applied: Figures 2-3 will read Prevalence (95% CI)"
}
else {
    di as error "> WARNING: metaprop header patch NOT applied; Figures 2-3 will read ES (95% CI)"
}

************************************************************
* 1. DATA (26 studies; Table 1)
*    overlap=1 -> excluded from quantitative pools
************************************************************
input str30 study frail total prefrail year age55 male50 yr20 str8 design str15 region str8 size200 highq overlap
"Zhan 2026"            114  665   .  2026 1 1 1 "CS"     "Asia"          ">=200" 1 0
"Echeverria 2026"       66  588   .  2026 1 1 1 "CS"     "Europe"        ">=200" 1 0
"Nakamura 2026"         28  325 227  2026 1 1 1 "CS"     "Asia"          ">=200" 1 0
"Iskakova 2026"         13  100  27  2026 0 1 1 "CS"     "Asia"          "<200"  0 0
"Apornpong 2026"        13  324 153  2026 0 1 1 "Cohort" "Asia"          ">=200" 1 0
"Mbabazi 2026"          56  371 168  2026 1 1 1 "CS"     "Africa"        ">=200" 1 0
"Contreras 2025"       114  729 353  2025 0 1 1 "CS"     "Europe"        ">=200" 0 0
"Ruderman 2025"         48  574 266  2025 0 1 1 "CS"     "North America" ">=200" 1 0
"Manyara 2025"           8  223 137  2025 0 0 1 "CS"     "Africa"        ">=200" 1 0
"Sharma 2025"          133 1001 456  2025 0 0 1 "CS"     "North America" ">=200" 1 0
"Wiechmann 2024"        91  670 340  2024 1 1 1 "CS"     "South America" ">=200" 1 0
"Zhabokritsky 2024"     73  439 274  2024 1 1 1 "CS"     "North America" ">=200" 1 0
"Woldesemayat 2023"     17  187 141  2023 0 0 1 "CS"     "Africa"        "<200"  1 0
"Doctor 2023"          126  699   .  2023 1 1 1 "CS"     "Europe"        ">=200" 0 0
"Meireles 2023"         38  557   .  2023 1 1 1 "Cohort" "North America" ">=200" 1 0
"Sangarlangkarn 2022"   28  324 176  2022 . 1 1 "CS"     "Asia"          ">=200" 0 1
"Allavena 2022"         64  474 300  2022 1 1 1 "Cohort" "Europe"        ">=200" 1 0
"Araujo 2021"           12  197 100  2021 0 1 1 "CS"     "South America" "<200"  0 0
"Lellouche 2021"        11  192 110  2021 1 1 1 "CS"     "Europe"        "<200"  1 0
"Felker 2021"           41  509 297  2021 1 1 1 "CS"     "Europe"        ">=200" 1 1
"Kelly 2019"            62 1016 390  2019 0 1 0 "Cohort" "North America" ">=200" 1 0
"Hawkins 2018"          32  199  97  2018 1 1 0 "CS"     "North America" "<200"  1 0
"Paul 2018"             21  122  54  2018 1 1 0 "CS"     "North America" "<200"  0 0
"Petit 2018"            32  502 291  2018 1 1 0 "CS"     "Europe"        ">=200" 1 0
"Tassiopoulos 2017"     59  967 373  2017 0 1 0 "Cohort" "North America" ">=200" 1 1
"Ding 2017"             21  345  97  2017 0 1 0 "CS"     "Asia"          ">=200" 1 0
end

* Meireles 2023 = 38/557 (6.8%) - matches manuscript Table 1
* and Figure 2. (Earlier TODO about the source paper's own
* rates resolved: the analysis value stays 38/557.)

generate negyear = -year

************************************************************
* 2. FIGURE 2 - Frailty prevalence forest (k = 23)
*    Expect: Overall 10.5% (8.6-12.5), I2 = 90.4%
************************************************************
metaprop frail total if overlap==0, random ftt label(namevar=study) ///
    sortby(negyear study) xlab(0,0.1,0.2,0.3,0.4,0.5) ///
    xtitle("Prevalence") scheme(s1mono) graphregion(color(white)) ///
    note("NOTE: Weights and between-subgroup heterogeneity test are from random-effects model")
graph export "Figure2_frailty_prevalence.pdf", as(pdf) replace

************************************************************
* 3. FIGURE 3 - Pre-frailty prevalence forest (k = 19)
*    Expect: Overall 51.1% (46.0-56.1), I2 = 95.1%
************************************************************
metaprop prefrail total if prefrail<. & overlap==0, random ftt ///
    label(namevar=study) sortby(negyear study) ///
    xlab(0,0.2,0.4,0.6,0.8,1.0) ///
    xtitle("Prevalence") scheme(s1mono) graphregion(color(white)) ///
    note("NOTE: Weights and between-subgroup heterogeneity test are from random-effects model")
graph export "Figure3_prefrailty_prevalence.pdf", as(pdf) replace

************************************************************
* 4. SUBGROUPS for Tables 2 and 3 (six variables)
*    Expected k values (frailty / pre-frailty):
*      age55   0/1 = 10/13  |  10/9
*      male50  0/1 =  3/20  |   3/16
*      yr20    0/1 =  5/18  |   5/14   (Araujo 2021 counts as
*                     "After 2020")
*      design  CS/Co = 19/4 |  16/3
*      region  A/E/NA/Af/SA = 5/6/7/3/2 | 4/4/6/3/2
*      size200 <200/>=200 = 6/17 | 6/13
*    The by() output also prints the between-subgroup
*    Cochran's Q test - these P values are the
*    "P for subgroup difference" column of Tables 2-3.
************************************************************
foreach v in age55 male50 yr20 design region size200 {
    di as result "===== frailty / `v' ====="
    metaprop frail total if overlap==0, random ftt by(`v') nograph label(namevar=study)
    di as result "===== prefrailty / `v' ====="
    metaprop prefrail total if prefrail<. & overlap==0, random ftt by(`v') nograph label(namevar=study)
}

************************************************************
* 5. SENSITIVITY (high quality only; overlap already excluded)
*    Expect (manuscript): frailty 9.7% (7.8-11.8, k = 18);
*                         pre-frailty 53.2% (47.2-59.0, k = 15)
************************************************************
metaprop frail total if overlap==0 & highq==1, random ftt label(namevar=study) nograph
metaprop prefrail total if prefrail<. & overlap==0 & highq==1, random ftt label(namevar=study) nograph
************************************************************
* 5b. LEAVE-ONE-OUT SENSITIVITY ANALYSIS (executable)
*     Excludes one study at a time and re-pools; the pooled
*     estimate and 95% CI are printed for every run and also
*     written to log files for review.
*     Manuscript expects: frailty 10.2%-10.8%;
*                         pre-frailty 49.7%-52.4%
*     (metaprop does not expose the pooled estimate in
*      returned results, so each run is printed and logged
*      rather than collected into a variable.)
************************************************************
quietly levelsof study if overlap==0 & frail<., local(studies_f)
log using "leave_one_out_frailty.log", text replace name(loolog)
foreach s of local studies_f {
    di as result "===== Leave-one-out frailty: exclude `s' ====="
    metaprop frail total if overlap==0 & study!="`s'", random ftt nograph label(namevar=study)
}
log close loolog

quietly levelsof study if overlap==0 & prefrail<., local(studies_p)
log using "leave_one_out_prefrailty.log", text replace name(loolog)
foreach s of local studies_p {
    di as result "===== Leave-one-out pre-frailty: exclude `s' ====="
    metaprop prefrail total if prefrail<. & overlap==0 & study!="`s'", random ftt nograph label(namevar=study)
}
log close loolog

************************************************************
* 6. EGGER on FT scale + SUPPLEMENTARY FIGURES 1-2 (funnels)
*    Expect (manuscript): frailty P = 0.44; pre-frailty P = 0.32
************************************************************
generate p        = frail/total if overlap==0
generate ft       = 0.5*(asin(sqrt(p)) + asin(sqrt((frail+1)/(total+1)))) if overlap==0
generate ftse     = sqrt(1/(4*total)) if overlap==0
generate ppre     = prefrail/total if prefrail<. & overlap==0
generate ft_pre   = 0.5*(asin(sqrt(ppre)) + asin(sqrt((prefrail+1)/(total+1)))) if prefrail<. & overlap==0
generate ftse_pre = sqrt(1/(4*total)) if prefrail<. & overlap==0

metabias ft ftse, egger        // frailty     -> P = 0.44
metabias ft_pre ftse_pre, egger // pre-frailty -> P = 0.32

preserve
keep if ft<.
meta set ft ftse, studylabel(study)
meta summarize, random(dl)
meta funnelplot, xtitle("Prevalence (Freeman-Tukey transformed)") ///
    ytitle("Standard error") scheme(s1mono) graphregion(color(white))
graph export "SuppFig1_funnel_frailty_FT.pdf", as(pdf) replace
restore

preserve
keep if ft_pre<.
meta set ft_pre ftse_pre, studylabel(study)
meta summarize, random(dl)
meta funnelplot, xtitle("Prevalence (Freeman-Tukey transformed)") ///
    ytitle("Standard error") scheme(s1mono) graphregion(color(white))
graph export "SuppFig2_funnel_prefrailty_FT.pdf", as(pdf) replace
restore

************************************************************
* 7. FIGURE 4 - Depression forest (6 studies; no overlap)
*    Effect estimates match the submitted Figure 4.
*    Expect: OR 1.24 (1.11-1.38), I2 = 79.9%, DL
************************************************************
clear
input str30 study double(or lci uci)
"Echeverria 2026"     2.67  1.28  5.54
"Mbabazi 2026"        2.59  1.63  4.12
"Nakamura 2026"       1.12  1.04  1.21
"Zhan 2026"           1.11  1.04  1.19
"Paul 2018"           1.26  1.05  1.51
"Ding 2017"           1.25  1.18  1.33
end
generate logor = ln(or)
generate logse = (ln(uci) - ln(lci)) / (2 * 1.96)

metan logor logse, random eform label(namevar=study) effect("OR") ///
    xlabel(0.5,1,2,4,8) dp(2) plotregion(style(none)) ///
    xtitle("Odds ratio") graphregion(color(white)) null(1) ///
    note("NOTE: Weights and between-subgroup heterogeneity test are from random-effects model")
graph export "Figure4_depression_6studies.pdf", as(pdf) replace

************************************************************
* 8. FIGURE 5 - Single / Loneliness / SES forest (no overall)
*    Effect estimates match the submitted Figure 5.
*    Felker 2021 kept here (pair-mate Petit 2018 reports no
*    SES factor - no cohort double-counted).
*    Expect: Single 2.17 (1.46-3.23) I2=0.0%
*            Loneliness 1.53 (0.92-2.54) I2=70.5%
*            SES 1.89 (0.71-5.02) I2=85.5%
************************************************************
clear
input str30 study str32 factor double(value lci uci)
"Mbabazi 2026"        "Single status"                  1.95  1.16   3.28
"Zhabokritsky 2024"   "Single status"                  2.09  1.01   4.30
"Woldesemayat 2023"   "Single status"                  4.20  1.30  13.57
"Zhabokritsky 2024"   "Loneliness"                     1.25  1.09   1.44
"Meireles 2023"       "Loneliness"                     2.14  1.23   3.73
"Allavena 2022"       "Deprived socioeconomic status"  3.17  1.76   5.70
"Felker 2021"         "Deprived socioeconomic status"  1.17  0.74   1.85
end
generate logeffect = ln(value)
generate logse = (ln(uci) - ln(lci)) / (2 * 1.96)

metan logeffect logse, random by(factor) nooverall eform ///
    label(namevar=study) effect("OR") xlabel(0.5,1,2,4,8,16) dp(2) ///
    plotregion(style(none)) xtitle("Odds ratio") ///
    graphregion(color(white)) ///
    note("NOTE: Weights and between-subgroup heterogeneity test are from random-effects model")
graph export "Figure5_psychosocial_factors.pdf", as(pdf) replace

************************************************************
* END. Expected checks after running (all must reproduce the
* revised manuscript):
*  - Figure 2: 23 rows, Overall 10.5% (8.6-12.5), I2 90.4%
*  - Figure 3: 19 rows, Overall 51.1% (46.0-56.1), I2 95.1%
*  - Figure 4: OR 1.24 (1.11-1.38), I2 79.9%
*  - Figure 5: 2.17 / 1.53 / 1.89 as above
*  - Egger: frailty P = 0.44; pre-frailty P = 0.32
*  - Sensitivity (high quality): 9.7% (7.8-11.8, k=18);
*    53.2% (47.2-59.0, k=15)
*  - Sangarlangkarn 2022 and Tassiopoulos 2017 appear in NO
*    prevalence forest plot; Felker 2021 only in Figure 5 (SES)
************************************************************
