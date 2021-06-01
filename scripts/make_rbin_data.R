library(Rbin)

args = commandArgs(trailingOnly=TRUE)
print(args)

rbin_dir = args[1]
indexfile = args[2]
chrom = args[3]

rbin_files = list.files(rbin_dir, full.names=T)
index = read.table(indexfile)

start_coord = min(subset(index, V1==chrom, V2))
end_coord = max(subset(index, V1==chrom, V3))

data = RbinRead_exome_ratio(chrom, start_coord, end_coord, 'mixed', indexfile, rbin_files)
colnames(data) = basename(colnames(data))

write.csv(data, printf('LRR.table.c%d.csv', chrom), row.names=F, quote=F)


