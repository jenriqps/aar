/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";

/* Input 6 */
/*
 * Interest rates scenarios
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=work.escTasasInteres REPLACE;
	GETNAMES=YES;
	SHEET="escTasasInteres";
RUN;

data ext.escTasasInteres(label="Scenarios of the Interest Rates");
	format pct_rate percentn10.2;
	label
		cve_scenario = 'Scenario'
		num_year = 'Year'
		pct_rate = 'Interest rate';
	set work.escTasasInteres;
run;

* We add an index;
proc datasets library=ext nolist nodetails;
	modify escTasasInteres;
	index create i6 = (cve_scenario num_year) / nomiss unique;
quit;


/* We clean the Work library */
	
proc datasets lib=work kill nolist;
run;
	
