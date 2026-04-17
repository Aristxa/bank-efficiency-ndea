# Technical Efficiency of Albanian Banks — Dynamic Network DEA (2021–2023)

A Dynamic Network Data Envelopment Analysis of nine Albanian commercial
banks — Banka Kombëtare Tregtare, Raiffeisen, Credins, Intesa Sanpaolo,
OTP, Tirana Bank, Union Bank, Fibank, and ABI — over the period 2021–2023.

The banking production process is modelled as two interconnected stages.
The first stage converts labour, branches, and deposits into intermediate
products (investments, cards, loans). The second stage converts those
products into final financial outcomes (net income, ROE). Carry-over
effects propagate a share of each year's intermediate products into the
following year's input base, making the model dynamic.

## Methodology

| Stage | Inputs                                   | Outputs                                    |
|-------|------------------------------------------|--------------------------------------------|
| 1     | Staff, branches, deposits                | Investments, cards, loans (*intermediate*) |
| 2     | Investments, cards, loans                | Net income, ROE                            |

A bank's *network efficiency* is defined as the product of its Stage 1
and Stage 2 scores. Linear programmes are solved per DMU, year, and stage
using the `Benchmarking` R package.

Supplementary analyses:

- Bias-corrected bootstrap confidence intervals (Simar & Wilson, 1998).
- Malmquist productivity index, decomposed into efficiency change and
  frontier shift (Färe, Grosskopf, Norris & Zhang, 1994).
- Sensitivity analysis across the carry-over parameters.

## Data

Nine banks, three years, ten variables — sourced from the banks' annual
reports. Stored in `data/bankat_dynamic.xlsx`.

## Project structure

```
.
├── R/                    Analysis modules
│   ├── 01_load_data.R
│   ├── 02_dea_functions.R
│   ├── 03_dynamic_network_dea.R
│   ├── 04_bootstrap.R
│   ├── 05_malmquist.R
│   ├── 06_sensitivity.R
│   └── 07_visualizations.R
├── scripts/run_analysis.R   Full pipeline entry point
├── report/report.qmd        Quarto report (HTML + Plotly)
├── shiny/app.R              Interactive dashboard
├── data/                    Input dataset
├── output/                  Generated tables and figures
├── docs/                    Static site (GitHub Pages)
└── .github/workflows/       Continuous integration
```

## Requirements

- R ≥ 4.1
- [Quarto](https://quarto.org/) (optional, for rendering the report)

Install the required R packages:

```r
install.packages(c(
  "readxl", "Benchmarking", "ggplot2", "dplyr", "tidyr",
  "gridExtra", "here", "plotly", "DT", "ggrepel", "scales",
  "shiny", "bslib"
))
```

## Usage

Run the full analysis:

```bash
Rscript scripts/run_analysis.R
```

Render the HTML report:

```bash
quarto render report/report.qmd
```

Launch the interactive dashboard:

```r
shiny::runApp("shiny")
```

## Author

**Aristea Gjokthomi** — University of Tirana, Faculty of Economics,
Department of Applied Statistics and Informatics. Master's in Information
Systems in Economics (MSHSIE). Course: *Operations Research*, 2025.

## References

- Färe, R., & Grosskopf, S. (2000). Network DEA. *Socio-Economic Planning Sciences*, 34(1), 35–49.
- Färe, R., Grosskopf, S., Norris, M., & Zhang, Z. (1994). Productivity growth, technical progress, and efficiency change in industrialized countries. *American Economic Review*, 84(1), 66–83.
- Kao, C., & Hwang, S.-N. (2008). Efficiency decomposition in two-stage data envelopment analysis. *European Journal of Operational Research*, 185(1), 418–429.
- Sealey, C. W., & Lindley, J. T. (1977). Inputs, outputs, and a theory of production and cost at depository financial institutions. *Journal of Finance*, 32(4), 1251–1266.
- Simar, L., & Wilson, P. W. (1998). Sensitivity analysis of efficiency scores: how to bootstrap in nonparametric frontier models. *Management Science*, 44(1), 49–61.
- Tone, K., & Tsutsui, M. (2014). Dynamic DEA with network structure. *Omega*, 42(1), 124–131.

## License

Released under the MIT License. See [LICENSE](LICENSE).

---

## Shqip

**Efiçenca teknike e bankave në Shqipëri — Dynamic Network DEA (2021–2023)**

Analizë e efiçencës teknike të nëntë bankave tregtare shqiptare — Banka
Kombëtare Tregtare, Raiffeisen, Credins, Intesa Sanpaolo, OTP, Tirana
Bank, Union Bank, Fibank dhe ABI — për periudhën 2021–2023, duke
përdorur modelin Dynamic Network Data Envelopment Analysis.

Procesi bankar modelohet në dy faza të ndërlidhura. Faza e parë
transformon punonjësit, degët dhe depozitat në produkte ndërmjetëse
(investime, karta, kredi). Faza e dytë i kthen këto produkte në rezultate
financiare përfundimtare (të ardhura neto, ROE). Efektet *carry-over*
bartin një pjesë të produkteve ndërmjetëse të një viti në bazën e
inputeve të vitit pasardhës.

Analizat plotësuese përfshijnë intervale besueshmërie bootstrap
(Simar & Wilson, 1998), indeksin e produktivitetit Malmquist, dhe
analizën e ndjeshmërisë ndaj parametrave carry-over.

### Ekzekutimi

```bash
Rscript scripts/run_analysis.R      # pipeline i plotë
quarto render report/report.qmd     # raporti HTML
```

```r
shiny::runApp("shiny")              # panel interaktiv
```

### Autorja

**Aristea Gjokthomi** — Universiteti i Tiranës, Fakulteti i Ekonomisë,
Departamenti i Statistikës dhe Informatikës së Zbatuar. Master Shkencor
në Sisteme Informacioni në Ekonomi (MSHSIE). Lënda: *Kërkime Operacionale*, 2025.
