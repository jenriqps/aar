/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";


/* Input 5 */
/*
 * Mortality table
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=work.tablaMortalidad REPLACE;
	GETNAMES=YES;
	SHEET="tablaMortalidad";
RUN;


data ext.tablaMortalidad(label="Mortality Table");
	label 
		val_age = 'Attained age (years)'
		val_1000qx = '1000 q_x'
		;
	set work.tablaMortalidad;
run;

* We add an index;
proc datasets library=ext nolist;
	modify tablaMortalidad;
	index create val_age / nomiss unique;
run;


