---
title: "Homework 12"
author: "Moshood A. Garuba"
date: "2025-05-03"
output: pdf_document
---




```r
library(shiny)
library(dplyr)
library(readr)
```


```r
# Load the data
movies <- read_csv("movies.csv")

# Cleaned data
movies_clean <- movies %>%
  select(title, thtr_rel_year, audience_score, critics_score) %>%
  filter(!is.na(thtr_rel_year)) %>%
  distinct()

# Get sorted unique years
years <- sort(unique(movies_clean$thtr_rel_year))
```


```r
# Define UI
ui <- fluidPage(
  titlePanel("Movie Scores by Year"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Select Release Year", choices = years),
      radioButtons("score_type", "Choose Score Type:",
                   choices = c("Audience Score" = "audience_score",
                               "Critic Score" = "critics_score"))
    ),
    
    mainPanel(
      tableOutput("top_movies")
    )
  )
)

# Define server
server <- function(input, output) {
  output$top_movies <- renderTable({
    req(input$year)
    movies_clean %>%
      filter(thtr_rel_year == input$year) %>%
      arrange(desc(.data[[input$score_type]])) %>%
      select(title, thtr_rel_year, all_of(input$score_type)) %>%
      head(10)
  })
}

# Run app
shinyApp(ui, server)
```

```{=html}
<div style="width: 100% ; height: 400px ; text-align: center; box-sizing: border-box; -moz-box-sizing: border-box; -webkit-box-sizing: border-box;" class="muted well">Shiny applications not supported in static R Markdown documents</div>
```

