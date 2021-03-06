/* Opens the CAS Session "SASCAS1" */
cas sascas1;
caslib _all_ assign;


/*************************/
/* Run the python script */

proc fcmp outlib=work.myfuncs.pyfuncs;
/* Define the function.  */
/* $ and following length statement are required for character output */
function fcmp_function(arg1 $) $;
length FCMP_out $ 1312;
	declare object py(python);
rc = py.infile("/data/fedhealth/SPyRG/Python/Wikipedia.py");
rc = py.publish();
rc = py.call("wikiQuery", arg1);
rc = py.call("runPythonCode");
FCMP_out = py.results["MyOutputKey"];
return(FCMP_out);
endsub;
run;
options cmplib=work.myfuncs;
 
data _null_;
   result = fcmp_function(&ParameterForPython.);
   put result=;
run;

/********************/
/* Run the R Script */

proc iml;
ClusterNumber = %trim(&ParameterForR.);
submit ClusterNumber / r;
source('/data/fedhealth/SPyRG/R/R_Ops.R')
runRCode(clusters = &ClusterNumber)
endsubmit;
quit;



