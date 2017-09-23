#!/usr/bin/perl

package ProcessNodeFiles;
#use strict;
#use warnings;

#BUG: change $genomeTree with fileRootNodeFile

# First input: Node file from GeneTrace
# eg: perl processNodeFiles.pl genomeTree.nodes

sub process_node_files{

#my $genomeTree = shift @ARGV;
my $genomeTree =  $_[0];

open OLDOUT, '>&STDOUT';
open STDOUT, '>', "gainLosses.output";

my $node = '';
my @nodeFileLines;

open(NODE_FILE_READER, $genomeTree);
while (<NODE_FILE_READER>) {
    chomp;
    ($node) = split(" ");
    push @nodeFileLines, $node;
}
close NODE_FILE_READER;


my $fileSize = $#nodeFileLines; #+1;

for(my $idRoot=0; $idRoot<1; $idRoot++){
    
    my $fileRoot;
    for(my $NR=0; $NR <= $#nodeFileLines; $NR++){
        if($NR == $idRoot){
            $fileRoot = $nodeFileLines[$NR];
        }
    }
    
    #print "fileRoot\: $fileRoot\n";
    
    my $fileRootNodeFile = "$fileRoot.node";
    my @fRootNodeFLines;
    
    #open(FILEROOT_NODE_FILE_READER, $genomeTree);
    open(FILEROOT_NODE_FILE_READER, $fileRootNodeFile);
    while (<FILEROOT_NODE_FILE_READER>) {
        ($node) = $_;
        $node =~ s/\r|\n//g;
        push @fRootNodeFLines, $node;
    }
    close FILEROOT_NODE_FILE_READER;
    
    
    #print "\n\>\>\> fRootNodeFLines\:\n";
    #my $counter=1;
    #foreach my $line (@fRootNodeFLines){
    #    print "$line -$counter\n";
    #    $counter++;
    #}
    
    
    my $maxRoot = $#fRootNodeFLines; #+1;
    #print "maxRoot\: $maxRoot\n";
    
    my @tmpNodesArray;
    
    my $cnt=0;
    foreach my $line (@fRootNodeFLines){
        
        #print "$line, cnt = $cnt\n";
        
        if($cnt!=0 && $cnt!=$maxRoot){
            #print "line \'$line\' was pushed";
            push @tmpNodesArray, $line;
        }
        $cnt++;
    }
    
    
    my @sortedNodesArray = sort { lc($a) cmp lc($b) } @tmpNodesArray;
    
    #print "tmpNodesArray\: @tmpNodesArray\n";
    
    
    #print "sortedNodesArray\: @sortedNodesArray\n";
    
    foreach my $line (@sortedNodesArray){
        print "$fileRoot \t $line \t H\n";
    }
    
    #print "\n\n%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n\n\n";
}

   
    my @fullNodeFileLines;
    
    open(NODE_FILE_READER, $genomeTree);
    while (<NODE_FILE_READER>) {
        #chomp;
        my $line = $_;
        $line =~ s/\r|\n//g;
        push @fullNodeFileLines, $line;
    }
    close NODE_FILE_READER;
    
    
    for(my $id=1; $id<=$fileSize; $id++){
        my $fileChild;
        my $fileParent;
        
        my @values;
        my $cnt=0;
        foreach my $line (@fullNodeFileLines){
            if($cnt == $id){
                @values = split(' ', $line);
                
                $fileChild = $values[0];
                $fileParent = $values[1];
                last;
            }
            $cnt++;
        }
        
        #print "----$fileChild $fileParent---\n";
        
        my $fileChildNode = "$fileChild.node";
        open(FH, $fileChildNode);
        my @fileChildNodeLines = <FH>;
        close FH;
        my $maxChild = $#fileChildNodeLines; #+1;
        
        
        my $fileParentNode = "$fileParent.node";
        open(FH, $fileParentNode);
        my @fileParentNodeLines = <FH>;
        close FH;
        my $maxParent = $#fileParentNodeLines; #+1;
        
        my @tmpFileChildNodeLines;
        my @tmpFileParentNodeLines;
        
        $cnt=0;
        foreach my $line (@fileChildNodeLines){
            if($cnt != 0 && $cnt!=$maxChild){
                #$line =~ /^(.*?)\s/;
                $line =~ s/\r|\n//g;
                my @tmpSubstr = split(" ", $line);
                push @tmpFileChildNodeLines, $tmpSubstr[0];
                
                #print "\n\>\> $line was pushed\n";
            }
            $cnt++;
        }
        
        my @sortedFileChildNodeLines = sort { lc($a) cmp lc($b) } @tmpFileChildNodeLines;
        
        #print "sortedFileChildNodeLines\: @sortedFileChildNodeLines\n%%%%%%%%%\n";
        
        my $tmpFChildH = "$fileChild.clear";
        open FH, "> $tmpFChildH" or die "can't open '$tmpFChildH': $!"; 
        foreach ( @sortedFileChildNodeLines )
        {
            print FH $_;
        }
        close FH;
        
        
        $cnt=0;
        foreach my $line (@fileParentNodeLines){
            if($cnt != 0 && $cnt!=$maxParent){
                #$line =~ /^(.*?)\s/;
                $line =~ s/\r|\n//g;
                my @tmpSubstr = split(" ", $line);
                push @tmpFileParentNodeLines, $tmpSubstr[0];
            }
            $cnt++;
        }
        
        my @sortedFileParentNodeLines = sort { lc($a) cmp lc($b) } @tmpFileParentNodeLines;
        
        #print "sortedFileParentNodeLines\: @sortedFileParentNodeLines\n%%%\n";
        
        my $tmpFParentH = "$fileParent.clear";
        open FH, "> $tmpFParentH" or die "can't open '$tmpFParentH': $!";
        foreach ( @sortedFileParentNodeLines )
        {
            print FH $_;
        }
        close FH;
        
        #substitute diff with perl code
        system("diff $fileChild.clear $fileParent.clear > differences.temp");
        
        my $tmpFName = "differences.temp";
        open(FH, $tmpFName);
        my @tmpDiffArr = <FH>;
        close FH;
        
        #print "\>\>\.\.\. differences.temp\:\n";
        foreach my $line (@tmpDiffArr){
            #    print "$line\n";
        }
        #print "^^^^^^^^^^^^^^^^^^\n";
        
        #`grep ">" differences.temp | cat | sed 's/..\(.*\)/\1/' > lostGenes.temp`;
        
        my $differencesTemp = "differences.temp";
        open(FH, $differencesTemp);
        my @differencesTempLines = <FH>;
        close FH;
        my @tmpLostGenes = grep />/, @differencesTempLines;
        my @subsLostGenes;
        
        foreach my $line (@tmpLostGenes){
            #$line =~ s/^..//;
            $line =~ s/^..(.*)/$1/;
            my @tmpSubstr = split(" ", $line);
            push @subsLostGenes, $tmpSubstr[0];
        }
        my $tmpFH = "lostGenes.temp";
        open FH, "> $tmpFH" or die "can't open '$tmpFH': $!";
        foreach ( @subsLostGenes )
        {
            print FH $_;
        }
        close FH;
        
        #-----------------
        $tmpFName = "lostGenes.temp";
        open(FH, $tmpFName);
        @tmpDiffArr = <FH>;
        close FH;
        
        #print "\>\>\.\.\. lostGenes.temp\:\n";
        foreach my $line (@tmpDiffArr){
            #    print "$line\n";
        }
        #print "^^^^^^^^^^^^^^^^^^^\n";
        
        #`grep "<" differences.temp | cat | sed 's/..\(.*\)/\1/' > gainedGenes.temp`;
    
        my $differencesTemp_2 = "differences.temp";
        open(FH, $differencesTemp_2);
        my @differencesTempLines_2 = <FH>;
        close FH;
        my @tmpLostGenes_2 = grep /</, @differencesTempLines_2;
        my @subsLostGenes_2;
        
        foreach my $line (@tmpLostGenes_2){
            #$line =~ s/^..//;
            $line =~ s/^..(.*)/$1/;
            my @tmpSubstr = split(" ", $line);
            push @subsLostGenes_2, $tmpSubstr[0];
        }
        my $tmpFH_2 = "gainedGenes.temp";
        open FH, "> $tmpFH_2" or die "can't open '$tmpFH_2': $!";
        foreach ( @subsLostGenes_2 )
        {
            print FH $_;
        }
        close FH;
        
        #-----------------
        $tmpFName = "gainedGenes.temp";
        open(FH, $tmpFName);
        @tmpDiffArr = <FH>;
        close FH;
        
        #print "\>\>\.\.\. gainedGenes.temp\:\n";
        foreach my $line (@tmpDiffArr){
            #    print "$line\n";
        }
        #print "^^^^^^^^^^^^^^^^^^^\n";
        
        `comm -1 -2 $fileChild.clear $fileParent.clear > commonGenes.temp`;
        
        
        my $comGenesTmp = "commonGenes.temp";
        open(FH, $comGenesTmp);
        my @commonGenesTempLines = <FH>;
        close FH;
        
        foreach my $line (@commonGenesTempLines){
            #$line =~ /^(.*?)\s/;
            $line =~ s/\r|\n//g;
            my @tmpSubstr = split(" ", $line);
            print "$fileChild \t $tmpSubstr[0] \t H\n";
        }
        
        
        my $gainGenesTmp = "gainedGenes.temp";
        open(FH, $gainGenesTmp);
        my @gainedGenesTempLines = <FH>;
        close FH;
        
        foreach my $line (@gainedGenesTempLines){
            #$line =~ /^(.*?)\s/;
            $line =~ s/\r|\n//g;
            print "$fileChild \t $line \t G\n";
        }
        
        
        my $lostGenesTmp = "lostGenes.temp";
        open(FH, $lostGenesTmp);
        my @lostGenesTempLines = <FH>;
        close FH;
        
        foreach my $line (@lostGenesTempLines){
            #$line =~ /^(.*?)\s/;
            $line =~ s/\r|\n//g;
            print "$fileChild \t $line \t L\n";
        }
        
        unlink glob('*.temp');
}

unlink glob('*.clear');

close STDOUT;

open STDOUT, '>&OLDOUT' or die "Can't restore stdout: $!";
close OLDOUT or die "Can't close OLDOUT: $!";
}
1;
