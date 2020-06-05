##' @noRd
mod_special_wells_ui <- function(id){
    ns <- shiny::NS(id)
    shiny::fluidRow(
        shiny::column(
            width = 6,
            shinydashboard::box(
                status = "warning",
                width = 12,
                solidHeader = TRUE,
                title = shiny::h3(shiny::textOutput(ns("status"))),
                shiny::fluidRow(
                    shiny::column(
                        width = 2,
                        align = "right",
                        shinyWidgets::dropdownButton(
                            shiny::div(shiny::textOutput(ns("help"))),
                            icon = shiny::icon("info-circle"),
                            tooltip = shinyWidgets::tooltipOptions(title = "Help"),
                            status = "warning",
                            size = "sm",
                            width = "350px"
                        )
                    )
                ),
                shiny::textInput(
                    ns("special_select"),
                    shiny::h4("Enter Line Letter & Column number, each box 
                          separated by commas without spaces.\n The wells 
                          already filled as forbidden will not be drawn as 
                          'Not Random'."),
                    value = NULL,
                    placeholder = "Ex: A1,B2,C3")
            ) # end of box
        )
    )
}


##' @noRd
mod_special_wells_server <- function(input, output, session, status, p_dimensions){
    if (status == "forbidden") {
        output$status <- shiny::renderText({
            "Forbidden Wells"
        })
        output$help <- shiny::renderText({
            "Forbidden means that the wells in question will not be filled at 
            all in the final plate plan. Consequently, during 
            the experiment, these will be completely empty wells."
        })
        
    }else if (status == "notRandom") {
        output$status <- shiny::renderText({
            "Not randomized Wells"
        })
        
        output$help <- shiny::renderText({
            "These samples will not be used for the backtracking algorithm.
            They correspond to Quality controls or Standards."
        })
    }
    
    p_lines <- shiny::reactive({
        return(p_dimensions()$nb_lines)
    })
    
    p_cols <- shiny::reactive({
        return(p_dimensions()$nb_cols)
    })
    
    special_wells <- shiny::reactive({
        ## if special wells have been entered, then we transform into a dataframe
        ## compatible with the rest of the code
        if (input$special_select != "") {
            return(convertVector2Df(input$special_select,
                                    p_lines(),
                                    p_cols(),
                                    status = status))
        }else{
            return(NULL)
        }
    })

    return(special_wells)
}