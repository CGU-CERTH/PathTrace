#!/usr/bin/perl

package PopulateNodes;
#use strict;
#use warnings;

# First input: Profile file for GeneTrace
# Second input: Genome list file for GeneTrace
# Third input: Node tree file for GeneTrace
# Forth input: number of intermediate nodes from the GeneTrace graph
# Fifth input: gain parameter for GeneTrace
# Sixth input: loss parameter for GeneTrace
# Seventh input: image name for GeneTraceOutput
# Eigth input: directory name for the Node files

# eg perl populateNodes.pl pathway.profiles geneTraceGenomeList genomeTree.nodes 8 5 2 genetrace.jpg NodePathway

sub populate_nodes{

my @args;

my $num_args = 8;
for(my $i = 0; $i < $num_args; $i++) {
        my $tmpArg = $_[$i];
	push @args, $tmpArg;
}


if(-e $args[7]){
    print "$args[7] directory already exists...\n";
}
elsif(!(mkdir $args[7])) {
   die "Unable to create $args[7]\n";
}


print "Running Full geneTrace\n";


my @sysargs_1 = `perl ./geneTrace/geneTrace.pl $args[0] $args[1] $args[2] -all -gain $args[4] -loss $args[5] -img $args[6] > genetrace.populateNodes.output`;
system(@sysargs_1);

print "Starting populating nodes\n";


for(my $id = 0; $id <= $args[3]; $id++) {
    print "Running Node$id...\n";
    my @sysargs_2 = `perl ./geneTrace/geneTrace.pl $args[0] $args[1] $args[2] -gain $args[4] -loss $args[5] -node node$id > $args[7]/node$id.node`;
    system(@sysargs_2);
}

my @genomeIds;
my $first = '';
my $genomeId= '';

open (GENOME_ID_READER, $args[1]);
while (<GENOME_ID_READER>) {
    chomp;
    ($first, $genomeId) = split("\t");
    push @genomeIds, $genomeId;
}
close (GENOME_ID_READER);


foreach my $taxaID (@genomeIds){
    print "Running $taxaID...\n";
    my @sysargs_3 = `perl ./geneTrace/geneTrace.pl $args[0] $args[1] $args[2] -gain $args[4] -loss $args[5] -node $taxaID > $args[7]/$taxaID.node`;
    system(@sysargs_3);
}

print "Finished populating nodes\n";

}
1;
