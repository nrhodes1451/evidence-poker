shinyServer(function(input, output, clientData, session){
  observeEvent(input$btn_deal,{
    print("test")
  })
})