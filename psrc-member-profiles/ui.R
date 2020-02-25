# User Interface for a Place Selection with a map returned for that place.

shinyUI(
    navbarPage(title = div(img(src="psrc-logo.png", width = 260, height = 92, style = "padding-bottom: 25px")),theme = "styles.css",
               collapsible = TRUE,
        tabPanel("Overview",
            sidebarLayout(
                sidebarPanel(
                    selectInput("Place","Please Select the community you are interested in:",data_places),
                    selectInput("Year","Please Select the year you are interested in:",data_years),
                    textOutput("Population"),
                    textOutput("MedianAge"),
                    textOutput("MedianIncome"),
                    textOutput("AvgHHSize"),
                    textOutput("UnempRate"),
                    textOutput("AvgTT"),
                    h3("Note on Census Data:"),
                    textOutput("CensusBackground"),
                    br(),
                    downloadLink('downloadData', label = "Download Data Profiles in Excel"),
                    width = 3),
                          
                mainPanel(
                    h1("Community Profiles"),
                    "We invite you to explore our various data sets through our Community Profiles Data Portal. This data portal provides access to Census data, Regional Transportation Plan Projects and the Transportation Improvement Program and project related information by jurisdiction. If you can't find what you're looking for, or would like further information about Census or project related data products, please contact us and we will be happy to assist you.",
                    hr(),
                    h2(textOutput("general_heading")),
                    hr(),
                    leafletOutput("place_map"),
                    hr()
                    
                ) # end of main panel for Community Selection
            ) # end of side bar layout for Community Selection
        ), # end of Community Selection Tab
            

        tabPanel("Demographics",
                 
                 tabsetPanel(type= "tabs",
                             tabPanel("Age",
                                      fluidRow(
                                          column(width = 5, plotlyOutput("plot_age")),
                                          column(width = 5, offset = 1, DT::dataTableOutput("table_age"))
                                      )
                             ), # end of Age tab panel
                             
                             tabPanel("Race",
                                      fluidRow(
                                          column(width = 6,
                                                 verticalLayout(plotlyOutput("plot_race"),
                                                                DT::dataTableOutput("table_race"))),
                                          column(width = 5, selectInput("Race","",data_race), leafletOutput("race_map",height="600px"))
                                      ) # end of Fluid Row
                             ), # end of Home Value tab panel

                             tabPanel("Disability",
                                      fluidRow(
                                          column(width = 5,selectInput("Disability","",data_disability),leafletOutput("disability_map",height="600px"))
                                      )
                             ), # end of Disability Tab Panel
                                                                                       
                             tabPanel("About",
                                      fluidRow(
                                          column(width = 12,
                                                 h1("Data Sources:"),
                                                 hr(),
                                                 "The mode share data is from the ACS Community Profile DP03",
                                                 br(),
                                                 "The travel time data is from ACS Datatable B08303")
                                      ) # end of Fluid Row
                             ) # end of About tab panel  
                             
                 ) # end of Demographics TabSet
                 
        ), # end of Demographics tabPanel     
                
        tabPanel("Housing",
                 
                 tabsetPanel(type= "tabs",
                             tabPanel("Type of Units",
                                      fluidRow(
                                          column(width = 5, plotlyOutput("plot_housing")),
                                          column(width = 5, offset = 1, DT::dataTableOutput("table_housing"))
                                      )
                             ), # end of units tab panel
                             
                             tabPanel("Home Value",
                                      fluidRow(
                                          column(width = 6,
                                                 verticalLayout(plotlyOutput("plot_homevalue"),
                                                                DT::dataTableOutput("table_homevalue"))),
                                          column(width = 5, br(), leafletOutput("homevalue_map",height="600px"))
                                      ) # end of Fluid Row
                             ), # end of Home Value tab panel

                             tabPanel("Monthly Rent",
                                      fluidRow(
                                          column(width = 6,
                                                 verticalLayout(plotlyOutput("plot_monthlyrent"),
                                                                DT::dataTableOutput("table_monthlyrent"))),
                                          column(width = 5, br(), leafletOutput("monthlyrent_map",height="600px"))
                                      ) # end of Fluid Row
                             ), # end of Monthly Rent tab panel
                             
                             tabPanel("Vehicles Available",
                                      fluidRow(
                                          column(width = 6,
                                                 verticalLayout(plotlyOutput("plot_vehicles"),
                                                                DT::dataTableOutput("table_vehicles"))),
                                          column(width = 5, br(), leafletOutput("zerocar_map",height="600px"))
                                      ) # end of Fluid Row
                             ), # end of Vehicle Availability tab panel                          
                                                         
                             tabPanel("About",
                                      fluidRow(
                                          column(width = 12,
                                                 h1("Data Sources:"),
                                                 hr(),
                                                 "The mode share data is from the ACS Community Profile DP03",
                                                 br(),
                                                 "The travel time data is from ACS Datatable B08303")
                                      ) # end of Fluid Row
                             ) # end of About tab panel  
                             
                 ) # end of Housing TabSet
                 
        ), # end of Housing tabPanel          
        
        tabPanel("Jobs and Income",
                 
                 tabsetPanel(type= "tabs",
                             tabPanel("Occupation",
                                      fluidRow(
                                          column(width = 5, plotlyOutput("plot_occupation")),
                                          column(width = 5, offset = 1, DT::dataTableOutput("table_occupation"))
                                      )
                             ), # end of occupation tab panel
                             
                            tabPanel("Industry",
                                    fluidRow(
                                        column(width = 5, plotlyOutput("plot_industry")),
                                        column(width = 5, offset = 1, DT::dataTableOutput("table_industry"))
                                    )
                            ), # end of industry tab panel
                            
                            tabPanel("Household Income",
                                     fluidRow(
                                         column(width = 5, plotlyOutput("plot_income")),
                                         column(width = 5, offset = 1, DT::dataTableOutput("table_income"))
                                     )
                            ), # end of income tab panel
        
                             tabPanel("About",
                                      fluidRow(
                                          column(width = 12,
                                                 h1("Data Sources:"),
                                                 hr(),
                                                 "The mode share data is from the ACS Community Profile DP03",
                                                 br(),
                                                 "The travel time data is from ACS Datatable B08303")
                                      ) # end of Fluid Row
                             ) # end of About tab panel  
                             
                 ) # end of Jobs TabSet
                 
        ), # end of Jobs tabPanel  
                
        tabPanel("Projects and Funding",
                 
                 tabsetPanel(type= "tabs",
                             tabPanel("Transportation Improvement Program",
                                      fluidRow(
                                          column(width = 5,
                                                 h2(textOutput("tip_heading")),
                                                 "The TIP provides a summary of current transportation projects underway within King, Pierce, Snohomish, and Kitsap counties. These projects are funded with federal, state and local funds, including the most recent federal grants awarded through PSRC.",
                                                 br(),
                                                 br(),
                                                 "The TIP spans a four-year period and must be updated at least every two years. After public review and comment, the TIP is approved by the Regional Council's Transportation Policy and Executive Boards before being submitted for further approvals to the Governor and ultimately the U.S. Department of Transportation.",
                                                 br(),
                                                 br(),
                                                 "The 2019-2022 Regional TIP was adopted by PSRC's Executive Board in October 2018 and final state and federal approvals were received in January of 2019.  Projects in the 2019-2022 Regional TIP are shown below.",
                                                 br(),
                                                 br()
                                                 ),
                                          column(width = 5, offset = 1, leafletOutput("tip_map",height="400px"))
                                      ), # end of Fluid Row
                                      
                                      fluidRow(
                                          column(width = 9, offset = 1, hr(), DT::dataTableOutput("table_tip")))
                             ), # end of tip tab panel
                             
                             tabPanel("Regional Transportation Plan",
                                      fluidRow(
                                          column(width = 5,
                                                 h2(textOutput("rtp_heading")),
                                                 "Larger scale regional investments planned through 2040 are included in the RTP on the Regional Capacity Projects list.",
                                                 br(),
                                                 br(),
                                                 "Regional Capacity Projects are those projects adding capacity to the regional system above a pre-determined threshold, and include roadway, transit, bicycle/pedestrian and other project types. Projects meeting this threshold must be approved on the list before proceeding towards funding and implementation. Projects that are below this threshold are considered programmatic in the plan and are able to pursue funding and implementation with no further actions.",
                                                 br(),
                                                 br(),
                                                 "As part of the update, projects are requested to be either in the financially constrained plan or in the Unprogrammed portion of the plan.",
                                                 br(),
                                                 br()
                                          ),
                                          column(width = 5, offset = 1, leafletOutput("rtp_map",height="400px"))
                                      ), # end of Fluid Row
                                      
                                      fluidRow(
                                          column(width = 9, offset = 1, hr(), DT::dataTableOutput("table_rtp")))                                      
                             ), # end of RTP tab panel
                             
                             tabPanel("About",
                                      fluidRow(
                                          column(width = 12,
                                                 h1("Data Sources:"),
                                                 hr(),
                                                 "The mode share data is from the ACS Community Profile DP03",
                                                 br(),
                                                 "The travel time data is from ACS Datatable B08303")
                                      ) # end of Fluid Row
                             ) # end of About tab panel  
                             
                 ) # end of Projects and Funding TabSet
                 
        ), # end of Projects and Funding tabPanel        

        tabPanel("Travel",
                 
                 tabsetPanel(type= "tabs",
                             tabPanel("Mode Share",
                                      fluidRow(
                                          column(width = 5,
                                                 verticalLayout(plotlyOutput("plot_ms"),
                                                                DT::dataTableOutput("table_ms"))),
                                          column(width = 6, offset=1, selectInput("Mode","",data_modes), leafletOutput("modeshare_map",height="600px"))
                                      ) # end of Fluid Row
                             ), # end of mode share tab panel
                             
                             tabPanel("Travel Time",
                                      fluidRow(
                                          column(width = 6,
                                                 verticalLayout(plotlyOutput("plot_tt"),
                                                                DT::dataTableOutput("table_tt"))),
                                          column(width = 5, br(), leafletOutput("traveltime_map",height="600px"))
                                      ) # end of Fluid Row
                             ), # end of travel time tab panel
                             
                             tabPanel("Congestion",
                                      fluidRow(
                                          column(width=2, offset = 1, selectInput("Month","Select Month:",data_months)),
                                          column(width=2, selectInput("Hour","Select Hour:",data_hours))
                                      ),
                                      fluidRow(
                                          column(width = 4, offset = 1, plotlyOutput("plot_tmc")),
                                          column(width = 5, offset = 1, leafletOutput("congestion_map"))
                                      ),
                                      fluidRow(
                                          column(width = 9, offset = 1, DT::dataTableOutput("table_tmc"))
                                      ) # end of Fluid Row
                             ), # end of congestion tab panel                
                             
                             tabPanel("About",
                                      fluidRow(
                                          column(width = 12,
                                                 h1("Data Sources:"),
                                                 hr(),
                                                 "The mode share data is from the ACS Community Profile DP03",
                                                 br(),
                                                 "The travel time data is from ACS Datatable B08303")
                                      ) # end of Fluid Row
                             ) # end of travel time tab panel  
                             
                 ) # end of Transportation TabSet
                 
        ) # end of Transportation tabPanel
                            
    ) # end of navbar page

) # end of UI

        