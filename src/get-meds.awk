# Name: get-meds.awk
#
# Tab-delimits 3 fields, honoring quotes
#
# Copyright 2018 University of North Carolina Board of Trustees
# All Rights Reserved
# 
# version=1.0 
# sccver='$Id:$'
BEGIN {
    FPAT = "([^,]+)|(\"[^\"]+\")"
}
{
    n = split($1, a, "\\", seps)
    print a[n-2]"\t"a[n-1]"\t"$3
}

