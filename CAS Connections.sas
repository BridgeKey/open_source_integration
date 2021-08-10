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

/* Saves table to the CAS Global Scope (saving it as an hdat) then load to In-Memory*/
proc casutil incaslib="open_source_integration";
	DROPTABLE casdata = "iris" incaslib="open_source_integration" quiet; 
	SAVE casdata="iris.sashdat" outcaslib = "open_source_integration" replace;
	LOAD casdata="iris.sashdat" incaslib = "open_source_integration" 
		outcaslib="open_source_integration" casout = "iris" promote;
quit;
