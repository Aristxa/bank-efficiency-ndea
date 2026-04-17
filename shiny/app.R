# ---------------------------------------------------------------------------
# shiny/app.R
# Shiny dashboard for the Dynamic Network DEA results.
# Run: shiny::runApp("shiny")
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(ggplot2)
  library(plotly)
  library(DT)
  library(here)
})

r_files <- sort(list.files(here("R"), pattern = "\\.R$", full.names = TRUE))
invisible(lapply(r_files, source))

data_cached <- load_bank_data()

ui <- page_navbar(
  title = "Albanian Banks — Dynamic Network DEA",
  theme = bs_theme(bootswatch = "flatly"),

  nav_panel(
    title = "Efficiency Explorer",
    layout_sidebar(
      sidebar = sidebar(
        width = 320,
        h4("Carry-over rates"),
        helpText("Share of each intermediate product carried into next year."),
        sliderInput("carry_inv",  "Investments",  0, 0.8, 0.30, step = 0.05),
        sliderInput("carry_card", "Cards",        0, 0.8, 0.50, step = 0.05),
        sliderInput("carry_loan", "Loans",        0, 0.8, 0.20, step = 0.05),
        hr(),
        selectInput("rts", "Returns to scale",
                    choices = c("VRS" = "vrs", "CRS" = "crs"),
                    selected = "vrs"),
        selectInput("orient", "Orientation",
                    choices = c("Input" = "in", "Output" = "out"),
                    selected = "in"),
        actionButton("reset", "Reset to baseline", class = "btn-secondary btn-sm")
      ),

      layout_columns(
        col_widths = c(6, 6),
        card(card_header("Network Efficiency Trend"),
             plotlyOutput("trend_plot", height = "380px")),
        card(card_header("Stage 1 vs Stage 2"),
             plotlyOutput("scatter_plot", height = "380px"))
      ),
      card(card_header("Summary by Bank"),
           DTOutput("summary_tbl"))
    )
  ),

  nav_panel(
    title = "Malmquist",
    card(card_header("Productivity Index Decomposition"),
         plotOutput("mpi_plot", height = "520px")),
    card(card_header("Detail"),
         DTOutput("mpi_tbl"))
  ),

  nav_panel(
    title = "Sensitivity",
    layout_sidebar(
      sidebar = sidebar(
        selectInput("sens_param", "Parameter to sweep",
                    choices = c("Investments" = "investime",
                                "Cards"       = "karta",
                                "Loans"       = "kredi"),
                    selected = "investime")
      ),
      card(card_header("Sensitivity curve"),
           plotlyOutput("sens_plot", height = "500px")),
      card(card_header("Ranking stability"),
           DTOutput("sens_tbl"))
    )
  ),

  nav_panel(
    title = "About",
    card(card_body(
      h3("Methodology"),
      p("Dynamic Network DEA, two-stage:"),
      tags$ul(
        tags$li("Stage 1: staff, branches, deposits → investments, cards, loans"),
        tags$li("Stage 2: investments, cards, loans → net income, ROE")
      ),
      p("Carry-over effects propagate a fraction of each year's intermediate",
        "products into the next year's input base."),
      h3("Source"),
      p("Author: Aristea Gjokthomi — University of Tirana, 2025."),
      p("Code:", a("github.com/…/bank-efficiency-ndea",
                   href = "https://github.com"))
    ))
  )
)

server <- function(input, output, session) {

  rates <- reactive({
    list(investime = input$carry_inv,
         karta     = input$carry_card,
         kredi     = input$carry_loan)
  })

  results <- reactive({
    dynamic_network_dea(data_cached,
                        carry_rates = rates(),
                        rts = input$rts,
                        orientation = input$orient,
                        verbose = FALSE)
  })

  summary_tbl <- reactive({
    summarize_bank_performance(results())
  })

  observeEvent(input$reset, {
    updateSliderInput(session, "carry_inv",  value = 0.30)
    updateSliderInput(session, "carry_card", value = 0.50)
    updateSliderInput(session, "carry_loan", value = 0.20)
  })

  output$trend_plot <- renderPlotly({
    ggplotly(plot_network_trends(results()))
  })

  output$scatter_plot <- renderPlotly({
    ggplotly(plot_stage_scatter(results(), year = max(results()$Year)))
  })

  output$summary_tbl <- renderDT({
    datatable(summary_tbl(),
              options = list(pageLength = 9, dom = "t"),
              rownames = FALSE) %>%
      formatPercentage(c("Stage1_Avg", "Stage2_Avg", "Network_Avg"), 1)
  })

  mpi <- reactive(malmquist_index(data_cached))

  output$mpi_plot <- renderPlot(plot_malmquist(mpi()))
  output$mpi_tbl  <- renderDT(
    datatable(mpi(), options = list(pageLength = 20), rownames = FALSE)
  )

  sens <- reactive({
    sensitivity_carry_rates(data_cached, param = input$sens_param)
  })

  output$sens_plot <- renderPlotly({
    ggplotly(plot_sensitivity(sens()))
  })

  output$sens_tbl <- renderDT({
    datatable(sensitivity_summary(sens()),
              options = list(pageLength = 9, dom = "t"),
              rownames = FALSE) %>%
      formatPercentage(c("Min_NetworkAvg", "Max_NetworkAvg", "Range"), 1)
  })
}

shinyApp(ui, server)
