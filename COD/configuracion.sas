/*Declaracion de macro variables globales*/

/* SE DEBE CORRER ESTE NODO ANTES QUE CUALQUIER OTRO */

%global root;

* Modifica la siguiente ruta si es necesario;
%let root=C:/Users/jenri/Google Drive/Cosas del trabajo/SAS/SASUniversityEdition/myfolders/aar;

/*************************************************************************************************************************************/
/*****								 Asignacion de librerias									 								******/
/*************************************************************************************************************************************/

libname ext "&root./DAT/extraccion";	
libname aexpl "&root./DAT/staging/aexploratorio";	
libname cact "&root./DAT/staging/cactuarial";	
libname cfin "&root./DAT/staging/cfinancieros";	
libname prft "&root./DAT/staging/profit";	

* Package of methods;

proc ds2;
	package ext.riskEngine / overwrite=yes;
		method radix(double precision r) returns double precision;
			return r;
		end;

		method lives(double precision radix, double precision l_x_lag , double precision q_x) returns double precision;
			dcl double precision l_x;
			if missing(l_x_lag) then l_x = radix;
			else l_x = l_x_lag * (1 - q_x);
			return l_x;
		end; 

		method p_x(double precision q_x) returns double precision;
			dcl double precision p_x;
			p_x = 1 - q_x;
			return p_x;
		end; 

		method e_x(double precision p_x, double precision e_x_fwd) returns double precision;
			dcl double precision e_x;
			if missing(e_x_fwd) then e_x = p_x;
			else e_x = p_x * (1+e_x_fwd);
			return e_x;
		end; 


	endpackage;
run;
quit;







