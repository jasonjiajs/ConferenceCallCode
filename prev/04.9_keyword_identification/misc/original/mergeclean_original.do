/* please change the directory if you are running the code on the server*/

import excel "K:\CriCount\TotalCircnew.xlsx", sheet("Sheet1") firstrow clear
drop if Keywords == "capm" & !ustrregexm(Paragraph,"[ \,\.\?\;\[\-\(]capm[ \,\.\?\;\]\-\)]",1)
drop if Keywords == "irr" & !ustrregexm(Paragraph,"[ \,\.\?\;\[\-\(]irr[ \,\.\?\;\]\-\)]",1)
drop if Keywords == "occ" & !ustrregexm(Paragraph,"[ \,\.\?\;\[\-\(]occ[ \,\.\?\;\]\-\)]",1)
drop if Keywords == "roic" & !ustrregexm(Paragraph,"[ \,\.\?\;\[\-\(]roic[ \,\.\?\;\]\-\)]",1)
drop if Keywords == "wacc" & !ustrregexm(Paragraph,"[ \,\.\?\;\[\-\(]wacc[ \,\.\?\;\]\-\)]",1)


bysort Paragraph: gen obs = _N
tab obs

 
gen key_ident = 1 if Keywords == "interest rate" | Keywords == "cost of debt"
replace key_ident = 0 if missing(key_ident)
bysort Paragraph: egen q_count = sum(key_ident)

drop if obs>1 & (Keywords == "interest rate" | Keywords == "cost of debt") & (q_count<obs)

drop obs key_ident q_count

duplicates drop Paragraph, force

tab Keywords

**** now merge with other information ****
keep Keywords Paragraph Report File

tempfile para
save `para', replace


**** merge with other sources ***
import delimited "K:\CallCsv\CC_ListTotal.csv", case(preserve) clear 
keep Title Subtitle Date Report ticker gvkey_t gvkey_h gvkey_c gvkey prob gues_by_dticker gues_name countryid country 

tempfile cc1
save `cc1', replace

***** merge with other sources *** 
import delimited "K:\NewConfCall\csv\CC_List.csv", case(preserve) clear 
keep Title Subtitle Date Report ticker gvkey_t gvkey_h gvkey_c gvkey prob gues_by_dticker gues_name countryid country 
duplicates drop


tempfile cc2
save `cc2', replace

use `cc1', clear
merge 1:1 Report using `cc2'  /* 1 merged, choose the older one*/

drop _merge


merge 1:m Report using `para'

drop if _merge == 1
drop _merge


*** sort by gvkey date name ***
sort gvkey Date gues_name Title

order Keywords Paragraph Date gvkey Title Subtitle
order Report, after(ticker)

export excel using "K:\CriCount\cric1_newtotal.xlsx", firstrow(variables)


