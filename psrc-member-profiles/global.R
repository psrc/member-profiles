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
library(lubridate)
library(RODBC)

wrkdir <- "C:/coding/member-profiles/psrc-member-profiles"
inpdir <- "C:/coding/member-profiles/worker-flow"
tmcdir <- "C:/coding/member-profiles/npmrds"

source(file.path(wrkdir, 'functions.R'))

server_name <- "AWS-PROD-SQL\\COHO"
database_name <- "Elmer"

##################################################################################
##################################################################################
### Database table items
##################################################################################
##################################################################################

census_data <- stored_procedure_from_db(server_name,database_name,"exec census.census_data_for_member_profiles")

##################################################################################
##################################################################################
### Minor Cleanup to still be done in Elmer but here for now
##################################################################################
##################################################################################

census_data$place_type <- str_trim(census_data$place_type, "right")

# Add County to the name for the counties to avoid overlap with place names 
census_data$geog_name[census_data$geog_name == "King" & census_data$place_type == "co"] <- "King County"
census_data$geog_name[census_data$geog_name == "Kitsap" & census_data$place_type == "co"] <- "Kitsap County"
census_data$geog_name[census_data$geog_name == "Pierce" & census_data$place_type == "co"] <- "Pierce County"
census_data$geog_name[census_data$geog_name == "Snohomish" & census_data$place_type == "co"] <- "Snohomish County"

census_data$variable_description[census_data$variable_name == "DP04_0013"] <- "20+ Units"

final_tract_variables <- c("DP02_0071","DP02_0073","DP02_0075","DP02_0077",
                           "DP03_0019","DP03_0020","DP03_0021","DP03_0022","DP03_0023","DP03_0024", "DP03_0025",
                           "DP04_0058","DP04_0089","DP04_0134",
                           "DP05_0064","DP05_0065","DP05_0066","DP05_0067","DP05_0068","DP05_0069")

census_data$tract_data <- 0
census_data$tract_data[census_data$place_type %in% c("pl","co")] <- 1
census_data$tract_data[census_data$variable_name %in% final_tract_variables & census_data$place_type %in% c("tr")] <- 2
census_data <- census_data[tract_data >= 1]
census_data <- census_data[, !"tract_data"]

##################################################################################
##################################################################################
### Shapefiles
##################################################################################
##################################################################################

community.shape <- readOGR(dsn='c:/coding/member-profiles/shapefiles',layer='places_no_water_wgs1984',stringsAsFactors = FALSE)
community.shape$ZOOM <- as.integer(community.shape$ZOOM)
community.point <- setDT(community.shape@data)

tract.shape <- readOGR(dsn='c:/coding/member-profiles/shapefiles',layer='extended_tract_2010_no_water_wgs1984',stringsAsFactors = FALSE)

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

ms_var <- c("DP03_0018","DP03_0019","DP03_0020","DP03_0021","DP03_0022","DP03_0023","DP03_0024")
ms_cols <- c("variable_description","estimate","margin_of_error")
ms_total <- c("Workers 16+")
ms_remove <- NULL
ms_order <- c("Drove Alone", "Carpooled", "Transit", "Walked", "Other", "Telework")

numeric_ms <- c("estimate","margin_of_error")
percent_ms <- c("Share","Region")
mode_length <- 10

##################################################################################
##################################################################################
### Travel Time Information
##################################################################################
##################################################################################

tt_var <- c("B08303_001","B08303_002","B08303_003","B08303_004","B08303_005","B08303_006","B08303_007","B08303_008","B08303_009","B08303_010","B08303_011","B08303_012","B08303_013")
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

occ_var <- c("DP03_0026","DP03_0027","DP03_0028","DP03_0029","DP03_0030","DP03_0031")
occ_cols <- c("variable_description","estimate","margin_of_error")
occ_total <- c("Civilian Employed Population 16+")
occ_remove <- NULL
occ_order <- c("Construction, Natural Resources & Maintenance","Management, Business, Science & Arts", "Production, Transportation & Material Moving", "Sales & Office", "Service")

ind_var <- c("DP03_0032","DP03_0033","DP03_0034","DP03_0035","DP03_0036","DP03_0037","DP03_0038","DP03_0039","DP03_0040","DP03_0041","DP03_0042","DP03_0043","DP03_0044","DP03_0045")
ind_cols <- c("variable_description","estimate","margin_of_error")
ind_total <- c("Civilian Employed Population 16+")
ind_remove <- NULL
ind_order <- c("Agriculture, Forestry & Mining", "Construction", "Education, Health Care & Social Services", "Entertainment, Accommodations & Food Services", "FIRES", "Information", "Manufacturing", "Other Services", "Professional, Management & Administrative", "Public Administration", "Retail", "Transportation, Warehousing & Utilities","Wholesale")

inc_var <- c("DP03_0051","DP03_0052","DP03_0053","DP03_0054","DP03_0055","DP03_0056","DP03_0057","DP03_0058","DP03_0059","DP03_0060","DP03_0061")
inc_cols <- c("variable_description","estimate","margin_of_error")
inc_total <- c("Total Households")
inc_remove <- NULL
inc_order <- c("< $10k","$10k to $15k","$15k to $25k","$25k to $35k","$35k to $50k","$50k to $75k","$75k to $100k","$100k to $150k","$150k to $200k","More Than $200k")

numeric_jobs <- c("estimate","margin_of_error")
percent_jobs <- c("Share","Region")
job_length <- 10

##################################################################################
##################################################################################
### Housing Information
##################################################################################
##################################################################################

hs_var <- c("DP04_0006","DP04_0007","DP04_0008","DP04_0009","DP04_0010","DP04_0011","DP04_0012","DP04_0013","DP04_0014")
hs_cols <- c("variable_description","estimate","margin_of_error")
hs_total <- c("Total Units")
hs_remove <- NULL
hs_order <- c("1 Unit Detached", "1 Unit Attached", "2 Units", "3-4 Units", "5-9 Units", "10-19 Units", "20+ Units", "Mobile Home")

numeric_hs <- c("estimate","margin_of_error")
percent_hs <- c("Share","Region")
house_length <- 5

##################################################################################
##################################################################################
### Vehicle Availability Information
##################################################################################
##################################################################################

va_var <- c("DP04_0057","DP04_0058","DP04_0059","DP04_0060","DP04_0061")
va_cols <- c("variable_description","estimate","margin_of_error")
va_total <- c("Total Units")
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

hv_var <- c("DP04_0080","DP04_0081","DP04_0082","DP04_0083","DP04_0084","DP04_0085","DP04_0086","DP04_0087","DP04_0088")
hv_cols <- c("variable_description","estimate","margin_of_error")
hv_total <- c("Owner Occupied Units")
hv_remove <- NULL
hv_order <- c("< $50k", "$50k to $100k", "$100k to $150k", "$150k to $200k", "$200k to $300k", "$300k to $500k", "$500k to $1m", "More Than $1m")

numeric_hv <- c("estimate","margin_of_error")
percent_hv <- c("Share","Region")
hv_length <- 5

##################################################################################
##################################################################################
### Rent Information
##################################################################################
##################################################################################

rent_var <- c("DP04_0126","DP04_0127","DP04_0128","DP04_0129","DP04_0130","DP04_0131","DP04_0132","DP04_0133")
rent_cols <- c("variable_description","estimate","margin_of_error")
rent_total <- c("Occupied Rental Units")
rent_remove <- NULL
rent_order <- c("< $500", "$500 to $1000", "$1000 to $1500", "$1500 to $2000", "$2000 to $2500", "$2500 to $3000", "More Than $3000")

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
age_total <- c("Total Population")
age_remove <- NULL
age_order <- c("< 5yrs","5 to 10yrs","10 to 15yrs","15 to 20yrs","20 to 25yrs","25 to 35ys","35 to 45yrs","45 to 55yrs","55 to 60yrs","60 to 65yrs","65 to 75yrs","75 to 85yrs", "More Than 85yrs")

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
race_total <- c("Total Population")
race_remove <- NULL
race_order <- c("White","Black or African American","American Indian and Alaska Native","Asian","Native Hawaiian and Other Pacific Islander","Some Other Race")

numeric_race <- c("estimate","margin_of_error")
percent_race <- c("Share","Region")
race_length <- 5

##################################################################################
##################################################################################
### Disability Information
##################################################################################
##################################################################################

disability_var <- c("DP02_0071","DP02_0073","DP02_0075","DP02_0077")
disability_cols <- c("variable_description","estimate","margin_of_error")
disability_total <- c("Total Population")
disability_remove <- NULL
disability_order <- c("< 18 With a Disability","18 to 65 With a Disability","Over 65 With a Disability","All Ages With a Disability")

numeric_disability <- c("estimate","margin_of_error")
percent_disability <- c("Share","Region")
disability_length <- 5

##################################################################################
##################################################################################
### Dropdown Data creation
##################################################################################
##################################################################################

modes <- census_data[variable_name %in% c("DP03_0019","DP03_0020","DP03_0021","DP03_0022","DP03_0023","DP03_0024")]
disabled <- census_data[variable_name %in% c("DP02_0073","DP02_0075","DP02_0077","DP02_0071")]
race <- census_data[variable_name %in% c("DP05_0064","DP05_0065","DP05_0066","DP05_0067","DP05_0068","DP05_0069")]
places <- census_data[place_type %in% c("pl","co")]

data_years <- unique(census_data$census_year)
data_places <- sort(unique(places$geog_name))
data_modes <- unique(modes$variable_description)
data_disability <- unique(disabled$variable_description)
data_race <- unique(race$variable_description)

# Clean up R workspace
rm("modes","disabled","race","places") 

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
