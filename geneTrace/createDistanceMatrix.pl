#!/sw/arch/bin/perl -w

use strict;
use lib "geneTrace/";
use tree::readPhylProfile;

my ($phylProfFile, $Z_infoFile, $Z_infoEUFile) = @ARGV;


unless ($phylProfFile && $Z_infoFile)
{
    die "
USAGE:
$0 phylProfFile org_list <ignore_orgs_list>
";
}


# Initiate organisms hashes:
my ($num2orgHashRef, $orgsNum) = &setOrgNums($Z_infoFile);
my %num2orgHash = %{$num2orgHashRef};

my $noUseOrgsNum = 0;
my %noUseOrgsHash;
my $noUseOrgsHashRef = \%noUseOrgsHash;

if ($Z_infoEUFile)
{
   ($noUseOrgsHashRef, $noUseOrgsNum) = &setOrgNums($Z_infoEUFile);
   %noUseOrgsHash = %{$noUseOrgsHashRef};
}

my %distanceMarix;
my %similarityTable;

# for parsimony matrix
my %orgHash;

&readPhylFile();
#for parsimony:
#&printParsimonyMatrix();

#for distance matrix:
&makeDistanceMatrix;
&printDistanceMatrix();

sub printParsimonyMatrix
{
    my @orgNums = keys %orgHash;
    my $charachtersNum = scalar @{$orgHash{$orgNums[0]}};
    printf "%4d%6d\n", scalar @orgNums, $charachtersNum;

    @orgNums = sort numerically @orgNums;

    foreach my $orgNum (@orgNums)
    {
	print $num2orgHash{$orgNum}, "\t", @{$orgHash{$orgNum}}, "\n";
    }
}

#-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-


sub makeDistanceMatrix
{
    my @orgs = keys %similarityTable;

    foreach my $org1 (@orgs)
    {
	foreach my $org2 (@orgs)
	{
	    my $totalGeneNum;
	    my $totalGeneNum1 = $similarityTable{$org1}{$org1};
	    my $totalGeneNum2 = $similarityTable{$org2}{$org2};
	    if ($totalGeneNum1 > $totalGeneNum2) {$totalGeneNum = $totalGeneNum2;}
	    else {$totalGeneNum = $totalGeneNum1;}

	    $distanceMarix{$org1}{$org2} = 1 - ($similarityTable{$org1}{$org2} / $totalGeneNum);
	}
    }
}

#-=-=-=-=-=-=-=-=-

sub printDistanceMatrix
{
    my @orgNums = keys %num2orgHash;
    @orgNums = sort numerically @orgNums;

    my $orgNum = scalar @orgNums - scalar (keys %noUseOrgsHash);

    printf "%5d\n", $orgNum;

    foreach my $orgNum (@orgNums)
    {
	if (exists $noUseOrgsHash{$orgNum}){next;}
	my $org = $num2orgHash{$orgNum};

	printf "%-10s%5s", $org, "";
	foreach my $orgNum2 (@orgNums)
	{
	    if (exists $noUseOrgsHash{$orgNum2}){next;}
	    my $org2 = $num2orgHash{$orgNum2};
	    unless (defined $distanceMarix{$org}{$org2})
	    {$distanceMarix{$org}{$org2} = 0;}
	    printf "%-7f  ", $distanceMarix{$org}{$org2};
	}
	print "\n";
    }
}


sub readPhylFile
{
    open (PHYL, $phylProfFile) || die "ERROR: can't open $phylProfFile\n";

    while (my $line = <PHYL>)
    {
	my @patternString = split (/\s+/, $line);
	my $clusterNum = shift @patternString;

	my $i;
	# check that number of organisms in the string and Z_info file match
	my $orgNum = scalar (keys %num2orgHash);
	my $orgNum2 = scalar @patternString;

	unless ($orgNum == $orgNum2)
	{
	    die "ERROR: organism numbers by hash $orgNum do not match the number of fields $orgNum2\n";
	}

	my %tmpHash;
	my $nonZero = 0;

	for ($i=1; $i <= $orgNum; $i++)
	{
	    my $org = $num2orgHash{$i};
	    if (exists $noUseOrgsHash{$i}) { next;}

# distance matrix
	    if ($patternString[$i-1])
	    {		$tmpHash{$org} = 1;	    }

# parsimony matrix
#	    if ($patternString[$i-1])
#	    {		push (@{$orgHash{$i}}, 1);	  $nonZero = 1; }
#	    else { push (@{$orgHash{$i}}, 0);}

	}

	unless ($nonZero)
	{
	    for ($i=1; $i <= $orgNum; $i++)
	    {
		my $org = $num2orgHash{$i};
		if (exists $noUseOrgsHash{$i}) { next;}
		pop @{$orgHash{$orgNum}};
	    }
	}

# distance matrix
	my @orgs = keys %tmpHash;
	foreach my $org1 (@orgs)
	{
	    foreach my $org2 (@orgs)
	    {
		$similarityTable{$org1}{$org2}++;
	    }
	}
    }
    close PHYL;
}

sub numerically
{
    return $a <=> $b;
}
