# ---------------------------------------------------------------------------
# 03_dynamic_network_dea.R
# Core Dynamic Network DEA engine. Splits the banking production process
# into two stages and propagates carry-over effects across years.
#
# Stage 1: staff + branches + deposits -> investments + cards + loans
# Stage 2: investments + cards + loans -> net income + ROE
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

dynamic_network_dea <- function(data,
                                carry_rates = default_carry_rates,
                                variables = dea_variables,
                                rts = "vrs",
                                orientation = "in",
                                verbose = TRUE) {
  years <- sort(unique(data$Year))
  all_results <- list()
  prev_intermediate <- NULL

  for (i in seq_along(years)) {
    year <- years[i]
    year_data <- data %>%
      filter(Year == year) %>%
      arrange(DMU)

    inputs_stage1 <- as.matrix(year_data[, variables$stage1_inputs])
    intermediates <- as.matrix(year_data[, variables$intermediates])
    final_outputs <- as.matrix(year_data[, variables$final_outputs])

    inputs_stage1_expanded <- inputs_stage1
    if (i > 1 && !is.null(prev_intermediate)) {
      if (carry_rates$investime > 0) {
        inputs_stage1_expanded <- cbind(
          inputs_stage1_expanded,
          carry_investments = prev_intermediate[, 1] * carry_rates$investime
        )
      }
      if (carry_rates$kredi > 0) {
        inputs_stage1_expanded <- cbind(
          inputs_stage1_expanded,
          carry_loans = prev_intermediate[, 3] * carry_rates$kredi
        )
      }
    }

    stage1 <- run_dea(inputs_stage1_expanded, intermediates, rts, orientation)
    stage2 <- run_dea(intermediates,         final_outputs, rts, orientation)
    network_eff <- stage1$eff * stage2$eff

    year_results <- data.frame(
      Year = year,
      Bank = year_data$DMU,
      Stage1_Eff  = round(stage1$eff, 4),
      Stage2_Eff  = round(stage2$eff, 4),
      Network_Eff = round(network_eff, 4),
      Stage1_Peers = get_peers_with_weights(stage1, year_data$DMU),
      Stage2_Peers = get_peers_with_weights(stage2, year_data$DMU),
      Bottleneck  = classify_bottleneck(stage1$eff, stage2$eff, network_eff),
      stringsAsFactors = FALSE
    )

    if (verbose) {
      message(sprintf("[%d] mean Network Eff = %.3f  |  fully efficient = %d/%d",
                      year,
                      mean(year_results$Network_Eff),
                      sum(year_results$Network_Eff >= 0.95),
                      nrow(year_results)))
    }

    all_results[[as.character(year)]] <- year_results
    prev_intermediate <- intermediates
  }

  bind_rows(all_results)
}

summarize_bank_performance <- function(results) {
  results %>%
    group_by(Bank) %>%
    summarise(
      Stage1_Avg  = round(mean(Stage1_Eff),  4),
      Stage2_Avg  = round(mean(Stage2_Eff),  4),
      Network_Avg = round(mean(Network_Eff), 4),
      Years_Efficient = sum(Network_Eff >= 0.95),
      .groups = "drop"
    ) %>%
    mutate(Category = categorize_performance(Network_Avg)) %>%
    arrange(desc(Network_Avg))
}
