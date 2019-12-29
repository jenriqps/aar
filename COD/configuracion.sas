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







