library(RPostgreSQL)
library(rvest)
library(dplyr)
library(tidyverse)
library(jpeg)
library(lubridate)
library(data.table)

query <- '
CREATE TABLE IF NOT EXISTS DRAKOR (
  Date, 
  Title,
  Description,
  Img,
  PRIMARY KEY (Img)
)
'

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname = Sys.getenv("ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("ELEPHANT_SQL_USER"),
                 password = Sys.getenv("ELEPHANT_SQL_PASSWORD")
)

#Create table for 1st time
data <- dbGetQuery(con, query)

#Specifying the url for desired website to be scraped
url <- 'https://www.dramabeans.com/recaps/'

#Reading the HTML code from the website
webpage <- read_html(url)

#Using CSS selectors to scrape the date section
date_html <- html_nodes(webpage,'.published')

#Converting the date to text
date <- html_text(date_html)
date <- mdy(date)
date <- as.Date(date)
date1 <- as.data.table(date)

#Let's have a look at the date
head(date)

#Using CSS selectors to scrape the title section
title_html <- html_nodes(webpage,'.post-title-thumbnail')

#Converting the title to text
title <- html_text(title_html)

#Let's have a look at the title
head(title)

#Using CSS selectors to scrape the image section
img_html <- html_nodes(webpage,'.img-responsive')

#Converting the image to text
img <- img_html[5:14] %>% html_attr('src')

#Let's have a look at the runtime
head(img)

#Using CSS selectors to scrape the description section
des_html <- html_nodes(webpage,'.post-content')

#Converting the description to text
des <- des_html[2:11] %>% html_text(des_html)

#Let's have a look at the description
head(des)

#Data-Preprocessing
des_data <- gsub("\r\n\r\n","",des)

#Let's have another look at the description data
head(des_data)

query2 <- '
SELECT * FROM "public"."drakor"
'

data <- dbGetQuery(con, query2)

data <- data.frame(Date = date1,
                   Title = title,
                   Description = des_data,
                   Img = img)

dbWriteTable(conn = con, name = "DRAKOR", value = data, append = TRUE, row.names = FALSE, overwrite=FALSE)

on.exit(dbDisconnect(con)) 

