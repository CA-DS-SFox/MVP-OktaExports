# MVP-OktaExports
Process the daily Okta Exports

*See R_Tidy_Transforms_Toy.R for a complete Toy example demonstrating the daily process*

## Background
Sarah Spittle exports a daily flat csv file of advisers on the system with various detail about those advisers. Considerations are ...
- variable names in the export have mixed case and spaces, we want better variable names
- okta_id is the canonical identifier for an adviser, but a small handful of advisers have multiple entries in the data as they work across multiple offices, we want to collapse into a single record.
- Some of the details change frequently, we want to keep a history of changes.
- As advisers leave they are removed from Okta, we want to keep a history of past advisers for a period of time.

One way to do this is to transform Sarahs file into a tidy/long format dataframe, identify changes and then merge these into a cumulative dataset. From this data for use in RAP reporting can be extracted, but it also forms the basis for analysis by other domains.

## Steps are -

1. Create base dataset - only needs to happen once.
2. Daily : identify changes in todays export and merge those into the base dataset (*R_102_Create_Updated_Okta_Dataset.R*). 
3. Reporting : Create latest data by taking the most recent record for each okta_id/variable and exporting in the required format (*R_102_Create_Updated_Okta_Dataset.R*).
