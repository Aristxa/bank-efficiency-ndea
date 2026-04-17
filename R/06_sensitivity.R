# ---------------------------------------------------------------------------
# 06_sensitivity.R
# Sensitivity analysis over the carry-over parameters. Each parameter is
# swept across a grid while the others are held at baseline, and the
# resulting shift in Network efficiency is recorded per bank.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

sensitivity_carry_rates <- function(data,
                                    param = c("investime", "karta", "kredi"),
                                    grid = seq(0.0, 0.8, by = 0.1),
                                    variables = dea_variables) {
  param <- match.arg(param)
  baseline <- default_carry_rates

  out <- lapply(grid, function(v) {
    rates <- baseline
    rates[[param]] <- v
    res <- dynamic_network_dea(data, carry_rates = rates,
                               variables = variables, verbose = FALSE)
    res %>%
      group_by(Bank) %>%
      summarise(Network_Avg = mean(Network_Eff), .groups = "drop") %>%
      mutate(Param = param, Value = v)
  })

  bind_rows(out)
}

sensitivity_summary <- function(sens_df) {
  sens_df %>%
    group_by(Bank) %>%
    summarise(
      Min_NetworkAvg = round(min(Network_Avg), 4),
      Max_NetworkAvg = round(max(Network_Avg), 4),
      Range          = round(max(Network_Avg) - min(Network_Avg), 4),
      .groups = "drop"
    ) %>%
    arrange(desc(Range))
}
