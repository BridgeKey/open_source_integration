%let SessRefName = sascas1;
%let CASProjectFolder = open_source_iris;
%let CASLibRef = FRAN;

/************************************/
/*		Connecting to CAS			*/
/************************************/

/* Opens the CAS Session "SASCAS1" */
cas &SessRefName.;
caslib _all_ assign;

/* Create a 8 Character (or less) Lib Ref Nickname to work in the library */
libname Fran cas caslib= "Open_Source_Iris";
