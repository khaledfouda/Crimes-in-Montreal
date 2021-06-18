/* proc sgpanel data=proj_lib.crime_data noautolegend; */
/* 	*where bp_status='Normal' or bp_status='High'; */
/* 	panelby CATEGORIE / layout=panel novarname; */
/* 	histogram CATEGORIE / transparency=0.5; */
/* 	density CATEGORIE; */
/* 	rowaxis grid; colaxis grid; */
/* run; */
ods graphics on;






/*  */
/* proc freq data=proj_lib.crime_data  noprint; */
/* 	tables YEAR*CATEGORIE / nopercent nocum out=temp1; */
/* run; */
/* data temp1; */
/* 	set temp1; */
/* 	drop percent; */
/* run; */
/*  */
/* proc sort data=temp1 out=temp1; */
/* 	by Descending CATEGORIE YEAR; */
/* run; */
/*  */
/* proc sgpanel data=temp1 noautolegend; */
/* 	panelby CATEGORIE /novarname uniscale=column; */
/* 	vbarparm category=YEAR response=count / group=categorie  ; */
/* run; */
/* 	 */
/*  */
/*  */
/*  */
/* proc univariate data=proj_lib.crime_data noprint; */
/* 	class CATEGORIE; */
/* 	*var YEAR; */
/* 	histogram YEAR / ncols=3 barwidth=20; */
/* 	ods select histogram; */
/* run; */
/*  */
/* options symbolgen; */
/* proc print data=learn.assign(obs=10) noobs; */
/* footnote2 "on the &sysscp System Using Release &sysver"; */
/* run; */
/*  */
/*  */
/* ods graphics on; */
/* proc freq data=proj_lib.crime_data  noprint; */
/* 	tables CATEGORIE / nopercent nocum out=temp1; */
/* 	 */
/* run; */
/*  */
/* proc sort data=temp1 out=temp1; */
/* 	by Descending Count; */
/*  */
/* run; */
/* data _null_; */
/* 	length allvars $1000;    */
/* 	retain allvars ' ';    */
/* 	set temp1 end=eof; */
/* 		allsum + count; */
/* 		allvars = trim(left(allvars))||' '||left(put(count,12.));    */
/* 		if eof then do; */
/* 			call symput('count_l', allvars); */
/* 			call symput('sum_catg',allsum); */
/* 			%put &=count_l &=N; */
/* 		end; */
/* run; */
/*  */
/*  */
/* data anno_catg; */
/* 	set temp1 end=_last_; */
/* 	length  anchor$6 function $13 */
/* 		style $10 xc2 $15 direction $10 label $300; */
/*  	  */
/* 	xc1 = categorie; */
/* 	drop count categorie; */
/* 	if categorie eq 'Fatal Crime' then y1 = count +3000; */
/* 	else y1 = count - 2000; */
/* 	retain function "text" drawspace 'datavalue' width 15 */
/* 		justify "center"  anchor "top" xc2 '' HSYS . size . style '' y2 0 direction '' scale .  ; */
/* 	label=strip(put(count/&N,percent12.1)); */
/* 	output; */
/*  run; */
/*  */
/* proc sql; */
/*  */
/* 	insert into work.anno_catg(function,  */
/* 	drawspace,xc1, xc2, y1, y2,  */
/* 	direction, style, scale) */
/* 	values ('Arrow',  */
/* 	'datavalue', 'Fatal Crime', 'Fatal Crime', 4800, 30000,  */
/* 	'in', 'FILLED', .001); */
/* 	 */
/* 	insert into work.anno_catg(function, */
/* 	drawspace, xc1, y1, */
/* 	anchor, justify, width, label) */
/* 	values("text", */
/* 	'datavalue', 'Auto theft', 38449, */
/* 	'left', 'center', 52, '    Fatal Crimes had an increase of 19.2% in 2018 and a decrease of 22.6% in 2019') */
/* 	; */
/* quit; */
/*  */
/* 	 */
/*  */
/* proc sgplot data=temp1 noautolegend sganno=anno_catg pad=(bottom=15%); */
/*  title 'Total number of crimes per category'; */
/* 	vbarparm category=categorie response=count / group=categorie; */
/* 	xaxis fitpolicy=none label='Category'; */
/* 	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total'; */
/* run; */
/*  */



ods graphics off;






