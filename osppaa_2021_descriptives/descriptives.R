## >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> #
# >> PREP: Load data and packages                                    #
## >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> #

source("yml_SETTINGS_loading.R")

## >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> #
# >> Descriptive tables                                    #
## >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> >> #

######################################################################
## Basic Descriptive Table for all coins before normalization after:
## - removing outliers
## - removing missing variables
######################################################################
options(scipen=999)

## >> Descriptives of very raw data table for appendix

dropcoins <- c("bitcoin")
raw <- as_tibble(read.csv("../osppaa_data/inputdata_raw_hourly.csv"))
raw <- raw %>% filter(!coin %in% dropcoins)%>% droplevels()
descriptives_raw <- dscrbe(raw, col_desc = c("coin",
                                             "prices",
                                             "csupply",
                                             "total_volumes"))
descriptives_raw <- descriptives_raw %>%
    mutate(vars = rename_vars(as.character(vars)))

## >> Descriptives of data as used in regressions for table
load(paste0(SETTINGS$modelling$finaldatapath,"mT_mMCaV.Rdta"))

descriptives_clean_short <-
    dta[["noutl"]] %>%
    group_by(coin) %>%
    summarize(n             = n(),
              sd_price      = round(sd(prices)*100, digits = 2),
              vol_latest    = round(head(total_volumes,1)/1000000, digits = 2),
              supply_latest = round(head(market_caps,1)/1000000, digits = 2),
              min_dist      = round(min(V_fv)*100, digits = 2),
              avg_dist      = round(mean(V_fv)*100, digits = 2),
              max_dist      = round(max(V_fv)*100, digits = 2)) %>%
    mutate(coin = rename_coins(as.character(coin))) %>% 
    arrange(desc(n)) %>%
    as.data.frame

## >> Table to tex
## Add Multicolumn row
addtorow <- list()
addtorow$pos <- list(0)
addtorow$command <- "\\multicolumn{2}{l}{ } & \\multicolumn{3}{c}{} & \\multicolumn{3}{c}{\\emph{Peg Dev.}} \\\\  \\emph{Projects} & \\emph{Obs.} & $\\sigma$ & \\emph{Vol.} & \\emph{Supply} & \\emph{Min.} & \\emph{Avg.} & \\emph{Max.} \\\\"
tbl <- xtable(descriptives_clean_short
            , align = "llcrrrrrr"
             ,title = "Average market capitalization, aggregated trading volumes, and prices  after data cleaning."
              )
print(tbl
     ,file=paste0(SETTINGS$modelling$resultspath,"descriptives_clean_short.tex")
     ,sanitize.text.function = function(x) x
     ,include.rownames = FALSE
     ,floating = FALSE
     ,booktabs = TRUE
     ,include.colnames=FALSE
     ,add.to.row=addtorow
     ,hline.after = c(-1, 0, nrow(tbl))
                                        #    , format.args = list(width = 7)
      )


## >> Outlier treatment

n          <- NULL
p          <- NULL
cuttoffseq <- seq(1,10,1)
for(cuttoff in cuttoffseq){

    noutl    <- truncateOutliersPanel(dta[["raw"]], truncvar = cuttoff)
    absdiff  <- sum(dta[["raw"]][,"prices"] != noutl[,"prices"])
    prozdiff <- round(100*absdiff/length(noutl$prices),digits = 2)
    n <- c(n,absdiff)
    p <- c(p,prozdiff)

}

tbl <- data.frame("Cut-Off (in SD)"                    = round(cuttoffseq, digits = 0),
                  "N"   = n,
                  "\\%" = p,
                  check.names                  = F)

tbl <- xtable(tbl %>% mutate_all(as.character)
             ,align = "cccc"
              )
addtorow <- list()
addtorow$pos <- list(0)
addtorow$command <- "\\multicolumn{1}{c}{Cutoff} & \\multicolumn{2}{c}{Outliers as Defined by Cutoff} \\\\ (in Std. Dev.) & N & \\% \\\\"
print(tbl
     ,file=paste0(SETTINGS$modelling$resultspath, "outliers.tex")
     ,sanitize.text.function = function(x) x
     ,include.rownames = FALSE
     ,floating = FALSE
     ,add.to.row=addtorow
     ,booktabs = TRUE
     ,include.colnames=FALSE
     ,hline.after = c(-1, 0, nrow(tbl))
      )

