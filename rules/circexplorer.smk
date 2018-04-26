def get_fastq(wildcards):
    return seq.loc[(wildcards.sample), ["fq1", "fq2"]]

rule star:
  input: get_fastq
  output: "circexplorer/{sample}_chim_bam/Chimeric.out.junction"
	
  threads: 12
  params: name="star_{sample}", mem="64000"

  run: 
    STAR=config["star_tool"]
    pathToGenomeIndex = config["star_index"]
	 
    shell("""
    {STAR} --runThreadN {threads} \
           --runMode alignReads \
           --genomeDir {pathToGenomeIndex} \
	   --readFilesIn {input[0]} {input[1]} \
	   --outFileNamePrefix circexplorer/{wildcards.sample}_chim_bam/  \
	   --outSAMtype BAM SortedByCoordinate \
           --chimSegmentMin 5 \
           --chimJunctionOverhangMin 5 
    """) 
    
rule circ_explorer:
  input: "circexplorer/{sample}_chim_bam/Chimeric.out.junction"
  output: "results/{sample}_circrna/circularRNA_known.txt"
  
  params: name="ce_{sample}", mem="64000"

  run:
  
    refflat= config["refflat2"]
    genome= config["genome"]
  
    shell("""
    fast_circ.py parse \
        -r {refflat} \
        -g {genome} \
        -t STAR \
        -o results/{wildcards.sample}_circrna \
        {input} > circexplorer/{wildcards.sample}_circ.log
    """)
