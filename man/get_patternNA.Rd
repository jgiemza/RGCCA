% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/determine_patternNA.R
\name{get_patternNA}
\alias{get_patternNA}
\title{get_patternNA}
\usage{
get_patternNA(blocks)
}
\arguments{
\item{blocks}{list of blocks}
}
\value{
a object patternNA, which corresponds to a list containing:
\itemize{
\item the percentage of missing values per variable (\code{pctNA})
\item the percentage of missing values per block (\code{pctNAbyBlock})
\item the complete individuals percentage (\code{completeSubjectByBlock})
\item the final blocks (with potential additional NA lines) (\code{blocks})
}
}
\description{
Determines the pattern of missing values and allows to use it to create datasets with the same pattern. Also add NA lines if one individual is present in a block and not in another one.
}
\examples{
X1=matrix(rnorm(150),30,5)
X2=matrix(rnorm(150),30,5)
X3=matrix(rnorm(150),30,5)
X1[1:10,1]=NA
X1[2,2]=NA
X1[11,]=NA
X2[1:10,1]=NA
colnames(X1)=paste0("A",1:5)
colnames(X2)=paste0("B",1:5)
colnames(X3)=paste0("C",1:5)
A=list(bloc1=X1,bloc2=X2,bloc3=X3)
get_patternNA(A)
}
\seealso{
\code{\link[RGCCA]{plot.patternNA}}
}
