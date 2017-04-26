*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_alv1.ass                                                    ;
* Date........: 2016-04-27                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Run all programs for the analysis                             ;
* Note........:                                                               ;
*-----------------------------------------------------------------------------;
* Data used...:                                                               ;
* Data created:                                                               ;
*-----------------------------------------------------------------------------;
* OP..........: Linux/ SAS ver 9.04.01M2P072314                               ;
*-----------------------------------------------------------------------------;

*-- External programs --------------------------------------------------------;

*-- SAS macros ---------------------------------------------------------------;

*-- SAS formats --------------------------------------------------------------;

*-- Main program -------------------------------------------------------------;
libname ivfdb  oracle path=universe schema=REPRODUKTION  readbuff=4000 user="svesan" pw="aHG39ndT23";

*----------------------------------------------------;
* Data management                                    ;
*----------------------------------------------------;

%inc saspgm(s_dm10);      *-- Data management ;

%inc saspgm(s_infertil);  *-- DM Underlying infertility ;

%inc saspgm(s_blcovar);   *-- DM Baseline covariates ;

%inc saspgm(s_coxdsn1);   *-- Set up the data for cox regression;


%inc saspgm(s_dm10);    *-- Data management ;



*-- Temporary code;
*libname in '/home/svesan/psy1502/temp';
*proc copy in=in out=work;
*  select formats surv1 bl_covars;
*run;

%inc saspgm(s_coxdsn); *-- Create R data frames ;

proc copy in=work out=in;
  select coxdsn_miss coxdsn;
run;

title1 'Compare vs R. OCD crude';
proc phreg data=coxdsn;
  where outcome='1';
  class group;
  model (entry, exit)*event(0) = group;
  estimate 'ART/Spont' group  -1 1 / exp;
run;

title1 'Compare vs R. OCD adjusted';
proc phreg data=coxdsn;
  where outcome='1';
  class group;
  effect spl_byr=spline(byear / naturalcubic );

  model (entry, exit)*event(0) = spl_byr mat_cat pat_cat mat_phist pat_phist;

  estimate 'ART/Spont' group  -1 1 / exp;
run;


*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
delete _null_;
quit;

*-- End of File --------------------------------------------------------------;
