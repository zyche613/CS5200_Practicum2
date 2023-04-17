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
                    ISOAbbreviation TEXT,
                    volume TEXT,
                    pubDate Date
                  )")

article_schema <- SQL("CREATE TABLE Articles (
                    articleID INTEGER PRIMARY KEY,
                    journalID INTEGER,
                    articleTitle TEXT,
                    FOREIGN KEY (journalID) REFERENCES Journals (journalID)
                  )")

article_author_schema <- SQL("CREATE TABLE ArticleAuthor (
                           articleID INTEGER,
                           authorID INTEGER,
                           FOREIGN KEY (articleID) REFERENCES Articles (articleID),
                           FOREIGN KEY (authorID) REFERENCES Authors (authorID)
                          )")

dbExecute(dbcon, author_schema)
dbExecute(dbcon, journal_schema)
dbExecute(dbcon, article_schema)
dbExecute(dbcon, article_author_schema)

# XML and DTD file from URL

# XML validation
xmlLocal <- "pubmed-tfm-xml/pubmed22n0001-tf.xml"
dtdLocal <- "pubmed.dtd"

xmlObj <- xmlTreeParse(xmlLocal, dtdLocal)
r <- xmlRoot(xmlObj)
cnt <- xmlSize(r)
print(cnt)

# Store to data frame
author_df <- data.frame(authorID = integer(),
                        lastName = character(),
                        firstName = character(),
                        initials = character()
                        )

article_df <- data.frame(articleID = integer(),
                         journalID = integer()
                         )

journal_df <- data.frame(journalID = integer(),
                         journalTitle = character(),
                         ISSN = character(),
                         ISOAbbreviation = character(),
                         volume = character(),
                         pubDate = character()
                        )

article_author_df <- data.frame(articleID = integer(),
                                authorID = integer()
                               )