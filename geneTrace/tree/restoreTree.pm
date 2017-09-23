use strict;

use tree::all;

#-=-=-=-=-=-=-=-=-=-=-=-=- Contstants -=-=-=-=-=-=-=-

my $yes = 'yes';
my $not = 'not';
my $waitConst = 1;
#my $threshold = 2;
#my $threshold = 1;
#my $threshold2 = 4;

#-==-=-=-=-=-=-=--=-=-=- main subroutines -=-=-=-===-==--==-=-=-=-

sub findEvolChanges
{
    my ($tree) = @_;
    my (@gains, @loss);

    &setEvolChanges($tree, $tree->{root}, $not);

    foreach my $node (keys %{ $tree->{nodesHash} })
    {
	my $transition = &getNodeTransition($tree, $node);
	if ($transition eq "acquision")
	{push (@gains, $node);}
	elsif ($transition eq "loss")
	{push (@loss, $node);}
	elsif ($transition eq ""){}
	else
	{ die "ERROR: unknown transition $transition to node $node\n";}
    }
    return (\@gains, \@loss);
}


#-=-=-=-=-=-=-=-=-=-=-=-

sub setEvolChanges 
{
    my ($tree, $nodeName, $parentState) = @_;
    my $presence = &showNodePresence ($tree, $nodeName);

    unless ($presence eq $parentState)
    {
	if ($parentState eq $not && $presence eq $yes)
	{ &setNodeTransition ($tree, $nodeName, "acquision"); }
#	{ push (@acquision, $nodeName); }
	elsif ($parentState eq $yes && $presence eq $not)
#	{ push (@loss, $nodeName);}
	{ &setNodeTransition ($tree, $nodeName, "loss"); }   
	else {die "Unknown transition: from $parentState to $presence\n";}
    }
    my @kids = &showKids ($tree, $nodeName);
    my $kid;
    foreach $kid (@kids)
    {
	&setEvolChanges ($tree,$kid, $presence);
    }
}


#-=-=-=-==-=-=-=-=-=-===-=-=-=-=-=-=-=-=-=-

sub decisions_decisions
{
    my ($tree, $nodeName, $parentState, $gainThreshold, $lossThreshold) = @_;

    unless (defined $tree && defined $nodeName && defined $parentState &&
	    defined $gainThreshold && defined $lossThreshold)
    {	die "decisions_decisions got wrong number of parameters: @_";    }

    my @kids = &showKids ($tree, $nodeName);
    my $kid;

    my $presence = &showNodePresence ($tree, $nodeName);

    # return if leaf
    if (&isLeaf($tree, $nodeName)) 	{ return;}
    
    # continue if everything already clear
    unless ($presence eq $not || $presence eq $yes)
    {
	my ($totalYes, $totalNot) = $presence =~ /(\d+):(\d+)/;
	
	# gene does not dissapear as long as it has non-0 probability
	# and the pattern is higher then threshold.
	if ($parentState eq $yes) 
	{
	    if ($totalNot * $waitConst - $totalYes >= $lossThreshold)
#	    if ($totalYes > 1 && $totalNot * $waitConst / ($totalYes - 1) >= $lossThreshold)
	    { &setNodePresence ($tree, $nodeName, $not); }
	    else
	    { &setNodePresence ($tree, $nodeName, $yes); }
	}
	
	# did gene appear this generation?
	# yes, if several kids have non-0 probablility values
	# and the probablility at this node is higher then threshold
	elsif ($parentState eq $not) 
	{
	    my %kidValuesHash;
	    # assign probablilities to each kid
	    foreach $kid (@kids)
	    {
		my $kidPresence = &showNodePresence( $tree, $kid);
		$kidValuesHash{$kidPresence}++;
	    }
	    
	    if (exists $kidValuesHash{$not}){delete $kidValuesHash{$not};}
	    my @diffKids = keys %kidValuesHash;
	    my $differentKidsNum = scalar @diffKids;
	    # Kids pattern is not only "no" + smth 
	    if ( $differentKidsNum  > 1 || 
		 $kidValuesHash{$diffKids[0]} > 1) 
	    {
		# Assign 'not' only if higher then threshold
		if ( $totalNot * $waitConst - $totalYes >= $gainThreshold)
#		if ($totalYes > 1 && $totalNot * $waitConst / ($totalYes - 1) >= $threshold)
		{ &setNodePresence ($tree, $nodeName, $not);}
		else
		{ &setNodePresence ($tree, $nodeName, $yes);}
	    }
	    else { &setNodePresence ($tree, $nodeName, $not);}
	}
	else
	{
	    die "BUG: can't deside what to do with node $nodeName\n";
	}
    }
    foreach $kid (@kids)
    {
	&decisions_decisions ($tree, $kid, &showNodePresence( $tree, $nodeName), $gainThreshold, $lossThreshold);
    }
}

#-=-=-=-=-=-=-=-

# Find number of evolutionary changes required at each position 
# for each starting condition

# This version makes desisions for cases that are obvious
# This is in order to make more realsitic penalty assignment.
sub assignPenalties
{
    my ($tree, $nodeName, $gainThreshold, $lossThreshold) = @_;
    my %kidValuesHash;

    unless (defined $tree && defined $nodeName &&
	    defined $gainThreshold && defined $lossThreshold)
    {	die "assignPenalties got wrong number of parameters: @_";    }

    # return if leaf
    if (&isLeaf($tree, $nodeName)) 	{ return;}

    # assign probablilities to each kid
    my @kids = &showKids ($tree, $nodeName);
    my $kid;

    foreach $kid (@kids)
    {	&assignPenalties ($tree, $kid, $gainThreshold, $lossThreshold);    }

    my $totalYes = 0;
    my $totalNot = 0;
    foreach $kid (@kids)
    {
	my $presence = &showNodePresence( $tree, $kid);
	my $branchLength = &showBranchLength ($tree, $kid);
	unless (defined $branchLength)
	{ $branchLength = 1;}
	else
	{ $branchLength = - log ($branchLength);  }
	    
	if ($presence eq $yes)
	{
#	    unless ($kidValuesHash{$presence})
	    {
		$totalYes += 1;#/ $branchLength; 
	    } 
	}
	elsif ($presence eq $not)
	{ 
#	    unless ($kidValuesHash{$presence})
	    { $totalNot+= 1;}# /$branchLength; } 
	}
	elsif ($presence =~ /(\d+):(\d+)/)
	{
	    $totalYes += $1;# /$branchLength; 
	    $totalNot += $2;# /$branchLength;
	}
	else {die "ERROR: unrecognised pattern of $kid: $presence\n";}
	$kidValuesHash{$presence}++;
    }

    my @kidValuesArray = keys %kidValuesHash;
    my $differentKidsNumber = scalar @kidValuesArray;

    # All the kids have the same 
    # unambiguous pattern of presence or absence: same pattern
    if ( $differentKidsNumber == 1 &&
	($kidValuesArray[0]       eq $yes ||
	 $kidValuesArray[0]       eq $not ))
    {
	&setNodePresence ($tree, $nodeName, $kidValuesArray[0]);
	return;
    }

    # Here is the desision making:

    # If there too much loss, setting "No" would be realistic
    # and would not propagate heavy penalty dowards.
    if ($totalNot - $totalYes >= $lossThreshold)
    {	&setNodePresence ($tree, $nodeName, $not);     }

    # If there seems to be gene presence anyway, set "Yes" to
    # avoid propagating dependent gaining downwards as independent ones.
    elsif ($totalYes > 1 && $totalNot * $waitConst - $totalYes < $gainThreshold)
    {
	&setNodePresence ($tree, $nodeName, $yes);
    }
    else
    {	&setNodePresence ($tree, $nodeName, $totalYes . ":" . $totalNot);    }

}
