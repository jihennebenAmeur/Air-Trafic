library(shiny)
library(shinydashboard)

source("ui.R")
source("server.R")

shinyApp(ui = ui, server = server)
