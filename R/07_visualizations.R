# ---------------------------------------------------------------------------
# 07_visualizations.R
# Reusable plotting helpers. Each returns a ggplot / plotly object so
# callers (run script, Quarto report, Shiny app) can compose freely.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})

bank_palette <- c("#e74c3c", "#3498db", "#2ecc71", "#f39c12",
                  "#9b59b6", "#1abc9c", "#34495e", "#e67e22", "#95a5a6")

plot_network_trends <- function(results) {
  ggplot(results, aes(x = factor(Year), y = Network_Eff,
                      group = Bank, color = Bank)) +
    geom_hline(yintercept = 0.95, linetype = "dashed",
               color = "#27ae60", alpha = 0.6) +
    geom_hline(yintercept = 0.85, linetype = "dotted",
               color = "#e67e22", alpha = 0.6) +
    geom_line(linewidth = 1.1, alpha = 0.85) +
    geom_point(size = 3) +
    scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.2),
                       labels = scales::percent_format(accuracy = 1)) +
    scale_color_manual(values = bank_palette) +
    labs(title = "Dynamic Network DEA — Efficiency Evolution 2021–2023",
         subtitle = "Network Efficiency = Stage 1 × Stage 2, with carry-over",
         x = "Year", y = "Network Efficiency",
         caption = "Green dashed = fully efficient threshold (95%).") +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom",
          plot.title = element_text(face = "bold"))
}

plot_stage_scatter <- function(results, year = NULL) {
  if (is.null(year)) year <- max(results$Year)
  d <- results %>% filter(Year == !!year)

  ggplot(d, aes(x = Stage1_Eff, y = Stage2_Eff)) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                color = "gray50") +
    geom_point(aes(size = Network_Eff, color = Bank), alpha = 0.75) +
    ggrepel::geom_text_repel(aes(label = Bank), size = 3.2,
                             show.legend = FALSE) +
    scale_size_continuous(range = c(5, 15), name = "Network\nEfficiency") +
    scale_color_manual(values = bank_palette) +
    scale_x_continuous(limits = c(0.5, 1.05),
                       labels = scales::percent_format(accuracy = 1)) +
    scale_y_continuous(limits = c(0.5, 1.05),
                       labels = scales::percent_format(accuracy = 1)) +
    labs(title = paste("Two-Stage Efficiency Decomposition —", year),
         x = "Stage 1 Efficiency (Resources → Products)",
         y = "Stage 2 Efficiency (Products → Revenue)") +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"))
}

plot_bootstrap_ci <- function(boot_df) {
  ggplot(boot_df, aes(x = reorder(Bank, Eff_BiasCorrected),
                      y = Eff_BiasCorrected)) +
    geom_errorbar(aes(ymin = CI_Lower_95, ymax = CI_Upper_95),
                  width = 0.25, color = "#34495e") +
    geom_point(size = 3, color = "#e74c3c") +
    geom_point(aes(y = Eff_Original), shape = 4, size = 3,
               color = "#3498db") +
    coord_flip() +
    facet_wrap(~ Year, ncol = 1) +
    scale_y_continuous(limits = c(0, 1.1),
                       labels = scales::percent_format(accuracy = 1)) +
    labs(title = "Bootstrap 95% Confidence Intervals for Efficiency",
         subtitle = "Red dot = bias-corrected score  |  Blue × = original DEA score",
         x = NULL, y = "Efficiency") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"))
}

plot_malmquist <- function(mpi_df) {
  mpi_long <- mpi_df %>%
    select(Period, Bank, EC, TC, MPI) %>%
    pivot_longer(c(EC, TC, MPI), names_to = "Component", values_to = "Value")

  ggplot(mpi_long, aes(x = Bank, y = Value, fill = Component)) +
    geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
    geom_col(position = position_dodge(width = 0.8), width = 0.75) +
    facet_wrap(~ Period, ncol = 1) +
    scale_fill_manual(values = c(EC = "#3498db", TC = "#e67e22", MPI = "#2ecc71")) +
    labs(title = "Malmquist Productivity Index Decomposition",
         subtitle = "MPI = EC × TC   (1.0 baseline = no change)",
         x = NULL, y = "Index value") +
    theme_minimal(base_size = 11) +
    theme(plot.title = element_text(face = "bold"),
          axis.text.x = element_text(angle = 30, hjust = 1))
}

plot_sensitivity <- function(sens_df) {
  ggplot(sens_df, aes(x = Value, y = Network_Avg,
                      color = Bank, group = Bank)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    scale_color_manual(values = bank_palette) +
    scale_y_continuous(limits = c(0, 1.05),
                       labels = scales::percent_format(accuracy = 1)) +
    labs(title = "Sensitivity of Network Efficiency to Carry-Over Rate",
         subtitle = paste("Varying parameter:", unique(sens_df$Param)),
         x = "Carry-over rate",
         y = "Average Network Efficiency") +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold"))
}
