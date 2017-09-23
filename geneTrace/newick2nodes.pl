#!/sw/arch/bin/perl -w

$| = 1;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=- Modules -=-=-=-=-=-=-=-=-=

use strict;

use lib "geneTrace/";
use tree::simple;
use tree::newick;

#-=-=-==-=-=-=-=-=-=-== Constants & Parameters -=-=-=-=-=-

my ($treeFile,  $outFile) = @ARGV;

unless ($treeFile && $outFile)
{
    die "USAGE:
$0 NewicktreeFile nodeTreeFile
";
}

#--=-=-=-=-=-=-=-=-=-=-=-=- Main Flow -=-==-=--=-=-=-=-=-

my $tree = &newTree();
$tree = &readNewickTreeFile($treeFile);
&findLeafs($tree);

my @nodes = keys %{$tree->{nodesHash}};
my $node;

# Mark all leafs that should be kept
# by species name
foreach $node (@nodes)
{
    if (&isLeaf ($tree, $node))
    {
	&setNodePresence ($tree, $node, 'undef');
    }
}

&printTree ($tree, $tree->{root}, $outFile);
