/*-------------------------------------------------------------------------------
# Name:	   TidyData
# Purpose: Show how to fix untidy data using Stata code
# Author:  Tim Essam, Ph.D. / USAID GeoCenter
# Created: 2016/07
# License: MIT
# Notes:   Code for Stata 13 or 14
#-------------------------------------------------------------------------------
*/

clear
capture log close



* Creating Tidy Data
cd "C:/Users/Tim/Documents/TidyData"
log using "TidyData.txt", replace
copy "https://github.com/GeoCenter/resources/blob/master/untidy_data.xlsx?raw=true" untidy_data.xlsx, replace


* Example 1: Merged cells 
***********************************************************************************
/* Import the file, use the firstrow option to have the first 
   row read in as variables
*/
import excel untidy_data.xlsx, sheet("merged_cells") firstrow 

list
/* Notice that Stata does not assign the value from the merged cells to 
   multiple variable names. Instead, we have the variable names in the first
   row of the dataframe. So we'll need to create some new variable names
   based on the contents of the first row. But, State does not like variable
   names to start with numbers so we will have to use a combination of strings
   and numbers. */
 
* Create a loop to iterate over all the variables in data frame.
foreach x of varlist _all {
	/* First, create a place holder variable called newnew that takes the
	   value of the 1st observation in the dataframe */
	local newname  = `x'[1]
	
	/* Convert each value in the newname local into an allowed Stata name */
	local newname2 = strtoname("`newname'")
	
	/* Finally, rename each variable */
	rename `x' `newname2'
}
*end

* Drop the 1st row as this information is now caputred in the variable names
drop in 1

* Now, rename the variables 
rename (_2012 _2014) (cholera_cases_2012 cholera_cases_2014)

* create a unique id based on the region
egen id = group(region)

* Reshape the data into a fully tidy dataset
reshape long cholera_cases_@, i(id) j(year)
rename cholera_cases_ cholera_cases

egen uniqueid = group(id year)
la var year "year"
la var region "Ethiopia region (administrative unit 1)"
la var cholera_cases "Number of cholera cases reported"

* write the data frame to the window
clist, noo

* optional -- if you want to save the data
save "tidyData_ex1.dta", replace





* Example 2: Multiple values per cell 
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("multiple_values_cell") firstrow 

* Use the split command with a parse option (parsing on commas) to creat new variables
split region, p(,)

* Create unique id for projects and reshape the data in fully tidy dataset
rename region admin1_old
egen projectid = group(project)

* Reshape the data frame into a tidy data set and drop extra observations for which
* the admin1 region is missing
reshape long region@, i(projectid) j(regionCode)
drop if region == ""

egen uniqueid = group(projectid regionCode)
isid uniqueid

* Add a few variable labels
la var regionCode "region code"
la var region "Ethiopia region (administrative unit 1)"
clist, noo




* Example 3: No unique id
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("no_unique_id") firstrow

* Check if the combination of project and region make a variable unique
isid project region

egen id = group(project region) 
sort id
clist, noo



* Example 4: Variable names not meaningful
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("varnames_not_meaningful") firstrow 

rename (variable1 variable2) (cholera TB)
la var cholera "Number of cholera cases reported"
la var TB "Number of tuberculosis cases reported"

egen regionid = group(region)
isid regionid
clist, noo






* Example 5: Variable contain measurements
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("varnames_contain_measurement") firstrow 
rename (cholera C) (cholera2012 cholera2014)

egen regionid = group(region)
reshape long cholera@, i(region) j(year)

egen id = group(regionid year)
isid id
clist, noo



* Example 5: Variable contain measurements
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("inconsistent_data") firstrow 

* Notice that everything imports as a string b/c of inconsistencies
d
clist, noo

* First, let's remove row 4 as this is duplicative of row 3
drop if project == "project3" & start_date == "01012014"

* now let's fix the start_dates
replace start_date = "01-01-16" if project == "project3"
replace start_date = "25-12-16" if project == "project2"

* Split out dates into components
split start_date, p(-) destring
rename (start_date1 start_date2 start_date3)(day month year)
replace year = year + 2000
drop start_date

* Use Stata's date function to convert the values to dates
* I always forgot how to do this so I visit: http://www.ats.ucla.edu/stat/stata/modules/dates.htm
g start_date = mdy(month, day, year)
format start_date %td
list

* Next, let's correct the funding amounts; First, strip out special characters
replace funding = subinstr(funding, "$", "",.)
replace funding = subinstr(funding, "M", "",.)

* Destring to convert to numeric values
g funding2 = real(funding)
replace funding2 = 75*1000000 if funding2 == 75

* Fix up the region names
tab region
replace region = "Afar" if regexm(region, "Affar")

* Label all of the variables
la var day 	 "start date day"
la var month "start date month"
la var year  "start date year"
la var start_date "start_date"
drop funding
ren funding2 funding
la var funding "total funding by project"

* Format the funding variable for readability below
format funding %14.0fc

* Create a unique id for projects
egen projectid = group(project)
clist, noo




* Example 7: Missing value not explicit 
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("missing_values") firstrow 

describe

* notice that the TB_cases variable read in as strings, "-" should be 0
* fix this up and then destring the cases; 
* NOTE: Stata treats blank cells as missing values, "." represents a missing value;
replace TB_cases = subinstr(TB_cases, "-", "0",.)
g TB_cases_num = real(TB_cases)

misstable sum TB_cases_num

* Create a unique ID and label values
egen regionid = group(region)
la var TB_cases_num "tuberculosis cases"

order region regionid TB_cases_num cholera_cases
clist, noo



* Example 8: Not computer readable
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("not_comp_readable") firstrow 

list
* Notice that all the cells are blank -- Stata doesn't read colors

rename (A projectstatus) (project status)
tostring status, replace
replace status = "kinda okay" if inlist(project, "project1", "project3")
replace status = "good" if project == "project2"
replace status = "really not okay" if project == "project4"

* Now, let's encode the status so it can be used as a factor
encode status, gen(status_enc)
tab status_enc, nolabel
tab status_enc

* create a unique project id
egen projectid = group(project)
isid projectid

la var project "project number"
clist, noo




* Example 9: Undocumented, vague data
***********************************************************************************
clear
import excel untidy_data.xlsx, sheet("undocumented") firstrow 
clist, noo

* Need to add value labels to the region so we know what 5, 1, and 7 mean
label define reglab 1 "Oromia" 5 "Afar" 7 "Somali"
label values region reglab
tab region
tab region, nol

* Label variables
la var funding "funding in USD"
la var project "project numbeR"
la var region "Ethiopia region"

* Add a note about the funding variable
notes funding: funding amount is in 2015 USD

* create a unique project id
egen projectid = group(project)
isid projectid
clist, noo


capture log close
