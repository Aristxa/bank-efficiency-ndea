# ---------------------------------------------------------------------------
# 02_dea_functions.R
# Reusable DEA primitives: efficient-frontier scores, peer attribution,
# and bottleneck classification.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(Benchmarking)
  library(dplyr)
})

run_dea <- function(inputs, outputs,
                    rts = "vrs", orientation = "in") {
  stopifnot(is.matrix(inputs), is.matrix(outputs),
            nrow(inputs) == nrow(outputs))
  dea(inputs, outputs, RTS = rts, ORIENTATION = orientation)
}

get_peers_with_weights <- function(dea_result, dmu_names) {
  apply(dea_result$lambda, 1, function(row) {
    peers <- which(row > 0.01)
    if (length(peers) == 0 || length(peers) == length(row)) {
      return("★ Efficient")
    }
    weights <- row[peers]
    paste(mapply(function(n, w) sprintf("%s(%.0f%%)", n, w * 100),
                 dmu_names[peers], weights),
          collapse = ", ")
  })
}

classify_bottleneck <- function(stage1_eff, stage2_eff, network_eff,
                                tolerance = 0.05, efficient_cutoff = 0.95) {
  case_when(
    stage1_eff < stage2_eff - tolerance ~ "Stage 1 ⚠",
    stage2_eff < stage1_eff - tolerance ~ "Stage 2 ⚠",
    network_eff >= efficient_cutoff      ~ "✓ Efficient",
    TRUE                                 ~ "≈ Balanced"
  )
}

categorize_performance <- function(network_avg) {
  case_when(
    network_avg >= 0.95 ~ "🥇 Leader",
    network_avg >= 0.85 ~ "🥈 Strong",
    network_avg >= 0.75 ~ "🥉 Average",
    TRUE                ~ "⚠ Needs improvement"
  )
}
