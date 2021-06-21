%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname proj_lib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS;
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;