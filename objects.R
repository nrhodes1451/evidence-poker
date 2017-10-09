# Objects ----
card <- R6Class("card",
  public = list(
    suit=NULL,
    value=NULL,
    visible=NULL,

    initialize=function(
      value=NA,
      suit=NA,
      visible=FALSE){
        # Value check
        value <- as.integer(value)
        if(is.na(value) || length(value)!=1 ||
           value<1 || value>13) return(NULL)
        self$value <- value

        # Suit check
      suit <- tolower(as.character(suit))
        if(is.na(suit) || length(suit)!=1 ||
           nchar(suit)!=1 || !(suit %in% c("c","d","h","s"))) return(NULL)
        self$suit <- suit

        if(!is.logical(visible)) return(NULL)
        self$visible <- visible
    }
  )
)

hand <- R6Class("hand",
  public = list(
    cards = NULL,
    initialize = function(){
        self$cards <- list()
    },

    deal_card = function(card){
      self$cards <- c(self$cards, card)
    },

    fold = function(){
      self$cards <- list()
    }
  )
)

player <- R6Class("player",
  public = list(
    active = NULL,
    chips = NULL,
    hand = NULL,
    id = NULL,
    name = NULL,
    in_game = NULL,
    is_dealer = NULL,
    is_big_blind = NULL,
    is_small_blind = NULL,

    initialize = function(
      id = NA,
      name=NA,
      chips=0,
      active=FALSE,
      in_game = FALSE,
      is_dealer = FALSE,
      is_big_blind = FALSE,
      is_small_blind = FALSE){
        self$active <- active
        self$id <- id
        self$name <- name
        self$chips <- chips
        self$hand <- hand$new()
    },

    fold = function(){
      self$hand$fold()
      self$active <- FALSE
    },

    bid = function(c){
      if(is.na(c) || as.integer(c)!=c ||
         self$chips < c) return(NULL)
      self$chips <- self$chips - c
      return(as.integer(c))
    },

    leave = function(){
      self$handfold()
      self$active <- FALSE
      self$in_game <- FALSE
      self$is_dealer <- FALSE
      self$is_big_blind <- FALSE
      self$is_small_blind <- FALSE
    }
  )
)

deck <- R6Class("deck",
  public = list(
    cards = NULL,

    initialize = function(){
      self$gather()
      self$shuffle()
    },

    gather = function(){
      suits <- c("c","d","h","s")
      self$cards <- lapply(0:51, function(x){
        card$new(x %% 13 + 1, suits[as.integer(x/13)+1])
      })
    },

    shuffle = function(){
      self$cards <- self$cards[order(rnorm(52,0,1))]
    },

    deal = function(){
      card <- self$cards[1]
      self$cards <- self$cards[-1]
      return(card)
    }
  )
)

game <- R6Class("game",
  public = list(
    id = NULL,
    game = NULL,
    deck = NULL,
    dealer = NULL,
    players = NULL,
    state = NULL,
    table_cards = NULL,
    error_log = NULL,

    initialize = function(id, name, dealer){
      self$id = id
      self$name = name
      self$dealer = dealer
      dealer$in_game = TRUE
      dealer$is_dealer = TRUE

      self$players = list()
      self$deck = deck$new()
      self$table_cards = hand$new()
      self$state = private$states[1]

      self$error_log = list()
    },

    deal = function(){
      if(length(self$players)<2){
        self$error_log$warning = "Waiting for players to join"
        return(FALSE)
      }
      self$state <- private$states[
        (which(private$states == self$state)) %% 5 + 1]
      if(self$state==private$states[2]){
        for(p in self$players){
          p$hand$deal_card(self$deck$deal())
          p$hand$deal_card(self$deck$deal())
        }
      }
      else if(self$state==private$states[3]){
        self$table_cards$deal_card(self$deck$deal())
        self$table_cards$deal_card(self$deck$deal())
        self$table_cards$deal_card(self$deck$deal())
      }
      else if(self$state==private$states[4]){
        self$table_cards$deal_card(self$deck$deal())
      }
      else if(self$state==private$states[5]){
        self$table_cards$deal_card(self$deck$deal())
      }
      else{
        self$cleanup()
      }
      return(self$state)
    },

    cleanup = function(){
      self$table_cards <- hand$new()
      for(p in self$players){
        p$hand <- hand$new()
      }
    },

    add_player = function(player){
      if(length(players)>9){
        self$error_log$warning = "Table full"
        return(FALSE)
      }
      if(self$state==private$states[1]){
        player$hand <- hand$new()
        self$players = c(self$players, player)
        return(TRUE)
      }
      else{
        self$error_log$warning = "New players may only join between hands"
        return(FALSE)
      }
    },

    remove_player = function(player){
      if(self$state==private$states[1]){
        self$players = self$players[-player]
        return(TRUE)
      }
      else{
        self$error_log$warning =
          paste(player$name, "will leave at the end of this hand")
        return(FALSE)
      }
    }
  ),

  private = list(
    states = c(
      "New Hand",
      "Pre Flop",
      "Flop",
      "Turn",
      "River"
    )
  )
)

app <- R6Class("poker-app",
  public = list(
    games = NULL,
    users = NULL,
    timestamp = NULL,
    error_log = list(),

    initialize = function(){
      if(file.exists("app.RDS")){

      }
      else{
        self$games = list()
        self$users = list()
        self$timestamp = now()
      }
    },

    save_app = function(){
      self$timestamp = now()
      saveRDS("app.RDS")
    },
    load_app = function(){
      self$timestamp = now()
      readRDS("app.RDS")
    },

    create_game = function(id, user){
      if(id %in% names(self$games)){
        self$error_log$error <- "Game already exists"
      }
      else if(user$in_game){
        self$error_log$error <- "Can't create game. Please leave the current game first."
      }
      else{
        new_game <- game$new(id, id, user)
        self$games[[id]] <- new_game
      }
    },
    end_game = function(id){
      if(!(id %in% names(self$games))){
        self$error_log$error <- "Game not found"
      }
      else{
        old_game <- self$games[[id]]
        for(player in old_game){
          player$leave()
        }
        self$games <- self$games[[-id]]
      }
    }

  )
)

poker_app <- app$new()