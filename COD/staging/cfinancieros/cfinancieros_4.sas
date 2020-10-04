/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%include "&root./COD/staging/cfinancieros/macrosCFinancieros.sas";
%include "&root./COD/configuracion.sas";

/* 4 We add the valuations per year */
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
	modify assets_year;
	format 
		val_assetTotal dollar32.;
	label 
		num_year="Year" 
		cve_scenario = "Scenario"
		val_assetTotal = "Total Asset Value"
		;	
	modify assetscf_year;
	format 
		val_assetCFTotal dollar32.;
	label 
		num_year="Year" 
		cve_scenario = "Scenario"
		val_assetCFTotal = "Total Asset Cash Flow"
		;	
quit;


