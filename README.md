# CDpan: Constructing dispensable genome for pan-genome analysis

## Introduction

There is an increasing understanding that a reference sequence representing a genome of individual is insufficient to capture the genomic diversity we observe in nature. With the development of short-reads sequencing, it's convenient to achieve the high depth whole-genome sequencing data of an individual. Therefore, to help the researchers to capture the genomic sequences absent in the reference genome within the species, we propose the CDpan (Constructing dispensable genome for pan-genome analysis) to construct the dispensable genome using high-throughput sequencing reads.

## Installation

Download from project homepage, <https://github.com/kimi-du-bio/CDpan>, or check out the code using Git from <https://github.com/kimi-du-bio/CDpan.git>.

### Dependencies

CDpan required Perl version 5.16 or above and Python version 3.6+ to run. Only Linux is supported (May or may not run under Perl for MacOS or Windows, etc).

CDpan uses three Perl modules, ```Bio::SeqIO```, ```Config::IniFiles``` and ```File::Slurp```, which may be not installed by default configuration of perl, you can install them as follows:

```Bash
cpan -i Bio::SeqIO Config::IniFiles File::Slurp
```

Using CDpan requires the following tools to be installed:

- [TrimGalore](https://github.com/FelixKrueger/TrimGalore)
- [Cutadapt](https://github.com/marcelm/cutadapt)
- [FastQC](https://github.com/s-andrews/FastQC)
- [BWA](https://github.com/lh3/bwa)
- [GATK](https://github.com/broadinstitute/gatk)
- [samtools](https://github.com/samtools/samtools)
- [MaSuRCA 3.x](https://github.com/alekseyzimin/masurca) (Not compatible with MaSuRCA 4.0 or above)
- [centrifuge](https://github.com/DaehwanKimLab/centrifuge)
- [MMseqs2](https://github.com/soedinglab/MMseqs2)
- [mummer](https://github.com/mummer4/mummer)
- [RepeatMasker](https://github.com/rmhubley/RepeatMasker)
- [Bowtie2](https://github.com/BenLangmead/bowtie2)
- [bedtools](https://github.com/arq5x/bedtools2)
- [minimap2](https://github.com/lh3/minimap2)

CDpan has been tested on the following environment: `Perl v5.34`, `Python 3.9.6`, `TrimGalore v0.6.7`, `Cutadapt v3.4`, `FastQC v0.11.9`, `BWA v0.7.17`, `GATK v4.2.1.0`, `samtools v1.13`, `MaSuRCA v3.4.2`, `centrifuge v1.0.4`, `MMseqs2 v13`, `mummer v4.0.0`, `RepeatMasker v4.1.2`, `Bowtie2 v2.4.4`, `bedtools v2.30.0`, `minimap2 v2.22`. It may run on any other version of most tools except the MaSuRCA 4.0+.

### Quick Start Guide

<!--TODO: Complete download link-->

CDpan is out of the box. You can acquire the latest version from the [release page](https://github.com/kimi-du-bio/CDpan/releases) with:

```Bash
curl -fsSL https://github.com/kimi-du-bio/CDpan/xxx -o cdpan.tar.gz
tar xvzf cdpan.tar.gz
./cdpan/bin/cdpan -v
```

If you see the version message, the program has been installed successfully.

For convenient use, you can add `./cdpan/bin/` to the `PATH`, or establish a soft connection of `./cdpan/bin/cdpan` in the `PATH`. For example:

```Bash
echo 'export PATH=$HOME/cdpan/bin/:$PATH' >> ~/.bashrc
# or
ln -s $HOME/cdpan/bin/cdpan ~/.local/bin/cdpan
```

### Running CDpan

Run CDpan from the command line like this:

**Usage:** ```cdpan <module> -i input_dir [options]```

The main input of the program is a directory which deposited the fastq(fastq.gz) file of the paired-end sequencing reads.

The main output of the program is a fasta file containing the sequences of the constructed dispensable genome and the predicted inserted location of the new sequences relative to the reference genome.

To use CDpan, you need to specify a module and support the `input_dir`. Please refer to the [Usage](#usage) section to get the detailed information of the module contained in the CDpan. The introduction of `input_dir` please refer to the following [Usage](#usage) section.

## Usage

### General usage

```Bash
cdpan RUN-ALL -i input_dir -c config_file
```

#### input directory

The `input_dir` is a directory which you archive your sequencing data. Each sub-directory of the input directory should be named by the id of a separate sample and this sub-directory should include all the sequencing data of the sample. The sequencing data must be the paired-end reads. The directory format may be like this:

```sh
Data
|
|---sample1---|---*_1.fastq (fq, fastq.gz, fq.gz)
              |---*_2.fastq (fq, fastq.gz, fq.gz)
|---sample2---|---*_1.fastq (fq, fastq.gz, fq.gz)
              |---*_2.fastq (fq, fastq.gz, fq.gz)
...
|---sampleN---|---*_1.fastq (fq, fastq.gz, fq.gz)
              |---*_2.fastq (fq, fastq.gz, fq.gz)
```

#### config file

The `config_file` is a variant of .ini-style config file and a config file example can be found in the [example.ini](examples/example.ini). You can change this file to suit your practical circumstance. The detailed described of config file, please refer to the [Config file](#config-file) section.

#### output

This program produces a fasta file containing the sequences of the constructed dispensable genome and the txt file for the predicted inserted location.

#### only sequences

If you only interested in the DNA sequences absent in the reference genome but present within the species, you can use the following command:

```Bash
cdpan RUN-DIEM -i input_dir -c config_file
```

The output is only the fasta file containing the new DNA sequences.

## Full list of options for CDpan

Flexible and customizable new DNA sequences detection for advanced users.

**Usage:** ```cdpan <module> -i input_dir [options]```

**Note:** Before running the following module, we recommend to first set the `config_file`. Every module in CDpan use the same `config_file`. The detailed information of the `config_file` can be found in the [Config file](#config-file) section.

### General Options

Command line parameters are consistent for all modules. General options include:

- -h, --help
  - Print help message and exits.
- -v, --version
  - Print version message and exits.
- -i, --input
  - Path of input directory. Each sub-directory of the input directory should be named by the id of a separate sample and this sub-directory should include all the sequencing data of the sample. The sequencing data must be the paired-end reads.
  - Mandatory
- -c, --config
  - Path of config file, which is a variant of .ini-style config file. The detailed described of config file, please refer to the [Config file](#config-file) section.
  - Required by module align, mope, soot, location, RUN-DIEM and RUN-ALL.
- -o, --output
  - Prefix of the output file
  - Default: name of input directory
- -O, --output_dir
  - Output directory
  - Default: current directory
- -w, --work_dir
  - Path of work directory. Work directory is used to store process files, the directory should not exist or be empty.
  - Default: ${output_dir}/cdpan_tmp
- -l, --output-level [012]
  - Level of detail of the output. Optional values include 0, 1, and 2. When output-level is set to 0, only the result file will be output. When it is set to 1, the result file, key process files and partial process logs will be saved. When it is set to 2, the result file and all process files will be saved.
  - **Warning:** When output-level is set to 2, a very large number of process files may be generated and occupy a large amount of hard disk space. We recommend using it during debugging.
  - Default: 0
- --no-qc [01]
  - no quality control. You can do the quality control using other software.
  - Bool. 0 is False and 1 is True.
  - Default: False

### Specific Module

#### RUN-ALL

Module `RUN-ALL` executes `module`, `filter`, `align`, `extract`, `assembly`, `mope`, `vot`, `soot`, `merge` and `location` sequentially.

#### RUN-DIEM

Module `RUN-DIEM` executes `module`, `filter`, `align`, `extract`, `assembly`, `mope`, `vot`, `soot` and `merge` sequentially.

#### Pre-processing

```bash
cdpan filter -i input_dir -c config_file
```

The input directory is the same format as the [General usage](#general-usage). This module is used to filter the low quality reads. You can do the quality control using other software and run the following processes.

#### Alignment

```bash
cdpan align -i input_dir -c config_file
```

The input directory is the same format as the [General usage](#general-usage). If you use the CDpan to do the pre-processing procedure, the input directory is the output directory of the pre-processing.

Of course, you can use the clean data which processed by yourself, just provide the data deposited directory to the input directory. If you do that, the input directory should be like:

```sh
Data
|
|---sample1---|---sample1_clean_1.fq.gz
              |---sample1_clean_2.fq.gz
|---sample2---|---sample2_clean_1.fq.gz
              |---sample2_clean_2.fq.gz
...
|---sampleN---|---sampleN_clean_1.fq.gz
              |---sampleN_clean_2.fq.gz
```

This module is used to align the sequencing reads to the reference genome.

#### Extract the unmapped reads

```bash
cdpan extract -i input_dir -c config_file
```

The input directory is the output directory of the alignment process. This step is used to extract the ummaped reads from the aligned results.

#### Assembly

```bash
cdpan assembly -i input_dir -c config_file
```

The input directory is the output directory of the previous process. This step is used to assemble the unmmaped reads of each individual.

#### Remove the contaminants

```bash
cdpan mope -i input_dir -c config_file
```

The input directory is the output directory of the assembly process. This step is used to remove the contaminants sequences in the assembled results.

#### Remove the redundants

```bash
cdpan vot -i input_dir -c config_file
```

The input directory is the output directory after the module "mpope" running. This step is used to remove the redundants sequences in the assembled results.

#### Retained the new DNA sequences

```bash
cdpan soot -i input_dir -c config_file
```

The input directory is the output directory of the "vot" process. This step is used to keep the absent sequences of the reference genome in the assembled results.

#### Final dispensable genome

```bash
cdpan merge -i input_dir -c config_file
```

The input directory is the output directory of the "soot" process. This step is used to integrated the new DNA sequences of all individuals and construct the final dispensable genome. The output is a fasta file.

#### Location

```bash
cdpan location -i input_dir -c config_file
```

The input directory is the output directory of the "merge" process. This step is used to determine the genomic positions of new DNA sequences relative to the reference genome. The output of this step is a txt file.

If you wish to run the module `location` separately, you should also supply the output directory of the "extract" and "vot" process.

## Config file

Config file is a variant of .ini-style config file and the only difference is that CDpan only accepts the comment guided by '#' but not ';'.

The following is a example of the config file, you can also find this file in the [example.ini](examples/example.ini):

```ini
# This part definite the threads used in the pipeline

[CDPAN]
thread = 1

# This part definite the path of the dependency software
# If you make sure that all tools are located in the PATH, you don’t need to set this
[TOOLS]
trim_galore        = /usr/bin/trim_galore
cutadapt           = /usr/bin/cutadapt
fastqc             = /usr/bin/fastqc
bwa                = /usr/bin/bwa
gatk               = /usr/bin/gatk
samtools           = /usr/bin/samtools
masurca            = /usr/bin/masurca
centrifuge         = /usr/bin/centrifuge
centrifuge-kreport = /usr/bin/centrifuge-kreport
mmseqs             = /usr/bin/mmseqs
nucmer             = /usr/bin/nucmer
show-coords        = /usr/bin/show-coords
RepeatMasker       = /usr/bin/RepeatMasker
bowtie2            = /usr/bin/bowtie2
bedrooms           = /usr/bin/bedrooms
bowtie2-build      = /usr/bin/bowtie2-build

# This section definites the required file
[DATA]
## The reference genome file, must be .fasta or .fa format
ref = *.fasta
## The NCBI nucleotide non-redundant index, download from <https://genome-idx.s3.amazonaws.com/centrifuge/nt_2018_3_3.tar.gz>
nt_index =
## The file contained the NCBI taxid which you want to keep, just one colunm. We supply a example file contained all liliopsida taxid in the <https://github.com/kimi-du-bio/CDpan/examples/Liliopsida.taxid>.
taxid =

# The parameter of pre-processing.
[FILTER]
## The minimum Phred score
quality = 20
## The minimum length of reads after quality and adapter trimming
length = 20
## Maximum allowed error rate
error-rate = 0.1

[ALIGN]
library = ILLUMINA

# The parameter of assembly.
[ASSEMBLY]
## The fragment mean of paired-end reads
fragment-mean = 300
## The fragment standard deviation of paired-end reads
fragment-stdev=50
## jellyfish hash size, set this to about 10x the genome size
JF_SIZE = 2000000000

# The parameter of mope module.
[MOPE]
## The NCBI taxid of your research species
host-taxids =
## The minmum length of new DNA sequences
min-length = 1000

# The parameter of vot module (we recommend to only just change the "min-seq-id" parameter).
[VOT]
cov-mode = 1
coverage = 0.9
## The ratio of length overlap for two sequences
min-seq-id = 0.9
cluster-mode = 2

# The parameter of soot module
[SOOT]
## The maximum gap between two adjacent matches in a cluster
maxgap = 1000
## The minimum length of a cluster of matches
mincluster = 90
## The minimum length of a single exact match
minmatch = 500

[LOCATION]
## Specify the species or clade of the input sequence. The species name must be a valid NCBI Taxonomy Database species name.
species =
```

## Output file

This program produces a fasta file containing the sequences of the constructed dispensable genome and the txt file for the predicted inserted location.

The txt file contains a file header guided by '##', which describes the format of this file. Followed by specific information of the predicted inserted location, one row per contig and one column per sample.

## Example file

We also provide a example script and partial necessary file in the [examples](examples). To run the script, you need to install all tools required by CDpan and prepare the input file and the NCBI nucleotide non-redundant index file (download from <https://genome-idx.s3.amazonaws.com/centrifuge/nt_2018_3_3.tar.gz>). You may also need to adjust some parameters, such as paths of tools and files.

The input file used by this script is the example data of [EUPAN](https://github.com/doodlehzq/EUPAN) and you can get it from <https://cgm.sjtu.edu.cn/eupan/example_data/eupanExample.tar.gz>.

<!--
## Features to be added

- [ ] Use perl language to rewrite compare.py
- [x] Log
- [ ] Almost all parameters could be imported using the parameter card
- [ ] Safer file path handling
- [ ] Allows to import reference genomes that already have dictionary and index
- [x] no quality control
-->

## Question

1. How to get the taxid required in the contig file?

>The taxid file contained the all NCBI taxids which Phylum, Class or Order that your studied species belongs to. We recommednd to use the taxonkit software to get the taxids. For example, the NCBI taxids of all Chordata can be obtained just run: taxonkit list 7711.
