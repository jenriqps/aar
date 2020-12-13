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
 * 2 Mortality table (same results as the previous ones but with DS2 procedure)
 */

* Package of methods;
proc ds2;
	package ext.riskEngine / overwrite=yes;

		method p_x(double precision q_x) returns double precision;
			dcl double precision p_x;
			p_x = 1 - q_x;
			return p_x;
		end; 

	endpackage;
run;
quit;


proc ds2;
	data work.tablamortalidadv3(overwrite=yes);
		* We declare the variables;
		dcl double precision l_x having format comma10. label 'Lives (l_x)';
		dcl double precision p_x having format comma10.6 label 'Probability of living (p_x)';
		dcl double precision q_x having format comma10.6 label 'Probability of death (q_x)';
		dcl double precision n_p_x0 having format comma10.6 label 'Cumulative Probability of living (at age x0)';
		retain n_p_x0;
		dcl package ext.riskEngine risk();

		* We initialize the values;	
		method init();
			n_p_x0 = 1;
		end;
		
		* We calculate the values;
		method run();	
			set ext.tablamortalidad(locktable=share);
			l_x = &radix. * n_p_x0;
			p_x = risk.p_x(val_1000qx/1000);
			q_x = 1 - p_x;
			n_p_x0 = n_p_x0 * p_x;
			output;
		end;
	enddata;
run;
quit;

proc sort data=work.tablamortalidadv3;
	by descending val_age;
run;

proc ds2;
	data ext.tablamortalidadv2_2(overwrite=yes);
		* We declare the variables;
		dcl double precision e_x having format comma10.2 label 'Life expectation (e_x)';
		dcl double precision e_x_fwd;
		retain e_x_fwd;
		dcl package ext.riskEngine risk();
		* We initialize the values;	
		method init();
			e_x_fwd = 0;
		end;

		* We calculate the values;	
		method run();
			set work.tablamortalidadv3(locktable=share);
			
			e_x_fwd = p_x * (1 + e_x_fwd);
			e_x = e_x_fwd;
			output;
		end;
	enddata;
run;
quit;

title 'Mortality table';
proc sgplot data=ext.tablamortalidadv2_2;
	step x=val_age y=q_x / lineattrs=(color=orange);
	step x=val_age y=l_x / y2axis lineattrs=(color=blue);
	xaxis grid;
	yaxis grid;
run;
title;

title 'Life Expectation';
proc sgplot data=ext.tablamortalidadv2_2;
	step x=val_age y=e_x / lineattrs=(color=green);
	xaxis grid;
	yaxis grid;
run;
title;


