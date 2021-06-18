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

	

proc sgplot data=temp1 noautolegend sganno=anno_catg /*pad=(bottom=15%)*/;
 *title 'Total number of crimes per category';
	vbarparm category=categorie response=count / group=categorie;
	xaxis fitpolicy=none label='Category';
	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total';
run;

*------------------------------------------------------;
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
	xaxis display=(NOVALUES noticks) fitpolicy=none label='District';
	yaxis  tickvalueformat=comma. valueshint integer label='Total';
run;

*-----------------------------------------------------------;




ods graphics off;
