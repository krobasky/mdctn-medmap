
# Quick Start:
`./src/pipeline.sh`  
  _creates_: `map.MDCTN-genRxCUIs-genNames-subRxCUIs-subNames`  
  _from_: `CONCEPT_DIMENSION.csv`  
  _using_: `src/pipeline.sh`

**OUTPUT**: `map.MDCTN-genRxCUIs-genNames-subRxCUIs-subNames`  
Tab-delimited file  
_Columns:_
```
| Col | Name     | Description                                                                                         |
| --- |:--------:| ---------------------------------------------------------------------------------------------------:|
| 1   | MDCTN    | Medication code, every code represented from CONCEPT_DIMENSION.csv,                                 |
|     |          |	  e.g., MDCTN:00005306231                                                                          |
| 2   | genCUI   | semi-colon delimited list of general medication names, without dosing or compound drug information, |
|     |          |		e.g.,  25255;108118;   formoterol;Mometasone;                                                    |
| 3   | labels   | semi-colon delimited list of drug targets (most general, not including dose or other compounds)     |
|     |          |		e.g.,  prednisone                                                                                |
| 4   | broadCUI |semi-colon delimited list of CUIs, not including anything from genCUI                                |
|     |	         |  	e.g., 245314;745679;                                                                             |
| 5   |  names   |semi-colon delimited list of the names of each MDCTN as found in the CONCEPT_DIMENSION.csv           |
```
_Directories:_  
`src`    : all programs, incidental scripts, test cases and teset data  
`config` : configuration files here
