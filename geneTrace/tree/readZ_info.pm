use strict;
use tree::simple;

sub readInfoFile
{
    my ($infile) = @_;
    my %speHash;
    my $tree = &newTree();

    open (IN, $infile) || die "ERROR: can't open $infile\n";    
    &newNode($tree, 'Root','undef','','');

    my $line;
    while ($line = <IN>)
    {
	if ($line =~ /(\d+)\t+(\d+\/\d+\/\d+)\t+(\S+)\s+([ |\S]+)\t+([ |\S]+)\t+/)
	{
	    my $org = $3;
	    my $name = $4;
	    my $path = $5;
	    my ($familyName, $speName);
	    my $fullName;

	    ($path) = $path =~ /(.+)\./;

	    unless ($path)
	    { print STDERR "\aWORNING: path unrevealed for $org\n"; next;}
	    my @pathList = split (/;\s*/, $path);

	    if ($name =~ /(\S+)\s+(\S+?),*\s/)
	    {
	        ($familyName, $speName) = ($1, $2);
		$fullName = $familyName . "_" . $speName;
		push (@pathList, $fullName);
	    }
	    elsif ($name =~ /(\S+?),*\s+/)
	    {		$fullName = $1;	    }

	    $speHash{$fullName} = 1;

#	    next;    
#	    unless (exists $speHash{$org}){next;}

	    $org = uc $org;
	    push (@pathList, $org);
	    my $parent = 'Root';
	    my $node;
	    
	    foreach $node (@pathList)
	    {
		$node =~ s/ /_/g;
		if ($node eq $parent) {next;}
		my $depth;
		if ($node eq $org)
		{     &newNode($tree, $node, 0, $parent, 'undef');}
		else {&newNode($tree, $node, 'undef', $parent, '');}
		&addKid ($tree, $parent, $node);
		$parent = $node;
	    }
	}
    }
    
    close IN;
#    &findLeafs($tree);
    return (\%speHash, $tree);
}


1;
