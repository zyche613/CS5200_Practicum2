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
dbfile = "prac2.sqlite"
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
  quarter INTEGER,
  month INTEGER,
  day INTEGER,
  articleNumbers INTEGER,
  authorNumbers INTEGER,
  FOREIGN KEY (journalID) REFERENCES JournalDim (journalID)
)")

# Get Journal dimention from the SQLite database
journal_dim <- dbGetQuery(litedb, 
                          "SELECT journalID, journalTitle, ISSN, ISOAbbreviation
                          FROM journals
                          ")

# Get Journal dimention from the SQLite database
journal_fact <- dbGetQuery(litedb, "
SELECT journalIssueID, journalID, citedMedium, volume, issue, year,
quarter, month, day, COUNT(articleID) AS articleNumbers, SUM(authorNum) AS authorNumbers
FROM (SELECT journalIssueID, journalID, citedMedium, volume, issue, year, (CASE 
      WHEN month IN (1,2,3) THEN 1
      WHEN month IN (4,5,6) THEN 2
      WHEN month IN (7,8,9) THEN 3
      WHEN month IN (10,11,12) THEN 4
      ELSE 0
      END) AS quarter, month, day, articleID, COUNT(authorID) AS authorNum
      FROM JournalIssue
      NATURAL JOIN Articles
      NATURAL JOIN AuthorArticle
      NATURAL JOIN Authors
      GROUP BY articleID)
GROUP BY JournalIssueID
")

# print(journal_dim)
# print(journal_fact)

# Write to MySQL database
dbSendQuery(mydb, "SET GLOBAL local_infile = true;")
rownames(journal_dim) <- NULL
rownames(journal_fact) <- NULL
dbWriteTable(mydb,"JournalDim", journal_dim, append=TRUE, row.names=FALSE)
dbWriteTable(mydb,"JournalFact", journal_fact, append=TRUE, row.names=FALSE)

# factTab <- dbGetQuery(mydb, "SELECT * FROM journalFact LIMIT 20")
# print(factTab)
# factDim <- dbGetQuery(mydb, "SELECT * FROM journalDim LIMIT 20")
# print(factDim)


# Your star schema must support analytical queries such as these:

# What the are number of articles published in every journal in 2012 and 2013?
res1 <- dbGetQuery(mydb, "SELECT journalTitle, year, SUM(articleNumbers) 
           FROM JournalFact NATURAL JOIN JournalDim
           WHERE year = 2012 OR year = 2013
           GROUP BY journalTitle, year
           ")
print(res1)

# What is the number of articles published in every journal in each quarter of 2012 through 2015?
res2 <- dbGetQuery(mydb, "SELECT journalTitle, year, quarter, SUM(articleNumbers)
           FROM JournalFact NATURAL JOIN JournalDim
           WHERE year >= 2012 AND year <= 2015
           GROUP BY journalTitle, year, quarter
           ")
print(res2)

# How many articles were published each quarter (across all years)?
res3 <- dbGetQuery(mydb, "SELECT quarter, SUM(articleNumbers)
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
  
# Disconnect the MySQL database
killDbConnections <- function () {
  all_cons <- dbListConnections(MySQL())
  print(all_cons)
  for(con in all_cons)
    +  dbDisconnect(con)
  print(paste(length(all_cons), " connections killed."))
}
killDbConnections()

# Disconnect the SQLite database
if(dbIsValid(litedb)){
  dbDisconnect(litedb)
  print("DB has been disconncted!")
}
