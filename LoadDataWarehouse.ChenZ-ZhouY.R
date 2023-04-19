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
dbExecute(mydb, "DROP TABLE IF EXISTS JournalFact;")
dbExecute(mydb, "DROP TABLE IF EXISTS JournalDim;")
dbExecute(mydb, 
          "CREATE TABLE JournalDim (
  journalID INTEGER PRIMARY KEY,
  journalTitle TEXT,
  ISSN TEXT,
  ISOAbbreviation TEXT
)")
dbExecute(mydb, 
"CREATE TABLE JournalFact (
  journalIssueID INTEGER PRIMARY KEY,
  journalID INTEGER,
  citedMedium Text,
  volume INTEGER,
  issue INTEGER,
  year INTEGER,
  month INTEGER,
  articleNumbers INTEGER,
  authoerNumbers INTEGER，
  FOREIGN KEY (journalID) REFERENCES JournalDim (journalID)
)")

# Get Journal dimention from the SQLite database
journal_dim <- dbGetQuery(litedb, 
                          "SELECT *
                          FROM journals
                          ")

# Get Journal dimention from the SQLite database
journal_fact <- dbGetQuery(litedb, "
SELECT journalIssueID, journalID, citedMedium, volume, issue, year,
(CASE 
WHEN month IN (1,2,3) THEN 1
WHEN month IN (4,5,6) THEN 2
WHEN month IN (7,8,9) THEN 3
WHEN month IN (10,11,12) THEN 4
ELSE 0
END) AS quarter, month, day, COUNT(DISTINCT articleID), COUNT(DISTINCT authorID)
FROM JournalIssue
NATURAL JOIN Articles
NATURAL JOIN ArticleAuthor
NATURAL JOIN Authors
GROUP BY journalIssueID
")

# Write to MySQL database
dbSendQuery(mydb, "SET GLOBAL local_infile = true;")
dbWriteTable(mydb,"Journal", journal_fact, append=TRUE, row.names=FALSE)

# Your star schema must support analytical queries such as these:

# What the are number of articles published in every journal in 2012 and 2013?
res1 <- dbGetQuery(mydb, "SELECT journalTitle, year, SUM(articleNumbers) 
           FROM JournalFact NATURAL JOIN JournalDim
           WHERE year = 2012 OR year = 2013
           GROUP BY journalID, year
           ")
print(res1)

# What is the number of articles published in every journal in each quarter of 2012 through 2015?
res2 <- dbGetQuery(mydb, "SELECT journalTitle, year, quarter, SUM(articleNumbers)
           FROM JournalFact NATURAL JOIN JournalDim
           WHERE year >= 2012 AND year <= 2015
           GROUP BY journalID, year, quarter
           ")
print(res2)

# How many articles were published each quarter (across all years)?
res <- dbGetQuery(mydb, "SELECT quarter, SUM(articleNumbers)
           FROM JournalFact
           GROUP BY quarter
           ")
print(res3)

# How many unique authors published articles in each year for which there is data?
res4 <- dbGetQuery(mydb, "SELECT year, SUM(authorNumbers)
           FROM JournalFact
           GROUP BY year
           ")
print(res4)
  


