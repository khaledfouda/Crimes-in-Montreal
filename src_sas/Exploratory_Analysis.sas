libname proj_lib "&root_dir\data\sas";
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
*%let  N = 191611;
* 1. Missing Values Analysis ;
title 'Montreal Crime Study^nExploratory Analysis^n
-----------------------^n1.Missing Values Analysis';
 data missing_table(keep=type location borough pol_div categ quart_na date_na);
	set proj_lib.crime_data nobs=n;
	call symputx('N',n, 'G');
	
	retain location borough pol_div categ quart_na date_na;
	if missing(LONGITUDE)  then Location + 1;
	if missing(ARRONDIS)  then Borough + 1;
	if missing(DIVISION)  then Pol_Div + 1;
	if missing(CATEGORIE)  then Categ + 1;
	if missing(Quart)  then Quart_na + 1;
	if missing(Date) then Date_na +1;
	
	if _N_ EQ n then do;
		type = 'N missing';
		output;
		Location = Location / n;
		Borough = Borough / n;
		Pol_Div = Pol_Div / n;
		Categ = Categ / n;
		Quart_na = Quart_na /n;
		Date_na = Date_na / n;
		type='Percent';
		*drop Date_na Quart_na;
		output;
	end;
run;


proc print data = proj_lib.crime_data;
where 