# Remember to remove unused packages from list!

library(shiny)
library(shinydashboard)
library(shinyjs)
library(readr)
library(reshape2)
library(R6)
library(lubridate)
library(plotly)
library(stringr)
library(rhandsontable)
library(tidyr)
library(dplyr)

toproper=function(x){
  x %>% strsplit(" ") %>% lapply(function(str){
    lapply(str, function(s){
      if(nchar(s)<4 && s!="for" && s!="kit") {
        return(toupper(s))}
      else{
        return(paste0(toupper(substr(s, 1, 1)), tolower(substring(s, 2))))
      }
    }) %>% paste(collapse=" ")
  }) %>% unlist
}

global_options <- list(
  skin = "black",
  status_color = "primary",
  charts = list(
    font = list(family = "sans-serif", size = 12),
    colors = list(
      purple='rgb(111,87,152)',
      blue='rgb(47,195,199)',
      grey="rgb(100,100,100")
  )
)

# Load Classes
source("objects.R")