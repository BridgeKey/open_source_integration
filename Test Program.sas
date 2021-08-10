/* Test Push */
/*I want to add my timer snippet, for seeing how long code takes*/

options nonotes;data _null_;call symputx("starttime",time());run;options notes;
/* Place Code Here */
/* Here we can put any set of code and view the runtime within the working env */

data _null_;
	x = 450;
run;
options nonotes;data _null_;call symputx("runtime",time()-&starttime);run;options notes;%put Total Run Time = &runtime seconds;