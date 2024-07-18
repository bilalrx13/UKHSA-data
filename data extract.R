library(httr)
library(jsonlite)
library(dplyr)
library(readr)
library(stringr)

locations <- read_csv("locations.csv")


  base_url <- "https://directory.spineservices.nhs.uk/ORD/2-0-0/organisations/"
  all_data <- data.frame()
  
  for (i in 1:length(locations[[1]])){
    query_url <- paste0(base_url, locations[i,1])
    response <- GET(query_url)
    content <- content(response, "text", encoding = "UTF-8")
    json_data <- fromJSON(content, flatten = TRUE)
    
    
    temp_data <- data.frame(Name=json_data$Organisation$Name,
                            ID=json_data$Organisation$OrgId$extension,
                            postcode=str_replace_all(json_data$Organisation$GeoLoc$Location$PostCode, pattern=" ", repl="") )

    
    all_data <- bind_rows(all_data, temp_data)
  }
  
  all_data[ , 'latitude'] = NA
  all_data[ , 'longitude'] = NA

  
  base_url <- "https://api.postcodes.io/postcodes/"
  
  for (i in 1:length(locations[[1]])){
    tryCatch({
    query_url <- paste0(base_url, all_data$postcode[i])
    response <- GET(query_url)
    content <- content(response, "text", encoding = "UTF-8")
    json_data <- fromJSON(content, flatten = TRUE)
    
    
    all_data$longitude[i]=json_data$result$longitude
    all_data$latitude[i]=json_data$result$latitude
    }, error=function(e){})
  }
# Save the data to a CSV file
write.csv(all_data, "nhs_organisations.csv", row.names = FALSE)