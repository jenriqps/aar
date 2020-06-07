/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);

%let radix = 1000000;


/*
 * 1 Mortality table (with IML)
 */

* We add the values to the mortality table;
proc iml;
	edit ext.TABLAMORTALIDAD;
	read all var _NUM_ into lt[colname=numVars];
	close ext.TABLAMORTALIDAD; 	

	radix = &radix.;
	n = nrow(lt);
	*print n;
	ltplus=J(n,5);
	*print ltplus;
	do i=1 to n;
		ltplus[i,1]=lt[i,1];
		ltplus[i,2]=lt[i,2];
		ltplus[i,3]=lt[i,2]/1000;
		if i=1 then ltplus[i,4]=radix;
		else ltplus[i,4]=ltplus[i-1,4]*(1-ltplus[i-1,3]);
	end;
	
	do i = n to 1 by -1;
		if i = n then ltplus[i,5] = (1 - ltplus[i,3]);
		else ltplus[i,5] = (1 - ltplus[i,3]) * ( 1 + ltplus[i+1,5]);
	end;
	* print ltplus;
	* We send the results to a data set;
	create work.ltplus from ltplus;
	append from ltplus;
	close work.ltplus;	
	
	
	* Doing everything inside IML procedure;
	submit;
	
		data ext.tablamortalidadv2;
			format 
			col1 comma10. col2 comma10.6 col3 comma10.6 col4 comma10. col5 comma10.1; 
			label
			col1 = "Attained age (years)"
			col2 = "1000 q_x"
			col3 = "q_x"
			col4 = "l_x"
			col5 = "e_x";
			set work.ltplus;	
		run;
		
		
		ods layout gridded columns=2;
		ods region;
		title 'Mortality table';
		proc sgplot data=ext.tablamortalidadv2;
			step x=col1 y=col3 / lineattrs=(color=orange);
			step x=col1 y=col4 / y2axis lineattrs=(color=blue);
			xaxis grid;
			yaxis grid;
		run;
		title;
		ods region;
		title 'Life Expectation';
		proc sgplot data=ext.tablamortalidadv2;
			step x=col1 y=col5 / lineattrs=(color=green);
			xaxis grid;
			yaxis grid;
		run;
		title;
		ods layout end;	
	
	endsubmit;
	
	
quit;



