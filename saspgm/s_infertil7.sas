*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_infertil7.sas                                               ;
* Date........: 2016-03-18                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Code for fertility problems                                   ;
* Note........: Derive code for an underlying fertility problem derived from  ;
*             : codes in the patient register. From the s_frida6 program      ;
* Note........: 2016-06-16 added codes for male infert related diagnosis      ;
* Note........: 2016-08-16 added printouts of diagnosis                       ;
* Note........: 2016-08-24 added printouts of formatted diagnoses             ;
* Note........: 2016-08-30 now the tmpdsn directory is not used in program    ;
* Note........: 2017-03-03 now only one infertility variable                  ;
* Note........: 2017-03-29 combine male and female infertility                ;
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

*--------------------------------------------;
* Maternal diagnosis                         ;
*--------------------------------------------;
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
  keep lopnr_barn lopnr_mor infert_rel_diag icd diag;  *infert_diag infcat icd diag;

  rename infert_rel_diag = female_inf;

  label  infert_rel_diag      = 'Female related infertility diagnosis'
         infert_diag          = 'Infertility diagnosis IPR'
         ipr_ovulatory_inf    = 'Ovulatory infertility IPR'
         ipr_structural_inf   = 'Structural infertility IPR'
         ipr_inflammatory_inf = 'Inflammatory infertility IPR'
         ipr_malefactor_inf   = 'Male factor infertility OPR'
         infcat               = 'Level of infertility'
  ;

  length infert_rel_diag infert_diag infcat
         ipr_malefactor_inf ipr_ovulatory_inf ipr_structural_inf ipr_inflammatory_inf
         ipr_gesthypertension ipr_preeclampsia ipr_gestdiabetes 3
  ;

  format infert_diag infert_rel_diag yesno. ;

  set t1;

  *adding variable for ICD code version;
  *Sk

*ICD 7;
if icd = '7' then do;

  if diag in: ('275', '215', '634,10', '634,11', '634,12', '636') then infert_rel_diag = 1;

  if diag =: '636' then infert_diag = 1;

  if diag in: ('275', '634,10', '634,11', '634,12') then ipr_ovulatory_inf = 1;

  if diag =: '215' then ipr_inflammatory_inf = 1;

end;
else if icd = '8' then do;

  if diag in: ('256', '625,3', '626,00', '626,10', '626,11', '628') then infert_rel_diag = 1;

  if diag =: '628' then infert_diag = 1;

  if diag in: ('256', '626,00', '626,10', '626,11') then ipr_ovulatory_inf = 1;

  if diag =: '625,3' then ipr_inflammatory_inf = 1;

  if diag in: ('637') then ipr_gesthypertension = 1;

  if diag in: ('637,03','637,04','637,09','637,10') then ipr_preeclampsia = 1;

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

end;

*-- 2016-04-27 added categoris of increasing infertility problems or indications of;
if infert_rel_diag=0 and infert_diag=1 then abort;
else if infert_rel_diag=1 and infert_diag le 0 then infcat=1;
else if infert_rel_diag=1 and infert_diag=1 then infcat=2;

if infert_rel_diag = 1 then output;
else delete;

*if infert_rel_diag NE 1
AND ipr_gesthypertension NE 1
AND ipr_preeclampsia NE 1
AND ipr_gestdiabetes NE 1 then delete;

run;

*-- Remove replicates due to different codes;
proc sort data=t2 out=t2_nodup nodupkey;
  by lopnr_barn lopnr_mor female_inf;
run;
proc summary data=t2_nodup nway;
  var female_inf ;
  by lopnr_barn;
  output out=female_infertility(drop=_freq_ _type_ label='Codes for female infertility problems') max=;
run;



*----------------------------------------------------------------;
* Paternal diagnosis                                             ;
* 2016-06-10 added codes for male infertility related diagnoses  ;
*----------------------------------------------------------------;
proc sql;
  create table t3
  as select b.lopnr_barn, a.*
  from dd3(keep=lopnr diag diag_dat npr_source icd rename=(lopnr=lopnr_far)) as a
  inner join mbr1 as b
    on a.lopnr_far=b.lopnr_far
    where npr_source='S' and diag_dat < child_bdat
    ;
quit;

data t4;
  keep lopnr_barn lopnr_far male_inf icd diag;

  label  male_inf             = 'Male inf. related diagnosis'
  ;

  length male_inf 3
  ;

  format  male_inf yesno. ;

  set t3;

*ICD 7;
if icd = '7' then do;
  if diag in: ('272,1', '276,0', '462,0', '757,0', '757,21') then male_inf=1;
  else male_inf=0;
end;
else if icd = '8' then do;
  if diag in: ('253,10', '257,10', '456,10', '607,70', '752,10', '752,2') then male_inf=1;
  else male_inf=0;
end;
else if icd = '9' then do;
  *-- 2016-06-10 added codes for male infertility related diagnoses;
  if diag in: ('253C','257C','257B','456E','608C','752F','752G') then male_inf=1;
  else male_inf=0;
end;
else if icd = '10' then do;
  if diag in: ('E230','E291','E895','I861','N44','Q53','Q54') then male_inf=1;
  else male_inf=0;
end;

*-- 2016-04-27 added categoris of increasing infertility problems or indications of;
if male_inf then output;
else delete;
run;

*-- Remove replicates due to different codes;
proc sort data=t4 out=t4_nodup nodupkey;
  by lopnr_barn male_inf;
run;

proc summary data=t4_nodup nway;
  var male_inf;
  by lopnr_barn;
  output out=male_infertility(drop=_freq_ _type_ label='Codes for male infertility problems') max=;
run;


*----------------------------------------------------------------;
* Combine male and female infertility                            ;
*----------------------------------------------------------------;
data infertility(label='Codes for infertility problems, Male OR female');
  attrib infert_rel_diag length=3 format=yesno. label='Parental infertility related diagnosis'
         infert_source length=$3 label='Female or Male Infertility'
         male_inf length=3 label='Male infertility related diagnosis'
         female_inf length=3 label='Female infertility related diagnosis'
  ;
  merge female_infertility(in=f_inf keep=lopnr_barn female_inf)
        male_infertility(in=m_inf keep=lopnr_barn male_inf);
  by lopnr_barn;

  if f_inf and m_inf then do;
    infert_rel_diag=1; infert_source='M+F';
  end;
  else if f_inf and not m_inf then do;
    infert_rel_diag=1; infert_source='F'; male_inf=0;
  end;
  else if m_inf and not f_inf then do;
    infert_rel_diag=1; infert_source='M'; female_inf=0;
  end;
run;

*proc copy in=work out=tmpdsn;
*  select infertility;
*run;
/*****

*-- 2016-08-16 added table of diagnoses used;

data tab3;
  length label $60 start end $6;
  retain fmtname 'INFDFMT' type 'char' ;
  set t2(keep=diag female_inf icd)
      t4(keep=diag male_inf icd);

* The code below work GIVEN the correct diagnoses have been selecte first        *;

*ICD7 from 1964 to 1968:                                                         *;
if female_inf=1 and icd=7 then do;
  if substr(diag,1,3) = '275' then label='Ovarian dysfunction (including PCOS)';
  else if substr(diag,1,3) = '215' then label='Endometriosis';
  else if substr(diag,1,3) = '634' then label='Absent/Scanty or scanty menstruation';
  else if substr(diag,1,3) = '636' then label='Female Infertility';
end;
else if female_inf=1 and icd=8 then do;
*ICD8  from 1969 to 1986:                                                       *;
  if substr(diag,1,3) = '256' then label='Ovarian dysfunction (including PCOS)';
  else if substr(diag,1,5) = '625,3' then label='Endometriosis';
  else if substr(diag,1,3) = '626' then label='Absent/Scanty menstruation';
  else if substr(diag,1,3) = '628' then label='Female Infertility - Unspecified';
end;
else if female_inf=1 and icd=9 then do;

*ICD9  from 1987 to 1996:                                                       *;
  if substr(diag,1,3) = '256' then label='Ovarian dysfunction (including PCOS)';
  else if substr(diag,1,3) = '617' then label='Endometriosis';
  else if substr(diag,1,3) = '626' then label='Absent/Scanty menstruation';
  else if substr(diag,1,4) = '628A' then label='Female Infertility- Anovulatory';
  else if substr(diag,1,4) = '628C' then label='Female Infertility- Tubal';
  else if substr(diag,1,4) = '628D' then label='Female Infertility- Uterine';
  else if substr(diag,1,4) = '628E' then label='Female Infertility- Cervical';
  else if substr(diag,1,4) = '628W' then label='Female Infertility- Other specified';
  else if substr(diag,1,4) = '628X' then label='Female Infertility - Unspecified';
  else if substr(diag,1,3) = '628'  then label='Female Infertility - Unspecified';
end;
else if female_inf=1 and icd=10 then do;

*ICD10 from 1997 to 2010 (no commas in code):                                   *;
  if substr(diag,1,3) = 'E28' then label='Ovarian dysfunction (including PCOS)';
  else if substr(diag,1,3) = 'N80'   then label='Endometriosis';
  else if substr(diag,1,3) = 'N91'   then label='Absent/Scanty menstruation';
  else if substr(diag,1,4) = 'N970'  then label='Female Infertility - Anovulatory';
  else if substr(diag,1,4) = 'N971'  then label='Female Infertility - Tubal';
  else if substr(diag,1,4) = 'N972'  then label='Female Infertility - Uterine';
  else if substr(diag,1,4) = 'N973'  then label='Female Infertility - Cervical';
  else if substr(diag,1,4) = 'N974'  then label='Female Infertility - Male factor';
  else if substr(diag,1,5) = 'N978A' then label='Female Infertility - Immunological';
  else if substr(diag,1,5) = 'N978B' then label='Female Infertility - Social factors';
  else if substr(diag,1,5) = 'N978C' then label='Female Infertility - Unexplained';
  else if substr(diag,1,5) = 'N978D' then label='Female Infertility - Endometriosis';
  else if substr(diag,1,5) = 'N978W' then label='Female Infertility - Other specified';
  else if substr(diag,1,4) = 'N978'  then label='Female Infertility - Other specified';
  else if substr(diag,1,4) = 'N979'  then label='Female Infertility - Unspecified';
  else if substr(diag,1,4) = 'N97'   then label='Female Infertility';
end;


*MALE RELATED PROBLEMS *;
if male_inf=1 and icd=7 then do;

*ICD7  from 1964 to 1968:*;

if substr(diag,1,3) = '616' then label='Male infertility';
else if substr(diag,1,5) = '272,1' then label='Hypopituitarism';
else if substr(diag,1,5) = '276,0' then label='Testicular hypofunction';
else if substr(diag,1,5) = '462,0' then label='Varicocele';
else if substr(diag,1,5) = '757,0' then label='Cryptorchidism';
else if substr(diag,1,6) = '757,21' then label='Hypospadia';
end;
else if male_inf=1 and icd=8 then do;

*ICD8  from 1969 to 1986:                                                   *;
if substr(diag,1,6) = '606,99' then label='Male infertility';
else if substr(diag,1,6) = '253,10' then label='Hypopituitarism';
else if substr(diag,1,6) = '257,10' then label='Testicular hypofunction';
else if substr(diag,1,6) = '456,10' then label='Varicocele';
else if substr(diag,1,6) = '607,70' then label='Testicular torsion';
else if substr(diag,1,6) = '752,10' then label='Cryptorchidism';
else if substr(diag,1,5) = '752,2' then label='Hypospadia';
end;
else if male_inf=1 and icd=9 then do;

* ICD9  from 1987 to 1996:                                                  *;
if substr(diag,1,3) = '606' then label='Male infertility';
else if substr(diag,1,4) = '253C' then label='Hypopituitarism';
else if substr(diag,1,4) = '257C' then label='Testicular hypofunction';
else if substr(diag,1,4) = '257B' then label='Testicular hypofunction, iatrogenic';
else if substr(diag,1,4) = '456E' then label='Varicocele';
else if substr(diag,1,4) = '608C' then label='Testicular torsion';
else if substr(diag,1,4) = '752F' then label='Cryptorchidism';
else if substr(diag,1,4) = '752G' then label='Hypospadia and epispadia';
end;
else if male_inf=1 and icd=10 then do;

* ICD10 from 1997 to 2010 (no commas in code):                              *;
if substr(diag,1,3) = 'N46' then label='Male infertility';
else if substr(diag,1,4) = 'E230' then label='Hypopituitarism';
else if substr(diag,1,4) = 'E291' then label='Testicular hypofunction';
else if substr(diag,1,4) = 'E895' then label='Testicular hypofunction, iatrogenic';
else if substr(diag,1,4) = 'I861' then label='Varicocele';
else if substr(diag,1,3) = 'N44'  then label='Testicular torsion';
else if substr(diag,1,3) = 'Q53'  then label='Cryptorchidism';
else if substr(diag,1,3) = 'Q54'  then label='Hypospadia';
end;

start=diag;
end  =start;

run;

proc sort data=tab3(keep=fmtname type start end label) out=tab4 nodupkey;by fmtname type start label;run;
proc format cntlin=tab4 lib=work;run;quit;


title1 'Frequencies of diagnosis with increased risk of FEMALE OR MALE subfertility';
%tit(prog=s_infertil4);
proc freq data=tab3 order=freq;
*  where female_inf=1;
  table diag / nocum;
  format diag $infdfmt.;
run;



title1 'Frequencies of diagnosis with increased risk of MALE subfertility';
%tit(prog=s_infertil4);
proc freq data=tab3 order=freq;
  where male_inf=1;
  table diag / nocum;
  format diag $infdfmt.;
run;


*-- And the individual diagnoses;
proc sort data=t2(where=(female_inf=1)) out=tab1 nodupkey;by lopnr_barn female_inf diag;run;
proc sort data=t4(where=(male_inf=1)) out=tab2 nodupkey;by lopnr_barn male_inf diag;run;

title1 'Frequencies of diagnosis with increased risk of FEMALE subfertility';
%tit(prog=s_infertil4);
proc freq data=tab1 order=freq;
  table diag / nocum;
run;







title1 'Frequencies of diagnosis with increased risk of male OR female subfertility';
%tit(prog=s_infertil4);
proc freq data=tab2 order=freq;
  table diag / nocum;
run;
*/

*-- Dataset with indicator for infertility;
proc sort data=infertility out=e1 nodupkey;
  by lopnr_barn infert_rel_diag;
run;


*-- Dataset with all infertility diagnoses;
data e2;
  set t2(keep=lopnr_barn icd diag)  t4(keep=lopnr_barn icd diag);
run;
proc sort data=e2 out=e3 nodupkey;by icd diag lopnr_barn;run;
proc sort data=e2 out=e4 nodupkey;by icd diag;run;

data _null_;
  set e4;by icd diag;
  if first.icd then put / icd= diag @@;
  else put  '; ' diag @@;
run;


*-- Frequency distribution (one parent can have several codes, but only one of each);
proc freq data=e3 order=freq;
  table diag;
  by icd;
run;












*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
  delete t1-t4 tab1 - tab4;
quit;

*-- End of File --------------------------------------------------------------;
