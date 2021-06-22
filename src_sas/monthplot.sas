


/*All the plots and tables produced in this and other SAS files can be exported in a png form. 
The lines to export are commented. Uncomment them if you need the files and 
don't forget provide the folder where you need to have them in print_dir macro variable */

%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname DataLib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS\monthplot; 
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*---------------------------------------------;
* ----------------------------------------------------------------------------------------------------------------
	This file includes only one large MACRO function.
	It creates a complete month plot - using the helper functions from monthplot_MACROS.sas - for one category.

	If the macro was called with the default parameter, it will create a monthplot for the whole ungroped data.
	Our input data "crime_data" is already set as default so we don't need to specify it.
	Likely, the temporary folder to save the subseries images is where the WORK library is,
		and the output library is as defined above print_dir.
;

%include "&root_dir\src_sas\monthplot_MACROS.sas";

%macro monthplot(input=DataLib.crime_data, name=All_data, 
		tmp_dir=%sysfunc(getoption(WORK)), out_dir=&print_dir);
	* 
	This MACRO function is divided into two parts.
		part 1. Data processing :
			proc sort & freq as usual besides using proc sql to compute some variables needed for the graph.
			These Macro variables holds the values of : 
				Symbols : List of all month names. JANUARY to DECEMBER
				Month_min and Month_max : The two months with minimum and maximum means so they can have different colors.

		part 2. Producing the graph.

;

	%if "&name" eq "All_data" %then /*Don't use where statement if no categories were specified*/
		%do;

			proc sort data=&input out=ts_all(keep=date);
				format date monyy7.;
				by date;
			run;

		%end;
	%else
		%do;

			proc sort data=&input out=ts_all(keep=date);
				where category eq "&name";
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

	
	proc sql noprint; /*making a list of all months names*/
		select distinct monthname into :symbols separated by ' ' from ts_all order by month;
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
	%subseries_template(x=date, y=count, size=200px);
	%all_subseries_plots(symbols=&symbols, data=ts_all, wherevar=month, wherevalues=&values, maxvalue=&monthmax, minvalue=&monthmin);
	*-------------------------------------------------

			The following are the annotations to display the category in the graph.;

	data anno;
		
		function = "text";
		x1space = 'DATAVALUE';
		y1space = 'DATAPIXEL';
		x1 = 6;
		y1 = 370;
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
	ods graphics close;
%mend monthplot;
