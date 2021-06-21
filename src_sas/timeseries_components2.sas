%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname proj_lib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS;
ods escapechar='^';

/* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*---------------------------------------------;

proc sql noprint;
	create table categories as select distinct category format=$25. from 
		proj_lib.crime_data;
quit;

proc sort data=proj_lib.crime_data out=sorted(keep=date category);
	format date monyy7.;
	by category date;
run;

proc freq data=sorted noprint;
	by category;
	format date monyy7.;
	tables date / nocum nopercent out=sorted;
run;

proc expand data=sorted out=outsor from=month;
	by category;
	id date;
run;

proc timeseries data=sorted out=outsor;
	by category;
	id date interval=month start='01JAN2015'd end='31MAY2021'd setmissing=.0000;
	var count;
	*corr lag n pacf;
	*decomp orig tc sc ic cc / mode=add;
run;

*-----------------------------------------------------------;

%MACRO time_series_report(categ, p, outfor);
	ods _all_ close;
	options printerpath=png nodate papersize=('12in', '9in') nonumber;
	ods select ParameterEstimates ComponentSignificance FitSummary OutlierSummary 
		ErrorACFPlot;
	%let filename = %sysfunc(translate("&print_dir.ucm_&categ..png", "_", ' '));
	%put &=filename;
	title "&categ";
	title2 'Time Series Fitting Analysis';
	* 1. Armed Robbery:;
	ods printer file=&filename columns=2 dpi=200;

	proc ucm data=outsor;
		where category="&categ";
		id date interval=month;
		model count;
		irregular p=&p q=1 s=12;
		deplag lags=(1, 12);
		season length=12;
		estimate plot=acf /*outest=out1*/;
		forecast outfor=&outfor;
		outlier maxnum=5 print=short;
	run;

	ods printer close;
	ods listing;
	ods graphics /reset=ALL;
%mend time_series_report;

*---------------------------------------------------------;
%time_series_report(Fatal Crime, 1, ucm_fatal_crimes);
%time_series_report(Auto Burglary, 1, ucm_Auto_burgalaries);
%time_series_report(Break and Enter, 1, ucm_break_and_enter);
%time_series_report(Mischief, 2, ucm_mischief);
%time_series_report(Armed Robbery, 2, ucm_Armed_robberies);
%time_series_report(Auto theft, 2, ucm_Auto_thefts);
*-------------------------------------------------------------;