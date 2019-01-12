%macro simAllAssets(maxSim=);

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
		
		proc sql noprint;		
			select pct_annualYield into: pct_annualYield
			from ext.activosfinancieros
			where id_asset = 1
			;
		quit;

		
		proc sql;
			insert into work.curve_int
				set num_year = 0,
					val_int = &pct_annualYield.
				;
		quit;
		
		proc sort data=work.curve_int;
			by num_year;
		run;
		
		%assets(sim=&k.,id_asset=1,curve=curve_int,spread=&i_spreadAAA.,callRate=&i_callRate.,valTotPort=&valTotPort.,spreadMort=&spreadMort.)
		%assets(sim=&k.,id_asset=2,curve=curve_int,spread=&i_spreadAAA.,callRate=&i_callRate.,valTotPort=&valTotPort.,spreadMort=&spreadMort.)		
		%assets(sim=&k.,id_asset=3,curve=curve_int,spread=&i_spreadAAA.,callRate=&i_callRate.,valTotPort=&valTotPort.,spreadMort=&spreadMort.)
		

	%end;

%mend;



%macro assets(sim=,id_asset=,curve=,spread=,callRate=,valTotPort=,spreadMort=);
	proc sql noprint;
		select num_remainingYears into: num_remainingYears
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;
		select pct_annualYield into: pct_annualYield
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;
		select pct_portfolio into: pct_portfolio
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select num_remainingYears into: num_remainingYears
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select cod_asset into: cod_asset
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select num_YrsCallProtection into: num_YrsCallProtection
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select flg_callable into: flg_callable
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;			
	quit;
	
	%put Number of remaining years &num_remainingYears. || Annual yield &pct_annualYield. || Percentage of portfolio &pct_portfolio. || Type of asset &cod_asset.;
	
	data work.assets1;		
		do num_year=0 to &num_remainingYears.;
			output;
		end;
	run;
	
	/* Bono cuponado, callable */

	%if &cod_asset. = 1 %then
		%do;
			proc sql;
				create table work.assets2 as
					select 
						a.*
						, sum(b.val_int,&spread.) as val_curAvaiRate
					from work.assets1 a inner join work.curve_int b on a.num_year = b.num_year	
					;
			quit;
			
			%local ind1;
			%let ind1 = n;
			
			data work.assets21;
				set work.assets2;	
				dif = &pct_annualYield. - val_curAvaiRate;
				if &flg_callable. = 1 and num_year <= &num_YrsCallProtection. then
					cod_callable = "n";
			run;
			
			data work.assets3;
				set work.assets21;	
				if dif gt &callRate. and num_year > &num_YrsCallProtection. then
					cod_callable = "y";
				else 
					cod_callable = "n";		
				
			run;	
			
			%do t=1 %to &num_remainingYears.;
			
				data work.aux;
					set work.assets3;
					if num_year <= &t. then				
					lagCod_Callable = lag(cod_callable);
					if lagCod_Callable = 'y' then
						cod_callable = lagCod_Callable;
				run;
				
				data work.assets3;
					update work.assets3 work.aux;
					by num_year;
				run;
			
			%end;
				
			
			
			
			/*
			
			data work.assets3;
				set work.assets2;
				if &flg_callable. = 1 and num_year > &num_YrsCallProtection. then
					do;
						dif = &pct_annualYield. - val_curAvaiRate;
						marca = &callRate.;
						etiqueta = "&ind1.";
						if dif gt &callRate. then		
						if dif gt &callRate. then
							do;
								cod_callable = "y";
								call symputx("ind1","y","L");
							end;
						if "&ind1." = "y" then
							do;
								cod_callable="y";							
							end;
						else
							cod_callable="n";	
						
					end;
				else
					cod_callable="n";
			run;
			*/
			
		
			data work.assets4;
				set work.assets3;
				if cod_callable='y' then
					do;
						val_assetValue=0;
					end;
				else
					if num_year lt &num_remainingYears. then
						val_assetValue=&pct_portfolio.*&valTotPort.;
					else
						val_assetValue=0;
						
			run;
			
			data work.assets5;
				set work.assets4;		
				val_cashFlow = sum(lag(val_assetValue)*&pct_annualYield.,sum(-val_assetValue,lag(val_assetValue)));
				output;					
				
				if num_year eq 0 then
					do;
						val_cashFlow=0;
					end;
			run;
			
			data work.asset_id_&id_asset._&sim.(keep=cve_scenario id num_year val_assetValue val_cashFlow);
				set work.assets5;
				cve_scenario = &sim.;
				id = &id_asset.;
			run;
		%end;

	/* Bono cupón cero */

	%if &cod_asset. = 2 %then
		%do;
			data work.assets2;
				set work.assets1;
				if num_year lt &num_remainingYears. then
				val_assetValue = &pct_portfolio.*&valTotPort.*(1+&pct_annualYield.)**num_year;
				if num_year = (&num_remainingYears.) then
					val_cashFlow = &pct_portfolio.*&valTotPort.*(1+&pct_annualYield.)**num_year;
				else 
					val_cashFlow = 0;
				
			run;
			
			data work.asset_id_&id_asset._&sim.(keep=cve_scenario id num_year val_assetValue val_cashFlow);
				set work.assets2;
				cve_scenario = &sim.;
				id = &id_asset.;
			run;
		%end;
	
	/* Bono respaldado con hipotecas */

	%if &cod_asset. = 3 %then
		%do;
			proc sql;
				create table work.assets2 as
					select 
						a.*
						, sum(b.val_int,&spreadMort.) as val_curAvaiRateMort
					from work.assets1 a left join work.curve_int b on a.num_year = b.num_year	
					;
			quit;
			
			proc sql noprint;
			/* Regular */
				select val_parametro into: prePymt0
				from ext.parametros
				where id_parameter=6
				;	
			/* Additional */
				select val_parametro into: prePymt1
				from ext.parametros
				where id_parameter=7
				;
				select val_parametro into: prePymt2
				from ext.parametros
				where id_parameter=8
				;				
			quit;
			
			data work.assets3;
				set work.assets2;
				val_extAnPrePymt = min(1,max(0,&prePymt1.*(&pct_annualYield.-val_curAvaiRateMort)/&prePymt2.));
				mnt_outsPrincipalEOY = 0;
				mnt_interestPymt = 0;
				mnt_principalPymt = 0;
				mnt_totalPymt = 0;	
				mnt_prePymt = 0;
				mnt_totalCF = 0;
			run;			
			
			%put pct_portfolio = &pct_portfolio. valTotPort = &valTotPort.;
			
			data work.assets4;
				set work.assets3;
				if num_year=0 then
				do;
					mnt_outsPrincipalEOY = &pct_portfolio.*&valTotPort.;
					val_cashFlow = mnt_outsPrincipalEOY;
					output;
				end;
				else
					output;
			run;
		
			
			%do i=1 %to &num_remainingYears.;			
				data work.aux(where=(num_year=&i.));
					set work.assets4;
					if num_year <= &i. then
						do;
							mnt_interestPymt = lag(mnt_outsPrincipalEOY)*&pct_annualYield.;
							mnt_totalPymt = mort(lag(mnt_outsPrincipalEOY),.,&pct_annualYield.,&num_remainingYears.+1-num_year);
							mnt_principalPymt = sum(mnt_totalPymt,-mnt_interestPymt);
							mnt_prePymt = (val_extAnPrePymt+&prePymt0.)*(lag(mnt_outsPrincipalEOY)-mnt_principalPymt);
							mnt_totalCF = sum(mnt_totalPymt,mnt_prePymt);						 
							mnt_outsPrincipalEOY = sum(sum(lag(mnt_outsPrincipalEOY),-mnt_principalPymt,-mnt_prePymt),&pct_portfolio.*&valTotPort.*(num_year = 0));
							val_assetValue = mnt_outsPrincipalEOY;
							val_cashFlow = mnt_totalCF;
							output;
						end;
				run;
				
				
				data work.assets4;
					update work.assets4 aux;
					by num_year;					
				run;
				
				data work.asset_id_&id_asset._&sim.(keep= cve_scenario id num_year val_assetValue val_cashFlow);
					format num_year 10. val_assetValue val_cashFlow comma16.2;
					set work.assets4;
					cve_scenario = &sim.;
					id = &id_asset.;
					val_assetValue = mnt_outsPrincipalEOY;
					val_cashFlow = mnt_totalCF;
				run;
				
			%end;

			
		
			
		%end;
		
	/* Limpiamos la memoria */
	
	proc datasets lib=work nolist;
		delete assets: aux:;
	run;
	
	

	
%mend;


%macro assets_v2(sim=,id_asset=,curve=,spread=,callRate=,valTotPort=,spreadMort=);
/*
Cálculo de precios de activos con SAS/IML
*/

	proc sql noprint;
		select num_remainingYears into: num_remainingYears
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;
		select pct_annualYield format 16.6 into: pct_annualYield
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;
		select pct_portfolio format 16.6 into: pct_portfolio
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select num_remainingYears into: num_remainingYears
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select cod_asset format 6. into: cod_asset
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select num_YrsCallProtection into: num_YrsCallProtection
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;	
		select flg_callable format 6. into: flg_callable
		from ext.activosfinancieros
		where id_asset = &id_asset.
		;			
	quit;
	
	%put Number of remaining years=&num_remainingYears. || Annual yield=&pct_annualYield. || Percentage of portfolio=&pct_portfolio. || Type of asset:&cod_asset.;
	
	data work.assets1;		
		do num_year=0 to &num_remainingYears.;
			output;
		end;
	run;
	
	/* Bono cuponado, callable */

	%if &cod_asset. = 1 %then
		%do;
		
			proc iml;
				edit work.curve_int;
				read all var _NUM_ into curv[colname=numVars];
				close work.curve_int;
				
				asset = J(&num_remainingYears.+1,6,0);
				print asset;
				do i=0 to &num_remainingYears.;
					* num_year;
					asset[i+1,1]=i;
					* val_curAvaiRate;
					asset[i+1,2]=curv[i+1,2]+&spread.;
					* dif;
					asset[i+1,3]=&pct_annualYield.-asset[i+1,2];
					* Flag de callable;
					if &flg_callable. = 1 & asset[i+1,1] <= &num_YrsCallProtection. then asset[i+1,4] = 0;
					if asset[i+1,3] > &callRate. & asset[i+1,1] > &num_YrsCallProtection. then asset[i+1,4]=1;
					else asset[i+1,4]=0;
					if i>0 then; if asset[i,4]=1 then asset[i+1,4]=1;
					* Asset value;
					if asset[i+1,4]=1 then asset[i+1,5]=0;
					else asset[i+1,5]=&pct_portfolio.*&valTotPort.;
					* Cashflow;
					if asset[i+1,1] = 0 then asset[i+1,6]=0;
					else asset[i+1,6] = asset[i,5]*&pct_annualYield.+(-asset[i+1,5]+asset[i,5]);
				end;
				print asset;
				
				* Enviamos los resultados a un data set;
				create work.assets5 from asset;
				append from asset;
				close work.assets5;	
				
			run;

			data work.asset_id_&id_asset._&sim.(keep=cve_scenario id num_year val_assetValue val_cashFlow);
				set work.assets5;
				num_year = col1;
				val_assetValue = col5;
				val_cashFlow = col6;
				cve_scenario = &sim.;
				id = &id_asset.;
			run;
		%end;

	/* Bono cupón cero */

	%if &cod_asset. = 2 %then
		%do;
			data work.assets2;
				set work.assets1;
				if num_year lt &num_remainingYears. then
				val_assetValue = &pct_portfolio.*&valTotPort.*(1+&pct_annualYield.)**num_year;
				if num_year = (&num_remainingYears.) then
					val_cashFlow = &pct_portfolio.*&valTotPort.*(1+&pct_annualYield.)**num_year;
				else 
					val_cashFlow = 0;
				
			run;
			
			data work.asset_id_&id_asset._&sim.(keep=cve_scenario id num_year val_assetValue val_cashFlow);
				set work.assets2;
				cve_scenario = &sim.;
				id = &id_asset.;
			run;
		%end;
	
	/* Bono respaldado con hipotecas */

	%if &cod_asset. = 3 %then
		%do;
			proc sql;
				create table work.assets2 as
					select 
						a.*
						, sum(b.val_int,&spreadMort.) as val_curAvaiRateMort
					from work.assets1 a left join work.curve_int b on a.num_year = b.num_year	
					;
			quit;
			
			proc sql noprint;
			/* Regular */
				select val_parametro into: prePymt0
				from ext.parametros
				where id_parameter=6
				;	
			/* Additional */
				select val_parametro into: prePymt1
				from ext.parametros
				where id_parameter=7
				;
				select val_parametro into: prePymt2
				from ext.parametros
				where id_parameter=8
				;				
			quit;
			
			data work.assets3;
				set work.assets2;
				val_extAnPrePymt = min(1,max(0,&prePymt1.*(&pct_annualYield.-val_curAvaiRateMort)/&prePymt2.));
				mnt_outsPrincipalEOY = 0;
				mnt_interestPymt = 0;
				mnt_principalPymt = 0;
				mnt_totalPymt = 0;	
				mnt_prePymt = 0;
				mnt_totalCF = 0;
			run;			
			
			%put pct_portfolio = &pct_portfolio. valTotPort = &valTotPort.;
			
			data work.assets4;
				set work.assets3;
				if num_year=0 then
				do;
					mnt_outsPrincipalEOY = &pct_portfolio.*&valTotPort.;
					val_cashFlow = mnt_outsPrincipalEOY;
					output;
				end;
				else
					output;
			run;
		
			
			%do i=1 %to &num_remainingYears.;			
				data work.aux(where=(num_year=&i.));
					set work.assets4;
					if num_year <= &i. then
						do;
							mnt_interestPymt = lag(mnt_outsPrincipalEOY)*&pct_annualYield.;
							mnt_totalPymt = mort(lag(mnt_outsPrincipalEOY),.,&pct_annualYield.,&num_remainingYears.+1-num_year);
							mnt_principalPymt = sum(mnt_totalPymt,-mnt_interestPymt);
							mnt_prePymt = (val_extAnPrePymt+&prePymt0.)*(lag(mnt_outsPrincipalEOY)-mnt_principalPymt);
							mnt_totalCF = sum(mnt_totalPymt,mnt_prePymt);						 
							mnt_outsPrincipalEOY = sum(sum(lag(mnt_outsPrincipalEOY),-mnt_principalPymt,-mnt_prePymt),&pct_portfolio.*&valTotPort.*(num_year = 0));
							val_assetValue = mnt_outsPrincipalEOY;
							val_cashFlow = mnt_totalCF;
							output;
						end;
				run;
				
				
				data work.assets4;
					update work.assets4 aux;
					by num_year;					
				run;
				
				data work.asset_id_&id_asset._&sim.(keep= cve_scenario id num_year val_assetValue val_cashFlow);
					format num_year 10. val_assetValue val_cashFlow comma16.2;
					set work.assets4;
					cve_scenario = &sim.;
					id = &id_asset.;
					val_assetValue = mnt_outsPrincipalEOY;
					val_cashFlow = mnt_totalCF;
				run;
				
			%end;

			
		
			
		%end;
		
	/* Limpiamos la memoria */
	
	proc datasets lib=work nolist;
		delete assets: aux:;
	run;
	
	

	
%mend;

