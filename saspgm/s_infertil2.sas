*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_infertil2.sas                                               ;
* Date........: 2016-03-18                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Code for fertility problems                                   ;
* Note........: Derive code for an underlying fertility problem derived from  ;
*             : codes in the patient register. From the s_frida6 program      ;
* Note........: 2016-06-16 added codes for male infert related diagnosis      ;
*-----------------------------------------------------------------------------;
* Data used...: dd3 mbr1                                                      ;
* Data created: infertility                                                   ;
*-----------------------------------------------------------------------------;
* OP..........: Linux/ SAS ver 9.04.01M2P072314                               ;
*-----------------------------------------------------------------------------;

*-- External programs --------------------------------------------------------;
*%inc saspgm(s_dm10);

*-- SAS macros ---------------------------------------------------------------;

*-- SAS formats --------------------------------------------------------------;

*-- Main program -------------------------------------------------------------;

proc sql;
  create table t1
  as select b.lopnr_barn, a.*
  from dd3(keep=lopnr diag diag_dat npr_source icd rename=(lopnr=lopnr_mor)) as a
  inner join mbr1 as b
    on a.lopnr_mor=b.lopnr_mor
    where npr_source='S' and diag_dat < child_bdat
    ;
quit;

data t2;
  keep lopnr_barn lopnr_mor infert_rel_diag infert_diag infcat male_inf;

  label  infert_rel_diag      = 'Infertility related diagnosis IPR'
         infert_diag          = 'Infertility diagnosis IPR'
         ipr_ovulatory_inf    = 'Ovulatory infertility IPR'
         ipr_structural_inf   = 'Structural infertility IPR'
         ipr_inflammatory_inf = 'Inflammatory infertility IPR'
         ipr_malefactor_inf   = 'Male factor infertility OPR'
         infcat               = 'Level of infertility'
         male_inf             = 'Male inf. related diagnosis'
  ;

  length infert_rel_diag infert_diag infcat
         ipr_malefactor_inf ipr_ovulatory_inf ipr_structural_inf ipr_inflammatory_inf
         ipr_gesthypertension ipr_preeclampsia ipr_gestdiabetes male_inf 3
  ;

  format infert_diag infert_rel_diag male_inf yesno. ;

  set t1;

  *adding variable for ICD code version;
  *Sk

*ICD 7;
if icd = '7' then do;

  if diag in: ('275', '215', '634,10', '634,11', '634,12', '636') then infert_rel_diag = 1;

  if diag =: '636' then infert_diag = 1;

  if diag in: ('275', '634,10', '634,11', '634,12') then ipr_ovulatory_inf = 1;

  if diag =: '215' then ipr_inflammatory_inf = 1;


  *-- 2016-06-10 added codes for male infertility related diagnoses;
  if diag in: ('272,1', '276,0', '462,0', '757,0', '757,21') then male_inf=1;
  else male_inf=0;
end;
else if icd = '8' then do;

  if diag in: ('256', '625,3', '626,00', '626,10', '626,11', '628') then infert_rel_diag = 1;

  if diag =: '628' then infert_diag = 1;

  if diag in: ('256', '626,00', '626,10', '626,11') then ipr_ovulatory_inf = 1;

  if diag =: '625,3' then ipr_inflammatory_inf = 1;

  if diag in: ('637') then ipr_gesthypertension = 1;

  if diag in: ('637,03','637,04','637,09','637,10') then ipr_preeclampsia = 1;


  *-- 2016-06-10 added codes for male infertility related diagnoses;
  if diag in: ('253,10', '257,10', '456,10', '607,70', '752,10', '752,2') then male_inf=1;
  else male_inf=0;
end;
else if icd = '9' then do;

  if diag in: ('256', '617', '626A', '626B', '628') then infert_rel_diag = 1;

  if diag =: '628' then infert_diag = 1;

  if diag in: ('256', '626A', '626B', '628A') then ipr_ovulatory_inf = 1;

  if diag in: ('628C', '628D', '628E') then ipr_structural_inf = 1;

  if diag =: '617' then ipr_inflammatory_inf = 1;

  if diag in: ('642') then ipr_gesthypertension = 1;

  if diag in: ('642E','642F','642G') then ipr_preeclampsia = 1;

  if diag in: ('648A','648W') then ipr_gestdiabetes = 1;


  *-- 2016-06-10 added codes for male infertility related diagnoses;
  if diag in: ('253C','257C','257B','456E','608C','752F','752G') then male_inf=1;
  else male_inf=0;
end;
else if icd = '10' then do;

  if diag in: ('E28', 'N80', 'N91', 'N97') then infert_rel_diag = 1;

  if diag =: 'N97' then infert_diag = 1;

  if diag in: ('E28', 'N970', 'N91') then ipr_ovulatory_inf = 1;

  if diag in: ('N971', 'N972', 'N973') then ipr_structural_inf = 1;

  if diag in: ('N80', 'N978D') then ipr_inflammatory_inf = 1;

  if diag in: ('N974') then ipr_malefactor_inf = 1;

  if diag in: ('O13','O14','O15','O16') then ipr_gesthypertension = 1;

  if diag in: ('O14','O15') then ipr_preeclampsia = 1;

  if diag in: ('O244') then ipr_gestdiabetes = 1;


  *-- 2016-06-10 added codes for male infertility related diagnoses;
  if diag in: ('E23.0','E29.1','E89.5','I86.1','N44','Q53','Q54') then male_inf=1;
  else male_inf=0;
end;

*-- 2016-04-27 added categoris of increasing infertility problems or indications of;
if infert_rel_diag=0 and infert_diag=1 then abort;
else if infert_rel_diag=1 and infert_diag le 0 then infcat=1;
else if infert_rel_diag=1 and infert_diag=1 then infcat=2;

if infert_rel_diag = 1 or infert_diag=1 then output;
else delete;

*if infert_rel_diag NE 1
AND ipr_gesthypertension NE 1
AND ipr_preeclampsia NE 1
AND ipr_gestdiabetes NE 1 then delete;

run;

*-- Remove replicates due to different codes;
proc sort data=t2 nodupkey;
  by lopnr_barn infert_rel_diag male_inf infert_diag;
run;

proc summary data=t2 nway;
  var infert_rel_diag infert_diag infcat male_inf;
  by lopnr_barn;
  output out=infertility(drop=_freq_ _type_ label='Codes for infertility problems') max=;
run;


proc copy in=work out=tmpdsn;
  select infertility;
run;


*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
  delete t1 t2;
quit;

*-- End of File --------------------------------------------------------------;
