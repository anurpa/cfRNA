def get_fastq(wildcards):
    return seq.loc[(wildcards.sample), ["fq1", "fq2"]]


rule STAR:
  input: get_fastq
  output: "genecounts_rmdp/{sample}_bam/Aligned.sortedByCoord.out.bam"
	
  threads: 12
  params: name="star_{sample}", mem="64000"

  run: 
    STAR=config["star_tool"]
    index = config["star_index"]
	 
    shell("""
		{STAR} --runThreadN {threads} \
		--runMode alignReads \
		--genomeDir {index} \
		--readFilesIn {input[0]} {input[1]} \
		--outFileNamePrefix genecounts_rmdp/{wildcards.sample}_bam/ \
		--outSAMtype BAM SortedByCoordinate """)

rule picard:
  input: "genecounts_rmdp/{sample}_bam/Aligned.sortedByCoord.out.bam"
  output:"genecounts_rmdp/{sample}_bam/{sample}.rmd.bam"
  
  params: name="rmd_{sample}", mem="5300"
  threads: 1
  
  run: 
    picard=config["picard_tool"]
    
    shell("java -Xmx3g -jar {picard} \
    INPUT={input} \
    OUTPUT={output} \
    METRICS_FILE=genecounts_rmdp/{wildcards.sample}_bam/{wildcards.sample}.rmd.metrics.text \
    REMOVE_DUPLICATES=true")
    
rule bamtosam:
  input:"genecounts_rmdp/{sample}_bam/{sample}.rmd.bam"
  output:"genecounts_rmdp/{sample}_bam/{sample}.rmd.sam"

  params: name="bamtosam_{sample}",mem="5300"

  run:
    shell("""samtools view -h {input} > {output}""")

rule sort:
  input:"genecounts_rmdp/{sample}_bam/{sample}.rmd.sam"
  output: "genecounts_rmdp/{sample}_bam/{sample}_sort.rmd.sam"    
  
  params: name="sort_{sample}", mem="6400"

  run:
    shell("""samtools sort -O sam -n {input} -o {output}""")
    
rule genecount:
  input: "genecounts_rmdp/{sample}_bam/{sample}_sort.rmd.sam" 
  output:"results/{sample}_gene_count.txt"

  params: name="genecount_{sample}", mem="5300"
  threads: 1
  
  run:
    shell("""
      htseq-count \
            -f sam \
            -r name \
            -s reverse \
            -m intersection-strict \
            --samout=genecounts_rmdp/htseq_samout/Output_{wildcards.sample}.sam \
            {input} \
            /home/exacloud/lustre1/CEDAR/anurpa/genomes/gencode.v27.annotation.gtf > {output}""")
		 
