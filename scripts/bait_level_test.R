library(foreach)
library(doMC)
library(data.table)

args = commandArgs(trailingOnly=TRUE)

print(args)

data = fread(args[1])
covar = fread(args[2])
chrom = as.integer(args[3])

setkey(covar, platekey)
use_samples = intersect(covar$platekey, colnames(data))

registerDoMC(30)

res <- foreach(ix=1:nrow(data), .combine='rbind') %dopar% {
    tmp = cbind(covar[use_samples], t(data[ix, use_samples, with=F]))
    bfit <- glm(covid ~ . - platekey, data=tmp, family='binomial')
    bcoef <- coef(summary(bfit))
    c(data[ix, 1:3], bcoef['V1',])
}

res = setDT(as.data.frame(res))

fwrite(res, sprintf('./covid_v2_chr%d_bait_result_mixed.csv', chrom), row.names=F, quote=F)