# ---------------------------------------------------------------------------
# scripts/run_analysis.R
# Main pipeline. Writes all artefacts to output/.
# Usage: Rscript scripts/run_analysis.R
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(ggplot2)
})

# Source modules in order
r_files <- sort(list.files(here("R"), pattern = "\\.R$", full.names = TRUE))
invisible(lapply(r_files, source))

message("→ Loading data")
data <- load_bank_data()

message("→ Running Dynamic Network DEA")
results <- dynamic_network_dea(data)
summary_tbl <- summarize_bank_performance(results)

message("→ Bootstrap confidence intervals (Stage 1)")
boot_stage1 <- bootstrap_by_year(data, stage = "stage1", n_boot = 1000)

message("→ Bootstrap confidence intervals (Stage 2)")
boot_stage2 <- bootstrap_by_year(data, stage = "stage2", n_boot = 1000)

message("→ Malmquist Productivity Index")
mpi <- malmquist_index(data)

message("→ Sensitivity analysis (carry-over: investments)")
sens_inv <- sensitivity_carry_rates(data, param = "investime")

message("→ Writing outputs")
out <- here("output")
write.csv(results,     file.path(out, "network_dea_results.csv"),   row.names = FALSE)
write.csv(summary_tbl, file.path(out, "bank_performance_summary.csv"), row.names = FALSE)
write.csv(boot_stage1, file.path(out, "bootstrap_stage1.csv"),      row.names = FALSE)
write.csv(boot_stage2, file.path(out, "bootstrap_stage2.csv"),      row.names = FALSE)
write.csv(mpi,         file.path(out, "malmquist_index.csv"),       row.names = FALSE)
write.csv(sens_inv,    file.path(out, "sensitivity_investments.csv"), row.names = FALSE)

ggsave(file.path(out, "network_trends.png"),
       plot_network_trends(results), width = 11, height = 7, dpi = 200)
ggsave(file.path(out, "stage_scatter.png"),
       plot_stage_scatter(results), width = 9, height = 7, dpi = 200)
ggsave(file.path(out, "bootstrap_stage1_ci.png"),
       plot_bootstrap_ci(boot_stage1), width = 9, height = 11, dpi = 200)
ggsave(file.path(out, "malmquist.png"),
       plot_malmquist(mpi), width = 11, height = 8, dpi = 200)
ggsave(file.path(out, "sensitivity_investments.png"),
       plot_sensitivity(sens_inv), width = 10, height = 7, dpi = 200)

message("✓ Pipeline complete. Artefacts in output/")
print(summary_tbl)
