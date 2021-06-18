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
/* 	xc1 = categorie; */
/* 	drop count categorie; */
/* 	if categorie eq 'Fatal Crime' then y1 = count +3000; */
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
/* 	vbarparm category=categorie response=count / group=categorie; */
/* 	xaxis fitpolicy=none label='Category'; */
/* 	yaxis values=(&count_l) grid tickvalueformat=comma. valueshint integer label='Total'; */
/* run; */