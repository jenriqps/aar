/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%include "&root./COD/staging/cfinancieros/macrosCFinancieros.sas";
%include "&root./COD/configuracion.sas";


proc sql noprint;
	select val_parametro into: i_assets
	from ext.parametros
	where id_parameter=2
	;
quit;

proc sql noprint;
	select val_parametro into: i_spreadAAA
	from ext.parametros
	where id_parameter=5
	;
quit;

proc sql noprint;
	select val_parametro into: i_callRate
	from ext.parametros
	where id_parameter=4
	;
quit;

proc sql noprint;
	select val_parametro into: valTotPort
	from ext.parametros
	where id_parameter=3
	;
quit;

proc sql noprint;
	select val_parametro into: spreadMort
	from ext.parametros
	where id_parameter=10
	;
quit;



%let max_years = 200; 

	data work.curve_int;		
		do num_year=0 to &max_years.;
			val_int = &i_assets.; 
			output;
		end;
	run;


/* 2 Alternative scenarios */

%simAllAssets_v2(maxSim=100)
;

data cfin.asset_alt;
	set work.asset_id_:;
run;

proc datasets lib=work kill nolist nodetails;
quit;





