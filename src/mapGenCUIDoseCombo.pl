#!/usr/bin/perl
use strict;
use warnings;
# Name: mapGenCUIDoseCombo.pl
#
# Combines multiple MDCTN records onto a single line.
#
# Dependencies:
#   lookupCUI.pl
#   File::Basename
#   Switch
#
# Copyright 2018 University of North Carolina Board of Trustees
# All Rights Reserved

my $version="1.0";
my $sccver='$Id:$';

my $dirname = dirname(__FILE__);
my $lookupCUI="$dirname/lookupCUI.pl";
use File::Basename;
use Cwd 'abs_path';
my $gRoot = dirname(abs_path($0))."/..";
my $gTargetFile   = "${gRoot}/config/map.medTarget-RxCUI";

sub display_usage {
    print "
Version $version $sccver
Usage:\n  ".(basename $0)." [-t <med-targets>] [-h]
Combines multiple MDCTN records onto a single line.
  -t med-targets	Tab-delimited, manually curated list of interesting drugs, paired to their most generic RxCUI [$gTargetFile]
  -h 			This message

Copyright 2018 University of North Carolina Board of Trustees
All Rights Reserved

License: GNU GPL 2
".(basename $0)." comes with ABSOLUTELY NO WARRANTY; 
This is free software, and you are welcome to redistribute it under certain conditions.
Author: Kimberly Robasky, krobasky\@renci.org
Created On: 2018
";
}

use Getopt::Long;
my $gHelp;
our $gVerbose;
GetOptions ("targetFile=s"   => \$gTargetFile,  
	    "help"   => \$gHelp,  
	    "verbose"  => \$gVerbose)
    or die("Error in command line arguments\n".display_usage());
if($gHelp) {display_usage(); exit(0);}

# name = long hand description from an rxnorm lookup ("RxNorm Name")
# label = short string used to match drug targets of interest with the MDCTN catalog entries
our %genLabel2CUI=();
our %genCUI2Label=();
open(MAP,"<",$gTargetFile) or die ("Can't open $gTargetFile");
while(<MAP>){
    if(m/^#/){next;}
    chomp();
    my ($label,$CUI)=split("\t");
    my ($scrap, $name)=split("\t",`${lookupCUI} -r $CUI|grep "RxNorm Name"`);
    chomp($name);
    sleep(1); # don't go too fast or you might get banned from the service
    $genCUI2Label{$CUI}=$label;
    $genLabel2CUI{$label}=$CUI;
    $genLabel2CUI{"$label-name"}=$name;
}

# Use a statemachine pattern
my (%next, %curr);
$_=<STDIN>;
chomp();
($next{"MDCTN"},$next{"RxCUI"},$next{"label"},$next{"name"})=split("\t");
my %MDCTNstr=();
my %CUI2Name=();
our $state="START_REC";
while(<STDIN>) {
    chomp();
    ($curr{"MDCTN"},$curr{"RxCUI"},$curr{"label"},$curr{"name"})=
	($next{"MDCTN"},$next{"RxCUI"},$next{"label"},$next{"name"});
    ($next{"MDCTN"},$next{"RxCUI"},$next{"label"},$next{"name"}) = split("\t");
    run_state_machine(\%curr, $next{"MDCTN"}, \%CUI2Name, \%MDCTNstr);
}	

# Advance the machine state one more time for the last line:
($curr{"MDCTN"},$curr{"RxCUI"},$curr{"label"},$curr{"name"})=
    ($next{"MDCTN"},$next{"RxCUI"},$next{"label"},$next{"name"});
($next{"MDCTN"},$next{"RxCUI"},$next{"label"},$next{"name"}) = ("","","","");
run_state_machine(\%curr, $next{"MDCTN"}, \%CUI2Name, \%MDCTNstr);

sub run_state_machine {
    my ($c, $nextMDCTN, $C2N, $meds)=@_;

    use Switch;
    switch($state) {
	case "START_REC" {
	    if(exists $meds->{$c->{"MDCTN"}} && $meds->{$c->{"MDCTN"}} ne "") { print STDERR "WARNING:".$c->{"label"}."\t".$c->{"MDCTN"}."\t".$c->{"RxCUI"}."\t".$c->{"name"}."\n";}

	    for(keys %$C2N){delete $C2N->{$_};}
	    $C2N->{$genLabel2CUI{$c->{"label"}}}=$genLabel2CUI{$c->{"label"}."-name"};
	    if($genLabel2CUI{$c->{"label"}} ne $c->{"RxCUI"}) { $C2N->{$c->{"RxCUI"}}=$c->{"name"}; }
	    
	    # If this MDCTN has only one record, handle it here
	    if($nextMDCTN ne $c->{"MDCTN"} ) {
		output_record($c->{"label"},$c->{"MDCTN"}, $C2N, \%genCUI2Label, $meds);
	    } else {
		$state="IN_REC";
	    }
	}
	case "IN_REC" {
	    if(! exists $C2N->{$c->{"RxCUI"}} || $C2N->{$c->{"RxCUI"}} eq "") {	
		$C2N->{$c->{"RxCUI"}}=$c->{"name"};
	    }
	    if($nextMDCTN ne $c->{"MDCTN"} ) {
		output_record($c->{"label"},$c->{"MDCTN"}, $C2N, \%genCUI2Label, $meds);
		$state="START_REC";
	    }
	}
    }
}

sub output_record {
    my ($label, $mdctn, $C2N_ref, $genC2L, $m) = @_;
    my %C2N=%{$C2N_ref};

    my $CUIStr = ""; my $nameStr="";
    foreach my $genCUI (keys %{$genC2L}) {
	foreach my $CUI (sort keys %C2N ) {
	    if($CUI eq $genCUI) {
		$CUIStr.="$CUI;";
		$nameStr.="$C2N{$CUI};";
		# remove $CUI from %C2N
		delete $C2N{$CUI};
	    }
	}
    }
    
    $CUIStr.="\t";
    $nameStr.="\t";
    foreach my $CUI (sort keys %C2N) {
	$CUIStr.="$CUI;";
	$nameStr.="$C2N{$CUI};";
    }
    
    print $label."\t".$mdctn."\t".$CUIStr."\t".$nameStr."\n";
    $m->{$mdctn}=$label."\t".$mdctn."\t".$CUIStr."\t".$nameStr;
}
