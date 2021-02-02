/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
options mprint mlogic minoperator fullstimer;
%include "&root./COD/configuracion.sas";
%include "&root./COD/staging/profit/macrosProfit.sas";

proc datasets lib=prft kill nolist;
	run;

	/* Tasa actual de Treasuries */
proc sql noprint;
	select val_parametro into: val_Trsry from ext.parametros where id_parameter=2;
quit;

%let max_years = 200;

data work.curve_int;
	do num_year=0 to &max_years.;
		val_int=&val_Trsry.;
		output;
	end;
run;

/* Escenario base */
%profit_v2(curve=curve_int, sim=0);

/* Escenarios alternativos */

%simAllProfits_v2(maxSim=100);

data prft.profit;
	set work.profit_:;
run;

proc datasets lib=work kill nolist;
	quit;

proc sql;
	create table prft.pvProfits as select cve_scenario
		, sum(mnt_pvAnnualProfit) format comma16.2 as pvAnnualProfit from 
		prft.profit group by cve_scenario;
quit;

proc datasets library=prft;
	modify profit;
	label 
	num_year="Year" 
	mnt_pvAnnualProfit="PV of Annual Profits"
	cve_scenario="Scenario"
	val_scenTrRate="Scenario Treasury Rate"	
	mnt_reserveTotal="Reserve End of Year"
	val_assetTotal="Existing Assets - Asset Value End of Year"
	val_assetCFTotal="Existing Assets - Cash Flow"
	mnt_projPymtTot="Projected Annuity Benefits"
	mnt_expenses="Expenses"
	mnt_cfDuringYear="Cash Flow During Year"
	val_cbEOY="Cash Balance - Value End of Year"
	mnt_cbIntDuringYear="Cash Balance - Interest During Year"
	mnt_totalAssetsEOY="Total Assets - Asset Value End of Year"
	mnt_totalAssetsCFDuringYear="Total Assets Cash Flow During Year"
	mnt_investIncome="Investment Income"
	mnt_benefitsPlusExpenses="Benefits and Expenses"
	mnt_increaseReserves="Increase in Reserves"
	mnt_annualProfit="Annual Profits"
	val_discountFactor="Cumulative Discount Rates";
quit;

proc datasets library=prft;
	modify pvprofits;
	label 
	cve_scenario= "Scenario"
	pvAnnualProfit = "PV of Annual Profits"
	;
quit;