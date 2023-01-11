# MVP-OktaExports
Process the daily Okta Exports

*See R_Tidy_Transforms_Toy.R for a complete Toy example demonstrating the daily process*

## Background
Sarah Spittle exports a daily flat csv file of advisers in Okta with various details (e.g. firstName, lastName, volunteer, etc). Processing considerations are ...
- variable names in the export have mixed case and spaces, we want better variable names.
- okta_id is the canonical identifier for an adviser, but a small handful of advisers have multiple entries in the data because they work across multiple offices, we want to collapse these into a single record.
- Some of the details change frequently, we want to keep a history of changes because they provide useful insights.
- As advisers leave they are removed from Okta, we want to keep a history of past advisers for a period of time.

One way to do this is to transform Sarahs file into a tidy/long format dataframe, identify changes and then merge these into a cumulative dataset. From this cumulative dataset multiple other datasets can be created on the fly - daily adviser name for use in RAP reporting for instance.

## Steps are -

1. Create base dataset - only needs to happen once (*R_101_Create_Base_Okta_Dataset.R*).
2. Daily : identify changes in todays export and merge those into the base dataset (*R_102_Create_Updated_Okta_Dataset.R*). 
3. Reporting : Create latest data for Adviser name by taking the most recent record for each okta_id/variable and exporting in the required format (*R_102_Create_Updated_Okta_Dataset.R*).
