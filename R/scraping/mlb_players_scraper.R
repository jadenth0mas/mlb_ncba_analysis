library(tidyverse)
library(rvest)
library(purrr)

# Read ESPN site to get the link to the roster for every team
l <- read_html("https://www.espn.com/mlb/players")
links <- l %>% html_elements(".small-logos div a") %>% html_attr("href")
f_links <- paste0("https://www.espn.com", links)

# Go to every page and read the html
pages <- f_links %>% map(read_html)

# Column names to keep
cnames <- c("Name", "POS", "BAT", "THW", "Age", "HT", "WT", "Birth Place")

# Function to retrieve the tables from html d from read_html and add a team column
f <- function(d) {
  g  <- d %>% html_elements("table") %>% html_table()
  rost <- reduce(g, rbind) %>% select(all_of(cnames))
  team <- d %>% html_elements("#fittPageContainer .db") %>% html_text() 
  team <- paste(team, collapse=" ")
  rost <- mutate(rost, Team=team)
  return(rost)
}

# Do for every team roster page
z <- map(pages, f)

# Combine all of the teams into one dataframe and clean it creating fname, lname, state (country for international players)
#, city, and make height in inches
plays <- reduce(z, rbind) %>% rename(birth_place='Birth Place') %>% mutate(Name=gsub('[0-9]+', '', Name), THW=as.factor(THW), BAT=as.factor(BAT),
                                     WT=as.numeric(gsub(' lbs', '', WT)), feet = str_split_i(HT, pattern=" ", i=1),
                                     fname=str_split_i(Name, pattern=" ", i=1),
                                     lname=str_split_i(Name, pattern=" ", i=2),
                                     city=str_split_i(birth_place, pattern=", ", i=1),
                                     state=str_split_i(birth_place, pattern=", ", i=2),
                                     inches = str_split_i(HT, pattern=" ", i=2), across(c(feet, inches), parse_number),
                                     HT=(feet*12)+inches, League="MLB") %>% select(!feet & !inches & !Name & !birth_place) %>%
  relocate(c(fname, lname))
  
# Write new data frame to csv file
write_csv(plays, "mlbBaseballPlayers_2023.csv")
