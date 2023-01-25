
# read the csv data from Sarah Spittle

fn_read_okta_export <- function(file_export, file_date) {
  
  df_okta <- read_csv(file_export, col_types = cols(.default = 'c')) %>% 
    # regularise the variable names 
    janitor::clean_names() %>% 
    # there are 8 which have 2 entries as they work across 2 offices, collapse these into single records
    arrange(okta_id, office) %>% 
    group_by(okta_id) %>% 
    mutate(office = paste0(office, collapse='; ')) %>% 
    mutate(member_id = paste0(member_id, collapse='; ')) %>% 
    filter(row_number() == 1) %>% 
    ungroup() %>% 
    # add a variable to record extract date
    mutate(date_extract = file_date) %>% 
    # make an adviser name for reporting from first_name, last_name
    mutate(advisername = paste0(first_name,' ', last_name))
  
  return(df_okta)
}

fn_okta_tidy <- function(df_wide) {
  
  df_tidy <- df_wide %>% 
    pivot_longer(-c(okta_id, date_extract),
                 names_to = 'variable',
                 values_to = 'data')
}  
