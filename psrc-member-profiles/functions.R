# Functions for use in app creation

# Function to Return a value from the place shapefile such as lat, lon, zoom level or county
find_place_data <- function(wrk_nm, wrk_typ) {
  wrk_coord <- as.numeric(community.point[NAME == wrk_nm,get(wrk_typ)])
  return(wrk_coord)
}

# Function
table_from_db <- function(srv_nm,db_nm,tbl_nm) {
  db_con <- dbConnect(odbc::odbc(),
                      driver = "SQL Server",
                      server = srv_nm,
                      database = db_nm,
                      trusted_connection = "yes"
  )
  
  w_tbl <- dbReadTable(db_con,SQL(tbl_nm))
  odbc::dbDisconnect(db_con)
  setDT(w_tbl)
  return(w_tbl)
}

table_cleanup <- function(w_tbl,curr_cols,upd_cols) {
  w_tbl <-w_tbl[,..curr_cols]
  setnames(w_tbl,upd_cols)  
  return(w_tbl)
}

return_estimate <- function(wrk_tbl,wrk_plc,wrk_yr,wrk_var, wrk_val, wrk_dec) {
  wrk_result <- format(as.numeric(wrk_tbl[place_name %in% wrk_plc & year %in% wrk_yr & variable_name %in% wrk_var,sum(get(wrk_val))]), nsmall = wrk_dec, big.mark = ",")
  return(wrk_result)
}

create_summary_table <- function(w_tbl,w_plc,w_yr,w_cat,w_var,w_cols,w_tot,w_rem,w_ord) {
  # Subset the table and add a share of the total results
  tbl <- w_tbl[place_name %in% w_plc & year %in% w_yr & get(w_cat) %in% w_var]
  tbl <- tbl[,..w_cols]
  
  # First Remove any extraneous columns if w_remove is not NULL
  if (!is.null(w_rem)) {
    tbl <- tbl[!(variable_description %in% w_rem)]
  }
  
  # Calculate a Total to use in share calculations and then remove the total
  total <- as.integer(tbl[variable_description == w_tot,sum(estimate)])
  tbl$Share <- tbl$estimate / total
  tbl <- tbl[!(variable_description %in% w_tot)]
  
  # Set the order of the table using factors
  tbl$variable_description <- factor(tbl$variable_description, levels = w_ord)
  tbl <- tbl[order(variable_description),]
  
  # Calculate Regional Shares for comparison
  r_tbl <- w_tbl[place_name %in% c("King County","Kitsap County", "Pierce County", "Snohomish County") & year %in% w_yr & get(w_cat) %in% w_var]
  r_tbl <- r_tbl[,..w_cols]
  
  # First Remove any extraneous columns if w_remove is not NULL
  if (!is.null(w_rem)) {
    r_tbl <- r_tbl[!(variable_description %in% w_rem)]
  }
  
  # Combine County Results into a Regional Total
  regional <- r_tbl %>% group_by(variable_description) %>% summarise(estimate = sum(estimate))
  setDT(regional)
  
  # Calculate a Total to use in share calculations and then remove the total
  total <- as.integer(regional[variable_description == w_tot,sum(estimate)])
  regional$Region <- regional$estimate / total
  regional <- regional[!(variable_description %in% w_tot)] 
  f_cols <- c("variable_description","Region")
  
  # Set the order of the table using factors
  regional$variable_description <- factor(regional$variable_description, levels = w_ord)
  regional <- regional[order(variable_description),]
  regional <- regional[,..f_cols]
  
  # Merge the Place and Region tables on variable description
  tbl <- merge(tbl,regional,by="variable_description")
  
  return(tbl)
}

create_project_map <- function(w_place) {
  
  # First determine the city and trim city shapefile and project coverage to the city
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  interim <- intersect(rtp.shape, city)
  proj_ids <- unique(interim$mtpid)
  
  if (is.null(interim) == TRUE) {
    
    working_map <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(baseGroups = c("Base Map"),
                       overlayGroups = c("Approved Projects","Candidate Projects","Unprogrammed Projects","City Boundary"),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      addPolygons(data = city,
                  fillColor = "76787A",
                  weight = 1,
                  opacity = 1.0,
                  color = "#444444",
                  fillOpacity = 0.10,
                  group = "City Boundary")%>%
      setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
    
  } else {
    
    rtp.trimmed <- rtp.shape[which(rtp.shape$mtpid %in% proj_ids),]
    
    candidate <- rtp.trimmed[which(rtp.trimmed$MTPStatus %in% "Candidate"),]
    approved <- rtp.trimmed[which(rtp.trimmed$MTPStatus %in% "Approved"),]
    unprogrammed <- rtp.trimmed[which(rtp.trimmed$MTPStatus %in% "Unprogrammed"),]
    
    approved_labels <- paste0("<b>","Project Sponsor: ", "</b>",approved$Sponsor,
                              "<b> <br>",paste0("Project Title: "), "</b>", approved$Title,
                              "<b> <br>",paste0("Project Cost: $"), "</b>", prettyNum(round(approved$TotalCost, 0), big.mark = ","),
                              "<b> <br>",paste0("Project Status: "), "</b>", approved$MTPStatus,
                              "<b> <br>",paste0("Project Completion: "), "</b>", approved$CompletionYear) %>% lapply(htmltools::HTML)
    
    candidate_labels <- paste0("<b>","Project Sponsor: ", "</b>",candidate$Sponsor,
                               "<b> <br>",paste0("Project Title: "), "</b>", candidate$Title,
                               "<b> <br>",paste0("Project Cost: $"), "</b>", prettyNum(round(candidate$TotalCost, 0), big.mark = ","),
                               "<b> <br>",paste0("Project Status: "), "</b>", candidate$MTPStatus,
                               "<b> <br>",paste0("Project Completion: "), "</b>", candidate$CompletionYear) %>% lapply(htmltools::HTML)    
    
    unprogrammed_labels <- paste0("<b>","Project Sponsor: ", "</b>",unprogrammed$Sponsor,
                                  "<b> <br>",paste0("Project Title: "), "</b>", unprogrammed$Title,
                                  "<b> <br>",paste0("Project Cost: $"), "</b>", prettyNum(round(unprogrammed$TotalCost, 0), big.mark = ","),
                                  "<b> <br>",paste0("Project Status: "), "</b>", unprogrammed$MTPStatus,
                                  "<b> <br>",paste0("Project Completion: "), "</b>", unprogrammed$CompletionYear) %>% lapply(htmltools::HTML)
    # Create Map
    working_map <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(baseGroups = c("Base Map"),
                       overlayGroups = c("Approved Projects","Candidate Projects","Unprogrammed Projects","City Boundary"),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      addPolygons(data = city,
                  fillColor = "76787A",
                  weight = 4,
                  opacity = 1.0,
                  color = "#91268F",
                  dashArray = "4",
                  fillOpacity = 0.0,
                  group = "City Boundary")%>% 
      addPolylines(data = approved,
                   color = "#91268F",
                   weight = 4,
                   label = approved_labels,
                   fillColor = "#91268F",
                   group = "Approved Projects") %>%
      addPolylines(data = candidate,
                   color = "#8CC63E",
                   weight = 4,
                   label = candidate_labels,
                   fillColor = "#8CC63E",
                   group = "Candidate Projects") %>%
      addPolylines(data = unprogrammed,
                   color = "#00A7A0",
                   weight = 4,
                   dashArray = "4",
                   label = unprogrammed_labels,
                   fillColor = "#00A7A0",
                   group = "Unprogrammed Projects") %>%
      
      setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
  }
  
  return(working_map)
  
}

create_tip_map <- function(w_place) {
  
  # First determine the city and trim city shapefile and project coverage to the city
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  interim <- intersect(tip.shape, city)
  proj_ids <- unique(interim$ProjNo)
  
  if (is.null(interim) == TRUE) {
    
    working_map <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(baseGroups = c("Base Map"),
                       overlayGroups = c("TIP Projects","City Boundary"),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      addPolygons(data = city,
                  fillColor = "76787A",
                  weight = 1,
                  opacity = 1.0,
                  color = "#444444",
                  fillOpacity = 0.10,
                  group = "City Boundary")%>%
      setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
    
  } else {
    
    tip.trimmed <- tip.shape[which(tip.shape$ProjNo %in% proj_ids),]
    
    labels <- paste0("<b>","Project Sponsor: ", "</b>",tip.trimmed$PlaceShortName,
                     "<b> <br>",paste0("Project Title: "), "</b>", tip.trimmed$ProjectTitle,
                     "<b> <br>",paste0("Project Cost: $"), "</b>", prettyNum(round(tip.trimmed$TotCost, 0), big.mark = ","),
                     "<b> <br>",paste0("Type of Improvement: "), "</b>", tip.trimmed$ImproveType,
                     "<b> <br>",paste0("Project Completion: "), "</b>", tip.trimmed$EstCompletionYear) %>% lapply(htmltools::HTML)
    
    # Create Map
    working_map <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(baseGroups = c("Base Map"),
                       overlayGroups = c("TIP Projects","City Boundary"),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      addPolygons(data = city,
                  fillColor = "76787A",
                  weight = 4,
                  opacity = 1.0,
                  color = "#91268F",
                  dashArray = "4",
                  fillOpacity = 0.0,
                  group = "City Boundary")%>% 
      addPolylines(data = tip.trimmed,
                   color = "#F05A28",
                   weight = 4,
                   label = labels,
                   fillColor = "#F05A28",
                   group = "TIP Projects") %>%
      setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
  }
  
  return(working_map)
  
}

create_project_table <- function(w_place, w_program, o_nms, f_nms) {
  
  # First determine the city and trim city shapefile and project coverage to the city
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  trimmed <- intersect(w_program, city)
  
  if (is.null(trimmed) == TRUE) {
    
    tbl <- setNames(data.table(matrix(nrow = 0, ncol = 7)), f_nms)
    
  } else {
    
    tbl <- setDT(trimmed@data)
    tbl <- tbl[,..o_nms]
    setnames(tbl,f_nms)
    tbl <- tbl[!duplicated(tbl), ]
  }
  
  return(tbl)
  
}

create_tmc_table <- function(w_tbl, w_place, o_nms, f_nms, w_hr, w_yr, w_mo) {
  
  # Subset for the Hour, Year and Month Selected and join to full shoefile
  current_tbl <- w_tbl[year %in% w_yr & hour %in% w_hr & month %in% w_mo]

  # Determine the city and trim city shapefile and TMC coverage to the city
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  trimmed <- intersect(tmc.shape, city)
  trimmed  <- sp::merge(trimmed, current_tbl, by = "Tmc")  
  
  if (is.null(trimmed) == TRUE) {
    
    tbl <- setNames(data.table(matrix(nrow = 0, ncol = 8)), f_nms)
    
  } else {
    
    tbl <- setDT(trimmed@data)
    tbl <- tbl[,..o_nms]
    
    # Add a Congestion Columne
    tbl$congestion <- "Minimal"
    tbl$congestion[tbl$ratio < 0.25] <- "Severe"
    tbl$congestion[tbl$ratio >= 0.25 & tbl$ratio < 0.50] <- "Heavy"
    tbl$congestion[tbl$ratio >= 0.50 & tbl$ratio < 0.70] <- "Moderate"
    
    setnames(tbl,f_nms)
    tbl <- tbl[!duplicated(tbl), ]
  }
  
  return(tbl)
  
}

create_tmc_congestion_table <- function(w_tbl, w_place, o_nms, f_nms, w_hr, w_yr, w_mo) {
  
  # Subset for the Hour, Year and Month Selected and join to full shoefile
  current_tbl <- w_tbl[year %in% w_yr & hour %in% w_hr & month %in% w_mo]
  
  # Determine the city and trim city shapefile and TMC coverage to the city
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  trimmed <- intersect(tmc.shape, city)
  trimmed  <- sp::merge(trimmed, current_tbl, by = "Tmc")  
  
  if (is.null(trimmed) == TRUE) {
    
    tbl <- setNames(data.table(matrix(nrow = 0, ncol = 8)), f_nms)
    
  } else {
    
    tbl <- setDT(trimmed@data)
    tbl <- tbl[,..o_nms]
    
    # Add a Congestion Columne
    tbl$congestion <- "Minimal"
    tbl$congestion[tbl$ratio < 0.25] <- "Severe"
    tbl$congestion[tbl$ratio >= 0.25 & tbl$ratio < 0.50] <- "Heavy"
    tbl$congestion[tbl$ratio >= 0.50 & tbl$ratio < 0.70] <- "Moderate"
    
    setnames(tbl,f_nms)
    tbl <- tbl[!duplicated(tbl), ]
  }
  
  num_tmc <- nrow(tbl)
  num_moderate <- sum(tbl$`Congestion Level` == "Moderate")
  num_heavy <- sum(tbl$`Congestion Level` == "Heavy")
  num_severe <- sum(tbl$`Congestion Level` == "Severe")
  
  cong_nms <- c("Moderate","Heavy","Severe")
  count_by_type <- c(num_moderate,num_heavy,num_severe)
  
  f_tbl <- data.table(`Congestion Level`=cong_nms, `Segments`=count_by_type)
  f_tbl$Share <- f_tbl$Segments / num_tmc
  
  # Set the order of the table using factors
  f_order <- c("Moderate","Heavy","Severe")
  f_tbl$`Congestion Level` <- factor(f_tbl$`Congestion Level`, levels = f_order)
  f_tbl <- f_tbl[order(`Congestion Level`),]
  f_tbl$Place <- w_place
  
  return(f_tbl)
  
}

create_congestion_map <- function(w_place, w_hr, w_yr, w_mo) {
  
  # Subset for the Hour, Year and Month Selected and join to full shoefile
  current_tbl <- tmc.ratios[year %in% w_yr & hour %in% w_hr & month %in% w_mo]
  
  # Determine the city and trim city shapefile and TMC coverage to the city
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  trimmed <- intersect(tmc.shape, city)
  trimmed  <- sp::merge(trimmed, current_tbl, by = "Tmc") 
  
  if (is.null(trimmed) == TRUE) {
    
    working_map <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(baseGroups = c("Base Map"),
                       overlayGroups = c("Moderate Congestion","Heavy Congestion","Severe Congestion","City Boundary"),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      addPolygons(data = city,
                  fillColor = "76787A",
                  weight = 1,
                  opacity = 1.0,
                  color = "#444444",
                  fillOpacity = 0.10,
                  group = "City Boundary")%>%
      setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
    
  } else {
    
    moderate <- trimmed[which(trimmed$ratio >= 0.50 & trimmed$ratio < 0.70),]
    heavy <- trimmed[which(trimmed$ratio >= 0.25 & trimmed$ratio < 0.50),]
    severe <- trimmed[which(trimmed$ratio < 0.25),]
    
    moderate_labels <- moderate_labels <- paste0("<b> <br>","Speed Ratio: ", "</b>", prettyNum(round((moderate$ratio)*100, 0), big.mark = ","),"%") %>% lapply(htmltools::HTML)
    heavy_labels <- paste0("<b> <br>","Speed Ratio: ", "</b>", prettyNum(round((heavy$ratio)*100, 0), big.mark = ","),"%") %>% lapply(htmltools::HTML)    
    severe_labels <- paste0("<b> <br>","Speed Ratio: ", "</b>", prettyNum(round((severe$ratio)*100, 0), big.mark = ","),"%") %>% lapply(htmltools::HTML)
    
    # Create Map
    working_map <- leaflet() %>% 
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(baseGroups = c("Base Map"),
                       overlayGroups = c("Moderate Congestion","Heavy Congestion","Severe Congestion","City Boundary"),
                       options = layersControlOptions(collapsed = FALSE)) %>%
      addPolygons(data = city,
                  fillColor = "76787A",
                  weight = 4,
                  opacity = 1.0,
                  color = "#91268F",
                  dashArray = "4",
                  fillOpacity = 0.0,
                  group = "City Boundary")%>% 
      addPolylines(data = moderate,
                   color = "orange",
                   weight = 4,
                   label = moderate_labels,
                   fillColor = "orange",
                   group = "Moderate Congestion") %>%
      addPolylines(data = heavy,
                   color = "red",
                   weight = 4,
                   label = heavy_labels,
                   fillColor = "red",
                   group = "Heavy Congestion") %>%
      addPolylines(data = severe,
                   color = "black",
                   weight = 4,
                   label = severe_labels,
                   fillColor = "black",
                   group = "Severe Congestion") %>%
      
      setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
  }
  
  return(working_map)
  
}

create_tract_map_pick_variable <- function(w_tbl, w_var, w_yr, w_color, w_place, w_type, w_var_type, w_title, w_pre, w_suff) {
  
  # Trim full Tract table to Variable and Year of interest
  current_tbl <- w_tbl[year %in% w_yr & get(w_var_type) %in% w_var]
  cols <- c("geoid",w_type)
  current_tbl <- current_tbl[,..cols]
  setnames(current_tbl,c("geoid","value"))
  current_tbl$value[current_tbl$value <= 0] <- 0
  
  # Trim Tracts for current place
  city <- community.shape[which(community.shape$NAME %in% w_place),]
  interim <- intersect(tract.shape, city)
  tract_ids <- unique(interim$GEOID10)
  
  tracts.trimmed <- tract.shape[which(tract.shape$GEOID10 %in% tract_ids),]
  current_value  <- sp::merge(tracts.trimmed, current_tbl, by.x = "GEOID10", by.y = "geoid")
  
  # Determine Bins
  rng <- range(current_value$value)
  max_bin <- max(abs(rng))
  round_to <- 10^floor(log10(max_bin))
  max_bin <- ceiling(max_bin/round_to)*round_to
  breaks <- (max_bin*c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1))
  bins <- c(0, breaks)
  
  pal <- colorBin(w_color, domain = current_value$value, bins = bins)
  
  labels <- paste0("<b>",paste0(w_title,": "), "</b>", w_pre, prettyNum(round(current_value$value, 1), big.mark = ","),w_suff) %>% lapply(htmltools::HTML)
  
  # Create Map
  working_map <- leaflet(data = current_value, options = leafletOptions(zoomControl=FALSE)) %>% 
    addProviderTiles(providers$CartoDB.Positron) %>%
    addLayersControl(baseGroups = c("Base Map"),
                     overlayGroups = c("Census Tracts","City Boundary"),
                     options = layersControlOptions(collapsed = FALSE)) %>%
    addPolygons(data = city,
                fillColor = "76787A",
                weight = 4,
                opacity = 1.0,
                color = "#91268F",
                dashArray = "4",
                fillOpacity = 0.0,
                group = "City Boundary")%>% 
    addPolygons(fillColor = pal(current_value$value),
                weight = 1.0,
                opacity = 1,
                color = "white",
                dashArray = "3",
                fillOpacity = 0.7,
                highlight = highlightOptions(
                  weight =5,
                  color = "76787A",
                  dashArray ="",
                  fillOpacity = 0.7,
                  bringToFront = TRUE),
                label = labels,
                labelOptions = labelOptions(
                  style = list("font-weight" = "normal", padding = "3px 8px"),
                  textsize = "15px",
                  direction = "auto"),
                group = "Census Tracts")%>%
    addLegend("bottomright", pal=pal, values = current_value$value,
              title = paste0(w_title),
              labFormat = labelFormat(prefix = w_pre, suffix = w_suff),
              opacity = 1) %>%
    setView(lng=find_place_data(w_place,"INTPTLON"), lat=find_place_data(w_place,"INTPTLAT"), zoom=find_place_data(w_place,"ZOOM"))
  
  return(working_map)
  
}