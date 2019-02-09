/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%global root;
%let root=/folders/myfolders/aar;

%include "&root./COD/staging/cfinancieros/macrosCFinancieros.sas";
%include "&root./COD/staging/cfinancieros/configuracion.sas";


proc datasets lib=cfin kill nolist;
run;

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

/* Escenario base */


%assets_v2(sim=0,id_asset=1,curve=curve_int,spread=&i_spreadAAA.,callRate=&i_callRate.,valTotPort=&valTotPort.,spreadMort=&spreadMort.)
%assets_v2(sim=0,id_asset=2,curve=curve_int,spread=&i_spreadAAA.,callRate=&i_callRate.,valTotPort=&valTotPort.,spreadMort=&spreadMort.)
%assets_v2(sim=0,id_asset=3,curve=curve_int,spread=&i_spreadAAA.,callRate=&i_callRate.,valTotPort=&valTotPort.,spreadMort=&spreadMort.)



/* Escenarios alternativos */

%simAllAssets_v2(maxSim=100)
;



/* Unimos todas las reservas en un tabla, máxima granularidad */ 

data cfin.asset;
	set work.asset_id_:;
run;



proc datasets lib=work kill nolist;
run;




/* Agregamos por año */
proc sql;
	create table cfin.assets_year as
		select 
			cve_scenario
			, num_year
			, sum(val_assetValue) format comma16.2 as val_assetTotal
		from cfin.asset
		group by cve_scenario, num_year
		;
quit;

proc sql;
	create table cfin.assetsCF_year as
		select 
			cve_scenario
			, num_year
			, sum(val_cashFlow) format comma16.2 as val_assetCFTotal
		from cfin.asset
		group by cve_scenario, num_year
		;
quit;

proc datasets library=cfin;
	modify asset;
	format 
		val_assetValue val_cashFlow dollar32.;
	label 
		num_year="Year" 
		cve_scenario = "Scenario"
		id = "Asset ID"
		val_assetValue = "Asset Value"
		val_cashFlow = "Cash Flow"
		;
quit;


