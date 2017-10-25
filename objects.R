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
    },

    get_img = function(){
      if(self$visible){
        return(paste0("img/cards/",self$value,self$suit,".svg"))
      }
      else return("img/cards/back.png")
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
    hand = NULL,
    hosting = NULL,
    username = NULL,
    password = NULL,
    game = NULL,
    is_dealer = NULL,
    is_big_blind = NULL,
    is_small_blind = NULL,
    timestamp = NULL,

    initialize = function(
      username = NA,
      password = NA,
      active = FALSE,
      hosting = FALSE,
      is_dealer = FALSE,
      is_big_blind = FALSE,
      is_small_blind = FALSE){
        self$username <- username
        self$password <- password
        self$active <- active
        self$hosting <- hosting
        self$is_dealer <- is_dealer
        self$is_big_blind <- is_big_blind
        self$is_small_blind <- is_small_blind
        self$hand <- hand$new()
        self$timestamp <- now()
    },

    fold = function(){
      self$timestamp <- now()
      self$hand$fold()
      self$active <- FALSE
    },

    bid = function(c){
      self$timestamp <- now()
      if(is.na(c) || as.integer(c)!=c ||
         self$chips < c) return(NULL)
      self$chips <- self$chips - c
      return(as.integer(c))
    },

    in_game = function(){
      return(!is.null(self$game))
    },

    join_game = function(id){
      self$timestamp <- now()
      self$active <- FALSE
      self$game <- id
      player$hand <- hand$new()
      self$hosting <- FALSE
      self$is_dealer <- FALSE
      self$is_big_blind <- FALSE
      self$is_small_blind <- FALSE
    },

    leave = function(){
      self$timestamp <- now()
      self$hand$fold()
      self$active <- FALSE
      self$game <- NULL
      self$is_dealer <- FALSE
      self$is_big_blind <- FALSE
      self$is_small_blind <- FALSE
    },

    status = function(){
      if(self$hosting){
        return("Hosting")
      }
      else if(self$in_game()){
        return("In Game")
      }
      else return("Inactive")
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
      card <- self$cards[[1]]
      card$visible <- TRUE
      self$cards <- self$cards[-1]
      return(card)
    }
  )
)

game <- R6Class("game",
  public = list(
    id = NULL,
    chips = NULL,
    deck = NULL,
    error_log = list(),
    host = NULL,
    players = NULL,
    state = NULL,
    table_cards = NULL,
    timestamp = NULL,

    initialize = function(gameid, hostid){
      self$id = gameid
      self$host = hostid

      self$deck = deck$new()
      self$table_cards = hand$new()
      self$state = private$states[1]
      self$timestamp <- now()
    },

    deal = function(){
      if(length(self$players)<2){
        self$error_log$error = "Waiting for players to join"
        return(NULL)
      }
      return_val <- list()
      self$state <- private$states[
        (which(private$states == self$state)) %% 5 + 1]
      return_val$state <- self$state
      if(self$state==private$states[2]){
        return_val$hands <- list()
        for(p in self$players){
          return_val$hands[[p]] <- c(
            self$deck$deal(),
            self$deck$deal())
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
      self$timestamp <- now()
      return(return_val)
    },

    cleanup = function(){
      self$timestamp <- now()
      self$deck <- deck$new()
      self$table_cards <- hand$new()
      for(p in self$players){
        p$hand <- hand$new()
      }
    },

    add_player = function(name){
      self$timestamp <- now()
      if(length(self$players)>9){
        self$error_log$warning = "Table full"
        return(FALSE)
      }
      if(self$state==private$states[1]){
        self$players = c(self$players, name)
        return(TRUE)
      }
      else{
        self$error_log$warning = "New players may only join between hands"
        return(FALSE)
      }
    },

    remove_player = function(player){
      self$timestamp <- now()
      if(self$state==private$states[1]){
        player$leave()
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
    session_user = NULL,
    timestamp = NULL,
    users = NULL,

    initialize = function(){
      private$load_app()
    },

    log_in = function(username, password){
      # Error handling
      if((class(username)=="character" && class(password)=="character") &&
        (nchar(username)>0 && nchar(password)>0)){
        # Username/Password verification
        if(username %in% names(self$users)){
          if(self$users[[username]]$password != password){
            private$clear_log()
            private$error_log$warning <- "Username/Password mismatch"
            return(FALSE)
          }
          # Log in as user
          else{
            private$load_app()
            self$session_user <- self$users[[username]]
            self$session_user$timestamp <- now()

            # Check that user's game is still active and update accordingly
            if(!is.null(self$session_user$game)){
              if(!(self$session_user$game %in% names(self$games))){
                self$session_user$leave()
              }
            }

            private$clear_log()
            private$error_log$message <- paste("Successfully logged in as",
                                            username)
            return(TRUE)
          }
        }
        # Create new user
        else{
          user <- player$new(username, password)
          if(private$compare_users(self$session_user, user)){
            private$clear_log()
            private$error_log$warning <- paste("Already loggied in as user:",
                                                username)
            return(FALSE)
          }
          private$load_app()
          private$add_user(user)
          self$session_user <- user
          private$save_app()
          private$clear_log()
          private$error_log$message <- paste("New user created:", username)
          return(TRUE)
        }
      }
      else{
        private$error_log$error <-
        return(FALSE)
      }
    },

    log_out = function(){
      self$session_user <- NULL
    },

    create_game = function(id){
      if(is.null(self$session_user)) return(FALSE)
      # Refresh the games list
      private$load_app()

      if(id %in% names(self$games)){
        private$clear_log()
        private$error_log$error <- "Game already exists."
        return(FALSE)
      }
      else if(self$session_user$in_game()){
        private$clear_log()
        private$error_log$error <- "Can't create game. Please leave the current game first."
        return(FALSE)
      }
      else{
        # Update host user
        self$session_user$hosting <- TRUE
        self$session_user$active <- TRUE
        self$session_user$game <- id

        # Create new game
        new_game <- game$new(id, self$session_user$username)

        self$games[[id]] <- new_game
        # Save changes
        private$save_app()
        return(TRUE)
      }
    },

    join_game = function(id){
      if(!(id %in% names(self$games))){
        private$clear_log()
        private$error_log$error <- "Game not found"
        return(FALSE)
      }
      else if(self$session_user$in_game()){
        private$clear_log()
        private$error_log$error <- "Please leave the current game first"
        return(FALSE)
      }
      else{
        private$load_app()
        if(self$games[[id]]$add_player(self$session_user$username)){
          self$session_user$join_game(id)
          private$save_app()
          return(TRUE)
        }
        else{
          private$error_log <- self$games[[id]]$error_log
          return(TRUE)
        }
      }
    },

    deal = function(){
      if(!self$session_user$hosting){
        private$error_log <- list("error"="No game found")
        return(FALSE)
      }
      else{
        d <- self$games[[self$session_user$game]]$deal()
        if(is.null(d)){
          private$error_log <- self$games[[self$session_user$game]]$error_log
          return(FALSE)
        }
        else{
          # Deal Hands
          if(!is.null(d$hands)){
            for(i in seq_along(d$hands)){
              p <- names(d$hands)[i]
              self$users[[p]]$hand$initialize()
              for(c in d$hands[[i]]){
                self$users[[p]]$hand$deal_card(c)
              }
            }
          }
          else if(d$state=="New Hand"){
            for(p in self$games[[self$session_user$game]]$players){
              self$users[[p]]$hand$initialize()
            }
          }
          private$save_app()
          return(TRUE)
        }
      }
    },

    end_game = function(id){
      if(is.null(self$session_user)) return(FALSE)
      # Refresh the games list
      private$load_app()

      if(!(id %in% names(self$games))){
        private$error_log$error <- "Game not found"
      }
      else if(self$games[[id]]$host$username !=
              self$session_user$username){
        private$error_log$error <- "Only the host can end the game."
      }
      else{
        old_game <- self$games[[id]]
        for(player in old_game){
          player$leave()
        }
        self$games <- self$games[[-id]]

        # Save changes
        private$save_app()
      }
    },

    print_log = function(){
      if(length(private$error_log)>0){
        return(private$error_log[1])
        private$clear_log()
      }
      else{
        return(NULL)
      }
    },

    reset = function(){
      # for(g in self$games){
      #   g$
      # }
      self$games <- list()
      self$users <- list()
      self$games %>% saveRDS("games.RDS")
      self$users %>% saveRDS("users.RDS")
    }
  ),

  private <- list(
    self_destruct = 1, # Days to record games & users

    error_log = list("error"="Not logged in"),

    clear_log = function(){
      private$error_log <- list()
    },

    save_app = function(){
      self$timestamp = now()

      self$users[[self$session_user$username]] <- self$session_user
      self$users[[self$session_user$username]]$timestamp <- self$timestamp

      self$users %>% saveRDS("users.RDS")
      self$games %>% saveRDS("games.RDS")
    },

    load_app = function(){
      if(file.exists("users.RDS")){
        self$users <- readRDS("users.RDS")
        self$games <- readRDS("games.RDS")
        self$timestamp <- now()

        # Remove inactive users and recreate list if necessary
        self$users <- self$users %>% lapply(function(u){
          if(difftime(self$timestamp, u$timestamp, units="hours") >
             private$self_destruct){
                return(NULL)
            }
            else{
                return(u)
            }
        }) %>% unlist
        if(is.null(self$users)){
          self$users <- list()
        }

        # Remove inactive games and recreate list if necessary
        self$games <- self$games %>% lapply(function(g){
          if(difftime(self$timestamp, g$timestamp, units="hours") >
             private$self_destruct){
            }
            else{
                return(g)
            }
        }) %>% unlist
        if(is.null(self$games)){
          self$games <- list()
        }
      }
      else return(NULL)
    },

    add_user = function(u){
      if(class(u)[1] != "player") return(NULL)
      users <- self$users
      users[[u$username]] <- u
      self$users <- users
    },

    compare_users = function(u, v){
      if(is.null(u) || is.null(v)) return(FALSE)
      return(u$username == v$username)
    },

    remove_user = function(u){
      if(is.null(self$session_user)) return(FALSE)
      if(class(u)[1] != "player") return(NULL)
      users <- self$users[names(self$users)!=u$username]
      self$users <- users
    }
  )
)

poker_app <- app$new()