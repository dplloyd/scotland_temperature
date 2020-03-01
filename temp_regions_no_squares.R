# Visualising temperature changes in Scotland, 1884-2017
#My attempt at making a Scotland version of 
#https://www.r-bloggers.com/temperature-changes-in-germany-visualized-in-r/
#
#
# This version uses a mean air temperature for the whole of Scotland
# rather than gridded data. But those data are availble from CEDA!

library(ncdf4) # for reading the climate data
library(tidyverse) # for general data wrangling
library(sf) # maps
library(plotly) # for interactive map

#Climate data taken from:
#http://data.ceda.ac.uk/badc/ukmo-hadobs/data/insitu/MOHC/HadOBS/HadUK-Grid/v1.0.0.0/country/tas/ann/v20181126

# Get the climate data
ncin =   nc_open("tas_hadukgrid_uk_country_ann_188401-201812.nc")

print(ncin)

#Get the variables of interest
temp = ncvar_get(ncin,varid = "tas")
region = ncvar_get(ncin,varid = "geo_region")
time = ncvar_get(ncin,varid = "time")

#Some wrangling into a tibble. Not pretty.
tempt = temp %>% t() 
colnames(tempt) = region
tempt_tbl = tempt %>% as_tibble() 
tempscot = tempt_tbl$`Scotland                `
tempscot = as.tibble(tempscot)

#Add in a year
tempscot = tempscot %>% mutate(dateYear = seq(1:135)+1883) %>% rename(temperature = value)

#I following the original author's approach here. See link above for method. 
#Note the limited year range for setting reference temperature.
reference_temperature = 
  tempscot %>%  
  filter(dateYear >= 1971 & dateYear <= 2000)  %>% 
  summarise(reference_temperature = mean(temperature, na.rm = TRUE),
            reference_sd = sd(temperature, na.rm = TRUE)) %>% data.frame()
reference_temperature

deviation_temperature = 
  tempscot %>%
  mutate(refTemp = reference_temperature$reference_temperature,
         refSd = reference_temperature$reference_sd) %>% 
  mutate(deviation_mean = temperature - refTemp,
         deviation_sd = deviation_mean/refSd)


plot(deviation_temperature$deviation_sd)

#Now I want to create a choropleth map. Read in the Scotland shapefile
UK_shape = sf::read_sf("NUTS_Level_1_January_2018_Ultra_Generalised_Clipped_Boundaries_in_the_United_Kingdom/") 
scot_shape = UK_shape[11,] 

ggplot(scot_shape) + geom_sf()
#Source: Office for National Statistics licensed under the Open Government Licence v.3.0
#Contains OS data © Crown copyright and database right 2019

#For each row (year) of climate data, add the shape file
all_scot_data = merge(scot_shape,deviation_temperature)

#Check the earliest year
ggplot(all_scot_data[1,]) + geom_sf() + facet_wrap(facets = vars(dateYear))

#Choosing how many years to plot, and chopping out the Orkeny SHetland folk, as they
#can't render properly and add white space. Sorry guys!
tmp = all_scot_data[1:135,]

 myPlot = 
  ggplot(tmp,lwd =0) + geom_sf(aes(fill = deviation_sd), color = "white")+
  xlim(64000,400000) + ylim(550000,960000) +
  facet_wrap(vars(dateYear),nrow = 7 )+
    theme_void() +
  scale_fill_gradient2(low = "#176fb6",
                       mid = "#dfecf7",
                       high = "#cc1017",
                       name = "Std devs from mean air temperature") +
   labs(title = "Temperature Changes in Scotland, 1884 - 2018 \n",caption = "Data sources:
* Met Office; Hollis, D.; McCarthy, M.; Kendon, M.; Legg, T.; Simpson, I. (2018): 
HadUK-Grid gridded and regional average climate observations for the UK. Centre for Environmental 
Data Analysis, 29/02/2020. http://catalogue.ceda.ac.uk/uuid/4dc8450d889a491ebb20e724debe2dfb
* Office for National Statistics licensed under the Open Government Licence v.3.0 
* Contains OS data © Crown copyright and database right 2019
        
Notes:
Mean and standard deviation air temperature calculated on years 1971-2000.
With apologies to Shetland and Orkney." ) +
   theme(legend.position = "bottom",
         strip.background = element_blank(),
         strip.text.x = element_blank(),
         panel.spacing =  unit(0, "lines"),
         plot.caption = element_text(size=5,hjust= 0)) 


  
ggsave("Scotland_variation_of_temp_1884-2018",plot = myPlot,device = "pdf",dpi = "retina")
#ggsave("Scotland_variation_of_temp_1884-2018",plot = myPlot,device = "png",dpi = "retina")



# # try and animate. I got this working, changed something, and now I can't recover it. Left in case I return to this.
# animated_map = ggplot(tmp,aes(frame = dateYear)) +
#   geom_sf(aes(fill = deviation_sd), color = "white") +
#   theme_void() +
#   scale_fill_gradient2(low = "#176fb6",
#                        mid = "#dfecf7",
#                        high = "#cc1017") +
#   theme(legend.position = "none",
#         strip.background = element_blank(),
#         strip.text.x = element_blank())
# 
# 
# plotly(animated_map)



