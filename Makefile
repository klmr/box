%.md: %.rmd
	Rscript --no-save --no-restore -e "library(knitr); knit('$<', '$@')"
