# Define server logic required to draw the map for the main panel
shinyServer(function(input, output) {
    
    output$general_heading <- renderText({
        paste(input$Place, " in ", input$Year)
    })

    output$place_map <- renderLeaflet({
        leaflet() %>%
            addTiles() %>%
            addPolygons(data = community.shape[which(community.shape$NAME %in% input$Place),],
                        fillColor = "76787A",
                        weight = 4,
                        opacity = 1.0,
                        color = "#91268F",
                        dashArray = "4",
                        fillOpacity = 0.0)%>%
            setView(lng=find_place_data(input$Place,"INTPTLON"), lat=find_place_data(input$Place,"INTPTLAT"), zoom=find_place_data(input$Place,"ZOOM"))
    })
    
    output$Population <- renderText({
        paste("Population: ", return_estimate(wa_places, input$Place, input$Year, "DP02_0086","estimate",0))
    })
    
    output$MedianAge <- renderText({
        paste("Median Age: ", return_estimate(wa_places, input$Place, input$Year, "DP05_0018","estimate",1))
    })
    
    output$MedianIncome <- renderText({
        paste("Median HH Income: $", return_estimate(wa_places, input$Place, input$Year, "DP03_0062","estimate",0))
    })
    
    output$AvgHHSize <- renderText({
        paste("Average HH Size: ", return_estimate(wa_places, input$Place, input$Year, "DP02_0015","estimate",2))
    })
    
    output$UnempRate <- renderText({
        paste("Unemployment Rate: ", return_estimate(wa_places, input$Place, input$Year, "DP03_0009","estimate_percent",1),"%")
    })
    
    output$AvgTT <- renderText({
        paste("Travel Time to Work: ", return_estimate(wa_places, input$Place, input$Year, "DP03_0025","estimate",1), " minutes")
    })
    
    output$table_ms <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",ms_var,ms_cols,ms_total,ms_remove,ms_order),rownames = FALSE, options = list(pageLength = mode_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_ms, "", digits = 0) %>% formatPercentage(percent_ms, 1)
    })
    
    output$plot_ms <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",ms_var,ms_cols,ms_total,ms_remove,ms_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Commuters: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#8CC63E", fill = "#8CC63E" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1))+
                xlab("Mode of Travel") +
                ylab("Percent of Total Commuters") +
                theme(legend.position = "none",
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })
    
    output$ms_heading <- renderText({
        paste("Mode to Work: ",  input$Place, " Residents")
    })
    
    output$table_tt <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",tt_var, tt_cols,tt_total,tt_remove,tt_order),rownames = FALSE, options = list(pageLength = tt_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_tt, "", digits = 0) %>% formatPercentage(percent_tt, 1)
    })
    
    output$plot_tt <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",tt_var, tt_cols,tt_total,tt_remove,tt_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Commuters: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#F05A28", fill = "#F05A28" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 0.5))+
                xlab("Travel Time (minutes)") +
                ylab("Percent of Total Commuters") +
                theme(legend.position = "none",
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })
    
    output$rtp_map <- renderLeaflet({create_project_map(input$Place)})
    
    output$tip_map <- renderLeaflet({create_tip_map(input$Place)})
    
    output$congestion_map <- renderLeaflet({create_congestion_map(input$Place, input$Hour, input$Year, input$Month)})
    
    output$CensusBackground <- renderText({
        paste("As a State Data Center for the central Puget Sound region, PSRC keeps a complete inventory of data released from the 1990, 2000, and 2010 censuses, as well as the American Community Survey (ACS).  The American Community Survey (ACS) is a product of the U.S. Census Bureau. Cities and counties use the ACS to track the well-being of children, families, and the elderly. They use it to determine where to locate new roads and transit routes, schools, and hospitals. This portal includes demographic profiles which include age, sex, income, household size, education, and other topics for all cities and towns in the PSRC region.")
    })

    output$DemographicBackground <- renderText({
        paste("Most of the information on demographic characteristics is summarized in Data Profile 5 (DP05) with household, disability and ancestry data in Data Profile 2 (DP02). DP05 includes data on age and race and is a summarization of a variety of detailed tables related to age and race contained within the American Community Survey datasets.")
    }) 

    output$HousingBackground <- renderText({
        paste("Housing characteristics are summarized in Data Profile 4 (DP04) and includes data on occupancy, units, bedrooms, costs, tenure, value and vehicle availability.")
    }) 

    output$JobsBackground <- renderText({
        paste("Job and income characteristics are summarized in Data Profile 3 (DP03) and includes data on occupations, household income, health insurance and mode to work.")
    })     
        
    output$table_rtp <- DT::renderDataTable({
        datatable(create_project_table(input$Place,rtp.shape,rtp_cols,final_nms), rownames = FALSE, options = list(pageLength = proj_length, columnDefs = list(list(className = 'dt-center', targets = 4:6)))) %>% formatCurrency(currency_rtp , "$", digits = 0)
    })
    
    output$table_tip <- DT::renderDataTable({
        datatable(create_project_table(input$Place,tip.shape,tip_cols,final_nms), rownames = FALSE, options = list(pageLength = proj_length, columnDefs = list(list(className = 'dt-center', targets = 4:6)))) %>% formatCurrency(currency_rtp , "$", digits = 0)
    })
    
    output$tip_heading <- renderText({
        paste("Transportation Improvement Program: Projects in ",  input$Place)
    })

    output$rtp_heading <- renderText({
        paste("Regional Capacity Project List: Projects in ",  input$Place)
    }) 
    
    output$occupation_heading <- renderText({
        paste("Occupations for Residents in ",  input$Place)
    })

    output$industry_heading <- renderText({
        paste("Industry of Occupation for Residents in ",  input$Place)
    })    

    output$income_heading <- renderText({
        paste("Household Income for Residents in ",  input$Place)
    })     
            
    output$table_tmc <- DT::renderDataTable({
        datatable(create_tmc_table(tmc.ratios, input$Place, orig_tmc, final_tmc, input$Hour, input$Year, input$Month), rownames = FALSE, options = list(pageLength = tmc_length, columnDefs = list(list(className = 'dt-center', targets = 3:7)))) %>% formatCurrency(decimal_tmc , "", digits = 2) %>% formatCurrency(number_tmc , "", digits = 0)
    })
    
    output$plot_tmc <- renderPlotly({
        ggplotly(
            ggplot(data=create_tmc_congestion_table(tmc.ratios, input$Place, orig_tmc, final_tmc, input$Hour, input$Year, input$Month), 
                   aes(x = `Place`,
                       fill=`Congestion Level`, 
                       y=`Share`,
                       text= paste0("<b>", "% Congested: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", position="stack" ) +
                scale_fill_manual(values=congestion_colors) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1.0))+
                xlab("Level of Congestion") +
                ylab("% NHS Congested") +
                theme(legend.position = "bottom",
                      legend.direction="horizontal",
                      legend.title = element_blank(),
                      axis.text=element_text(size=10),
                      axis.text.x = element_blank(),
                      axis.ticks.x = element_blank(),
                      axis.title.x = element_blank(),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text")) %>% layout(legend = list(orientation = 'h', x=0.35, y=0))
    })
    
    output$plot_occupation <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",occ_var,occ_cols,occ_total,occ_remove,occ_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Workers: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#91268F", fill = "#91268F" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1))+
                xlab("Occupation") +
                ylab("Percent of Total Workers") +
                theme(legend.position = "none",
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })
    
    
    
    output$plot_industry <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",ind_var,ind_cols,ind_total,ind_remove,ind_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Workers: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#00A7A0", fill = "#00A7A0" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 0.5))+
                coord_flip() +
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())
            ,tooltip = c("text"))
    })
    
    output$plot_income <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",inc_var,inc_cols,inc_total,inc_remove,inc_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Households: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#8CC63E", fill = "#8CC63E" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 0.5))+
                coord_flip() +
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())
            ,tooltip = c("text"))
    })
    
    output$table_occupation <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",occ_var,occ_cols,occ_total,occ_remove,occ_order),rownames = FALSE, options = list(pageLength = job_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_jobs, "", digits = 0) %>% formatPercentage(percent_jobs, 1)
    })
    
    output$table_industry <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",ind_var,ind_cols,ind_total,ind_remove,ind_order),rownames = FALSE, options = list(pageLength = job_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_jobs, "", digits = 0) %>% formatPercentage(percent_jobs, 1)
    })
    
    output$table_income <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",inc_var,inc_cols,inc_total,inc_remove,inc_order),rownames = FALSE, options = list(pageLength = job_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_jobs, "", digits = 0) %>% formatPercentage(percent_jobs, 1)
    })
    
    output$table_housing <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",hs_var, hs_cols,hs_total,hs_remove,hs_order),rownames = FALSE, options = list(pageLength = house_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_hs, "", digits = 0) %>% formatPercentage(percent_hs, 1)
    })
    
    output$plot_housing <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",hs_var, hs_cols,hs_total,hs_remove,hs_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Housing Units: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#F05A28", fill = "#F05A28" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1.0))+
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
            scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })
 
    output$table_vehicles <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",va_var, va_cols,va_total,va_remove,va_order),rownames = FALSE, options = list(pageLength = va_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_va, "", digits = 0) %>% formatPercentage(percent_va, 1)
    })
    
    output$plot_vehicles <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",va_var, va_cols,va_total,va_remove,va_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Occupied Units: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#00A7A0", fill = "#00A7A0" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1.0))+
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })  

    output$table_homevalue <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",hv_var, hv_cols,hv_total,hv_remove,hv_order),rownames = FALSE, options = list(pageLength = hv_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_hv, "", digits = 0) %>% formatPercentage(percent_hv, 1)
    })
    
    output$plot_homevalue <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",hv_var, hv_cols,hv_total,hv_remove,hv_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Owner Occupied Units: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#8CC63E", fill = "#8CC63E" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1.0))+
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })    

    output$table_monthlyrent <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",rent_var, rent_cols,rent_total,rent_remove,rent_order),rownames = FALSE, options = list(pageLength = rent_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_rent, "", digits = 0) %>% formatPercentage(percent_rent, 1)
    })
    
    output$plot_monthlyrent <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",rent_var, rent_cols,rent_total,rent_remove,rent_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Rental Occupied Units: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#91268F", fill = "#91268F" ) +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1.0))+
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })     

    output$table_age <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",age_var,age_cols,age_total,age_remove,age_order),rownames = FALSE, options = list(pageLength = age_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_age, "", digits = 0) %>% formatPercentage(percent_age, 1)
    })
    
    output$plot_age <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",age_var,age_cols,age_total,age_remove,age_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Population: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#91268F", fill = "#91268F") +
                scale_y_continuous(labels = scales::percent, limits = c(0, 0.5))+
                coord_flip() +
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())
            ,tooltip = c("text"))
    })
    
    output$downloadData <- downloadHandler(
        filename = function() {paste0("acsprof",as.character(as.integer(input$Year)-2004),"-",as.character(as.integer(input$Year)-2000),"-pl-",str_replace(tolower(input$Place)," ","-"),".xlsx")},
        content <- function(file) {file.copy(paste0("c:/coding/census-data-profiles/output/acsprof",as.character(as.integer(input$Year)-2004),"-",as.character(as.integer(input$Year)-2000),"-pl-",str_replace(tolower(input$Place)," ","-"),".xlsx"),file)},
        contentType = "application/Excel"
    )

    output$table_race <- DT::renderDataTable({
        datatable(create_summary_table(wa_places,input$Place,input$Year,"variable_name",race_var,race_cols,race_total,race_remove,race_order),rownames = FALSE, options = list(pageLength = race_length, columnDefs = list(list(className = 'dt-center', targets =1:4)))) %>% formatCurrency(numeric_race, "", digits = 0) %>% formatPercentage(percent_race, 1)
    })
    
    output$plot_race <- renderPlotly({
        ggplotly(
            ggplot(data=create_summary_table(wa_places,input$Place,input$Year,"variable_name",race_var,race_cols,race_total,race_remove,race_order), 
                   aes(x=`variable_description`, 
                       y=`Share`,
                       text= paste0("<b>", "% of Total Population: ","</b>",prettyNum(round(`Share`*100, 1), big.mark = ","),"%")
                   )) +
                geom_bar(stat="identity", color = "#8CC63E", fill = "#8CC63E") +
                scale_y_continuous(labels = scales::percent, limits = c(0, 1.0))+
                theme(legend.position = "none",
                      axis.title.y=element_blank(), 
                      axis.title.x=element_blank(),
                      axis.text=element_text(size=10),
                      axis.title=element_text(size=12,face="bold"),
                      panel.grid.major = element_blank(),
                      panel.grid.minor = element_blank(),
                      panel.border = element_blank(),
                      axis.line = element_blank())+
                scale_x_discrete(labels = function(x) str_wrap(x, width = 5))
            ,tooltip = c("text"))
    })
    
    output$monthlyrent_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, "DP04_0134",input$Year, "Blues", input$Place, "estimate", "variable_name", "Median Rent", "$","")})
    
    output$homevalue_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, "DP04_0089",input$Year, "Blues", input$Place, "estimate", "variable_name", "Median Home Value", "$","")})
    
    output$zerocar_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, "DP04_0058",input$Year, "Blues", input$Place, "estimate_percent", "variable_name", "% Zero Car HH's", "","%")})
    
    output$traveltime_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, "DP03_0025",input$Year, "Blues", input$Place, "estimate", "variable_name", "Time to Work (minutes)", "","")})
    
    output$disability_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, input$Disability, input$Year, "Blues", input$Place, "estimate_percent", "variable_description", "Share of People with a Disability", "","%")})
    
    output$modeshare_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, input$Mode, input$Year, "Blues", input$Place, "estimate_percent", "variable_description", "Share", "","%")})

    output$race_map <- renderLeaflet({create_tract_map_pick_variable(wa_tracts, input$Race, input$Year, "Blues", input$Place, "estimate_percent", "variable_description", "Share of Population", "","%")})    

    observeEvent(input$showpanel, {
        
        if(input$showpanel == TRUE) {
            removeCssClass("Main", "col-sm-12")
            addCssClass("Main", "col-sm-8")
            shinyjs::show(id = "sidebar")
            shinyjs::enable(id = "sidebar")
        }
        else {
            removeCssClass("Main", "col-sm-8")
            addCssClass("Main", "col-sm-12")
            shinyjs::hide(id = "sidebar")
        }
    })
    
    
})
