*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_alv3.ass                                                    ;
* Date........: 2016-04-27                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Run all programs for the analysis                             ;
* Note........: 2016-06-10 updated s_infertil to s_infertil2                  ;
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


libname ivfdb  oracle path=universe schema=REPRODUKTION  readbuff=4000 user="svesan" pw="aHG39ndT23";

filename saspgm "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\saspgm";
filename result "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\sasout";
filename log    "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\saslog";

libname  tmpdsn  "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\temp";
libname  sasperm "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\sastmp";

filename mall "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\saspgm\mall.sas";

*-- Skjold;
/*
libname tmpdsn  "/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/temp";
libname sasperm "/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/sastmp";

filename saspgm  "/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/saspgm";
*/


*----------------------------------------------------;
* Data management                                    ;
*----------------------------------------------------;

%inc saspgm(s_dm12);      *-- Data management ;

%inc saspgm(s_infertil2); *-- DM Underlying infertility ;

%inc saspgm(s_blcovar);   *-- DM Baseline covariates ;

%inc saspgm(s_coxdsn2);   *-- Set up the data for cox regression;



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
