%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname proj_lib "&root_dir\data\sas";
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;

* 1. Missing Values Analysis ;
title 'Montreal Crime Study^n
-----------------------^nExploratory Analysis^n
-----------------------^n1.Missing Values Analysis';
 data missing_table(keep=type location borough Police_Division);
	length type $15.;
	set proj_lib.crime_data nobs=n;
	call symputx('N',n, 'G');
	
	retain location 0 borough 0 Police_Division 0 ;
	if missing(LONGITUDE)  then Location + 1;
	if missing(ARRONDIS)  then Borough + 1;
	if missing(DIVISION)  then Police_Division + 1;
	
	if _N_ EQ n then do;
		type = 'Count';
		output;
		Location = put(Location / n,7.2);
		Borough = put(Borough / n,7.2);
		Police_Division = put(Police_Division / n,7.2);
		type='Percent';
		output;
	end;
run;
PROC TRANSPOSE DATA=missing_table out=missing_table name=Variable;
	ID TYPE;
run;

proc print data=missing_table noobs;
	format Percent percent7.1 Count comma.;
run;
*-------------------------------------------------------------------------------;
title '2. Univariate Analysis^n';
title2'i. Number of Crimes per Category';
proc freq data=proj_lib.crime_data  noprint;
	tables CATEGORIE / nopercent nocum out=temp1;
run;

proc sort data=temp1 out=temp1;
	by Descending Count;
run;

proc sgplot data=temp1 noautolegend;
	hbarparm category=categorie response=count / group=categorie;
	xaxis grid;
run;
*-----------------------------------------------------;


ods graphics off;
