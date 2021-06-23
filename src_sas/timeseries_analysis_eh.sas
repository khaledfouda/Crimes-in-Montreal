
%let root_dir = D:\CODE\projects\mtl\Crimes-in-Montreal;
libname DataLib "&root_dir\data\sas";
%let print_dir = &root_dir\plots\SAS\EDA; 
ods escapechar='^'; /* To allow the abbr ^n for inserting new lines in titles and footnotes.*/
ods graphics on;

proc freq data=DataLib.crime_data noprint;
	format date monyy7.;
*where year not eq 2021; /*skip 2021 since it's not complete*/
	tables date * category / nopercent nocum norow nocol list out=temp1;
run;

proc sort data=temp1 out=temp1;
	by category date;
run;

ods graphics / reset scalemarkers=no width=800px;
%macro layout(c);
layout overlay/ yaxisopts=(label=' ') xaxisopts=(label=' ');
        seriesplot x=date y=eval(ifn(category=&c, count,.))  ;
		entry halign=center &c / valign=top border=true;
      endlayout;
%mend;

proc template;
  define statgraph lattice;
  begingraph;
    *entrytitle "Changes over time";
    layout lattice / border=true pad=10 opaque=true
                    rows=3 columns=2 columngutter=3;
      
      %layout('Armed Robbery');
	  %layout('Fatal Crime');
	  %layout('Auto Burglary');
	  %layout('Auto theft');
	  %layout('Break and Enter');
	  %layout('Mischief');
      sidebar;
        discretelegend "cars";
      endsidebar;
    endlayout;
  endgraph;
  end;
run;
ods listing gpath="&print_dir" image_dpi=200;
	ods graphics / reset scalemarkers=no width=800px imagename="monthplot_&name";
proc sgrender data=temp1 template=lattice;
run;