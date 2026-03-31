# HRaDeX: high-resolution HDX–MS analysis made simple ⚙️🧬

HaDeX

publications

A new R package and web server (HRaDeX) enabling high-resolution analysis of HDX–MS data by reconstructing residue-level deuterium uptake rates from peptide-level measurements.

Author

BioGenies Lab

Published

May 19, 2025

Keywords

HDX-MS, protein dynamics, structural proteomics, HRaDeX, mass spectrometry, protein folding, bioinformatics tools

------------------------------------------------------------------------

📌 **Project highlights**

- ⚙️ New tool: **HRaDeX (R package + web server)**  
- 🧬 Enables **high-resolution HDX–MS analysis**  
- 🔍 Reconstructs **residue-level dynamics from peptide data**  
- 📊 Uses **extended kinetic modeling (ZS model)**  
- 🎯 Validated on **4000+ peptides across multiple datasets**

------------------------------------------------------------------------

🎉 **New paper out!** This one is all about turning messy HDX–MS data into something *actually interpretable* 😄

👉 [HRaDeX: R Package and Web Server for Computing High-Resolution Deuterium Uptake Rates for HDX–MS Data](https://doi.org/10.1021/acs.jproteome.4c00700)

------------------------------------------------------------------------

# 🔗 Try it yourself (no excuses 😉)

HRaDeX is available as both a **web application** and an **R package**, allowing flexible use across workflows, from quick exploration to large-scale analysis.

- [🌐 Web server](https://hradex.mslab-ibb.pl/)  
- [🔬 Comparative server](https://compahradex.mslab-ibb.pl/)  
- [💻 GitHub (R package)](https://github.com/hadexversum/HRaDeX)

------------------------------------------------------------------------

# 🎧 Audio summary

HDX–MS + peptide overlap + kinetic modeling = 😵‍💫

👉 So yes, this one also deserves a **quick audio breakdown 🎧**

Your browser does not support the audio element.

------------------------------------------------------------------------

# 🔬 What is this about?

**HRaDeX is a bioinformatics tool for analyzing hydrogen–deuterium exchange mass spectrometry (HDX–MS) data**, enabling reconstruction of **protein dynamics at near residue-level resolution**.

HDX–MS measures how proteins exchange hydrogen with deuterium over time, revealing:

- structural stability  
- folding dynamics  
- solvent accessibility

👉 But standard analysis is limited to **peptide-level resolution**, averaging signals across multiple residues.

------------------------------------------------------------------------

# 🚨 The core limitation

Classic HDX–MS:

- ❌ loses residue-level detail  
- ❌ averages overlapping signals  
- ❌ makes precise interpretation difficult

👉 This is where HRaDeX comes in.

------------------------------------------------------------------------

# 🧠 The idea behind HRaDeX

HRaDeX reconstructs high-resolution information using:

### 🧩 Overlapping peptides

- combines multiple fragments covering the same region

### ⚙️ Kinetic modeling

- fits uptake curves using **extended ZS model**  
- separates:
  - fast  
  - intermediate  
  - slow exchange components

👉 Each peptide becomes a mixture of dynamic populations.

------------------------------------------------------------------------

# 🎨 Visualizing protein dynamics

One of the nicest features:

👉 **RGB color encoding of exchange rates**

- 🔴 fast (flexible)  
- 🟢 intermediate  
- 🔵 slow (structured)

➡️ giving a **single-view map of dynamics across the sequence**

------------------------------------------------------------------------

# ⚙️ How the workflow works

According to the workflow:

1.  ✅ Filter invalid data  
2.  🧊 Detect “no exchange” regions  
3.  📈 Fit kinetic models  
4.  🎯 Select best model (BIC)  
5.  🔗 Aggregate overlapping peptides  
6.  🎨 Map results to sequence/structure

------------------------------------------------------------------------

# ⚙️ Two resolution strategies

HRaDeX provides:

### 1️⃣ Shortest peptide

- assigns values from smallest fragment

### 2️⃣ Weighted average

- integrates all overlapping peptides

👉 The combination enables **higher resolution than standard HDX–MS**

------------------------------------------------------------------------

# 📊 Performance & validation

Tested extensively:

- ✔️ \>4000 peptides  
- 📉 very low fitting error (RSS)  
- 🎯 ~4–7% RMSE in reconstructed uptake

👉 Meaning: **HRaDeX reliably reproduces experimental HDX behavior**

------------------------------------------------------------------------

# 🧬 What you can actually do with it

- map **flexible vs stable regions**  
- detect **binding interfaces**  
- study **allosteric effects**  
- compare **protein states**

👉 Example: binding-induced conformational changes clearly visible in case studies

------------------------------------------------------------------------

# 🚀 Why this matters

This work bridges a major gap:

👉 from **peptide-level data → residue-level interpretation**

It enables:

- better structural insight  
- more precise protein dynamics analysis  
- improved reproducibility

------------------------------------------------------------------------

# ⚠️ Limitations

- depends on **peptide coverage**  
- requires **good experimental design**  
- resolution limited if overlap is low

👉 Still a major step forward compared to standard pipelines

![](../fig/tools/hradex.png)

# 📌 Publication metadata

- **Title:** HRaDeX: R Package and Web Server for Computing High-Resolution Deuterium Uptake Rates for HDX–MS Data  
- **Journal:** Journal of Proteome Research  
- **Year:** 2025  
- **DOI:** https://doi.org/10.1021/acs.jproteome.4c00700
- **Authors:** Weronika Puchała, Michał Kistowski, Liliya Zhukova, Michał Burdukiewicz, Michał Dadlez
- **Type:** Software / methods  
- **Domain:** structural proteomics

------------------------------------------------------------------------

# 🏷️ Keywords

HDX-MS, protein dynamics, structural proteomics, deuterium exchange, mass spectrometry, protein folding, bioinformatics tools, kinetic modeling
