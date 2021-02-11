#!/usr/bin/env nextflow

// Re-usable componext for adding a helpful help message in our Nextflow script
def helpMessage() {
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    
    nextflow run main.nf --covar covar.tsv --logr logr.csv --chrom 5
    
    Mandatory arguments:
      --covar       [string] path to covar file in plain test
      --logr        [string] path to logr data in plain text
      --output      [string] name of the output file
      --demedian    [string] Remove median from logR by binary response: TRUE or FALSE

    Optional arguments:
      --help          [flag] Show help messages

    """.stripIndent()
}

// Show help message
if (params.help) exit 0, helpMessage()

if (params.covar) ch_covar = Channel.value(file(params.covar))
if (params.logr) ch_logr = Channel.value(file(params.logr))



// Doing bait-level association test
if (params.part == 'bait_test'){
  process bait_test {
    tag "${params.output}"
    echo true
    publishDir "results/", mode: "move"

    input:
    path covar from ch_covar
    path logr from ch_logr

    output:
    path "${params.output}"

    script:
    """
      Rscript /scripts/bait_level_test.R $logr $covar ${params.output} ${params.demedian}
    """
  }
}