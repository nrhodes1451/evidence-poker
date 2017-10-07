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
    active = NULL,
    cards = NULL,
    initialize = function(
      active = FALSE){
        self$active <- active
    },

    deal_card = function(card){
      self$cards <- c(self$cards, card)
    },

    fold = function(){
      self$active <- FALSE
      self$cards <- NULL
    }
  )
)

player <- R6Class("player",
  public = list(
    active = NULL,
    chips = NULL,
    hand = NULL,
    name = NULL,
    initialize = function(
      name=NA,
      chips=0,
      active=FALSE){
        self$active <- active
        self$name <- name
        self$chips <- chips
    },

    fold = function(){
      self$hand <- NULL
      self$active <- FALSE
    },

    bid = function(c){
      if(is.na(c) || as.integer(c)!=c ||
         self$chips < c) return(NULL)
      self$chips <- self$chips - c
      return(as.integer(c))
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