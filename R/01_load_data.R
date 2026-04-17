# ---------------------------------------------------------------------------
# 01_load_data.R
# Loads the Albanian banking data from Excel and returns a tidy data frame.
# Path is resolved via here::here() so the project is portable.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readxl)
  library(here)
  library(dplyr)
})

load_bank_data <- function(path = here("data", "bankat_dynamic.xlsx")) {
  if (!file.exists(path)) {
    stop("Data file not found at: ", path,
         "\nExpected location: data/bankat_dynamic.xlsx")
  }

  data <- read_excel(path)

  required_cols <- c("DMU", "Year", "Numri i punonjësve", "Degët",
                     "Depozitat (milion ALL)",
                     "Investime në letra me vlerë (milion ALL)",
                     "Numri i kartave të lëshuara",
                     "Kreditë e dhëna (milion ALL)",
                     "Të ardhurat neto (milion ALL)", "ROE")

  missing <- setdiff(required_cols, colnames(data))
  if (length(missing) > 0) {
    stop("Missing required columns: ", paste(missing, collapse = ", "))
  }

  data %>%
    arrange(Year, DMU) %>%
    as.data.frame()
}

# Variable groupings used across the DEA pipeline
dea_variables <- list(
  stage1_inputs = c("Numri i punonjësve", "Degët", "Depozitat (milion ALL)"),
  intermediates = c("Investime në letra me vlerë (milion ALL)",
                   "Numri i kartave të lëshuara",
                   "Kreditë e dhëna (milion ALL)"),
  final_outputs = c("Të ardhurat neto (milion ALL)", "ROE")
)

default_carry_rates <- list(
  investime = 0.30,
  karta     = 0.50,
  kredi     = 0.20
)
