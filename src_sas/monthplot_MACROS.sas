*
This file contains 5 helper macro functions. They are imported and used by the file monthplot.sas.
The 5 functions in order :
	1.  subseries_template : A template to graph a simple spline to fit the number of crimes for
			one category and over one single month over years.
	2. subseries_plot: creates a sgrender plot using the template above. The plot is saved temporary as a png image.
	3. all_subseries_plot: per one category, this functions runs subseries_plot() over all the 12 months with an image per month.

	4. symbol_images(): Reads a list of images (the ones we produced from earlier).	

	5. cycle_plot_template: The template for the monthplot. Basically, it creates a scatter plot and uses the images from
		before as labels on the data points.
;
* The following functions are based on the proposed technique in this paper
		https://support.sas.com/rnd/datavisualization/papers/sgf2019/3214_2019.pdf
		Identifying Seasonality and Trend with a Cycle Plot in SAS? by Lingxiao Li, SAS Institute Inc
;
* 1. THE SUBSERIES PLOT TEMPLATE;

%macro subseries_template(
	x=, 
	y=, 
	ymin=,
	ymax=,
	size=/* image size */);
	proc template ;
		define statgraph subseries;
			dynamic linecolor;
			begingraph / pad=0px border=false opaque=false designwidth=&size designheight=&size;
			layout overlay / walldisplay=none xaxisopts=(display=none) yaxisopts=(display=none);
			modelband 'spline';
			pbsplineplot x=&x y=&y / clm='spline' nknots=10 lineattrs=(color=linecolor);
			referenceline y=eval(mean(&y)) / lineattrs=(color=linecolor);
			endlayout;
			endgraph;
		end;
	run;

%mend subseries_template;

*-----------------------------------------------------------------------------------------------------;
* 2. GENERATING THE SUBSERIES PLOTS ------;

%macro subseries_plot(symbol=, /* a name to given to the image file*/
	data=,
	moni=, /* month number */
	linecolor=/* line color to highlight the max/min */);
	ods graphics / reset imagename="&symbol";

	proc sgrender data=&data(where=(month=&moni)) template=subseries;
		dynamic linecolor="&linecolor";
	run;

%mend subseries_plot;

*--------------------------------------------------------------------------;
* 3.;

%macro all_subseries_plots(symbols=, /* list of symbols (month names in our case) */
	data=, /* dataset */
	wherevalues=, /* (a list of month numbers) where values */
	maxvalue=, /* value with the max mean - make it red */
	minvalue=/* value with the min mean - make it green*/);
	ods _all_ close;
	ods listing gpath="&gpath";

	%do i=1 %to 12;
		%let var&i=%qscan(%superq(symbols), &i, %str( )); /* gets the ith month name*/
		%let val&i=%qscan(%superq(wherevalues), &i, %str( )); /* The month's number. don't use &i since they are not ordered!! */
		%subseries_plot(symbol=&&var&i, data=&data, moni=&&val&i, 
			linecolor=%if(&maxvalue=&i) %then red;
		%else %if(&minvalue=&i) %then
			green;
		%else
			black;
		);
	%end;
	ods listing close;
%mend all_subseries_plots;

*----------------------------------------------------------------------------------------;
* 4;
%macro symbol_images(symbols /* list of symbols */);
	%let word_cnt=%sysfunc(countw(%superq(symbols)));
	%do is=1 %to 12;
		%let var&is=%qscan(%superq(symbols), &is, %str( ));
		symbolimage name=&&&var&is image="&gpath\&&&var&is...png"; /*we can refernce the image later using the name*/
	%end;
%mend symbol_images;

*-----------------------------------------------------------------------------------------;
*  5 Scatter plot template;

%macro cycle_plot_template(x=, /* category */
	y=, /* mean values of Y */
	symbols=, /* list of symbols */
	ticks=/* list of displayed tick values */);
	proc template ;
		define statgraph cycle_plot_graph; /*stat graph template allows us to describe the srtucture and appearence of the graph*/
			dynamic title1 title2; /* for two titles */
			
			begingraph / subpixel=on attrpriority=none datasymbols=(&symbols);

				entrytitle title1; /*to show the titles*/
				entrytitle title2;
				%symbol_images(&symbols); /*load the images*/

				/* define the custom image markers */
				layout overlay / /*two nested layouts are defined*/
					xaxisopts=(type=discrete display=(tickvalues label) discreteopts=(colorbands=odd colorbandsattrs=(transparency=0.75) 
						tickdisplaylist=(&ticks))) 
					yaxisopts=(linearopts=(thresholdmin=1 thresholdmax=1 tickvalueformat=(extractscale=true)) );
				scatterplot x=&x y=&y / group=&x usediscretesize=true discretemarkersize=0.85;
				ANNOTATE; /*to add the title. The anno table is defined is monthplot.sas*/
				/*The following layout is defined the legend.*/
				layout gridded / columns =1 border=true autoalign=(bottomright topright) backgroundcolor=lightyellow ;
					
					entry halign=left  {unicode '2014'x} halign=right "mean line";
					entry textattrs=(color=green) halign=left  {unicode '2014'x} halign=right "lowest mean";
					entry textattrs=(color=Red) halign=left  {unicode '2014'x} halign=right "highest mean";
				endlayout;
				endlayout;
				
			endgraph;
		end;
	run;

%mend cycle_plot_template;




*-----------------------------------------------------------------------;