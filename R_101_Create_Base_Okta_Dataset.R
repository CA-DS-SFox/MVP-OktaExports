
library(tidyverse)
library(here)
library(glue)

source('R_Include_Functions.R')

WRITE_DATA <- TRUE
FIRST_GOOD_FORMAT <- '2023-01-07'

# PURPOSE : Create the Base (first) extract of Okta data from new daily updates

# -------------------------------------------------------------------------
# make a list of the exported okta files from sarah spittle

dir_okta <- 'G:/.shortcut-targets-by-id/1R7BhFme3NwLx29xYiWhe6jDQr_2tZtm2/OKTA - Data Exports'

df_okta_daily_exports <- tibble(oktaexports = list.files(dir_okta)) %>% 
  mutate(filedate = word(oktaexports, 1, sep='_')) %>% 
  mutate(badformat = case_when(filedate < FIRST_GOOD_FORMAT ~ 1, T ~ 0)) %>% 
  filter(badformat == 0) %>% 
  identity()

# -------------------------------------------------------------------------
# get base file : Once ever only

base_file <- df_okta_daily_exports[1, c('oktaexports')] %>% as.character()
base_date <- df_okta_daily_exports[1, c('filedate')] %>% as.character()

df_okta_base <- fn_read_okta_export(paste0(dir_okta, '/', base_file), base_date)
df_tidy_base <- fn_okta_tidy(df_okta_base)

# colnames - schema
df_colnames <- tibble(variable = df_okta_base %>% colnames()) %>% 
  full_join(df_tidy_base %>% count(variable) %>% rename(tidy = n), by='variable')

df_colnames %>% print(n = 100)

df_tidy_base %>% glimpse()

# -------------------------------------------------------------------------

if (WRITE_DATA) {
  out_name = paste0(here('data'),'/', base_date,'_oktatidy.csv')  
  write_csv(df_tidy_base, out_name)
}
