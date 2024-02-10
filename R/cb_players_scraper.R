library(tidyverse)
library(rvest)
library(purrr)

# Get the team page links from the club baseball website
l <- read_html("https://clubbaseball.org/league/teams/")
links <- l %>% html_elements(".folded-corner:nth-child(6)") %>% html_attr("href")
f_links <- paste0("https://clubbaseball.org", links)

# Read the pages and get the html
pages <- f_links %>% map(read_html)


# Gets the teams roster of players
f <- function(d) {
  dt <- d %>% html_element("table") %>% html_table()
  team <- d %>% html_element("h3") %>% html_text()
  team <- str_remove(team, " Roster")
  dt <- mutate(dt, Team=team)
  return(dt)
}
z <- map(pages, f)

# Fill the data frame with the values
og_df <- data.frame()
og_df <- z %>% reduce(rbind)

# Mutate the data frame by changing the data types and splitting the HT value
# Also removes the teams that did not have a roster for the 2024 season as of 01/27/24
# Also removes all players listed as firstName INACTIVE
clubRosters_2024 <- og_df %>% mutate(across(c("#", WT), as.numeric), Yr=as.factor(`Yr/Elig`),
                       feet = str_split_i(HT, pattern=" ", i=1), fname=str_split_i(Player, pattern=", ", i=2),
                       inches = str_split_i(HT, pattern=" ", i=2), lname=str_split_i(Player, pattern=", ", i=1),
                       Bats=as.factor(Bats), Throws=as.factor(Throws), League="Club",
                       city=str_split_i(Hometown, pattern=", ", i=1),
                       state=str_split_i(Hometown, pattern=", ", i=2)) %>% 
  select(!`Yr/Elig`) %>% filter(!Player=="No items available" & !is.na(inches) & !inches=="\"") %>% mutate(across(c(feet, inches), parse_number)) %>% 
  filter(inches<12 & feet < 8) %>%
  mutate(HT=inches+(feet*12)) %>% select(!inches & !feet & !Player & !Hometown) %>% filter(!grepl("INACTIVE", fname)) %>%
  relocate(c(fname, lname))

# Replace empty strings with NA
clubRosters_2024[clubRosters_2024==""]<-NA

# Write to file
write_csv(clubRosters_2024, file="clubBaseballPlayers_2024.csv")
