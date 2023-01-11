
library(tidyverse)

# PURPOSE : Demonstrate the cumulative format I want to use for Okta data (tidy/long)
#           Show how daily updates which represent changes are to be processed
#           order of the transforms is important, so new and removed have to be first

# this is the state of the cumulative data today
x_current <- tribble(~okta_id,	~date_extract,	~variable,	~data,
              "00uyf9p2g4nMWrbAv0i6",	"2023-01-06",	"username",	"tahirad@lca.citizensadvice.org.uk",
              "00uyf9p2g4nMWrbAv0i6",	"2023-01-06",	"status",	"SUSPENDED",
              "00uyf9p2g4nMWrbAv0i6",	"2023-01-07",	"status",	"REMOVED",
              "00uyf9p2g4nMWrbAv0i7",	"2023-01-06",	"username",	"fox@lca.citizensadvice.org.uk",
              "00uyf9p2g4nMWrbAv0i7",	"2023-01-06",	"status",	"SUSPENDED",
              "00uyf9p2g4nMWrbAv0i8",	"2023-01-06",	"username",	"fox2@lca.citizensadvice.org.uk",
              "00uyf9p2g4nMWrbAv0i8",	"2023-01-06",	"status",	"ACTIVE",
              "00uyf9p2g4nMWrbAv0i8",	"2023-01-06",	"lastName",	"Smith")

# this is the new export
# - 00uyf9p2g4nMWrbAv0i9 : is new
# - 00uyf9p2g4nMWrbAv0i7 : was exported yesterday, but not today, so we need to generate a "ROMOVED" record
# - 00uyf9p2g4nMWrbAv0i8 : Status and last name have changed since yesterday
x_export <- tribble(~okta_id,	~date_extract,	~variable,	~data,
              "00uyf9p2g4nMWrbAv0i8",	"2023-01-08",	"username",	"fox2@lca.citizensadvice.org.uk",
              "00uyf9p2g4nMWrbAv0i8",	"2023-01-08",	"status",	"SUSPENDED",
              "00uyf9p2g4nMWrbAv0i8",	"2023-01-06",	"lastName",	"Smith-Windsor",
              "00uyf9p2g4nMWrbAv0i9",	"2023-01-08",	"username",	"fox@lca.citizensadvice.org.uk",
              "00uyf9p2g4nMWrbAv0i9",	"2023-01-08",	"status",	"ACTIVE")

# Output required for updated cumulative dataset
# okta_id              date_extract variable data                             
# <chr>                <chr>        <chr>    <chr>                            
# 00uyf9p2g4nMWrbAv0i6 2023-01-07   status   REMOVED                          
# 00uyf9p2g4nMWrbAv0i6 2023-01-06   status   SUSPENDED                        
# 00uyf9p2g4nMWrbAv0i6 2023-01-06   username tahirad@lca.citizensadvice.org.uk
# 00uyf9p2g4nMWrbAv0i7 2023-01-08   status   REMOVED                          
# 00uyf9p2g4nMWrbAv0i7 2023-01-06   status   SUSPENDED                        
# 00uyf9p2g4nMWrbAv0i7 2023-01-06   username fox@lca.citizensadvice.org.uk    
# 00uyf9p2g4nMWrbAv0i8 2023-01-08   lastName Smith-Windsor                    
# 00uyf9p2g4nMWrbAv0i8 2023-01-06   lastName Smith                            
# 00uyf9p2g4nMWrbAv0i8 2023-01-08   status   SUSPENDED                        
# 00uyf9p2g4nMWrbAv0i8 2023-01-06   status   ACTIVE                           
# 00uyf9p2g4nMWrbAv0i8 2023-01-06   username fox2@lca.citizensadvice.org.uk   
# 00uyf9p2g4nMWrbAv0i9 2023-01-08   status   ACTIVE                           
# 00uyf9p2g4nMWrbAv0i9 2023-01-08   username fox@lca.citizensadvice.org.uk  

# -------------------------------------------------------------------------
# 1. New okta_id added - identify new okta_ids and update current 
x_new <- x_export %>% 
  filter(!okta_id %in% x_current$okta_id)

x_current_update <- x_current %>% bind_rows(x_new)

# -------------------------------------------------------------------------
# 2. okta_id removed from system - identify okta_ids in current not REMOVED, no longer in export
#    give them a ROMOVED status and update current

# already removed
x_current_removed <- x_current_update %>% filter(variable == 'status' & data == 'REMOVED')

# newly removed from this export
x_new_removed <- x_current_update %>% 
  distinct(okta_id) %>% 
  filter(!okta_id %in% x_current_removed$okta_id) %>% 
  filter(!okta_id %in% x_export$okta_id) %>% 
  mutate(date_extract = max(x_export$date_extract),
         variable = 'status',
         data = 'REMOVED')

x_current_update <- x_current_update %>% bind_rows(x_new_removed) 

# -------------------------------------------------------------------------
# 3. identify changed variables, update current

x_variable_updates <- x_export %>% 
  select(-date_extract) %>% 
  anti_join(x_current_update %>% select(-date_extract), by=c('okta_id','variable','data'), drop = FALSE) %>% 
  mutate(date_extract = max(x_export$date_extract))

x_current_update <- x_current_update %>% bind_rows(x_variable_updates) 

# -------------------------------------------------------------------------
# 4. create new current dataset which reflects todays changes

x_current <- x_current_update %>% 
  arrange(okta_id, variable, desc(date_extract))

