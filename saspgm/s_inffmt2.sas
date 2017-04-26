data ??;
  length label $60 start end $6;
  retain fmtname 'INFDFMT' type 'char' ;
  set ??;

/* The code below work GIVEN the correct diagnoses have been selecte first        */

/*ICD7 from 1964 to 1968:                                                        */
if female_inf=1 and icd=7 then do;
  if diag = '275' then label='Ovarian dysfunction (including PCOS)     
  else if diag = '215' then label='Endometriosis                                        
  else if diag = '634' then label='Absent/Scanty or scanty menstruation
  else if diag = '636' then label='Female Infertility                 
end;
else if female_inf=1 and icd=8 then do;
/*ICD8  from 1969 to 1986:                                                       */
  else if diag = '256' then label='Ovarian dysfunction (including PCOS)     
  else if diag = '625,3' then label='Endometriosis                                        
  else if diag = '626' then label='Absent/Scanty menstruation
  else if diag = '628' then label='Female Infertility
end;
else if female_inf=1 and icd=9 then do;

/*ICD9  from 1987 to 1996:                                                       */
  else if diag = '256' then label='Ovarian dysfunction (including PCOS)     
  else if diag = '617' then label='Endometriosis                                        
  else if diag = '626' then label='Absent/Scanty menstruation
  else if diag = '628A' then label='Female Infertility- Anovulatory
  else if diag = '628C' then label='Female Infertility- Tubal
  else if diag = '628D' then label='Female Infertility- Uterine
  else if diag = '628E' then label='Female Infertility- Cervical
  else if diag = '628W' then label='Female Infertility- Other specified
  else if diag = '628X' then label='Female Infertility- Unspecified
  else if diag = '628' then label='Female Infertility
end;
else if female_inf=1 and icd=10 then do;
                 
/*ICD10 from 1997 to 2010 (no commas in code):                                   */
  else if diag = 'E28' then label='Ovarian dysfunction (including PCOS)     
  else if diag = 'N80' then label='Endometriosis                                        
  else if diag = 'N91' then label='Absent/Scanty menstruation
  else if diag = 'N97' then label='Female Infertility'
  else if diag = 'N970' then label='Female Infertility - Anovulatory'
  else if diag = 'N971' then label='Female Infertility - Tubal'
  else if diag = 'N972' then label='Female Infertility - Uterine'
  else if diag = 'N973' then label='Female Infertility - Cervical'
  else if diag = 'N974' then label='Female Infertility - Male factor'
  else if diag = 'N978' then label='Female Infertility - other specified'
  else if diag = 'N978A' then label='Female Infertility - Immunological'
  else if diag = 'N978B' then label='Female Infertility - Social factors'
  else if diag = 'N978C' then label='Female Infertility - Unexplained'
  else if diag = 'N978D' then label='Female Infertility - Endometriosis'
  else if diag = 'N978W' then label='Female Infertility - Other specified'
  else if diag = 'N979' then label='Female Infertility - Unspecified'
end;

/*MALE RELATED PROBLEMS */
if male_inf=1 and icd=7 then do;

ICD7  from 1964 to 1968:*/                                                   
else if diag = '616' then label='Male infertility
else if diag = '272,1' then label='Hypopituitarism
else if diag = '276,0' then label='Testicular hypofunction
else if diag = '462,0' then label='Varicocele
else if diag = '757,0' then label='Cryptorchidism
else if diag = '757,21' then label='Hypospadia
end;
else if male_inf=1 and icd=8 then do;

/*ICD8  from 1969 to 1986:                                                   */
else if diag = '606,99' then label='Male infertility
else if diag = '253,10' then label='Hypopituitarism
else if diag = '257,10' then label='Testicular hypofunction
else if diag = '456,10' then label='Varicocele
else if diag = '607,70' then label='Testicular torsion
else if diag = '752,10' then label='Cryptorchidism
else if diag = '752,2' then label='Hypospadia
end;
else if male_inf=1 and icd=9 then do;

/* ICD9  from 1987 to 1996:                                                  */
else if diag = '606' then label='Male infertility
else if diag = '253C' then label='Hypopituitarism
else if diag = '257C' then label='Testicular hypofunction
else if diag = '257B' then label='Testicular hypofunction, iatrogenic
else if diag = '456E' then label='Varicocele
else if diag = '608C' then label='Testicular torsion
else if diag = '752F' then label='Cryptorchidism
else if diag = '752G' then label='Hypospadia and epispadia
end;
else if male_inf=1 and icd=10 then do;

/* ICD10 from 1997 to 2010 (no commas in code):                              */
else if diag = 'N46' then label='Male infertility 
else if diag = 'E230' then label='Hypopituitarism
else if diag = 'E291' then label='Testicular hypofunction
else if diag = 'E895' then label='Testicular hypofunction, iatrogenic
else if diag = 'I861' then label='Varicocele
else if diag = 'N44' then label='Testicular torsion
else if diag = 'Q53' then label='Cryptorchidism
else if diag = 'Q54' then label='Hypospadia
end;

start=diag;
end  =start;

run;


proc format cntlin=? lib=work;run;