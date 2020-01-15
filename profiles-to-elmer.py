# Load the libraries we need
import pandas as pd
import urllib
import time
import os
import geopandas as gp
import zipfile
import getpass 
import shutil
import glob 
import sqlalchemy
import sys
import ast

start_of_production = time.time()

working_directory = os.getcwd()
output_directory = os.path.join(working_directory,'output')
temp_path = os.path.join('c:\\Users',getpass.getuser(),'Downloads')

# Create the output directory for the trip generation results
if not os.path.exists(output_directory):
    os.makedirs(output_directory)

# This option will supress the warning message on possbile copy issues - confirmed it is working as desired so turning it off
pd.set_option('chained_assignment',None)

# Get the lookup passed from the system argument
acs_data = ast.literal_eval(sys.argv[1])
analysis_years = ast.literal_eval(sys.argv[2])
api_key = sys.argv[3]
data_tables = ast.literal_eval(sys.argv[4])

def download_census_shapes(working_url,working_zip):
    
    with urllib.request.urlopen(working_url) as response, open(working_zip, 'wb') as out_file:
        shutil.copyfileobj(response, out_file)

    # Uncompress the Shapefile for use in the analysis and remove the zipfile
    working_archive = zipfile.ZipFile(working_zip, 'r')
    working_archive.extractall(temp_path)
    working_archive.close()
    os.remove(working_zip)

def get_data_profile(current_call,place_type,current_table):
    
    response = urllib.request.urlopen(current_call)
    census_data = response.read()
    working_df = pd.read_json(census_data)
    working_df = working_df.rename(columns=working_df.iloc[0]).drop(working_df.index[0])

    working_df = pd.melt(working_df, id_vars=['NAME','GEO_ID']) 

    # Clean up the data profiles to only include the estimate and margins of error
    working_df = working_df[~working_df['variable'].str.contains('EA')]
    working_df = working_df[~working_df['variable'].str.contains('MA')]
    working_df = working_df[~working_df['variable'].str.contains('PEA')]
    working_df = working_df[~working_df['variable'].str.contains('PMA')]
    working_df = working_df[working_df['variable'].str.contains(current_table)]
    
    working_df['place_type'] = place_type
    working_df['table'] = current_table
  
    return working_df

def spatial_join(target_shapefile,join_shapefile,keep_columns):
    
    # open join shapefile as a geodataframe
    join_layer = gp.GeoDataFrame.from_file(join_shapefile)
    target_layer = gp.GeoDataFrame.from_file(target_shapefile)
    
    # Create PSRC Flag in the Join Layer and trim down before joining
    join_layer['PSRC'] = 0
    join_layer.loc[(join_layer['COUNTYFP'] == '033')|(join_layer['COUNTYFP'] == '035')|(join_layer['COUNTYFP'] == '053')|(join_layer['COUNTYFP'] == '061'), 'PSRC'] = 1
    cols_to_keep = ['geometry','PSRC']
    join_layer = join_layer[cols_to_keep]
    
    # spatial join
    merged = gp.sjoin(target_layer, join_layer, how = "inner", op='intersects')
    merged = pd.DataFrame(merged)
    merged = merged[keep_columns]
    
    return merged

def SendToSQL(db_table_name,db_schema,df,db_server_instance,db_name,db_chunks,db_types):
	conn_string = 'mssql+pyodbc://{}/{}?trusted_connection=yes&driver=ODBC+Driver+17+for+SQL+Server'.format(db_server_instance, db_name)
	engine = sqlalchemy.create_engine(conn_string,fast_executemany=True)
	df.to_sql(db_table_name, con=engine, schema=db_schema, if_exists='replace',chunksize=db_chunks,dtype=db_types)

##################################################################################################
##################################################################################################    
#  Dictionary of output types from the dataprofiles
##################################################################################################
################################################################################################## 
api_outputs = {'E':'estimate',
               'M':'margin_of_error',
               'PE':'percent',
               'PM':'percent_margin_of_error'}

numeric_columns = ['estimate','margin_of_error','percent','percent_margin_of_error']

final_df = pd.DataFrame()

for acs_data_type in acs_data:

    for year in analysis_years:
    
        if acs_data_type == '1yr' :
            data_set = 'acs/acs1'
    
        elif acs_data_type == '5yr' :
            data_set = 'acs/acs5'
    
        all_profiles = pd.DataFrame()
        labels_df = pd.DataFrame()
        yearly_df = pd.DataFrame()

        ##################################################################################################
        ##################################################################################################    
        # Download the Census Shapefiles and create a lookup for places in Washington
        ##################################################################################################
        ##################################################################################################
        place_zip = temp_path + '\\tl_'+str(year)+'_53_place.zip'
        place_url = 'https://www2.census.gov/geo/tiger/TIGER'+str(year)+'/PLACE/tl_'+str(year)+'_53_place.zip'

        county_zip = temp_path + '\\tl_'+str(year)+'_53_cousub.zip'
        county_url = 'https://www2.census.gov/geo/tiger/TIGER'+str(year)+'/COUSUB/tl_'+str(year)+'_53_cousub.zip'

        print('Downloading the Census Place shapefile and uncompressing for year ' +year)
        download_census_shapes(place_url, place_zip)

        print('Downloading the Census County shapefile and uncompressing for year ' +year)
        download_census_shapes(county_url, county_zip)

        place_shapefile = os.path.join(temp_path,'tl_'+str(year)+'_53_place.shp')
        county_shapefile = os.path.join(temp_path,'tl_'+str(year)+'_53_cousub.shp')

        print('Creating a lookup of Place GEOIDs and a PSRC Flag')
        keep_columns = ['GEOID','PSRC']
        places = spatial_join(place_shapefile, county_shapefile, keep_columns)
        
        ##################################################################################################
        ##################################################################################################    
        # Download the List of all Variables with labels and only save those for Data Profiles
        ##################################################################################################
        ################################################################################################## 
        print('Downloading a list of all variables and labels for all available detailed tables for year '+year+' ACS '+ acs_data_type + ' data')
        variable_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + '/variables'
        response = urllib.request.urlopen(variable_api_call)
        census_data_variables = response.read()
        tables_df = pd.read_json(census_data_variables)
        tables_df = tables_df.rename(columns=tables_df.iloc[0]).drop(tables_df.index[0])
        tables_df  = tables_df.rename(columns={'name':'variable'})
        tables_df = tables_df.drop('concept',axis=1)

        print('Downloading a list of all variables and labels for all available data-profiles for year '+year+' ACS '+ acs_data_type + ' data')
        variable_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + '/profile/variables'
        response = urllib.request.urlopen(variable_api_call)
        census_data_variables = response.read()
        profiles_df = pd.read_json(census_data_variables)
        profiles_df = profiles_df.rename(columns=profiles_df.iloc[0]).drop(profiles_df.index[0])
        profiles_df  = profiles_df.rename(columns={'name':'variable'})
        profiles_df = profiles_df.drop('concept',axis=1)

        print('Combining the Profile and Detailed Table labels into one dataframe and Clean Up')
        labels_df = profiles_df.append(tables_df)

        # Clean up the labels dataframe so it only includes data profile labels for the estimate and removes Puerto Rico specific labels
        labels_df = labels_df[~labels_df['variable'].str.contains('PE')]
        labels_df = labels_df[~labels_df['variable'].str.contains('PR')]
        labels_df = labels_df[labels_df['label'].str.contains('Estimate')]       
        labels_df['variable'] = labels_df['variable'].str.replace('E','')
        labels_df = labels_df.sort_values(by='variable', ascending=True)
        labels_df = labels_df.reset_index()
        labels_df = labels_df.drop('index',axis=1)

        print('Cleaning up labels for year '+year+' ACS '+ acs_data_type + ' data')
        labels_df['category'] = ''
        labels_df['sub_category'] = ''
        labels_df['subject'] = ''
        labels_df['level'] = 0

        working = labels_df['label']

        for i in range (0, len(working)):
            current_subject = working[i].split("!!")
            subject_items = len(working[i].split("!!"))
            labels_df['level'][i] = str(subject_items - 2)
    
            if subject_items >2:
                sub_cat = subject_items-2
                labels_df['sub_category'][i] = current_subject[sub_cat]
    
            labels_df['subject'][i] = current_subject[-1]
            labels_df['category'][i] = (current_subject[1]).upper()

        labels_df = labels_df.drop('label',axis=1)

        ##################################################################################################
        ##################################################################################################    
        # Create a master dataframe of all profiles for all geographies
        ##################################################################################################
        ################################################################################################## 

        for tables in data_tables:
            print('Downloading '+tables+' for year '+year+' ACS '+ acs_data_type + ' data')    
            
            if tables[:2] == 'DP':
                current_profile = '/profile?get=group('+tables+')'
                
            else:
                current_profile = '?get=group('+tables+')'

            print('Downloading all Places in Washington')
            census_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + current_profile + '&' + 'for=place:*' +'&in=state:53' + '&key=' + api_key
            interim = get_data_profile(census_api_call,'pl',tables)
            interim['GEOID'] = interim.GEO_ID.str[9:]
            interim = pd.merge(interim,places,on='GEOID',suffixes=('_x','_y'),how='left')
            interim = interim[interim['PSRC'] == 1]
            
            if tables[:2] == 'DP':
                interim['var'] = interim.variable.str[:9]
                interim['typ'] = interim.variable.str[9:]
                
            else:
                interim['var'] = interim.variable.str[:10]
                interim['typ'] = interim.variable.str[10:]
        
            interim = interim.drop('variable',axis=1)
            interim = interim.drop('GEO_ID',axis=1)
            interim = interim.drop('PSRC',axis=1)
            interim['geography_level'] = '160'
            interim['state'] = 'WA'
            
            if all_profiles.empty:
                all_profiles = interim
            else:
                all_profiles = all_profiles.append(interim)

            print('Downloading the State of Washington')
            census_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + current_profile + '&' + 'for=state:53' + '&key=' + api_key
            interim = get_data_profile(census_api_call,'st',tables)
            interim['GEOID'] = interim.GEO_ID.str[9:]
 
            if tables[:2] == 'DP':
                interim['var'] = interim.variable.str[:9]
                interim['typ'] = interim.variable.str[9:]
                
            else:
                interim['var'] = interim.variable.str[:10]
                interim['typ'] = interim.variable.str[10:]
        
            interim = interim.drop('variable',axis=1)
            interim = interim.drop('GEO_ID',axis=1)
            interim['geography_level'] = '040'
            interim['state'] = 'WA'
            all_profiles = all_profiles.append(interim)  
        
            print('Downloading all Counties in PSRC Region')
            census_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + current_profile + '&' + 'for=county:033,035,053,061' +'&in=state:53' + '&key=' + api_key
            interim = get_data_profile(census_api_call,'co',tables)
            interim['GEOID'] = interim.GEO_ID.str[9:]
            
            if tables[:2] == 'DP':
                interim['var'] = interim.variable.str[:9]
                interim['typ'] = interim.variable.str[9:]
                
            else:
                interim['var'] = interim.variable.str[:10]
                interim['typ'] = interim.variable.str[10:]
        
            interim = interim.drop('variable',axis=1)
            interim = interim.drop('GEO_ID',axis=1)
            interim['geography_level'] = '050'
            interim['state'] = 'WA'
            all_profiles = all_profiles.append(interim)

            print('Downloading all MSAs in the nation')
            census_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + current_profile + '&for=metropolitan%20statistical%20area/micropolitan%20statistical%20area:*' + '&key=' + api_key
            interim = get_data_profile(census_api_call,'msa',tables) 
            interim['GEOID'] = interim.GEO_ID.str[9:]
            
            if tables[:2] == 'DP':
                interim['var'] = interim.variable.str[:9]
                interim['typ'] = interim.variable.str[9:]
                
            else:
                interim['var'] = interim.variable.str[:10]
                interim['typ'] = interim.variable.str[10:]
        
            interim = interim.drop('variable',axis=1)
            interim = interim.drop('GEO_ID',axis=1)
            interim['geography_level'] = '310'
            interim['state'] = interim['NAME']
            interim['state'] = interim['state'].str.replace(' Micro Area','')
            interim['state'] = interim['state'].str.replace(' Metro Area','')
            interim['state'] = interim.state.str[-2:]
            all_profiles = all_profiles.append(interim)

            # Only downloand and process census tracts if data is 5yr data
            if acs_data_type == '5yr':
            
                print('Downloading all Census Tracts in the PSRC Region')
                census_api_call = 'https://api.census.gov/data/' + str(year) + '/'+ data_set + current_profile + '&' + 'for=tract:*' +'&in=state:53' +'&in=county:033,035,053,061' + '&key=' + api_key
                interim = get_data_profile(census_api_call,'tr',tables)
                interim['GEOID'] = interim.GEO_ID.str[9:]
            
                if tables[:2] == 'DP':
                    interim['var'] = interim.variable.str[:9]
                    interim['typ'] = interim.variable.str[9:]
                
                else:
                    interim['var'] = interim.variable.str[:10]
                    interim['typ'] = interim.variable.str[10:]
        
                interim = interim.drop('variable',axis=1)
                interim = interim.drop('GEO_ID',axis=1)
                interim['geography_level'] = '140'
                interim['state'] = 'WA'
                all_profiles = all_profiles.append(interim)
            
        print('Removing extra text from Census Place Names')
        all_profiles.loc[all_profiles['NAME'].str.contains('CDP'), 'place_type'] = 'cdp'
        all_profiles['NAME'] = all_profiles['NAME'].str.replace(', Washington','')
        all_profiles['NAME'] = all_profiles['NAME'].str.replace(' city','')
        all_profiles['NAME'] = all_profiles['NAME'].str.replace(' town','')
        all_profiles['NAME'] = all_profiles['NAME'].str.replace(' County','')
        all_profiles['NAME'] = all_profiles['NAME'].str.replace(', WA Metro Area','')
        all_profiles.columns = all_profiles.columns.str.lower()
  
        # Create Clean Table format of Estimate and Margins of Error
        for key, value in api_outputs.items():

            if key=='E':
                yearly_df = all_profiles[all_profiles['typ'] == key]
                yearly_df = yearly_df.drop('typ',axis=1)
                yearly_df = yearly_df.rename(columns={'value':value})
        
            else:
                interim = all_profiles[all_profiles['typ'] == key]
                interim = interim.drop('typ',axis=1)
                interim  = interim.rename(columns={'value':value})
                yearly_df = pd.merge(yearly_df,interim,on=['name','place_type','geography_level','table','geoid','var','state'],suffixes=('_x','_y'),how='left')

        print('Removing any Duplicate Records from the Dataframe and adding labels for year '+year+' ACS '+ acs_data_type + ' data')
        yearly_df.drop_duplicates(keep = 'first', inplace = True)
        yearly_df = yearly_df.reset_index()
        yearly_df = pd.merge(yearly_df,labels_df,left_on='var',right_on='variable',suffixes=('_x','_y'),how='left')
        yearly_df['year'] = year
        yearly_df['census_type'] = acs_data_type

        print('Appending the yearly dataframes')
        if final_df.empty:
            final_df = yearly_df
        else:
            final_df = final_df.append(yearly_df)
        
        # Remove temporary census shapefiles
        for fl in glob.glob(temp_path + '\\tl_'+str(year)+'_53_*'):
            os.remove(fl)
    
print('Write to staging table in Elmer and removing temporary files')
final_df = final_df.drop('var',axis=1)
final_df = final_df.drop('index',axis=1)

# Remove  Puerto Rico and Micro Areas from the Final dataframe
final_df = final_df[~final_df['state'].str.contains('PR')]
final_df = final_df[~final_df['name'].str.contains('Micro Area')]
final_df['estimate'] = pd.to_numeric(final_df['estimate'])
final_df['margin_of_error'] = pd.to_numeric(final_df['margin_of_error'])
final_df['percent'] = pd.to_numeric(final_df['percent'])
final_df['percent_margin_of_error'] = pd.to_numeric(final_df['percent_margin_of_error'])
           
tbl_dtypes = {'year': sqlalchemy.types.INTEGER(),
             'level': sqlalchemy.types.INTEGER(),
             'geography': sqlalchemy.types.INTEGER(),
             'geoid': sqlalchemy.types.NUMERIC(),
             'name':sqlalchemy.types.VARCHAR(length=255),
             'place_type':sqlalchemy.types.VARCHAR(length=3),
             'table':sqlalchemy.types.VARCHAR(length=6),
             'state':sqlalchemy.types.VARCHAR(length=2),
             'variable':sqlalchemy.types.VARCHAR(length=10),
             'category':sqlalchemy.types.VARCHAR(length=100),
             'sub_category':sqlalchemy.types.VARCHAR(length=100),
             'subject':sqlalchemy.types.VARCHAR(length=100),
             'census_type':sqlalchemy.types.VARCHAR(length=10),
             'estimate': sqlalchemy.types.NUMERIC(scale=2,asdecimal=True),
             'margin_of_error': sqlalchemy.types.NUMERIC(scale=2,asdecimal=True),
             'percent': sqlalchemy.types.NUMERIC(scale=2,asdecimal=True),
             'percent_margin_of_error': sqlalchemy.types.NUMERIC(scale=2,asdecimal=True)
             }

SendToSQL('census_data','stg',final_df,'AWS-PROD-SQL\\Coho','Elmer',10000,tbl_dtypes)

end_of_production = time.time()
print ('The Total Time for all processes took', (end_of_production-start_of_production)/60, 'minutes to execute.')
