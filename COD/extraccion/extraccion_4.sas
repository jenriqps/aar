/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";

/* Input 4 */
/*
 * Financial assets
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=work.activosFinancieros REPLACE;
	GETNAMES=YES;
	SHEET="activosFinancieros";
RUN;

proc format lib=ext;
	value sino
	1="Yes"
	0="No";
run;

data ext.activosFinancieros(label="Characteristics of the Financial Assets");
	length tx_country $50.;
	format
	pct_portfolio pct_annualYield percentn10.2
	flg_callable sino.
	cod_asset asset.;
	label 
		id_asset = 'Asset ID'
		dsc_asset = 'Asset Description'
		num_remainingYears='Remaining Years'
		num_YrsCallProtection = 'Yrs of Call Protection'
		pct_annualYield = 'Annual Yield'
		pct_portfolio = 'Porcentaje del portafolio'	
		cod_asset = 'Type of financial asset'
		flg_callable = 'Is the bond callable?'
		tx_country = "Country of the issuer"
		cv_currency = "Currency"
		num_latitude = "Latitude of the issuer"
		num_longitude = "Longitude of the issuer"
		;
	set work.activosFinancieros;
run;

* We add an index;
proc datasets library=ext nolist nodetails;
	modify activosFinancieros;
	index create id_asset / nomiss unique;
quit;

* Metadata;
proc contents data=ext.activosFinancieros varnum;
run;

