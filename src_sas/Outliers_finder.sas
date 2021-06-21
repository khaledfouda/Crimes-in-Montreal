/* ods listing gpath="&print_dir" image_dpi=200 ; */
/* ods graphics / reset scalemarkers=no width=800px imagename="seasonality" ; */
/*  */
/* proc sgpanel data=ucm_all noautolegend; */
/* 	title 'Seasonality per category'; */
/* 	where date between '01JAN2018'd and '31DEC2018'd; */
/* 	panelby category /  novarname  nowall noheaderborder  ; */
/* 	series x=date y=s_season / transparency=.8 ; */
/* 	scatter x=date y=s_season ; */
/* 	colaxis  interval=month label='Month' valuesformat=monname3. ; */
/* 	rowaxis display=none; */
/* run; */
/* ods listing; */
/* ods graphics; */
/* *------------------------------------------------------------------------; */
ods listing gpath="&print_dir" image_dpi=200 ;
ods graphics / reset scalemarkers=no width=800px imagename="model_fit" ;

proc sgpanel data=ucm_std ;
	title 'Model Fit (After applying seasonality and ARMA model)';
	title2 'The data were standardized to keep a common y-axis';
	where date lt '01JUN2021'd;
	panelby category /  novarname  nowall noheaderborder  ;
	series x=date y=s_treg / transparency=.1 name='Model' legendlabel='Model' ;
	scatter x=date y=count /transparency=.7 name='Original' legendlabel='Original';
	colaxis  interval=year label='Month' /*valuesformat=monname3.*/ ;
	rowaxis display=none;
	keylegend "Model" "Original" / position=top;
run;
ods listing;
ods graphics;




/*  */
/*  */
/* proc stdize data=ucm_all out=ucm_std method=std; */
/* 	by category; */
/* 	var count s_treg s_irreg; */
/* run; */