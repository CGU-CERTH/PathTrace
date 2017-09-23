use tree::simple;

#=-==-=-=-=-=-=-=-=-

sub readNewickTreeFile
{
    my ($fileName) = @_;
    my $totalLine;

    open (FILE, $fileName) || die "ERROR: can't open $fileName\n";
    my $line;
    foreach $line (<FILE>)
    {
	chomp $line;
	$totalLine .= $line;
    }

    close FILE;

    my $tree = &newTree;
    $tree->{nodeCount} = 0;
    my ($lineBack, $root) = &makeNewickSubTree ($tree, $totalLine);
    &addParent ($tree, $tree->{root},'');
    return $tree;
}

#-=-=-=-=-=-=-=-=-=-=-

sub reformatName
{
    my ($name) = @_;

    $name =~ s/ /_/g;
    $name =~ s/\'//g;
    $name =~ s/,//g;

    if ($name =~ /(\S+)\#(\S+)/)    { $name= $2;    }
    if ($name =~ /<(.+)\>_(.+)/)    {	$name= $2;    }
    return $name;
}

#-=-=-=-=-=--=-=-=-=-
sub makeNewickSubTree
{
    my($tree, $line) = @_;

    my $char;
    my ($nodeName, $branchLength);
    my @kidsList;
    my @brothers;
    my @brothersNames;

    while (($char, $line) = $line =~ /(.)(.*)/)
    {
	if ($char eq ';')
	{
            if (@kidsList)
	    {
		unless ($nodeName)
		{
		    $nodeName = "node" . $tree->{nodeCount};
		    $tree->{nodeCount}++;
		}
		my $node = &newNode ($tree, $nodeName);
		foreach $kid (@kidsList)
		{
		    if ($kid eq $nodeName)
		    {
			die "ERROR: $kid is a kid of himself\n@kidsList\n";
		    }
		    &addKid  ($tree, $nodeName, $kid);
		    &addParent ($tree, $kid, $nodeName);
		}
		$tree->{root} = $nodeName;
	    }
	    return;
	}
	if ($char eq '(') # kid is starting
	{
	    ($line, @kidsList) = &makeNewickSubTree($tree, $line);
	}
	elsif ($char eq ',') # next is a brother
	{	@kidsList = ();}
	elsif ($char eq ')') # finish the level
	{
	    return ($line, @brothers);
	}
	elsif ($char eq ' '){next;} 
	else #($char eq '\'' || $char eq ':') # node description
	{
	    $line = $char . $line;
	    ($nodeName, $branchLength, $line) = $line =~ /(.*?)\s*:\s*(-*[\d\.]+)(.*)/; 
	    if ($nodeName){   $nodeName = &reformatName ($nodeName);}
	    unless ($nodeName)
	    {
		$nodeName = "node" . $tree->{nodeCount};
		$tree->{nodeCount}++;
	    }

	    unless (defined $branchLength)
	    { die "Undefined branch length for node $nodeName\n"; }

	    unless ($nodeName){die "Sorry, BUG\a\n$nodeName\n$oldName\n";}

	    # if a node with this name exists, add a unique integer identifier
	    if (&getNode ($tree, $nodeName))
	    {
		$nodeName .= $tree->{nodeCount};
		$tree->{nodeCount}++;
	    }

	    my $node = &newNode ($tree, $nodeName);
	    $node->{branchLength} = $branchLength;
	    push (@brothers, $nodeName);

	    my $kid;
	    if (@kidsList)
	    {
		$node->{depth} = 'undef';
		foreach $kid (@kidsList)
		{
		    if ($kid eq $nodeName)
		    {
			die "ERROR: $kid is a kid of himself\n@kidsList\n";
		    }
		    &addKid  ($tree, $nodeName, $kid);
		    &addParent ($tree, $kid, $nodeName);
		}
	    }
	    else
	    {$node->{depth} = 0;}
	    $tree->{root} = $nodeName;
	}

    }
}

sub printNewickTree
{
    my ($tree, $nodeName) = @_;

    my @kids = &showKids($tree, $nodeName);

    if (@kids)
    {
	print "(";
	foreach my $kid (@kids)
	{
	    &printNewickTree ($tree, $kid);
	    unless ($kid eq $kids[scalar@kids - 1])
	    {  print ","; }
	}
	print ")";
    }
    unless ($nodeName =~ /^node/){ 
	print "\'$nodeName\'";
    }
    my $node = &getNode($tree, $nodeName);
    if (defined $node->{branchLength})
    {    print ":", $node->{branchLength};}
    print "\n";

}


1;
