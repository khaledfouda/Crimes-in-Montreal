/* Calculate the quartiles and inter-quartile range using proc univariate */
proc means data=outdecomp nway noprint;
		by category;
		var cc;
		output out=temp P25=P25 P75=P75;
run;
	/* Extract the upper and lower limits into macro variables */
	*let Imterquartile range be IQR = Q3-Q1 then,
	lower limit low = Q1 - 3 * IQR
	upper limit upp = Q3 + 3 * IQR
;
data temp;
	set temp;
	IQR = p75 - p25;
	low = p25 - 1 * IQR;
	upp = p75 + 1 * IQR;
	keep category low upp;
run;

/* The following extracts the outliers as a table of category, date, type, and count*/
data extremeObs;
	set temp(rename=(category=ecat));
	do until (eof);
		set outdecomp end=eof;
		if category = ecat;
		if cc not eq . then do;
			if 	cc < low then do;
				type = 'lower';
				output;
			end;
			else if cc > upp then do;
				type = 'Upper';
				output;
			end;
		end;
	end;
	keep category date type original;
run;
		












%macro outliers(input=, var=, output=);
	
	/* Calculate the quartiles and inter-quartile range using proc univariate */
	proc means data=&input nway noprint;
		var &var;
		output out=temp P25=P75= / autoname;
	run;

	/* Extract the upper and lower limits into macro variables */
	data temp;
		set temp;
		ID=1;
		array varb(&n) &Q1;
		array varc(&n) &Q3;
		array lower(&n) &varL;
		array upper(&n) &varH;

		do i=1 to dim(varb);
			lower(i)=varb(i) - 3 * (varc(i) - varb(i));
			upper(i)=varc(i) + 3 * (varc(i) - varb(i));
		end;
		drop i _type_ _freq_;
	run;

	data temp1;
		set &input;
		ID=1;
	run;

	data &output;
		merge temp1 temp;
		by ID;
		array var(&n) &var;
		array lower(&n) &varL;
		array upper(&n) &varH;

		do i=1 to dim(var);

			if not missing(var(i)) then
				do;

					if var(i) >=lower(i) and var(i) <=upper(i);
				end;
		end;
		drop &Q1 &Q3 &varL &varH ID i;
	run;

%mend;

%outliers(input=tt, var=age weight height, output=outresult);