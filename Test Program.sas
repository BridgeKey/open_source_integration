/* Test Push */
/*I want to add my timer snippet, for seeing how long code takes*/

options nonotes;data _null_;call symputx("starttime",time());run;options notes;
/* Place Code Here */
options nonotes;data _null_;call symputx("runtime",time()-&starttime);run;options notes;%put Total Run Time = &runtime seconds;