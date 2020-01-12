/**********************************************************************
 * Notas de Administración Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/

options mprint mlogic minoperator fullstimer;

%global root;
%let root=/folders/myfolders/aar;

%include "&root./COD/staging/cfinancieros/macrosCFinancieros.sas";
%include "&root./COD/configuracion.sas";

/* 3 We join all the valuations in one table at maximum detail */ 

data cfin.asset;
	set cfin.asset_:;
run;



proc datasets lib=work kill nolist;
run;



