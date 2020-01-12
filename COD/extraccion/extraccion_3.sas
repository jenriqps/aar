/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";



/* Input 3 */
/*
 * Parameters 
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=xlsx
	OUT=work.parametros REPLACE;
	GETNAMES=YES;
	sheet="parametros";
RUN;


data ext.parametros(label='Parameters');
	label 
		id_parameter = 'Parameter ID'
		dsc_parameter = 'Parameter description'
		val_parametro = 'Parameter Value';
	set work.parametros;
run;

* We add an index;
proc datasets library=ext nolist;
	modify parametros;
	index create id_parameter / nomiss unique;
run;


