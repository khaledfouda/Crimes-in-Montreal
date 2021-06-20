%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname proj_lib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS;
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*---------------------------------------------;
proc sql noprint;
	create table categories as
		select distinct category format=$25. 
			from proj_lib.crime_data;
quit;


proc sort data=proj_lib.crime_data out=sorted(keep=date category);
	format date monyy7. category $25.;
	by category date;
run;




proc freq data=sorted noprint;
/* 	where category not eq 'Fatal Crime'; */
	by category;
	format date monyy7. category $25.;
	tables date / nocum nopercent out=sorted;
run;
data AllMonthYear;
	start = '01Jan2015'd;
	set categories;
	do i=0 to 76;
		date = intnx('month', start, i);
		output;
	end;
	drop start i;
	format date monyy7. category $25.;
run;

	



proc sql;
	create table corrected as
		select t2.date, t2.category, t1.count, t1.category as cat2, t1.date as d2
			from sorted as t1
				left join AllMonthYear as t2
					on(t1.date=t2.date and t1.category=t2.category);
	*drop table sorted;
	drop table AllMonthYear;
quit;
	
proc sort data=corrected out=corrected;
	format date monyy7.;
	by category date;
run;
	
proc expand data=sorted out=outsor from=month;
	by category;
	id date;
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



proc timeseries data=corrected outdecomp=outdecomp(keep=category date cc) plots=all;
	by category;
   id date interval=month start='01JAN2015'd end='31MAY2021'd setmissing=0;
   var count;
   decomp cc / mode=add;
run;



















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