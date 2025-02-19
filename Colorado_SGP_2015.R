#########################################################
###
### Calculate SGPs for Colorado - 2015
###
##########################################################

### Load required packages

require(SGP)
require(data.table)


###  Load Colorado LONG data up to 2015

load("Data/Colorado_Data_LONG.Rdata")


###  Read in 2015 SGP Configuration Scripts and Combine

source("SGP_CONFIG/2015/ELA.R")
source("SGP_CONFIG/2015/MATHEMATICS.R")

COLO_2015.config <- c(
		MATHEMATICS_2015.config,
		ELA_2015.config)

###  Winnow out all course progressions with fewer than 2,000 kids (per discussion on 3/14/16)

SGPstateData[["CO_ORIGINAL"]][["SGP_Configuration"]][["sgp.cohort.size"]] <- 2000
SGPstateData[["CO_ORIGINAL"]][["SGP_Configuration"]][["return.norm.group.scale.scores"]] <- TRUE


### abcSGP

Colorado_SGP <- abcSGP(
		state="CO_ORIGINAL",
		sgp_object=Colorado_Data_LONG,
		sgp.config = COLO_2015.config,
		steps=c("prepareSGP", "analyzeSGP", "combineSGP", "outputSGP"),
		sgp.percentiles = TRUE,
		sgp.projections = FALSE,
		sgp.projections.lagged = FALSE,
		sgp.percentiles.baseline=FALSE,
		sgp.projections.baseline = FALSE,
		sgp.projections.lagged.baseline = FALSE,
		sgp.percentiles.equated = FALSE,
		simulate.sgps = FALSE,
		save.intermediate.results=FALSE,
		outputSGP.output.type=c("LONG_Data", "LONG_FINAL_YEAR_Data", "WIDE_Data"),
		parallel.config = list(BACKEND="PARALLEL", WORKERS=list(PERCENTILES=15))) # Ubuntu/Linux


### Fill in ACHIEVEMENT_LEVEL_PRIOR for ELA -- WRITING was the test specified as first prior...
for (pg in 3:8) {
	Colorado_SGP@Data[which(CONTENT_AREA=="ELA" & YEAR=='2015' & GRADE==pg+1 & VALID_CASE=="VALID_CASE"),
		ACHIEVEMENT_LEVEL_PRIOR := ordered(findInterval(as.numeric(SCALE_SCORE_PRIOR),
			SGPstateData[["CO_ORIGINAL"]][["Achievement"]][["Cutscores"]][["WRITING"]][[paste("GRADE", pg, sep="_")]]),
			labels=c("Unsatisfactory", "Partially Proficient", "Proficient", "Advanced"))]
}


###  Summarize Results

Colorado_SGP <- summarizeSGP(
	Colorado_SGP,
	state="CO_ORIGINAL",
	parallel.config=list(BACKEND="PARALLEL", WORKERS=list(SUMMARY=12))
)


visualizeSGP(Colorado_SGP,
	state="CO_ORIGINAL",
	plot.types = "bubblePlot",
	bPlot.years=  "2015",
	bPlot.content_areas=c("ELA", "MATHEMATICS"),
	bPlot.anonymize=TRUE)


###  Save 2015 Colorado SGP object

save(Colorado_SGP, file="Data/Colorado_SGP.Rdata")
