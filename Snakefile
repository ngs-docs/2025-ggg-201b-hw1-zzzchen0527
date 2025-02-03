SAMPLES = ["SRR2584857_1","SRR2584403_1", "SRR2584404_1", "SRR2584405_1"]
GENOME = ["ecoli-rel606"]

rule make_vcf:
    input:
        expand("outputs/{sample}.x.{genome}.vcf",
               sample=SAMPLES, genome=GENOME)

rule uncompress_genome:
    input: "{genome}.fa.gz"
    output: "outputs/{genome}.fa"
    shell: """
        gunzip -c {input} > {output}
    """

rule map_reads:
    input:
        reads="{reads}.fastq.gz",
        ref="outputs/{genome}.fa"
    output: "outputs/{reads}.x.{genome}.sam"
    shell: """
        minimap2 -ax sr {input.ref} {input.reads} > {output}
    """

rule sam_to_bam:
    input: "outputs/{reads}.x.{genome}.sam",
    output: "outputs/{reads}.x.{genome}.bam",
    shell: """
        samtools view -b {input} > {output}
     """

rule sort_bam:
    input: "outputs/{reads}.x.{genome}.bam"
    output: "outputs/{reads}.x.{genome}.bam.sorted"
    shell: """
        samtools sort {input} > {output}
    """

rule index_bam:
    input: "outputs/{reads}.x.{genome}.bam.sorted"
    output: "outputs/{reads}.x.{genome}.bam.sorted.bai"
    shell: """
        samtools index {input}
    """

rule call_variants:
    input:
        ref="outputs/{genome}.fa",
        bam="outputs/{reads}.x.{genome}.bam.sorted",
        bai="outputs/{reads}.x.{genome}.bam.sorted.bai",
    output:
        pileup="outputs/{reads}.x.{genome}.pileup",
        bcf="outputs/{reads}.x.{genome}.bcf",
        vcf="outputs/{reads}.x.{genome}.vcf",
    shell: """
        echo running mpileup
        bcftools mpileup -Ou -f {input.ref} {input.bam} > {output.pileup}
        echo running call
        bcftools call -mv -Ob --ploidy 1 {output.pileup} -o {output.bcf}
        echo running view
        bcftools view {output.bcf} > {output.vcf}
    """
