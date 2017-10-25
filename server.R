shinyServer(function(input, output, clientData, session){

  # Buttons disabled by default ----
  addClass("btn_join_game", "disabled")
  addClass("btn_create_game", "disabled")
  addClass("btn_deal", "disabled")

  # Error Messages ----
  display_error <- function(log){
    if(is.null(log)){
      # Hide error message
      return(renderUI(HTML(NULL)))
    }
    else{
      renderUI({
        HTML(paste0("
          <div class=\"notification-overlay\"></div>
          <div class=\"shiny-notification shiny-notification-",
            # Message type
            names(log)[1],"\">
            <div class=\"shiny-notification-close\"
              onclick=\"$('.notification-overlay').hide();
              $('.shiny-notification').hide();\">
              <i class=\"fa fa-times-circle\"></i>
            </div>
            <div class=\"shiny-notification-content\">
              <div class=\"shiny-notification-content-text\">",
                # Message text
                log[[1]],"
              </div>
              <div class=\"shiny-notification-content-action\"></div>
            </div>
          </div>"))
      })
    }
  }

  # Update UI ----
  updateUI <- function(){
    shinyjs::runjs(paste0("
      $(\"#admin-row .box:eq(0) .box-title\").text(\"",poker_app$session_user$username,"\");"))

    status <- poker_app$session_user$status()

    if(status == "Hosting"){
      shinyjs::runjs("$('a[href=\"#shiny-tab-table\"]').removeClass(\"hidden\");")
    } else{
      shinyjs::runjs("$('a[href=\"#shiny-tab-table\"]').addClass(\"hidden\");")
    }
    if(status == "In Game"){
      shinyjs::runjs("$('a[href=\"#shiny-tab-hand\"]').removeClass(\"hidden\");")
    } else {
      shinyjs::runjs("$('a[href=\"#shiny-tab-hand\"]').addClass(\"hidden\");")
    }
  }

  updateTable <- function(update_cards=TRUE, update_players=FALSE){

    # Return null if no active game
    if(is.null(poker_app$session_user$game)){
      return(NULL)
    }

    g <- poker_app$games[[poker_app$session_user$game]]
    # Update Players
    if(update_players){
      shinyjs::runjs(paste0("$('a[href=\"#shiny-tab-table\"] span').text(\"",
                            g$id,"\");"))
      for(i in 1:10){
        if(i %in% seq_along(g$players)){
          shinyjs::runjs(paste0("
            $('#player",i,"').removeClass('player-inactive');
            $('#player",i," span').text('",g$players[i],"');"))
        }
        else{
          shinyjs::runjs(paste0("
            $('#player",i,"').addClass('player-inactive');"))
        }
      }
    }
    # Update Cards
    if(update_cards){
      # Table
      if(poker_app$session_user$hosting){
        cards <- g$table_cards$cards
        if(g$state == "New Hand"){
          shinyjs::runjs("
            $('.card').addClass('card-hidden');
            $('#deck').removeClass('card-hidden');
            $('.card').attr('src','img/cards/back.png');")
        }
        else if(g$state == "Flop"){
          shinyjs::runjs(paste0("
            $('#flop1').removeClass('card-hidden');
            $('#flop2').removeClass('card-hidden');
            $('#flop3').removeClass('card-hidden');
            $('#flop1').attr('src','",cards[[1]]$get_img(),"');
            $('#flop2').attr('src','",cards[[2]]$get_img(),"');
            $('#flop3').attr('src','",cards[[3]]$get_img(),"');"))
        }
        else if(g$state == "Turn"){
          shinyjs::runjs(paste0("
            if($('#flop1').hasClass('card-hidden')){
              $('#flop1').removeClass('card-hidden');
              $('#flop2').removeClass('card-hidden');
              $('#flop3').removeClass('card-hidden');
              $('#flop1').attr('src','",cards[[1]]$get_img(),"');
              $('#flop2').attr('src','",cards[[2]]$get_img(),"');
              $('#flop3').attr('src','",cards[[3]]$get_img(),"');
            }
            $('#turn').removeClass('card-hidden');
            $('#turn').attr('src','",cards[[4]]$get_img(),"');"))
        }
        else if(g$state == "River"){
          shinyjs::runjs(paste0("
            if($('#flop1').hasClass('card-hidden')){
              $('#flop1').removeClass('card-hidden');
              $('#flop2').removeClass('card-hidden');
              $('#flop3').removeClass('card-hidden');
              $('#flop1').attr('src','",cards[[1]]$get_img(),"');
              $('#flop2').attr('src','",cards[[2]]$get_img(),"');
              $('#flop3').attr('src','",cards[[3]]$get_img(),"');
            }
            if($('#turn').hasClass('card-hidden')){
              $('#turn').removeClass('card-hidden');
              $('#turn').attr('src','",cards[[4]]$get_img(),"');
            }
            $('#river').removeClass('card-hidden');
            $('#river').attr('src','",cards[[5]]$get_img(),"');"))
        }
      }
      # Hands
      else if(poker_app$session_user$in_game()){
        cards <- poker_app$session_user$hand$cards
        if(g$state == "New Hand"){
          shinyjs::runjs("
            if(!$('#hand1').hasClass('hand-card-hidden')){
              $('#hand1').addClass('hand-card-hidden');
              $('#hand2').addClass('hand-card-hidden');
              $('#hand1').attr('src','img/cards/back.png');
              $('#hand1').attr('src','img/cards/back.png');
            }")
        }
        else{
          shinyjs::runjs(paste0("
            if($('#hand1').hasClass('hand-card-hidden')){
              $('#hand1').removeClass('hand-card-hidden');
              $('#hand2').removeClass('hand-card-hidden');
              $('#hand1').attr('src','",cards[[1]]$get_img(),"');
              $('#hand2').attr('src','",cards[[2]]$get_img(),"');
            }"))
        }
      }
    }
  }

  # Login ----
  observeEvent(input$btn_login, {
    if(nchar(input$txt_login_id)>0 && nchar(input$txt_login_pw)>0){
      if(poker_app$log_in(input$txt_login_id, input$txt_login_pw)){
        removeClass("txt_login_id", "input-error")
        removeClass("txt_login_pw", "input-error")
        addClass("login", "hidden")

        # Update UI
        if(length(poker_app$games)>0){
          updateSelectInput(session, "sct_games",
            choices = names(poker_app$games),
            selected = names(poker_app$games) %>% first)
          removeClass("btn_join_game", "disabled")
        }
        removeClass("btn_create_game", "disabled")

        updateUI()
        updateTable(update_cards=TRUE, update_players=TRUE)
      }

      output$user_status <- renderText(render_user_status())
      output$error_message <- display_error(poker_app$print_log())
    }
    else{
      if(nchar(input$txt_login_id)==0){
        addClass("txt_login_id", "input-error")
      }
      else{
        removeClass("txt_login_id", "input-error")
      }
      if(nchar(input$txt_login_pw)==0){
        addClass("txt_login_pw", "input-error")
      }
      else{
        removeClass("txt_login_pw", "input-error")
      }
    }
  })

  # Logout ----
  observeEvent(input$btn_logout, {
    poker_app$log_out()
    session$reload()
  })
  # Admin ----

  # User Status
  render_user_status <- function(){
    if(is.null(poker_app$session_user)){
      return("No active user")
    }
    if(poker_app$session_user$status()=="Inactive"){
      return("Currently inactive")
    }
    else if(poker_app$session_user$status()=="In Game"){
      return(paste("In game:", poker_app$session_user$game))
    }
    else{
      return(paste("Hosting game:", poker_app$session_user$game))
    }
  }

  # Game selection
  observeEvent(input$btn_join_game, {
      if(poker_app$join_game(input$sct_games)){
        updateUI()
        shinyjs::runjs("$('a[href=\"#shiny-tab-hand\"').click()")
      }
      else{
        output$error_message <- display_error(poker_app$print_log())
      }
  })

  # Game creation
  observeEvent(input$btn_create_game, {
    if(nchar(input$txt_game_name)>0){
      if(poker_app$create_game(input$txt_game_name)){
        updateUI()
        shinyjs::runjs("$('a[href=\"#shiny-tab-table\"').click()")
      }
      else{
        output$error_message <- display_error(poker_app$print_log())
      }
    }
  })

  # Table ----
  observeEvent(input$btn_deal,{
    if(poker_app$deal()){
      updateTable()
    }
    else{
      output$error_message <- display_error(poker_app$print_log())
    }
  })

  # Hand ----
  # observeEvent(input$foo,{
  #   print("Test")
  # })
})