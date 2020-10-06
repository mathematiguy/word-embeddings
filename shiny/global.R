library(here)
library(shiny)

source(here('shiny/utils.R'))
source(here('shiny/ui.R'))
source(here('shiny/server.R'))

# Create Shiny app ----
app <- shinyApp(ui = ui, server = server)

runApp(app, port = 7727, host = "0.0.0.0")
