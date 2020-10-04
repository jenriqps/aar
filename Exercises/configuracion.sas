/*Declaracion de macro variables globales*/

/* SE DEBE CORRER ESTE NODO ANTES QUE CUALQUIER OTRO */

%global root;

* Modifica la siguiente ruta si es necesario;
*%let root=C:/Users/jenri/Google Drive/Cosas del trabajo/SAS/SASUniversityEdition/myfolders/aar;
%let root=/folders/myfolders/aar;

%put &=root.;
