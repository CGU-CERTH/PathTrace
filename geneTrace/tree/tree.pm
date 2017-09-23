use strict;
use GD;

#-=-=-=-=-=-=-=-=-=-=- Constants -==-=-=-=-=-=--=-=-

# Graph constants:
my $margin = 20;
my $lineSpacing = 5;
my $Xpixels4node = 90;
my $Ypixels4node = 50;
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
    };
    $tree->{nodesHash}{$name} = $node;

    return $node;
}

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
	if ($char eq ';'){return;}
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
	else #($char eq '\'' || $char eq ':') # node description
	{
	    $line = $char . $line;
	    ($nodeName, $branchLength, $line) = $line =~ /(.*?):([\d\.]+)(.*)/; 
	    unless ($nodeName)
	    {
		$nodeName = "node" . $tree->{nodeCount};
		$tree->{nodeCount}++;
	    }
	    unless (defined $branchLength)
	    { die "Undefined branch length for node $nodeName\n"; }

	    my $node = &newNode ($tree, $nodeName);
	    $node->{branchLength} = $branchLength;

	    push (@brothers, $nodeName);
	    unless ($nodeName){die "Sorry, BUG\a\a\a\a\n";}

	    my $kid;
	    if (@kidsList)
	    {
		$node->{depth} = 'undef';
		foreach $kid (@kidsList)
		{
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
    $node->{presence} = $presence;
    return;
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

    unless ($node){die "BUG: addKid got unexistent node\n";}
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
	    if ($root){die "ERROR: more then 2 roots in the tree\n";}
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

    while ($line = <IN>)
    {
	if ($line =~ /(\S+)\s+(\S+)\s+(\S+)/)
	{
	    my $nodeName   = $1;
	    my $parentName = $2;
	    my $presence   = $3;

	    unless (&getNode ($tree, $nodeName))
	    { &newNode ($tree, $nodeName, 0, $parentName, $presence); }
	    else {die "ERROR: leaf has more then one entry\n";}

	    unless (&getNode ($tree, $parentName))
	    { &newNode ($tree, $parentName, 'undef' ,'','');}
	    &addKid ($tree, $parentName, $nodeName);
	}
	elsif ($line =~ /(\S+)\s+(\S+)/)
	{
	    my $nodeName   = $1;
	    my $parentName = $2;

	    unless (&getNode ($tree, $nodeName))
	    { &newNode ($tree, $nodeName, 'undef', $parentName, ''); }
	    else
	    { &addParent ($tree, $nodeName,$parentName);}

	    unless (&getNode ($tree, $parentName))
	    { &newNode ($tree, $parentName, 'undef', '','');}
	    &addKid ($tree, $parentName, $nodeName);
	}
    }

    close IN;

    $tree->{root} = &findRoot($tree);
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

#=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--

sub splitWord2Pices
{
    my ($nodeName, $piceSize, $maxNonsplit) = @_;

    my @stringArr = split (/[_\/]/,$nodeName);
    my $line;
    my @drawStringArr;

    foreach $line (@stringArr)
    {
	my $i;
	for ($i = 0; $i < length ($line); $i= $i+$piceSize)
	{
	    if (length (substr ($line,$i,)) < $maxNonsplit)
	    {
		my $linePice= substr ($line, $i,);
		push (@drawStringArr, $linePice);
		last;
	    }
	    else
	    {
		my $linePice = substr ($line, $i, $piceSize);
		if (length ($line) > $i + $piceSize)
		{ $linePice = $linePice . "-";}
		push (@drawStringArr, $linePice);
	    }
	}
    }

    return @drawStringArr;
}

#-=-=-=-=-=-=-=-=-

sub drawTree
{
    my ($tree, $imgFile) = @_;

    # find the maximal depth and the leaf number
    my $leafNum  = &findLeafsNum($tree, $tree->{root});
    my $maxDepth = &findDepth ($tree, $tree->{root}, 0);

    # open a file to write img
    open (IMG, ">$imgFile") || die "ERROR: can't open $imgFile for writing\n";

    # Calculate img size
    my $maxX = $leafNum  * $Xpixels4node;
    my $maxY = $maxDepth * $Ypixels4node;

    # Create img object and allocate colors
    my $img = new GD::Image($maxX,$maxY);
    my $white = $img->colorAllocate(255,255,255);
    my $black = $img->colorAllocate(0,0,0);       
    my $red   = $img->colorAllocate(255,0,0);
    my $blue  = $img->colorAllocate(0,0,255);

    # Calculate y-coordinates for levels of the tree
    my $maxXdraw =  $maxX - $margin;
    my $maxYdraw =  $maxY - $margin;
    my $yStep = int ( $maxYdraw - $margin )/ ($maxDepth);

    # make the background transparent and interlaced
    $img->transparent($white);
    $img->interlaced('true');

    # draw all the nodes
    &recursiveDraw ($tree, $tree->{root}, $img, $yStep, $margin, $maxXdraw, $maxYdraw, $black, $red, $blue);

    # Convert the image to PNG and print it to file
    binmode IMG;
    print IMG $img->png;
    close IMG;
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub recursiveDraw
{
    my ($tree, $nodeName, $img, $yStep, $xLeft, $xRight, $y, $black, $red, $blue) = @_;


    # Decide for color of the node
    my $presence = &showNodePresence ($tree, $nodeName);
    my $color;
    if ($presence eq $not)
    {	$color = $blue;}
    elsif ($presence eq $yes)
    {   $color = $red; }
    else { $color = $black; }

    # Calculate coordinates of the node
    my $x = $xLeft + ( ($xRight - $xLeft) / 2 );

    # Split node name to lines of size no more then 12. 
    my @drawStringArr = &splitWord2Pices ($nodeName, 8,12);
    my $linesNum = scalar @drawStringArr;
    my $botY = $y - ($linesNum * $lineSpacing) / 2;

    # Print node name line by line
    my $lineNum = 0;
    my $line;
    foreach $line (@drawStringArr)
    {
	my $strY = $botY + 2 *$lineNum * $lineSpacing;
	$img->string(gdSmallFont,$x,$strY,$line,$color);
	$lineNum++;
    }

    if (&isLeaf ($tree, $nodeName))
    {return;}

    #draw kids
    my @kids = &showKids($tree, $nodeName);
    my $kid;
    my $leafNum = &findLeafsNum($tree, $nodeName);
    my $xStep = int ( ($xRight - $xLeft) / $leafNum );
    my $runningXleft = $xLeft;

    foreach $kid (@kids)
    {
	# Calculate coordinates to draw a kid
	my $kidLeafsNum = &findLeafsNum($tree, $kid);
	my $kidXleft  = $runningXleft;
	my $kidXright = $kidXleft + $kidLeafsNum * $xStep;
	$runningXleft = $kidXright;
	my $kidY = $y - $yStep;	
	&recursiveDraw ($tree, $kid, $img, $yStep, $kidXleft, $kidXright, $kidY, $black, $red, $blue);

	#draw line to the kid
	my $kidXMid = $kidXleft + ($kidXright - $kidXleft) / 2;
	$img->line($x,$y - $lineSpacing,$kidXMid, $kidY + 3 *$lineSpacing, $color); 
    }
}

#-=-=-=-=-=-=-=-

sub printTree
{
    my ($tree, $nodeName, $textFile) = @_;

    open (TXT, "> $textFile") || die "ERROR: can't open $textFile\n";
    &recursivePrint ($tree, $nodeName);
    close TXT;
}

sub recursivePrint
{
    my ($tree, $nodeName) = @_;

    my $node = &getNode ($tree, $nodeName);
    unless ($node->{presence}){$node->{presence} = '';}
    printf TXT "%-25s\t%-25s\t%-5s\n",  $node->{name}, $node->{parent}, $node->{presence};

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

