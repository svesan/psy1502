*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_alv7.ass                                                    ;
* Date........: 2016-06-22                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Run all programs for the analysis                             ;
* Note........: 2016-06-10 updated s_infertil to s_infertil2                  ;
* Note........: 2016-06-10 updated s_dm13 to s_dm14                           ;
* Note........: 2016-08-30 s_infertil5 is now used. Earlier?                  ;
* Note........: 2017-03-03 updated for matrix server and combined male and    ;
* ............: female infertility to one common variable. Tassa dont think   ;
* ............: the codes are not sufficient to support male vs female.       ;
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

/*
libname ivfdb  oracle path=universe schema=REPRODUKTION  readbuff=4000 user="svesan" pw="aHG39ndT23";

filename saspgm "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\saspgm";
filename result "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\sasout";
filename log    "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\saslog";

libname  tmpdsn  "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\temp";
libname  sasperm "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\sastmp";

filename mall "P:\AAA\AAA_Research\sasproj\PSY\PSY1502\saspgm\mall.sas";
*/

*-- Matrix;

libname tmpdsn  "/nfs/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/temp";
libname sasperm "/nfs/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/sastmp";

filename saspgm  "/nfs/home/svesan/ki/ABS/mep/sasproj/PSY/PSY1502/saspgm";



*----------------------------------------------------;
* Data management                                    ;
*----------------------------------------------------;

%inc saspgm(s_dm14);      *-- Data management ;

%inc saspgm(s_infertil7); *-- DM Underlying infertility ;

%inc saspgm(s_blcovar);   *-- DM Baseline covariates ;

%inc saspgm(s_coxdsn4);   *-- Set up the data for cox regression;

%inc saspgm(s_rate_tab);  *-- Cases and rates table;



*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
delete _null_;
quit;

*-- End of File --------------------------------------------------------------;
