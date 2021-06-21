/* %let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal; */
/* libname proj_lib "&root_dir\data\sas"; */
/* %let print_dir = &root_dir\plots\SAS; */
/* ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes. */
/* ods graphics on; */
/* *---------------------------------------------; */
/* proc sql noprint; */
/* 	create table categories as */
/* 		select distinct category format=$25.  */
/* 			from proj_lib.crime_data; */
/* quit; */
/*  */
/*  */
/* proc sort data=proj_lib.crime_data out=sorted(keep=date category); */
/* 	format date monyy7.; */
/* 	by category date; */
/* run; */
/*  */
/*  */
/* proc freq data=sorted noprint; */
/* 	where category not eq 'Fatal Crime'; */
/* 	by category; */
/* 	format date monyy7.; */
/* 	tables date / nocum nopercent out=sorted; */
/* run; */
/*  */
/*  */
/* proc expand data=sorted out=outsor from=month; */
/* 	by category; */
/* 	id date; */
/* run; */
/*  */
/* proc timeseries data=sorted out=outsor; */
/* 	by category; */
/* 	id date interval=month start='01JAN2015'd end='31MAY2021'd setmissing=.0000; */
/* 	var count; */
/* 	*corr lag n pacf; */
/* 	*decomp orig tc sc ic cc / mode=add; */
/*     */
/* run; */
/*  */
*-----------------------------------------------------------;
ods select ParameterEstimates FitSummary ComponentSignificance OutlierSummary ErrorACFPlot;
* 1. Armed Robbery:;

proc ucm data=outsor;
	where category = "Fatal Crime";
	*by category;
	id date interval=month;
	model count;
	irregular p=1 q=1  s=12;
	*irregular p=1  s=12;
	*irregular q=1  s=12;
	*irregular p=1 q=1  s=12;
	deplag lags=(1,12);
	season length=12  ;
	estimate plot=acf outest=out1;
	forecast outfor=fore1 ;
	outlier maxnum=5 print=short;
	
run;




ods graphics /reset=ALL;






