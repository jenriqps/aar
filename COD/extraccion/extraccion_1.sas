/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";

/* Input 1 */
/*
 * Financial assets catalog
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=work.catActFin REPLACE;
	GETNAMES=YES;
	SHEET="catActFin";
RUN;

data ext.catActFin(label="Catalog of Financial Assets");
	label
		cod_asset = 'Code of the asset'
		dsc_asset = 'Description of the asset';
	set work.catActFin;
run;

proc sql noprint;
	select put(cod_asset,2.)||"="||"'"||trim(dsc_asset)||"'" into :vara separated by " "
	from ext.catActFin
	;
quit;

%put &vara.; 

proc format lib=ext;
	value asset
	&vara.
	;
run;

* We add an index;
proc datasets library=ext nolist nodetails;
	modify catActFin;
	index create cod_asset / nomiss unique;
quit;

* Metadata;
proc contents data=ext.catActFin varnum;
run;


