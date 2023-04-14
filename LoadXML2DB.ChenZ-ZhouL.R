## load library
# Package names
packages <- c("XML", "DBI", "RSQLite", "RCurl")

# Install packages not yet installed
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

# Packages loading
invisible(lapply(packages, library, character.only = TRUE))
library(XML)
library(DBI)
library(RSQLite)
library(RCurl)

# db setup
dbcon <- dbConnect(RSQLite::SQLite(), "")

# create db tables
author_schema <- SQL("CREATE TABLE Authors (
                   authorID INTEGER PRIMARY KEY,
                   lastName TEXT,
                   firstName TEXT,
                   Initials TEXT
                  )")

journal_schema <- SQL("CREATE TABLE Journals (
                    journalID INTEGER PRIMARY KEY,
                    journalTitle TEXT,
                    ISSN TEXT,
                    ISSOAbbreviation TEXT,
                    volume TEXT,
                    pubDate Date
                  )")

article_schema <- SQL("CREATE TABLE Articles (
                    pmid INTEGER PRIMARY KEY,
                    journalID INTEGER,
                    FOREIGN KEY (journalID) REFERENCES Journals (journalID)
                  )")

article_author_schema <- SQL("CREATE TABLE ArticleAuthor (
                           pmid INTEGER,
                           authorID INTEGER,
                           FOREIGN KEY (pmid) REFERENCES Articles (pmid),
                           FOREIGN KEY (authorID) REFERENCES Authors (authorID)
                          )")

dbExecute(dbcon, author_schema)
dbExecute(dbcon, journal_schema)
dbExecute(dbcon, article_schema)
dbExecute(dbcon, article_author_schema)

# XML and DTD file 
xmlFileURL <- "https://sendeyo.com/en/7cb87d1376"
dtdFileURL <- "https://sendeyo.com/en/56a8588cd1"
xmlData <- getURL(xmlFileURL)
dtdData <- getURL(dtdFileURL)

# XML validation
xmlObj <- xmlTreeParse(xmlData, dtdData)
r <- xmlRoot(xmlObj)
cnt <- xmlSize(r)
print(cnt)
