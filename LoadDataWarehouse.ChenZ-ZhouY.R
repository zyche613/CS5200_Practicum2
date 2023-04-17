# CS5200 2023 Spring
# Authors: Zhengyuan Chen & Yi Zhou
# Date: 2023-04-16


library(RMySQL)
library(RMySQL)

# Question 1. Create a new R Script for Part 2


# Question 2. Create a MySQL database using either a local or a cloud MySQL instance

# Connect to the MySQL database
db_user <- 'root'
db_password <- 'password'
db_name <- 'p2_db'
db_host <- 'localhost' 
db_port <- 3306

# db connection
mydb <-  dbConnect(RMySQL::MySQL(), user = db_user, password = db_password, host = db_host, port = db_port)
dbSendQuery(mydb, paste("DROP database IF EXISTS ", db_name))
dbSendQuery(mydb, paste("CREATE database ", db_name))
mydb <-  dbConnect(RMySQL::MySQL(), user = db_user, password = db_password,
                   dbname = db_name, host = db_host, port = db_port)


# Question 3. Create and populate a star schema for journal facts

# Connect to the SQLite database
fpath = "./"
dbfile = "article.db"
litedb <- dbConnect(RSQLite::SQLite(), paste0(fpath, dbfile))

# Create the Journal Fact Table
dbExecute(mydb, "DROP TABLE IF EXISTS Journals;")
dbExecute(mydb, 
"CREATE TABLE Journals (
  journalID INTEGER PRIMARY KEY,
  journalTitle TEXT,
  ISSN TEXT,
  ISOAbbreviation TEXT,
  volume INTEGER,
  issue INTEGER,
  year INTEGER,
  month INTEGER,
  articleNumbers INTEGER,
  authoerNumbers INTEGER
)")

# Get Journal info from the SQLite database
journal_fact <- dbGetQuery(litedb, "
SELECT journalID, journalTitle, ISSN, ISOAbbreviation, volume, issue, year, month, 
COUNT(DISTINCT articleID), COUNT(DISTINCT authorID)
FROM Journals
NATURAL JOIN Articles
NATURAL JOIN ArticleAuthor
NATURAL JOIN Authors
GROUP BY journalID
")

# Write to MySQL database
dbSendQuery(mydb, "SET GLOBAL local_infile = true;")
dbWriteTable(mydb,"Journal", journal_fact, append=TRUE, row.names=FALSE)

# Your star schema must support analytical queries such as these:

# What the are number of articles published in every journal in 2012 and 2013?
res1 <- dbGetQuery(mydb, "SELECT journalID, journalTitle, SUM(articleNumbers) 
           FROM Journals
           WHERE year = 2012 OR year = 2013
           GROUP BY journalID
           ")
print(res1)

# What is the number of articles published in every journal in each quarter of 2012 through 2015?
res2 <- dbGetQuery(mydb, "SELECT journal_id, title, year, quarter, SUM(articles) AS number_of_articles
           FROM Journal
           WHERE year >= 1975 AND year <= 1979
           GROUP BY journal_id, title, year, quarter
           ")
print(res2)

# How many articles were published each quarter (across all years)?
res <- dbGetQuery(mydb, "SELECT quarter, SUM(articles) AS number_of_articles
           FROM Journal
           GROUP BY quarter
           ")
print(res3)

# How many unique authors published articles in each year for which there is data?
res4 <- dbGetQuery(mydb, "SELECT quarter, SUM(articles) AS number_of_articles
           FROM Journal
           GROUP BY quarter
           ")
print(res4)
  


