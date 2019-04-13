/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options  fmtsearch=(ext);

%include "&root./COD/configuracion.sas";

proc datasets lib=ext kill nolist;
run;

proc datasets lib=work kill nolist;
run;


FILENAME REFFILE "&root./DAT/extraccion/insumos/insumos.xlsx";

/* Input 1 */
/*
 * Catálogo de activos financieros
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

* Agregamos un índice;
proc datasets library=ext nolist;
	modify catActFin;
	index create cod_asset / nomiss unique;
run;


/* Input 2 */
/*
 * Tabla con los asegurados
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=xlsx
	OUT=work.asegurados REPLACE;
	GETNAMES=YES;
	sheet="asegurados";
RUN;

data ext.asegurados(label="Characteristics of the annuities");
	format mnt_annualPayment comma30.2 fec_issueDate fec_currentDate date9.;
	label 
		id_annuity = 'Annuities'
		num_issueAge ='Male Issue Age'
		fec_issueDate ='Issue Date'
		fec_currentDate ='Current Date'
		mnt_annualPayment ='Annual Payment'
		num_originalTotalYearsPayments = 'Original Total Years of Payments'
		num_originalCertainYears = 'Original Certain Years' 	
		num_extraPymt = 'Number of extra payments';
	set work.asegurados;
run;

* Agregamos un índice;
proc datasets library=ext nolist;
	modify asegurados;
	index create id_annuity / nomiss unique;
run;

/* Input 3 */
/*
 * Parámetros 
 */

PROC IMPORT DATAFILE=REFFILE
	DBMS=xlsx
	OUT=work.parametros REPLACE;
	GETNAMES=YES;
	sheet="parametros";
RUN;


data ext.parametros(label="Parameters");
	label 
		id_parameter = 'Identificador del parámetro'
		dsc_parameter = 'Descripción del parámetro'
		val_parametro = 'Valor del parámetro';
	set work.parametros;
run;

* Agregamos un índice;
proc datasets library=ext nolist;
	modify parametros;
	index create id_parameter / nomiss unique;
run;


/* Input 4 */
/*
 * Activos financieros
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

* Agregamos un índice;
proc datasets library=ext nolist;
	modify activosFinancieros;
	index create id_asset / nomiss unique;
run;

/* Input 5 */
/*
 * Tabla de Mortalidad
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

* Agregamos un índice;
proc datasets library=ext nolist;
	modify tablaMortalidad;
	index create val_age / nomiss unique;
run;


/* Input 6 */
/*
 * Escenarios de tasas de interés
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

* Agregamos un índice;
proc datasets library=ext nolist;
	modify escTasasInteres;
	index create i6 = (cve_scenario num_year) / nomiss unique;
run;


/* Limpiamos la memoria */
	
proc datasets lib=work kill nolist;
run;
	
