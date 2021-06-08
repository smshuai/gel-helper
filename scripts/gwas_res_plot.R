require(data.table)
require(ggplot2)
require(ggrepel)

manhattan_plot <- function(gwas.dat, sig='auto', chroms=1:24, annot=FALSE) {
    gwas.dat <- as.data.table(gwas.dat)
    gwas.dat <- gwas.dat[CHR %in% chroms]
    setkey(gwas.dat, CHR, BP)
    nCHR <- length(unique(gwas.dat$CHR))

    nbp = gwas.dat[, list('nbp'=max(BP)), by=CHR]
    setkey(nbp, CHR)
    nbp[, bp_offset:=c(0, cumsum(as.numeric(nbp))[-nCHR])]
    gwas.dat = gwas.dat[nbp]
    gwas.dat[, BPcum:=BP+bp_offset]
    axis.set <- gwas.dat[, list('center'=(max(BPcum)+min(BPcum))/2), by=CHR]
    
    if (sig=='auto') sig <- 0.01/nrow(gwas.dat)
    
    ylim <- max(c(-log10(gwas.dat$P), -log10(sig))) * 1.1
    
    manhplot <- ggplot(gwas.dat, aes(x=BPcum, y=-log10(P), color=as.factor(CHR))) +
        geom_point(alpha=0.75, size=0.5) +
        geom_hline(yintercept = -log10(sig), color='red', linetype='dashed') +
        scale_x_continuous(label = axis.set$CHR, breaks=axis.set$center) +
        scale_y_continuous(expand = c(0,0),
                           limits = c(0, ylim)) +
        scale_color_manual(values = rep(c("#F1BB7B", "#FD6467", 
                                          "#5B1A18", "#D67236"), nCHR)) +
        labs(x=NULL, y='-log10(P)') +
        theme_bw() +
        theme(legend.position = 'none',
            panel.border = element_blank(),
            panel.grid = element_blank())
    if (annot) {
        n = 3 # annot max 3 sig genes for each chrom with significant hits
        gene_annot <- gwas.dat[P <= sig][order(P)][, head(Gene, n), by=CHR]$V1
        if (length(gene_annot) > 0) {
            manhplot <- manhplot + geom_text_repel(data=gwas.dat[Gene %in% gene_annot],
                                                   aes(x=BPcum, y=-log10(P), label=gene_name))
        }
    }
    return(manhplot)
}


pval_qqplot <- function(pvec, add_lambda=TRUE) {
    pobs = -log10(sort(pvec))
    pexp = -log10(1:length(pvec)/length(pvec))
    df = data.frame(pobs, pexp)
    p = ggplot(df, aes(x=pexp, y=pobs)) + geom_point(size=0.8, alpha=0.75) +
        geom_abline(slope=1, intercept=0, color='red', linetype='dashed') +
        labs(x='Expected -log10(P)', y='Observed -log10(P)') +
        theme_bw() +
        theme(panel.grid = element_blank())
    if (add_lambda) p <- p + annotate('text', x=max(pexp)*0.2, y=max(pobs)*0.9, label=sprintf('Lambda = %.3f', calc_lambda(pvec)), color='red')
    return(p)
}

calc_lambda <- function(pvec) {
    chisq <- qchisq(1 - pvec, 1)
    lambda <- median(chisq) / qchisq(1/2, df = 1)
    return(lambda)
}

pval_hist <- function(pvec) {
    p = ggplot(data.frame(pvec), aes(x=pvec)) +
        geom_histogram(bins=20, fill="#899DA4", color='black') +
        theme_bw() +
        theme(panel.grid = element_blank()) +
        labs(x='Observed P', y='count')
    p
    return(p)
}


# manhattan_plot(gwas.dat) / (pval_hist(gwas.dat$P) | pval_qqplot(gwas.dat$P) )
