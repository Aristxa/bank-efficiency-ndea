# ---------------------------------------------------------------------------
# 05_malmquist.R
# Malmquist Productivity Index (MPI) decomposed into:
#   - EC: technical efficiency change
#   - TC: technological change (frontier shift)
#   - MPI = EC × TC
# Values > 1 = improvement, < 1 = deterioration.
# Reference: Färe, Grosskopf, Norris & Zhang (1994).
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(Benchmarking)
  library(dplyr)
})

malmquist_index <- function(data,
                            variables = dea_variables,
                            rts = "crs",
                            orientation = "in") {
  years <- sort(unique(data$Year))
  if (length(years) < 2) stop("Malmquist index requires at least two years.")

  results <- list()

  for (i in 2:length(years)) {
    y0 <- years[i - 1]
    y1 <- years[i]

    d0 <- data %>% filter(Year == y0) %>% arrange(DMU)
    d1 <- data %>% filter(Year == y1) %>% arrange(DMU)
    common_banks <- intersect(d0$DMU, d1$DMU)
    d0 <- d0 %>% filter(DMU %in% common_banks)
    d1 <- d1 %>% filter(DMU %in% common_banks)

    xs <- variables$stage1_inputs
    ys <- variables$final_outputs

    X0 <- as.matrix(d0[, xs]); Y0 <- as.matrix(d0[, ys])
    X1 <- as.matrix(d1[, xs]); Y1 <- as.matrix(d1[, ys])

    eff_00 <- dea(X0, Y0, RTS = rts, ORIENTATION = orientation)$eff
    eff_11 <- dea(X1, Y1, RTS = rts, ORIENTATION = orientation)$eff
    eff_01 <- dea(X0, Y0, XREF = X1, YREF = Y1,
                  RTS = rts, ORIENTATION = orientation)$eff
    eff_10 <- dea(X1, Y1, XREF = X0, YREF = Y0,
                  RTS = rts, ORIENTATION = orientation)$eff

    EC  <- eff_11 / eff_00
    TC  <- sqrt((eff_00 / eff_01) * (eff_10 / eff_11))
    MPI <- EC * TC

    results[[paste(y0, y1, sep = "->")]] <- data.frame(
      Period = paste(y0, "→", y1),
      Bank   = d1$DMU,
      EC     = round(EC,  4),
      TC     = round(TC,  4),
      MPI    = round(MPI, 4),
      Interpretation = case_when(
        MPI > 1.02 ~ "Productivity improved",
        MPI < 0.98 ~ "Productivity declined",
        TRUE       ~ "Roughly unchanged"
      ),
      stringsAsFactors = FALSE
    )
  }

  bind_rows(results)
}
