% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/initsvd.R
\name{initsvd}
\alias{initsvd}
\title{Initialisation by SVD decomposition of X}
\usage{
initsvd(X, dual = TRUE)
}
\arguments{
\item{X}{A matrix with n lines and p columns}

\item{dual}{TRUE by default, allow to study the transposed matrix X when the number of rows is lower that the number of columns}
}
\value{
A matrix with n lines and n columns
}
\description{
The function initsvd() is called by rgccad() and does not have to be used by the user.
initsvd() enables the computation of initial scores of subjects for RGCCA based on SVD decomposition
If missing values, they are imputed by colmeans
}
