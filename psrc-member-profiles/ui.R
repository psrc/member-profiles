# User Interface for a Place Selection with a map returned for that place.

shinyUI(
    fluidPage(sidebarLayout(
        sidebarPanel(id = "sidebar",
            div(img(src="psrc-logo.png", width = 260, height = 92, style = "padding-top: 25px")),
            br(),
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
            width=3),
        mainPanel(shinyjs::useShinyjs(), id ="Main",
                  bsButton("showpanel", "Show/hide sidebar", type = "toggle", value = TRUE),
            navbarPage(title = "", theme = "styles.css", windowTitle = "PSRC Community Profiles",
                             tabPanel(icon("city"),
                                      h1("Community Profiles"),
                                      "We invite you to explore our various data sets through our Community Profiles Data Portal. This data portal provides access to Census data, Regional Transportation Plan Projects and the Transportation Improvement Program and project related information by jurisdiction. If you can't find what you're looking for, or would like further information about Census or project related data products, please contact us and we will be happy to assist you.",
                                      hr(),
                                      h2(textOutput("general_heading")),
                                      hr(),
                                      leafletOutput("place_map"),
                                      hr()
                            ), # end of Overview tabset panel
            
                            tabPanel(icon("users"),
                                textOutput("DemographicBackground"),
                                tabsetPanel(
                                    
                                    tabPanel("Age",
                                        fluidRow(
                                            column(width = 6, br(), plotlyOutput("plot_age")),
                                            column(width = 6, br(), DT::dataTableOutput("table_age"))
                                        ) # end of fluid row
                                    ), # end of age tab panel
                                          
                                    tabPanel("Race",
                                        fluidRow(
                                            column(width = 6, br(), br(), plotlyOutput("plot_race")),
                                            column(width = 6, selectInput("Race","",data_race), leafletOutput("race_map"))
                                        ), # end of fluid row
                                        fluidRow(
                                            column(width = 12,hr(),DT::dataTableOutput("table_race"))
                                        ) # end of fluid Row
                                    ), # end of race tab panel
                                          
                                    tabPanel("Disability",
                                        fluidRow(
                                            column(width = 12,selectInput("Disability","",data_disability),leafletOutput("disability_map"))
                                        ) # end of fluid row
                                    ) # end of Disability Tab Panel
                                    
                                ) # end of Demographics tabset panel
                            ), # end of Demographics Tab Panel
            
                            tabPanel(icon("home"),
                                textOutput("HousingBackground"),
                                tabsetPanel(
                                
                                    tabPanel("Housing Units",
                                        fluidRow(
                                            column(width = 12, plotlyOutput("plot_housing"))
                                      
                                        ), # end of fluid row
                                        fluidRow(
                                            column(width = 12, hr(), DT::dataTableOutput("table_housing"))
                                        ) # end of fluid row
                                    ), # end of units tab panel
                         
                                    tabPanel("Home Value",
                                        fluidRow(
                                            column(width = 6,
                                             verticalLayout(plotlyOutput("plot_homevalue"),
                                                            DT::dataTableOutput("table_homevalue"))),
                                            column(width = 6, br(), leafletOutput("homevalue_map",height="600px"))
                                        ) # end of Fluid Row
                                    ), # end of Home Value tab panel
                         
                                    tabPanel("Monthly Rent",
                                        fluidRow(
                                            column(width = 6,
                                             verticalLayout(plotlyOutput("plot_monthlyrent"),
                                                            DT::dataTableOutput("table_monthlyrent"))),
                                            column(width = 6, br(), leafletOutput("monthlyrent_map",height="600px"))
                                        ) # end of Fluid Row
                                    ), # end of Monthly Rent tab panel
                         
                                    tabPanel("Vehicles Available",
                                        fluidRow(
                                            column(width = 6,
                                             verticalLayout(plotlyOutput("plot_vehicles"),
                                                            DT::dataTableOutput("table_vehicles"))),
                                            column(width = 6, br(), leafletOutput("zerocar_map",height="600px"))
                                        ) # end of Fluid Row
                                    ) # end of Vehicle Availability tab panel 
                         
                                ) # end of Housing tabset panel
                            ), # end of Housing Tab Panel

                            tabPanel(icon("briefcase"),
                                     textOutput("JobsBackground"),
                                     tabsetPanel(
                                         
                                         tabPanel("Occupation",
                                                  fluidRow(
                                                      column(width = 12, plotlyOutput("plot_occupation"))
                                                      
                                                  ), # end of fluid row
                                                  fluidRow(
                                                      column(width = 12, hr(), DT::dataTableOutput("table_occupation"))
                                                  ) # end of fluid row
                                         ), # end of occupation tab panel
                                         
                                         tabPanel("Industry",
                                                  fluidRow(
                                                      column(width = 12, plotlyOutput("plot_industry"))
                                                      
                                                  ), # end of fluid row
                                                  fluidRow(
                                                      column(width = 12, hr(), DT::dataTableOutput("table_industry"))
                                                  ) # end of fluid row
                                         ), # end of industry tab panel
                                         
                                         tabPanel("Income",
                                                  fluidRow(
                                                      column(width = 12, plotlyOutput("plot_income"))
                                                      
                                                  ), # end of fluid row
                                                  fluidRow(
                                                      column(width = 12, hr(), DT::dataTableOutput("table_income"))
                                                  ) # end of fluid row
                                         ) # end of income tab panel
                                         
                                     ) # end of jobs and income tabset panel
                            ), # end of jobs and income Tab Panel
                            
                            tabPanel(icon("wrench"),
                                     
                                     tabsetPanel(
                                         
                                        tabPanel("Transportation Improvement Program",
                                                fluidRow(
                                                    column(width = 6,
                                                            h3(textOutput("tip_heading")),
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
                                                    column(width = 6, br(), leafletOutput("tip_map",height="400px"))
                                                ), # end of Fluid Row
                                                          
                                                fluidRow(
                                                        column(width = 12, hr(), DT::dataTableOutput("table_tip")))
                                        ), # end of tip tab panel
                                                 
                                        tabPanel("Regional Transportation Plan",
                                                fluidRow(
                                                        column(width = 6,
                                                                h3(textOutput("rtp_heading")),
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
                                                        column(width = 6, br(), leafletOutput("rtp_map",height="400px"))
                                                ), # end of Fluid Row
                                                          
                                                fluidRow(
                                                        column(width = 12, hr(), DT::dataTableOutput("table_rtp")))                                      
                                        ) # end of RTP tab panel
                                                 
                                     ) # end of Projects and Funding TabSet
                                     
                            ), # end of Projects and Funding tabPanel                             

                            tabPanel(icon("car"),
                                     
                                tabsetPanel(
                                        tabPanel("Mode Share",
                                                fluidRow(
                                                        column(width = 6,
                                                            verticalLayout(plotlyOutput("plot_ms"),
                                                                            DT::dataTableOutput("table_ms"))),
                                                        column(width = 6, selectInput("Mode","",data_modes), leafletOutput("modeshare_map",height="600px"))
                                                ) # end of Fluid Row
                                        ), # end of mode share tab panel
                                                 
                                        tabPanel("Travel Time to Work",
                                                fluidRow(
                                                        column(width = 6,
                                                            verticalLayout(plotlyOutput("plot_tt"),
                                                                            DT::dataTableOutput("table_tt"))),
                                                        column(width = 6, br(), leafletOutput("traveltime_map",height="600px"))
                                                ) # end of Fluid Row
                                        ), # end of travel time tab panel
                                                 
                                        tabPanel("Congestion",
                                                fluidRow(
                                                        column(width=2, offset=1, selectInput("Month","Select Month:",data_months)),
                                                        column(width=2, selectInput("Hour","Select Hour:",data_hours))
                                                ), # end of Fluid Row
                                                
                                                fluidRow(
                                                        column(width = 6, plotlyOutput("plot_tmc")),
                                                        column(width = 6, leafletOutput("congestion_map"))
                                                ), # end of Fluid Row
                                                          
                                                fluidRow(
                                                        column(width = 12, hr(), DT::dataTableOutput("table_tmc"))
                                                ) # end of Fluid Row
                                        ) # end of congestion tab panel                
                                                 
                                     ) # end of Transportation TabSet
                                     
                            ), # end of Transportation tabPanel

                            tabPanel(icon("info-circle"),
                                     h1("Data Sources"),
                                     "The data in this portal comes from a few key sources:",
                                     hr(),
                                     h2("Census Data"),
                                     "The Census Data used in this portal is stored in PSRC's central database but is available from the US Census Bureau. All tables can be downloaded either via the Census API (https://www.census.gov/data/developers/data-sets/acs-5year.html) or the Census Data page (https://data.census.gov/cedsci/).",
                                     br(),
                                     h3("Census Tables:"),
                                     "Travel Time to Work: Table B08303",
                                     br(),
                                     "Age: Data Profile 5 (DP05)",
                                     br(),
                                     "Disability: Data Profile 2 (DP02)",
                                     br(),
                                     "Housing Units: Data Profile 4 (DP04)",
                                     br(),
                                     "Home Value: Data Profile 4 (DP04)",
                                     br(),
                                     "Income: Data Profile 3 (DP03)",
                                     br(),
                                     "Industry: Data Profile 3 (DP03)",
                                     br(),
                                     "Mode Share: Data Profile 3 (DP03)",
                                     br(),
                                     "Monthly Rent: Data Profile 4 (DP04)",
                                     br(),
                                     "Occupation: Data Profile 3 (DP03)",
                                     br(),
                                     "Race: Data Profile 5 (DP05)",
                                     br(),
                                     "Vehicles Available: Data Profile 4 (DP04)",
                                     br()
                            ) # end of Data tabset panel
                            
                                                        
                    ) # end of NavBar Page
                ) # end of main panel
        ) # end of sidebar layout
    ) # end of main fluid page
) #end of shiny ui
