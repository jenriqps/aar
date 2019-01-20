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


%macro profit_v2(curve=,sim=);
	* Cálculo de escenarios de utilidades con SAS/IML;
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
	
	%put annExpenses = &annExpenses, positiveBal=&positiveBal., negativeBal=&negativeBal;

	proc iml;
		* Curva;
		edit work.&curve.;
		read all var _NUM_ into curv0[colname=numVars];
		close work.&curve.;
		* Reservas;
		edit cact.reserve_year;
		read all var _NUM_ into res0[colname=numVars];
		close cact.reserve_year;
		* Flujos de pasivos;
		edit cact.projcf_year;
		read all var _NUM_ into lcf0[colname=numVars];
		close cact.projcf_year;
		* Valor de los activos;
		edit cfin.assets_year(where=(cve_scenario=&sim.));
		read all var _NUM_ into assets0[colname=numVars];
		close cfin.assets_year;
		* Flujos de los activos;
		edit cfin.assetscf_year(where=(cve_scenario=&sim.));
		read all var _NUM_ into acf0[colname=numVars];
		close cfin.assetscf_year;	

		*res=J(100,2,0);
		*print res;
		curv=shape(curv0,100,2,0);
		res=shape(res0,100,2,0);
		lcf=shape(lcf0,100,2,0);
		assets=shape(assets0,100,3,0);
		acf=shape(acf0,100,3,0);
		/*
		print curv;		
		print res;
		print lcf;
		print assets;
		*/
		*print acf;
		
		
		
		prft=J(&max_hor.+2,19,0);
		do i=0 to (&max_hor.+1);
			* num_year;
			prft[i+1,1]=i;
			* val_scenTrRate;
			prft[i+1,2]=curv[i+1,2];
			* cve_scenario;
			prft[i+1,3]=&sim.;
			* mnt_reserveTotal;
			prft[i+1,4]=res[i+1,2];
			* mnt_projPymtTot;
			prft[i+1,5]=lcf[i+1,2];
			* val_assetTotal;
			prft[i+1,6]=assets[i+1,3];
			
			* val_assetCFTotal;
			prft[i+1,7]=acf[i+1,3];
			
			* mnt_expenses;
			if prft[i+1,5] > 0 then aux=1; else aux=0;
			prft[i+1,8]=&annExpenses.*aux;
			
			* mnt_cbIntDuringYear;
			if prft[i+1,1] > 0 then
				do;
					if prft[i,9] < 0 then aux1=1; else aux1=0;
					if prft[i,9] >= 0 then aux2=1; else aux2=0;			
					prft[i+1,10]=sum(prft[i,9]*sum(prft[i+1,2],&negativeBal.)*aux1,prft[i,9]*sum(prft[i+1,2],&positiveBal.)*aux2);
				end;			
			* mnt_cfDuringYear;
			prft[i+1,11]=sum(prft[i+1,7],-prft[i+1,5],-prft[i+1,8],prft[i+1,10]);
			* val_cbEOY;
			if i = 0 then prft[i+1,9]=0; else prft[i+1,9]=sum(prft[i,9],prft[i+1,11]);
			* mnt_totalAssetsEOY;
			prft[i+1,12]=sum(prft[i+1,6],prft[i+1,9]);
			* mnt_totalAssetsCFDuringYear;
			prft[i+1,13]=sum(prft[i+1,7],prft[i+1,10]);		
			* mnt_benefitsPlusExpenses;
			prft[i+1,14]=sum(prft[i+1,5],prft[i+1,8]);
			* mnt_investIncome;
			if prft[i+1,1]>0 then
				do;
					if prft[i+1,14] > 0 then aux=1; else aux=0;
					prft[i+1,15]=sum(prft[i+1,7],prft[i+1,6]-prft[i,6],prft[i+1,10])*aux;
				end;
			* mnt_increaseReserves;
			if prft[i+1,1] > 0 then prft[i+1,16]=prft[i+1,4] - prft[i,4]; else prft[i+1,16]=0;
			* mnt_annualProfit;
			prft[i+1,17]=sum(prft[i+1,15],-prft[i+1,14],-prft[i+1,16]);
			* val_discountFactor;
			if prft[i+1,1] = 0 then prft[i+1,18]=1; else prft[i+1,18]=prft[i,18]*(1+prft[i+1,2])**-1;
			* mnt_pvAnnualProfit;
			prft[i+1,19]=prft[i+1,18]*prft[i+1,17];					
		end;
		
		* Enviamos los resultados a un data set;
		create work.prft from prft;
		append from prft;
		close work.prft;
	run;

	
	data work.profit_&sim.(drop=col:);
		format 
					mnt_reserveTotal
					val_assetTotal
					val_assetCFTotal
					mnt_projPymtTot
					mnt_expenses
					mnt_cfDuringYear
					val_cbEOY
					mnt_cbIntDuringYear
					mnt_totalAssetsEOY
					mnt_totalAssetsCFDuringYear
					mnt_investIncome
					mnt_benefitsPlusExpenses
					mnt_increaseReserves
					mnt_annualProfit
					val_discountFactor
					mnt_pvAnnualProfit dollar16.2;				
		
		set work.prft;
					cve_scenario=col3;
					num_year=col1;
					val_scenTrRate=col2;
					mnt_reserveTotal=col4;
					val_assetTotal=col6;
					val_assetCFTotal=col7;
					mnt_projPymtTot=col5;
					mnt_expenses=col8;
					mnt_cfDuringYear=col11;
					val_cbEOY=col9;
					mnt_cbIntDuringYear=col10;
					mnt_totalAssetsEOY=col12;
					mnt_totalAssetsCFDuringYear=col13;
					mnt_investIncome=col15;
					mnt_benefitsPlusExpenses=col14;
					mnt_increaseReserves=col16;
					mnt_annualProfit=col17;
					val_discountFactor=col18;
					mnt_pvAnnualProfit=col19;				
	run;
	
	/* Limpiamos la memoria */
	
	proc datasets lib=work nolist;
		delete profits: profitsaux;
	run;
	
	


%mend;


%macro simAllProfits_v2(maxSim=);

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
		
		%profit_v2(curve=curve_int,sim=&k.)
		

	%end;


	
%mend;

