shinyServer(function(input, output, clientData, session){

  # Buttons disabled by default ----
  addClass("btn-join-game", "disabled")
  addClass("btn_create_game", "disabled")
  addClass("btn_deal", "disabled")

  # Error Messages ----
  display_error <- function(log){
    print(log)
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

  output$mmm_error_message <- display_error(poker_app$print_log())

  # Login ----
  observeEvent(input$btn_login, {
    if(nchar(input$txt_login_id)>0 && nchar(input$txt_login_pw)>0){
      if(poker_app$log_in(input$txt_login_id, input$txt_login_pw)){
        removeClass("txt_login_id", "input-error")
        removeClass("txt_login_pw", "input-error")
        addClass("login", "hidden")

        # Update UI
        if(length(poker_app$games)>0){
          updateSelectInput(session, "sct-games",
            choices = names(poker_app$games),
            selected = names(poker_app$games) %>% first)
          removeClass("btn-join-game", "disabled")
        }
        removeClass("btn_create_game", "disabled")
      }
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

  # Admin ----

  # Game selection

  # Game creation
  observeEvent(input$btn_create_game, {
    if(nchar(input$txt_game_name)>0){
      if(poker_app$create_game(input$txt_game_name)){
        # js$goToTable()
      }
      else{
        output$error_message <- display_error(poker_app$print_log())
      }
    }
  })

  # Table ----
  observeEvent(input$btn_deal,{
    print("test")
  })
})