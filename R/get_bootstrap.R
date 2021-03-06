#' Extract a bootstrap
#'
#' Extract statistical information from a bootstrap
#'
#' @inheritParams bootstrap
#' @inheritParams plot_histogram
#' @inheritParams plot_var_2D
#' @inheritParams plot_var_1D
#' @param bars A character among "sd" for standard deviations, "stderr" for the standard error, "ci" for confidence interval of scores and "cim" for the confidence intervall of the mean.
#' @param b A list of list weights (one per bootstrap per blocks)
#' @return A matrix containing the means, 95% intervals, bootstrap ratio and p-values
#' @examples
#' library(RGCCA)
#' data("Russett")
#' blocks = list(agriculture = Russett[, seq(3)], industry = Russett[, 4:5],
#'     politic = Russett[, 6:11] )
#' rgcca_out = rgcca(blocks)
#' boot = bootstrap(rgcca_out, 2, superblock = FALSE, n_cores = 1)
#' get_bootstrap(boot, n_cores = 1)
#' @export
#' @importFrom stats pt
get_bootstrap <- function(
    b,
    comp = 1,
    i_block = length(b$bootstrap[[1]]),
    bars="sd",
    collapse = FALSE,
    n_cores = parallel::detectCores() - 1) {
    stopifnot(is(b, "bootstrap"))

    check_compx("comp", comp, b$rgcca$call$ncomp, i_block)
    check_ncol(b$rgcca$Y, i_block)
    check_blockx("i_block", i_block, b$rgcca$call$blocks)
    check_boolean("collapse", collapse)
    check_integer("n_cores", n_cores, 0)

    if (n_cores == 0)
        n_cores <- 1

    if (collapse && b$rgcca$call$superblock) {
        b$rgcca$a <- b$rgcca$a[-length(b$rgcca$a)]
        if (i_block > length(b$rgcca$a))
            i_block <- length(b$rgcca$a)
    }

    if (comp > min(b$rgcca$call$ncomp))
        stop("Selected dimension was not associated to every blocks",
             exit_code = 113)

    cat("Binding in progress...")

    mean <- weight <- sd <- occ <- list()

    if (collapse)
        J <- seq(length(b$rgcca$a))
    else
        J <- i_block

    for (i in J) {

        b_bind <- parallelize(
            c(),
            b$bootstrap,
            function(x) x[[i]][, comp],
            n_cores = n_cores,
            envir = environment(),
            applyFunc = "parLapply")

        weight[[i]] <- b$rgcca$a[[i]][, comp]
        b_select <- matrix(
            unlist(b_bind),
            nrow = length(b_bind),
            ncol = length(b_bind[[1]]),
            byrow = TRUE
        )
        colnames(b_select) <- names(weight[[i]])
        rm(b_bind); gc()

        n <- seq(NCOL(b_select))

        if (tolower(b$rgcca$call$type) %in% c("spls", "spca", "sgcca")) {

            occ[[i]] <- unlist(
                parallelize(
                    c(),
                    n,
                   function(x)
                       sum(b_select[, x] != 0) / length(b_select[, x]),
                   n_cores = n_cores,
                   envir = environment(),
                   applyFunc = "parLapply"))
            
        }

        mean[[i]] <- unlist(
            parallelize(
            c(),
            n,
           function(x) mean(b_select[,x]),
           n_cores = n_cores,
           envir = environment(),
           applyFunc = "parLapply"
        ))
        if (NCOL(b_select) == 1)
            sd[[i]] <- 1
        else
            sd[[i]] <- unlist(
                parallelize(
                    c(),
                    n,
                   function(x) sd(b_select[,x]),
                   n_cores = n_cores,
                   envir = environment(),
                   applyFunc = "parLapply"
                ))

        rm(b_select); gc()
    }
    
    n_boot <- length(b$bootstrap)

    occ <- unlist(occ)
    mean <- unlist(mean)
    weight <- unlist(weight)
    sd <- unlist(sd) 

    cat("OK.\n", append = TRUE)
    p.vals <- 2 * pt(abs(weight)/sd, lower.tail = FALSE, df = n_boot - 1)
    tail <- qt(1 - .05 / 2, df = n_boot - 1)
    
    if(bars=="sd")
    {
        length_bar=sd
     }
    if(bars=="stderr")
    {
        length_bar=sd/sqrt(n_boot)
    }
    if(bars=="ci")
    {
        length_bar=tail*sd
    }
    if(bars=="cim")
    {
        length_bar=tail*sd/sqrt(n_boot)
    }

    df <- data.frame(
        mean = mean,
        estimate = weight,
        lower_band = mean -  length_bar,
        upper_band = mean +  length_bar,
        bootstrap_ratio = abs(mean) / sd,
        p.vals,
        BH = p.adjust(p.vals, method = "BH")
    )

    if (tolower(b$rgcca$call$type) %in% c("spls", "spca", "sgcca")) {
        index <- 8
        df$occurrences <- occ
    }else{
        index <- 5
        df$sign <- rep("", NROW(df))
        
        for (i in seq(NROW(df)))
            if (df$lower_band[i]/df$upper_band[i] > 0)
                df$sign[i] <- "*"
        
    }
    
    rm(b); gc()

    if (collapse)
        df$color <- as.factor(get_bloc_var(b$rgcca$a, collapse = collapse))

    zero_var <- which(df[, 1] == 0)
    if (NROW(df) > 1 && length(zero_var) != 0)
        df <- df[-zero_var, ]

    b <- data.frame(order_df(df, index, allCol = TRUE), order = NROW(df):1)
    attributes(b)$indexes <-
        list(
            estimate = "RGCCA weights",
            bootstrap_ratio = "Bootstrap-ratio",
            sign = "Significant 95% \nbootstrap interval",
            occurrences = "Non-zero occurences",
            mean = "Mean bootstrap weights"
        )
    attributes(b)$type <- class(rgcca)
    attributes(b)$n_boot <- n_boot
    class(b) <- c(class(b), "df_bootstrap")
    return(b)
}
