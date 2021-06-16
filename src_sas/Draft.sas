/* proc sgpanel data=proj_lib.crime_data noautolegend; */
/* 	*where bp_status='Normal' or bp_status='High'; */
/* 	panelby CATEGORIE / layout=panel novarname; */
/* 	histogram CATEGORIE / transparency=0.5; */
/* 	density CATEGORIE; */
/* 	rowaxis grid; colaxis grid; */
/* run; */
ods graphics on;
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
ods graphics off;