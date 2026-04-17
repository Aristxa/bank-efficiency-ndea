# ---------------------------------------------------------------------------
# 04_bootstrap.R
# Bootstrap confidence intervals for DEA efficiency scores following
# Simar & Wilson (1998, 2000). Scores are reflected around 1 so the
# bootstrapped estimates respect the natural upper bound.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(Benchmarking)
  library(dplyr)
})

bootstrap_dea <- function(inputs, outputs,
                          n_boot = 2000,
                          rts = "vrs",
                          orientation = "in",
                          bandwidth = NULL,
                          seed = 42) {
  set.seed(seed)
  stopifnot(nrow(inputs) == nrow(outputs))
  n <- nrow(inputs)

  original <- dea(inputs, outputs, RTS = rts, ORIENTATION = orientation)$eff

  if (is.null(bandwidth)) {
    bandwidth <- 0.9 * min(sd(original), IQR(original) / 1.34) * n^(-1/5)
    if (!is.finite(bandwidth) || bandwidth <= 0) bandwidth <- 0.05
  }

  boot_eff <- matrix(NA_real_, nrow = n_boot, ncol = n)

  for (b in seq_len(n_boot)) {
    idx <- sample.int(n, replace = TRUE)
    perturb <- rnorm(n, 0, bandwidth)
    eff_star <- original[idx] + perturb
    eff_star <- ifelse(eff_star > 1, 2 - eff_star, eff_star)
    eff_star <- pmin(pmax(eff_star, 0.1), 1)

    inputs_star  <- inputs  * (eff_star / original[idx])
    outputs_star <- outputs

    boot_res <- tryCatch(
      dea(inputs_star, outputs_star, RTS = rts, ORIENTATION = orientation)$eff,
      error = function(e) rep(NA_real_, n)
    )
    boot_eff[b, ] <- boot_res
  }

  bias <- colMeans(boot_eff, na.rm = TRUE) - original
  bias_corrected <- original - bias

  data.frame(
    Eff_Original       = round(original, 4),
    Eff_BiasCorrected  = round(bias_corrected, 4),
    Bias               = round(bias, 4),
    CI_Lower_95        = round(apply(boot_eff, 2, quantile, 0.025, na.rm = TRUE), 4),
    CI_Upper_95        = round(apply(boot_eff, 2, quantile, 0.975, na.rm = TRUE), 4)
  )
}

bootstrap_by_year <- function(data,
                              variables = dea_variables,
                              stage = c("stage1", "stage2"),
                              n_boot = 2000,
                              seed = 42) {
  stage <- match.arg(stage)
  years <- sort(unique(data$Year))

  results <- lapply(years, function(year) {
    yd <- data %>% filter(Year == year) %>% arrange(DMU)
    if (stage == "stage1") {
      inp <- as.matrix(yd[, variables$stage1_inputs])
      out <- as.matrix(yd[, variables$intermediates])
    } else {
      inp <- as.matrix(yd[, variables$intermediates])
      out <- as.matrix(yd[, variables$final_outputs])
    }
    boot <- bootstrap_dea(inp, out, n_boot = n_boot, seed = seed)
    boot$Year <- year
    boot$Bank <- yd$DMU
    boot$Stage <- stage
    boot
  })

  bind_rows(results)
}
