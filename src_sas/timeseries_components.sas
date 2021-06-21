%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname proj_lib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS;
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*---------------------------------------------;
/* proc sql noprint; */
/* 	create table categories as */
/* 		select distinct category format=$25.  */
/* 			from proj_lib.crime_data; */
/* quit; */


proc sort data=proj_lib.crime_data out=sorted(keep=date category);
	format date monyy7.;
	by category date;
run;


proc freq data=sorted noprint;
/* 	where category not eq 'Fatal Crime'; */
	by category;
	format date monyy7.;
	tables date / nocum nopercent out=sorted;
run;



proc timeseries data=sorted outdecomp=outdecomp(keep=category date cc);
	by category;
   id date interval=month start='01JAN2015'd end='31MAY2021'd setmissing=0;
   var count;
   decomp cc / mode=add;
run;
*------------------------------------------------------------------------------;
proc stdize data=outdecomp out=scaled_decomp method=std;
	by category;
	var cc;
run;


ods graphics on / width=9in height=5in;
proc sgplot data=scaled_decomp noautolegend;
	where date >= '01JAN2019'd;
	series x=date y=cc / group=category curvelabel;
	xaxis interval=month;
run;
proc sgplot data=scaled_decomp noautolegend;
	where date < '01JAN2019'd;
	series x=date y=cc / group=category curvelabel;
	xaxis interval=month;
run;

ods graphics/ reset=all;

proc timeseries data=sorted outdecomp=outdecomp plot=all
								/*plots=(pacf sc sic tcs cc tc ic SERIES)*/  ;
	by category;
   id date interval=month start='01JAN2015'd end='31MAY2021'd setmissing=.0001;
   var count;
   corr lag n pacf;
   decomp orig tc sc ic cc / mode=add;
   
run;

ods select ExtremeObs;
proc univariate data=outdecomp robustscale ;
by category;
var  ic;
id date;
output out=extreme; 
run; 
ods graphics /reset=ALL;


proc expand data=sorted out=outsor from=month;
	by category;
	id date;
run;


ods select ParameterEstimates FitSummary ComponentSignificance OutlierSummary PanelResidualPlot;
proc ucm data=outsor;
	where category = "Break and Enter";
	*by category;
	id date interval=month;
	model count;
	irregular p=1 q=1  s=12;
	deplag lags=(1)(12);
	season length=12  ;
	estimate plot=panel outest=out1;
	forecast outfor=fore1 ;
	outlier maxnum=5 print=short;
	
run;
	ods graphics /reset=ALL;











/* proc freq data=proj_lib.crime_data  noprint; */
/* 	tables category / nopercent nocum out=temp1; */
/* 	 */
/* run; */
/*  */
/* proc sort data=temp1 out=temp1; */
/* 	by Descending Count; */
/*  */
/* run; */
/* data _null_; */
/* 	length allvars $1000;    */
/* 	set temp1 end=eof; */
/* 	retain allvars ' ';    */
/* 	allvars = trim(left(allvars))||' '||left(put(count,12.));    */
/* 	if eof then do; */
/* 		call symput('count_l', allvars); */
/* 		%put &=count_l &=N; */
/* 	end; */
/* run; */
/*  */
/*  */
/* data anno_catg; */
/* 	set temp1 end=_last_; */
/* 	length  anchor$6 function $13 */
/* 		style $10 xc2 $15 direction $10 label $300 */
/* 		x1space y1space x2space y2space $15; */
/*  	  */
/* 	xc1 = category; */
/* 	drop count category; */
/* 	if category eq 'Fatal Crime' then y1 = count +3000; */
/* 	else y1 = count - 2000; */
/* 	retain function "text" drawspace 'datavalue' width 15 */
/* 	x1 . x2 .  y2 . xc2 '' X1SPACE '' X2SPACE '' Y1SPACE '' Y2SPACE '' */
/* 		justify "center"  anchor "top" HSYS . size . style '' y2 0 direction '' scale .  ; */
/* 	label=strip(put(count/&N,percent12.1)); */
/* 	output; */
/*  run; */
/*  */
/* proc sql; */
/*  */
/* 	insert into work.anno_catg (function,  */
/* 	drawspace,xc1, xc2, y1, y2,  */
/* 	direction, style, scale) */
/* 	values ('Arrow',  */
/* 	'datavalue', 'Fatal Crime', 'Fatal Crime', 4800, 12000,  */
/* 	'in', 'FILLED', .001); */
/* 	 */
/* 	insert into work.anno_catg(function, */
/* 	x1space, y1space, */
/* 	x1, y1, */
/* 	anchor, justify, width, label) */
/* 	values("text", */
/* 	'DATAPIXEL', 'DATAVALUE', */
/* 	310, 20000, */
/* 	'left', 'center', 40, 'Fatal Crimes had an increase of 19.2% in 2018 and a decrease of 22.6% in 2019') */
/* 	; */
/* quit; */
/*  */
/*  */
/* proc sgplot data=temp1 noautolegend sganno=anno_catg /*pad=(bottom=15%)*/; */
/*  *title 'Total number of crimes per category'; */
/* 	vbarparm category=category response=count / group=category; */
/* 	xaxis fitpolicy=none label='Category'; */
/* 	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total'; */
/* run; */