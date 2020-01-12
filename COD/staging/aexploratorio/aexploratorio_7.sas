/**********************************************************************
 * Notas de Administracion Actuarial del Riesgo;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/

%include "&root./COD/configuracion.sas";
ods graphics / reset width=6.4in height=4.8in imagemap noborder;
options  fmtsearch=(ext);


/* 7 Financial assets */

ods graphics / reset width=8in height=4.8in imagemap noborder;
proc sgmap plotdata=EXT.ACTIVOSFINANCIEROS;
	openstreetmap;
	title 'Investments by Country';
	bubble x=num_longitude y=num_latitude size=pct_portfolio/ group=tx_country 
		name="bubblePlot";
	keylegend "bubblePlot" / title='Country:';
run;
ods graphics / reset;
title;





