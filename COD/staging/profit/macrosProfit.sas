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
	
	proc datasets lib=work nolist nodetails;
		delete profits: profitsaux;
	quit;
	
	


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
			if prft[i+1,1]=0 then prft[i+1,2]=.; 
			else prft[i+1,2]=curv[i,2];			
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
			if prft[i+1,5] > 0 then prft[i+1,8]=&annExpenses.; else prft[i+1,8]=0;
			
			* mnt_cbIntDuringYear;
			if prft[i+1,1] > 0 then
				do;
					if prft[i,9] < 0 then 
					prft[i+1,10]=prft[i,9]*sum(prft[i+1,2],&negativeBal.);
					else if prft[i,9] >= 0 then 
					prft[i+1,10]=prft[i,9]*sum(prft[i+1,2],&positiveBal.); 	
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
	
	proc datasets lib=work nolist nodetails;
		delete profits: profitsaux;
	quit;
	
	


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



/*--------------------------------------------------------------------------------------------------
SAS RawToSankey macro created by Shane Rosanbalm of Rho, Inc. 2015
*---------- high-level overview ----------;
-  The Sankey diagram macro requires data in two structures:
   -  The NODES dataset must be one record per bar segment.
   -  The LINKS dataset must be one record per connection between bar segments. 
-  This macro transforms a vertical dataset (i.e., one record per SUBJECT and XVAR) into the 
   Sankey NODES and LINKS structures.
*---------- required parameters ----------;
data=             vertical dataset to be converted to sankey structures
subject=          subject identifier
yvar=             categorical y-axis variable
                  converted to values 1-N for use in plotting
                  
xvar=             categorical x-axis variable
                  converted to values 1-N for use in plotting
*---------- optional parameters ----------;
completecases=    whether or not to require non-missing yvar at all xvar values
                  valid values: yes/no.
                  default: yes.
                  
outlib=           library in which to save NODES and LINKS datasets
                  default is the WORK library
                  
yvarord=          sort order for y-axis conversion, in a comma separated list
                     e.g., yvarord=%quote(red rum, george smith, tree)
                  default sort is equivalent to ORDER=DATA
                  
xvarord=          sort order for x-axis conversion, in a comma separated list
                     e.g., xvarord=%quote(pink plum, fred funk, grass)
                  default sort is equivalent to ORDER=DATA
-------------------------------------------------------------------------------------------------*/



%macro rawtosankey
   (data=
   ,subject=
   ,yvar=
   ,xvar=
   ,completecases=
   ,outlib=work
   ,yvarord=
   ,xvarord=
   );


   %*---------- localization ----------;
   
   %local i;
   
   
   %*---------- return code ----------;
   
   %global rts;
   %let rts = 0;
   

   %*-----------------------------------------------------------------------------------------;
   %*---------- display parameter values at the top (for debugging) ----------;
   %*-----------------------------------------------------------------------------------------;
   
   %put &=data;
   %put &=subject;
   %put &=yvar;
   %put &=xvar;
   %put &=outlib;
   %put &=yvarord;
   %put &=xvarord;
   
   
   
   %*-----------------------------------------------------------------------------------------;
   %*---------- basic parameter checks ----------;
   %*-----------------------------------------------------------------------------------------;
   
   
   %*---------- dataset exists ----------;
   
   %let _dataexist = %sysfunc(exist(&data));
   %if &_dataexist = 0 %then %do;
      %put %str(W)ARNING: RawToSankey -> DATASET [&data] DOES NOT EXIST;
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   
   %*---------- variables exist ----------;
   
   %macro varexist(data,var);
      %let dsid = %sysfunc(open(&data)); 
      %if &dsid %then %do; 
         %let varnum = %sysfunc(varnum(&dsid,&var));
         %if &varnum %then &varnum; 
         %else 0;
         %let rc = %sysfunc(close(&dsid));
      %end;
      %else 0;
   %mend varexist;
   
   %if %varexist(&data,&subject) = 0 %then %do;
      %put %str(W)ARNING: RawToSankey -> VARIABLE [&subject] DOES NOT EXIST;
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %if %varexist(&data,&yvar) = 0 %then %do;
      %put %str(W)ARNING: RawToSankey -> VARIABLE [&yvar] DOES NOT EXIST;
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %if %varexist(&data,&xvar) = 0 %then %do;
      %put %str(W)ARNING: RawToSankey -> VARIABLE [&xvar] DOES NOT EXIST;
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   

   %*---------- eject missing yvar records ----------;
   
   data _nodes00;
      set &data;
      %if &completecases = yes %then %do;
         where not missing(&yvar);
      %end;
   run;
   
   
   %*---------- convert numeric yvar to character (for easier processing) ----------;
   
   %let dsid = %sysfunc(open(&data)); 
   %let varnum = %sysfunc(varnum(&dsid,&yvar));
   %let vartype = %sysfunc(vartype(&dsid,&varnum));
   %if &vartype = N %then %do; 
      data _nodes00;
         set _nodes00 (rename=(&yvar=_&yvar));
         &yvar = compress(put(_&yvar,best.));
         drop _&yvar;
      run;
   %end;
   %let rc = %sysfunc(close(&dsid));
   
   
   %*---------- convert numeric xvar to character (for easier processing) ----------;
   
   %let dsid = %sysfunc(open(&data)); 
   %let varnum = %sysfunc(varnum(&dsid,&xvar));
   %let vartype = %sysfunc(vartype(&dsid,&varnum));
   %if &vartype = N %then %do; 
      data _nodes00;
         set _nodes00 (rename=(&xvar=_&xvar));
         &xvar = compress(put(_&xvar,best.));
         drop _&xvar;
      run;
   %end;
   %let rc = %sysfunc(close(&dsid));
   
   
   %*---------- left justify xvar and yvar values (inelegant solution) ----------;
   
   data _nodes00;
      set _nodes00;
      &yvar = left(&yvar);
      &xvar = left(&xvar);
   run;
   
   
   %*---------- if no yvarord specified, build one using ORDER=DATA model ----------;
   
   proc sql noprint;
      select   distinct &yvar
      into     :yvar1-
      from     _nodes00
      ;
      %global n_yvar;
      %let n_yvar = &sqlobs;
      %put &=n_yvar;
   quit;
      
   %if &yvarord eq %str() %then %do;
   
      proc sql noprint;
         select   max(length(&yvar))
         into     :ml_yvar
         from     _nodes00
         ;
         %put &=ml_yvar;
      quit;
   
      data _null_;
         set _nodes00 (keep=&yvar) end=eof;
         array ordered {&n_yvar} $&ml_yvar;
         retain filled ordered1-ordered&n_yvar;
      
         *--- first record seeds array ---;
         if _N_ = 1 then do;
            filled = 1;
            ordered[filled] = &yvar;
         end;
      
         *--- if subsequent records not yet in array, add them ---;
         else do;
            hit = 0;
            do i = 1 to &n_yvar;
               if ordered[i] = &yvar then hit = 1;
            end;
            if hit = 0 then do;
               filled + 1;
               ordered[filled] = &yvar;
            end;
         end;
      
         *--- concatenate array elements into one variable ---;
         if eof then do;
            yvarord = catx(', ',of ordered1-ordered&n_yvar);
            call symputx('yvarord',yvarord);
         end;
      run;
      
   %end;

   %put &=yvarord;


   %*---------- if no xvarord specified, build one using ORDER=DATA model ----------;
   
   proc sql noprint;
      select   distinct &xvar
      into     :xvar1-
      from     _nodes00
      ;
      %global n_xvar;
      %let n_xvar = &sqlobs;
      %put &=n_xvar;
   quit;
      
   %if &xvarord eq %str() %then %do;
   
      proc sql noprint;
         select   max(length(&xvar))
         into     :ml_xvar
         from     _nodes00
         ;
         %put &=ml_xvar;
      quit;
   
      data _null_;
         set _nodes00 (keep=&xvar) end=eof;
         array ordered {&n_xvar} $&ml_xvar;
         retain filled ordered1-ordered&n_xvar;
      
         *--- first record seeds array ---;
         if _N_ = 1 then do;
            filled = 1;
            ordered[filled] = &xvar;
         end;
      
         *--- if subsequent records not yet in array, add them ---;
         else do;
            hit = 0;
            do i = 1 to &n_xvar;
               if ordered[i] = &xvar then hit = 1;
            end;
            if hit = 0 then do;
               filled + 1;
               ordered[filled] = &xvar;
            end;
         end;
      
         *--- concatenate array elements into one variable ---;
         if eof then do;
            xvarord = catx(', ',of ordered1-ordered&n_xvar);
            call symputx('xvarord',xvarord);
         end;
      run;
      
   %end;

   %put &=xvarord;


   %*---------- parse yvarord ----------;
   
   %let commas = %sysfunc(count(%bquote(&yvarord),%bquote(,)));
   %let n_yvarord = %eval(&commas + 1);
   %put &=commas &=n_yvarord;
   
   %do i = 1 %to &n_yvarord;
      %global yvarord&i;      
      %let yvarord&i = %scan(%bquote(&yvarord),&i,%bquote(,));
      %put yvarord&i = [&&yvarord&i];      
   %end;
   
   
   %*---------- parse xvarord ----------;
   
   %let commas = %sysfunc(count(%bquote(&xvarord),%bquote(,)));
   %let n_xvarord = %eval(&commas + 1);
   %put &=commas &=n_xvarord;
   
   %do i = 1 %to &n_xvarord;      
      %global xvarord&i;
      %let xvarord&i = %scan(%bquote(&xvarord),&i,%bquote(,));
      %put xvarord&i = [&&xvarord&i];      
   %end;
      
   
   %*-----------------------------------------------------------------------------------------;
   %*---------- yvarord vs. yvar ----------;
   %*-----------------------------------------------------------------------------------------;
   
   
   %*---------- same number of values ----------;

   %if &n_yvarord ne &n_yvar %then %do;
      %put %str(W)ARNING: RawToSankey -> NUMBER OF yvarord= VALUES [&n_yvarord];
      %put %str(W)ARNING: RawToSankey -> DOES NOT MATCH NUMBER OF yvar= VALUES [&n_yvar];
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %*---------- put yvarord and yvar into quoted lists ----------;
   
   proc sql noprint;
      select   distinct quote(trim(left(&yvar)))
      into     :_yvarlist
      separated by ' '
      from     _nodes00
      ;
   quit;
   
   %put &=_yvarlist;
   
   data _null_;
      length _yvarordlist $2000;
      %do i = 1 %to &n_yvarord;
         _yvarordlist = trim(_yvarordlist) || ' ' || quote("&&yvarord&i");
      %end;
      call symputx('_yvarordlist',_yvarordlist);
   run;
   
   %put &=_yvarordlist;
   
   %*---------- check lists in both directions ----------;
   
   data _null_;
      array yvarord (&n_yvarord) $200 (&_yvarordlist);
      array yvar (&n_yvar) $200 (&_yvarlist);
      call symputx('_badyvar',0);
      %do i = 1 %to &n_yvarord;
         if "&&yvarord&i" not in (&_yvarlist) then call symputx('_badyvar',1);
      %end;
      %do i = 1 %to &n_yvar;
         if "&&yvar&i" not in (&_yvarordlist) then call symputx('_badyvar',2);
      %end;
   run;
   
   %if &_badyvar eq 1 %then %do;
      %put %str(W)ARNING: RawToSankey -> VALUE WAS FOUND IN yvarord= [&_yvarordlist];
      %put %str(W)ARNING: RawToSankey -> THAT IS NOT IN yvar= [&_yvarlist];
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %if &_badyvar eq 2 %then %do;
      %put %str(W)ARNING: RawToSankey -> VALUE WAS FOUND IN yvar= [&_yvarlist];
      %put %str(W)ARNING: RawToSankey -> THAT IS NOT IN yvarord= [&_yvarordlist];
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
      

   %*-----------------------------------------------------------------------------------------;
   %*---------- xvarord vs. xvar ----------;
   %*-----------------------------------------------------------------------------------------;
   
   
   %*---------- same number of values ----------;
   
   %if &n_xvarord ne &n_xvar %then %do;
      %put %str(W)ARNING: RawToSankey -> NUMBER OF xvarord= VALUES [&n_xvarord];
      %put %str(W)ARNING: RawToSankey -> DOES NOT MATCH NUMBER OF xvar= VALUES [&n_xvar];
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %*---------- put xvarord and xvar into quoted lists ----------;
   
   proc sql noprint;
      select   distinct quote(trim(left(&xvar)))
      into     :_xvarlist
      separated by ' '
      from     _nodes00
      ;
   quit;
   
   %put &=_xvarlist;
   
   data _null_;
      length _xvarordlist $2000;
      %do i = 1 %to &n_xvarord;
         _xvarordlist = trim(_xvarordlist) || ' ' || quote("&&xvarord&i");
      %end;
      call symputx('_xvarordlist',_xvarordlist);
   run;
   
   %put &=_xvarordlist;
   
   %*---------- check lists in both directions ----------;
   
   data _null_;
      array xvarord (&n_xvarord) $200 (&_xvarordlist);
      array xvar (&n_xvar) $200 (&_xvarlist);
      call symputx('_badxvar',0);
      %do i = 1 %to &n_xvarord;
         if "&&xvarord&i" not in (&_xvarlist) then call symputx('_badxvar',1);
      %end;
      %do i = 1 %to &n_xvar;
         if "&&xvar&i" not in (&_xvarordlist) then call symputx('_badxvar',2);
      %end;
   run;
   
   %if &_badxvar eq 1 %then %do;
      %put %str(W)ARNING: RawToSankey -> VALUE WAS FOUND IN xvarord= [&_xvarordlist];
      %put %str(W)ARNING: RawToSankey -> THAT IS NOT IN xvar= [&_xvarlist];
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %if &_badxvar eq 2 %then %do;
      %put %str(W)ARNING: RawToSankey -> VALUE WAS FOUND IN xvar= [&_xvarlist];
      %put %str(W)ARNING: RawToSankey -> THAT IS NOT IN xvarord= [&_xvarordlist];
      %put %str(W)ARNING: RawToSankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
      

   %*-----------------------------------------------------------------------------------------;
   %*---------- enumeration ----------;
   %*-----------------------------------------------------------------------------------------;


   %*---------- enumerate yvar values ----------;
   
   proc sort data=_nodes00 out=_nodes05;
      by &yvar;
   run;
   
   data _nodes10;
      set _nodes05;
      by &yvar;
      %do i = 1 %to &n_yvarord;
         if &yvar = "&&yvarord&i" then y = &i;
      %end;
   run;
   
   %*---------- enumerate xvar values ----------;
   
   proc sort data=_nodes10 out=_nodes15;
      by &xvar;
   run;   
   
   data _nodes20;
      set _nodes15;
      by &xvar;
      %do i = 1 %to &n_xvarord;
         if &xvar = "&&xvarord&i" then x = &i;
      %end;
   run;
   
   %*---------- subset if doing complete cases ----------;
   
   proc sql noprint;
      select   max(x)
      into     :xmax
      from     _nodes20
      ;
      %put &=xmax;
   quit;
   
   proc sql;
      create table _nodes30 as
      select   *
      from     _nodes20
      %if &completecases eq yes %then 
         group by &subject
         having   count(*) eq &xmax
         ;
      ;
   quit;

   %*---------- count subjects in case not doing complete cases ----------;

   %global subject_n;
   
   proc sql noprint;
      select   count(distinct &subject)
      into     :subject_n
      %if &completecases eq yes %then
         from     _nodes30
         ;
      %if &completecases eq no %then
         from     _nodes10
         ;      
      ;
      %put &=subject_n;
   quit;
   
   
   %*-----------------------------------------------------------------------------------------;
   %*---------- transform raw data to nodes structure ----------;
   %*-----------------------------------------------------------------------------------------;


   proc sql;
      create table _nodes40 as
      select   x, y, count(*) as size
      from     _nodes30
      group by x, y
      ;
   quit;
   
   data &outlib..nodes;
      set _nodes40;
      length xc yc $200;
      %do i = 1 %to &n_xvarord;
         if x = &i then xc = "&&xvarord&i";
      %end;
      %do i = 1 %to &n_yvarord;
         if y = &i then yc = "&&yvarord&i";
      %end;
   run;

   
   %*-----------------------------------------------------------------------------------------;
   %*---------- transform raw data to links structure ----------;
   %*-----------------------------------------------------------------------------------------;


   proc sort data=_nodes30 out=_links00;
      by &subject x;
   run;
   
   data _links10;
      set _links00;
      by &subject x;
      retain lastx lasty;
      if first.&subject then call missing(lastx,lasty);
      else if lastx + 1 eq x then do;
         x1 = lastx;
         y1 = lasty;
         x2 = x;
         y2 = y;
         output;
      end;
      lastx = x;
      lasty = y;
   run;

   proc sql noprint;
      create table &outlib..links as
      select   x1, y1, x2, y2, count(*) as thickness
      from     _links10
      group by x1, y1, x2, y2
      ;
   quit;
   
   
   %*--------------------------------------------------------------------------------;
   %*---------- clean up ----------;
   %*--------------------------------------------------------------------------------;
   
   
   %if &debug eq no %then %do;
   
      proc datasets library=work nolist;
         delete _nodes: _links:;
      run; quit;
   
   %end;
   
   
   %*---------- return code ----------;
   
   %let rts = 1;
   


%mend rawtosankey;


/*--------------------------------------------------------------------------------------------------

SAS Sankey macro created by Shane Rosanbalm of Rho, Inc. 2015

*---------- high-level overview ----------;

-  This macro creates a stacked bar chart with sankey-like links between the stacked bars. 
   It is intended to display the change over time in subject endpoint values.
   These changes are depicted by bands flowing from left to right between the stacked bars. 
   The thickness of each band corresponds to the number of subjects moving from the left to 
   the right.
-  The macro assumes two input datasets exist: NODES and LINKS.
   -  Use the macro %RawToSankey to help build NODES and LINKS from a vertical dataset.
   -  The NODES dataset must be one record per bar segment, with variables:
      -  X and Y (the time and response), 
      -  XC and YC (the character versions of X and Y),
      -  SIZE (the number of subjects represented by the bar segment).
      -  The values of X and Y should be integers starting at 1.
      -  Again, %RawToSankey will build this dataset for you.
   -  The LINKS dataset must be one record per link, with variables:
      -  X1 and Y1 (the time and response to the left), 
      -  X2 and Y2 (the time and response to the right), 
      -  THICKNESS (the number of subjects represented by the band). 
      -  The values of X1, Y1, X2, and Y2 should be integers starting at 1.
      -  Again, %RawToSankey will build this dataset for you.
-  The chart is produced using SGPLOT. 
   -  The procedure contains one HIGHLOW statement per node (i.e., per bar segment).
   -  The procedure contains one BAND statement per link (i.e., per connecting band).
   -  The large volume of HIGHLOW and BAND statements is necessary to get color consistency in 
      v9.3 (in v9.4 we perhaps could have used attribute maps to clean things up a bit).
-  Any ODS GRAPHICS adjustments (e.g., HEIGHT=, WIDTH=, IMAGEFMT=, etc.) should be made prior to 
   calling the macro.
-  Any fine tuning of axes or other appearance options will need to be done in (a copy of) the 
   macro itself.

*---------- required parameters ----------;

There are no required parameters for this macro.

*---------- optional parameters ----------;

sankeylib=        Library where NODES and LINKS datasets live.
                  Default: WORK
                  
colorlist=        A space-separated list of colors: one color per response group.
                  Not compatible with color descriptions (e.g., very bright green).
                  Default: the qualitative Brewer palette.

barwidth=         Width of bars.
                  Values must be in the 0-1 range.
                  Default: 0.25.
                  
yfmt=             Format for yvar/legend.
                  Default: values of yvar variable in original dataset.

xfmt=             Format for x-axis/time.
                  Default: values of xvar variable in original dataset.

legendtitle=      Text to use for legend title.
                     e.g., legendtitle=%quote(Response Value)

interpol=         Method of interpolating between bars.
                  Valid values are: cosine, linear.
                  Default: cosine.

stat=             Show percents or frequencies on y-axis.
                  Valid values: percent/freq.
                  Default: percent.
                  
datalabel=        Show percents or frequencies inside each bar.
                  Valid values: yes/no.
                  Default: yes.
                  Interaction: will display percents or frequences per stat=.
                  
*---------- depricated parameters ----------;

percents=         Show percents inside each bar.
                  This has been replaced by datalabel=. 

-------------------------------------------------------------------------------------------------*/



%macro sankey
   (sankeylib=work
   ,colorlist=
   ,barwidth=0.25
   ,yfmt=
   ,xfmt=
   ,legendtitle=
   ,interpol=cosine
   ,stat=percent
   ,datalabel=yes
   ,percents=
   );



   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   %*---------- some preliminaries ----------;
   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;



   %*---------- localization ----------;
   
   %local i j;
   
   %*---------- deal with percents= parameter ----------;
   
   %if &percents ne %then %do;
      %put %str(W)ARNING: Sankey -> PARAMETER percents= HAS BEEN DEPRICATED.;
      %put %str(W)ARNING: Sankey -> PLEASE SWITCH TO PARAMETER datalabel=.;
      %put %str(W)ARNING: Sankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %*---------- dataset exists ----------;
   
   %let _dataexist = %sysfunc(exist(&sankeylib..nodes));
   %if &_dataexist = 0 %then %do;
      %put %str(W)ARNING: Sankey -> DATASET [&sankeylib..nodes] DOES NOT EXIST.;
      %put %str(W)ARNING: Sankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   data nodes;
      set &sankeylib..nodes;
   run;
   
   %let _dataexist = %sysfunc(exist(&sankeylib..links));
   %if &_dataexist = 0 %then %do;
      %put %str(W)ARNING: Sankey -> DATASET [&sankeylib..links] DOES NOT EXIST.;
      %put %str(W)ARNING: Sankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   data links;
      set &sankeylib..links;
   run;
   
   %*---------- variables exist ----------;
   
   %macro varexist(data,var);
      %let dsid = %sysfunc(open(&data)); 
      %if &dsid %then %do; 
         %let varnum = %sysfunc(varnum(&dsid,&var));
         %if &varnum %then &varnum; 
         %else 0;
         %let rc = %sysfunc(close(&dsid));
      %end;
      %else 0;
   %mend varexist;
   
   %if %varexist(nodes,x) = 0 or %varexist(nodes,y) = 0 or %varexist(nodes,size) = 0 %then %do;
      %put %str(W)ARNING: Sankey -> DATASET [work.nodes] MUST HAVE VARIABLES [x y size].;
      %put %str(W)ARNING: Sankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %if %varexist(links,x1) = 0 or %varexist(links,y1) = 0 or %varexist(links,x2) = 0 
         or %varexist(links,y2) = 0 or %varexist(links,thickness) = 0 %then %do;
      %put %str(W)ARNING: Sankey -> DATASET [work.links] MUST HAVE VARIABLES [x1 y1 x2 y2 thickness].;
      %put %str(W)ARNING: Sankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   
   %*---------- preliminary sorts (and implicit dataset/variable checking) ----------;
   
   proc sort data=nodes;
      by y x size;
   run;

   proc sort data=links;
      by x1 y1 x2 y2 thickness;
   run;
   
   %*---------- break apart colors ----------;

   %if &colorlist eq %str() 
      %then %let colorlist = cxa6cee3 cx1f78b4 cxb2df8a cx33a02c cxfb9a99 cxe31a1c 
                             cxfdbf6f cxff7f00 cxcab2d6 cx6a3d9a cxffff99 cxb15928;
   %let n_colors = %sysfunc(countw(&colorlist));
   %do i = 1 %to &n_colors;
      %let color&i = %scan(&colorlist,&i,%str( ));
      %put color&i = [&&color&i];
   %end;
   
   %*---------- xfmt ----------;
   
   %if &xfmt eq %str() %then %do;
   
      %let xfmt = xfmt.;
      
      proc format;
         value xfmt
         %do i = 1 %to &n_xvar;
            &i = "&&xvarord&i"
         %end;
         ;
      run;
      
   %end;
   
   %put &=xfmt;
   
   %*---------- number of rows ----------;

   proc sql noprint;
      select   max(y)
      into     :maxy
      from     nodes
      ;
   quit;
   
   %*---------- number of time points ----------;

   proc sql noprint;
      select   max(x)
      into     :maxx
      from     nodes
      ;
   quit;
   
   %*---------- corresponding text ----------;
   
   proc sql noprint;
      select   distinct y, yc
      into     :dummy1-, :yvarord1-
      from     nodes
      ;
   quit;
   
   %do i = 1 %to &sqlobs;
      %put yvarord&i = [&&yvarord&i];
   %end;
   
   %*---------- validate interpol ----------;
   
   %let _badinterpol = 0;
   data _null_;
      if      upcase("&interpol") = 'LINEAR' then call symput('interpol','linear');
      else if upcase("&interpol") = 'COSINE' then call symput('interpol','cosine');
      else call symput('_badinterpol','1');
   run;
   
   %if &_badinterpol eq 1 %then %do;
      %put %str(W)ARNING: Sankey -> THE VALUE INTERPOL= [&interpol] IS INVALID.;
      %put %str(W)ARNING: Sankey -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;
   


   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   %*---------- convert counts to percents for nodes ----------;
   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   
   
   
   ods select none;
   ods output crosstabfreqs=_ctfhl (where=(_type_='11'));
   proc freq data=nodes;
      table x*y;
      weight size;
   run;
   ods select all;
   
   data _highlow;
      set _ctfhl;
      by x;
      node = _N_;
      retain cumpercent;
      if first.x then cumpercent = 0;
      lowpercent = cumpercent;
      highpercent = cumpercent + 100*frequency/&subject_n;
      cumpercent = highpercent;   
      retain cumcount;
      if first.x then cumcount = 0;
      lowcount = cumcount;
      highcount = cumcount + frequency;
      cumcount = highcount;   
      keep x y node lowpercent highpercent lowcount highcount;   
   run;
   
   proc sql noprint;
      select   max(node)
      into     :maxhighlow
      from     _highlow
      ;
   quit;



   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   %*---------- write a bunch of highlow statements ----------;
   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;



   data _highlow_statements;
      set _highlow;
      by x;
      length highlow $200 color $20 legendlabel $40 scatter $200;

      %*---------- choose color based on y ----------;
      %do c = 1 %to &maxy;
         if y = &c then color = "&&color&c";
      %end;

      %*---------- create node specific x, low, high variables and write highlow statement ----------;
      %do j = 1 %to &maxhighlow;
         %let jc = %sysfunc(putn(&j,z%length(&maxhighlow).));
         %let jro = %sysfunc(mod(&j,&maxy));
         %if &jro = 0 %then %let jro = &maxy;
         if node = &j then do;
            xb&jc = x;
            lowb&jc = lowpercent;
            %if &stat eq freq %then
               lowb&jc = lowb&jc*&subject_n/100;;
            highb&jc = highpercent;
            %if &stat eq freq %then
               highb&jc = highb&jc*&subject_n/100;;
            %if &yfmt eq %then 
               legendlabel = "&&yvarord&jro" ;
            %else %if &yfmt ne %then
               legendlabel = put(y,&yfmt.) ;
            ;
            highlow = "highlow x=xb&jc low=lowb&jc high=highb&jc / type=bar barwidth=&barwidth" ||
               " fillattrs=(color=" || trim(color) || ")" ||
               " lineattrs=(color=black pattern=solid)" ||
               " name='" || trim(color) || "' legendlabel='" || trim(legendlabel) || "';";
            *--- sneaking in a scatter statement for percent annotation purposes ---;
            mean = mean(lowpercent,highpercent);
            %if &stat eq freq %then
               mean = mean(lowcount,highcount);;
            percent = highpercent - lowpercent;
            %if &stat eq freq %then
               percent = highcount - lowcount;;
            if percent >= 1 then do;
               meanb&jc = mean;
               textb&jc = compress(put(percent,3.)) || '%';
               %if &stat eq freq %then
                  textb&jc = compress(put(percent,3.));;
               scatter = "scatter x=xb&jc y=meanb&jc / x2axis markerchar=textb&jc;";
            end;
         end;
      %end;

   run;

   proc sql noprint;
      select   distinct trim(highlow)
      into     :highlow
      separated by ' '
      from     _highlow_statements
      where    highlow is not missing
      ;
   quit;

   %put highlow = [%nrbquote(&highlow)];

   proc sql noprint;
      select   distinct trim(scatter)
      into     :scatter
      separated by ' '
      from     _highlow_statements
      where    scatter is not missing
      ;
   quit;

   %put scatter = [%nrbquote(&scatter)];
   
   
   %*---------- calculate offset based on bar width and maxx ----------;
   
   data _null_;
      if &maxx = 2 then offset = 0.25;
      else if &maxx = 3 then offset = 0.15;
      else offset = 0.05 + 0.03*((&barwidth/0.25)-1);
      call symputx ('offset',offset);
   run;   



   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   %*---------- convert counts to percents for links ----------;
   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;



   %*---------- left edge of each band ----------;
   
   proc sql;
      create   table _links1 as
      select   a.*, b.highcount as cumthickness 
      from     links as a
               inner join _highlow (where=(highcount~=lowcount)) as b
               on a.x1 = b.x 
                  and a.y1 = b.y
      order by x1, y1, x2, y2
      ;
   quit;
   
   data _links2;
      set _links1;
      by x1 y1 x2 y2;
      link = _N_;
      xt1 = x1;
      retain lastybhigh1;
      if first.x1 then 
         lastybhigh1 = 0;
      yblow1 = lastybhigh1;
      ybhigh1 = lastybhigh1 + thickness/&subject_n;
      lastybhigh1 = ybhigh1;
      if last.y1 then
         lastybhigh1 = cumthickness/&subject_n;
   run;
   
   %*---------- right edge of each band ----------;
   
   proc sql;
      create   table _links3 as
      select   a.*, b.highcount as cumthickness 
      from     links as a
               inner join _highlow (where=(highcount~=lowcount)) as b
               on a.x2 = b.x 
                  and a.y2 = b.y
      order by x2, y2, x1, y1
      ;
   quit;
   
   data _links4;
      set _links3;
      by x2 y2 x1 y1;
      retain lastybhigh2;
      if first.x2 then 
         lastybhigh2 = 0;
      xt2 = x2;
      yblow2 = lastybhigh2;
      ybhigh2 = lastybhigh2 + thickness/&subject_n;
      lastybhigh2 = ybhigh2;
      if last.y2 then
         lastybhigh2 = cumthickness/&subject_n;
   run;
   
   %*---------- make vertical ----------;
   
   proc sort data=_links2 out=_links2b;
      by x1 y1 x2 y2;
   run;
   
   proc sort data=_links4 out=_links4b;
      by x1 y1 x2 y2;
   run;
   
   data _links5;
      merge
         _links2b (keep=x1 y1 x2 y2 xt1 yblow1 ybhigh1 link)
         _links4b (keep=x1 y1 x2 y2 xt2 yblow2 ybhigh2)
         ;
      by x1 y1 x2 y2;
   run;
   
   data _links6;
      set _links5;
      
      xt1alt = xt1 + &barwidth*0.48;
      xt2alt = xt2 - &barwidth*0.48;
      
      %if &interpol eq linear %then %do;
      
         do xt = xt1alt to xt2alt by 0.01;
            *--- low ---;
            mlow = (yblow2 - yblow1) / (xt2alt - xt1alt);
            blow = yblow1 - mlow*xt1alt;
            yblow = mlow*xt + blow;
            *--- high ---;
            mhigh = (ybhigh2 - ybhigh1) / (xt2alt - xt1alt);
            bhigh = ybhigh1 - mhigh*xt1alt;
            ybhigh = mhigh*xt + bhigh;
            output;
         end;
         
      %end;

      %if &interpol eq cosine %then %do;
      
         do xt = xt1alt to xt2alt by 0.01;
            b = constant('pi')/(xt2alt-xt1alt);
            c = xt1alt;
            *--- low ---;
            alow = (yblow1 - yblow2) / 2;
            dlow = yblow1 - ( (yblow1 - yblow2) / 2 );
            yblow = alow * cos( b*(xt-c) ) + dlow;
            *--- high ---;
            ahigh = (ybhigh1 - ybhigh2) / 2;
            dhigh = ybhigh1 - ( (ybhigh1 - ybhigh2) / 2 );
            ybhigh = ahigh * cos( b*(xt-c) ) + dhigh;
            output;
         end;
         
      %end;
      
      keep xt yblow ybhigh link y1;
   run;
   
   proc sort data=_links6;
      by link xt;
   run;
   
   %*---------- number of links ----------;

   proc sql noprint;
      select   max(link)
      into     :maxband
      from     _links6
      ;
   quit;
   
   %*---------- write the statements ----------;
   
   data _band_statements;
      set _links6;
      by link xt;
      length band $200 color $20;

      %*---------- choose color based on y1 ----------;
      %do c = 1 %to &maxy;
         if y1 = &c then color = "&&color&c";
      %end;

      %*---------- create link specific x, y variables and write series statements ----------;
      %do j = 1 %to &maxband;
         %let jc = %sysfunc(putn(&j,z%length(&maxband).));
         if link = &j then do;
            xt&jc = xt;
            yblow&jc = 100*yblow;
            %if &stat eq freq %then
               yblow&jc = yblow&jc*&subject_n/100;;
            ybhigh&jc = 100*ybhigh;
            %if &stat eq freq %then
               ybhigh&jc = ybhigh&jc*&subject_n/100;;
            band = "band x=xt&jc lower=yblow&jc upper=ybhigh&jc / x2axis transparency=0.5" || 
               " fill fillattrs=(color=" || trim(color) || ")" ||
               " ;";
         end;
      %end;

   run;

   proc sql noprint;
      select   distinct trim(band)
      into     :band
      separated by ' '
      from     _band_statements
      where    band is not missing
      ;
   quit;

   %put band = [%nrbquote(&band)];
   
                     
   
   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   %*---------- plot it ----------;
   %*----------------------------------------------------------------------------------------------;
   %*----------------------------------------------------------------------------------------------;
   
   
   
   data _all;
      set _highlow_statements _band_statements;
   run;
   
   proc sgplot data=_all noautolegend;
      %*---------- plotting statements ----------;
      &band;
      &highlow;
      %if &datalabel eq yes %then &scatter;;
      %*---------- axis and legend statements ----------;
      x2axis display=(nolabel noticks) min=1 max=&maxx integer offsetmin=&offset offsetmax=&offset 
         tickvalueformat=&xfmt;
      xaxis display=none type=discrete offsetmin=&offset offsetmax=&offset 
         tickvalueformat=&xfmt;
      yaxis offsetmin=0.02 offsetmax=0.02 grid 
         %if &stat eq freq %then label="Frequency";
         %else label="Percent";
         ;
      keylegend %do i = 1 %to &maxy; "&&color&i" %end; / title="&legendtitle";
   run;
   

   %*--------------------------------------------------------------------------------;
   %*---------- clean up ----------;
   %*--------------------------------------------------------------------------------;
   
   
   %if &debug eq no %then %do;
   
      proc datasets library=work nolist nodetails;
         delete _nodes: _links: _all: _band: _highlow: _ctfhl _denom:;
      run; quit;
   
   %end;
   


%mend sankey;


/*--------------------------------------------------------------------------------------------------

SAS Sankey macro created by Shane Rosanbalm of Rho, Inc. 2015

*---------- high-level overview ----------;

-  This macro creates a stacked bar chart with Sankey-like links between the stacked bars. 
   The graphic is intended to display the change over time in categorical subject endpoint 
   values. These changes are depicted by bands flowing from left to right between the stacked 
   bars. The thickness of each band corresponds to the number of subjects moving from the left 
   to the right.
-  This macro is actually just a wrapper macro that contains two smaller macros. 
   -  The first inner macro, %RawToSankey, performs a data transformation. Assuming an input  
      dataset that is vertical (i.e., one record per subject and visit), the macro 
      generates two sets of counts:
      (a)   The number of subjects at each endpoint*visit combination (aka, NODES).
            E.g., how many subjects had endpoint=1 at visit=3?
      (b)   The number of subjects transitioning between endpoint categories at adjacent 
            visits (aka LINKS).
            E.g., how many subjects had endpoint=1 at visit=3 and endpoint=3 at visit=4?
      -  By default the endpoint and visit values are sorted using the ORDER=DATA principle.
         The optional parameter yvarord= and xvarord= can be used to change the display order.
   -  The second inner macro, %Sankey, uses SGPLOT to generate the bar chart (using the NODES 
      dataset) and the Sankey-like connectors (using the LINKS dataset).
      -  Any ODS GRAPHICS adjustments (e.g., HEIGHT=, WIDTH=, IMAGEFMT=, etc.) should be made 
         prior to calling the macro.
      -  There are a few optional parameters for changing the appearance of the graph (colors, 
         bar width, x-axis format, etc.), but it is likely that most seasoned graphers will want 
         to further customize the resulting figure. In that case, it is probably best to simply 
         make a copy of the %Sankey macro and edit away.

*---------- required parameters ----------;

data=             Vertical dataset to be converted to sankey structures

subject=          Subject identifier

yvar=             Categorical y-axis variable
                  Converted to values 1-N for use in plotting
                  
xvar=             Categorical x-axis variable
                  Converted to values 1-N for use in plotting

*---------- optional parameters ----------;

completecases=    Whether or not to require non-missing yvar at all xvar values for a subject
                  Valid values: yes/no.
                  Default: yes.
                  
yvarord=          Sort order for y-axis conversion, in a comma separated list
                     e.g., yvarord=%quote(red rum, george smith, tree)
                  Default sort is equivalent to ORDER=DATA
                  
xvarord=          Sort order for x-axis conversion, in a comma separated list
                     e.g., xvarord=%quote(pink plum, fred funk, grass)
                  Default sort is equivalent to ORDER=DATA

colorlist=        A space-separated list of colors: one color per yvar group.
                  Not compatible with color descriptions (e.g., very bright green).
                  Default: the qualititive Brewer palette.

barwidth=         Width of bars.
                  Values must be in the 0-1 range.
                  Default: 0.25.
                  
yfmt=             Format for yvar/legend.
                  Default: values of yvar variable in original dataset.
                  Gotcha: user-defined formats must utilize converted yvar values 1-N.

xfmt=             Format for x-axis/time.
                  Default: values of xvar variable in original dataset.
                  Gotcha: user-defined formats must utilize converted xvar values 1-N.

legendtitle=      Text to use for legend title.
                     e.g., legendtitle=%quote(Response Value)

interpol=         Method of interpolating between bars.
                  Valid values are: cosine, linear.
                  Default: cosine.

stat=             Show percents or frequencies on y-axis.
                  Valid values: percent/freq.
                  Default: percent.
                  
datalabel=        Show percents or frequencies inside each bar.
                  Valid values: yes/no.
                  Default: yes.
                  Interaction: will display percents or frequences per stat=.
                  
debug=            Keep work datasets.
                  Valid values: yes/no.
                  Default: no.                  
                  
*---------- depricated parameters ----------;

percents=         Show percents inside each bar.
                  This has been replaced by datalabel=. 

-------------------------------------------------------------------------------------------------*/


%macro sankeybarchart
   (data=
   ,subject=
   ,yvar=
   ,xvar=
   ,completecases=yes
   ,yvarord=
   ,xvarord=
   ,colorlist=
   ,barwidth=0.25
   ,yfmt=
   ,xfmt=
   ,legendtitle=
   ,interpol=cosine
   ,stat=percent
   ,datalabel=yes
   ,debug=no
   ,percents=
   );
   

   %*---------- first inner macro ----------;

   %if &data eq %str() or &subject eq %str() or &yvar eq %str() or &xvar eq %str() %then %do;
      %put %str(W)ARNING: SankeyBarChart -> AT LEAST ONE REQUIRED PARAMETER IS MISSING.;
      %put %str(W)ARNING: SankeyBarChart -> THE MACRO WILL STOP EXECUTING.;
      %return;
   %end;

   %rawtosankey
      (data=&data
      ,subject=&subject
      ,yvar=&yvar
      ,xvar=&xvar
      %if &completecases ne %then 
         ,completecases=&completecases;
      %if &yvarord ne %then 
         ,yvarord=&yvarord;
      %if &xvarord ne %then 
         ,xvarord=&xvarord;
      );


   %*---------- second inner macro ----------;

   %if &rts = 1 %then %do;
   
      %sankey
         (barwidth=&barwidth
         ,interpol=&interpol
         ,stat=&stat
         ,datalabel=&datalabel
         %if &colorlist ne %then 
            ,colorlist=&colorlist;
         %if &yfmt ne %then 
            ,yfmt=&yfmt;
         %if &xfmt ne %then 
            ,xfmt=&xfmt;
         %if &legendtitle ne %then 
            ,legendtitle=&legendtitle;
         %if &percents ne %then 
            ,percents=&percents;
         );
      
   %end;

%mend;

































