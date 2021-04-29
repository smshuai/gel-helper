library(foreach)
library(doMC)
library(data.table)
library(patchwork)
library(Rbin)

args = commandArgs(trailingOnly=TRUE)

print(args)

## CMD arguments
rbin_dir = args[1]
covar = fread(args[2])
out = args[3]
indexfile = args[4]
chrom = args[5]
start = args[6]
stop = args[7]
demedian = args[8]
makeplot = args[9]

## Make data
rbin_names = dir(rbin_dir) # Assuming file name is sample name here
use_samples = intersect(covar$platekey, rbin_names)
rbin_files = paste0(rbin_dir, "/", use_samples)

# RbinRead_exome_ratio(chr, start, stop, typ="mixed", indexfile = NULL, filenames=NULL)
data = RbinRead_exome_ratio(chrom, start, stop, 'mixed', indexfile, rbin_files)


registerDoMC(30)

res <- foreach(ix=1:nrow(data), .combine='rbind') %dopar% {
    tmp = cbind(covar[use_samples], t(data[ix, use_samples, with=F]))
    if (demedian) {
        med = tmp[, median(V1), by=covid] # V1 is logR ratio
        tmp[covid==0, V1:=V1-med[covid==0, V1]]
        tmp[covid==1, V1:=V1-med[covid==1, V1]]
    }
    bfit <- glm(covid ~ . - platekey, data=tmp, family='binomial')
    bcoef <- coef(summary(bfit))
    unlist(c(data[ix, 1:3], bcoef['V1',]))
}

res = setDT(as.data.frame(res))
colnames(res) = c('CHR', 'START', 'END', 'EST', 'SE', 'Z', 'P')
res[, BP:=(START+END)/2]

if (makeplot) {
    source('/scripts/gwas_res_plot.R')
    p = manhattan_plot(res) / (pval_hist(res$P) | pval_qqplot(res$P))
    ggsave(paste0(out, '.png'), p, width = 15, height=15, units = 'cm', dpi=300)
}

fwrite(res, paste0(out, '.txt'), row.names=F, quote=F)