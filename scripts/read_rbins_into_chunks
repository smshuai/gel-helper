library(Rbin)
library(data.table)

get_all_data_by_type <- function(indexfile, binfiles, type="mixed") {
    index = read.table(indexfile)
    chrs = unique(index[,1])
    return(do.call(rbind, sapply(chrs, function(x) RbinRead_exome_ratio(x, min(index[index[,1]==x,2]), max(index[index[,1]==x,3]), type, indexfile, binfiles))))
}
                                     
covar <- fread('./covar/covid_v2.5_covar_GT_pca20.tsv')
indexfile <- './mounted-data/index_tab.txt'
binpath <- './mounted-data/rbin/'
N <- ceiling(nrow(covar) / 1000) # 1K samples for each file
start_ix <- seq(1, N*1000, 1000)
end_ix <- start_ix + 999
for (i in 1:N) {
    print(paste(start_ix[i], end_ix[i], sep=','))
    binfiles <- paste0(binpath, na.omit(covar$platekey[start_ix[i]:end_ix[i]]))
    dat <- get_all_data_by_type(indexfile, binfiles)
    dat = dat[,4:ncol(dat)]
    fwrite(t(dat), sprintf('./PCA_logRratio_chunk/PCA_logR_ratio_chunk_%d.csv', i), sep=',', col.names=F, quote=F)
}
