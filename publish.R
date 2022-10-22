library(RPostgreSQL)
library(dplyr)
library(jpeg)

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname = Sys.getenv("ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("ELEPHANT_SQL_USER"),
                 password = Sys.getenv("ELEPHANT_SQL_PASSWORD")
)

query2 <- '
SELECT * FROM "public"."DRAKOR"
'

data <- dbGetQuery(con, query2)

# Status Message
## Looking for the Latest Data to Make Status Message

data <- data %>% filter(date == max(date))

baris <- c(1:nrow(data))
terpilih <- sample(baris, 1)

dataSiap <- data %>%
  filter(Title == data$Title[terpilih], Description == data$Description[terpilih], Img == data$Img[terpilih])
  
# Hashtag
hashtag <- c("dramakorea","reviewdrama","koreandrama")

samp_word <- sample(hashtag, 1)

## Function for Capital Each Word
simpleCap <- function(x) {
  x <- tolower(x)
  s <- strsplit(x, " ")[[1]]
  paste(toupper(substring(s, 1,1)), substring(s, 2),
        sep="", collapse=" ")
}

# Build the status message
status_details <- paste0(
  "Title : ", simpleCap(dataSiap$Title[1]),
  "\n",
  simpleCap(dataSiap$Description[1]), "https://www.dramabeans.com/recaps/",
  "\n",
  "#", samp_word, " #recapsdrama #", paste(gsub(" ", "", simpleCap(dataSiap$Title), fixed = TRUE)))

# Download the image to a temporary location
# save to a temp file
file <- tempfile(fileext = ".jpeg")
download.file(dataSiap$Img[1], file, mode="auto")

## Provide alt-text description
alt_text <- paste0(simpleCap(dataSiap$Title[1]))

# Publish to Twitter
library(rtweet)

## Create Twitter token
drakor_token <- rtweet::rtweet_bot(
  api_key =    Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  api_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

# save the data
write.csv(data, file.path("data/cobasimpan.csv"))

## Post the image to Twitter
rtweet::post_tweet(
  status = status_details,
  media = file,
  media_alt_text = alt_text,
  token = drakor_token
)

query3 <- '
DROP TABLE IF EXISTS "DRAKOR"
'

dbExecute(con, query3)

on.exit(dbDisconnect(con))
