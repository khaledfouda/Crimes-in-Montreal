*THE SUBSERIES PLOT TEMPLATE;

%macro subseries_template(x=, /* x role of the subseries */
	y=, /* y role of the subseries */
	ymin=, /* min value of y */
	ymax=, /* max value of y */
	size=/* image size */);
	proc template ;
		define statgraph subseries;
			dynamic linecolor;
			begingraph / pad=0px border=false opaque=false 
				designwidth=&size designheight=&size;
			layout overlay / walldisplay=none xaxisopts=(display=none) 
				yaxisopts=(display=none linearopts=(viewmin=&ymin viewmax=&ymax));
			modelband 'spline';
			pbsplineplot x=&x y=eval(&y+0.5*(&ymin + &ymax)- mean(&y)) / clm='spline' 
				nknots=10 lineattrs=(color=linecolor);
			referenceline y=eval(0.5*(&ymin + &ymax)) / lineattrs=(color=linecolor);
			endlayout;
			endgraph;
		end;
	run;

%mend subseries_template;

*-----------------------------------------------------------------------------------------------------;
* GENERATING THE SUBSERIES PLOTS ------;

%macro subseries_plot(symbol=, /* symbol name like DoW */
	data=, /* dataset */
	whereclause=, /* where clause for this symbol */
	linecolor=/* line color to highlight the max */);
	ods graphics / reset imagename="&symbol";

	proc sgrender data=&data(where=(&whereclause)) template=subseries;
		dynamic linecolor="&linecolor";
	run;

%mend subseries_plot;

*--------------------------------------------------------------------------;
* the following functions generates all the subseries plots using the function above.;

%macro all_subseries_plots(symbols=, /* list of symbols */
	data=, /* dataset */
	wherevar=, /* variable used for subsetting */
	wherevalues=, /* where values */
	maxvalue=, /* value with the max mean */
	minvalue=/* value with the min mean*/);
	ods _all_ close;
	ods listing gpath="&gpath";
	%let word_cnt=%sysfunc(countw(%superq(symbols)));

	%do i=1 %to &word_cnt;
		%let var&i=%qscan(%superq(symbols), &i, %str( ));
		%let val&i=%qscan(%superq(wherevalues), &i, %str( ));
		%subseries_plot(symbol=&&var&i, data=&data, whereclause=&wherevar.=&&val&i, 
			linecolor=%if(&maxvalue=&&val&i) %then red;
		%else %if(&minvalue=&&val&i) %then
			green;
		%else
			black;
		);
	%end;
	ods listing close;
%mend all_subseries_plots;

*----------------------------------------------------------------------------------------;

%macro symbol_images(symbols /* list of symbols */);
	%let word_cnt=%sysfunc(countw(%superq(symbols)));

	%do i=1 %to &word_cnt;
		%let var&i=%qscan(%superq(symbols), &i, %str( ));
		symbolimage name=&&&var&i image="&gpath/&&&var&i...png";
	%end;
%mend symbol_images;

*-----------------------------------------------------------------------------------------;
*   Scatter plot template;

%macro cycle_plot_template(x=, /* category */
	y=, /* mean values of Y */
	symbols=, /* list of symbols */
	ticks=/* list of displayed tick values */);
	proc template ;
		define statgraph cycle_plot_graph;
			dynamic title1 title2 footnote;
	
			/* for two titles and a footnote */
			begingraph / subpixel=on attrpriority=none /* each group gets a new symbol */
			datasymbols=(&symbols);

			/* override the group markers */
			entrytitle title1;
			entrytitle title2;
			entryfootnote halign=left footnote;
			%symbol_images(&symbols);

			/* define the custom image markers */
			layout overlay / xaxisopts=(type=discrete display=(tickvalues label) 
				discreteopts=(colorbands=odd colorbandsattrs=(transparency=0.75) 
				tickdisplaylist=(&ticks))) yaxisopts=(linearopts=(thresholdmin=1 
				thresholdmax=1 tickvalueformat=(extractscale=true)));
			scatterplot x=&x y=&y / group=&x usediscretesize=true 
				discretemarkersize=0.85;
				ANNOTATE;
			endlayout;
			endgraph;
		end;
	run;

%mend cycle_plot_template;

*-----------------------------------------------------------------------;