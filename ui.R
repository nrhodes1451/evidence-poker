# Header
header <- dashboardHeader(title = "Evidence Poker")

# Sidebar ----

sidebar <- dashboardSidebar(
  hr(),

  sidebarMenu(id="tabs",
    menuItem("Settings", tabName="settings", icon=icon("gears")),
    menuItem("Table", tabName="table", icon=icon("table"))
  )
)

# Body ----

body <- dashboardBody(
  useShinyjs(),
  # Extend shinyjs ----
  # Awaiting internet access to download V8 package
  # extendShinyjs(text="shinyjs.goToTable = function(){
  #   $(\"a[href='#shiny-tab-table']\").click();}"),

    # HTML Tags ----
  tags$head(
    tags$script(src = "scripts.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    # tags$link(rel="shortcut icon",
    # href="https://www.annalect.com/wp-content/uploads/2016/06/27210921/favicon.ico")
  ),

  # Loading bars ----
  conditionalPanel(condition="check_shiny_busy()", id="loading",
    tags$div(class="plotlybars-wrapper",
      tags$div(class="plotlybars",
        tags$div(class="plotlybars-bar b1"),
        tags$div(class="plotlybars-bar b2"),
        tags$div(class="plotlybars-bar b3"),
        tags$div(class="plotlybars-bar b4"),
        tags$div(class="plotlybars-bar b5"),
        tags$div(class="plotlybars-bar b6"),
        tags$div(class="plotlybars-bar b7")
      ),
    tags$div(class="plotlybars-text")
    )
  ),
  # Login Screen ----
  tags$div(id="login", class="overlay",
    box(
      title="Login",
      status = global_options$status_color,
      textInput("txt_login_id", NULL, placeholder="Username"),
      passwordInput("txt_login_pw", NULL, placeholder="Password"),
      actionButton("btn_login", "Log in"),
      width = NULL,
      solidHeader = TRUE
    )
  ),

  # Error messages ----
  htmlOutput("error_message"),

  tabItems(
  # Settings ----
    tabItem(tabName = "settings",
      fluidRow(id="settings-row",
        column(width=6,
          box(
            title="Join A Game",
            status = global_options$status_color,
            selectInput("sct-games", "Available games:", NULL),
            actionButton("btn_join_game", "Join", class="disabled", NULL),
            width = NULL,
            height=380,
            solidHeader = TRUE
          )
        ),
        column(width=6,
          box(
            title="Create A New Game",
            status = global_options$status_color,
            textInput("txt_game_name", NULL, placeholder="Game Name"),
            actionButton("btn_create_game", "Create Game"),
            width = NULL,
            height=380,
            solidHeader = TRUE
          )
        )
      )
    ),
  # Table ----
    tabItem(tabName = "table",
      fluidRow(id="table-row",
        column(width=12,
          box(id="table-box",
            title="Table",
            status = global_options$status_color,
            width = NULL,
            solidHeader = TRUE,
            div(class="players players-top",
              div(id='player1', class='player player-inactive',
                img(src='img/avatar.png'), "p1"),
              div(id='player3', class='player player-inactive',
                img(src='img/avatar.png'), "p3"),
              div(id='player5', class='player player-inactive',
                img(src='img/avatar.png'), "p5"),
              div(id='player7', class='player player-inactive',
                img(src='img/avatar.png'), "p7"),
              div(id='player9', class='player player-inactive',
                img(src='img/avatar.png'), "p9")
            ),
            actionButton("btn_deal", ""),
            div(class="cards",
              img(id='deck', class='card card-back',
                src='img/cards/back.png'),
              img(id='flop1', class='card card-back card-hidden',
                src='img/cards/back.png'),
              img(id='flop2', class='card card-back card-hidden',
                src='img/cards/back.png'),
              img(id='flop3', class='card card-back card-hidden',
                src='img/cards/back.png'),
              img(id='turn', class='card card-back card-hidden',
                src='img/cards/back.png'),
              img(id='river', class='card card-back card-hidden',
                src='img/cards/back.png')
            ),
            div(class="players players-bottom",
              div(id='player1', class='player player-inactive',
                "p2", img(src='img/avatar.png')),
              div(id='player1', class='player player-inactive',
                "p4", img(src='img/avatar.png')),
              div(id='player1', class='player player-inactive',
                "p6", img(src='img/avatar.png')),
              div(id='player1', class='player player-inactive',
                "p8", img(src='img/avatar.png')),
              div(id='player1', class='player player-inactive',
                "p10", img(src='img/avatar.png'))
            )
          )
        )
      )
    )
  )
)

# Dashboard Page -------

dashboardPage(
  header = header,
  sidebar = sidebar,
  body = body,
  title = "Evidence Poker",
  skin = global_options$skin
)