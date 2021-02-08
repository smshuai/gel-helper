#!/usr/bin/env nextflow

// Re-usable componext for adding a helpful help message in our Nextflow script
def helpMessage() {
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    
    nextflow run main.nf --project test --part 4 
    
    Mandatory arguments:
      --covar       [string] Name of the project
      --logr
      --chrom         

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
    tag "${sample_name}"
    echo true
    publishDir "results/", mode: "move"

    input:
    path covar from ch_covar
    path logr from ch_logr

    output:
    path "covid_v2_chr${params.chrom}_bait_result_mixed.csv"

    script:
    """
      Rscript /scripts/bait_level_test.R $logr $covar $params.chrom
    """
  }
}