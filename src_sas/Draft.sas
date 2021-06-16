/* proc sgpanel data=proj_lib.crime_data noautolegend; */
/* 	*where bp_status='Normal' or bp_status='High'; */
/* 	panelby CATEGORIE / layout=panel novarname; */
/* 	histogram CATEGORIE / transparency=0.5; */
/* 	density CATEGORIE; */
/* 	rowaxis grid; colaxis grid; */
/* run; */
ods graphics on;


/* proc freq data=proj_lib.crime_data  noprint; */
/* 	tables YEAR*CATEGORIE / nopercent nocum out=temp1; */
/* run; */
/* data temp1; */
/* 	set temp1; */
/* 	*count = log(count); */
/* 	*monnum = month(input(cats('01',MONTH,'2016'), date9.)); */
/* 	drop percent; */
/* run; */
/*  */
/* proc sort data=temp1 out=temp1; */
/* 	by Descending CATEGORIE YEAR; */
/* run; */
/*  */
/* proc sgpanel data=temp1 noautolegend; */
/* 	panelby CATEGORIE /novarname uniscale=column; */
/* 	hbar CATEGORIE / l ; */
/* 	vbarparm category=YEAR response=count / group=categorie  ; */
/* 	*series y=count x=YEAR ; */
/* run; */
/* 	 */
/*  */


proc univariate data=proj_lib.crime_data noprint;
	class CATEGORIE;
	*var YEAR;
	histogram YEAR / ncols=3 barwidth=20;
	ods select histogram;
run;






ods graphics off;