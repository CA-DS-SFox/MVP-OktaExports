
library(tidyverse)
library(here)
library(glue)

source('R_Include_Functions.R')

WRITE_DATA <- TRUE
FIRST_GOOD_FORMAT <- '2023-01-07'

# PURPOSE : Update the previous Okta extract with todays new information
#           See R_Tidy_Transforms_Toy.R for logic

# -------------------------------------------------------------------------
# 1. Get last extraction date and latest data

df_okta_latest <- tibble(oktaexports = list.files(here('data'))) %>% 
  mutate(filedate = word(oktaexports, 1, sep='_')) %>% 
  mutate(filetype = word(oktaexports, 2, sep='_')) %>% 
  filter(filetype == 'oktatidy.csv') %>% 
  filter(filedate == max(filedate)) %>% 
  identity()

latest_date <- df_okta_latest$filedate
latest_file <- df_okta_latest$oktaexports

df_okta_current <- read_csv(paste0(here('data'), '/', latest_file),
                    col_types = cols(.default = 'c')) 

# -------------------------------------------------------------------------
# 2. Get list of new extract files since then

dir_okta <- 'G:/.shortcut-targets-by-id/1R7BhFme3NwLx29xYiWhe6jDQr_2tZtm2/OKTA - Data Exports'

df_okta_daily_exports <- tibble(oktaexports = list.files(dir_okta)) %>% 
  mutate(filedate = word(oktaexports, 1, sep='_')) %>% 
  filter(filedate > FIRST_GOOD_FORMAT) %>% 
  filter(filedate > latest_date) %>% 
  identity()

if (nrow(df_okta_daily_exports) == 0) stop(' ... No Exports to process')

# find the earliest unprocessed updates
update_date <- df_okta_daily_exports %>% filter(filedate == min(filedate)) %>% pull(filedate)
update_file <- df_okta_daily_exports %>% filter(filedate == min(filedate)) %>% pull(oktaexports)

# -------------------------------------------------------------------------
# 3. Update the current data with the oldest unprocessed export
#    This will replace the current file used in step 1, so each pass can only process 1 set of updates

print(glue('Processing files from ', update_date))

df_okta <- fn_read_okta_export(paste0(dir_okta, '/', update_file), update_date)
df_tidy <- fn_okta_tidy(df_okta)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# make a copy of the current df to update
df_okta_current_update <- df_okta_current

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3.1. New okta_id added - identify new okta_ids and update current 
df_update_new <- df_tidy %>% 
  filter(!okta_id %in% df_okta_current$okta_id)

df_okta_current_update <- df_okta_current_update %>% bind_rows(df_update_new)

change_new <- df_update_new %>% distinct(okta_id) %>% tally() %>% pull()
change_new_recs <- df_update_new %>% nrow()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3.2. okta_id removed from system - identify okta_ids in current not REMOVED, no longer in export
#      give them a ROMOVED status and update current

# already removed
df_current_removed <- df_okta_current_update %>% filter(variable == 'status' & data == 'REMOVED')

# newly removed from this export
df_new_removed <- df_okta_current_update %>% 
  distinct(okta_id) %>% 
  filter(!okta_id %in% df_current_removed$okta_id) %>% 
  filter(!okta_id %in% df_tidy$okta_id) %>% 
  mutate(date_extract = update_date,
         variable = 'status',
         data = 'REMOVED')

df_okta_current_update <- df_okta_current_update %>% bind_rows(df_new_removed) 

change_removed <- df_new_removed %>% distinct(okta_id) %>% tally() %>% pull()
change_removed_recs <- df_new_removed %>% nrow()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3.3. identify changed variables, update current

df_variable_updates <- df_tidy %>% 
  select(-date_extract) %>% 
  anti_join(df_okta_current_update %>% select(-date_extract), by=c('okta_id','variable','data'), drop = FALSE) %>% 
  mutate(date_extract = update_date)

df_okta_current_update <- df_okta_current_update %>% bind_rows(df_variable_updates) 

change_updated <- df_variable_updates %>% distinct(okta_id) %>% tally() %>% pull()
change_updated_recs <- df_variable_updates %>% nrow()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3.4. create new current dataset which reflects todays changes

df_okta_updated <- df_okta_current_update %>% 
  arrange(okta_id, variable, desc(date_extract))

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 3.5 Check totals

glue('START : Rows {nrow(df_okta_current)}, okta_ids {nrow(df_okta_current %>% distinct(okta_id))}')
glue('AFTER : Rows {nrow(df_okta_updated)}, okta_ids {nrow(df_okta_updated %>% distinct(okta_id))}')
glue('NEW : Rows {change_new_recs}, okta_ids {change_new}')
glue('ID REMOVED : Rows {change_removed_recs}, okta_ids {change_removed}')
glue('UPDATES : Rows {change_updated_recs}, okta_ids {change_updated}')
glue('NEW DF : {nrow(df_okta_current_update)}, CHECK {nrow(df_okta_current) + change_new_recs + change_removed_recs + change_updated_recs}')

# -------------------------------------------------------------------------
# 3.6 Extract useful datasets for analytics

get_var = 'advisername'

df_reporting_adviser <- df_okta_updated %>% 
  filter(variable == get_var) %>% 
  group_by(okta_id) %>% 
  filter(date_extract == max(date_extract)) %>% 
  ungroup() %>% 
  select(okta_id, date_extract, data) %>% 
  rename(!!get_var := data)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if (WRITE_DATA) {
  # write the updated data
  file_name <- glue(here('data'),'/{update_date}_oktatidy.csv')  
  print(glue(' ... Writing {file_name}'))
  write_csv(df_okta_updated, file_name)
  
  # write the adviser name data for reporting
  file_name <- glue(here('data'),'/reporting_oktaadvisers.csv')  
  print(glue(' ... Writing {file_name}'))
  write_csv(df_reporting_adviser, file_name)
  
}
