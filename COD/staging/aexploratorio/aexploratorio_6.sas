/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);



/* 6 Financial assets */


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






