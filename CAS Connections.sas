/* Opens the CAS Session "SASCAS1" */
cas sascas1;
caslib _all_ assign;

/* Create a PATH based CAS Lib */
caslib open_source_integration datasource=(srctype="path") 
path="/{your location}/SPyRG" sessref=sascas1 subdirs global;
/* Create a 8 Character (or less) Lib Ref Nickname to work in the library */
libname myCasLib cas caslib= "open_source_integration";

data mycaslib.iris (promote=YES);
	set sashelp.iris;
run;
