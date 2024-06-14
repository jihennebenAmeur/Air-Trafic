library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
ui <- dashboardPage(
  dashboardHeader(title = "Trafic Aérien"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Base de Données", tabName = "database", icon = icon("database")),
      menuItem("Analyses", tabName = "analyses", icon = icon("chart-bar"),
               menuSubItem("Trafic aéroportuaire", tabName = "monthly_traffic", icon = icon("calendar-alt")),
               menuSubItem("Retards des Vols", tabName = "flight_delays", icon = icon("clock")),
               menuSubItem("Périodes de Pic", tabName = "peak_periods", icon = icon("chart-line")),
               menuSubItem("Performance des Compagnies", tabName = "airline_performance", icon = icon("plane")),
               menuSubItem("Distance vs Retard", tabName = "distance_delay", icon = icon("arrows-alt-h"))
      ),
      menuItem("Prédiction", tabName = "prediction", icon = icon("chart-line")),
      menuItem("Mission", tabName = "mission", icon = icon("flag"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css"),
      tags$style(HTML("
        body, .content-wrapper, .right-side {
          background-color: #ffffff;
        }
        .main-header .logo {
          background-color: #3C8DBC;
        }
        .navbar {
          background-color: #3C8DBC;
        }
        .card-container { 
          display: flex;
          flex-wrap: wrap;
          justify-content: space-around;
          align-items: flex-start;
        }
        .card {
          display: flex;
          flex-wrap: wrap;
          justify-content: space-around;
          align-items: flex-start;
        }
        .value-box {
          background-color: #3C8DBC;
          color: white;
        }
        .value-box2{
          background-color: #ffffff;
          color: #3C8DBC;
          position: relative;
        }
        .value-trait {
          background-color: #ffffff;
          color: #3C8DBC;
          position: relative;
          padding: 20px 40px; /* Ajuster la taille des boutons */
          font-size: 16px;   /* Ajuster la taille du texte */
          font-weight: bold;  /* Texte en gras */
        }
        .content-header {
          color: #3C8DBC;
          text-align: center;
        }
        .content-header2 {
          color: #FFFFFF;
        }
        .profile-card {
          text-align: center;
          padding: 20px;
          margin: 10px;
          flex: 1 0 21%;
          max-width: 1000px;
          border-radius: 5px;
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
          background-color: #ffffff;
          position: relative;
          overflow: hidden;
          box-sizing: border-box;
        }
        .profile-background {
          background-size: cover;
          height: 200px;
          width: 100%;
        }
        .profile-image {
          width: 140px;
          height: 140px;
          border-radius: 50%;
          border: 4px solid white;
          position: absolute;
          top: 100px;
          left: 50%;
          transform: translateX(-50%);
        }
        .profile-info {
          padding-top: 60px;
        }
        .blue-background {
          background-color: #3C8DBC;
          color: white;
          padding: 20px;
          border-radius: 5px;
          margin-bottom: 20px;
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
        .traitement {
          text-align: center; 
          margin-top: 20px;    /* Ajustement de la marge top */
        }
        .donnee {
          margin-top: 20px;    /* Ajustement de la marge top */
        }
      "))
    ),
    tabItems(
      tabItem(tabName = "home",
              h1("Bienvenue sur cette application!", class = "content-header"),
              div(class = "blue-background",
                  h4("Il s'agit d'une application Shiny focalisée sur un problème de gestion du trafic aérien en augmentation constante chez Aéroports de Paris (ADP). Face à cette croissance, nous rencontrons divers défis opérationnels, notamment des retards de vols, des annulations, ainsi que des cas où les passagers doivent passer la nuit à l'aéroport. Cette application vise à analyser ces problématiques en profondeur, en utilisant les données accumulées par ADP pour découvrir les causes sous-jacentes et identifier des solutions efficaces.
En naviguant à travers cette plateforme, vous aurez accès à des visualisations de données interactives, des analyses prédictives et des recommandations stratégiques qui nous aideront à améliorer nos opérations et à offrir une meilleure expérience à nos passagers.")
              ),
              actionButton("masterIA", "Master IPSSI", class = "value-box"),
              div(
                h1("Notre Equipe", class = "content-header"),
                div(class = "card-container", 
                    div(class = "profile-card",
                        div(class = "profile-background", style = "background-image: url('profil.jpg');"),  # Assume background image for each
                        img(src = "nabila.png", class = "profile-image"),
                        div(class = "profile-info",
                            h3("Nabila EL ABDALI")
                        )
                    ),
                    div(class = "profile-card",
                        div(class = "profile-background", style = "background-image: url('profil.jpg');"),
                        img(src = "claudia.png", class = "profile-image"),
                        div(class = "profile-info",
                            h3("Claudia TIMOCI")
                        )
                    )
                ),
                div(class = "card-container",    
                    div(class = "profile-card",
                        div(class = "profile-background", style = "background-image: url('profil.jpg');"),
                        img(src = "muthuvel.png", class = "profile-image"),
                        div(class = "profile-info",
                            h3("Muthuvel SAVOUNDIRAPANDIANE")
                        )
                    ),
                    div(class = "profile-card",
                        div(class = "profile-background", style = "background-image: url('profil.jpg');"),
                        img(src = "jihene.png", class = "profile-image"),
                        div(class = "profile-info",
                            h3("Jihene BEN AMEUR")
                        )
                    )
                )
              )
      ),
      tabItem(tabName = "database",
              h1("Traitement de base de données", class = "content-header"),
              div(class = "blue-background",
                  h2("Notre démarche", class = "content-header2"),
                  h4("Vérification des contraintes de clés primaires et étrangères:"),
                  p("- Utilisation de requêtes SQL pour vérifier l'intégrité des clés primaires (PK) et étrangères (FK)."),
                  p("- Vérifier que les clés naturelles respectent les formats attendus (par exemple, regex sur les colonnes origin, dest, carrier, tailnum)."),
                  p("- Identifier les données manquantes ou incohérentes par rapport aux FK définies."),
                  h4("Résolution des anomalies identifiées:"),
                  p("- Proposer des actions correctives telles que l'ajout des données manquantes dans les tables référencées (airports, planes, weather)."),
                  p("- Définir une stratégie pour les clés étrangères manquantes ou incorrectes, par exemple en revoir les données de vols associées à des aéroports non référencés.")
              ),
              div(class = "traitement",
                  fluidRow(
                    column(width = 3,
                           tags$img(src = "bdd.jpg", height = "100px")
                    ),
                    column(width=3,
                           actionButton("B1", "Avant le traitement", class = "value-trait"),
                           
                    ),
                    column(width=3,
                           actionButton("B2", "Après le traitement", class = "value-trait")
                           
                    ),
                  ),
              ),
              div(class="donnee",
                  fluidRow(
                    column(width = 4,
                           uiOutput("numAirports")
                    ),
                    column(width = 4,
                           uiOutput("numPlanes")
                    ),
                    column(width = 4,
                           uiOutput("numFlights")
                    )
                  )
              ),
              div(class="table-container",
                  DTOutput("dataTable")
              ),
      ),
    
      
  
      tabItem(tabName = "monthly_traffic",
             
              fluidRow(
                valueBoxOutput("totalFlights"),
                valueBoxOutput("averageDelay"),
                valueBoxOutput("cancelledFlights")
              ), 
              fluidRow(
                selectInput("plotType", "Type de Visualisation:",
                            choices = list("Trafic Mensuel" = "monthly",
                                           "Trafic par Jour de la Semaine" = "daily",
                                           "Trafic par Heure de la Journée" = "hourly"),
                            selected = "monthly"),  # valeur par défaut définie ici
                plotlyOutput("dynamicPlot")
              )
              
              ),
      tabItem(tabName = "flight_delays",
             
              fluidRow(
                valueBoxOutput("totalFlights"),
                valueBoxOutput("averageDelay"),
                valueBoxOutput("cancelledFlights")
              ),
              fluidRow(
                plotlyOutput("arrivalDelayDist", height = "400px"),
                plotlyOutput("departureDelayDist", height = "400px")
              ),
              fluidRow(
                plotlyOutput("hourlyDelay", height = "400px")
              ),
              fluidRow(
                plotlyOutput("delayByCarrier", height = "400px"),
                plotlyOutput("delayByOrigin", height = "400px")
              ),
              ),
      tabItem(tabName = "peak_periods",
              
              fluidRow(
                valueBoxOutput("totalFlights"),
                valueBoxOutput("averageDelay"),
                valueBoxOutput("cancelledFlights")
              ),
              
              fluidRow(
                plotlyOutput("holidayTraffic", height = "400px"),
                plotlyOutput("summerTraffic", height = "400px"),
              ),
              
              
      ),
      tabItem(tabName = "airline_performance",
              h1("Performance des Compagnies", class = "content-header"),
              fluidRow(
                valueBoxOutput("totalFlights"),
                valueBoxOutput("averageDelay"),
                valueBoxOutput("cancelledFlights")
              ),
              fluidRow(
                plotlyOutput("delayRateByCarrier", height = "400px"),
                plotlyOutput("cancelledFlightsByCarrier", height = "400px"),
              ),
              
      ),
      tabItem(tabName = "distance_delay",
              h1("Distance vs Retard", class = "content-header"),
              fluidRow(
                box(title = "Histogramme des retards d'arrivée", status = "primary", solidHeader = TRUE, width = 6, plotOutput("histArrDelay")),
                box(title = "Histogramme des retards de départ", status = "primary", solidHeader = TRUE, width = 6, plotOutput("histDepDelay"))
              ),
              fluidRow(
                box(title = "Diagramme de dispersion des retards au départ et à l'arrivée", status = "primary", solidHeader = TRUE, width = 12, plotOutput("scatterDelay"))
              ),
              fluidRow(
                box(title = "Retard moyen à l'arrivée par heure de départ", status = "primary", solidHeader = TRUE, width = 6, plotOutput("avgArrDelayByHour")),
                box(title = "Retard moyen au départ par heure de départ", status = "primary", solidHeader = TRUE, width = 6, plotOutput("avgDepDelayByHour"))
              ),
              fluidRow(
                box(title = "Relation entre la distance et le retard moyen", status = "primary", solidHeader = TRUE, width = 12, plotOutput("distanceDelayPlot"))
              ),
              fluidRow(
                box(title = "Commentaire", status = "primary", solidHeader = TRUE, width = 12,
                    p("Le nuage de points illustre la relation entre le retard au départ et le retard à l'arrivée pour les vols. Chaque point représente un vol unique, l'axe des x indiquant le retard au départ et l'axe des y indiquant le retard à l'arrivée. La ligne bleue représente un modèle de régression linéaire ajusté aux données, indiquant une forte corrélation positive entre le retard au départ et le retard à l'arrivée. Cela suggère que les retards au départ sont susceptibles d'entraîner des retards à l'arrivée."),
                    p("Relation entre la distance et le retard moyen à l'arrivée. Ce nuage de points illustre la relation entre la distance des vols et le retard moyen à l'arrivée. Chaque point représente le retard moyen à l'arrivée pour une distance donnée. La ligne rouge est un ajustement de régression linéaire, montrant une légère tendance négative. Cela implique que les vols plus longs ont tendance à avoir des retards moyens à l'arrivée légèrement inférieurs, peut-être parce que les vols plus longs ont plus de temps tampon pour compenser les retards initiaux. La zone ombrée représente l'intervalle de confiance de la ligne de régression.")
                )
              )
      ),
      tabItem(tabName = "prediction",
              h2("Prédiction"),
              fluidRow(
                box(title = "Predict Next Delays", status = "primary", solidHeader = TRUE, width = 12, 
                    numericInput("dep_delay", "Departure Delay (minutes):", value = 10),
                    actionButton("predict", "Predict Arrival Delay"),
                    verbatimTextOutput("predictionResult")
                )
              ),
              fluidRow(
                box(title = "Machine Learning Model for Delay Prediction", status = "primary", solidHeader = TRUE, width = 12, plotlyOutput("mlPlot"))
              )
      ),
      tabItem(tabName = "mission", 
              h1("Mission", class = "content-header"), 
              p("Détails et objectifs de la mission de ce projet")
      )
    )
  )
)
