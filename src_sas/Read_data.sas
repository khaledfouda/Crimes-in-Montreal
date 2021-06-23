/*All the plots and tables produced in this and other SAS files can be exported in a png form. 
The lines to export are commented. Uncomment them if you need the files and 
don't forget provide the folder where you need to have them in print_dir macro variable */

%let datafile = "&root_dir\data\output\Police_Interventions_cleaned.csv";
%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname DataLib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS\EDA; 
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*---------------------------------------------;

/*Read the data and put it in a permanent sas-data-file*/
data DataLib.Crime_Data;
	length category $25
		   ARRONDIS  $40
		   DIVISION $80
		   QUART $10;
	informat DATE yymmdd.
			 LONGITUDE LATITUDE best32.;
	infile &datafile dsd dlm =',' FIRSTOBS=2;
	input category $
		  DATE 
		  ARRONDIS $
		  QUART $
		  DIVISION $
		  PDQ
		  LONGITUDE
		  LATITUDE;
	*Missing coordinations has values of 1. Note that if LONGITUDE=1  THEN LATITUDE=1;
	IF LONGITUDE EQ 1 THEN DO;
		LONGITUDE = .;
		LATITUDE = .;
	END;
	IF ARRONDIS EQ 'NA' then ARRONDIS = '';
	IF DIVISION EQ 'NA' then DIVISION = '';
	format DATE DDMMYY10.;
	MONTH = put(DATE, monname3.);
	YEAR = year(DATE);
	label category='Crime Category'
	      DATE = 'Date'
	      ARRONDIS = 'district'
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
title2 'Total number of rows is 191,611.';
footnote 'A different sample is generated every time you run the code.';
proc surveyselect data=DataLib.crime_data method=srs rep=1
	sampsize=&n_sample out=work.sample_print(drop=Replicate) noprint;
	id _all_;
run;
proc print data=work.sample_print noobs label;
run;
*---------------
Optional - We export only 3 random rows to a file. Uncomment if needed.
;
/* options printerpath=png nodate papersize=('6.8in','3.5in') nonumber; */
/* ods _all_ close; */
/* ods printer file="&print_dir\sample_table.png"; */
/*  */
/* title 'A sample of 3 obseravations.'; */
/* footnote; */
/* proc print data=work.sample_print(obs=3) label; */
/* run; */
/* ods printer close; */
/* ods listing; */
*------------------------
* Print column descroptions from proc contents; 
*Uncomment the following to save to file.;
*ods _all_ close; 
*options printerpath=png nodate papersize=('4.8in','4.5in') nonumber; 
*ods printer file="&print_dir\table_contents.png";
ods select Variables;
title;title2;footnote;
 proc contents data=work.sample_print; 
 run; 
 *ods printer close; 
 *ods listing; 
