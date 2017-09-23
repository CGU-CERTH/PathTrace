#!/usr/bin/perl

package CreateMatrix;

#use strict;
#use warnings;

# eg: perl createMatrixPT.pl sequencesFile.parsed geneList genomeList > sequencesFile.matrix

sub create_matrix_pt{

#my $sequencesFile_parsed = shift @ARGV;
#my $geneList = shift @ARGV;
#my $genomeList = shift @ARGV;

open OLDOUT, '>&STDOUT';
open STDOUT, '>', "sequencesFile.matrix";

my $sequencesFile_parsed = $_[0];
my $geneList = $_[1];
my $genomeList = $_[2];

#get genome Ids
my @genomeIds;

my $first = '';
my $second = '';
my $genomeId = '';
my $fourth = '';

open (GENOME_ID_READER, $genomeList);
while (<GENOME_ID_READER>) {
    chomp;
    ($first, $second, $genomeId, $fourth) = split("\t");
    push @genomeIds, $genomeId;
}

close (GENOME_ID_READER);

foreach my $genomeId ( @genomeIds ) {
	print "$genomeId ";
}
print "\n";


#get gene Ids
my @geneIds;


open (GENE_ID_READER, $geneList);
while (<GENE_ID_READER>) {
    chomp;
    (my $geneId) = split(" ");
    push @geneIds, $geneId;
}
close (GENE_ID_READER);

foreach my $geneId ( @geneIds ) {
	print "$geneId ";
    
    open(SEQUENCES_FILE_READER, $sequencesFile_parsed);
    my @seqFileLines = <SEQUENCES_FILE_READER>;
    close SEQUENCES_FILE_READER;
    
    
    foreach my $genomeId ( @genomeIds ) {
        my @tmpGrepRes = grep /$geneId/, @seqFileLines;
        my @matchingLines = grep /$genomeId/, @tmpGrepRes;
        my $numOfLines = scalar @matchingLines;
        print "$numOfLines ";
    }
    
    print "\n";
}

close STDOUT;

open STDOUT, '>&OLDOUT' or die "Can't restore stdout: $!";
close OLDOUT or die "Can't close OLDOUT: $!";
}
1;
