*-----------------------------------------------------------------------------;
* Study.......: PSY1502                                                       ;
* Name........: s_dm5.sas                                                     ;
* Date........: 2016-03-03                                                    ;
* Author......: svesan                                                        ;
* Purpose.....: Create analysis datasets                                      ;
* Note........:                                                               ;
*-----------------------------------------------------------------------------;
* Data used...:                                                               ;
* Data created: ana0                                                          ;
*-----------------------------------------------------------------------------;
* OP..........: Linux/ SAS ver 9.04.01M2P072314                               ;
*-----------------------------------------------------------------------------;

*-- External programs --------------------------------------------------------;

*-- SAS macros ---------------------------------------------------------------;

*-- SAS formats --------------------------------------------------------------;
proc format;
  value yesno   0='N' 1='Y';
  value sexfmt  1='M' 2='F';
  value embftyp 1='Slow freezing' 2='Vitrification';
  value ivficsi 1='IVF' 2='ICSI';
  value frozen  1='Fresh' 2='Frozen';
  value spsrc   4='Retrograde ejaculation' 3='Testis' 2='Epididymis' 1='Ejaculated';

  value ivficsi   1='IVF' 2='ICSI';
  value trtfmt    1='Standard IVF' 2='IVF frozen' 3='ICSI fresh' 4='ICSI frozen' 5='ICSI surgical';
  value $ztrtfmt '1'='Standard IVF' '2'='IVF frozen' '3'='ICSI fresh'
                 '4'='ICSI frozen' '5'='ICSI surgical';
  value $outc    '1'='OCD' '2'='TIC' '3'='TD' '4'='OTT';

  value matcat  1='<20' 2='20-24' 3='25-29' 4='30-34' 5='>=35';

  value froz 1='Frozen' 0='Fresh';

  value ivficsi 1='IVF' 2='ICSI';

  value testis 1='Testis/Epididymal' 0='Ejaculated';

run;

*-- Main program -------------------------------------------------------------;
*libname swork server=skjold slibref=work;

*-------------------------------------------------------------------------------------;
* Description of the variables in SOS IVF can be found in the folder                  ;
* /projects/Reproduktion/Reproduktion_IT/Data/Data documentation/codebooks from SOS/  ;
*-------------------------------------------------------------------------------------;


*---------------------------------------------------------------------------;
* Select medical birth register                                             ;
* OBS!! Not sure what is the difference between variable INDATE and INDATUM ;
* Frida has created the INDATE variable from the indatum variable. INDATE   ;
* is the perferred variable to use                                          ;
* DODFOD: All was missing to excluded this variable                         ;
*---------------------------------------------------------------------------;

proc sql;
  create table mbr0 as
  select lopnr_mor label='Mother ID' length=6, lopnr_barn label='Child ID' length=6,
         paritet length=3 label='Parity',
         malder as mage length=4 label='Mother age, best estimate',
         case kon
           when '1' then '1' when '2' then '2' else ''
         end as sex length=1 label='Sex',
         case bordf2
           when '1' then '1' when '2' then '0' else ''
         end as singleton length=1 label='Singleton birth (Y/N)',
         grvbs as gage length=3 label='Gestational age (weeks)',
         datepart(bdate_child) as child_bdat length=4 format=yymmdd10. label='Child birth date',
         datepart(bdate_mother) as mo_bdat length=4 format=yymmdd10. label='Mother birth date',
         case when ofribarn > 0 then ofribarn else 0 end as infert_yr length=3 label='Yrs of Infertility',
         case when dodfod ne '' then 1 else 0 end as deadborn length=3 format=yesno. label='Dead born'

  from ivfdb.mbr(where=(bdate_child GE "01jan1985"d and lopnr_barn GT .z) )
  ;
run;

*-- Exclude records where mother and child id unknown or dead born;
data mbr1a;
  drop _a_ _b_;
  attrib byear length=4 label='Birth Year';
  retain _b_ 0;
  set mbr0(where=(deadborn=0) end=eof;

  byear=year(child_bdat);
  _a_=0;
  if lopnr_barn le .z or lopnr_mor le .z then _a_=1;

  _b_=_b_+_a_;
  if eof then put 'WARNING: ' _b_ 'records deleted due to missing ID of child or mother';
  if _a_=1 then delete;
run;

*-- Add in info on death and emigration;
proc sql;
  create table mbr1 as
  select a.*,
         datepart(b.deathdate) as death_dat length=4 format=yymmdd10. label='Date of death',
         datepart(c.migrdate) as emig_dat length=4 format=yymmdd10. label='Date of emigration'
  from mbr1a as a
  left join ivfdb.dod5214 as b
    on a.lopnr_barn=b.lopnr
  left join ivfdb.migrations(where=(migrtype='emi')) as c
    on a.lopnr_barn=c.lopnr
  ;
quit;
proc sort data=mbr1;by lopnr_barn;run;


*---------------------------------------------------------------------------;
* Select patient register data                                              ;
* OBS!! Not sure what is the difference between variable INDATE and INDATUM ;
* Frida has created the INDATE variable from the indatum variable. INDATE   ;
* is the perferred variable to use                                          ;
*---------------------------------------------------------------------------;
proc sql;drop table npr1, npr2;run;

proc sql;
  drop index lopnr_barn on mbr1;
  create index lopnr_barn on mbr1;
quit;

proc sql;
  create view npr1 as
  select a.lopnr as lopnr length=6, indate length=4 format=yymmdd10. label='Diag date',
  substr(left(dia1),1,6) as dia1 length=6,
  substr(left(dia2),1,6) as dia2 length=6,
  substr(left(dia3),1,6) as dia3 length=6,
  substr(left(dia4),1,6) as dia4 length=6,
  substr(left(dia5),1,6) as dia5 length=6,
  substr(left(dia6),1,6) as dia6 length=6,
  substr(left(dia7),1,6) as dia7 length=6,
  substr(left(dia8),1,6) as dia8 length=6,
  substr(left(dia9),1,6) as dia9 length=6,
  substr(left(dia10),1,6) as dia10 length=6,
  substr(left(dia11),1,6) as dia11 length=6,
  substr(left(dia12),1,6) as dia12 length=6,
  substr(left(dia13),1,6) as dia13 length=6,
  substr(left(dia14),1,6) as dia14 length=6,
  substr(left(dia15),1,6) as dia15 length=6,
  substr(left(dia16),1,6) as dia16 length=6,
  substr(left(dia17),1,6) as dia17 length=6,
  substr(left(dia18),1,6) as dia18 length=6,
  substr(left(dia19),1,6) as dia19 length=6,
  substr(left(dia20),1,6) as dia20 length=6,
  substr(left(dia21),1,6) as dia21 length=6,
  substr(left(dia22),1,6) as dia22 length=6
  from ivfdb.patient_sluten(keep=lopnr indate  dia1-dia22) as a
  join mbr1 as b
    on b.lopnr_barn=a.lopnr
    where indate GT "01jan1988"d
  ;

  create view npr2 as
  select a.lopnr as lopnr length=6, indate length=4 format=yymmdd10. label='Diag date',
  substr(left(dia1),1,6) as dia1 length=6,
  substr(left(dia2),1,6) as dia2 length=6,
  substr(left(dia3),1,6) as dia3 length=6,
  substr(left(dia4),1,6) as dia4 length=6,
  substr(left(dia5),1,6) as dia5 length=6,
  substr(left(dia6),1,6) as dia6 length=6,
  substr(left(dia7),1,6) as dia7 length=6,
  substr(left(dia8),1,6) as dia8 length=6,
  substr(left(dia9),1,6) as dia9 length=6,
  substr(left(dia10),1,6) as dia10 length=6,
  substr(left(dia11),1,6) as dia11 length=6,
  substr(left(dia12),1,6) as dia12 length=6,
  substr(left(dia13),1,6) as dia13 length=6,
  substr(left(dia14),1,6) as dia14 length=6,
  substr(left(dia15),1,6) as dia15 length=6,
  substr(left(dia16),1,6) as dia16 length=6,
  substr(left(dia17),1,6) as dia17 length=6,
  substr(left(dia18),1,6) as dia18 length=6,
  substr(left(dia19),1,6) as dia19 length=6,
  substr(left(dia20),1,6) as dia20 length=6,
  substr(left(dia21),1,6) as dia21 length=6,
  substr(left(dia22),1,6) as dia22 length=6
  from ivfdb.patient_oppen(keep=lopnr indate  dia1-dia22) as a
  join mbr1 as b
    on b.lopnr_barn=a.lopnr
    where indate GT "01jan1988"d
  ;
quit;

data npr3;
  keep lopnr npr_source diag_dat diag;
  attrib diag length=$7. label="Diagnosis"
         diag_dat length=4 format=yymmdd10. label="Date of Diagnosis"
         npr_source length=$1. label="In or out-patient"
  ;
  array  dd $8 dia1-dia22;

  set npr1(in=sluten keep=lopnr indate dia1-dia22)
      npr2(in=oppen  keep=lopnr indate dia1-dia22);

  if sluten then npr_source="S";else nprg_source="O";

  diag_dat=datepart(indate);
  diag='x';i=0;
  do until(diag='' or i GE 22);
    i=i+1;
    diag=compress(dd(i), " -");
    if diag ne '' then output;
  end;
run;


*----------------------------------------------------------------;
* Now, apply the different codes for OCD, TICS, TD               ;
* Tourett is F95.9 part of TICS (as AD in ASD)                   ;
* and calculate age at diagnosis                                 ;
* Note: Join with death and emigration to ensure all diagnosis   ;
*       are before death and emigration. Not need to check later ;
*----------------------------------------------------------------;
proc sort data=npr3;by lopnr diag_dat;run;
data npr4(keep=outcome lopnr_barn diag_dat diag_age death_dat emig_dat)
     chk_diag_age(keep=outcome lopnr_barn  diag_dat diag diag_age);

  rename lopnr=lopnr_barn;
  attrib outcome  length=$1 label='Outcome' format=$outc.
         diag_age length=4  label='Age at diagnosis'
  ;
  merge mbr1(keep=lopnr_barn child_bdat death_dat emig_dat rename=(lopnr_barn=lopnr))
        npr3(in=npr3);
  by lopnr;

  *-- Check for and exclude diagnosis after emigration or death;
  check=0;

  diag_age=round((diag_dat-child_bdat)/365.25, 0.01);
  if emig_dat>.z and emig_dat<diag_dat then check=1;
  if death_dat>.z and death_dat<diag_dat then check=1;
  if diag_age LE 1 then check=1;

  if npr3 and check=0 then do;
    d4 = substr(left(diag), 1, 4);
    d3 = substr(d4, 1, 3);

    *- OCD or TICS and TD;
  /*
    if d3 = "F42" or d3 = "F95" then ott=1; else ott=0;
    if d3 = "F42"               then ocd=1; else ocd=0;
    if d3 = "F95"               then tic=1; else tic=0;
    if d4 = "F952"              then td =1; else td =0;

    if ott then output;
  */

    if d3 = 'F42' and diag_age GT 2 then do; outcome='1'; output npr4; outcome='4'; output npr4; end;
    else if d3 = 'F42' and diag_age LE 2 then do; outcome='1'; output chk_diag_age; end;

    else if d4 = 'F952' and diag_age GT 2 then do; outcome='3'; output npr4; outcome='4'; output npr4; end;
    else if d4 = 'F952' and diag_age LE 2 then do; outcome='3'; output chk_diag_age; end;

    else if d3 = 'F95' and diag_age GT 0.5 then do; outcome='2'; output npr4; outcome='4'; output npr4; end;
    else if d3 = 'F95' and diag_age LE 0.5 then do; outcome='2'; output chk_diag_age; end;
    /*  if d3 in ('F95','F42') then do; outcome='4'; output; end;*/
  end;
run;

*-- Select only the first diagnosis;
proc sort data=npr4 nodupkey; by lopnr_barn diag_dat;run;
proc sort data=npr4 nodupkey; by lopnr_barn;run;


*-----------------------------------------------------------;
* IVF treatments from MBR up to 1997                        ;
* Tourett is F95.9 part of TICS (as AD in ASD)              ;
*-----------------------------------------------------------;
data sosivf1;
  drop lopnr_kvinna zlopnr_barn zmetod zembryon bdate_child bdate_mother etdate;
  attrib child_bdat length=4  format=yymmdd10. label="Child DoB"
         mo_bdat    length=4  format=yymmdd10. label="Mother DoB"
         et_dat     length=4  format=yymmdd10. label="ET Date"
         lopnr_mor  length=6  label='Mother ID'
         lopnr_barn length=6  label='Child ID'
         embryon    length=$1 label='#Embryon'
         metod      length=$2
  ;
  set ivfdb.ivf_sos(keep=lopnr_barn lopnr_kvinna bdate_child bdate_mother embryon metod
                         etdate embryon
                    rename=(embryon=zembryon metod=zmetod lopnr_barn=zlopnr_barn));

  lopnr_mor  = lopnr_kvinna;
  lopnr_barn = zlopnr_barn;
  child_bdat = datepart(bdate_child);
  mo_bdat    = datepart(bdate_mother);
  if etdate>.z then et_dat=datepart(etdate);else et_dat=.u;
  embryon    = zembryon;
  metod      = zmetod ;

  if lopnr_barn le .z then delete;

run;

data sosivf2;
  drop met metod1 metod2;
  attrib ivf_icsi length=3 format=ivficsi. label='IVF/ICSI'
         frozen   length=3 format=froz.    label='Frozen'
         testis   length=3 format=yesno.   label='Surgery'
         trt      length=3 format=trtfmt.  label='IVF procedure'
  ;
  set sosivf1;

  if et_dat GE '01jan2002'd then metod2=metod;
  else metod1=metod;

  met=input(metod,8.);
  if met in (1,2,6) then ivf_icsi=1;
  else if met in (3,4,5,7,8,9,10) then ivf_icsi=2;
  else if met in (0) then ivf_icsi=.M;
  if met in (3,4,5) then frozen=0;
  else if met in (6,7,8,9) then frozen=1;
  else if met in (0) then frozen=.M;
  if met in (4,5,8) then testis=1;
  else if met in (1,2,3,6,7) then testis=0;
  else if met in (9,0,7) then testis=.M;

  if met in (0) then trt=.M;         /* Unknown        */
  else if met in (1,2) then trt=1;   /* Std IVF        */
  else if met in (6) then trt=2;     /* Do. fryst      */
  else if met in (3) then trt=3;     /* ICSI fresh     */
  else if met in (7) then trt=4;     /* ICSI frozen  can 8+9 be added here  */
  else if met in (4,5,8) then trt=5; /* ICSI surgical    */
  else trt=.U;

  *-- Delete record that is already in QIVF;
  if lopnr_mor=67295 and child_bdat='24OCT2007'd then delete;
run;


*-----------------------------------------------------------;
* Data management of Q-IVF. IVF from 01jan2002              ;
*-----------------------------------------------------------;
data qivf1;
  drop lopnr_kvinna etdate cyclestartdate resultdeliverydate d_method spermreceive
       cyclefreshfrozen embryofreezetype;

  attrib et_dat      length=4 label='Embryo Start Date'    format=yymmdd10.
         st_dat      length=4 label='Start date for cycle' format=yymmdd10.
         x_dat       length=4 label='Date delivery. Alive' format=yymmdd10.
         ivficsi     length=3 label='IVF/ICSI'             format=ivficsi.
         spsource    length=3 label='Sperm Source'         format=spsrc.
         freshfrozen length=3 label='Frozen/fresh embryo'  format=frozen.
         freezetype  length=3 label='Slow/fast freeze'     format=embftyp.
         embryo_days length=4 label='Embryo days'
         lopnr_mor   length=6 label='Mother ID'

         ivf_icsi    length=3 format=ivficsi. label='IVF/ICSI'
         frozen      length=3 format=yesno.   label='Frozen'
         testis      length=3 format=testis.  label='Surgery'
         trt         length=3 format=trtfmt.  label='IVF procedure'
         embryon     length=$1 label='#Embryon'
  ;
  set ivfdb.qivf(keep=d_method cyclefreshfrozen etdate lopnr_man lopnr_kvinna oocytowndonated
                      etnumber embryofreezetype spermreceive cyclestartdate resultdeliverydate);

  lopnr_mor=lopnr_kvinna;

  et_dat=.U; st_dat=.U; x_dat=.U; embryo_days=.U;
  if etdate > .z then et_dat=datepart(etdate);
  if cyclestartdate > .z then st_dat=datepart(cyclestartdate);
  if resultdeliverydate > .z then x_dat =datepart(resultdeliverydate);

  if et_dat>.z and st_dat>.z then embryo_days = et_dat - st_dat;
  ivficsi     = d_method;
  spsource    = spermreceive ;
  freshfrozen = cyclefreshfrozen;
  freezetype  = embryofreezetype;

  *-- Frida 151117: Et_dat missing then no embryo transfer. Delete!! ;
  if et_dat le .z or et_dat>'01jan2020'd then delete;

  *-- Derive the same variables as in SOSIVF;
  *-- Note: Here we dont separate surgical frozen from surgical fresh;
  ivf_icsi=ivficsi;

  if freshfrozen=2 then frozen=1;
  else if freshfrozen=1 then frozen=0;

  if spsource=1 then testis=0;
  else if spsource in (2,3) then testis=1;
  else testis=.M;

  if ivf_icsi=1 and frozen=0 then trt=1;
  else if ivf_icsi=1 and frozen=1 then trt=2;
  else if ivf_icsi=2 and testis=1 then trt=5;
  else if ivf_icsi=2 and frozen=0 then trt=3;
  else if ivf_icsi=2 and frozen=1 then trt=4;

  *-- Create character variable to agree with sosivf;
  embryon=put(etnumber, 1.);

  *-- Deleting duplicate record;
  if lopnr_mor=280576 and x_dat='17SEP2009'd and embryo_days=0 then delete;
run;


*-- Select women and births in qivf;
proc sql;
  *-- First, children born in MBR from 2007 ;
  create table t1 as
  select lopnr_mor, lopnr_barn, child_bdat
  from mbr1
  where child_bdat>'01mar2007'd and lopnr_mor>.z;

  *-- Select distinct women in qivf;
  create table t2 as
  select distinct  lopnr_mor, et_dat
  from qivf1
  where et_dat>.z
  order by lopnr_mor
  ;

  *-- Now select the treatments in QIVF for these children and mothers;
  create table t3 as
  select a.lopnr_mor, a.lopnr_barn, b.et_dat, a.child_bdat, a.child_bdat-b.et_dat as diff
  from t1 as a
  join t2 as b
  on a.lopnr_mor=b.lopnr_mor
  having diff>139 and diff<316  /** 20 to 45 weeks */
  order by lopnr_mor, lopnr_barn, a.child_bdat, b.et_dat
  ;
run;quit;

*-- Select the treatment closest to birth;
data t4;
  drop i diff;
  attrib i     length=3 label='Embryo transfer order'
  ;
  retain i 0;
  set t3; by lopnr_mor lopnr_barn child_bdat et_dat;

  if first.lopnr_barn then i=1;else i=i+1;

  if last.lopnr_barn;
run;

*-- Now join back with QIVF to get additional covariates;
proc sort data=t4;by lopnr_mor et_dat;run;
proc sort data=qivf1;by lopnr_mor et_dat;run;
data qivf;
  merge t4(in=t4)
        qivf1(keep=lopnr_mor et_dat x_dat trt frozen testis ivf_icsi embryon);
  by lopnr_mor et_dat;
  if t4 then do;
    *if first.lopnr_mor ne last.lopnr_mor and x_dat ne child_bdat then delete;
    if first.et_dat ne last.et_dat and x_dat ne child_bdat then delete;
  end;
  else delete;
run;

*-----------------------------------------------------------;
* Combine IVF treatment data from QIVF and SOS              ;
*-----------------------------------------------------------;
proc sort data=sosivf2;by lopnr_mor lopnr_barn;run;
proc sort data=qivf;by lopnr_mor lopnr_barn;run;

data ivfdata(label='IVF data from SOS and Q-IVF');
  set sosivf2
        qivf
  ;
  byear=year(child_bdat);
run;

*-- Merge in data for each woman;
proc sort data=mbr1 out=tmp;by lopnr_mor lopnr_barn;run;
proc sort data=ivfdata;by lopnr_mor lopnr_barn;run;

data mbr2;
  attrib art length=$1 label='ART (Y/N)'
  ;
  merge tmp(in=mbr)
        ivfdata(in=ivfdata)
  ;
  by lopnr_mor lopnr_barn;

  if not ivfdata then do;
    art='N';
    trt=0;
  end;
  else art='Y';

  *-- Define the population part of MBR data;
  if not mbr then delete;
run;

*-- Replicate the mbr dataset once for each outcome + total so it can be joined with NPR4;
data mbr3(label='Multi-Generation-Outcome data');
  attrib outcome  length=$1 label='Outcome' format=$outc.;

  set mbr2(keep=lopnr_barn child_bdat);
  do outcome='1','2','3','4';
    output;
  end;
run;
proc sort data=mbr3;by outcome lopnr_barn;run;

*-----------------------------------------------------------;
* Baseline covariate dataset                                ;
*-----------------------------------------------------------;
proc sort data=mbr2;by lopnr_barn;run;
data bl_covars(label='BL covariates' sortedby=lopnr_barn);
  attrib preterm length=3  label='Pre-Term'               format=yesno.
         mat_cat length=3  label='Maternal age category'  format=matcat.
         frozen  length=3  label='Frozen/fresh'           format=froz.
         testis  length=3  label='Epididymal/testis'      format=testis.
         twin    length=3  label='Twins'                  format=yesno.
  ;

  set mbr2;

  *-- Preterm birth;
  if gage le .z then preterm=.u;
  else preterm = (gage<37); * Using our earlier paper ;

  *-- Create twin variable as in psy1001 instead of singleton;
  if singleton='0' then twin=1;else twin=0;

  *-- Maternal age categories <20, 20-24, 25-29, 30-34, >=35 ;
  if mage le .z then mat_cat=mage;
  else if mage le 19 then mat_cat=1;
  else if mage le 24 then mat_cat=2;
  else if mage le 29 then mat_cat=3;
  else if mage le 34 then mat_cat=4;
  else mat_cat=5;
run;

*-----------------------------------------------------------;
* Join in patient register data with diagnoses to create a  ;
* time to event dataset for survival analysis               ;
*-----------------------------------------------------------;
proc sort data=mbr3;by outcome lopnr_barn;run;
proc sort data=npr4;by outcome lopnr_barn;run;

data surv1(label='Surival time data' sortedby=outcome lopnr_barn);

  drop pyear logpyear;

  attrib entry   length=6  label='Age at entry'
         exit    length=6  label='Age at exit'
         pyear   length=6  label='Person years'
         outcome length=$3 label='Outcome'         format=$outc.
         event   length=3  label='Event'
  ;
  merge mbr3(in=mbr3)
        npr4(in=npr);
  by outcome lopnr_barn;

  *-- Require that in MBR and born before 1st Jan 2011;
  if mbr3 and child_bdat < '01JAN2011'd then do;
    *-- Cohort entry;
*    if outcome EQ '2' then entry=1;
*    else entry=2;
    entry=1;

    *-- For records in the patient register (dont need to check for death or emig since done in npr4);
    if npr then do;
      event=1;
      if diag_dat > .z then do;
        exit  = diag_age;
        pyear = exit-entry;
      end;
      if diag_dat le .z then abort;
    end;
    else do;
      event = 0; diag_age=.N;

      if emig_dat>.z and emig_dat<death_dat then exit = (emig_dat - child_bdat) / 365.25;
      else if death_dat>.z then exit = (death_dat - child_bdat) / 365.25;
      else exit = ('31Dec2013'd - child_bdat) / 365.25;

      pyear=exit-entry;
    end;
    logpyear=log(pyear);

    exit =round(exit, 0.01);
    pyear=round(pyear, 0.01);
  end;
  else delete;
run;

proc download inlib=work outlib=work;
  select formats surv1 ivfdata mbr0 bl_covars npr3 sosivf1 qivf;
run;

proc cport file='/home/svesan/psy1502_160304.tsp' lib=work;
  select formats ivfdata mbr0 npr3 sosivf1 qivf surv1 bl_covars;
run;


/****



data chk;
  keep outcome trt byear sex art paritet singleton gage  ivf_icsi frozen testis
       entry exit diag_age event pyear lopnr_barn lopnr_mor child_bdat diag_dat
       cens et_dat embryon logpyear;
  length cens 3;
  set ana0(where=(outcome in ('1','2')));
  cens=1-event;
run;

%tor(data=chk, dname=psy1502_ana0, rfile=psy1502_ana0.R,
     class=outcome trt byear sex art paritet singleton gage  ivf_icsi frozen testis,
     var  =entry exit diag_age event pyear lopnr_barn lopnr_mor child_bdat diag_dat et_dat embryon logpyear);

proc summary data=chk nway;
  var event;
  class entry exit cens byear trt;
  output out=aggr1 n=n;
run;
proc freq data=ana0;
where outcome='4' and art='Y';
table event;
run;
****/
/****
proc sql;
  create index diag on npr3;
quit;

proc sql;
  create table cens1(label='Censor due to CP') as
  select lopnr as lopnr_barn, min(diag_dat) as first_diag_dat length=3 format=yymmdd10.
  from npr3
  where substr(diag,1,3) in ('G80','343')
  group by lopnr order by lopnr
  ;
  create table cens2(label='Censor due to ID') as
  select lopnr as lopnr_barn, min(diag_dat) as first_diag_dat length=3 format=yymmdd10.
  from npr3
  where substr(diag,1,3) in ('F70','F71','F72','F73','F74','F75','F76','F77','F78','F79')
  group by lopnr order by lopnr
  ;
;
proc sql;
  create table ana1 as
  select a.*, b.first_diag_dat
  from ana0 as a
  left join cens2 as b
  on a.lopnr_barn=b.lopnr_barn
  ;
run;
***/



*-- Cleanup ------------------------------------------------------------------;
title1;footnote;
proc datasets lib=work mt=data nolist;
  delete _null_;
quit;

*-- End of File --------------------------------------------------------------;

    /****
*-- End of File ;
*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>;

proc cport file='/home/svesan/psy1502_160303.tsp' lib=work;
  select formats ana0 ivfdata mbr0 npr3 sos_ivf qivf;
run;


*-- Calculate #children, #cases, #proportion;
ods output BinomialCLs = b1;
ods listing close;
proc sort data=t1;by trt;run;
proc freq data=t1 ;
  table ott /  nopercent nocol missing binomial(exact) alpha=0.05 out=b2;
  by trt;
run;
ods listing ;

proc transpose data=b2 out=b3;
  var count;
  by trt;
run;

*-- Calculate rate ;

data b4;
  label citxt='Proportion (95%CI)' col1='Number of children' col2='# OCD/TICS/TD';
  merge b1 b3;by trt;
  col1=col1+col2;
  citxt=put(proportion, 5.3)||' ('||put(lowercl, 5.3)||'-'||put(uppercl,5.3)||')';
run;

proc print data=b4 noobs label;
  var trt col1 col2 citxt;
  format col1 col2 comma6.;
  sumvar col1 col2;
run;






proc means data=t1 nway maxdec=0 sum ;
  var pyear ott;
  class trt;
run;

ods graphics on;
proc glimmix data=t1;
  class trt;
  model ott = trt / offset=logpyear dist=poisson link=log;
  lsmeans trt / ilink plots=anom;
  estimate 'IVF frozen vs IVF Std'  trt -1 1 0 0 0 / exp;
  estimate 'ICSI fresh vs IVF Std'  trt -1 0 1 0 0 / exp;
  estimate 'ICSI frozen vs IVF Std' trt -1 0 0 1 0 / exp;
  estimate 'ICSI surg vs IVF Std'   trt -1 0 0 0 1 / exp;
  estimate 'IVF Std vs IVF frozen'  trt  1 -1 0 0 0 / exp;
run;
***/


/**********************
Description of the treatments ... compare with the psy1001 manuscript

data s1;
  retain one 1;
  attrib year length=4 label='Birth Year';
  set sosivf2(keep=et_dat metod child_bdat);
  year=year(child_bdat);
  met=input(metod,8.);

if et_dat>'01jan1982'd and et_dat<'01jan2002'd then do;
  if met=1 then lbl='Standard IVF, stimulerad';
  else if met=2 then lbl='Standard IVF, ostimulerad';
  else if met=3 then lbl='ICSI, farsk ejakulerade spermier';
  else if met=4 then lbl='ICSI, farsk epididymala spermier';
  else if met=5 then lbl='ICSI, farsk testikulara spermier';
  else if met=6 then lbl='Standard IVF, fryst';
  else if met=7 then lbl='ICSI, fryst ejakulerade spermier';
  else if met=8 then lbl='ICSI fryst, annan typ';
  else if met=9 then lbl='ICSI, fryst ospecificerad';
  else if met=0 then lbl='okand';
  else lbl='??';
end;
else if et_dat>'01jan2002'd then do;
  if met=1 then lbl='Standard IVF, stimulerad';
  else if met=2 then lbl='Standard IVF, ostimulerad';
  else if met=3 then lbl='ICSI, farsk ejakulerade spermier';
  else if met=4 then lbl='ICSI, farsk epididymala spermier';
  else if met=5 then lbl='ICSI, farsk testikulara spermier';
  else if met=6 then lbl='Standard IVF, fryst';
  else if met=7 then lbl='ICSI, fryst ejakulerade spermier';
  else if met=8 then lbl='ICSI fryst, annan typ';
  else if met=9 then lbl='IVF efter blastocystoverforing';
  else if met=10 then lbl='ICSI efter blastocystoverforing';
  else lbl='??';
end;
run;

proc summary data=s1 nway;
  var one;
  class year lbl;
  output out=s2 n=count;
run;
proc sort data=s2;by lbl;run;
data s3;
  retain index 0;
  set s2;by lbl;
  if first.lbl then index=index+1;
run;
proc sort data=s3;by year lbl;run;

proc transpose data=s3 out=s4 prefix=t;
  var count;
  id index;
  idlabel lbl;
  by year;
run;

proc print data=s4 noobs label;
  var year t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 ;
  sum year t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 ;
run;

*****/
/****

*--- Check for mother with > 1 father;
proc sql;
  create table v1 as
  select distinct lopnr_kvinna, lopnr_man, etdate
  from ivfdb.qivf1
  order by lopnr_kvinna, lopnr_man
  ;

data v2;
  retain i 0;
  set v1;by lopnr_kvinna;
  if first.lopnr_kvinna then i=1;else i=i+1;
run;

*-- Select women in qivf;
proc sql;
  create table h1 as
  select distinct lopnr_mor
  from qivf1
  where et_dat>.z
  order by lopnr_mor
  ;

*-- Select corresponding women in the MBR with children born after 11jan2007;
  create table h2 as
  select a.lopnr_mor, b.lopnr_barn, b.child_bdat from h1 as a
  join mbr1 as b
  on a.lopnr_mor=b.lopnr_mor
  where b.child_bdat > '11jan2007'd;







*** Number of IVF birth after 2007;
proc sql;
  select byear, count(*)
  from t4
  group by byear
  ;

*-- Check number of OCD cases after qivf;
proc sql;
  create table u0 as select distinct lopnr as lopnr_barn from npr2;

  create table u1 as
  select a.lopnr_barn
  from t4 as a
  join u0 as b
    on a.lopnr_barn=b.lopnr_barn
  ;


title1 'Frequencies of the unique diagnostic codes found in NPR';
title2 'Note: Only one code per individual counted (using first lifelong event)';
proc freq data=npr1;
  table diag;
run;
proc freq data=npr2;
  table diag;
run;

proc sort data=npr2 nodupkey;by lopnr;run;




proc means data=ana0 nway sum maxdec=1;
  var event pyear;
  class trt;
run;

****/

libname in '/home/svesan/ki/AAA/AAA_Research/sasproj/PSY/PSY1001/sastmp/' access=readonly;


proc freq data=ana0;table singleton;run;
