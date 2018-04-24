import pandas as pd

configfile: "/home/exacloud/lustre1/CEDAR/anurpa/cfrna/scripts/cfRNA/config.yaml"

seq = pd.read_table(config["samples"], index_col=["sample"], dtype=str)
samples=seq.index.values

EXT=["gene_count.txt","circrna/circularRNA_known.txt"]

rule all:
  input:
    expand("results/{sample}_{ext}",sample=samples,ext=EXT)

include: "rules/align_rmdp.smk"
include: "rules/circexplorer.smk"

