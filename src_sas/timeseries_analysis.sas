%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname proj_lib "&root_dir\data\sas";
%include "&root_dir\src_sas\monthplot.sas";

%MACRO PLOT_CATEGORIES;
	%monthplot();
	proc sql noprint;
		/* 	create table categories as */
		select distinct categorie as cat into :c1 - :c6 from proj_lib.crime_data;
	quit;

	%DO ii=1 %to 6;
		%monthplot(name=&&c&ii);
	%end;
%MEND PLOT_CATEGORIES;

%PLOT_CATEGORIES;