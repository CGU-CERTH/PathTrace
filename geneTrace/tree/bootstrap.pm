use strict;

use tree::all;

#-=-=-==-=-=-=-=-=-=-=-=-=-=-

# run N rounds of
#    select randomly half of the nodes
#    regenerate tree with this half of the nodes
#    restore gene history
#    store results


#-=-=-=-=-=-=-=-=-=-=-=-=-=-

my $not = "not";
my $yes = "yes";

#-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub findConfidence
{
    my ($tree, $inFile) = @_;
    my $runningTree = &newTree();
    &readTree($runningTree, $inFile);

    my @nodeNames = keys %{ $tree->{nodesHash} };
    foreach my $nodeName (@nodeNames)
    {
	my $node = &getNode ($tree, $nodeName);
	my $penalties = $node->{totalGenes};
	if ($penalties =~ /:/)
	{
	    my ($totalYes, $totalNot) = $penalties =~ /(\d+):(\d+)/;
	    $totalYes *=2;
	    $totalNot *=2;
	    my $presence = $totalYes . ":" . $totalNot;
	    &setNodePresence ($runningTree, $nodeName, $presence);
	}
	else 
	{
	    &setNodePresence ($runningTree, $nodeName, $penalties);
	}
    }
    &decisions_decisions($runningTree, $runningTree->{root}, $not);
    
    foreach my $nodeName (@nodeNames)
    {
	my $node = &getNode ($tree, $nodeName);
	my $presence = &showNodePresence($runningTree, $nodeName);
	$node->{totalGenes} = $presence;
    }
}


#-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub bootstrap
{
    my ($tree, $inFile, $trialsNum,$line, $num2orgHashRef, $noUseOrgsHashRef, $gainThreshold, $lossThreshold ) = @_;

    unless (defined $tree &&  defined $inFile && defined $trialsNum
	    && defined $line && defined $num2orgHashRef && 
	    defined $gainThreshold && defined $lossThreshold)
    {die "BUG: bootstrap function got wrong number of arguments\n";}


    my $i;
    for ($i = 0; $i < $trialsNum; $i++)
    {
	my $runningTree = &newTree();
	&readTree($runningTree, $inFile);
	my ($familyNum, $assigned) = &assign_PHYL_pattern($runningTree, $line, $num2orgHashRef, $noUseOrgsHashRef);
	my @deletedLeafs = &chooseLeafs ($runningTree);
	&purgeTree ($runningTree, @deletedLeafs);
##
	&assignPenalties($runningTree, $runningTree->{root}, $gainThreshold, $lossThreshold);
	&decisions_decisions($runningTree, $runningTree->{root}, $not, $gainThreshold, $lossThreshold); 

	my ($havesRef, $dontHavesRef) = &findAssignments($runningTree);
	&addHaveValues ($tree, $havesRef, $dontHavesRef);
    }
    &calculateBootstrapValues ($tree);
}


#-=-=-=-=-=-=-=-=-=-

sub calculateBootstrapValues
{
    my ($tree) = @_;

    my @nodes = values %{ $tree->{nodesHash} };
    foreach my $node (@nodes)
    {
	my $haves = $node->{haves};
	my $dont  = $node->{dontHaves};
	unless ($haves || $dont)
	{
	    $node->{totalGenes} = "undef";
	    next;
	}
	unless (defined $haves){$haves = 0;}
	unless (defined $dont){$dont = 0;}
	my $ratio = ($haves / ($haves + $dont)) * 100;
	$node->{totalGenes} = int $ratio;
	
	$node->{haves} = 0;
	$node->{dontHaves} = 0;
    }
}

#-=-=-=-=-=-=-=-=-=-=-=-=-

sub addHaveValues
{
    my ($tree, $havesRef, $dontHavesRef) = @_;
    my @haves = @{$havesRef};
    my @dontHaves = @{$dontHavesRef};

    foreach my $have (@haves)
    {
	my $node = &getNode ($tree, $have);
	$node->{haves}++;
    }
    foreach my $dont (@dontHaves)
    {
	my $node = &getNode ($tree, $dont);
	$node->{dontHaves}++;
    }
}


#-=-====-=-=-

sub findAssignments
{
    my ($tree) = @_;
    my (@haves, @dontHaves);

    my @nodes = keys %{ $tree->{nodesHash} };

    foreach my $node (@nodes)
    {
	my $presence = &showNodePresence($tree, $node);
	if ($presence eq $yes)
	{ push (@haves, $node);}
	elsif ($presence eq $not)
	{ push (@dontHaves, $node);}
	else
	{ die "Unclear presence: $presence to $node->{name}\n";	}
    }
    return (\@haves, \@dontHaves);
}

#-=-=-=-=-=-=-

sub chooseLeafs
{
    my ($tree) = @_;

    my %Num2leafHash;
    my @leafs = &getLeafs ($tree);
    my $count = 0;
    my @deletedLeafs;

    foreach my $leaf (@leafs)
    {
	$Num2leafHash{$count} = $leaf;   
	$count++;
    }

    my $deleteNum = $count / 2;
    my $deleted = 0;
    while ("true")
    {
	my $randomNum = rand $count;
	$randomNum = int $randomNum;
	if (exists $Num2leafHash{$randomNum})
	{
	    push (@deletedLeafs, $Num2leafHash{$randomNum});
	    delete $Num2leafHash{$randomNum};
	    $deleted++;
	    if ($deleted >= $deleteNum)
	    { last; }
	}
    }

    return @deletedLeafs;
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Receives a tree and a list of leafs to delete 
# manages deleting of the leafs
sub purgeTree
{
    my ($tree, @deletedLeafs) = @_;

    foreach my $deletedLeaf (@deletedLeafs)
    {
	&deleteLeaf ($tree, $deletedLeaf);
    }
}

# yep, kill him and all the family! ;-)
sub deleteLeaf
{
    my ($tree, $deletedLeaf) = @_;

    my $son = $deletedLeaf;
    my @brothers;

    my $grandSon = "";

    # kill fathers untill there is at least one helthy kid 
    while ("true")
    {
	my $fatherName = &showParent($tree, $son);
	unless ($fatherName){last;}
	delete $tree->{nodesHash}{$son};
	
	my $father = &getNode ($tree, $fatherName);
	delete $father->{kidsHash}{$son};
	$son = $fatherName;
	# Shortcut branches until there is at least two healthy kids
#	if ($grandSon)
#	{
#	    &addKid ($tree, $fatherName, $grandSon);
#	    &addParent ($tree, $grandSon, $fatherName);
#	}
	@brothers = keys %{$father->{kidsHash}};

	if (scalar @brothers > 0)	{last;}
#	if (scalar @brothers > 1)	{last;}
#	elsif (scalar @brothers == 1) { $grandSon = $brothers[0];}
    }

}

#-=-=-=-=-

1;
