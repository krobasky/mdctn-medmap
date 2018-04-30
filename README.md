
# Quick Start:

`./src/pipeline.sh --help`  

## Summary

_outputs_:  
+ `map.mdctn-dose-units-drug`  
+ `map.MDCTN-genRxCUIs-genNames-subRxCUIs-subNames`  

_inputs_:  
+  -t *med-targets*        Tab-delimited, manually curated list of interesting drugs, paired to their most generic RxCUI [config/map.medTarget-RxCUI]
+  -c *med-codes*          i2B2 export
+  -p *problem-codes*      codes that have identified problems and don't appear in i2B2 observation data for analysis [config/problem-codes.txt]

## Details
 
**OUTPUTS**: 

+ `map.mdctn-dose-units-drug`  
Tab-delimited file  
_Columns:_
```
| Col | Name     | Description                                                                                         |
| --- |:--------:| ---------------------------------------------------------------------------------------------------:|
| 1   | MDCTN    | Medication code, every code represented from CONCEPT_DIMENSION.csv,                                 |
|     |          |    e.g., MDCTN:00005306231                                                                          |
| 2   | dose     | Integer amount of dose                                                                              |
|     |          |    e.g.,  200                                                                                       |
| 3   | units    | Units of dose                                                                                       |
|     |          |    e.g.,  mg                                                                                        |
| 4   | drug     | Drug name, from config/map.medTarget-RxCUI                                                          |
|     |	         |    e.g., prednisone                                                                                 |
```

+ `map.MDCTN-genRxCUIs-genNames-subRxCUIs-subNames`  
Tab-delimited file  
_Columns:_
```
| Col | Name     | Description                                                                                         |
| --- |:--------:| ---------------------------------------------------------------------------------------------------:|
| 1   | MDCTN    | Medication code, every code represented from CONCEPT_DIMENSION.csv                                  |
|     |          |    e.g., MDCTN:00005306231                                                                          |
| 2   | genCUI   | semi-colon delimited list of general medication names, without dosing or compound drug information |
|     |          |    e.g.,  25255;108118;   formoterol;Mometasone;                                                    |
| 3   | labels   | semi-colon delimited list of drug labels (most general, not including dose or other compounds)      |
|     |          |    e.g.,  prednisone                                                                                |
| 4   | broadCUI |semi-colon delimited list of CUIs, not including anything from genCUI                                |
|     |	         |    e.g., 245314;745679;                                                                             |
| 5   |  names   |semi-colon delimited list of the names of each MDCTN as found in the CONCEPT_DIMENSION.csv           |
```

**Inputs:**

+ -c *med-codes*
i2B2 export  
e.g., `CONCEPT_DIMENSION.csv`  
Tab-delimited file  
_Columns:_
```
| Col | Name            | Description                                                                                         |
| --- |:---------------:| ---------------------------------------------------------------------------------------------------:|
| 1   | CONCEPT_PATH    |  path may contain the rxCUI code                                                                    |
|     |                 |    e.g., "\i2b2\MEDS\N0000010574\N0000029154\N0000029160\RX:313847\MDCTN:24730\"                    |
| 2   | CONCEPT_CD      |  the MDCTN code                                                                                     |
|     |                 |    e.g., "MDCTN:24730"                                                                              |
| 3   | NAME_CHAR       |  free text string describing drug, dose and units                                                   |
|     |                 |    e.g., "alitretinoin 0.001 MG/MG Topical Gel"                                                     |
| 4   | CONCEPT_BLOB    |  ignored                                                                                            |
| 5   | UPDATE_DATE     |  ignored                                                                                            |
| 6   | DOWNLOAD_DATE   |  ignored                                                                                            |
| 7   | IMPORT_DATE     |  ignored                                                                                            |
| 8   | SOURCESYSTEM_CD |  ignored                                                                                            |
| 9   | UPLOAD_ID       |  ignored                                                                                            |
```

+ -t *med-targets*  
Tab-delimited, manually curated list of interesting drugs, paired to their most generic RxCUI  
e.g., `config/map.medTarget-RxCUI`  
Tab-delimited file  
_Columns:_
```
| Col | Name  | Description                                                                                         |
| --- |:-----:| ---------------------------------------------------------------------------------------------------:|
| 1   | label |  path may contain the rxCUI code                                                                    |
|     |       |    e.g.,  prednisone                                                                                |
| 2   | rxCUI |  standardized rxnorm ID from https://rxnav.nlm.nih.gov                                              |
|     |       |    e.g., 8640                                                                                       |
```

+ -p *problem-codes*  
ASCII list of codes that have identified problems and that don't appear in i2B2 observation data for analysis  
e.g., `config/problem-codes.txt`  

## Directories:

`src`    : all programs, incidental scripts, test cases and teset data  
`config` : configuration files here

## Dependencies:
Use `sudo cpan install <dependency>` to ensure each of the following are installed:  
+ Data:Dumper
+ File::Basename
+ Cwd
+ Getopt::Long
+ Switch
+ JSON
+ MIME::Base64
+ REST::Client

