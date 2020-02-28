library(odbc)
library(DBI)
library(data.table)
library(stringr)
library(DT)
library(shiny)
library(shinyjs)
library(shinyBS)
library(ggplot2)
library(scales)
library(plotly)
library(foreign)
library(leaflet)
library(sp)
library(rgdal)
library(raster)
library(dplyr)
library(rgeos)

wrkdir <- "C:/coding/member-profiles/psrc-member-profiles"
inpdir <- "C:/coding/member-profiles/inputs"
tmcdir <- "C:/coding/member-profiles/npmrds"

source(file.path(wrkdir, 'functions.R'))

server_name <- "AWS-PROD-SQL\\COHO"
database_name <- "Elmer"

##################################################################################
##################################################################################
### Shapefiles
##################################################################################
##################################################################################

community.shape <- readOGR(dsn='c:/coding/member-profiles/shapefiles',layer='communities_wgs_1984',stringsAsFactors = FALSE)
community.shape$ZOOM <- as.integer(community.shape$ZOOM)
community.point <- setDT(community.shape@data)

tract.shape <- readOGR(dsn='c:/coding/member-profiles/shapefiles',layer='tract_2010_no_water_wgs1984',stringsAsFactors = FALSE)

rtp.url <- "https://services6.arcgis.com/GWxg6t7KXELn1thE/arcgis/rest/services/RTP/FeatureServer/0/query?where=0=0&outFields=*&f=pgeojson"
rtp.shape <- readOGR(dsn=rtp.url,stringsAsFactors = FALSE)
rtp.shape$ImprovementType <- " "

tip.url <- "https://services6.arcgis.com/GWxg6t7KXELn1thE/arcgis/rest/services/TIP_19_22/FeatureServer/0/query?where=0=0&outFields=*&f=pgeojson"
tip.shape <- readOGR(dsn=tip.url,stringsAsFactors = FALSE)
tip.shape$TotCost <- as.numeric(tip.shape$TotCost)
tip.shape$EstCompletionYear <- as.numeric(tip.shape$EstCompletionYear)
tip.shape$Status <- "2019-2022 TIP"

tmc.shape <- readOGR(dsn='c:/coding/member-profiles/shapefiles',layer='washington_wgs1984',stringsAsFactors = FALSE)

##################################################################################
##################################################################################
### Mode Share Information
##################################################################################
##################################################################################

ms_var <- "COMMUTING TO WORK"
ms_cols <- c("variable_description","estimate","margin_of_error")
ms_total <- c("Workers 16+")
ms_remove <- c("Mean Travel Time to Work")
ms_order <- c("Drove Alone", "Carpooled", "Transit", "Walked", "Other", "Telework")

numeric_ms <- c("estimate","margin_of_error")
percent_ms <- c("Share","Region")
mode_length <- 6

##################################################################################
##################################################################################
### Travel Time Information
##################################################################################
##################################################################################

tt_var <- "B08303"
tt_cols <- c("variable_description","estimate","margin_of_error")
tt_total <- c("Total")
tt_remove <- NULL
tt_order <- c("Less than 5 minutes", "5 to 9 minutes","10 to 14 minutes","15 to 19 minutes","20 to 24 minutes","25 to 29 minutes","30 to 34 minutes","35 to 39 minutes","40 to 44 minutes","45 to 59 minutes","60 to 89 minutes","90 or more minutes")

numeric_tt <- c("estimate","margin_of_error")
percent_tt <- c("Share","Region")
tt_length <- 6

##################################################################################
##################################################################################
### Projects and Funding Information
##################################################################################
##################################################################################

rtp_cols <- c("mtpid","Sponsor","Title","ImprovementType","CompletionYear","MTPStatus","TotalCost")
tip_cols <- c("ProjNo","PlaceShortName","ProjectTitle","ImproveType","EstCompletionYear","Status","TotCost")
final_nms <- c("ID","Sponsor","Title","Improvement Type","Project Completion","Project Status","Cost")

currency_rtp <- c("Cost")
proj_length <- 5

##################################################################################
##################################################################################
### TMC Information
##################################################################################
##################################################################################

orig_tmc <- c("Tmc","RoadName","FirstName","F_System","Direction","AADT","ratio")
final_tmc <- c("ID","Facility","Name","Functional Classification","Direction", "Daily Volume","Ratio of Posted Speed", "Congestion Level")

decimal_tmc <- c("Ratio of Posted Speed")
number_tmc <- c("Daily Volume")
tmc_length <- 5

# Colors for Bar Charts
congestion_colors <- c(
  "Moderate" = "orange",
  "Heavy" = "red",
  "Severe" = "black")

##################################################################################
##################################################################################
### Occupation, Industry and Income Information
##################################################################################
##################################################################################
occ_var <- "OCCUPATION"
occ_cols <- c("variable_description","estimate","margin_of_error")
occ_total <- c("Civilian employed population 16+")
occ_remove <- NULL
occ_order <- c("Construction, Natural Resources & Maintenance","Management, Business, Science & Arts", "Production, Transportation & Material Moving", "Sales & Office", "Service")

ind_var <- "INDUSTRY"
ind_cols <- c("variable_description","estimate","margin_of_error")
ind_total <- c("Civilian employed population 16+")
ind_remove <- NULL
ind_order <- c("Agriculture, forestry & mining", "Construction", "Education, Health Care & Social services", "Entertainment, Accommodations & Food services", "FIRES", "Information", "Manufacturing", "Other services", "Professional, Management & Administrative", "Public Administration", "Retail", "Transportation, Warehousing & Utilities","Wholesale")

inc_var <- c("DP03_0051","DP03_0052","DP03_0053","DP03_0054","DP03_0055","DP03_0056","DP03_0057","DP03_0058","DP03_0059","DP03_0060","DP03_0061")
inc_cols <- c("variable_description","estimate","margin_of_error")
inc_total <- c("Total households")
inc_remove <- NULL
inc_order <- c("< $10k","$10k to $15k","$15k to $25k","$25k to $35k","$35k to $50k","$50k to $75k","$75k to $100k","$100k to $150k","$150k to $200k","more than $200k")

numeric_jobs <- c("estimate","margin_of_error")
percent_jobs <- c("Share","Region")
job_length <- 10

##################################################################################
##################################################################################
### Housing Information
##################################################################################
##################################################################################

hs_var <- "UNITS IN STRUCTURE"
hs_cols <- c("variable_description","estimate","margin_of_error")
hs_total <- c("Total units")
hs_remove <- c("Boat, RV, Van etc.")
hs_order <- c("1-unit detached", "1-unit attached", "2 units", "3-4 units", "5-9 units", "10-19 units", "20+ units", "Mobile Home")

numeric_hs <- c("estimate","margin_of_error")
percent_hs <- c("Share","Region")
house_length <- 5

##################################################################################
##################################################################################
### Vehicle Availability Information
##################################################################################
##################################################################################

va_var <- "VEHICLES AVAILABLE"
va_cols <- c("variable_description","estimate","margin_of_error")
va_total <- c("Total units")
va_remove <- NULL
va_order <- c("0 Vehicles", "1 Vehicle", "2 Vehicles", "3+ Vehicles")

numeric_va <- c("estimate","margin_of_error")
percent_va <- c("Share","Region")
va_length <- 5

##################################################################################
##################################################################################
### Home Value Information
##################################################################################
##################################################################################

hv_var <- "VALUE"
hv_cols <- c("variable_description","estimate","margin_of_error")
hv_total <- c("Owner Occupied Units")
hv_remove <- c("Median Value")
hv_order <- c("< $50k", "$50k to $100k", "$100k to $150k", "$150k to $200k", "$200k to $300k", "$300k to $500k", "$500k to $1m", "more than $1m")

numeric_hv <- c("estimate","margin_of_error")
percent_hv <- c("Share","Region")
hv_length <- 5

##################################################################################
##################################################################################
### Rent Information
##################################################################################
##################################################################################

rent_var <- "GROSS RENT"
rent_cols <- c("variable_description","estimate","margin_of_error")
rent_total <- c("Occupied Rental Units")
rent_remove <- c("Median Rent", "No Rent Paid")
rent_order <- c("< $500", "$500 to $1000", "$1000 to $1500", "$1500 to $2000", "$2000 to $2500", "$2500 to $3000", "more than $3000")

numeric_rent <- c("estimate","margin_of_error")
percent_rent <- c("Share","Region")
rent_length <- 5

##################################################################################
##################################################################################
### Age Information
##################################################################################
##################################################################################

age_var <- c("DP05_0001","DP05_0005","DP05_0006","DP05_0007","DP05_0008","DP05_0009","DP05_0010","DP05_0011","DP05_0012","DP05_0013","DP05_0014","DP05_0015","DP05_0016","DP05_0017")
age_cols <- c("variable_description","estimate","margin_of_error")
age_total <- c("Total population")
age_remove <- NULL
age_order <- c("< 5yrs","5 to 10yrs","10 to 15yrs","15 to 20yrs","20 to 25yrs","25 to 35ys","35 to 45yrs","45 to 55yrs","55 to 60yrs","60 to 65yrs","65 to 75yrs","75 to 85yrs", "more than 85yrs")

numeric_age <- c("estimate","margin_of_error")
percent_age <- c("Share","Region")
age_length <- 5

##################################################################################
##################################################################################
### Race Information
##################################################################################
##################################################################################

race_var <- c("DP05_0063","DP05_0064","DP05_0065","DP05_0066","DP05_0067","DP05_0068","DP05_0069")
race_cols <- c("variable_description","estimate","margin_of_error")
race_total <- c("Total population")
race_remove <- NULL
race_order <- c("White ","Black or African American ","American Indian and Alaska Native ","Asian ","Native Hawaiian and Other Pacific Islander ","Some other race ")

numeric_race <- c("estimate","margin_of_error")
percent_race <- c("Share","Region")
race_length <- 5

##################################################################################
##################################################################################
### Database table items
##################################################################################
##################################################################################

geography_dim <- table_from_db(server_name,database_name,"census.geography_dim")
variable_dim <- table_from_db(server_name,database_name,"census.variable_dim")
variable_facts <- table_from_db(server_name,database_name,"census.variable_facts")

##################################################################################
##################################################################################
### Variable DIM cleanup until it is cleaned in the database
##################################################################################
##################################################################################
variables <- table_cleanup(variable_dim,c("variable_dim_id","census_year","census_table_code","census_product","name","category","variable_description"),c("variable_dim_id","year","census_table","census_product","variable_name","variable_category","variable_description"))

# Clean up Mode Names
variables$variable_description[variables$variable_name == "DP03_0018"] <- "Workers 16+"
variables$variable_description[variables$variable_name == "DP03_0019"] <- "Drove Alone"
variables$variable_description[variables$variable_name == "DP03_0020"] <- "Carpooled"
variables$variable_description[variables$variable_name == "DP03_0021"] <- "Transit"
variables$variable_description[variables$variable_name == "DP03_0022"] <- "Walked"
variables$variable_description[variables$variable_name == "DP03_0023"] <- "Other"
variables$variable_description[variables$variable_name == "DP03_0024"] <- "Telework"
variables$variable_description[variables$variable_name == "DP03_0025"] <- "Mean Travel Time to Work"

# Clean up Occupation Names
variables$variable_description[variables$variable_name == "DP03_0026"] <- "Civilian employed population 16+"
variables$variable_description[variables$variable_name == "DP03_0027"] <- "Management, Business, Science & Arts"
variables$variable_description[variables$variable_name == "DP03_0028"] <- "Service"
variables$variable_description[variables$variable_name == "DP03_0029"] <- "Sales & Office"
variables$variable_description[variables$variable_name == "DP03_0030"] <- "Construction, Natural Resources & Maintenance"
variables$variable_description[variables$variable_name == "DP03_0031"] <- "Production, Transportation & Material Moving"

# Clean up Industry Names
variables$variable_description[variables$variable_name == "DP03_0032"] <- "Civilian employed population 16+"
variables$variable_description[variables$variable_name == "DP03_0033"] <- "Agriculture, forestry & mining"
variables$variable_description[variables$variable_name == "DP03_0034"] <- "Construction"
variables$variable_description[variables$variable_name == "DP03_0035"] <- "Manufacturing"
variables$variable_description[variables$variable_name == "DP03_0036"] <- "Wholesale"
variables$variable_description[variables$variable_name == "DP03_0037"] <- "Retail"
variables$variable_description[variables$variable_name == "DP03_0038"] <- "Transportation, Warehousing & Utilities"
variables$variable_description[variables$variable_name == "DP03_0039"] <- "Information"
variables$variable_description[variables$variable_name == "DP03_0040"] <- "FIRES"
variables$variable_description[variables$variable_name == "DP03_0041"] <- "Professional, Management & Administrative"
variables$variable_description[variables$variable_name == "DP03_0042"] <- "Education, Health Care & Social services"
variables$variable_description[variables$variable_name == "DP03_0043"] <- "Entertainment, Accommodations & Food services"
variables$variable_description[variables$variable_name == "DP03_0044"] <- "Other services"
variables$variable_description[variables$variable_name == "DP03_0045"] <- "Public Administration"

# Clean up Income Levels
variables$variable_description[variables$variable_name == "DP03_0051"] <- "Total households"
variables$variable_description[variables$variable_name == "DP03_0052"] <- "< $10k"
variables$variable_description[variables$variable_name == "DP03_0053"] <- "$10k to $15k"
variables$variable_description[variables$variable_name == "DP03_0054"] <- "$15k to $25k"
variables$variable_description[variables$variable_name == "DP03_0055"] <- "$25k to $35k"
variables$variable_description[variables$variable_name == "DP03_0056"] <- "$35k to $50k"
variables$variable_description[variables$variable_name == "DP03_0057"] <- "$50k to $75k"
variables$variable_description[variables$variable_name == "DP03_0058"] <- "$75k to $100k"
variables$variable_description[variables$variable_name == "DP03_0059"] <- "$100k to $150k"
variables$variable_description[variables$variable_name == "DP03_0060"] <- "$150k to $200k"
variables$variable_description[variables$variable_name == "DP03_0061"] <- "more than $200k"

# Clean up Housing Units
variables$variable_description[variables$variable_name == "DP04_0006"] <- "Total units"
variables$variable_description[variables$variable_name == "DP04_0007"] <- "1-unit detached"
variables$variable_description[variables$variable_name == "DP04_0008"] <- "1-unit attached"
variables$variable_description[variables$variable_name == "DP04_0009"] <- "2 units"
variables$variable_description[variables$variable_name == "DP04_0010"] <- "3-4 units"
variables$variable_description[variables$variable_name == "DP04_0011"] <- "5-9 units"
variables$variable_description[variables$variable_name == "DP04_0012"] <- "10-19 units"
variables$variable_description[variables$variable_name == "DP04_0013"] <- "20+ units"
variables$variable_description[variables$variable_name == "DP04_0014"] <- "Mobile Home"
variables$variable_description[variables$variable_name == "DP04_0015"] <- "Boat, RV, Van etc."

# Clean up Vehicle Availability
variables$variable_description[variables$variable_name == "DP04_0057"] <- "Total units"
variables$variable_description[variables$variable_name == "DP04_0058"] <- "0 Vehicles"
variables$variable_description[variables$variable_name == "DP04_0059"] <- "1 Vehicle"
variables$variable_description[variables$variable_name == "DP04_0060"] <- "2 Vehicles"
variables$variable_description[variables$variable_name == "DP04_0061"] <- "3+ Vehicles"

# Clean up Home Value
variables$variable_description[variables$variable_name == "DP04_0080"] <- "Owner Occupied Units"
variables$variable_description[variables$variable_name == "DP04_0081"] <- "< $50k"
variables$variable_description[variables$variable_name == "DP04_0082"] <- "$50k to $100k"
variables$variable_description[variables$variable_name == "DP04_0083"] <- "$100k to $150k"
variables$variable_description[variables$variable_name == "DP04_0084"] <- "$150k to $200k"
variables$variable_description[variables$variable_name == "DP04_0085"] <- "$200k to $300k"
variables$variable_description[variables$variable_name == "DP04_0086"] <- "$300k to $500k"
variables$variable_description[variables$variable_name == "DP04_0087"] <- "$500k to $1m"
variables$variable_description[variables$variable_name == "DP04_0088"] <- "more than $1m"
variables$variable_description[variables$variable_name == "DP04_0089"] <- "Median Value"

# Clean up Retn Cost
variables$variable_description[variables$variable_name == "DP04_0126"] <- "Occupied Rental Units"
variables$variable_description[variables$variable_name == "DP04_0127"] <- "< $500"
variables$variable_description[variables$variable_name == "DP04_0128"] <- "$500 to $1000"
variables$variable_description[variables$variable_name == "DP04_0129"] <- "$1000 to $1500"
variables$variable_description[variables$variable_name == "DP04_0130"] <- "$1500 to $2000"
variables$variable_description[variables$variable_name == "DP04_0131"] <- "$2000 to $2500"
variables$variable_description[variables$variable_name == "DP04_0132"] <- "$2500 to $3000"
variables$variable_description[variables$variable_name == "DP04_0133"] <- "more than $3000"
variables$variable_description[variables$variable_name == "DP04_0134"] <- "Median Rent"
variables$variable_description[variables$variable_name == "DP04_0135"] <- "No Rent Paid"

# Clean up Age Groups
variables$variable_description[variables$variable_name == "DP05_0001"] <- "Total population"
variables$variable_description[variables$variable_name == "DP05_0005"] <- "< 5yrs"
variables$variable_description[variables$variable_name == "DP05_0006"] <- "5 to 10yrs"
variables$variable_description[variables$variable_name == "DP05_0007"] <- "10 to 15yrs"
variables$variable_description[variables$variable_name == "DP05_0008"] <- "15 to 20yrs"
variables$variable_description[variables$variable_name == "DP05_0009"] <- "20 to 25yrs"
variables$variable_description[variables$variable_name == "DP05_0010"] <- "25 to 35ys"
variables$variable_description[variables$variable_name == "DP05_0011"] <- "35 to 45yrs"
variables$variable_description[variables$variable_name == "DP05_0012"] <- "45 to 55yrs"
variables$variable_description[variables$variable_name == "DP05_0013"] <- "55 to 60yrs"
variables$variable_description[variables$variable_name == "DP05_0014"] <- "60 to 65yrs"
variables$variable_description[variables$variable_name == "DP05_0015"] <- "65 to 75yrs"
variables$variable_description[variables$variable_name == "DP05_0016"] <- "75 to 85yrs"
variables$variable_description[variables$variable_name == "DP05_0017"] <- "more than 85yrs"

# Clean up Race Descriptions
variables$variable_description[variables$variable_name == "DP05_0063"] <- "Total population"
variables$variable_description[variables$variable_name == "DP05_0064"] <- "White "
variables$variable_description[variables$variable_name == "DP05_0065"] <- "Black or African American "
variables$variable_description[variables$variable_name == "DP05_0066"] <- "American Indian and Alaska Native "
variables$variable_description[variables$variable_name == "DP05_0067"] <- "Asian "
variables$variable_description[variables$variable_name == "DP05_0068"] <- "Native Hawaiian and Other Pacific Islander "
variables$variable_description[variables$variable_name == "DP05_0069"] <- "Some other race "

# Clean up Disability Descriptions
variables$variable_description[variables$variable_name == "DP02_0073"] <- "< 18 with a disability"
variables$variable_description[variables$variable_name == "DP02_0075"] <- "18 to 65 with a disability"
variables$variable_description[variables$variable_name == "DP02_0077"] <- "over 65 with a disability"
variables$variable_description[variables$variable_name == "DP02_0071"] <- "All Ages with a disability"

##################################################################################
##################################################################################
### Geography DIM cleanup
##################################################################################
##################################################################################
geography <- table_cleanup(geography_dim,c("geography_dim_id","geoid","summary_level","name","place_type","state"),c("geography_dim_id","geoid","summary_level","place_name","place_type","place_state"))

# Add County to the name for the counties to avoid overlap with place names 
geography$place_name[geography$place_name == "King" & geography$place_type == "co "] <- "King County"
geography$place_name[geography$place_name == "Kitsap" & geography$place_type == "co "] <- "Kitsap County"
geography$place_name[geography$place_name == "Pierce" & geography$place_type == "co "] <- "Pierce County"
geography$place_name[geography$place_name == "Snohomish" & geography$place_type == "co "] <- "Snohomish County"

##################################################################################
##################################################################################
### Fully joined and cleaned census data table for analysis
##################################################################################
##################################################################################
census_data <- merge(variable_facts,variables, by="variable_dim_id")
census_data <- merge(census_data,geography, by="geography_dim_id")

# Clean up workspace
rm("geography_dim","variable_dim","variable_facts","geography","variables") 

##################################################################################
##################################################################################
### Cleaned place tables from Database used in App
##################################################################################
##################################################################################

# Trim data to Washington and Get a Clean list of places for analysis
wa_places <- census_data[place_state %in% "WA" & census_product %in% "5yr"]
wa_places$place_type <- str_trim(wa_places$place_type, "right")
wa_places <- wa_places[place_type %in% c("pl","co")]
only_places <- wa_places[place_type %in% c("pl")]

# Find Unique List of Modes
modes <- wa_places[variable_category %in% "COMMUTING TO WORK"]
modes <- modes[variable_description != "Workers 16+"]
modes <- modes[variable_description != "Mean Travel Time to Work"]

# Find Unique List of Disability Groups
disabled <- wa_places[variable_name %in% c("DP02_0073","DP02_0075","DP02_0077","DP02_0071")]
race <- wa_places[variable_name %in% c("DP05_0064","DP05_0065","DP05_0066","DP05_0067","DP05_0068","DP05_0069")]

data_years <- unique(wa_places$year)
data_places <- sort(unique(wa_places$place_name))
data_modes <- unique(modes$variable_description)
data_disability <- unique(disabled$variable_description)
data_race <- unique(race$variable_description)

##################################################################################
##################################################################################
### Cleaned tract table from Database used in App
##################################################################################
##################################################################################
cols_to_keep <- c("year","variable_name","variable_description","estimate","estimate_percent","geoid")
wa_tracts <- census_data[place_state %in% "WA" & census_product %in% "5yr" & place_type %in% "tr "]
all_tracts <- census_data[place_state %in% "WA" & census_product %in% "5yr" & place_type %in% "tr " & variable_category %in% "COMMUTING TO WORK"]

wa_tracts <- wa_tracts[,..cols_to_keep]
all_tracts <- all_tracts[,..cols_to_keep]
##################################################################################
##################################################################################
### Travel Time table items
##################################################################################
##################################################################################

tmc.ratios <- setDT(read.csv(file.path(tmcdir, 'tmc_cars.csv')))
tmc_nms <- c("Tmc","month","year","percentile","hour","ratio")
setnames(tmc.ratios,tmc_nms)

data_months <- as.character(unique(tmc.ratios$month))
data_hours <- as.character(unique(tmc.ratios$hour))
