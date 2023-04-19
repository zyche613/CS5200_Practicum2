## load library
# Package names
packages <- c("XML", "DBI", "RSQLite", "RCurl", "r2r")

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
library(r2r)

# db setup
dbcon <- dbConnect(RSQLite::SQLite(), "")

# create db tables
affiliation_schema <- SQL("CREATE TABLE Affiliation (
                          affiliationId INTEGER PRIMARY KEY,
                          affiliationText TEXT)")

author_schema <- SQL("CREATE TABLE Authors (
                   authorId INTEGER PRIMARY KEY,
                   lastName TEXT,
                   foreName TEXT,
                   initials TEXT,
                   suffix TEXT,
                   affiliationId INTEGER,
                   FOREIGN KEY (affiliationId) REFERENCES 
                  )")

journalIssue_schema <- SQL("CREATE TABLE JournalIssue (
                           journalIssueId INTEGER PRIMARY KEY,
                           journalId INTEGER,
                           citedMedium TEXT,
                           volume INTEGER,
                           issue INTEGER,
                           year INTEGER,
                           month INTGER,
                           day INTEGER,
                           FOREIGN KEY(journalId) REFERENCES Journals (jouranlId)")

journal_schema <- SQL("CREATE TABLE Journals (
                    journalId INTEGER PRIMARY KEY,
                    journalTitle TEXT,
                    journalIssue INTEGER,
                    ISSNType TEXT,
                    ISSN TEXT,
                    ISOAbbreviation TEXT,
                    FOREIGN KEY (journalIssue) REFERENCES JournalIssue (journalIssueId)
                  )")

article_schema <- SQL("CREATE TABLE Articles (
                    articleId INTEGER PRIMARY KEY,
                    journalIssueId INTEGER,
                    articleTitle TEXT,
                    completeYN TINYINT,
                    FOREIGN KEY (journalIssueId) REFERENCES JournalIssue (journalIssueId)
                  )")

article_author_schema <- SQL("CREATE TABLE AuthorArticle (
                           authorArticleId INTEGER PRIMARY KEY,
                           articleId INTEGER,
                           authorId INTEGER,
                           valid TINYINT,
                           FOREIGN KEY (articleID) REFERENCES Articles (articleID),
                           FOREIGN KEY (authorID) REFERENCES Authors (authorID)
                          )")

dbExecute(dbcon, affiliation_schema)
dbExecute(dbcon, author_schema)
dbExecute(dbcon, journal_schema)
dbExecute(dbcon, article_schema)
dbExecute(dbcon, article_author_schema)

# XML and DTD
xmlLocal <- "pubmed-tfm-xml/test.xml"
dtdLocal <- "pubmed.dtd"

xmlObj <- xmlTreeParse(xmlLocal, dtdLocal)
r <- xmlRoot(xmlObj)
cnt <- xmlSize(r)

# Load data from xml by node traversal
articleIdVector <- c()
articleIdDupVector <- c()
authorCnVector <- c()
authorLnVector <- c()
authorFnVector <- c()
authorInitVector <- c()
authorSuffVector <- c()
authorAffVector <- c()
issnVector <- c()
issnTypeVector <- c()
journalTitleVector <- c()
ISOAbbVector <- c()
articleTitleVector <- c()
authorCompVector <- c()
citedMedVector <- c()
volVector <- c()
issueVector <- c()
yearVector <- c()
monthVector <- c()
dayVector <- c()
validVector <- c()
monthVectorStr <- c("JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC")
seasonVector <- c("Spring", "Summer", "Fall", "Winter")
monthVectors <- c(3, 6, 9, 12)
mhmap <- hashmap()
mSeasonToMonth <- hashmap()

for (i in 1:12) {
  mhmap[monthVectorStr[[i]]] = i
}

for (i in 1:4) {
  mSeasonToMonth[seasonVector[i]] = monthVectors[i]
}

for (i in 1:cnt) {
  articleIdVector <- c(articleIdVector, i)
  aArticle <- r[[i]]
  authorList <- aArticle[[1]][["AuthorList"]]
  numOfAuthor <- 0      
  if (!is.null(authorList)) {
    numOfAuthor <- xmlSize(authorList)
    if (numOfAuthor > 0) {
      for (j in 1:numOfAuthor) {
        collectiveName <- "NA"
        lastName <- "NA"
        foreName <- "NA"
        initials <- "NA"
        suffix <- "NA"
        affiliation <- "NA"
        isComplete <- "N"
        # Get CollectiveName if any
        if (!is.null(xmlValue(authorList[[j]][["CollectiveName"]]))) {
          collectiveName = xmlValue(authorList[[j]][["CollectiveName"]])
        }
        # Get LastName if any
        if (!is.null(xmlValue(authorList[[j]][["LastName"]]))) {
          lastName = xmlValue(authorList[[j]][["LastName"]])
        }
        # Get ForeName if any
        if (!is.null(xmlValue(authorList[[j]][["ForeName"]]))) {
          foreName = xmlValue(authorList[[j]][["ForeName"]])
        }
        # Get Initials if any
        if (!is.null(xmlValue(authorList[[j]][["Initials"]]))) {
          initials = xmlValue(authorList[[j]][["Initials"]])
        }
        # Get Suffix if any
        if (!is.null(xmlValue(authorList[[j]][["Suffix"]]))) {
          suffix = xmlValue(authorList[[j]][["Suffix"]])
        }
        # Get AffiliationInfo if any
        if (!is.null(xmlValue(authorList[[j]][["AffiliationInfo"]]))) {
          affiliation = xmlValue(authorList[[j]][["AffiliationInfo"]][["Affiliation"]])
        }
        isComplete <- xmlAttrs(authorList)[["CompleteYN"]]
        # Append all info for future use
        authorCnVector <- c(authorCnVector, collectiveName)
        authorLnVector <- c(authorLnVector, lastName)
        authorFnVector <- c(authorFnVector, foreName)
        authorInitVector <- c(authorInitVector, initials)
        authorSuffVector <- c(authorSuffVector, suffix)
        authorAffVector <- c(authorAffVector, affiliation)
        articleIdDupVector <- c(articleIdDupVector, i)
        validVector <- c(validVector, xmlAttrs(authorList[[j]])[["ValidYN"]])
        authorCompVector <- c(authorCompVector, isComplete)
      }
    }  
  } else {
    collectiveName <- "NA"
    lastName <- "NA"
    foreName <- "NA"
    initials <- "NA"
    suffix <- "NA"
    affiliation <- "NA"
    isComplete <- "N"
    authorCnVector <- c(authorCnVector, "NA")
    authorLnVector <- c(authorLnVector, "NA")
    authorFnVector <- c(authorFnVector, "NA")
    authorInitVector <- c(authorInitVector, "NA")
    authorSuffVector <- c(authorSuffVector, "NA")
    authorAffVector <- c(authorAffVector, "NA")
    articleIdDupVector <- c(articleIdDupVector, i)
    validVector <- c(validVector, "N")
    authorCompVector <- c(authorCompVector, "N")
  }
    
  # Get ISSN, IssnType, Title, ISOAbbreviation
  ISSN = "NULL"
  IssnType = "NULL"
  title = "NULL"
  ISOAbbreviation = "NULL"
  Journal <- aArticle[[1]][["Journal"]]
  if (!is.null(xmlValue(Journal))) {
    ISSNNode <- Journal[["ISSN"]]
    if (!is.null(xmlValue(ISSNNode))) {
      ISSN = xmlValue(ISSNNode)
      IssnType = xmlAttrs(ISSNNode)[["IssnType"]]
    }
    titleNode <- Journal[["Title"]]
    if (!is.null(xmlValue(titleNode))) {
      title = xmlValue(titleNode)
    }
    ISOAbbreviationNode <- Journal[["ISOAbbreviation"]]
    if (!is.null(xmlValue(ISOAbbreviationNode))) {
      ISOAbbreviation = xmlValue(ISOAbbreviationNode)
    }
  }
  issnVector <- c(issnVector, ISSN)
  issnTypeVector <- c(issnTypeVector, IssnType)
  journalTitleVector <- c(journalTitleVector, title)
  ISOAbbVector <- c(ISOAbbVector, ISOAbbreviation)
  
  # Get title
  articleTitle <- aArticle[[1]][["ArticleTitle"]]
  articleTitleVector <- c(articleTitleVector, xmlValue(articleTitle))
  
  # Get journal issue info, including both attributes and nested fields
  JournalIssue <- Journal[["JournalIssue"]]
  cited_medium <- "NA"
  if (!is.null(xmlValue(JournalIssue))) {
    cited_medium <- xmlAttrs(JournalIssue)[["CitedMedium"]]
  }
  citedMedVector <- c(citedMedVector, cited_medium)
  volume <- 0
  issue <- 0
  year <- 2000
  month <- 1
  day <- 1
  # Get volume if any
  if (!is.null(xmlValue(JournalIssue[["Volume"]]))) {
    volume <- xmlValue(JournalIssue[["Volume"]])
  }
  # Get Issue if any
  if (!is.null(xmlValue(JournalIssue[["Issue"]]))) {
    issue <- xmlValue(JournalIssue[["Issue"]])
  }
  # Get pubDate and the detail time, i.e. year, month, medline date
  pubDate <- JournalIssue[["PubDate"]]
  if (!is.null(xmlValue(pubDate[["Year"]]))) {
    year <- xmlValue(pubDate[["Year"]])
  }
  if (!is.null(xmlValue(pubDate[["Month"]]))) {
    mon <- xmlValue(pubDate[["Month"]])
    if (nchar(mon) == 2) {
      month <- as.integer(mon)
    } else {
      month <- mhmap[[toupper(mon)]]
    }
  }
  if (!is.null(xmlValue(pubDate[["Day"]]))) {
    day <- xmlValue(pubDate[["Day"]])
  }
  
  #use the year and month of the start time
  if (!is.null(xmlValue(pubDate[["MedlineDate"]]))) {
    medlineDate <- xmlValue(pubDate[["MedlineDate"]])
    arr <- strsplit(medlineDate, "-")[[1]]
    start <- arr[[1]]
    startArr <- strsplit(start, " ")[[1]]
    year <- as.integer(startArr[[1]])
    if (length(startArr) > 1) {
      month <- mhmap[[toupper(startArr[[2]])]]
    }
  }
  volVector <- c(volVector, as.integer(volume))
  issueVector <- c(issueVector, as.integer(issue))
  yearVector <- c(yearVector, as.integer(year))
  monthVector <- c(monthVector, as.integer(month))
  dayVector <- c(dayVector, as.integer(day))
}

# function to get journalIssueId
getJournalIssueId <- function(x, output) {
  str1 <- paste0(x[["ISSN"]], ":", x[["journalTitle"]], ":", x[["ISSNType"]], ":", 
                 as.integer(x[["volume"]]), ":", as.integer(x[["issue"]]), ":", x[["citedMedium"]], ":", 
                 as.integer(x[["year"]]), ":", as.integer(x[["month"]]), ":", as.integer(x[["day"]]), sep="")
  index <- which(str1 == issue_cmp_str)
  return (journalIssueDf[index, 1])
}

# function to get journalId
getJournalId <- function(x, output) {
  str1 <- paste0(x[["ISSN"]], ":", x[["title"]], ":", x[["ISSNType"]])
  return(journalDf[which(str1 == journal_cmp_str), 1])
}

# journalDf
journalDf <- data.frame(ISSN=issnVector, ISSNType=issnTypeVector, journalTitle=journalTitleVector, ISOAbbreviation=ISOAbbVector)
journalDf <- journalDf[!duplicated(journalDf), ]
vectorJournalId <- 1:length(journalDf[,1])
journalDf <- cbind(journalId = vectorJournalId, journalDf)
print("journalDf")
print(head(journalDf, 5))

# Insert to Journals table
insertJournal <- function() {
  # Store data into journal table
  dbWriteTable(dbcon, "Journals", journalDf, append=TRUE, row.names=FALSE)
}
insertJournal()

# journalIssueDf
journalIssueDf <- data.frame(citedMedium=citedMedVector, volume=volVector, 
                             issue=issueVector, year=yearVector, month=monthVector, 
                             day=dayVector, ISSN=issnVector, 
                             title=journalTitleVector, ISSNType=issnTypeVector)
print(length(monthVector))

print(head(journalIssueDf, 5))
journalIssueDf <- journalIssueDf[!duplicated(journalIssueDf), ]
journalIssueDf <- cbind(journalIssueId = 1:length(journalIssueDf[,1]), journalIssueDf)

# Create articleDf dataframe
articleDf <- data.frame(articleId=articleIdVector, articleTitle=articleTitleVector, 
                        completeYN=authorCompVector,citedMedium=citedMedVector, 
                        volume=volVector, issue=issueVector, ISSN=issnVector, 
                        journalTitle=journalTitleVector, ISSNType=issnTypeVector, year=yearVector, 
                        month=monthVector, day=dayVector)
articleDf <- articleDf[!duplicated(articleDf$articleId), ]

# Find journal_issue_id from journalIssueDf
issue_cmp_str <- paste0(journalIssueDf$ISSN, ":", journalIssueDf$title, ":", journalIssueDf$ISSNType, ":", 
                  journalIssueDf$volume, ":", journalIssueDf$issue, ":",journalIssueDf$citedMedium, ":",
                  journalIssueDf$year, ":", journalIssueDf$month, ":", journalIssueDf$day, sep="")
# Find pub_date_id and journal_id from pubdate and journalDf
journal_cmp_str <- paste0(journalDf$ISSN, ":", journalDf$journalTitle, ":", journalDf$ISSNType)

# Store data into journal_issue table
journalIssueId <- apply(articleDf, 1, getJournalIssueId)
journalId <- apply(journalIssueDf, 1, getJournalId)
journalIssueDf <- cbind(journalIssueDf, journalId=journalId)
articleDf <- cbind(articleDf, journalIssueId = journalIssueId)
articleDf <- subset(articleDf, select=c(articleId, articleTitle, completeYN, journalIssueId))
print("articleDf")
print(head(articleDf, 5))
# Remove redundant columns
journalIssueDf <- subset(journalIssueDf, select = -c(ISSN, title, ISSNType))
print("journalIssueDf")
print(head(journalIssueDf, 5))
dbWriteTable(dbcon, "journalIssue", journalIssueDf, append=TRUE, row.names=FALSE)
dbWriteTable(dbcon, "Articles", articleDf, append=TRUE, row.names=FALSE)

# Create Author dataframe
numAuthor <- length(authorCnVector)
authorIdVector <- 1:numAuthor
authorDf <- data.frame(collectiveName = authorCnVector, 
                       lastName = authorLnVector, foreName = authorFnVector,
                       initials = authorInitVector, suffix = authorSuffVector, affiliationId = authorAffVector)
  
authorDf <- authorDf[!duplicated(authorDf), ]
authorIdVector <- 1:length(authorDf[,1])
authorDf <- cbind(authorId = authorIdVector, authorDf)
  
# Create AuthorArticle dataframe
authorArtDf <- data.frame(collectiveName=authorCnVector, affiliation=authorAffVector,
                          lastName=authorLnVector, foreName=authorFnVector, 
                          initials=authorInitVector, suffix=authorSuffVector,
                          articleId=articleIdDupVector, valid=validVector)
  
  # Get author_id according to name from authorDf
author_cmp_str <- paste0(authorDf$collectiveName, ",", authorDf$lastName, ",", 
                  authorDf$foreName, ",", authorDf$initials, ",", authorDf$suffix, 
                  ",", authorDf$affiliationId)
  
getAuthorId <- function(x) {
  str1 <- paste0(x[["collectiveName"]], ",", x[["lastName"]], ",", 
                  x[["foreName"]], ",", x[["initials"]], ",", x[["suffix"]], ",", x[["affiliation"]])
  index <- which(str1 == author_cmp_str)
  return (authorDf[index, 1])
}
  
author_id <- apply(authorArtDf, 1, getAuthorId)
authorArtDf <- cbind(authorId=author_id, authorArtDf)
print("authorDf")
print(head(authorDf, 5))
# Store data into author table
dbWriteTable(dbcon, "Authors", authorDf, append=TRUE, row.names=FALSE)

authorArtDf <- authorArtDf[!duplicated(authorArtDf), ]
pairLen <- length(authorArtDf[,1])
IdVector <- 1:pairLen
authorArtDf <- cbind(authorArticleId=IdVector, authorArtDf)
authorArtDf <- subset(authorArtDf, select = c(authorArticleId, authorId, articleId, valid))
print("authorArtDf")
print(head(authorArtDf, 5))
# Store data into author_article table
dbWriteTable(dbcon, "AuthorArticle", authorArtDf, append=TRUE, row.names=FALSE)

r <- dbGetQuery(dbcon, "SELECT * FROM JournalIssue")
r

# Disconnect database connection
dbDisconnect(dbcon)
