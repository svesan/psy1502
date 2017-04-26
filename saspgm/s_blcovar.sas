*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_blcovar.sas                                                 ;
* Date........: 2016-03-18                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Create dataset for baseline covariates                        ;
* Note........: 2016-06-10 added male_inf variable                            ;
*-----------------------------------------------------------------------------;
* Data used...: bl_covars0  infertility                                       ;
* Data created: bl_covars                                                     ;
*-----------------------------------------------------------------------------;
* OP..........: Linux/ SAS ver 9.04.01M2P072314                               ;
*-----------------------------------------------------------------------------;

*-- External programs --------------------------------------------------------;

*-- SAS macros ---------------------------------------------------------------;

*-- SAS formats --------------------------------------------------------------;

*-- Main program -------------------------------------------------------------;

data bl_covars(label='BL covariates' sortedby=lopnr_barn);

  merge bl_covars0 infertility;
  by lopnr_barn;

  *-- Information on infertility assumed known;
  if infert_diag le .z then infert_diag=0;
  if infert_rel_diag le .z then infert_rel_diag=0;
  if male_inf le .z then male_inf=0;

  if infcat le .z then infcat=0;
run;

*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
delete _null_;
quit;

*-- End of File --------------------------------------------------------------;
