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

# Import
# Save Raw and start from computer file
occ_download_prep() # preview the download request before sending to GBIF

plant_med = occ_download(pred("taxonKey", 2858200),
                         pred_within(med_basin_txt),
                         format = "SIMPLE_CSV")

occ_download_wait(plant_med) # check status

data_plant_med = occ_download_get(plant_med) %>%
  occ_download_import()

write.csv(data_plant_med, 
          here::here("data", "raw", "narcissus.csv"))

# Clean

# Save

