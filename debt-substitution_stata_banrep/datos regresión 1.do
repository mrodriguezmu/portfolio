********************************************************************************
*************************** BASES DE DATOS REGRESIÓN 1 *************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"


**# BASE GENERAL

// llamamos la base de datos del merge de la 341 con EE (en flujo)

use "$input\Merge_341_EE_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// collapsamos todo a nivel firma-tiempo (recordemos que los datos de la EE ya estan a nivel firma-tiempo, pero los de 341 están a nivel firma-banco-tiempo)

collapse (rawsum) capital_USD capitalme_USD capitalml_USD (lastnm) valor capitalme_USD_EE (max) insularidad_definitiva, by(Fecha_tri identif)

// unificamos la variable de crédito local en moneda extranjera. Recordemos que tenemos dos fuentes para esta variable: 341 y EE. Tomamos como fuente principal los datos de 341, pero, para las observaciones que no cuentan con este dato por parte de la 341, pero si para EE, tomamos los datos de EE

replace capitalme_USD = capitalme_USD_EE if capitalme_USD == 0 & capitalme_USD_EE != 0

// generamos la variable de año

gen year = yofd(dofq(Fecha_tri))

// establecemos el panel 

egen firma = group(identif)

xtset firma Fecha_tri

// generamos el cambio en las variables de crédito local (en moneda local, en moneda extranjera y total)

bys firma (Fecha_tri): gen var_capital_USD = capital_USD - L1.capital_USD  // cambio del credito local total

bys firma (Fecha_tri): gen var_capitalme_USD = capitalme_USD - L1.capitalme_USD  // cambio del credito local en moneda extranjera

bys firma (Fecha_tri): gen var_capitalml_USD = capitalml_USD - L1.capitalml_USD  // cambio del credito local en moneda local

// reemplazamos los missings generados por su valor correspondiente

replace var_capital_USD = 0 if var_capital_USD == . & capital_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capital_USD = capital_USD if var_capital_USD == . & capital_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalme_USD = 0 if var_capitalme_USD == . & capitalme_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalme_USD = capitalme_USD if var_capitalme_USD == . & capitalme_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalml_USD = 0 if var_capitalml_USD  == . & capitalml_USD  == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalml_USD = capitalml if var_capitalml_USD  == . & capitalml_USD  != 0 & Fecha_tri != yq(2000, 1)

// vemos el reporte del panel 

tsreport  Fecha_tri,  p 

// generamos los lags y los leads de las distintas variables de crédito 

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
    forvalues num=1(1)4{
		bys firma (Fecha_tri): gen lag_`num'_`var' = L`num'.`var'
		bys firma (Fecha_tri): gen lead_`num'_`var' = F`num'.`var'
		
	}
}

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD{
    replace lag_1_`var' = 0 if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	replace lead_1_`var' = 0 if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	replace lag_2_`var' = 0 if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	replace lead_2_`var' = 0 if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	replace lag_3_`var' = 0 if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	replace lead_3_`var' = 0 if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	replace lag_4_`var' = 0 if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	replace lead_4_`var' = 0 if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

// generamos los cambios acumulados para las variables de crédito local 

foreach var in capital_USD capitalme_USD capitalml_USD {
	gen acum_1_`var' = lead_1_`var' - lag_1_`var'
	
	gen acum_2_`var' = lead_2_`var' - lag_1_`var'
	
	gen acum_3_`var' = lead_3_`var' - lag_1_`var'
	
	gen acum_4_`var' = lead_4_`var' - lag_1_`var'
}

// guardamos la base de datos

save "$input\base_primera_reg_nuevo_credito1_lags_y_leads_05_08_2024.dta", replace // base de datos de nivel firma-tiempo que contiene todas las variables que necesitaremos para las distintas versiones de la regresión 1.

// balanceamos año a año para aquellas observaciones de insularidades 4 o 5 (ya que son las únicas que pueden tener crédito externo)

forvalues year=2000(1)2019{
    use "$input\base_primera_reg_nuevo_credito1_lags_y_leads_05_08_2024.dta", clear
    keep if year==`year'
	keep if insularidad_definitiva == 4 | insularidad_definitiva == 5 
	
	*completar panel
	drop firma
	egen firma=group(identif)
	xtset firma Fecha_tri 
	tsreport  Fecha_tri,  p 
	tsfill, full 
	
	*recuperamos los nits perdidos al balancear
	preserve
	keep if identif != ""
	keep identif firma
	duplicates drop
	rename identif nom
	tempfile nits_merge
	save `nits_merge' 
	restore 
	
	*Mergeamos
	merge m:1 firma using `nits_merge' 
	drop _merge
	replace identif = nom if identif == ""
	drop nom
	save "$input\balanceado_anual_nuevo_credito1_lags_leads_`year'.dta", replace // guardamos una base balanceada para cada año
}

// appendeamos las distintas bases anuales balanceadas

forvalues year=2000(1)2019{
    if `year'==2000{
	    use  "$input\balanceado_anual_nuevo_credito1_lags_leads_`year'.dta", clear
		save "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V1.dta", replace
		continue
	}
	use  "$input\balanceado_anual_nuevo_credito1_lags_leads_`year'.dta", clear
	append using "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V1.dta"
	save "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V1.dta", replace // esta base contiene el balanceo anual para las observaciones de insularidades 4 y 5 para cada año.
}

// llamamos la base con balanceo anual

use "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V1.dta", clear

// volvemos a generar la variable de firma para el panel 

drop firma

egen firma = group(identif)

xtset firma Fecha_tri

// reemplazamos los missings generados con el balanceo por su valor real

replace capital_USD=0 if capital_USD==.
replace capitalme_USD=0 if capitalme_USD==.
replace capitalml_USD =0 if capitalml_USD ==.
replace valor=0 if valor==.

bys firma (Fecha_tri): replace var_capitalme_USD= capitalme_USD - L1.capitalme_USD if var_capitalme_USD==. & Fecha_tri != yq(2000, 1)
bys firma (Fecha_tri): replace var_capital_USD= capital_USD - L1.capital_USD if var_capital_USD==. & Fecha_tri != yq(2000, 1)
bys firma (Fecha_tri): replace var_capitalml_USD= capitalml - L1.capitalml if var_capitalml_USD==. & Fecha_tri != yq(2000, 1)

replace var_capitalme_USD=0 if var_capitalme_USD==. & Fecha_tri != yq(2000, 1)
replace var_capital_USD=0 if var_capital_USD==. & Fecha_tri != yq(2000, 1)
replace var_capitalml_USD=0 if var_capitalml_USD==. & Fecha_tri != yq(2000, 1)

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD{
    bys firma (Fecha_tri): replace lag_1_`var' = L1.`var' if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	bys firma (Fecha_tri): replace lead_1_`var' = F1.`var' if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	bys firma (Fecha_tri): replace lag_2_`var' = L2.`var' if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	bys firma (Fecha_tri): replace lead_2_`var' = F2.`var' if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	bys firma (Fecha_tri): replace lag_3_`var' = L3.`var' if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	bys firma (Fecha_tri): replace lead_3_`var' = F3.`var' if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	bys firma (Fecha_tri): replace lag_4_`var' = L4.`var' if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	bys firma (Fecha_tri): replace lead_4_`var' = F4.`var' if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD{
    replace lag_1_`var' = 0 if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	replace lead_1_`var' = 0 if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	replace lag_2_`var' = 0 if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	replace lead_2_`var' = 0 if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	replace lag_3_`var' = 0 if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	replace lead_3_`var' = 0 if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	replace lag_4_`var' = 0 if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	replace lead_4_`var' = 0 if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

foreach var in capital_USD capitalme_USD capitalml_USD {
	replace acum_1_`var' = lead_1_`var' - lag_1_`var'
	
	replace acum_2_`var' = lead_2_`var' - lag_1_`var'
	
	replace acum_3_`var' = lead_3_`var' - lag_1_`var'
	
	replace acum_4_`var' = lead_4_`var' - lag_1_`var'
}

// guardamos la base de datos 

save "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V2.dta", replace // base de datos con balanceo anual y sin missings. Esta base de datos será el punto de partida para las distintas variaciones de la regresión 1.


**# BASE PARA REG CON CRÉDITO LOCAL EN MONEDA EXTRANJERA COMO VARIABLE DEPENDIENTE 

// llamamos la base de datos con balanceo anual y sin missings 

use "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V2.dta", clear

// queremos que la base solo tenga información de firmas que sacaron crédito externo Y crédito local en dólares en un margen de cuatro trimestres. Para ello generamos una condición que será igual a 1 para todas las observaciones que nos interesan

// generamos la variable de condición

gen condicion = 0

// la condición la cumplen las observaciones para las cuales la firma sacó tanto crédito externo como crédito local en dólares en el mismo trimestre

replace condicion = 1 if valor != 0 & var_capitalme_USD != 0 & var_capitalme_USD != . 

// la condición la cumplen las observaciones para las cuales la firma sacó crédito externo en el trimestre actual Y crédito local en dólares en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if valor != 0 & lag_`num'_var_capitalme_USD != 0 & lag_`num'_var_capitalme_USD != .
	replace condicion = 1 if valor != 0 & lead_`num'_var_capitalme_USD != 0 & lead_`num'_var_capitalme_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en dólares en el trimestre actual Y crédito externo en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if var_capitalme_USD != 0 & var_capitalme_USD != . & lag_`num'_valor != 0 & lag_`num'_valor != .
	replace condicion = 1 if var_capitalme_USD != 0 & var_capitalme_USD != . & lead_`num'_valor != 0 & lead_`num'_valor != .
	
}

// la condición la cumplen las observaciones para las cuales, si bien la firma no sacó crédito externo ni crédito local en dólares en el trimestre t, si sacó crédito local en dólares en t-1 Y crédito externo en t+2, así como las observaciones en las que la firma sacó crédito externo en t-1 Y crédito local en dólares en t+2

forvalues num=1(1)2{
    
	local val = abs(`num' - 3)

	replace condicion = 1 if lag_`num'_var_capitalme_USD != 0 & lag_`num'_var_capitalme_USD != . & lead_`val'_valor != 0 & lead_`val'_valor != .
	
	replace condicion = 1 if lag_`num'_valor != 0 & lag_`num'_valor != . & lead_`val'_var_capitalme_USD != 0 & lead_`val'_var_capitalme_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en dólares en t-1 Y crédito externo en t+1, así como las observaciones en las que la firma sacó crédito externo en t-1 Y crédito local en dólares en t+1

forvalues num=1(1)1{
    
	local val = abs(`num' - 2)

	replace condicion = 1 if lag_`num'_var_capitalme_USD != 0 & lag_`num'_var_capitalme_USD != . & lead_`val'_valor != 0 & lead_`val'_valor != .
	
	replace condicion = 1 if lag_`num'_valor != 0 & lag_`num'_valor != . & lead_`val'_var_capitalme_USD != 0 & lead_`val'_var_capitalme_USD != .
	
}

// conservamos solamente las observaciones que cumplen la condición 

keep if condicion == 1

// renombramos la variable de cambio en el crédito local en dólares (esto para cuando corramos las regresiones)

rename var_capitalme_USD acum_0_capitalme_USD

// guardamos esta base de datos 

save "$input\base_reg_1_mon_extranj.dta", replace // base de datos que contiene las observaciones que cumplen la condición para las firmas de haber sacado crédito externo y crédito local en dólares en un margen de cuatro trimestres 

// lo siguiente es recuperar las insularidades para las observaciones generadas al balancear anualmente

// llamamos la base generada arriba

use "$input\base_reg_1_mon_extranj.dta", clear

// recuperamos la variable "identif" (nits de las firmas) para las observaciones generadas al balancear 

preserve

keep identif firma

drop if identif == ""

duplicates drop

rename identif nits

tempfile nits_merge
save `nits_merge'

restore

merge m:1 firma using `nits_merge'

drop _merge

replace identif = nits if identif == ""

drop nits

// renombramos la variable de insularidad 

rename insularidad_definitiva insularidad_definitiva_1

// mergeamos con la base de datos que contiene las insularidades 

merge 1:1 identif Fecha_tri using "$input\Insularidades_definitivo_EE_saldos.dta"

// eliminamos las observaciones que no mergean de la base de insularidades

drop if _merge == 2

drop _merge

// recuperamos la variable de insularidad

replace insularidad_definitiva_1 = insularidad_definitiva if insularidad_definitiva_1 == .

// eliminamos la variable de insularidad proveniente de la base de insularidades, ya que ya no la necesitamos

drop insularidad_definitiva

// volvemos a renombrar la variable de insularidad de nuestra base de datos

rename insularidad_definitiva_1 insularidad_definitiva

// con lo anterior recuperamos la insularidad para aquellas observaciones que se encontraban en la base de datos de saldos. Sin embargo, para las observaciones que no se encuentran en esa base de datos no fue posible recuperar la insularidad (ya que no contaban con una insularidad en primer lugar). Por ello, vamos a generar la insularidad para aquellas observaciones

// mergeamos con la base de datos que contiene las variables para generar la insularidad

merge 1:1 identif Fecha_tri using "$input\variables_para_generar_insularidades_firma_tiempo.dta"

// eliminamos las observaciones que no mergean de la base using 

drop if _merge == 2

drop _merge

// reemplazamos por cero los missings (de las observaciones que no mergearon)

replace ralacion_bancaria = 0 if ralacion_bancaria == .
replace credito_usd_locales = 0 if credito_usd_locales == .
replace Insularidad_3_EE = 0 if Insularidad_3_EE == .
replace Insularidad_4_EE = 0 if Insularidad_4_EE == .
replace Insularidad_5_EE = 0 if Insularidad_5_EE == .

// generamos el panel

xtset firma Fecha_tri

// generamos los lags (hasta tres periodos atrás) de las variables con las que generaremos las insularidades

forvalues x=0(1)3{
    di `x' 
	bys firma : gen lag_ralacion_bancaria_`x'=L`x'.ralacion_bancaria
	bys firma : gen lag_credito_usd_locales_`x'=L`x'.credito_usd_locales
	bys firma : gen lag_Insularidad_3_EE_`x'=L`x'.Insularidad_3_EE
	bys firma : gen lag_Insularidad_4_EE_`x'=L`x'.Insularidad_4_EE
	bys firma : gen lag_Insularidad_5_EE_`x'=L`x'.Insularidad_5_EE
}

// generamos las insularidades

// insularidad 1

gen Insularidad_1_341=0
replace  Insularidad_1_341=1 if lag_ralacion_bancaria_0==1 | lag_ralacion_bancaria_1==1 | lag_ralacion_bancaria_2==1 | lag_ralacion_bancaria_3==1

// insularidad 2

gen Insularidad_2_341=0
replace Insularidad_2_341=1 if lag_ralacion_bancaria_0>1 | lag_ralacion_bancaria_1>1 | lag_ralacion_bancaria_2>1 | lag_ralacion_bancaria_3>1

// insularidad 3

gen Insularidad_3_341=0
replace Insularidad_3_341=1 if (lag_credito_usd_locales_0>0 & lag_credito_usd_locales_0 != .) | (lag_credito_usd_locales_1>0 & lag_credito_usd_locales_1!=.)  | (lag_credito_usd_locales_2>0 & lag_credito_usd_locales_2!= .) | (lag_credito_usd_locales_3>0 & lag_credito_usd_locales_3!=.) 

drop Insularidad_3_EE_completa
gen Insularidad_3_EE_completa=0
replace Insularidad_3_EE_completa=1 if lag_Insularidad_3_EE_0==1 | lag_Insularidad_3_EE_1==1 | lag_Insularidad_3_EE_2==1 | lag_Insularidad_3_EE_3==1

gen Insularidad_3_EE_341=0
replace Insularidad_3_EE_341=1 if Insularidad_3_EE_completa==1 | Insularidad_3_341==1

// insularidad 4

gen Insularidad_4_EE_completa=0
replace Insularidad_4_EE_completa=1 if lag_Insularidad_4_EE_0==1 | lag_Insularidad_4_EE_1==1 | lag_Insularidad_4_EE_2==1 | lag_Insularidad_4_EE_3==1

// insularidad 5

gen Insularidad_5_EE_completa=0
replace Insularidad_5_EE_completa=1 if lag_Insularidad_5_EE_0==1 | lag_Insularidad_5_EE_1==1 | lag_Insularidad_5_EE_2==1 | lag_Insularidad_5_EE_3==1

// renombramos 

rename Insularidad_1_341  Insularidad_1_rec
rename Insularidad_2_341  Insularidad_2_rec
rename Insularidad_3_EE_341 Insularidad_3_rec
rename Insularidad_4_EE_completa Insularidad_4_rec
rename Insularidad_5_EE_completa Insularidad_5_rec

// generamos la insularidad definitiva recuperada 

gen insularidad_definitiva_rec=.
replace insularidad_definitiva_rec=1 if Insularidad_1_rec==1
replace insularidad_definitiva_rec=2 if Insularidad_2_rec ==1
replace insularidad_definitiva_rec=3 if Insularidad_3_rec==1
replace insularidad_definitiva_rec=4 if Insularidad_4_rec==1
replace insularidad_definitiva_rec=5 if Insularidad_5_rec==1

// reemplazamos la insularidad definitiva por la recuperada solamente para aquellas observaciones con missing

replace insularidad_definitiva = insularidad_definitiva_rec if insularidad_definitiva == .

// por las diferencias entre cómo se generan las insularidad y cómo se define la condición de las observaciones que hacen parte de esta base de datos, se colan un 1% de observaciones de insularidades distintas a 4 y 5. Por ello, vamos a deshacernos de esas observaciones 

keep if insularidad_definitiva == 4 |insularidad_definitiva == 5

// eliminamos las variables que ya no necesitamos 

drop *_rec lag_Insularidad* lag_credito_usd_locales* lag_ralacion_bancaria*

// guardamos la base de datos 

save "$input\base_reg_1_mon_extranj_insu.dta", replace // base de datos para la regresión 1 que toma como variable dependiente el crédito local en dólares 


**# BASE PARA REG CON CRÉDITO LOCAL EN MONEDA LOCAL

// llamamos la base de datos con balanceo anual y sin missings 

use "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V2.dta", clear

// queremos que la base solo tenga información de firmas que sacaron crédito externo Y crédito local en pesos en un margen de cuatro trimestres. Para ello generamos una condición que será igual a 1 para todas las observaciones que nos interesan

// generamos la variable de condición

gen condicion = 0

// la condición la cumplen las observaciones para las cuales la firma sacó tanto crédito externo como crédito local en pesos en el mismo trimestre

replace condicion = 1 if valor != 0 & var_capitalml_USD != 0 & var_capitalml_USD != .  

// la condición la cumplen las observaciones para las cuales la firma sacó crédito externo en el trimestre actual Y crédito local en pesos en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if valor != 0 & lag_`num'_var_capitalml_USD != 0 & lag_`num'_var_capitalml_USD != .
	replace condicion = 1 if valor != 0 & lead_`num'_var_capitalml_USD != 0 & lead_`num'_var_capitalml_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en pesos en el trimestre actual Y crédito externo en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if var_capitalml_USD != 0 & var_capitalml_USD != . & lag_`num'_valor != 0 & lag_`num'_valor != .
	replace condicion = 1 if var_capitalml_USD != 0 & var_capitalml_USD != . & lead_`num'_valor != 0 & lead_`num'_valor != .
	
}

// la condición la cumplen las observaciones para las cuales, si bien la firma no sacó crédito externo ni crédito local en pesos en el trimestre t, si sacó crédito local en pesos en t-1 Y crédito externo en t+2, así como las observaciones en las que la firma sacó crédito externo en t-1 Y crédito local en pesos en t+2

forvalues num=1(1)2{
    
	local val = abs(`num' - 3)

	replace condicion = 1 if lag_`num'_var_capitalml_USD != 0 & lag_`num'_var_capitalml_USD != . & lead_`val'_valor != 0 & lead_`val'_valor != .
	
	replace condicion = 1 if lag_`num'_valor != 0 & lag_`num'_valor != . & lead_`val'_var_capitalml_USD != 0 & lead_`val'_var_capitalml_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en pesos en t-1 Y crédito externo en t+1, así como las observaciones en las que la firma sacó crédito externo en t-1 Y crédito local en pesos en t+1

forvalues num=1(1)1{
    
	local val = abs(`num' - 2)

	replace condicion = 1 if lag_`num'_var_capitalml_USD != 0 & lag_`num'_var_capitalml_USD != . & lead_`val'_valor != 0 & lead_`val'_valor != .
	
	replace condicion = 1 if lag_`num'_valor != 0 & lag_`num'_valor != . & lead_`val'_var_capitalml_USD != 0 & lead_`val'_var_capitalml_USD != .
	
}

// conservamos solamente las observaciones que cumplen la condición 

keep if condicion == 1

// renombramos la variable de cambio en el crédito local en pesos (esto para cuando corramos las regresiones)

rename var_capitalml_USD acum_0_capitalml_USD

// guardamos esta base de datos 

save "$input\base_reg_1_mon_local.dta", replace // base de datos que contiene las observaciones que cumplen la condición para las firmas de haber sacado crédito externo y crédito local en pesos en un margen de cuatro trimestres 

// lo siguiente es recuperar las insularidades para las observaciones generadas al balancear anualmente

// llamamos la base generada arriba

use "$input\base_reg_1_mon_local.dta", clear

// recuperamos la variable "identif" (nits de las firmas) para las observaciones generadas al balancear 

preserve

keep identif firma

drop if identif == ""

duplicates drop

rename identif nits

tempfile nits_merge
save `nits_merge'

restore

merge m:1 firma using `nits_merge'

drop _merge

replace identif = nits if identif == ""

drop nits

// renombramos la variable de insularidad 

rename insularidad_definitiva insularidad_definitiva_1

// mergeamos con la base de datos que contiene las insularidades 

merge 1:1 identif Fecha_tri using "$input\Insularidades_definitivo_EE_saldos.dta"

// eliminamos las observaciones que no mergean de la base de insularidades

drop if _merge == 2

drop _merge

// recuperamos la variable de insularidad

replace insularidad_definitiva_1 = insularidad_definitiva if insularidad_definitiva_1 == .

// eliminamos la variable de insularidad proveniente de la base de insularidades, ya que ya no la necesitamos

drop insularidad_definitiva

// volvemos a renombrar la variable de insularidad de nuestra base de datos

rename insularidad_definitiva_1 insularidad_definitiva

// con lo anterior recuperamos la insularidad para aquellas observaciones que se encontraban en la base de datos de saldos. Sin embargo, para las observaciones que no se encuentran en esa base de datos no fue posible recuperar la insularidad (ya que no contaban con una insularidad en primer lugar). Por ello, vamos a generar la insularidad para aquellas observaciones

// mergeamos con la base de datos que contiene las variables para generar la insularidad

merge 1:1 identif Fecha_tri using "$input\variables_para_generar_insularidades_firma_tiempo.dta"

// eliminamos las observaciones que no mergean de la base using 

drop if _merge == 2

drop _merge

// reemplazamos por cero los missings (de las observaciones que no mergearon)

replace ralacion_bancaria = 0 if ralacion_bancaria == .
replace credito_usd_locales = 0 if credito_usd_locales == .
replace Insularidad_3_EE = 0 if Insularidad_3_EE == .
replace Insularidad_4_EE = 0 if Insularidad_4_EE == .
replace Insularidad_5_EE = 0 if Insularidad_5_EE == .

// generamos el panel

xtset firma Fecha_tri

// generamos los lags (hasta tres periodos atrás) de las variables con las que generaremos las insularidades

forvalues x=0(1)3{
    di `x' 
	bys firma : gen lag_ralacion_bancaria_`x'=L`x'.ralacion_bancaria
	bys firma : gen lag_credito_usd_locales_`x'=L`x'.credito_usd_locales
	bys firma : gen lag_Insularidad_3_EE_`x'=L`x'.Insularidad_3_EE
	bys firma : gen lag_Insularidad_4_EE_`x'=L`x'.Insularidad_4_EE
	bys firma : gen lag_Insularidad_5_EE_`x'=L`x'.Insularidad_5_EE
}

// generamos las insularidades

// insularidad 1

gen Insularidad_1_341=0
replace  Insularidad_1_341=1 if lag_ralacion_bancaria_0==1 | lag_ralacion_bancaria_1==1 | lag_ralacion_bancaria_2==1 | lag_ralacion_bancaria_3==1

// insularidad 2

gen Insularidad_2_341=0
replace Insularidad_2_341=1 if lag_ralacion_bancaria_0>1 | lag_ralacion_bancaria_1>1 | lag_ralacion_bancaria_2>1 | lag_ralacion_bancaria_3>1

// insularidad 3

gen Insularidad_3_341=0
replace Insularidad_3_341=1 if (lag_credito_usd_locales_0>0 & lag_credito_usd_locales_0 != .) | (lag_credito_usd_locales_1>0 & lag_credito_usd_locales_1!=.)  | (lag_credito_usd_locales_2>0 & lag_credito_usd_locales_2!= .) | (lag_credito_usd_locales_3>0 & lag_credito_usd_locales_3!=.) 

drop Insularidad_3_EE_completa
gen Insularidad_3_EE_completa=0
replace Insularidad_3_EE_completa=1 if lag_Insularidad_3_EE_0==1 | lag_Insularidad_3_EE_1==1 | lag_Insularidad_3_EE_2==1 | lag_Insularidad_3_EE_3==1

gen Insularidad_3_EE_341=0
replace Insularidad_3_EE_341=1 if Insularidad_3_EE_completa==1 | Insularidad_3_341==1

// insularidad 4

gen Insularidad_4_EE_completa=0
replace Insularidad_4_EE_completa=1 if lag_Insularidad_4_EE_0==1 | lag_Insularidad_4_EE_1==1 | lag_Insularidad_4_EE_2==1 | lag_Insularidad_4_EE_3==1

// insularidad 5

gen Insularidad_5_EE_completa=0
replace Insularidad_5_EE_completa=1 if lag_Insularidad_5_EE_0==1 | lag_Insularidad_5_EE_1==1 | lag_Insularidad_5_EE_2==1 | lag_Insularidad_5_EE_3==1

// renombramos 

rename Insularidad_1_341  Insularidad_1_rec
rename Insularidad_2_341  Insularidad_2_rec
rename Insularidad_3_EE_341 Insularidad_3_rec
rename Insularidad_4_EE_completa Insularidad_4_rec
rename Insularidad_5_EE_completa Insularidad_5_rec

// generamos la insularidad definitiva recuperada 

gen insularidad_definitiva_rec=.
replace insularidad_definitiva_rec=1 if Insularidad_1_rec==1
replace insularidad_definitiva_rec=2 if Insularidad_2_rec ==1
replace insularidad_definitiva_rec=3 if Insularidad_3_rec==1
replace insularidad_definitiva_rec=4 if Insularidad_4_rec==1
replace insularidad_definitiva_rec=5 if Insularidad_5_rec==1

// reemplazamos la insularidad definitiva por la recuperada solamente para aquellas observaciones con missing

replace insularidad_definitiva = insularidad_definitiva_rec if insularidad_definitiva == .

// por las diferencias entre cómo se generan las insularidad y cómo se define la condición de las observaciones que hacen parte de esta base de datos, se colan un 1% de observaciones de insularidades distintas a 4 y 5. Por ello, vamos a deshacernos de esas observaciones 

keep if insularidad_definitiva == 4 |insularidad_definitiva == 5

// eliminamos las variables que ya no necesitamos 

drop *_rec lag_Insularidad* lag_credito_usd_locales* lag_ralacion_bancaria*

// guardamos la base de datos 

save "$input\base_reg_1_mon_local_insu.dta", replace // base de datos para la regresión 1 que toma como variable dependiente el crédito local en pesos


**# BASE PARA REG CON CRÉDITO LOCAL TOTAL

// llamamos la base de datos con balanceo anual y sin missings 

use "$input\balanceado_anual_nuevo_credito1_lags_leads_todos_V2.dta", clear

// queremos que la base solo tenga información de firmas que sacaron crédito externo Y crédito local (independiente de la moneda) en un margen de cuatro trimestres. Para ello generamos una condición que será igual a 1 para todas las observaciones que nos interesan

// generamos la variable de condición

gen condicion = 0

// la condición la cumplen las observaciones para las cuales la firma sacó tanto crédito externo como crédito local en el mismo trimestre

replace condicion = 1 if valor != 0 & var_capital_USD != 0 & var_capital_USD != .

// la condición la cumplen las observaciones para las cuales la firma sacó crédito externo en el trimestre actual Y crédito local en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if valor != 0 & lag_`num'_var_capital_USD != 0 & lag_`num'_var_capital_USD != .
	replace condicion = 1 if valor != 0 & lead_`num'_var_capital_USD != 0 & lead_`num'_var_capital_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en el trimestre actual Y crédito externo en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if var_capital_USD != 0 & var_capital_USD != . & lag_`num'_valor != 0 & lag_`num'_valor != .
	replace condicion = 1 if var_capital_USD != 0 & var_capital_USD != . & lead_`num'_valor != 0 & lead_`num'_valor != .
	
}

// la condición la cumplen las observaciones para las cuales, si bien la firma no sacó crédito externo ni crédito local en el trimestre t, si sacó crédito local en t-1 Y crédito externo en t+2, así como las observaciones en las que la firma sacó crédito externo en t-1 Y crédito local en t+2

forvalues num=1(1)2{
    
	local val = abs(`num' - 3)

	replace condicion = 1 if lag_`num'_var_capital_USD != 0 & lag_`num'_var_capital_USD != . & lead_`val'_valor != 0 & lead_`val'_valor != .
	
	replace condicion = 1 if lag_`num'_valor != 0 & lag_`num'_valor != . & lead_`val'_var_capital_USD != 0 & lead_`val'_var_capital_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en t-1 Y crédito externo en t+1, así como las observaciones en las que la firma sacó crédito externo en t-1 Y crédito local en t+1

forvalues num=1(1)1{
    
	local val = abs(`num' - 2)

	replace condicion = 1 if lag_`num'_var_capital_USD != 0 & lag_`num'_var_capital_USD != . & lead_`val'_valor != 0 & lead_`val'_valor != .
	
	replace condicion = 1 if lag_`num'_valor != 0 & lag_`num'_valor != . & lead_`val'_var_capital_USD != 0 & lead_`val'_var_capital_USD != .
	
}

// conservamos solamente las observaciones que cumplen la condición 

keep if condicion == 1

// renombramos la variable de cambio en el crédito local (esto para cuando corramos las regresiones)

rename var_capital_USD acum_0_capital_USD

// guardamos esta base de datos 

save "$input\base_reg_1_cred_total.dta", replace // base de datos que contiene las observaciones que cumplen la condición para las firmas de haber sacado crédito externo y crédito local en un margen de cuatro trimestres 

// lo siguiente es recuperar las insularidades para las observaciones generadas al balancear anualmente

// llamamos la base generada arriba

use "$input\base_reg_1_cred_total.dta", clear

// recuperamos la variable "identif" (nits de las firmas) para las observaciones generadas al balancear 

preserve

keep identif firma

drop if identif == ""

duplicates drop

rename identif nits

tempfile nits_merge
save `nits_merge'

restore

merge m:1 firma using `nits_merge'

drop _merge

replace identif = nits if identif == ""

drop nits

// renombramos la variable de insularidad 

rename insularidad_definitiva insularidad_definitiva_1

// mergeamos con la base de datos que contiene las insularidades 

merge 1:1 identif Fecha_tri using "$input\Insularidades_definitivo_EE_saldos.dta"

// eliminamos las observaciones que no mergean de la base de insularidades

drop if _merge == 2

drop _merge

// recuperamos la variable de insularidad

replace insularidad_definitiva_1 = insularidad_definitiva if insularidad_definitiva_1 == .

// eliminamos la variable de insularidad proveniente de la base de insularidades, ya que ya no la necesitamos

drop insularidad_definitiva

// volvemos a renombrar la variable de insularidad de nuestra base de datos

rename insularidad_definitiva_1 insularidad_definitiva

// con lo anterior recuperamos la insularidad para aquellas observaciones que se encontraban en la base de datos de saldos. Sin embargo, para las observaciones que no se encuentran en esa base de datos no fue posible recuperar la insularidad (ya que no contaban con una insularidad en primer lugar). Por ello, vamos a generar la insularidad para aquellas observaciones

// mergeamos con la base de datos que contiene las variables para generar la insularidad

merge 1:1 identif Fecha_tri using "$input\variables_para_generar_insularidades_firma_tiempo.dta"

// eliminamos las observaciones que no mergean de la base using 

drop if _merge == 2

drop _merge

// reemplazamos por cero los missings (de las observaciones que no mergearon)

replace ralacion_bancaria = 0 if ralacion_bancaria == .
replace credito_usd_locales = 0 if credito_usd_locales == .
replace Insularidad_3_EE = 0 if Insularidad_3_EE == .
replace Insularidad_4_EE = 0 if Insularidad_4_EE == .
replace Insularidad_5_EE = 0 if Insularidad_5_EE == .

// generamos el panel

xtset firma Fecha_tri

// generamos los lags (hasta tres periodos atrás) de las variables con las que generaremos las insularidades

forvalues x=0(1)3{
    di `x' 
	bys firma : gen lag_ralacion_bancaria_`x'=L`x'.ralacion_bancaria
	bys firma : gen lag_credito_usd_locales_`x'=L`x'.credito_usd_locales
	bys firma : gen lag_Insularidad_3_EE_`x'=L`x'.Insularidad_3_EE
	bys firma : gen lag_Insularidad_4_EE_`x'=L`x'.Insularidad_4_EE
	bys firma : gen lag_Insularidad_5_EE_`x'=L`x'.Insularidad_5_EE
}

// generamos las insularidades

// insularidad 1

gen Insularidad_1_341=0
replace  Insularidad_1_341=1 if lag_ralacion_bancaria_0==1 | lag_ralacion_bancaria_1==1 | lag_ralacion_bancaria_2==1 | lag_ralacion_bancaria_3==1

// insularidad 2

gen Insularidad_2_341=0
replace Insularidad_2_341=1 if lag_ralacion_bancaria_0>1 | lag_ralacion_bancaria_1>1 | lag_ralacion_bancaria_2>1 | lag_ralacion_bancaria_3>1

// insularidad 3

gen Insularidad_3_341=0
replace Insularidad_3_341=1 if (lag_credito_usd_locales_0>0 & lag_credito_usd_locales_0 != .) | (lag_credito_usd_locales_1>0 & lag_credito_usd_locales_1!=.)  | (lag_credito_usd_locales_2>0 & lag_credito_usd_locales_2!= .) | (lag_credito_usd_locales_3>0 & lag_credito_usd_locales_3!=.) 

drop Insularidad_3_EE_completa
gen Insularidad_3_EE_completa=0
replace Insularidad_3_EE_completa=1 if lag_Insularidad_3_EE_0==1 | lag_Insularidad_3_EE_1==1 | lag_Insularidad_3_EE_2==1 | lag_Insularidad_3_EE_3==1

gen Insularidad_3_EE_341=0
replace Insularidad_3_EE_341=1 if Insularidad_3_EE_completa==1 | Insularidad_3_341==1

// insularidad 4

gen Insularidad_4_EE_completa=0
replace Insularidad_4_EE_completa=1 if lag_Insularidad_4_EE_0==1 | lag_Insularidad_4_EE_1==1 | lag_Insularidad_4_EE_2==1 | lag_Insularidad_4_EE_3==1

// insularidad 5

gen Insularidad_5_EE_completa=0
replace Insularidad_5_EE_completa=1 if lag_Insularidad_5_EE_0==1 | lag_Insularidad_5_EE_1==1 | lag_Insularidad_5_EE_2==1 | lag_Insularidad_5_EE_3==1

// renombramos 

rename Insularidad_1_341  Insularidad_1_rec
rename Insularidad_2_341  Insularidad_2_rec
rename Insularidad_3_EE_341 Insularidad_3_rec
rename Insularidad_4_EE_completa Insularidad_4_rec
rename Insularidad_5_EE_completa Insularidad_5_rec

// generamos la insularidad definitiva recuperada 

gen insularidad_definitiva_rec=.
replace insularidad_definitiva_rec=1 if Insularidad_1_rec==1
replace insularidad_definitiva_rec=2 if Insularidad_2_rec ==1
replace insularidad_definitiva_rec=3 if Insularidad_3_rec==1
replace insularidad_definitiva_rec=4 if Insularidad_4_rec==1
replace insularidad_definitiva_rec=5 if Insularidad_5_rec==1

// reemplazamos la insularidad definitiva por la recuperada solamente para aquellas observaciones con missing

replace insularidad_definitiva = insularidad_definitiva_rec if insularidad_definitiva == .

// por las diferencias entre cómo se generan las insularidad y cómo se define la condición de las observaciones que hacen parte de esta base de datos, se colan un 1% de observaciones de insularidades distintas a 4 y 5. Por ello, vamos a deshacernos de esas observaciones 

keep if insularidad_definitiva == 4 |insularidad_definitiva == 5

// eliminamos las variables que ya no necesitamos 

drop *_rec lag_Insularidad* lag_credito_usd_locales* lag_ralacion_bancaria*

// guardamos la base de datos 

save "$input\base_reg_1_cred_total_insu.dta", replace // base de datos para la regresión 1 que toma como variable dependiente el crédito local total


**# BASE PARA REGRESIÓN 1.1

// Partiremos de la base que cuenta con lags y leads y balanceamos año a año, pero esta vez para aquellas observaciones de insularidades 3, 4 o 5 (ya que son las únicas que pueden tener crédito local en pesos)

forvalues year=2000(1)2019{
    use "$input\base_primera_reg_nuevo_credito1_lags_y_leads_05_08_2024.dta", clear
    keep if year==`year'
	keep if insularidad_definitiva == 3 | insularidad_definitiva == 4 | insularidad_definitiva == 5
	
	*completar panel
	drop firma
	egen firma=group(identif)
	xtset firma Fecha_tri 
	tsreport  Fecha_tri,  p 
	tsfill, full 
	
	*recuperamos los nits perdidos al balancear
	preserve
	keep if identif != ""
	keep identif firma
	duplicates drop
	rename identif nom
	tempfile nits_merge
	save `nits_merge' 
	restore 
	
	*Mergeamos
	merge m:1 firma using `nits_merge' 
	drop _merge
	replace identif = nom if identif == ""
	drop nom
	save "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_`year'.dta", replace // guardamos una base balanceada para cada año
}

// appendeamos las distintas bases anuales balanceadas

forvalues year=2000(1)2019{
    if `year'==2000{
	    use  "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_`year'.dta", clear
		save "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_todos_V2.dta", replace
		continue
	}
	use  "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_`year'.dta", clear
	append using "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_todos_V2.dta"
	save "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_todos_V2.dta", replace // esta base contiene el balanceo anual para las observaciones de insularidades 3, 4 y 5 para cada año.
}

// llamamos la base con balanceo anual

use "$input\balanceado_anual_nuevo_credito1_mon_local_vs_mon_extr_todos_V2.dta", clear

// volvemos a generar la variable de firma para el panel 

drop firma

egen firma = group(identif)

xtset firma Fecha_tri

// reemplazamos los missings generados con el balanceo por su valor real

replace capital_USD=0 if capital_USD==.
replace capitalme_USD=0 if capitalme_USD==.
replace capitalml_USD =0 if capitalml_USD ==.
replace valor=0 if valor==.

bys firma (Fecha_tri): replace var_capitalme_USD= capitalme_USD - L1.capitalme_USD if var_capitalme_USD==. & Fecha_tri != yq(2000, 1)
bys firma (Fecha_tri): replace var_capital_USD= capital_USD - L1.capital_USD if var_capital_USD==. & Fecha_tri != yq(2000, 1)
bys firma (Fecha_tri): replace var_capitalml_USD= capitalml - L1.capitalml if var_capitalml_USD==. & Fecha_tri != yq(2000, 1)

replace var_capitalme_USD=0 if var_capitalme_USD==. & Fecha_tri != yq(2000, 1)
replace var_capital_USD=0 if var_capital_USD==. & Fecha_tri != yq(2000, 1)
replace var_capitalml_USD=0 if var_capitalml_USD==. & Fecha_tri != yq(2000, 1)

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD{
    bys firma (Fecha_tri): replace lag_1_`var' = L1.`var' if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	bys firma (Fecha_tri): replace lead_1_`var' = F1.`var' if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	bys firma (Fecha_tri): replace lag_2_`var' = L2.`var' if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	bys firma (Fecha_tri): replace lead_2_`var' = F2.`var' if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	bys firma (Fecha_tri): replace lag_3_`var' = L3.`var' if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	bys firma (Fecha_tri): replace lead_3_`var' = F3.`var' if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	bys firma (Fecha_tri): replace lag_4_`var' = L4.`var' if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	bys firma (Fecha_tri): replace lead_4_`var' = F4.`var' if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD{
    replace lag_1_`var' = 0 if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	replace lead_1_`var' = 0 if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	replace lag_2_`var' = 0 if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	replace lead_2_`var' = 0 if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	replace lag_3_`var' = 0 if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	replace lead_3_`var' = 0 if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	replace lag_4_`var' = 0 if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	replace lead_4_`var' = 0 if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

foreach var in capital_USD capitalme_USD capitalml_USD {
	replace acum_1_`var' = lead_1_`var' - lag_1_`var'
	
	replace acum_2_`var' = lead_2_`var' - lag_1_`var'
	
	replace acum_3_`var' = lead_3_`var' - lag_1_`var'
	
	replace acum_4_`var' = lead_4_`var' - lag_1_`var'
}

// queremos que la base solo tenga información de firmas que sacaron crédito local en pesos Y crédito local en dólares en un margen de cuatro trimestres. Para ello generamos una condición que será igual a 1 para todas las observaciones que nos interesan

// generamos la variable de condición

gen condicion = 0

// la condición la cumplen las observaciones para las cuales la firma sacó tanto crédito local en pesos como crédito local en dólares en el mismo trimestre

replace condicion = 1 if var_capitalml != 0 & var_capitalme_USD != 0 & var_capitalml != . & var_capitalme_USD != .

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en pesos en el trimestre actual Y crédito local en dólares en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if var_capitalml != 0 & var_capitalml != . & lag_`num'_var_capitalme_USD != 0 & lag_`num'_var_capitalme_USD != .
	replace condicion = 1 if var_capitalml != 0  & var_capitalml != .& lead_`num'_var_capitalme_USD != 0 & lead_`num'_var_capitalme_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en dólares en el trimestre actual Y crédito local en pesos en algúno de los tres trimestres anteriores

forvalues num=1(1)3{

	replace condicion = 1 if var_capitalme_USD != 0 & var_capitalme_USD != . & lag_`num'_var_capitalml != 0 & lag_`num'_var_capitalml != .
	replace condicion = 1 if var_capitalme_USD != 0 & var_capitalme_USD != . & lead_`num'_var_capitalml != 0 & lead_`num'_var_capitalml != .
	
}

// la condición la cumplen las observaciones para las cuales, si bien la firma no sacó crédito local en pesos ni crédito local en dólares en el trimestre t, si sacó crédito local en dólares en t-1 Y crédito local en pesos en t+2, así como las observaciones en las que la firma sacó crédito local en pesos en t-1 Y crédito local en dólares en t+2

forvalues num=1(1)2{
    
	local val = abs(`num' - 3)

	replace condicion = 1 if lag_`num'_var_capitalme_USD != 0 & lag_`num'_var_capitalme_USD != . & lead_`val'_var_capitalml != 0 & lead_`val'_var_capitalml != .
	
	replace condicion = 1 if lag_`num'_var_capitalml != 0 & lag_`num'_var_capitalml != . & lead_`val'_var_capitalme_USD != 0 & lead_`val'_var_capitalme_USD != .
	
}

// la condición la cumplen las observaciones para las cuales la firma sacó crédito local en dólares en t-1 Y crédito local en pesos en t+1, así como las observaciones en las que la firma sacó crédito local en pesos en t-1 Y crédito local en dólares en t+1

forvalues num=1(1)1{
    
	local val = abs(`num' - 2)

	replace condicion = 1 if lag_`num'_var_capitalme_USD != 0 & lag_`num'_var_capitalme_USD != . & lead_`val'_var_capitalml != 0 & lead_`val'_var_capitalml != .
	
	replace condicion = 1 if lag_`num'_var_capitalml != 0 & lag_`num'_var_capitalml != . & lead_`val'_var_capitalme_USD != 0 & lead_`val'_var_capitalme_USD != .
	
}

// conservamos solamente las observaciones que cumplen la condición 

keep if condicion == 1

// renombramos la variable de cambio en el crédito local en pesos (esto para cuando corramos las regresiones)

rename var_capitalml acum_0_capitalml_USD

// guardamos esta base de datos 

save "$input\base_reg_1_1_mon_local_vs_mon_extranj.dta", replace // base de datos que contiene las observaciones que cumplen la condición para las firmas de haber sacado crédito local en pesos y crédito local en dólares en un margen de cuatro trimestres 

// lo siguiente es recuperar las insularidades para las observaciones generadas al balancear anualmente

// llamamos la base generada arriba

use "$input\base_reg_1_1_mon_local_vs_mon_extranj.dta", clear

// recuperamos la variable "identif" (nits de las firmas) para las observaciones generadas al balancear 

preserve

keep identif firma

drop if identif == ""

duplicates drop

rename identif nits

tempfile nits_merge
save `nits_merge'

restore

merge m:1 firma using `nits_merge'

drop _merge

replace identif = nits if identif == ""

drop nits

// renombramos la variable de insularidad 

rename insularidad_definitiva insularidad_definitiva_1

// mergeamos con la base de datos que contiene las insularidades 

merge 1:1 identif Fecha_tri using "$input\Insularidades_definitivo_EE_saldos.dta"

// eliminamos las observaciones que no mergean de la base de insularidades

drop if _merge == 2

drop _merge

// recuperamos la variable de insularidad

replace insularidad_definitiva_1 = insularidad_definitiva if insularidad_definitiva_1 == .

// eliminamos la variable de insularidad proveniente de la base de insularidades, ya que ya no la necesitamos

drop insularidad_definitiva

// volvemos a renombrar la variable de insularidad de nuestra base de datos

rename insularidad_definitiva_1 insularidad_definitiva

// con lo anterior recuperamos la insularidad para aquellas observaciones que se encontraban en la base de datos de saldos. Sin embargo, para las observaciones que no se encuentran en esa base de datos no fue posible recuperar la insularidad (ya que no contaban con una insularidad en primer lugar). Por ello, vamos a generar la insularidad para aquellas observaciones

// mergeamos con la base de datos que contiene las variables para generar la insularidad

merge 1:1 identif Fecha_tri using "$input\variables_para_generar_insularidades_firma_tiempo.dta"

// eliminamos las observaciones que no mergean de la base using 

drop if _merge == 2

drop _merge

// reemplazamos por cero los missings (de las observaciones que no mergearon)

replace ralacion_bancaria = 0 if ralacion_bancaria == .
replace credito_usd_locales = 0 if credito_usd_locales == .
replace Insularidad_3_EE = 0 if Insularidad_3_EE == .
replace Insularidad_4_EE = 0 if Insularidad_4_EE == .
replace Insularidad_5_EE = 0 if Insularidad_5_EE == .

// generamos el panel

xtset firma Fecha_tri

// generamos los lags (hasta tres periodos atrás) de las variables con las que generaremos las insularidades

forvalues x=0(1)3{
    di `x' 
	bys firma : gen lag_ralacion_bancaria_`x'=L`x'.ralacion_bancaria
	bys firma : gen lag_credito_usd_locales_`x'=L`x'.credito_usd_locales
	bys firma : gen lag_Insularidad_3_EE_`x'=L`x'.Insularidad_3_EE
	bys firma : gen lag_Insularidad_4_EE_`x'=L`x'.Insularidad_4_EE
	bys firma : gen lag_Insularidad_5_EE_`x'=L`x'.Insularidad_5_EE
}

// generamos las insularidades

// insularidad 1

gen Insularidad_1_341=0
replace  Insularidad_1_341=1 if lag_ralacion_bancaria_0==1 | lag_ralacion_bancaria_1==1 | lag_ralacion_bancaria_2==1 | lag_ralacion_bancaria_3==1

// insularidad 2

gen Insularidad_2_341=0
replace Insularidad_2_341=1 if lag_ralacion_bancaria_0>1 | lag_ralacion_bancaria_1>1 | lag_ralacion_bancaria_2>1 | lag_ralacion_bancaria_3>1

// insularidad 3

gen Insularidad_3_341=0
replace Insularidad_3_341=1 if (lag_credito_usd_locales_0>0 & lag_credito_usd_locales_0 != .) | (lag_credito_usd_locales_1>0 & lag_credito_usd_locales_1!=.)  | (lag_credito_usd_locales_2>0 & lag_credito_usd_locales_2!= .) | (lag_credito_usd_locales_3>0 & lag_credito_usd_locales_3!=.) 

drop Insularidad_3_EE_completa
gen Insularidad_3_EE_completa=0
replace Insularidad_3_EE_completa=1 if lag_Insularidad_3_EE_0==1 | lag_Insularidad_3_EE_1==1 | lag_Insularidad_3_EE_2==1 | lag_Insularidad_3_EE_3==1

gen Insularidad_3_EE_341=0
replace Insularidad_3_EE_341=1 if Insularidad_3_EE_completa==1 | Insularidad_3_341==1

// insularidad 4

gen Insularidad_4_EE_completa=0
replace Insularidad_4_EE_completa=1 if lag_Insularidad_4_EE_0==1 | lag_Insularidad_4_EE_1==1 | lag_Insularidad_4_EE_2==1 | lag_Insularidad_4_EE_3==1

// insularidad 5

gen Insularidad_5_EE_completa=0
replace Insularidad_5_EE_completa=1 if lag_Insularidad_5_EE_0==1 | lag_Insularidad_5_EE_1==1 | lag_Insularidad_5_EE_2==1 | lag_Insularidad_5_EE_3==1

// renombramos 

rename Insularidad_1_341  Insularidad_1_rec
rename Insularidad_2_341  Insularidad_2_rec
rename Insularidad_3_EE_341 Insularidad_3_rec
rename Insularidad_4_EE_completa Insularidad_4_rec
rename Insularidad_5_EE_completa Insularidad_5_rec

// generamos la insularidad definitiva recuperada 

gen insularidad_definitiva_rec=.
replace insularidad_definitiva_rec=1 if Insularidad_1_rec==1
replace insularidad_definitiva_rec=2 if Insularidad_2_rec ==1
replace insularidad_definitiva_rec=3 if Insularidad_3_rec==1
replace insularidad_definitiva_rec=4 if Insularidad_4_rec==1
replace insularidad_definitiva_rec=5 if Insularidad_5_rec==1

// reemplazamos la insularidad definitiva por la recuperada solamente para aquellas observaciones con missing

replace insularidad_definitiva = insularidad_definitiva_rec if insularidad_definitiva == .

// por las diferencias entre cómo se generan las insularidad y cómo se define la condición de las observaciones que hacen parte de esta base de datos, se colan un 1% de observaciones de insularidades distintas a 3, 4 y 5. Por ello, vamos a deshacernos de esas observaciones 

keep if insularidad_definitiva == 4 |insularidad_definitiva == 5 |insularidad_definitiva == 3

// eliminamos las variables que ya no necesitamos 

drop *_rec lag_Insularidad* lag_credito_usd_locales* lag_ralacion_bancaria*

// guardamos la base de datos 

save "$input\base_reg_1_1_mon_local_vs_mon_extranj_insu.dta", replace // base de datos para la regresión 1.1
