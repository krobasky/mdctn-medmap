#!/usr/bin/perl
use strict;
use warnings;
# Name: lookupCUI.pl
#
# Looks up values for an RxCUI code from NCBI
#
# Dependencies:
#   JSON
#   MIME::Base64
#   REST::Client
#   FILE::Basename
#
# Copyright 2018 University of North Carolina Board of Trustees
# All Rights Reserved

my $version="1.0";
my $sccver='$Id:$';
use File::Basename;

sub display_usage {
    print "
Version $version $sccver
Usage:\n  ".(basename $0)." [-r <rxCUI>] [-h]
Looks up values for an RxCUI code from NCBI
  -r rxCUI	an rxnorm or RxCUI code, defined on the NCBI home pages
  -h 		This message

Copyright 2018 University of North Carolina Board of Trustees
All Rights Reserved

License: GNU GPL 2
".(basename $0)." comes with ABSOLUTELY NO WARRANTY; 
This is free software, and you are welcome to redistribute it under certain conditions.
Author: Kimberly Robasky, krobasky\@renci.org
Created On: 2018
";
}


use JSON;
use MIME::Base64;
use REST::Client;

my $host='https://rxnav.nlm.nih.gov';
sub getPath { return "/REST/rxcui/$_[0]/allProperties.json?prop=all"; }
my @propNames = ("RxNorm Name",
		 "GENERAL_CARDINALITY",
		 "QUANTITY",
		 "AVAILABLE_STRENGTH");
use Getopt::Long;
our ($gVerbose,$gHelp);
my $rxCUI;
GetOptions ("rxCUI=s"   => \$rxCUI,  
	    "help"   => \$gHelp,  
	    "verbose"  => \$gVerbose)
    or die("Error in command line arguments\n".display_usage());
if($gHelp) {display_usage(); exit(0);}

my $headers = {Accept => 'application/json'};
my $client = REST::Client->new();
$client->setHost($host);
$client->GET(getPath($rxCUI),$headers);

####
# response looks a bitlike this:
#{"propConceptGroup":
# {"propConcept":[
#     {"propCategory":"NAMES","propName":"RxNorm Name","propValue":"1 ML Diphenhydramine Hydrochloride 50 MG/ML Prefilled Syringe"}, ...
#   ]
# }
#}
####
my $response = from_json($client->responseContent());
my $propCategories = toList($response->{'propConceptGroup'},'propConcept');
my %values=();
foreach my $p (@propNames){
    $values{$p}="not found.";
    foreach my $cat (@$propCategories) {
	if($cat->{'propName'} eq $p) {$values{$p}=$cat->{'propValue'};}
    }
}
foreach my $p (@propNames){
    print "$p\t$values{$p}\n";
}

sub toList {
    my $data = shift;
    my $key = shift;
    if (ref($data->{$key}) eq 'ARRAY') {
	$data->{$key};
    } elsif (ref($data->{$key}) eq 'HASH') {
	[$data->{$key}];
    } else {
	[];
    }
}
