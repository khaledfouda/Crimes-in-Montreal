%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
%let datafile = "&root_dir\data\output\Police_Interventions_cleaned.csv";
libname proj_lib "&root_dir\data\sas";


data proj_lib.Crime_Data;
	length CATEGORIE $25
		   ARRONDIS  $40
		   DIVISION $80
		   QUART $10;
	informat DATE yymmdd.
			  LONGITUDE LATITUDE best32.;
	infile &datafile dsd dlm =',' FIRSTOBS=2;
	input CATEGORIE $
		  DATE 
		  ARRONDIS $
		  QUART $
		  MONTH
		  YEAR
		  DIVISION $
		  PDQ
		  LONGITUDE
		  LATITUDE;
	*Missing coordinations has values of 1. Note that if LONGITUDE=1  THEN LATITUDE=1;
	IF LONGITUDE EQ 1 THEN LONGITUDE = .;
	format DATE DDMMYY10. MONTH EURDFMN12.;
	label CATEGORIE='Crime Category'
	      DATE = 'Date'
	      ARRONDIS = 'Borough'
	      QUART = 'Time of Day'
	      MONTH = 'Month'
	      YEAR = 'Year'
	      DIVISION = 'Police Division'
	      PDQ = 'Police Division ID'
	      LONGITUDE = 'Location Long.'
	      LATITUDE = 'Location Lat.';
run;
*--------------------;
%let n_sample = 20;
* The following prints a sample of random n_sample  rows from the data,
Every time the code is run, a new random sample is show.
;
title "A random sample of &n_sample observations from the data";
title2 'Total number of rows is 191611 with 8 variables.';
footnote 'A different sample is generated every time you run the code.';
proc surveyselect data=proj_lib.crime_data method=srs rep=1
	sampsize=&n_sample out=work.sample_print(drop=Replicate) noprint;
	id _all_;
run;
proc print data=work.sample_print noobs label;
run;
*---------------;