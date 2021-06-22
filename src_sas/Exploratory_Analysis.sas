/*All the plots and tables produced in this and other SAS files can be exported in a png form. 
The lines to export are commented. Uncomment them if you need the files and 
don't forget provide the folder where you need to have them in print_dir macro variable */

%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname DataLib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS\EDA; 
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*---------------------------------------------;


* 1. Missing Values Analysis. We count the number of missing data points in columns of interest.
We will also compute their percentage of the dataset and then print them (either to an image or the screen);
title 'Montreal Crime Study^n
-----------------------^nExploratory Analysis^n
-----------------------^n1.Missing Values Analysis';
footnote;
 data missing_table(keep=type location district Police_Division);
	length type $15.;
	set DataLib.crime_data nobs=n end=eof;
	call symput('N',n); /* we will make use of this macro variable later */
	
	retain location 0 district 0 Police_Division 0 ;
	if missing(LONGITUDE)  then Location + 1;
	if missing(ARRONDIS)  then district + 1;
	if missing(DIVISION)  then Police_Division + 1;
	
	if eof then do;
		type = 'Count';
		output; /*output number of missing values*/
		Location = put(Location / n,7.2);
		district = put(district / n,7.2);
		Police_Division = put(Police_Division / n,7.2);
		type='Percent';
		output; /*output their percentages*/
	end;
run;
PROC TRANSPOSE DATA=missing_table out=missing_table name=Variable;
	ID TYPE;
run;

/*options printerpath=png nodate papersize=('4.8in','2.5in') nonumber;*/
/*ods _all_ close;*/
/*ods printer file="&print_dir\missing_table.png";*/

proc print data=missing_table noobs;
	format Percent percent7.1 Count comma.;
run;

/*ods printer close;*/
/*ods listing;*/

*-------------------------------------------------------------------------------
           plot 1 -  Histogram of categories
--------------------------------------------------------------------------------
;

/*ods listing gpath="&print_dir" image_dpi=200;*/
/*ods graphics / reset scalemarkers=no  imagename="categories_univ";*/


title '2. Univariate Analysis';
title2'i. Number of Crimes per Category';

*-----------------------------------------------------;
proc freq data=DataLib.crime_data  noprint;
	tables category / nopercent nocum out=temp1;
run;

proc sort data=temp1 out=temp1;
	by Descending Count;

run;
data _null_; /*here we create the ticks for the y_axis in a macro variable.*/
	length allvars $1000;   
	set temp1 end=eof;
	retain allvars ' ';   
	allvars = trim(left(allvars))||' '||left(put(count,12.));   
	if eof then do;
		call symput('count_l', allvars);
	end;
run;

data anno_catg; /*The annotation on the graph. In this part of the code we create the percentages with their location on the graph.*/
	set temp1 end=_last_;
	length  anchor$6 function $13
		style $10 xc2 $15 direction $10 label $300
		x1space y1space x2space y2space $15;
 	 
	xc1 = category;
	drop count category;
	if category eq 'Fatal Crime' then y1 = count +3000;
	else y1 = count - 2000;
	retain function "text" drawspace 'datavalue' width 15
	x1 . x2 .  y2 . xc2 '' X1SPACE '' X2SPACE '' Y1SPACE '' Y2SPACE ''
		justify "center"  anchor "top" HSYS . size . style '' y2 0 direction '' scale . transparency . ;
	label=strip(put(count/&N,percent12.1));
	output;
 run;

proc sql;
	/*We then add more rows to ann_catg to account to draw an arrow and a tex on the graph.*/
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

proc sgplot data=temp1 noautolegend sganno=anno_catg noborder nowall  ;
 	title 'Total number of crimes per category';
	title5 'The y-axis corresponds to the sum of crimes in each category';
	footnote;
	vbarparm category=category response=count / group=category transparency=.2;
	xaxis fitpolicy=none label='Category' labelattrs=(size=12);
	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total' labelattrs=(size=12);
run;

/*ods listing close;*/

*-------------------------------------------------------------------------------
           plot 2 -  Histogram of districts
--------------------------------------------------------------------------------
;

/*ods listing gpath="&print_dir" image_dpi=200;*/
/*ods graphics / reset scalemarkers=no width=800px imagename="districts_univ";*/

proc freq data=DataLib.crime_data noprint;
	tables Arrondis / nopercent nocum out=temp1;
run;
proc sort data=temp1 out=temp1;
	where percent > 3; /*keep only districts who contribute to at least 3% of the total crime.*/
	by descending count;
run;


data anno; /*As before, we begin by  creating the labels on the bars.*/
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

proc sql noprint;
	/*We then add to the table above more arrowsand text.*/
	insert into work.anno(function, 
	x1space, x2space, y1space, y2space,
	x1, x2, y1, y2, 
	direction, style, scale, transparency)
	values ('Arrow', 
	'DATAPIXEL','DATAPIXEL', 'DATAVALUE','DATAVALUE',
	27, 48, 27000, 27000, 
	 "IN", "BARBED", .000001, .4)
	 values ('Arrow', 
	'DATAPIXEL','DATAPIXEL', 'DATAVALUE','DATAVALUE',
	55, 55, 19000, 17500, 
	 "OUT", "BARBED", .000001, .4)
	 values ('Arrow', 
	'DATAPIXEL','DATAPIXEL', 'DATAVALUE','DATAVALUE',
	105, 105, 16000, 14500, 
	 "OUT", "BARBED", .000001, .4);
	 
	
	insert into work.anno(function,
	x1space, y1space,
	x1, y1,
	anchor, justify, width, label)
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	50, 27000, 
	'left', 'center', 15, 'Downtown')
	/****************/
	values("text",
	'DATAPIXEL', 'DATAVALUE',
	30, 21000, 
	'left', 'center', 50, 'Decreased by 28.4% in 2018')
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

	select count(distinct arrondis) format 2.
	into :n_arrond /*The number of different districts to be shown in the footer.*/
	from DataLib.crime_data;
quit;


proc sgplot data=temp1 sganno=anno ; 
 title 'Total number of crimes per district';
 title2 'Only those contributing to at least 3% of the total crime rate are shown';
 title3 "They contribute to &sum_percent% of crime";
 footnote "The data contains &n_arrond districts.";
	vbarparm category=arrondis response=count / group=arrondis name='v' transparency=.2;
	keylegend 'v' / across = 1 position=TOPRIGHT location=inside valueattrs=(Size=10);
	xaxis display=(NOVALUES noticks) fitpolicy=none label='District' labelattrs=(size=12);
	yaxis  tickvalueformat=comma. valueshint integer label='Total' labelattrs=(size=12);
run;

/*ods listing close;*/

*-----------------------------------------------------------;
*-------------------------------------------------------------------------------
           plot 3 -  Evolution of crimes over time by category
--------------------------------------------------------------------------------
;

/*ods listing gpath="&print_dir" image_dpi=200;*/
/*ods graphics / reset scalemarkers=no width=800px imagename="categories_year";*/

proc freq data=DataLib.crime_data noprint;
	where year not eq 2021; /*skip 2021 since it's not complete*/
	tables year * category / nopercent nocum norow nocol list out=temp1;
run;

proc sort data=temp1 out=temp1;
	by category year;
run;


data temp1;
	/*We add one more column to the data that has the change in percentage from the year before*/
	set temp1;
	by category;
	prv_count = lag(count);
	if first.category or count eq prv_count then /*If there is no change or it's the first year*/ 
		change = .;
	else change = (count-prv_count)/prv_count;
	if abs(change) le .13 then change=.; /*Drop the change that is less than 13% (so we can print only relevant change)*/
	pos_change = change; /*keep track of positive and negetive changes so we give them different colors on graph*/
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
	/*series statement is repeated twice so we can show the positive and negative labels in different colors.*/
	series x=year y=count / group=category  lineattrs=(thickness=2) transparency=.2  lineattrs=(pattern=Solid)
	datalabel=pos_change datalabelattrs=(color=RED weight=bold size=10) datalabelpos=top 
		curvelabel curvelabelloc=outside curvelabelpos=end curvelabelattrs=(weight=BOLD);
	series x=year y=count / group=category datalabel=neg_change transparency=.2 lineattrs=(pattern=Solid)
		datalabelattrs=(color=GREEN weight=bold size=10) datalabelpos=top;
	scatter x=year y=count / group=category  markerattrs=(symbol=SquareFilled) transparency=.2;
	yaxis label='total' labelattrs=(size=12);
	xaxis label='Time ( JAN 2015 to DEC 2020)' labelattrs=(size=12);
run;

/*ods listing close;*/
ods graphics off;

