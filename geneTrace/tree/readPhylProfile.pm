use strict;
use tree::all;

my $yes = 'yes';
my $not = 'not';

#
sub assign_PHYL_pattern
{
    my ($tree, $pattern, $num2orgHashRef, $skipNumsRef) = @_;

    my %num2orgHash = %{$num2orgHashRef};
    my %skipNums = %{$skipNumsRef};
    my $totalAssignedPlus = 0;

    my @patternString = split (/\s+/, $pattern);

    my $clusterNum = shift @patternString;
    my $i;
    my $orgNum = scalar (keys %num2orgHash);
    my $orgNum2 = scalar @patternString;

    unless ($orgNum == $orgNum2) {die "ERROR: organism numbers by hash $orgNum do not match the number of fields $orgNum2\n";}

    for ($i=1; $i <= $orgNum; $i++)
    {
	my $org = $num2orgHash{$i};
	unless (exists ($skipNums{$i}))
	{
	    if ($patternString[$i-1])
	    {	    
		&setNodePresence ($tree, $org, $yes);	
		$totalAssignedPlus++;
	    }
	    else { &setNodePresence ($tree, $org, $not);	}
	}
    }
    return ($clusterNum, $totalAssignedPlus);
}

# Reads file of organisms numbers/names and returns hash of numbers to genome ids
sub setOrgNums
{
    my ($infile) = @_;
    my %speHash;
    my $tree;
    my $orgNum = 0;
    open (IN, $infile) || die "ERROR: can't open $infile\n";    

    my $line;
    while ($line = <IN>)
    {
	# modification from Z_info format to tab-separted list of numbers - organisms
#	if ($line =~ /(\d+)\t+(\d+\/\d+\/\d+)\t+(\S+)\s+([ |\S]+)\t+([ |\S]+)\t+/)

	if ($line =~ /(\d+)\t+(\S+)/)
	{
	    my $num = $1;
	    my $org = $2;
	    $org = uc ($org);
	    $speHash{$num} = $org;
	    $orgNum++;
	}
    }
    return (\%speHash, $orgNum);
}

1;
