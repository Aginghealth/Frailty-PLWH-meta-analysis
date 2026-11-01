# Prevalence and Psychosocial Risk Factors of Frailty among Older People Living with HIV: A Systematic Review and Meta-Analysis

This repository contains the analysis code for the above systematic review and meta-analysis. All study-level data are embedded in the do-file, so no external dataset is required.

## Software Requirements
- Stata version 18.0
- User-written packages (first run only):
  ```stata
  ssc install metaprop, replace
  ssc install metan, replace
  ssc install metabias, replace
  ssc install metafunnel, replace
