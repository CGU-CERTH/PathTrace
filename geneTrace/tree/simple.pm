use strict;
#use GD;

my $yes = 'yes';
my $not = 'not';

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Subroutine creates new tree object
sub newTree
{
    my %nodesHash;
    my $tree = {
	nodesHash => { %nodesHash },
	root      => '',
    };

    return $tree;
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

# Subroutine creates new tree
sub newNode
{
    my ($tree, $name, $depth, $parent, $presence) = @_;

    my %kidsHash;

    if (&getNode($tree, $name)){return;}
    my $leafsNum;
    unless($depth){$leafsNum = 1;}

    my $node = {
	name     => $name,
	depth    => $depth,
	leafsNum => $leafsNum,
	kidsHash => { %kidsHash },
	parent   => $parent,
	presence => $presence,
	transition => '',
    };
    $tree->{nodesHash}{$name} = $node;

    return $node;
}

#-=-=-=-=-=-=-=-=-=-

sub setBranchLength
{
    my ($tree, $nodeName, $branchLength) = @_;

    my $node = &getNode ($tree, $nodeName);
    $node->{branchLength} = $branchLength;
}

#-=-=-=-=-=-=-=-=-=-

sub showBranchLength 
{
    my ($tree, $nodeName) = @_;
    my $node = &getNode ($tree, $nodeName);
    return $node->{branchLength};
}

#-=-=-=-=-=-=-=-=-=-

sub getNode
{
    my ($tree, $nodeName) = @_;

    return $tree->{nodesHash}{$nodeName};
}

#-=-=-=-=-=-=-=-=--=

sub isLeaf
{
    my ($tree, $nodeName) = @_;

    my $node = &getNode ($tree, $nodeName);

    unless($node->{depth}) {return 1;}
    return 0;
}

#-=-=-=-=-=-=-=-=-=-

sub showKids
{
    my ($tree, $nodeName) = @_;

    my $node = &getNode($tree, $nodeName);
    my @kids = keys %{ $node->{kidsHash} };

    return @kids;
}

#-=-=-=-=-=-=-=-

sub showNodePresence
{
    my ($tree, $nodeName) = @_;

    my $node = &getNode($tree, $nodeName);
    my $presence = $node->{presence};

    return $presence;
}


#-=-=-=-=-=-=-=-

sub setNodePresence
{
    my ($tree, $nodeName, $presence) = @_;

    my $node = &getNode($tree, $nodeName);
    unless ($node){die "ERROR: can't assign presence $presence to $nodeName: node is not defined\n";}
###
    $node->{presence} = $presence;

    unless ($node->{totalGenes}){    $node->{totalGenes} = $presence;}
    return;
}

#-=-=-=-=-=-=-=-=-=-

sub showParent
{
    my ($tree, $nodeName) = @_;
    my $node = &getNode ($tree, $nodeName);
    return $node->{parent};
}

#-=-=-=-=-=-=-=-=-=-

sub addParent 
{
    my ($tree, $nodeName,$parentName) = @_;
    my $node = &getNode ($tree, $nodeName);
    $node->{parent} = $parentName;
}

#-=-=-=-=-=-=-=-=-=-=-=-=-

sub addKid
{
    my ($tree, $nodeName, $kidName) = @_;

    my $node =  &getNode($tree, $nodeName);

    unless ($node){die "BUG: addKid got unexistent node $nodeName\n";}
    $node->{kidsHash}{$kidName} = 1;
}

#-==-=-=-=-=-

# Given a tree finds its root
sub findRoot
{
    my ($tree) = @_;
 
    my $root;
    my @nodes = keys %{ $tree->{nodesHash} };
    my $node;

    foreach $node (@nodes)
    {
	unless ($tree->{nodesHash}{$node}->{parent})
	{
	    if ($root){die "ERROR: more then 2 roots in the tree: $root and $node\n";}
	    else {$root = $node;}
	}
    }
    return $root;
}

#-=-=-=-=-=-=-=-=-=-

# Reads the tree from the input file and assigns data structures
sub readTree
{
    my ($tree, $infile) = @_;
    open (IN, $infile) || die "ERROR: can't open $infile\n";
    my $line;
    my $longestBranchLength = 0;

    while ($line = <IN>)
    {
	my $branchLength;
	if ($line =~ /(.+)\s+:(\S+)/)
	{
	    $line = $1;
	    $branchLength = $2;
	    if ($branchLength > $longestBranchLength) 
	    {$longestBranchLength = $branchLength;}
	}
	if ($line =~ /(\S+)\s+(\S+)\s+(\S+)/)
	{
	    my $nodeName   = $1;
	    my $parentName = $2;
	    my $presence   = $3;

	    unless (&getNode ($tree, $nodeName))
	    { 
		&newNode ($tree, $nodeName, 0, $parentName, $presence);
		&setBranchLength ($tree, $nodeName, $branchLength);
	    }
	    else {die "ERROR: leaf $nodeName has more then one entry\n";}

	    unless (&getNode ($tree, $parentName))
	    { &newNode ($tree, $parentName, 'undef' ,'','');}
	    &addKid ($tree, $parentName, $nodeName);
	}
	elsif ($line =~ /(\S+)\s+(\S+)/)
	{
	    my $nodeName   = $1;
	    my $parentName = $2;

	    unless (&getNode ($tree, $nodeName))
	    {
		&newNode ($tree, $nodeName, 'undef', $parentName, '');
		&setBranchLength ($tree, $nodeName, $branchLength);
	    }
	    else
	    { &addParent ($tree, $nodeName,$parentName);}

	    unless (&getNode ($tree, $parentName))
	    { &newNode ($tree, $parentName, 'undef', '','');}
	    &addKid ($tree, $parentName, $nodeName);
	}
    }

    close IN;

    $tree->{root} = &findRoot($tree);
    if ($longestBranchLength)
    {$tree->{longestBranchLength} = $longestBranchLength;}
    &setLeafNumbsAndDepth($tree, $tree->{root});

    return $tree;
}

#-=-=-=-=-=-=-=-=-=-=-

sub findLeafsNum
{
    my ($tree, $nodeName) = @_;
    my $node = &getNode($tree, $nodeName);

    unless ($node->{leafsNum}){die "ERROR: no leafs to node $nodeName\nDepth $node->{depth}\n";}
    return $node->{leafsNum};
}

#-=-=-=-=-=-=-=-=-=-

sub findDepth
{
    my ($tree, $nodeName, $depth) = @_;

    my $node = &getNode ($tree, $nodeName);
    return $node->{depth};
}

#-=-=-=-=-=-=-=-=-=-

sub getLeafs
{
    my ($tree) = @_;
    my @nodes = keys %{$tree->{nodesHash}};
    my @leafs;

    foreach my $node (@nodes)
    {
	if (&isLeaf ($tree, $node))
	{
	    push (@leafs, $node);
	}
    }

    return @leafs;
}

#-=-=-=-=-=-=-=-=-=-=-=-

sub setLeafNumbsAndDepth
{
    my ($tree, $nodeName) = @_;
    if (&isLeaf($tree, $nodeName)) 
    {return (1, 0);}
    
    my @kids = &showKids($tree, $nodeName);
    my $accLeafNumbs = 0;
    my $maxDepth = 0;
    my $kid;

    foreach $kid (@kids)
    {
	my ($leafNum, $depth) = &setLeafNumbsAndDepth ($tree, $kid);
	$accLeafNumbs += $leafNum;
	if ($depth > $maxDepth){$maxDepth = $depth;}
    }

    my $node = &getNode($tree, $nodeName);
    $node->{leafsNum} = $accLeafNumbs;
    $maxDepth++;
    $node->{depth}    = $maxDepth;

    return ($accLeafNumbs, $maxDepth);
}


#-=-==-=-=-=-=-=-=

sub findLeafs
{
    my $tree = shift @_;

    my @nodes = keys %{$tree->{nodesHash}};
    my $nodeName;
    foreach $nodeName (@nodes)
    {
	my $node = $tree->{nodesHash}{$nodeName};
	unless (&showKids($tree, $nodeName))
	{
	    $node->{depth} = 0;
	}
	else {$node->{depth} = 'undef';}
    }
}

#-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=--=-=-=-=-

sub setNodeTransition
{
    my ($tree, $nodeName, $transition) = @_;

    my $node = &getNode($tree, $nodeName);
    $node->{transition} = $transition;
}

#-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=--=-=-=-=-

sub getNodeTransition
{
    my ($tree, $nodeName) = @_;

    my $node = &getNode($tree, $nodeName);

    return $node->{transition};
}


#-=-=-=-=-=-=-=-

sub printTree
{
    my ($tree, $nodeName, $textFile) = @_;

    open (TXT, "> $textFile") || die "ERROR: can't open $textFile\n";
    &recursivePrint ($tree, $nodeName);
    close TXT;
}

#-=-=-=-=-=-=-=-

sub recursivePrint
{
    my ($tree, $nodeName) = @_;


    my $node = &getNode ($tree, $nodeName);
    unless ($node->{presence}){$node->{presence} = '';}
    printf TXT "%-25s\t%-25s\t%-7s",  $node->{name}, $node->{parent}, $node->{presence};
#    printf "%-25s\t%-25s\t%-5s\n",  $node->{name}, $node->{parent}, $node->{presence};

#    if (defined $node->{branchLength})
#    {    print TXT ":", $node->{branchLength}, "\n";}
#    else {print TXT "\n";}

    print TXT "\n";
    if (&isLeaf($tree, $nodeName)) {return;}

    my @kids = &showKids($tree, $nodeName);
    my $kid;
    @kids = sort @kids;
    foreach $kid (@kids)
    {
	&recursivePrint($tree, $kid);
    }
}


1;

