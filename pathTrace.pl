#!/usr/bin/perl

# ToDO List: integrate variable for geneTrace path. Also in populateNode.pm module

# requires 'File::Copy' module
# use strict;
# use warnings;
use CreateMatrix;
use PopulateNodes;
use ProcessNodeFiles;
use File::Copy qw(move);
use File::Copy qw(copy);


# Parameters
my $blast_eValue = 0.000001;
# my $blast_maskValue = 'F';
my $profile_threshold = 0.9;
my $gain = 5;
my $loss = 2;
my $inputFileName = $ARGV[0];


# Input Parameters
#my $bioPaxFile = 'lysine_L3.owl'; #I1a

#my $genomeList = 'genomeList'; #I2a
#my $genomeBlastDB = '../../blast_bacteria_ensembl/bacteria_ensembl_DB'; #I2b
#my $genomeTree = 'genomeTree.nodes'; #I2c
#my $genomeTreeNodes = 8; # to be extracted from I2c #djifos

# Microme Demo
# my $genomeList = 'micromeGenomeList'; #I2a
# my $genomeBlastDB = '../blast_microme/micromeDB'; #I2b
# my $genomeTree = 'micromeTreeNodes.nodes'; #I2c
# my $genomeTreeNodes = 14; # to be extracted from I2c

my $bioPaxFile; #1
my $genomeList; #2
my $genomeBlastDB; #3
my $genomeTree; #4
my $genomeTreeNodes = 0; #extracted from 4th param

open(FH, $inputFileName);
chomp(my @inputParams = <FH>);
close FH;

#read 1st input parameter
my $tmpInputLine = $inputParams[0];
my @tmpVals = split("\t", $tmpInputLine);
$bioPaxFile = $tmpVals[0];

#read 2nd input parameter
my $tmpInputLine = $inputParams[1];
my @tmpVals = split("\t", $tmpInputLine);
$genomeList = $tmpVals[0];

#read 3rd input parameter
my $tmpInputLine = $inputParams[2];
my @tmpVals = split("\t", $tmpInputLine);
$genomeBlastDB = $tmpVals[0];

#read 4th input parameter
my $tmpInputLine = $inputParams[3];
my @tmpVals = split("\t", $tmpInputLine);
$genomeTree = $tmpVals[0];

#read ~5th input parameter
open (FH, $genomeTree) or die "Can't open '$genomeTree': $!";
my @genomeTreeLines = <FH>;
close FH;

my $substr = "node";

foreach my $line (@genomeTreeLines){
	my @tmpVals = split("\t", $line);

	foreach my $str (@tmpVals){
		if(index($str, $substr) != -1){
			$str =~ s/^....//g;
			#print "\n$str\n";
			if($str > $genomeTreeNodes){
				$genomeTreeNodes = $str;
			}
			
		}
	}
}

# Output Parameters
my $pathwayProfiles = 'pathway.profiles';
my $phylogeneticProfiles = 'phylo.profiles';
my $genetraceImg = 'genetrace.jpg';
my $genetraceOut = 'genetrace.output';
my $genetraceGeneImg = 'genetraceGene.jpg';
my $genetraceGeneOut = 'genetraceGene.output';

# Internal Parameters
my $pathwayName = `java -jar BiopaxClient.jar -n $bioPaxFile`;
open(FH, $genomeList);
my @numGenomesLines = <FH>;
close FH;
my $numGenomes = $#numGenomesLines +1;

my $outputDir = 'output';
if(-e $outputDir){
    print "$outputDir directory already exists...\n";
}
elsif(!(mkdir $outputDir)) {
    die "Unable to create $outputDir\n";
}

# STEP 1: Run biopax parser and extract gene/protein sequences -> internal files 'sequencesFile.fasta' and 'geneList'
print "STEP 1\n======\n";
my $javaParser = `java -jar BiopaxClient.jar -g $bioPaxFile sequencesFile.fasta`;
my $geneListGrep = `java -jar BiopaxClient.jar -i $bioPaxFile geneList`;


#---------------------------------Change Shell to Perl------------------------------------

# STEP 2: Run BLAST -> internal file 'sequencesFile.blastp';
print "STEP 3\n======\n";
my $blastRun = `blastp -db $genomeBlastDB -query sequencesFile.fasta -evalue $blast_eValue -outfmt 6 -out sequencesFile.blastp`;


# STEP 3: Construct matrix -> internal file 'sequencesFile.matrix'
print "STEP 5\n======\n";
CreateMatrix::create_matrix_pt("sequencesFile.blastp", "geneList", $genomeList);

# STEP 4: Store matrix into an array (@matrixData)
print "STEP 6\n======\n";
my @matrixData;
open(matrixData, "<sequencesFile.matrix") || die "Can't open file: $!\n";
while (<matrixData>)
{
	chomp;
	my @row =  split(/\s+/, $_);
	push(@matrixData, \@row);
}

# TO-Remove: Print array
print "STEP 6 (following to be removed)\n======\n";
foreach my $row (@matrixData) {
	foreach my $element (@$row) {
		print "$element ";
	}
	print "\n";
}

# STEP 5: Convert matrix to protein phylogenetic profiles (@ppData)
print "STEP 7\n======\n";
my $numRows = scalar @matrixData;
my $numCols = $numGenomes;
my @ppData;
# print "numRows = $numRows \n";
# print "numCols = $numCols \n";
foreach my $i ( 1 .. $numRows-1 ) {
        foreach my $j ( 1 .. $numCols ) {
		if ($matrixData[$i][$j] > 0) {
			$ppData[$i][$j] = 1;
		} else {
			$ppData[$i][$j] = 0;
		}
        }
}

# TO-Remove: Print phylogenetic profiles
print "STEP 7 (following to be removed)\n======\n";
foreach my $row (@ppData) {
	foreach my $element (@$row) {
		print "$element ";
	}
	print "\n";
}

# STEP 6: Print phylogenetic profiles -> Use output parameter $phylogeneticProfiles
print "STEP 8\n======\n";
open(FH, "+>temp") || die "Can't open temp: $!";
# print FH $pathwayName;
foreach my $i ( 1 .. $numRows-1 ) {
        foreach my $j ( 1 .. $numCols ) {
		print FH "$ppData[$i][$j] ";
        }
	print FH "\n";
}
close FH;


#my $mergeFiles = `paste geneList temp > $phylogeneticProfiles`;
my $geneListFile = "geneList";
my $tempFile = "temp";

open(FH, $geneListFile);
my @geneListFileLines = <FH>;
close FH;
open(FH, $tempFile);
my @tempFileLines = <FH>;
close FH;

my @phyloProfilesOutput;

my $lineIdx = 0;

foreach my $line (@geneListFileLines){
    
    $line =~ s/\r|\n//g;
    $phyloProfilesOutput[$lineIdx] = "$line\t$tempFileLines[$lineIdx]";
    
    $lineIdx++;
}

open FH, "> $phylogeneticProfiles" or die "can't open '$phylogeneticProfiles': $!";
foreach ( @phyloProfilesOutput )
{
    print FH $_;
}
close FH;


#my $removeTemp = `rm temp`;
unlink $tempFile;


# STEP 7: Construct the pathway profile -> Mean per column (sum and division)
print "STEP 9\n======\n";
my @sums;
foreach my $j ( 1 .. $numCols ) {
	foreach my $i ( 1 .. $numRows ) {
		$sums[$j] += $matrixData[$i][$j];
	}
	$sums[$j] = $sums[$j] / ($numRows - 1);
}

# TO-Remove: Print profile
print "STEP 9 (following to be removed)\n======\n";
print join(", ", @sums);
print "\n";

# STEP 8: Digitize the profile -> decimal to binary. Use parameter $profile_threshold
print "STEP 10\n=======\n";
foreach my $i ( 1 .. $numCols ) {
	if ($sums[$i] >= $profile_threshold) {
		$sums[$i] = 1;
	} else {
		$sums[$i] = 0;
	}
}
# TO-Remove: Print profile
print "STEP 10 (following to be removed)\n======\n";
print join(", ", @sums);
print "\n";

# STEP 9: Print pathway profile -> Use output parameter $pathwayProfiles
print "STEP 11\n=======\n";
open(FH, "+>$pathwayProfiles") || die "Can't open $pathwayProfiles: $!";
print FH $pathwayName;
foreach ( @sums )
{
    
    print FH " $_";
}
print FH "\n";
close FH;

# STEP 10: Run genetrace with custom parameters using pathway profiles -> intermediate file geneTraceGenomeList
print "STEP 12\n=======\n";
#system ( " awk -F '\t' '{print \$1\"\\t\"\$3}' $genomeList > geneTraceGenomeList" );

my @geneTraceGenomeListArray;

open (FH, $genomeList);
my @tmpGenomeListArray = <FH>;

foreach my $line (@tmpGenomeListArray){

    my @values = split("\t", $line);
    my $tmpLine = "$values[0]\t$values[2]\n";
    push @geneTraceGenomeListArray, $tmpLine;

}


my $geneTraceGenomeListFile = "geneTraceGenomeList";

open FH, "> $geneTraceGenomeListFile" or die "can't open '$geneTraceGenomeListFile': $!";
foreach my $line ( @geneTraceGenomeListArray )
{
    print FH $line;
}
close FH;

my $geneTraceRun = `perl ./geneTrace/geneTrace.pl $pathwayProfiles geneTraceGenomeList $genomeTree -all -gain $gain -loss $loss -img $genetraceImg > $genetraceOut`;


# STEP 11: Run populateNodes script for analysing pathway-per-Node content
print "STEP 13\n=======\n";
PopulateNodes::populate_nodes($pathwayProfiles, "geneTraceGenomeList", $genomeTree, $genomeTreeNodes, $gain, $loss, $genetraceImg, "NodePathway");

# STEP 12: Run processNodes script to generate gains and losses lists (may be removed as step later on)
print "STEP 14\n=======\n";

my $prNFSource = "ProcessNodeFiles.pm";
my $prNFDest = "NodePathway/ProcessNodeFiles.pm";
copy $prNFSource, $prNFDest;# or die "Failed to copy $$prNFSource: $!\n";

my $tmpPrNFiles = "NodePathway/ProcessNodeFiles.pm";
chdir('NodePathway/') or die "$!";

ProcessNodeFiles::process_node_files("../$genomeTree");


my $glSource = "gainLosses.output";
my $glDest = "../gainLosses.output";
move $glSource, $glDest;

my $tmpPrNFile = "ProcessNodeFiles.pm";
unlink $tmpPrNFile;

chdir('..') or die "$!";

# STEP 13: Run genetrace for gene profiles -> using intermediate file geneTraceGenomeList from STEP 10
print "STEP 15\n=======\n";
my $geneTraceGeneRun = `perl geneTrace/geneTrace.pl $phylogeneticProfiles geneTraceGenomeList $genomeTree -all -img $genetraceGeneImg > $genetraceGeneOut`;


# STEP 14: Run populateNodes script for analysing pathway-per-Node content
print "STEP 16\n=======\n";
PopulateNodes::populate_nodes($phylogeneticProfiles, "geneTraceGenomeList", $genomeTree, $genomeTreeNodes, 2, 4, $genetraceGeneImg, "NodeGene");

# STEP 15: Construct BioPax files (one per node)
print "STEP 17\n=======\n";
my $constrBioPax = `java -jar BiopaxClient.jar -apgn $bioPaxFile NodePathway/ NodeGene/`;

# STEP 16: Cleanup
print "STEP 18\n=======\n";
my $tmpCleanupDir = "output/BlastOutput";
if(-e $tmpCleanupDir){
    print "$tmpCleanupDir directory already exists...\n";
}
elsif(!(mkdir $tmpCleanupDir)) {
    die "Unable to create $tmpCleanupDir\n";
}

$tmpCleanupDir = "output/Profiles";
if(-e $tmpCleanupDir){
    print "$tmpCleanupDir directory already exists...\n";
}
elsif(!(mkdir $tmpCleanupDir)) {
    die "Unable to create $tmpCleanupDir\n";
}

$tmpCleanupDir = "output/Images";
if(-e $tmpCleanupDir){
    print "$tmpCleanupDir directory already exists...\n";
}
elsif(!(mkdir $tmpCleanupDir)) {
    die "Unable to create $tmpCleanupDir\n";
}

$tmpCleanupDir = "output/IntermediateFiles";
if(-e $tmpCleanupDir){
    print "$tmpCleanupDir directory already exists...\n";
}
elsif(!(mkdir $tmpCleanupDir)) {
    die "Unable to create $tmpCleanupDir\n";
}

$tmpCleanupDir = "output/GeneTraceFiles";
if(-e $tmpCleanupDir){
    print "$tmpCleanupDir directory already exists...\n";
}
elsif(!(mkdir $tmpCleanupDir)) {
    die "Unable to create $tmpCleanupDir\n";
}

my $old_loc = "sequencesFile.*";
my $arc_dir = "output/BlastOutput/";

for my $file (glob $old_loc) {
    move ($file, $arc_dir) or die $!;
}

$old_loc = "*.profiles";
$arc_dir = "output/Profiles/";

for my $file (glob $old_loc) {
    move ($file, $arc_dir) or die $!;
}

$old_loc = "*.jpg";
$arc_dir = "output/Images/";

for my $file (glob $old_loc) {
    move ($file, $arc_dir) or die $!;
}

my $nodeGeneDir = 'output/NodeGene/';
if(-e $nodeGeneDir){
    print "$nodeGeneDir directory already exists...\n";
}
elsif(!(mkdir $nodeGeneDir)) {
    die "Unable to create $nodeGeneDir\n";
}

$old_loc = "NodeGene/*";
$arc_dir = "output/NodeGene/";

for my $file (glob $old_loc) {
    move ($file, $arc_dir) or die $!;
}
my $nodeGeneDir = "NodeGene";
rmdir $nodeGeneDir;

my $nodePathDir = 'output/NodePathway/';
if(-e $nodePathDir){
    print "$nodePathDir directory already exists...\n";
}
elsif(!(mkdir $nodePathDir)) {
    die "Unable to create $nodePathDir\n";
}

$old_loc = "NodePathway/*";
$arc_dir = "output/NodePathway/";

for my $file (glob $old_loc) {
    move ($file, $arc_dir) or die $!;
}
my $nodePathDir = "NodePathway";
rmdir $nodePathDir;

move "genetrace.populateNodes.output", "output/GeneTraceFiles/";
move "geneTraceGenomeList", "output/GeneTraceFiles/";
move $genetraceOut, "output/GeneTraceFiles/";
move $genetraceGeneOut, "output/GeneTraceFiles/";
move "geneList", "output/IntermediateFiles/";
move "gainLosses.output", "output/IntermediateFiles/";

print "Process finished successfully!\n\n";
