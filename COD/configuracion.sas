/*Declaracion de macro variables globales*/

/* SE DEBE CORRER ESTE NODO ANTES QUE CUALQUIER OTRO */

%global root;

* La macrovariable _metauser tiene tu nombre de usuario;
%let root=/home/&_metauser./aar;

/*************************************************************************************************************************************/
/*****								 Asignacion de librerias									 								******/
/*************************************************************************************************************************************/

libname ext "&root./DAT/extraccion";	
libname aexpl "&root./DAT/staging/aexploratorio";	
libname cact "&root./DAT/staging/cactuarial";	
libname cfin "&root./DAT/staging/cfinancieros";	
libname prft "&root./DAT/staging/profit";	


FILENAME REFFILE "&root./DAT/extraccion/insumos/insumos.xlsx";








