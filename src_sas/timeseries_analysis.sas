
/*All the plots and tables produced in this and other SAS files can be exported in a png form. 
The lines to export are commented. Uncomment them if you need the files and 
don't forget provide the folder where you need to have them in print_dir macro variable */

%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname DataLib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS\monthplot; 
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;
*  
In this file we run the main macro in monthplot.sas to generate a graph for each category.
;
ODS PATH work.templat(update) sasuser.templat(read) sashelp.tmplmst(read);
%include "&root_dir\src_sas\monthplot.sas";

%MACRO PLOT_categories;
	*%monthplot();
	proc sql noprint; /*we create an array of different categories.*/
		select distinct category as cat into :c1 - :c6 from DataLib.crime_data;
	quit;

	%DO ii=1 %to 6; /*loop over each category.*/
		%monthplot(name=&&c&ii);
	%end;
%MEND PLOT_categories;

%PLOT_categories;
