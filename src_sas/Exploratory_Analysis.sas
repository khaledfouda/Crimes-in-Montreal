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
*-------------------------------------------------------------------------------
           plot 1 -  Histogram of categories
--------------------------------------------------------------------------------
;

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
	set temp1 end=eof;
	retain allvars ' ';   
	allvars = trim(left(allvars))||' '||left(put(count,12.));   
	if eof then do;
		call symput('count_l', allvars);
		%put &=count_l &=N;
	end;
run;


data anno_catg;
	set temp1 end=_last_;
	length  anchor$6 function $13
		style $10 xc2 $15 direction $10 label $300
		x1space y1space x2space y2space $15;
 	 
	xc1 = categorie;
	drop count categorie;
	if categorie eq 'Fatal Crime' then y1 = count +3000;
	else y1 = count - 2000;
	retain function "text" drawspace 'datavalue' width 15
	x1 . x2 .  y2 . xc2 '' X1SPACE '' X2SPACE '' Y1SPACE '' Y2SPACE ''
		justify "center"  anchor "top" HSYS . size . style '' y2 0 direction '' scale . transparency . ;
	label=strip(put(count/&N,percent12.1));
	output;
 run;

proc sql;

	insert into work.anno_catg (function, 
	drawspace,xc1, xc2, y1, y2, 
	direction, style, scale, transparency)
	values ('Arrow', 
	'datavalue', 'Fatal Crime', 'Fatal Crime', 4800, 12000, 
	'in', 'FILLED', .001, .5);
	
	insert into work.anno_catg(function,
	x1space, y1space,
	x1, y1,
	anchor, justify, width, label)
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	310, 20000,
	'left', 'center', 40, 'Fatal Crimes had an increase of 19.2% in 2018 and a decrease of 22.6% in 2019')
	;
quit;


proc sgplot data=temp1 noautolegend sganno=anno_catg noborder nowall/*pad=(bottom=15%)*/  ;
 *title 'Total number of crimes per category';
	vbarparm category=categorie response=count / group=categorie transparency=.2;
	xaxis fitpolicy=none label='Category' labelattrs=(size=12);
	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total' labelattrs=(size=12);
run;
*-------------------------------------------------------------------------------
           plot 2 -  Histogram of districts
--------------------------------------------------------------------------------
;
proc freq data=proj_lib.crime_data noprint;
	tables Arrondis / nopercent nocum out=temp1;
run;
proc sort data=temp1 out=temp1;
	where percent > 3;
	by descending count;
run;


data anno;
	set temp1 end=_last_;
	length  anchor$6 function $13 
		style $10 xc2 $15 direction $10 label $300
		X1SPACE X2SPACE Y1SPACE Y2SPACE $15;
 	 
	xc1 = arrondis;
	y1 = count;
	retain function "text" drawspace 'datavalue' width 15 textweight 'Bold'
		justify "center"  anchor "top" 
		x1 . x2 .  y2 . xc2 '' X1SPACE '' X2SPACE '' Y1SPACE '' Y2SPACE ''
		HSYS . size . style '' direction '' scale .  transparency .;
	label=strip(put(count/&N,percent12.1));
	
	sum_percent + percent;
	if _last_ then call symput('sum_percent', strip(put(sum_percent, 6.1)));
	drop count percent arrondis sum_percent;
 run;

proc sql;

	insert into work.anno(function, 
	x1space, x2space, y1space, y2space,
	x1, x2, y1, y2, 
	direction, style, scale, transparency)
	values ('Arrow', 
	'DATAPIXEL','DATAPIXEL', 'DATAVALUE','DATAVALUE',
	22, 43, 27000, 27000, 
	 "IN", "BARBED", .000001, .4)
	 values ('Arrow', 
	'DATAPIXEL','DATAPIXEL', 'DATAVALUE','DATAVALUE',
	35, 35, 19000, 17500, 
	 "OUT", "BARBED", .000001, .4)
	 values ('Arrow', 
	'DATAPIXEL','DATAPIXEL', 'DATAVALUE','DATAVALUE',
	85, 85, 16000, 14500, 
	 "OUT", "BARBED", .000001, .4);
	 
	
	insert into work.anno(function,
	x1space, y1space,
	x1, y1,
	anchor, justify, width, label)
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	45, 27000, 
	'left', 'center', 15, 'Downtown')
	/****************/
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	30, 21000, 
	'left', 'center', 40, 'Decreased by 28.4% in 2018')
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	30, 20000, 
	'left', 'center', 40, 'Biggest change overall')
	/***********/
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	80, 18000, 
	'left', 'center', 40, 'Increased by 10% in 2019')
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	80, 17000, 
	'left', 'center', 40, 'Biggest increase overall')
	;
quit;





proc sgplot data=temp1 sganno=anno ; 
 title 'Total number of crimes per district';
 title2 'Only those contributing to at least 3% of the total crime rate are shown';
 title3 "They contribute to &sum_percent% of crime";
	vbarparm category=arrondis response=count / group=arrondis name='v' transparency=.2;
	keylegend 'v' / across = 1 position=TOPRIGHT location=inside valueattrs=(Size=10);
	xaxis display=(NOVALUES noticks) fitpolicy=none label='District' labelattrs=(size=12);
	yaxis  tickvalueformat=comma. valueshint integer label='Total' labelattrs=(size=12);
run;

*-----------------------------------------------------------;
*-------------------------------------------------------------------------------
           plot 3 -  timeseries of categories
--------------------------------------------------------------------------------
;

proc freq data=proj_lib.crime_data noprint;
	*format date monyy5.;
	where year not eq 2021;
	tables year * categorie / nopercent nocum norow nocol list out=temp1;
run;

proc sort data=temp1 out=temp1;
	by categorie year;
run;

data temp1;
	set temp1;
	by categorie;
	prv_count = lag(count);
	if first.categorie or count eq prv_count then 
		change = .;
	else change = (count-prv_count)/prv_count;
	if abs(change) le .13 then change=.;
	pos_change = change;
	neg_change = change;
	if pos_change lt 0 then pos_change = .;
	if neg_change gt 0 then neg_change = .;
	format change pos_change neg_change percentn8.1;
	drop prv_count;
run;


proc sgplot data=temp1 noautolegend;
	title 'The evolution of crime total over time';
	title3 'Broken by category and summed over years';
	footnote 'Only significant changes of over 13% are labeled';
	footnote3 "Data related to 2021 were omitted since it is not complete";
	series x=year y=count / group=categorie  lineattrs=(thickness=2) 
	datalabel=pos_change datalabelattrs=(color=GREEN weight=bold size=10) datalabelpos=top 
		curvelabel curvelabelloc=outside curvelabelpos=end curvelabelattrs=(weight=BOLD);
	series x=year y=count / group=categorie datalabel=neg_change
		datalabelattrs=(color=RED weight=bold size=10) datalabelpos=top;
	scatter x=year y=count / group=categorie;
	yaxis label='total' labelattrs=(size=12);
	xaxis label='Time ( JAN 2015 to DEC 2020)' labelattrs=(size=12);
run;




ods graphics off;
