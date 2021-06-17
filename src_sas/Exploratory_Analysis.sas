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
	call symput('N',n);
	
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

title '2. Univariate Analysis';
title2'i. Number of Crimes per Category';

*-----------------------------------------------------;
proc freq data=proj_lib.crime_data  noprint;
	tables CATEGORIE / nopercent nocum out=temp1;
	
run;

proc sort data=temp1 out=temp1;
	by Descending Count;

run;
data _null_;
	length allvars $1000;   
	retain allvars ' ';   
	set temp1 end=eof;
		allsum + count;
		allvars = trim(left(allvars))||' '||left(put(count,12.));   
		if eof then do;
			call symput('count_l', allvars);
			call symput('sum_catg',allsum);
			%put &=count_l &=N;
		end;
run;


data anno_catg;
	set temp1 end=_last_;
	length /*x1space $11 y1space $13*/ anchor$6 function $13
		style $10 xc2 $15 direction $10 label $300;
 	 
	xc1 = categorie;
	drop count categorie;
	if categorie eq 'Fatal Crime' then y1 = count +3000;
	else y1 = count - 2000;
	retain function "text" drawspace 'datavalue' width 15
		justify "center"  anchor "top" xc2 '' HSYS . size . style '' y2 0 direction '' scale .  ;
	label=strip(put(count/&N,percent12.1));
	output;
 run;

proc sql;

	insert into work.anno_catg(function, 
	drawspace,xc1, xc2, y1, y2, 
	direction, style, scale)
	values ('Arrow', 
	'datavalue', 'Fatal Crime', 'Fatal Crime', 4800, 30000, 
	'in', 'FILLED', .001);
	
	insert into work.anno_catg(function,
	drawspace, xc1, y1,
	anchor, justify, width, label)
	values("text",
	'datavalue', 'Auto theft', 38449,
	'left', 'center', 52, '    Fatal Crimes had an increase of 19.2% in 2018 and a decrease of 22.6% in 2019')
	;
quit;

	

proc sgplot data=temp1 noautolegend sganno=anno_catg pad=(bottom=15%);
 *title 'Total number of crimes per category';
	vbarparm category=categorie response=count / group=categorie;
	xaxis fitpolicy=none label='Category';
	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total';
run;

*------------------------------------------------------;

ods graphics off;
