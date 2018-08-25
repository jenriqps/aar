%macro simAllProfits(maxSim=);

	proc sql;
		create table work.scenarios as
		select distinct cve_scenario
		from ext.esctasasinteres;
		;
	quit;
	
	
	data _null_;
		set work.scenarios;
		nom = 'ns_'||compress(put(_n_,3.));
		call symputx(nom,cve_scenario,'G');
	run;
	

	%do k=1 %to &maxSim.;
	
		data work.curve_int(keep=num_year val_int);	
			set ext.esctasasinteres(where=(cve_scenario=&&&&ns_&&k.));
			val_int=pct_rate;
		run;
		
		%profit(curve=curve_int,sim=&k.)
		

	%end;


	
%mend;

%macro profit(curve=,sim=);
	proc sql noprint;
		create table work.aux as
		select max(num_year) as v1
		from cact.reserve_year
		union
		select max(num_year) as v1
		from cfin.assets_year
		;
		select max(v1) into: max_hor
		from work.aux
		;
	quit;
	
	%put Horizonte máximo de tiempo = &max_hor.;
	
	proc sql noprint;
		select val_parametro into: annExpenses
		from ext.parametros
		where id_parameter=11
		;
		select val_parametro into: positiveBal
		from ext.parametros
		where id_parameter=12
		;
		select val_parametro into: negativeBal
		from ext.parametros
		where id_parameter=13
		;
	quit;


	data work.profits1;		
		do num_year=0 to &max_hor.+1;
			output;
		end;
	run;	
	
	proc sql;
		create table work.profits2 as
		select 
			a.num_year
			, b.val_int as val_scenTrRate
			, 0 as val_cbEOY
			, 0 as mnt_cbIntDuringYear
			, &sim. as cve_scenario
		from work.profits1 a left join work.&curve. b on a.num_year = b.num_year
		;
	quit;
	/*
	data work.profits2;
		set work.profits1;
		val_scenTrRate = &val_Trsry.; 
		val_cbEOY = 0;
		mnt_cbIntDuringYear = 0;
	run;
	*/
	
	proc sql;
		create table work.profits3 as
			select a.*, b.mnt_reserveTotal 
			from work.profits2 a left join cact.reserve_year b on (a.num_year=b.num_year)
			;
		create table work.profits4 as
			select a.*, b.mnt_projPymtTot 
			from work.profits3 a left join cact.projCF_year b on (a.num_year=b.num_year)
			;			
		create table work.profits5 as
			select 
				a.*
				, b.val_assetTotal 
			from work.profits4 a left join cfin.assets_year b on (a.num_year=b.num_year and a.cve_scenario = b.cve_scenario)			
			;
		create table work.profits6 as
			select 
				a.*
				, b.val_assetCFTotal 
			from work.profits5 a left join cfin.assetsCF_year b on (a.num_year=b.num_year and a.cve_scenario = b.cve_scenario)
			;		
	quit;
	
	data work.profits7;
		format mnt_expenses mnt_cfDuringYear comma16.2;
		set work.profits6;
		mnt_expenses = &annExpenses.*(mnt_projPymtTot>0);
		val_discountFactor = 1;
		/*mnt_cfDuringYear = sum(val_cfTotal,-mnt_projPymtTot,-mnt_expenses);*/
	run;
	
	%do i=1 %to &max_hor.;
		data work.profitsaux(where=(num_year=&i.));
			format mnt_cbIntDuringYear mnt_cfDuringYear val_cbEOY mnt_totalAssetsEOY mnt_totalAssetsCFDuringYear mnt_benefitsPlusExpenses mnt_investIncome mnt_increaseReserves mnt_annualProfit comma16.2 val_discountFactor comma16.10;
			set work.profits7;
			if num_year <= &i. then
				do;
					call symputx('aux',lag(val_cbEOY),'L');
					mnt_cbIntDuringYear = sum(lag(val_cbEOY)*sum(val_scenTrRate,&negativeBal.)*(lag(val_cbEOY)<0),lag(val_cbEOY)*sum(val_scenTrRate,&positiveBal.)*(lag(val_cbEOY)>=0));
					mnt_cfDuringYear = sum(val_assetCFTotal,-mnt_projPymtTot,-mnt_expenses,mnt_cbIntDuringYear);
					val_cbEOY = sum(lag(val_cbEOY),mnt_cfDuringYear);
					mnt_totalAssetsEOY = sum(val_assetTotal,val_cbEOY);
					mnt_totalAssetsCFDuringYear = sum(val_assetCFTotal,mnt_cbIntDuringYear);
					mnt_benefitsPlusExpenses = sum(mnt_projPymtTot,mnt_expenses);
					mnt_investIncome = sum(val_assetCFTotal,val_assetTotal-lag(val_assetTotal),mnt_cbIntDuringYear)*(mnt_benefitsPlusExpenses>0);
					mnt_increaseReserves = mnt_reserveTotal - lag(mnt_reserveTotal);
					mnt_annualProfit = sum(mnt_investIncome,-mnt_benefitsPlusExpenses,-mnt_increaseReserves);
					val_discountFactor = lag(val_discountFactor)*(1+val_scenTrRate)**-1;
					/*output;*/
				end;
		run;
		
		data work.profits7;
			update work.profits7 profitsAux;
			by num_year;
		run;
	%end;
	
	proc sql;
		create table work.profit_&sim. as
			select 
				cve_scenario
				, num_year
				, val_scenTrRate
				, mnt_reserveTotal
				, val_assetTotal
				, val_assetCFTotal
				, mnt_projPymtTot
				, mnt_expenses
				, mnt_cfDuringYear
				, val_cbEOY
				, mnt_cbIntDuringYear
				, mnt_totalAssetsEOY
				, mnt_totalAssetsCFDuringYear
				, mnt_investIncome
				, mnt_benefitsPlusExpenses
				, mnt_increaseReserves
				, mnt_annualProfit
				, val_discountFactor
				, val_discountFactor*mnt_annualProfit format comma16.2 as mnt_pvAnnualProfit
			from work.profits7
			;	
			
	quit;
	
	/* Limpiamos la memoria */
	
	proc datasets lib=work nolist;
		delete profits: profitsaux;
	run;
	
	


%mend;