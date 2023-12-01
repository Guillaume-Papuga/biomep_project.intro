#######################################################
# Project : Introduction to Biomep
# Script : 02.import_data.R
# Import, clean and organize data
# Authors : Guillaume Papuga
# Last update : 27 november 2023
#######################################################


######################### A. Spatial data #############################################
### 1. Limits of the mediterranean basin following Quezel & Medail 2003
# Load the polygon
path_med = here::here ("map", "Quezel&Medail_2003_final.gpkg")
med_basin = st_read(path_med)
print(med_basin)
plot(med_basin)

# Simplify the polygon
med_basin_simpl = st_simplify(med_basin, 
                              #preserveTopology = FALSE, 
                              dTolerance = 1000)
plot(med_basin_simpl) # no visual difference


# Turn the polygon into a text file
med_basin_txt = sf::st_geometry(med_basin_simpl) %>% 
  sf::st_as_text()

# 2. Spatial grids to analyse biodiversity pattern





# 10km grid

# 50km grid

######################### B. Plant datasets ###########################################
### Study dataset
# Import
plant_med = occ_download(pred("taxonKey", 2858200),
                         #pred_lte("coordinateUncertaintyInMeters",1000), # key is less than/equal value
                         pred_in("datasetKey", c("7a3679ef-5582-4aaa-81f0-8c2545cafc81",  # plantnet
                                                 "50c9509d-22c7-4a22-a47d-8c48425ef4a7")),  # inaturalist
                         pred_gte("year", 2000), # set the starting year
                         pred_within(med_basin_txt), # lat-lon values within WKT polygon
                         pred("hasGeospatialIssue", FALSE), #   Remove default geospatial issues.
                         pred("hasCoordinate", TRUE), #   Keep only records with coordinates.
                         pred_gte("distanceFromCentroidInMeters","2000"), # filter out country/area centroids in a download
                         pred("occurrenceStatus","PRESENT"), #   Remove absent records.
                         pred_not(pred_in("basisOfRecord",c("FOSSIL_SPECIMEN"))), #   Remove fossils and living specimens
                         format = "SIMPLE_CSV")

occ_download_wait(plant_med) # check status
gbif_citation(occ_download_get(plant_med)) # get the correct GBIF citation of the dataset

# Cleaning pipeline
data_plant_med = plant_med %>%
  occ_download_get(overwrite=TRUE) %>% # GBIF get
  occ_download_import() %>% # GBIF import in R
  setNames(tolower(names(.))) %>% # set lowercase column names to work with CoordinateCleaner
  filter(occurrencestatus  == "PRESENT") %>% # delete ABSENCE data
  filter(taxonrank  == "SPECIES" | taxonrank  == "SUBSPECIES") %>% # delete GENUS & FAMILY data
  filter(coordinateuncertaintyinmeters < 2000 | is.na(coordinateuncertaintyinmeters)) %>% # keep low uncertainty (keep NA for now ???)
  cc_cen(buffer = 1000, lon = "decimallongitude", lat = "decimallatitude") %>% # remove country centroids within 2km 
  cc_cap(buffer = 1000, lon = "decimallongitude", lat = "decimallatitude") %>% # remove capitals centroids within 2km
  cc_inst(buffer = 1000, lon = "decimallongitude", lat = "decimallatitude") %>% # remove zoo and herbaria within 2km 
  distinct(decimallatitude, decimallongitude, specieskey, .keep_all = TRUE) # delete data if copied in the two datasets

# Select columns
data_plant_med = data_plant_med %>%
  mutate (datasource = recode(datasetkey, '7a3679ef-5582-4aaa-81f0-8c2545cafc81' = 'plantnet', '50c9509d-22c7-4a22-a47d-8c48425ef4a7' = 'inat')) %>% # highlight the two datasets
  select(gbifid, datasource, occurrenceid, # GBIF infos 
         family, genus, species, infraspecificepithet, taxonrank, scientificname, specieskey, # taxonomy // delete infraspe infos if too large
         decimallatitude, decimallongitude, coordinateuncertaintyinmeters, # localisation
         eventdate, day, month, year) # date

# Save
write.csv(data_plant_med, 
          here::here("data", "raw", "data_plant_med.csv"))

### Background dataset
# Select columns
data_raw = plant_med %>%
  occ_download_get(overwrite=TRUE) %>% # GBIF get
  occ_download_import() %>%
  setNames(tolower(names(.))) %>% # set lowercase column names to work with CoordinateCleaner
  mutate (datasource = recode(datasetkey, '7a3679ef-5582-4aaa-81f0-8c2545cafc81' = 'plantnet', '50c9509d-22c7-4a22-a47d-8c48425ef4a7' = 'inat')) %>% # highlight the two datasets
  select(gbifid, datasource, occurrenceid, # GBIF infos 
         family, genus, species, infraspecificepithet, taxonrank, scientificname, specieskey, # taxonomy // delete infraspe infos if too large
         decimallatitude, decimallongitude, coordinateuncertaintyinmeters, # localisation
         eventdate, day, month, year) # date

# Save
write.csv(data_raw, 
          here::here("data", "raw", "background_dataset.csv"))