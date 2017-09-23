use tree::simple;
use GD;

#-=-=-=-=-=-=-=-=-=-=- Constants -==-=-=-=-=-=--=-=-

# Graph constants:
my $margin = 20;
my $lineSpacing = 5;
my $Xpixels4node = 90;
my $Ypixels4node = 50;

my $yes = 'yes';
my $not = 'not';

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
    my $green = $img->colorAllocate(0,100,0);

    # Calculate y-coordinates for levels of the tree
    my $maxXdraw =  $maxX - $margin;
    my $maxYdraw =  $maxY - $margin;
    my $yStep = int ( $maxYdraw - $margin )/ ($maxDepth);

    # make the background transparent and interlaced
    $img->transparent($white);
    $img->interlaced('true');

    my $line = "Results of $0 @ARGV";
    $img->string(gdSmallFont,$margin,$margin,$line,$green);
    # draw all the nodes
    &recursiveDraw ($tree, $tree->{root}, $img, $yStep, $margin, $maxXdraw, $maxYdraw, $black, $red, $blue, $green);

    # Convert the image to PNG and print it to file
    binmode IMG;
#    print IMG $img->png;
    print IMG $img->jpeg(75);
#    print IMG $img->gd2;
    close IMG;
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

sub recursiveDraw
{
    my ($tree, $nodeName, $img, $yStep, $xLeft, $xRight, $y, $black, $red, $blue, $green) = @_;


    # Decide for color of the node
    my $presence = &showNodePresence ($tree, $nodeName);
    unless ($presence){$presence = '';}

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

    my $node = &getNode ($tree, $nodeName);
    my $strY = $botY + 2 *$lineNum * $lineSpacing;
    if (defined $node->{totalGenes})
    {	$img->string(gdSmallFont,$x,$strY,$node->{totalGenes}, $green);    }

    if (&isLeaf ($tree, $nodeName))
    {return;}

    #draw kids
    my @kids = &showKids($tree, $nodeName);
    @kids = sort @kids;
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
	&recursiveDraw ($tree, $kid, $img, $yStep, $kidXleft, $kidXright, $kidY, $black, $red, $blue, $green);

	#draw line to the kid
	my $kidXMid = $kidXleft + ($kidXright - $kidXleft) / 2;
	$img->line($x,$y - $lineSpacing,$kidXMid, $kidY + 3 *$lineSpacing, $color); 
	# draw edge summary
	my $transition = &getNodeTransition($tree, $kid);
	if ($transition)
	{
	    my $xTrans = ($x-$kidXMid)/2+$kidXMid;
	    my $yTrans = ($y-$kidY)/2 + $kidY;

	    if ($transition =~ /(.+)::(.+)/)
	    {
		my $gain = $1;
		my $loss = $2;
		$img->string(gdSmallFont,$xTrans,$yTrans-$lineSpacing,$gain,$red);
		$img->string(gdSmallFont,$xTrans,$yTrans+$lineSpacing,$loss,$blue);
	    }
	    else
	    {
		$img->string(gdSmallFont,$xTrans,$yTrans,$transition,$black);
	    }
	}
    }
}

1;
