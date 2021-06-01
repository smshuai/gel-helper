library(foreach)
library(doMC)
library(data.table)
library(patchwork)

args = commandArgs(trailingOnly=TRUE)

print(args)

data = fread(args[1])
covar = fread(args[2])
out = args[3]
demedian = args[4]
makeplot = args[5]

setkey(covar, platekey)
use_samples = intersect(covar$platekey, colnames(data))

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
    if ('V1' %in% row.names(bcoef)) {
       unlist(c(data[ix, 1:3], bcoef['V1',]))
    } else {
       unlist(c(data[ix, 1:3], rep(NA, 4)))
    }
}

res = setDT(as.data.frame(res))
colnames(res) = c('CHR', 'START', 'END', 'EST', 'SE', 'Z', 'P')
res[, BP:=(START+END)/2]

fwrite(res, paste0(out, '.txt'), row.names=F, quote=F)

if (makeplot) {
    source('/scripts/gwas_res_plot.R')
    p = manhattan_plot(res) / (pval_hist(res$P) | pval_qqplot(res$P))
    ggsave(paste0(out, '.png'), p, width = 25, height=20, units = 'cm', dpi=300)
}