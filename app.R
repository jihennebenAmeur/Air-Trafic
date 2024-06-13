library(shiny)
library(shinydashboard)
library(DBI)
library(RMySQL)
library(dplyr)
library(ggplot2)
library(plotly)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = tags$div(
    tags$img(src = "airfrance_logo.png", height = "40px"),
    "Trafic Aérien"
  )),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Base de Données", tabName = "database", icon = icon("database")),
      menuItem("Méthode Utilisée", tabName = "method", icon = icon("info-circle")),
      menuItem("Mission", tabName = "mission", icon = icon("bullseye")),
      menuItem("Analyse", tabName = "analysis", icon = icon("chart-bar")),
      menuItem("Prédiction", tabName = "prediction", icon = icon("chart-line"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .skin-blue .main-header .logo {
          background-color: #002157; /* Bleu Marine */
          color: white;
          font-weight: bold;
        }
        .skin-blue .main-header .navbar {
          background-color: #002157; /* Bleu Marine */
        }
        .skin-blue .main-sidebar {
          background-color: #004b87; /* Bleu Roi */
        }
        .skin-blue .main-sidebar .sidebar .sidebar-menu .active a {
          background-color: #f5f5f5;
          color: #002157; /* Bleu Marine */
        }
        .box {
          border-top: 3px solid #002157; /* Bleu Marine */
          border-left: 3px solid #E60028;  /* Rouge */
          border-right: 3px solid #E60028; /* Rouge */
          border-bottom: 3px solid #E60028; /* Rouge */
        }
        .box-header {
          background-color: #E60028; /* Rouge */
          color: white;
          font-weight: bold;
        }
        .info-box {
          min-height: 130px;
          text-align: center;
        }
        .info-box-icon {
          height: 130px;
          line-height: 130px;
          font-size: 50px;
          background-color: #004b87; /* Bleu Roi */
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .info-box-content {
          font-size: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
          text-align: center;
        }
        .info-box-content .info-box-number {
          font-size: 28px;
          font-weight: bold;
          color: #004b87; /* Bleu Roi */
        }
        .blue-value {
          color: #004b87 !important; /* Bleu Roi */
        }
        .info-box-icon img {
          max-height: 80px;
          margin: auto;
          display: block;
        }
        .info-box-number {
          font-size: 28px;
          font-weight: bold;
        }
      "))
    ),
    tabItems(
      tabItem(tabName = "home",
              h1("Accueil"),
              p("Bienvenue sur l'application de visualisation du trafic aérien. Cette application vous permettra de visualiser et d'analyser les données de trafic aérien de manière interactive."),
              tags$img(src = "crew_image.jpg", height = "300px", style = "display: block; margin-left: auto; margin-right: auto;")
      ),
      tabItem(tabName = "dashboard",
              fluidRow(
                column(width = 4,
                       box(title = "Total Flights", status = "primary", solidHeader = TRUE, width = NULL,
                           div(style = "display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100px;",
                               tags$span(class = "blue-value", style = "font-size: 48px;", textOutput("totalFlights"))
                           )
                       )
                ),
                column(width = 4,
                       box(title = "Average Delay", status = "primary", solidHeader = TRUE, width = NULL,
                           div(style = "display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100px;",
                               tags$span(class = "blue-value", style = "font-size: 48px;", textOutput("averageDelay"))
                           )
                       )
                ),
                column(width = 4,
                       box(title = "Cancelled Flights", status = "primary", solidHeader = TRUE, width = NULL,
                           div(style = "display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100px;",
                               tags$span(class = "blue-value", style = "font-size: 48px;", textOutput("cancelledFlights"))
                           )
                       )
                )
              ),
              fluidRow(
                column(width = 6,
                       box(title = "Latest Trips", status = "primary", solidHeader = TRUE, width = NULL,
                           tableOutput("latestTrips")
                       )
                ),
                column(width = 6,
                       box(title = "Statistics", status = "primary", solidHeader = TRUE, width = NULL,
                           plotlyOutput("statistics")
                       )
                )
              ),
              fluidRow(
                column(width = 12,
                       box(title = "Flights Schedule", status = "primary", solidHeader = TRUE, width = NULL,
                           plotlyOutput("flightsSchedule")
                       )
                )
              )
      ),
      tabItem(tabName = "database",
              h2("Base de Données"),
              p("Description des différentes tables de la base de données utilisée pour cette analyse.")
      ),
      tabItem(tabName = "method",
              h2("Méthode Utilisée"),
              p("Explication de la méthode utilisée pour l'analyse des données et les prédictions.")
      ),
      tabItem(tabName = "mission",
              h2("Mission"),
              p("Description de la mission et des objectifs du projet.")
      ),
      tabItem(tabName = "analysis",
              h2("Analyse du Trafic Aérien"),
              fluidRow(
                box(title = "Number of Flights", status = "primary", solidHeader = TRUE, width = 4, textOutput("numFlights")),
                box(title = "Average Delay", status = "primary", solidHeader = TRUE, width = 4, textOutput("avgDelay")),
                box(title = "Number of Cancelled Flights", status = "primary", solidHeader = TRUE, width = 4, textOutput("numCancelled"))
              ),
              fluidRow(
                box(title = "Flights per Day", status = "primary", solidHeader = TRUE, width = 12, plotlyOutput("flightsPerDay"))
              ),
              fluidRow(
                box(title = "Cancelled Flights by Destination", status = "danger", solidHeader = TRUE, width = 12, plotlyOutput("cancelledByDestination"))
              ),
              fluidRow(
                box(title = "Delays by Destination", status = "warning", solidHeader = TRUE, width = 12, plotlyOutput("delaysByDestination"))
              )
      ),
      tabItem(tabName = "prediction",
              h2("Prédiction du Trafic Aérien"),
              fluidRow(
                box(title = "Predicted Traffic", status = "success", solidHeader = TRUE, width = 12, plotlyOutput("predictedTraffic"))
              )
      )
    )
  )
)

# Define server logic
server <- function(input, output) {
  # Function to get database connection
  get_db_connection <- function() {
    dbConnect(RMySQL::MySQL(),
              dbname = "traficaerien_1",
              host = "mysql-traficaerien.alwaysdata.net",
              user = "363266",
              password = "Ipssi22")
  }
  
  output$totalFlights <- renderText({
    850
  })
  
  output$averageDelay <- renderText({
    "12.96 min"
  })
  
  output$cancelledFlights <- renderText({
    21100
  })
  
  # Overview statistics
  output$numFlights <- renderText({
    conn <- get_db_connection()
    num_flights <- dbGetQuery(conn, "SELECT COUNT(*) AS num FROM flights")
    dbDisconnect(conn)
    num_flights$num
  })
  
  output$avgDelay <- renderText({
    conn <- get_db_connection()
    avg_delay <- dbGetQuery(conn, "SELECT AVG(dep_delay) AS avg_delay FROM flights WHERE dep_delay IS NOT NULL")
    dbDisconnect(conn)
    round(avg_delay$avg_delay, 2)
  })
  
  output$numCancelled <- renderText({
    conn <- get_db_connection()
    num_cancelled <- dbGetQuery(conn, "SELECT COUNT(*) AS num_cancelled FROM flights WHERE dep_time IS NULL AND arr_time IS NULL")
    dbDisconnect(conn)
    num_cancelled$num_cancelled
  })
  
  # Plot: Flights per Day
  output$flightsPerDay <- renderPlotly({
    conn <- get_db_connection()
    flights_per_day <- dbGetQuery(conn, "SELECT DATE(dep_time) AS flight_date, COUNT(*) AS num_flights FROM flights WHERE dep_time IS NOT NULL GROUP BY flight_date")
    dbDisconnect(conn)
    
    p <- ggplot(flights_per_day, aes(x = flight_date, y = num_flights)) +
      geom_line(color = "blue") +
      labs(title = "Number of Flights per Day", x = "Date", y = "Number of Flights") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Plot: Cancelled Flights by Destination
  output$cancelledByDestination <- renderPlotly({
    conn <- get_db_connection()
    cancelled_by_destination <- dbGetQuery(conn, "SELECT destination, COUNT(*) AS num_cancelled FROM flights WHERE dep_time IS NULL AND arr_time IS NULL GROUP BY destination")
    dbDisconnect(conn)
    
    p <- ggplot(cancelled_by_destination, aes(x = reorder(destination, -num_cancelled), y = num_cancelled)) +
      geom_bar(stat = "identity", fill = "red") +
      coord_flip() +
      labs(title = "Cancelled Flights by Destination", x = "Destination", y = "Number of Cancelled Flights") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Plot: Delays by Destination
  output$delaysByDestination <- renderPlotly({
    conn <- get_db_connection()
    delays_by_destination <- dbGetQuery(conn, "SELECT destination, AVG(dep_delay) AS avg_delay FROM flights WHERE dep_delay IS NOT NULL GROUP BY destination")
    dbDisconnect(conn)
    
    p <- ggplot(delays_by_destination, aes(x = reorder(destination, -avg_delay), y = avg_delay)) +
      geom_bar(stat = "identity", fill = "orange") +
      coord_flip() +
      labs(title = "Average Delays by Destination", x = "Destination", y = "Average Delay (minutes)") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Example: Latest Trips Table
  output$latestTrips <- renderTable({
    data.frame(
      Name = c("John Doe", "Jane Smith"),
      Flight = c("Qatar", "Emirates"),
      Members = c(5, 2),
      `Ticket Price` = c("$56k", "$40k")
    )
  })
  
  # Example: Statistics Plot
  output$statistics <- renderPlotly({
    stats <- data.frame(
      Month = factor(c("Jan", "Feb", "Mar", "Apr", "May", "Jun"), levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun")),
      Flights = c(10, 12, 15, 8, 10, 14),
      Passengers = c(30, 25, 35, 20, 25, 30)
    )
    
    p <- ggplot(stats, aes(x = Month)) +
      geom_bar(aes(y = Flights), stat = "identity", fill = "blue") +
      geom_line(aes(y = Passengers, group = 1, color = "green")) +
      labs(title = "Monthly Statistics", y = "Flights / Passengers (in 100s)", color = "") +
      scale_color_manual(values = c("green" = "green")) +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Example: Flights Schedule Plot
  output$flightsSchedule <- renderPlotly({
    schedule <- data.frame(
      Month = factor(c("Jan", "Feb", "Mar", "Apr", "May", "Jun"), levels = c("Jan", "Feb", "Mar", "Apr", "May", "Jun")),
      Flights = c(10, 12, 15, 8, 10, 14)
    )
    
    p <- ggplot(schedule, aes(x = Month, y = Flights)) +
      geom_line(color = "blue") +
      geom_point(color = "red", size = 3) +
      labs(title = "Flights Schedule", y = "Number of Flights") +
      theme_minimal()
    
    ggplotly(p)
  })
}

# Run the application
shinyApp(ui = ui, server = server)



