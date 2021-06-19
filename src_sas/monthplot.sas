%include "&root_dir\src_sas\monthplot_MACROS.sas";

%macro monthplot(input=proj_lib.crime_data, name=All_data, 
		tmp_dir=%sysfunc(getoption(WORK)), out_dir=&root_dir\plots\SAS\);
	* 
     part one: Preparing the data,
     
     The input dataset is expected to have a date column,
     
     The following code will sort by date, extract the month, add month number and names columns.
     Then another dataframe with only the means per month is created.
     A couple of macro variables are created wich are:
     	count_min count_max (min and max values in order to normalise the count values so we can judge change)
     	symbols, values (lists of all month names/numbers to be used as axes/labels)
     	month_min, month_max (month with lowest/highest average to be used to color those months)

;

	%if "&name" eq "All_data" %then
		%do;

			proc sort data=&input out=ts_all(keep=date);
				format date monyy7.;
				by date;
			run;

		%end;
	%else
		%do;

			proc sort data=&input out=ts_all(keep=date);
				where categorie eq "&name";
				format date monyy7.;
				by date;
			run;

		%end;

	proc freq data=ts_all noprint;
		tables date / nocum nopercent out=ts_all(drop=percent);
	run;

	data ts_all;
		set ts_all;
		monthname=put(date, monname10.);
		month=month(date);
	run;

	/* computing min/max */
	proc sql noprint;
		select min(count), max(count) into :count_min, :count_max from ts_all;
		select distinct monthname, month into :symbols separated by ' ', :values 
			separated by ' ' from ts_all order by month;
	quit;

	/* computing mean on month */
	proc summary data=ts_all nway;
		var count;
		class month;
		output out=ts_all_mean mean=;
	run;

	/* finding min&max-month */
	proc sql noprint;
		select month into :monthmax from ts_all_mean having count=max(count);
		select month into :monthmin from ts_all_mean having count=min(count);
	quit;

	*--------------------------------------------------
   part 2: Producing the plot.
   
   The MACROS used to define the plot are in the file: monthplot_MACROS.sas and are expected to be run
   before advancing in the execution of this file.
;
	* We begin by producing all the subseries plots (a plot per month)
 we will set a temporary folder to locate them. That folder is defined below in gpath;
	%let gpath= &tmp_dir;
	*;
	%subseries_template(x=date, y=count, ymin=&count_min, ymax=&count_max, 
		size=200px);
	%all_subseries_plots(symbols=&symbols, data=ts_all, wherevar=month, 
		wherevalues=&values, maxvalue=&monthmax, minvalue=&monthmin);
	*-------------------------------------------------

			The following are the annotations to display the category in the graph.;

	data anno;
		
		function = "text";
		x1space = 'DATAVALUE';
		y1space = 'DATAPIXEL';
		x1 = 6;
		y1 = 375;
		anchor='center';
		justify='center';
		width=50;
		label="&name";
		textsize=20;
		textcolor='grey';
		transparency=.2;
		output;
	run;

	*-------------------------------------------------------------------------------------;
	* Next we define the ticks by concatinating month names and adding '' and , ;
	%let ticks=%sysfunc(catq('1a', %sysfunc(translate(%upcase(&symbols), %str(,), 
		%str( )))));
	%put &=ticks;
	* We now initialize the main plots template. ;
	%cycle_plot_template(x=month, y=count, symbols=&symbols, ticks=&ticks);
	*-----------------------------------------------------------;
	* Last step: We generate the main plot.
We first assing the folder where we will keep the output image and then call the template.
;
	ods listing gpath="&out_dir" image_dpi=200;
	ods graphics / reset scalemarkers=no width=800px imagename="monthplot_&name";

	proc sgrender data=ts_all_mean template=cycle_plot_graph sganno=anno;
		label month='Month';
		dynamic title1="Month average of registered crimes for &name" 
			title2="Subseries shows the spline fit of crimes over time";
	run;

	ods listing close;
%mend monthplot;