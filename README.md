# PathTrace

PathTrace is an efficient algorithm for parsimony-based reconstructions of the evolutionary history of individual metabolic pathways.

## Requirements
- Perl _(verified to work in v5.24.1)_
  - Requires the `Tree::Simple module` for successful execution.

Compatible with all major Operating Systems (_verified to work with Linux Ubuntu 16.04 LTS and Windows 10_)


## Installing and Running PathTrace on the sample input
1. Download or clone the repository.
2. Go to the directory you cloned (or uncompressed) the application.
3. Run the command:

  `perl pathTrace.pl input/pathTraceInput`


### <a name="BLASTDB"></a> Creating the BLAST-DB

In order to run `pathTrace` with the provided demo data, the BLAST-DB necessary for detecting the homologs must be initially constructed.

The `FASTA` file with all target sequences used in the Case Study are available on **[FigShare here](LINKHERE)**. After downloading and uncompressing the data, the `BLAST`-able database can be constructed with the following command.

`makeblastdb -in PathTrace-Demo-Target.fasta -parse_seqids -dbtype prot -title bacteria_ensembl_DB -out bacteria_ensembl_DB`

The path of the final DB should be listed within the input file of `PathTrace`.

### Description of the Sample input

The demo folder of PathTrace comprises of the following four files:
1. `pathTraceInput`

  This is the main input file, and essentially points to the individual files necessary for a successful `pathTrace` execution, ordered as follows:
  - Query Pathway in `BioPAX` format
  - A file containing the target genomes
  - The `BLAST`-able database that will be used as the basis of the homology
  - A tree (phylogenetic or taxonomic) of the target genomes

  An example of the `pathTrace` input file is the following:

  ```
  input/Sample_Pathway_Lysine_BioPAX_L3.owl
  input/genomeList
  BLAST-DB/bacteria_ensembl_DB
  input/genomeTree.nodes
  ```

  The `BLAST`-able database entry should correspond to the location defined in the previous step (_[Creating the BLAST-DB](BLASTDB)_)

2. `genomeList`

  This is a list of the target genomes, i.e. the genomes against which the inference of presence or absence will be performed. The file has 4 tab-delimited columns that correspond to (a) the incremental number of the genome, (b) the full name of the genome (c) the CoGENT-like code of the genome and (d) the grouping based on common pangenome.

  An example of the `genomeList` input file is the following:

  ```
1  P_abyssi                   PABY-XXX  1
2  P_horikoshii               PHOR-XXX  1
3  S_pneumoniae_70585         SPNE-705  2
4  S_pyogenes_sf370           SPYO-SF3  2
5  B_anthracis_ames_ancestor  BANT-AMA  3
6  B_subtilis                 BSUB-XXX  3
7  B_aphidicola_5a            BAPH-5AX  4
8  B_aphidicola_schizaphis    BAPH-SCH  4
9  E_coli_dh10b               ECOL-DH1  5
10 E_coli_k12                 ECOL-K12  5
```

3. `genomeTree.nodes`

  The tree file format is historical/legacy, and can be easily be converted from a [Newick](https://en.wikipedia.org/wiki/Newick_format) tree format input file; the first column is node name, the second is parent name, and leaf nodes of the tree are marked with the third column with `undef` value in it. The root node does not have a parent and there should obviously be only one root. As an example, see the tree structure below:

  ```
node8                    	                         	      
node0       node8                    	       
PABY-XXX    node0    undef  
PHOR-XXX    node0    undef  
```

4. `Sample_Pathway_Lysine_BioPAX_L3.owl`

  A level-3 BioPAX file, containing the target pathway in the analysis. This can be downloaded directly from [BioCyc](https://biocyc.org/).






_Copyright (c) 2016 CERTH <br>
Author: Fotis E. Psomopoulos <br>
Last edit: 22 September 2017_
