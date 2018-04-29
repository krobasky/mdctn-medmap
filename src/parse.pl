#!/usr/bin/perl
# awk -F'\t' '{print $1"\t"$3"\t"$4"\t"$5}' ../map.MDCTN-genRxCUIs-genNames-subRxCUIs-subNames |./parse4.pl > check.this
#

use Data::Dumper;

@units = ("mg/ml", "mg","mcg","ml");
#; mg/,mg-,[0-9]mg,[0-9]mg/,mcg/, mcg-,[0-9]ml,);
while(<STDIN>){
    chomp();
    ($mdctn,$drug,$id,$namestr) = split("\t");
    $line=$_;
    chop($drug); # remove ;
    $drug=lc($drug);
    @names=split(";",$namestr);
    foreach (@names){
	if( m/[0-9]/) { # some records just have drug combinations, only look at records with dosage amounts
	   $n= lc();
	   foreach $unit (@units) {
	       $unitsOffset = index($n, $unit) - 1;
	       if($unitsOffset >= 0) {
		 
		   @nameTokens = split(' ', substr($n,0,$unitsOffset));
		   if($nameTokens[$#nameTokens - 1] eq $drug) {
		       # at this point, we've searched all known units and 
		       # found the units that match the drug of interest,
		       $dose = $nameTokens[$#nameTokens];
		       # now standardize the units
		       if($unit eq "mcg") { 
			   $dose = $dose/1000; $unit = "mg"; 
		       }

		       # now see if you've already recorded a dose like this for a drug of interest
		       $doseRecorded=0;
		       foreach $recordedDose (split("\n",$drugs{$id})){
			   ($rd,$ru,$rdrug,$rn,$rm)=split("\t",$recordedDose);
			   if($rn eq $n) {
			       # the same dose has already been handled for this drug, 
			       # ensure the units are the same, otherwise there was an error
			       if("$dose\t$unit" ne "$rd\t$ru") {
				   # should never happen
				   print STDERR "ERROR: $drug($mdctn):$n\n($dose\t$unit) ne ($rd\t$ru)\n";
			       }
			       # map the MDCTN and break out of the outer loops, you're done with this 'name'
			       # xxx don't forget to record the MDCTN
			       $doseRecorded=1;#xxx does this work?
#			       goto NEXTNAME;
			   }
		       }

		       # this is the first time seeing a dose like this for this drug, record it
		       $drugs{$id}.="$dose\t$unit\t($drug)\t$n\t$mdctn\n";

		       # now see if you've already seen this MDCTN code
		       if(exists $meds{$mdctn} && $meds{$mdctn} ne "") {
			   if($meds{$mdctn} ne "$dose\t$unit\t$drug\n") {
			       # you've seen this MDCTN before, but the dose is different
			       ($rd,$ru,$rdrug)=split("\t",$meds{$mdctn});
			       $medsmulti{$mdctn} .= "  $dose\t$unit\t$drug\n";
			       print STDERR "ERROR: multiple doses for $mdctn\n".
				   "$medsmulti{$mdctn}\n";
			   }
		       } else {
			   # you've not seen this MDCTN before, record it
			   $meds{$mdctn} = "$dose\t$unit\t$drug\n"; # this is the hash to print for your final table
			   $medsmulti{$mdctn} = "  $dose\t$unit\t$drug\n"; # keep this hash for printing any errors 
		       }

		       if($doseRecorded) {
			   #you're done, dose is found, don't look at any more units just look at next name
			   goto NEXTNAME;
		       }
		       
		   } # if this unit matched the drug of interest
	       } # if this unit type was found
	   } # foreach unit
	} # if digits in this 'name'

      NEXTNAME:
    } # foreach name
}
if($verbose) {
    print "=== drug to dose mappings ===\n";
    foreach $id (sort keys %drugs) {
	print "$id\n".$drugs{$id}."\n";
    }
    print "=== MDCTN to dose mappings ===\n";
}
foreach $m (sort keys %meds) {
    print "$m\t".$meds{$m};
}
