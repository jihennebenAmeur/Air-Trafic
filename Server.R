library(shiny)
library(jsonlite)
library(DBI)
library(RMySQL)
library(ggplot2)
library(dplyr)
library(ggplot2)
library(lubridate)
library(plotly)

chargement_depuis_txt <- function() {
  airports <- read.table("data/airport.txt", header = TRUE, sep = "\t")
  planes <- read.table("data/planes.txt", header = TRUE, sep = "\t")
  weather <- read.table("data/weather.txt", header = TRUE, sep = "\t")
  flights <- read.table("data/flights.txt", header = TRUE, sep = "\t")
  
  list(
    num_airports = nrow(airports),
    num_planes = nrow(planes),
    num_weather_records = nrow(weather),
    num_flights = nrow(flights)
  )
}

chargement_depuis_json <- function() {
  airlines <- fromJSON("data/airlines.json")
  num_airlines <- nrow(airlines)
  
  list(
    num_airlines = num_airlines
  )
}

chargement_depuis_db <- function() {
  con <- dbConnect(RMySQL::MySQL(),
                   dbname = "traficaerien_1",
                   host = "mysql-traficaerien.alwaysdata.net",
                   user = "363266",
                   password = "Ipssi22")
  on.exit(dbDisconnect(con))
  
  flight <- dbGetQuery(con, "SELECT * FROM flights")
  plane<-dbGetQuery(con, "SELECT * FROM planes")
  airport<-dbGetQuery(con, "SELECT * FROM airports")
  
  
  
  avg_delay <- mean(flights$dep_delay, na.rm = TRUE)
  num_cancelled <- sum(flights$cancelled)
  
  list(
    flights=flight,
    num_flights1 = nrow(flight),
    num_planes1=nrow(plane),
    num_airports1=nrow(airport),
    
    avg_delay = avg_delay,
    num_cancelled = num_cancelled
    # Ajoutez d'autres statistiques si nécessaire
  )
}

# Définition du serveur

server <- function(input, output, session) {
  conn <- dbConnect(RMySQL::MySQL(),
                    dbname = "traficaerien_1",
                    host = "mysql-traficaerien.alwaysdata.net",
                    user = "363266",
                    password = "Ipssi22")
  
  # 1. Transformation des colonnes en datetime et suppression des colonnes
  # Chargement des données des vols et des compagnies aériennes
  
  output$totalFlights <- renderValueBox({
    data <- dbGetQuery(conn, "SELECT COUNT(*) AS total FROM flights")
    valueBox(formatC(data$total, format = "d"), "Total Flights", icon = icon("plane"), color = "aqua")
  })
  
  output$averageDelay <- renderValueBox({
    data <- dbGetQuery(conn, "SELECT AVG(dep_delay) AS average FROM flights")
    valueBox(sprintf("%.2f min", data$average), "Average Delay", icon = icon("clock"), color = "yellow")
  })
  
  output$cancelledFlights <- renderValueBox({
    data <- dbGetQuery(conn, "SELECT COUNT(*) AS cancelled FROM flights WHERE dep_delay IS NULL")
    valueBox(formatC(data$cancelled, format = "d"), "Cancelled Flights", icon = icon("ban"), color = "red")
  })
  
  
  flights <- dbGetQuery(conn, "SELECT * FROM flights")
  airlines <- dbGetQuery(conn, "SELECT * FROM airlines")
  
  # Vérification du type des colonnes year, month, et day
  flights <- flights %>%
    mutate(year = as.numeric(year),
           month = as.numeric(month),
           day = as.numeric(day))
  
  # Transformer les colonnes en datetime
  flights <- flights %>%
    mutate(sched_dep_time = make_datetime(year, month, day, hour, minute),
           dep_time = make_datetime(year, month, day, dep_time %/% 100, dep_time %% 100),
           sched_arr_time = make_datetime(year, month, day, sched_arr_time %/% 100, sched_arr_time %% 100),
           arr_time = make_datetime(year, month, day, arr_time %/% 100, arr_time %% 100)) %>%
    select(-hour, -minute)
  
  # Liste des jours fériés fédéraux aux États-Unis pour l'année 2021
  holidays <- as.Date(c("2021-01-01", 
                        "2021-01-18", 
                        "2021-02-15", 
                        "2021-05-31", 
                        "2021-07-04", 
                        "2021-09-06", 
                        "2021-10-11", 
                        "2021-11-11", 
                        "2021-11-25", 
                        "2021-12-25"))
  
  flights <- flights %>%
    mutate(date = as.Date(sprintf("%d-%02d-%02d", year, month, day)),
           is_holiday = if_else(date %in% holidays, "Holiday", "Normal Day"),
           is_summer = if_else(month %in% 7:9, "Summer", "Other"))
  
  # Jointure entre flights et airlines pour obtenir le nom des compagnies aériennes
  flights <- flights %>%
    left_join(airlines, by = "carrier")
  
  # Vérification des transformations et de la jointure
  print("=== Vérification des transformations et de la jointure ===")
  print(head(flights))
  
  # Trafic pendant les jours fériés et les périodes de vacances
  holiday_traffic <- flights %>%
    group_by(is_holiday) %>%
    summarise(flights = n(), .groups = 'drop')
  
  print("=== Trafic pendant les jours fériés ===")
  print(holiday_traffic)
  
  output$holidayTraffic <- renderPlotly({
    plot <- ggplot(holiday_traffic, aes(x = is_holiday, y = flights, fill = is_holiday)) +
      geom_bar(stat = "identity") +
      labs(title = "Trafic pendant les Jours Fériés et les Périodes de Vacances", x = "Type de Jour", y = "Nombre de Vols") +
      theme_minimal()
    ggplotly(plot)
  })
  
  # Trafic en été (juillet, août, septembre)
  summer_traffic <- flights %>%
    filter(month %in% 7:9)
  
  print("=== Filtrage des données d'été ===")
  print(head(summer_traffic))
  
  summer_traffic <- summer_traffic %>%
    group_by(month) %>%
    summarise(flights = n(), .groups = 'drop')
  
  print("=== Trafic en été ===")
  print(summer_traffic)
  
  output$summerTraffic <- renderPlotly({
    plot <- ggplot(summer_traffic, aes(x = factor(month), y = flights)) +
      geom_line(group = 1, size = 1.2, color = "steelblue") +
      geom_point(size = 2, color = "steelblue") +
      labs(title = "Trafic en Été (Juillet, Août, Septembre)", x = "Mois", y = "Nombre de Vols") +
      theme_minimal()
    ggplotly(plot)
  })
  
  # Distribution des retards à l'arrivée et au départ
  output$arrivalDelayDist <- renderPlotly({
    plot <- ggplot(flights, aes(x = arr_delay)) +
      geom_histogram(binwidth = 10, fill = "steelblue", color = "black") +
      labs(title = "Distribution des Retards à l'Arrivée", x = "Retard à l'Arrivée (minutes)", y = "Nombre de Vols") +
      theme_minimal()
    ggplotly(plot)
  })
  
  output$departureDelayDist <- renderPlotly({
    plot <- ggplot(flights, aes(x = dep_delay)) +
      geom_histogram(binwidth = 10, fill = "steelblue", color = "black") +
      labs(title = "Distribution des Retards au Départ", x = "Retard au Départ (minutes)", y = "Nombre de Vols") +
      theme_minimal()
    ggplotly(plot)
  })
  
  # Retard moyen par heure de la journée
  hourly_delay <- flights %>%
    mutate(hour = hour(sched_dep_time)) %>%
    group_by(hour) %>%
    summarise(avg_arr_delay = mean(arr_delay, na.rm = TRUE),
              avg_dep_delay = mean(dep_delay, na.rm = TRUE), .groups = 'drop')
  
  output$hourlyDelay <- renderPlotly({
    plot <- ggplot(hourly_delay, aes(x = hour)) +
      geom_line(aes(y = avg_arr_delay, color = "Retard à l'Arrivée"), size = 1.2) +
      geom_line(aes(y = avg_dep_delay, color = "Retard au Départ"), size = 1.2) +
      labs(title = "Retard Moyen par Heure de la Journée", x = "Heure", y = "Retard Moyen (minutes)") +
      scale_color_manual(values = c("Retard à l'Arrivée" = "red", "Retard au Départ" = "blue")) +
      theme_minimal()
    ggplotly(plot)
  })
  
  # Comparaison des retards par compagnie aérienne et par aéroport de départ
  output$delayByCarrier <- renderPlotly({
    plot <- ggplot(flights, aes(x = name, y = dep_delay, fill = name)) +
      geom_boxplot() +
      labs(title = "Retards au Départ par Compagnie Aérienne", x = "Compagnie Aérienne", y = "Retard au Départ (minutes)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(plot)
  })
  
  output$delayByOrigin <- renderPlotly({
    plot <- ggplot(flights, aes(x = origin, y = dep_delay, fill = origin)) +
      geom_boxplot() +
      labs(title = "Retards au Départ par Aéroport d'Origine", x = "Aéroport d'Origine", y = "Retard au Départ (minutes)") +
      theme_minimal()
    ggplotly(plot)
  })
  
  # Taux de retard par compagnie aérienne
  delay_rate_by_carrier <- flights %>%
    group_by(name) %>%
    summarise(delay_rate = mean(dep_delay > 0, na.rm = TRUE), .groups = 'drop')
  
  output$delayRateByCarrier <- renderPlotly({
    plot <- ggplot(delay_rate_by_carrier, aes(x = reorder(name, -delay_rate), y = delay_rate, fill = name)) +
      geom_bar(stat = "identity") +
      labs(title = "Taux de Retard par Compagnie Aérienne", x = "Compagnie Aérienne", y = "Taux de Retard") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_y_continuous(labels = scales::percent)
    ggplotly(plot)
  })
  
  # Nombre de vols annulés par compagnie aérienne
  cancelled_flights_by_carrier <- flights %>%
    filter(is.na(dep_delay)) %>%
    group_by(name) %>%
    summarise(cancelled_flights = n(), .groups = 'drop')
  
  output$cancelledFlightsByCarrier <- renderPlotly({
    plot <- ggplot(cancelled_flights_by_carrier, aes(x = reorder(name, -cancelled_flights), y = cancelled_flights, fill = name)) +
      geom_bar(stat = "identity") +
      labs(title = "Nombre de Vols Annulés par Compagnie Aérienne", x = "Compagnie Aérienne", y = "Nombre de Vols Annulés") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(plot)
  })
  
  
  # Relation entre la distance et le retard moyen à l'arrivée
  distance_delay <- flights %>%
    group_by(distance) %>%
    summarise(avg_arr_delay = mean(arr_delay, na.rm = TRUE), .groups = 'drop')
  
  output$distanceDelay <- renderPlotly({
    plot <- ggplot(distance_delay, aes(x = distance, y = avg_arr_delay)) +
      geom_point(size = 2, color = "steelblue") +
      geom_smooth(method = "lm", color = "red") +
      labs(title = "Relation entre la Distance et le Retard Moyen à l'Arrivée", x = "Distance (miles)", y = "Retard Moyen à l'Arrivée (minutes)") +
      theme_minimal()
    ggplotly(plot)
  })
  
  
  
  txt_stats <- chargement_depuis_txt()
  db_stats <- chargement_depuis_db()
  
  observeEvent(input$B1, {
    output$numAirports <- renderValueBox({
      valueBox(
        value = txt_stats$num_airports,
        subtitle = "Nombre d'aéroports",
        icon = icon("plane"),
        color = "light-blue"
      )
    })
    
    output$numPlanes <- renderValueBox({
      valueBox(
        value = txt_stats$num_planes,
        subtitle = "Nombre d'avions",
        icon = icon("plane"),
        color = "light-blue"
      )
    })
    
    output$numFlights <- renderValueBox({
      valueBox(
        value = txt_stats$num_flights,
        subtitle = "Nombre de vols",
        icon = icon("plane"),
        color = "light-blue"
      )
    })
  })
  
  observeEvent(input$B2, {
    output$numAirports <- renderValueBox({
      valueBox(
        value = db_stats$num_airports1,
        subtitle = "Nombre d'aéroports",
        icon = icon("plane"),
        color = "light-blue"
      )
    })
    
    output$numPlanes <- renderValueBox({
      valueBox(
        value = db_stats$num_planes1,
        subtitle = "Nombre d'avions",
        icon = icon("plane"),
        color = "light-blue"
      )
    })
    
    output$numFlights <- renderValueBox({
      valueBox(
        value = db_stats$num_flights1,
        subtitle = "Nombre de vols",
        icon = icon("plane"),
        color = "light-blue"
      )
    })
  })
  
  
  
  
  
  
  
  monthly_traffic <- flights %>%
    group_by(origin, month = floor_date(sched_dep_time, "month")) %>%
    summarise(flights = n()) %>%
    ungroup()
  
  monthly_avg <- monthly_traffic %>%
    group_by(origin) %>%
    summarise(avg_flights = mean(flights))
  
  # Calcul du taux d'accroissement mensuel
  monthly_traffic <- monthly_traffic %>%
    group_by(origin) %>%
    mutate(monthly_growth_rate = (flights - lag(flights)) / lag(flights))
  
  # Trafic par jour de la semaine
  daily_traffic <- flights %>%
    mutate(day_of_week = wday(sched_dep_time, label = TRUE)) %>%
    group_by(day_of_week) %>%
    summarise(flights = n()) %>%
    ungroup()
  
  # Trafic par heure de la journée
  hourly_traffic <- flights %>%
    mutate(hour = hour(sched_dep_time)) %>%
    group_by(hour) %>%
    summarise(flights = n()) %>%
    ungroup()
  
  # Création du graphique dynamique
 output$dynamicPlot <- renderPlotly({
    plot_data <- NULL
    plot <- NULL
    
    if(input$plotType == "monthly") {
      plot <- ggplot(monthly_traffic, aes(x = month, y = flights, color = origin)) +
        geom_line(size = 1.2) +
        geom_hline(data = monthly_avg, aes(yintercept = avg_flights, color = origin), linetype = "dashed", size = 1) +
        facet_wrap(~ origin, scales = "free_y") +
        labs(title = "Trafic Mensuel par Aéroport", x = "Mois", y = "Nombre de Vols") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold"),
          axis.title = element_text(size = 14),
          axis.text = element_text(size = 12),
          legend.position = "bottom",
          strip.text = element_text(size = 14, face = "bold"),
          panel.grid.major = element_line(color = "grey80")
        )
    } else if(input$plotType == "daily") {
      plot <- ggplot(daily_traffic, aes(x = day_of_week, y = flights, fill = day_of_week)) +
        geom_bar(stat = "identity") +
        labs(title = "Trafic par Jour de la Semaine", x = "Jour de la Semaine", y = "Nombre de Vols") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold"),
          axis.title = element_text(size = 14),
          axis.text = element_text(size = 12),
          legend.position = "none",
          panel.grid.major = element_line(color = "grey80")
        )
    } else if(input$plotType == "hourly") {
      plot <- ggplot(hourly_traffic, aes(x = hour, y = flights)) +
        geom_histogram(stat = "identity", fill = "steelblue") +
        labs(title = "Trafic par Heure de la Journée", x = "Heure", y = "Nombre de Vols") +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 18, face = "bold"),
          axis.title = element_text(size = 14),
          axis.text = element_text(size = 12),
          panel.grid.major = element_line(color = "grey80")
        )
    }
    
    ggplotly(plot)
  })

  
 # Relation entre la distance et le retard moyen à l'arrivée:
 
 airports <- dbGetQuery(conn, "SELECT faa, lat, lon FROM airports")
 
 # Histogram of arrival delays
 output$histArrDelay <- renderPlot({
   flights_filtered <- flights %>%
     filter(is.finite(arr_delay) & is.finite(dep_delay))
   
   ggplot(flights_filtered, aes(x = arr_delay)) +
     geom_histogram(binwidth = 10, fill = "blue", color = "black", alpha = 0.7) +
     labs(title = "Histogram of Arrival Delays", x = "Arrival Delay (minutes)", y = "Frequency") +
     theme_minimal()
 })
 
 # Histogram of departure delays
 output$histDepDelay <- renderPlot({
   flights_filtered <- flights %>%
     filter(is.finite(arr_delay) & is.finite(dep_delay))
   
   ggplot(flights_filtered, aes(x = dep_delay)) +
     geom_histogram(binwidth = 10, fill = "red", color = "black", alpha = 0.7) +
     labs(title = "Histogram of Departure Delays", x = "Departure Delay (minutes)", y = "Frequency") +
     theme_minimal()
 })
 
 # Scatter plot of departure delay vs. arrival delay
 output$scatterDelay <- renderPlot({
   flights_filtered <- flights %>%
     filter(is.finite(arr_delay) & is.finite(dep_delay))
   
   ggplot(flights_filtered, aes(x = dep_delay, y = arr_delay)) +
     geom_point(alpha = 0.3) +
     geom_smooth(method = "lm", color = "blue") +
     labs(title = "Scatter Plot of Departure Delay vs. Arrival Delay", x = "Departure Delay (minutes)", y = "Arrival Delay (minutes)") +
     theme_minimal()
 })
 
 # Average Arrival Delay by Departure Hour
 output$avgArrDelayByHour <- renderPlot({
   average_delay_by_hour <- flights %>%
     mutate(dep_hour = hour(dep_time)) %>%
     group_by(dep_hour) %>%
     summarise(
       avg_arr_delay = mean(arr_delay, na.rm = TRUE),
       avg_dep_delay = mean(dep_delay, na.rm = TRUE),
       count = n()
     )
   
   ggplot(average_delay_by_hour, aes(x = dep_hour, y = avg_arr_delay)) +
     geom_line(color = "blue") +
     geom_point(color = "blue") +
     labs(title = "Average Arrival Delay by Departure Hour", x = "Departure Hour", y = "Average Arrival Delay (minutes)") +
     theme_minimal()
 })
 
 # Average Departure Delay by Departure Hour
 output$avgDepDelayByHour <- renderPlot({
   average_delay_by_hour <- flights %>%
     mutate(dep_hour = hour(dep_time)) %>%
     group_by(dep_hour) %>%
     summarise(
       avg_arr_delay = mean(arr_delay, na.rm = TRUE),
       avg_dep_delay = mean(dep_delay, na.rm = TRUE),
       count = n()
     )
   
   ggplot(average_delay_by_hour, aes(x = dep_hour, y = avg_dep_delay)) +
     geom_line(color = "red") +
     geom_point(color = "red") +
     labs(title = "Average Departure Delay by Departure Hour", x = "Departure Hour", y = "Average Departure Delay (minutes)") +
     theme_minimal()
 })
 
 # Relationship between Distance and Average Delay
 output$distanceDelayPlot <- renderPlot({
   avg_delay_by_distance <- flights %>%
     group_by(distance) %>%
     summarise(avg_arr_delay = mean(arr_delay, na.rm = TRUE))
   
   ggplot(avg_delay_by_distance, aes(x = distance, y = avg_arr_delay)) +
     geom_point(color = "blue", alpha = 0.6) +
     geom_smooth(method = "lm", color = "red") +
     labs(title = "Relationship between Distance and Average Arrival Delay", x = "Distance", y = "Average Arrival Delay (minutes)") +
     theme_minimal()
 }) 
 # Machine Learning Model for Delay Prediction
 model <- reactive({
   flights <- flights %>%
     filter(!is.na(dep_delay) & !is.na(arr_delay))
   lm(arr_delay ~ dep_delay, data = flights)
 })
 
 output$mlPlot <- renderPlotly({
   flights <- flights %>%
     filter(!is.na(dep_delay) & !is.na(arr_delay))
   flights$predicted_arr_delay <- predict(model(), flights)
   
   p <- ggplot(flights, aes(x = dep_delay, y = arr_delay)) +
     geom_point(alpha = 0.3, color = "blue") +
     geom_line(aes(y = predicted_arr_delay), color = "red") +
     labs(title = "Predicted Arrival Delay vs. Actual Arrival Delay", x = "Departure Delay (minutes)", y = "Arrival Delay (minutes)") +
     theme_minimal()
   
   ggplotly(p)
 })
 
 output$predictionResult <- renderText({
   input$predict
   isolate({
     newdata <- data.frame(dep_delay = input$dep_delay)
     predicted_delay <- predict(model(), newdata)
     paste("Predicted Arrival Delay:", round(predicted_delay, 2), "minutes")
   })
 })
 
  output$dataTable <- renderDT({
    datatable(head(db_stats$flights, 10))
  })
}
