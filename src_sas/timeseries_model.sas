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

proc timeseries data=sorted out=outsor;
	by category;
	id date interval=month start='01JAN2015'd end='31MAY2021'd setmissing=.0000;
	var count;
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
		level variance=0 noest ;
		slope variance=0 noest ;
		season length=12;
		estimate plot=acf /*outest=out1*/;
		forecast outfor=&outfor;
		outlier maxnum=5 print=short;
	run;

	ods printer close;
	ods listing;
	ods graphics /reset=ALL;

	proc sql ;
		alter table &outfor
		add category VARCHAR(25) format=$25.;
		update &outfor
		set category="&categ";
		create table temp as select category, date, count, s_irreg, s_season, s_treg, 
			s_noirreg, s_level from ucm_all union select category, date, count, s_irreg, 
			s_season, s_treg, s_noirreg, s_level from &outfor;
		drop table &outfor;
		drop table ucm_all;
		create table ucm_all as select * from temp;
		drop table temp;
	quit;

%mend time_series_report;

*---------------------------------------------------------;
data ucm_all;
	format category $25. date monyy7. count 5. s_irreg s_season s_treg s_noirreg s_level
		14.4;
	stop;
run;
*------------------------------------------------------------;
%time_series_report(Fatal Crime, 1, ucm_fatal_crimes);
%time_series_report(Auto Burglary, 1, ucm_Auto_burgalaries);
%time_series_report(Break and Enter, 1, ucm_break_and_enter);
%time_series_report(Mischief, 2, ucm_mischief);
%time_series_report(Armed Robbery, 2, ucm_Armed_robberies);
%time_series_report(Auto theft, 2, ucm_Auto_thefts);
*-------------------------------------------------------------;
proc stdize data=ucm_all out=ucm_std method=std;
	by category;
	var count s_treg s_irreg s_level;
run;
*-------------------------------------------------------------------;
ods listing gpath="&print_dir" image_dpi=200 ;
ods graphics / reset scalemarkers=no width=800px imagename="model_seasonality" ;

proc sgpanel data=ucm_all noautolegend;
	title 'SEASONALITY';
	where date between '01JAN2018'd and '31DEC2018'd;
	panelby category /  novarname  nowall noheaderborder  ;
	series x=date y=s_season / transparency=.8 ;
	scatter x=date y=s_season ;
	colaxis  interval=month label='Month' valuesformat=monname3. ;
	rowaxis display=none;
run;
ods listing;
ods graphics;
*------------------------------------------------------------------------;
ods listing gpath="&print_dir" image_dpi=200 ;
ods graphics / reset scalemarkers=no width=800px imagename="model_fit" ;

proc sgpanel data=ucm_std ;
	title 'Model Fit (After applying seasonality and ARMA model)';
	title2 'The data were standardized to keep a common y-axis';
	where date lt '01JUN2021'd;
	panelby category /  novarname  nowall noheaderborder  ;
	series x=date y=s_treg / transparency=.1 name='Model' legendlabel='Model' ;
	scatter x=date y=count /transparency=.7 name='Original' legendlabel='Original';
	colaxis  interval=year label='YEAR'  ;
	rowaxis display=none;
	keylegend "Model" "Original" / position=top;
run;
ods listing;
ods graphics;
*---------------------------------------------------------------------------------;
ods listing gpath="&print_dir" image_dpi=200 ;
ods graphics / reset scalemarkers=no width=800px imagename="model_residuals" ;
proc sgpanel data=ucm_all noautolegend ;
	title 'RESIDUALS';
	title2 'Residuals are shown to have a zero mean, a homogeneous variance and random behaviour';
	where date lt '01JUN2021'd;
	panelby category /  novarname  nowall noheaderborder  ;
	series x=date y=s_irreg / transparency=.1  ;
	colaxis  interval=year label='YEAR'  ;
run;
ods listing;
ods graphics;
*---------------------------------------------------------------------------------------;
ods listing gpath="&print_dir" image_dpi=200 ;
ods graphics / reset scalemarkers=no width=800px imagename="model_trends" ;
proc sgpanel data=ucm_all noautolegend ;
	title 'TRENDS';
	title2 'The data were standardized to keep a common y-axis';
	where date lt '01JUN2021'd;
	panelby category /  novarname  nowall noheaderborder  ;
	series x=date y=s_level / transparency=.2  ;
	colaxis  interval=year label='YEAR' ;
	rowaxis label=' ';
run;
ods listing;
ods graphics;



