#!/sw/arch/bin/perl -w

$| = 1;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=- modules -=-=-=-=-=-=-=-=-=-=-=-=-

use strict;

use lib "geneTrace/";
use tree::all;
use tree::readPhylProfile;
use tree::restoreTree;
use tree::bootstrap;

#-=-=-=-=-=-=-=-=-=-=-=-=-=-  Reading Input  -=-=-=-==-=-=-=-=-=--

my $USAGE = "
USAGE:
$0 Phyl_profFile org2NumbersFile treeFile <parameters>

* The files should be specified in the correct order
* The mode of the program must be set by one of the parametes
  (either \"all\", \"org\", \"node\", or \"family\")

Optional parameters
-ignore <fileName> - org2NumbersFile of species that should
                     not be considered for tree construction.
-img <fileName>    - a file name to for a graphical image file
                     For \'all\' and \'family\' modes only.
-family <familyId> - investigate only given family
-j <number>        - number of jacknife trials (for single family
                     or node modes only); default is 100
-pro <fileName>    - output phylogenetic profiles for each node to
                     a files fileName.profiles and fileName.organisms

See Readme for more information

--\a
";

my @ARGVcpy = @ARGV;

# read obligatory parameters:
my $Phyl_profFile = shift @ARGV;
my $organismsListFile = shift @ARGV;
my $treeFile = shift @ARGV;

# read optional parameters
my $param;
my ($imgFile, $mode, $family2search, $org, $org2NumbersIgnoreFile, $nodeToReport, $outputProfilesFile);
my $JecknifeIterNumber = -1;
my $gainThreshold = 2;
my $lossThreshold = 4;


while ($param = shift @ARGV)
{
    if ($param eq "-img")
    {
	$imgFile = shift @ARGV;
    }
#    if ($param eq "-mode")
#    { $mode = shift @ARGV;}
    elsif ($param eq "-all")
    { $mode = "all";}
    elsif ($param eq "-family")
    {
	$mode = "family";
	$family2search = shift @ARGV;
    }
    elsif ($param eq "-org")
    {
	$mode = "org";
	$org  = shift @ARGV;
    }
    elsif ($param eq "-ignore")
    {	$org2NumbersIgnoreFile = shift @ARGV;    }
    elsif ($param eq "-node")
    {
	$mode = "node";
	$nodeToReport = shift @ARGV;
    }
    elsif ($param eq "-j")
    {   $JecknifeIterNumber = shift @ARGV;    }
    elsif ($param eq "-pro")
    {   $outputProfilesFile = shift @ARGV;    }
    elsif ($param eq "-gain")
    {   $gainThreshold = shift @ARGV;    }
    elsif ($param eq "-loss")
    {   $lossThreshold = shift @ARGV;    }
    else
    {
	die $USAGE . "ERROR: Unknown argument $param or wrong number of parameters.\n\n";
    }
}

#-=-=-=-=-=-=-=-=-=--=-=- check validity of the input =-=-=-=-=-=-=--=-=-=

unless ($mode)
{
    die $USAGE . "ERROR: Mode is not specified\n";
}

unless ($Phyl_profFile && $organismsListFile && $Phyl_profFile)
{
    die $USAGE;
}

unless (-e $Phyl_profFile && -e $organismsListFile && -e $Phyl_profFile)
{
    die $USAGE . "ERROR: one of the input files does not exists\n\n";
}

if ($JecknifeIterNumber ne -1)
{
    unless ($mode eq "family" || $mode eq "node")
    {
	die $USAGE . "ERROR: Jecknife iterations are allowed only in the family mode or node mode.\nSee Readme for details\n";
    }
}

if ($mode eq "family" || $mode eq "node")
{
    if ($JecknifeIterNumber == -1)
    { $JecknifeIterNumber = 100;}
}

if ($outputProfilesFile)
{
    unless ($mode eq "all")
    {
	die $USAGE . "ERROR: Profiles file is output only in the \"all\" mode - see readme for details\n";
    }
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-  Constants  & Global hashes -=-=-=-==-=-=-=-=-=--

my $yes = 'yes'; # the marker of gene presence - don't change
my $not = 'not'; # the marker of gene absence - don't change

my $total;     # number of analyzed families
my $lossesNum = 0;

my %gainsNumHash;
my %genesHash;

# organisms to ignore:
my $noUseOrgsNum = 0;
my %noUseOrgsHash;
my $noUseOrgsHashRef = \%noUseOrgsHash;

my %evolPath; # for the org mode the evolutionary path of the organism

#-=-=-=-=-=-=-=-=-=-=-=-=-=- Main flow -=-=-=-=-=-=-=-=-=--


#-=-=-=-=-=-=-=-=-=-=-=-=-=- Read trees -=-=-=-=-=-=-=-=-=-

# initiate trees
my $runningTree = &newTree();
&readTree($runningTree, $treeFile);
my $finalTree;

unless ($mode eq "family")
{
    $finalTree   = &newTree();
    &readTree($finalTree, $treeFile);
}

# Initiate organisms hashes:
my ($num2orgHashRef, $orgsNum) = &setOrgNums($organismsListFile);
my %num2orgHash = %{$num2orgHashRef};

if ($org2NumbersIgnoreFile)
{
    ($noUseOrgsHashRef, $noUseOrgsNum) = &setOrgNums($org2NumbersIgnoreFile);
    %noUseOrgsHash = %{$noUseOrgsHashRef};
}




#-=-=-=-=-=-=-=-=-=-=-- Run reconstuction -=-=-=-=-=-=-=-=-=-=-=-=--=


# For a single family mode:
if ($mode eq "family")
{
    my $line;
    my $familyFound =0; # used for family mode only - turns to 1 when family is found
    open (PHYL, $Phyl_profFile) || die "ERROR: can't open $Phyl_profFile\n";
    while ($line = <PHYL>)
    {
	if ($line =~ /(\d+)\s+/)
	{
	    if ($1 eq $family2search)
	    {
		$familyFound = 1;
		last;
	    }
	}
    }

    unless($familyFound)
    {
	die "Error: couldn't find family $family2search\n";
    }

    my ($familyNum, $assigned) = &assign_PHYL_pattern($runningTree, $line, $num2orgHashRef, $noUseOrgsHashRef);

    close PHYL;
    &assignPenalties($runningTree, $runningTree->{root}, $gainThreshold, $lossThreshold);
    &decisions_decisions($runningTree, $runningTree->{root}, $not, $gainThreshold, $lossThreshold);
    my ($gainsRef, $lossesRef) = &findEvolChanges ($runningTree);
    &bootstrap($runningTree, $treeFile, $JecknifeIterNumber, $line, $num2orgHashRef, $noUseOrgsHashRef, $gainThreshold, $lossThreshold);

    print "Node\tJacknife\n";
    foreach my $genome (keys %{$runningTree->{nodesHash}})
    {
	unless (&isLeaf($runningTree, $genome))
	{
	    my $node = &getNode ($runningTree, $genome);
	    print $genome, "\t", $node->{totalGenes}, "\n";
	}
    }

    print "\n------\n\n";
    if ($imgFile)
    {
	@ARGV = @ARGVcpy;
	&drawTree($runningTree, $imgFile);
    }
    else
    {
	print STDERR "Image file not specified: no tree drawn\n\n-----\n\n";
    }
    my @gains = @{$gainsRef};
    my @losses = @{$lossesRef};

    my $event;
    print "Statistics: \n";
    print "Acquisions: ";
    foreach $event (@gains){ print $event . ", ";}
    print "\nLosses: ";
    foreach $event (@losses){ print $event . ", ";}
    print "\n";

    print STDERR "Done\n";
    exit;
}


#-=-=-=-=--=-=-=- multiple families mode:

# specify the evolutionary path for the 'org' mode
if ($org)
{
    print "Family\tGains events\n";
    my $runningNode = $org;
    while (1)
    {
	my $node = &getNode ($runningTree, $runningNode);
	unless ($node)    {	die "ERROR: can't get node \'$node\'\n";    }
	$evolPath{$runningNode} = 1;
	if ($runningNode eq $runningTree->{root}){last;}
	my $father = $node->{parent};
	$runningNode = $father;
    }
}

if ($nodeToReport)
{
    print "Family\tConfidence\n";
}

# run reconstruction of families, one by one
open (PHYL, $Phyl_profFile) || die "ERROR: can't open $Phyl_profFile\n";
while (my $line = <PHYL>)
{
    my ($familyNum, $assigned) = &assign_PHYL_pattern($runningTree, $line, $num2orgHashRef, $noUseOrgsHashRef);

    unless ($assigned > 1){ next;}

    if ($mode eq "org")
    {
	my $orgPresence = &showNodePresence($runningTree, $org);
	unless ($orgPresence eq $yes)
	{
	    next;
	}
    }

    $total++;
    &assignPenalties($runningTree, $runningTree->{root}, $gainThreshold, $lossThreshold );
    &decisions_decisions($runningTree, $runningTree->{root}, $not, $gainThreshold, $lossThreshold);
    my ($gainsRef, $lossesRef) = &findEvolChanges ($runningTree);

    my %parentsHash;
    foreach my $gain (@{$gainsRef})
    {
	my $parent = &showParent($runningTree, $gain);
	$parentsHash{$parent} = 1;
    }

    my $gainsNum = scalar (keys %parentsHash);
    if ($gainsNumHash{$gainsNum}){    $gainsNumHash{$gainsNum}++; }
    else {$gainsNumHash{$gainsNum} = 1;}

    # count number of losses:
    $lossesNum += scalar @{$lossesRef};

    if ($org)
    {
	print $familyNum, "\t";
    }

    # report required node:
    foreach my $gain (@{$gainsRef})
    {
	&addEvolChange ($finalTree, $gain, "acquision");
	if ($org)
	{
	    if (exists $evolPath{$gain})  { print $gain, " ";  }
	}
    }
    if ($org)    {	print "\n";    }

    if ($mode eq "all")
    {
	foreach my $loss (@{$lossesRef})
	{
	    &addEvolChange ($finalTree, $loss, "loss");
	}
    }
    if ($outputProfilesFile)
    {
	foreach my $nodeName (keys %{ $runningTree->{nodesHash} })
	{
	    my $reportedPresence = &showNodePresence ($runningTree, $nodeName);
	    if ($reportedPresence eq $yes)
	    {
		$genesHash{$familyNum}{$nodeName} = 1;
	    }
	}
    }
    if ($nodeToReport)
    {
	# 2 report all genes of particular node:
	my $reportedPresence = &showNodePresence ($runningTree, $nodeToReport);
	if ($reportedPresence eq $yes)
	{
	    &bootstrap($runningTree, $treeFile, $JecknifeIterNumber, $line, $num2orgHashRef, $noUseOrgsHashRef, $gainThreshold, $lossThreshold);
	    my $nodeOrg = &getNode ($runningTree, $nodeToReport);
	    print $familyNum, "\t", $nodeOrg->{totalGenes};
	    print "\n";
	}
    }

    &cleanTree($runningTree);
}
close PHYL;

print "Total number of analysed families: $total\n";

if ($org){exit;}

&findTotalGenesNum($finalTree, $finalTree->{root}, 0);

my @geinsNums = keys %gainsNumHash;
@geinsNums = sort numerically @geinsNums;
my $horisontals = 0;
my $horisontGenes = 0;

if ($mode eq "all")
{
    my @nodes = keys %{$finalTree->{nodesHash}};

    print "Node\tFamilies\tGains\tLosses\n";
    foreach my $nodeName (@nodes)
    {
	print $nodeName, "\t";
	my $node = &getNode ($finalTree, $nodeName);
	print $node->{totalGenes}, "\t";

	my $transition = &getNodeTransition($finalTree, $nodeName);
	my $gain = 0;
	my $loss = 0;
	if ($transition && $transition =~ /(.+)::(.+)/)
	{
	    $gain = $1;
	    $loss = $2;
	}
	print $gain, "\t", $loss;
	print "\n";
    }

    print "\n\n-----\n\n";
    foreach my $geinsNum (@geinsNums)
    {
	unless ($geinsNum == 1)
	{
	    $horisontals+=$gainsNumHash{$geinsNum}*($geinsNum-1);
	    $horisontGenes += $gainsNumHash{$geinsNum};
	}
    }

    print "Number of suspected HGT events is $horisontals in $horisontGenes genes\n";
    print "Number of genes acquired once is ", $gainsNumHash{1}, "\n";
    print "Number of gene losses is: $lossesNum\n";

    if ($imgFile)
    {
	@ARGV = @ARGVcpy;
	&drawTree($finalTree, $imgFile);
    }
    else
    {
	print STDERR "Image file not specified: no tree drawn\n";
    }
}

if ($outputProfilesFile)
{
    &printAncestralProfiles ($outputProfilesFile);
}

print STDERR "done\n\a";

#-=-=-=--=-=-=-=-=-=-=-=-=- Subroutines -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub findTotalGenesNum
{
    my ($tree, $nodeName, $parentGenesNum) = @_;

    my $node = &getNode($tree, $nodeName);
    my $transition = &getNodeTransition($tree, $nodeName);
    my ($gain, $loss) = (0, 0);

    if ($transition){($gain, $loss) = split ("::", $transition);}

    $node->{totalGenes} = $gain - $loss + $parentGenesNum;

    foreach my $kid (&showKids ($tree, $nodeName))
    {	&findTotalGenesNum($tree,$kid,  $node->{totalGenes});    }
}


sub cleanTree
{
    my ($tree) = @_;

    foreach my $nodeName (keys %{ $tree->{nodesHash} })
    {
	&setNodePresence($tree, $nodeName, "");
	&setNodeTransition($tree, $nodeName, "");
    }
}


sub addEvolChange
{
    my ($tree, $nodeName, $pattern) = @_;

    my $node = &getNode ($tree, $nodeName);
    my $transition = $node->{transition};

    unless ($transition) {$transition = "0::0";}

    my ($gain, $loss)  = split ("::", $transition);

    if ($pattern eq "acquision")    { $gain++; }
    elsif ($pattern eq "loss")      { $loss++; }
    else {die "ERROR: unknown pattern $pattern for node $nodeName in addEvolChange\n";}

    $transition = $gain . "::" . $loss;
    $node->{transition} = $transition;
}

sub printAncestralProfiles
{
    my ($outFile) = @_;

    my $profilesFile = $outFile . ".profiles";
    open (OUT, "> $profilesFile") || die "ERROR: can't open $outFile\n";
    my @genes = keys %genesHash;

    @genes = sort numerically @genes;
    my @ancestralGenomes;

    foreach my $genome (keys %{$finalTree->{nodesHash}})
    {
	unless (&isLeaf($finalTree, $genome))
	{
	    push (@ancestralGenomes, $genome);
	}
    }
#    @ancestralGenomes = sort numerically @ancestralGenomes;

    my $organismsListFile2Output = $outFile . ".organisms";

    open (ORGS, "> $organismsListFile2Output") || die "ERROR: can't open $organismsListFile2Output\n";
    my $i = 0;
    foreach my $ancestralGenome (@ancestralGenomes)
    {
	$i++;
	print ORGS $i, "\t",  $ancestralGenome, "\n";
    }
    close ORGS;

    foreach my $gene (@genes)
    {
	print OUT $gene, "\t";
	foreach my $ancestralGenome (@ancestralGenomes)
	{
	    if ($genesHash{$gene}{$ancestralGenome})
	    {		print OUT "1 ";	    }
	    else
	    {		print OUT "0 ";	    }
	}
	print OUT "\n";
    }
    close OUT;
}

# Sorting helper for numerical sort
sub numerically
{
    return $a <=> $b;
}
