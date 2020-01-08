backtrackUI <- function(id, label = NULL) {
  ns <- NS(id)
  fluidRow(
    box(title = h3("Your dataset"),
        collapsible = TRUE,
        width = 4,
        status = "warning",
        withLoader(
          dataTableOutput(ns("df_modif")),
          type = "html",
          loader = "loader3"
        )

    ),
    box(title = h3("Plate Layout Experiment"),
        width = 8,
        status = "warning",
        withLoader(
          plotOutput(ns("mapPlot"), height = 600),
          type = "html",
          loader = "loader3"
        )


    )
  )

}


# Server function for backtracking module
# df : dataframe - user data
# nb_g : total number of distinct groups
# max_iter : integer - maximal number of iterations
# forbidden_wells : dataframe  - containing all the blanks and forbidden wells
# rows : integer - plate's number of rows
# columns : integer - plate's number of columns
# constraint : character - neighborhood spatial constraint mode
backtrack <- function(input, output, session, df, nb_g, max_iter, forbidden_wells, rows, columns, constraint, project_name) {

  toReturn <- reactiveValues(
    final_df = NULL,
    final_map = NULL
  )

  user_data <- reactive({
    df$Group <- as.factor(df$Group)
    df$Well <- as.character(NA)
    df$Status <- as.factor("allowed")
    df$Row <- NA
    df$Column <- NA
    return(df)
  })


  # map is a list containing:
  #     a map plate : dataframe (containing user data + blanks + forbidden wells, ready to
  #                   be plotted or/and downloaded)
  #     the number of attempts to success
  map <- reactive({
    generateMapPlate(user_df = user_data(),
                  nb_rows = rows(),
                  nb_cols = columns(),
                  df_forbidden = forbidden_wells(),
                  mod = constraint(),
                  max_it = max_iter

    )
  })

  output$df_modif <- renderDataTable(datatable({
    map()
  }, rownames=FALSE)
  )

  map_plot <- reactive({
    if("forbidden" %in% map()$Status | "blank" %in% map()$Status){
      nb_g = nb_g + 1
      drawPlateMap(df = map(), nb_gps = nb_g, plate_lines = rows(), plate_cols = columns(), project_title = project_name())
    }else if("forbidden" %in% map()$Status & "blank" %in% map()$Status){
      nb_g = nb_g + 2
      drawPlateMap(df = map(), nb_gps = nb_g, plate_lines = rows(), plate_cols = columns(), project_title = project_name())
    }else{
      drawPlateMap(df = map(), nb_gps = nb_g, plate_lines = rows(), plate_cols = columns(), project_title = project_name())
    }
  })

  output$mapPlot <- renderPlot({
    map_plot()
  })

  loginfo("class(map()): %s",class(map()), logger = "backtracking")
  observeEvent(map(), {
    sendSweetAlert(
      session = session,
      title = "Success !!",
      text = "All in order, you can check your results in the Results Panel",
      type = "success"
    )
    },
    ignoreNULL = TRUE
  )

  # observeEvent(map(), {
  #   sendSweetAlert(
  #     session = session,
  #     title = "WPM failed...",
  #     text = "Seems that we reeched the maximal number of iterations without any result... Try again by increasing the number of iterations. ",
  #     type = "error"
  #   )
  #   },
  #   ignoreNULL = FALSE,
  #   ignoreInit = TRUE
  # )




  observe({
    toReturn$final_df <- map()
    toReturn$final_map <- map_plot()
  })



  return(toReturn)

}