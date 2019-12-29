/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);


proc datasets lib=aexpl kill nolist;
run;

/*
 * Tabla de mortalidad
 */

* Agregamos valores a la tabla de mortalidad;
proc iml;
	edit ext.TABLAMORTALIDAD;
	read all var _NUM_ into lt[colname=numVars];
	close ext.TABLAMORTALIDAD; 	

	radix=1000000;
	n = nrow(lt);
	*print n;
	ltplus=J(n,5);
	*print ltplus;
	do i=1 to n;
		ltplus[i,1]=lt[i,1];
		ltplus[i,2]=lt[i,2];
		ltplus[i,3]=lt[i,2]/1000;
		if i=1 then ltplus[i,4]=radix;
		else ltplus[i,4]=ltplus[i-1,4]*(1-ltplus[i-1,3]);
	end;
	
	do i = n to 1 by -1;
		if i = n then ltplus[i,5] = (1 - ltplus[i,3]);
		else ltplus[i,5] = (1 - ltplus[i,3]) * ( 1 + ltplus[i+1,5]);
	end;
	*print ltplus;
	* Enviamos los resultados a un data set;
	create work.ltplus from ltplus;
	append from ltplus;
	close work.ltplus;	
run;


data ext.tablamortalidadv2;
	format 
	col1 comma10. col2 comma10.6 col3 comma10.6 col4 comma10. col5 comma10.1; 
	label
	col1 = "Attained age (years)"
	col2 = "1000 q_x"
	col3 = "q_x"
	col4 = "l_x"
	col5 = "e_x";
	set work.ltplus;	
run;



title 'Mortality table';
proc sgplot data=ext.tablamortalidadv2;
	step x=col1 y=col3 / lineattrs=(color=orange);
	step x=col1 y=col4 / y2axis lineattrs=(color=blue);
	xaxis grid;
	yaxis grid;
run;
title;

title 'Life Expectation';
proc sgplot data=ext.tablamortalidadv2;
	step x=col1 y=col5 / lineattrs=(color=green);
	xaxis grid;
	yaxis grid;
run;
title;



/*
 * Escenarios de la curva de interés
 */

title 'Scenarios of the annual forward rate';
proc sgplot data=ext.esctasasinteres;
	series x=num_year y=pct_rate / group=cve_scenario;
run;
title;

title 'Heatmap of the scenarios of the annual forward rate';
proc sgplot data=ext.esctasasinteres;
	heatmap x=num_year y=pct_rate / colorstat=freq nxbins=50 nybins=10 showybins showxbins;
run;
title;

/*
 * Identificamos los diferentes nodos
 */

ods graphics / reset width=8in height=8in imagemap noborder;

title "Panel of the distribution of the scenarios of the annual forward rate";
proc sgpanel data=ext.esctasasinteres(where=(num_year ne 1));
	panelby num_year / uniscale=all columns=5 rows=6;
 	histogram pct_rate / fillattrs=(color=orange transparency=0.7);
 	density pct_rate / lineattrs=(color=red);
run;
title;

ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%macro histogramas();

	proc sql noprint;
		create table work.years as
		select distinct num_year
		from ext.esctasasinteres
		;
		select count(*) into: num
		from work.years
		;
		select num_year into: year1-
		from work.years
		;	
	quit;
	
	%do i=1 %to &num.;
	title "Histograma de las tasas generadas en el año &&&&year&&i.";

/* Dejar lo siguiente porque a veces falla proc univariate (los histogramas) */	
	/*
	proc sgplot data=ext.esctasasinteres;
		where num_year=&&&&year&&i.;
		histogram pct_rate;
	run;
*/
	proc univariate data=ext.esctasasinteres(where=(num_year=&&&&year&&i.));
		var pct_rate;
		histogram pct_rate/normal grid;
	run;	

	%end;
%mend;

*%histogramas;

/* Asegurados */
title "Characteristics of the insured people";
proc print data=ext.asegurados label;
run;

title "Buble plot of the characteristics of the insured people";
proc sgplot data=ext.asegurados;
	bubble x=num_issueAge y=num_originalTotalYearsPayments size=num_originalCertainYears / colorresponse=mnt_annualPayment;
	xaxis grid;
	yaxis grid;
run;

title "Characteristics of the financial assets";
proc print data=ext.activosfinancieros label;
run;

title "Callable bonds";
proc sgplot data=ext.activosfinancieros;
	vbar flg_callable  / response=pct_portfolio group=cod_asset;
	yaxis grid;
run;

proc template;
	define statgraph SASStudio.Pie;
		begingraph;
		layout region;
		piechart category=cod_asset response=pct_portfolio / group=flg_callable 
			groupgap=2% datalabellocation=inside;
		endlayout;
		endgraph;
	end;
run;

title "Type of financial asset and callability";
proc sgrender template=SASStudio.Pie data=EXT.ACTIVOSFINANCIEROS;
run;

title "Annual Yield";
proc sgplot data=ext.activosfinancieros;
	vbar dsc_asset  / response=pct_annualYield group=cod_asset;
	yaxis grid;
run;

title "Years of call protection";
proc sgplot data=ext.activosfinancieros;
	vbar dsc_asset  / response=num_YrsCallProtection group=cod_asset;
	yaxis grid;
run;

title "Remaining years";
proc sgplot data=ext.activosfinancieros;
	vbar dsc_asset  / response=num_remainingYears group=cod_asset;
	yaxis grid;
run;

proc template;
	define statgraph SASStudio.Pie2;
		begingraph;
		layout region;
		piechart category=cv_currency response=pct_portfolio / group=flg_callable 
			groupgap=2% datalabellocation=inside;
		endlayout;
		endgraph;
	end;
run;

title "Currency of the financial asset and callability";
proc sgrender template=SASStudio.Pie2 data=EXT.ACTIVOSFINANCIEROS;
run;

proc template;
	define statgraph SASStudio.Pie3;
		begingraph;
		layout region;
		piechart category=tx_country response=pct_portfolio  / group=flg_callable 
			groupgap=2% datalabellocation=inside;
		endlayout;
		endgraph;
	end;
run;

title "Country of the issuer and callability of the financial assets";
proc sgrender template=SASStudio.Pie3 data=EXT.ACTIVOSFINANCIEROS;
run;


ods graphics / reset width=8in height=4.8in imagemap noborder;
proc sgmap plotdata=EXT.ACTIVOSFINANCIEROS;
	openstreetmap;
	title 'Investments by Country';
	bubble x=num_longitude y=num_latitude size=pct_portfolio/ group=tx_country 
		name="bubblePlot";
	keylegend "bubblePlot" / title='Country:';
run;
ods graphics / reset;
title;





