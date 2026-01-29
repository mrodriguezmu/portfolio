********************************************************************************
****************************** DATOS REGRESIÓN 2 *******************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"


**# BASE GENERAL

// llamamos la base de datos del merge de la 341 con EE (en flujo)

use "$input\Merge_341_EE_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos las variables de variación ya incluidas en la base

drop var_*

// para aquellas observaciones que no cuentan con un banco (codentid = .), reemplazaremos el código por 0

replace codentid = 0 if codentid == .

// generamos una variable de firma-banco

egen firma_banco = group(identif codentid)

// generamos el panel firma-banco-tiempo

xtset firma_banco Fecha_tri

// generamos las variables de cambio en el crédito local

bys firma_banco (Fecha_tri): gen var_capital_USD = capital_USD - L1.capital_USD  // cambio del credito local total

bys firma_banco (Fecha_tri): gen var_capitalme_USD = capitalme_USD - L1.capitalme_USD  // cambio del credito local en moneda extranjera

bys firma_banco (Fecha_tri): gen var_capitalml_USD = capitalml_USD - L1.capitalml_USD  // cambio del credito local en moneda local

// reemplazamos los missings generados por su valor correspondiente

replace var_capital_USD = 0 if var_capital_USD == . & capital_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capital_USD = capital_USD if var_capital_USD == . & capital_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalme_USD = 0 if var_capitalme_USD == . & capitalme_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalme_USD = capitalme_USD if var_capitalme_USD == . & capitalme_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalml_USD = 0 if var_capitalml_USD == . & capitalml_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalml_USD = capitalml_USD if var_capitalml_USD == . & capitalml_USD != 0 & Fecha_tri != yq(2000, 1)

// generamos los lags y los leads de las distintas variables de crédito 

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
    forvalues num=1(1)4{
		bys firma_banco (Fecha_tri): gen lag_`num'_`var' = L`num'.`var'
		bys firma_banco (Fecha_tri): gen lead_`num'_`var' = F`num'.`var'
		
	}
}

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
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

save "$input\base_reg_2_20_08_2024.dta", replace // base de datos que contiene las variables de la 341 a nivel firma-banco-tiempo y las de EE a nivel firma-tiempo, ademas de los flujos, los lags y leads y los cambios acumulados. Esta base es el punto de partida para cada una de las sub bases con las que realizaremos las distintas vesiones de la regresión 2.


**# 1) BASES PARA REGRESIONES EN FORMA BÁSICA

**# 1.1) BASE REGRESIÓN 2 CON CRÉDITO LOCAL EN DÓLARES COMO VARIABLE DEPENDIENTE

// llamamos la base general

use "$input\base_reg_2_20_08_2024.dta", clear

// conservamos solamente las observaciones de las firmas que en algún momento sacaron crédito local en dólares 

preserve

drop if (capitalme == 0 | capitalme == .) & (var_capitalme_USD == 0 | var_capitalme_USD == .)

keep identif

duplicates drop

tempfile nits

save `nits'

restore

merge m:1 identif using `nits'
keep if _merge==3 
drop _merge

unique identif // número de firmas: 95537

// eliminamos la variable de firma-banco de la base anterior y la volvemos a generar para las firmas que conservamos

drop firma_banco

egen firma_banco = group(identif codentid)

// guardamos la base de datos 

save "$input\base_reg_2_20_08_2024_mon_extr_sin_variables.dta", replace // base de datos que contiene las observaciones para la regresión 2 con crédito local en dolares como variable dependiente

// llamamos la base que acabamos de generar

use "$input\base_reg_2_20_08_2024_mon_extr_sin_variables.dta", clear 

// mergeamos con la base de datos que contiene la llave firma-banco-tiempo en la que existió relación (en dólares) de la firma i con el banco b en el trimestre t

merge 1:1 codentid identif Fecha_tri using "$input\relacion_i_b_t_me"

// eliminamos las observaciones que no mergean de la base "using"

drop if _merge == 2

drop _merge

// para aquellas observaciones en las que la variable de relación es missing, reemplazamos el valor por cero

replace relacion_i_b_t = 0 if relacion_i_b_t == .

// generamos una dummy que se activa si la firma i tuvo relación con el banco b en los cuatro trimestres anteriores

gen D = 0

by firma_banco (Fecha_tri), sort: replace D = 1 if L1.relacion_i_b_t == 1 | L2.relacion_i_b_t == 1 | L3.relacion_i_b_t == 1 | L4.relacion_i_b_t == 1

replace D = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos el primer lag del crédito externo (variable valor - recordemos que esta variable ya es un flujo) por la dummy. Esto lo hacemos generando una nueva variable

gen lag_1_valor_x_D = D * lag_1_valor

// generamos la sumatoria de la variable anterior para todas las firmas para cada trimestre, así como los lags de la misma. Para ello generamos un preserve

preserve
collapse (sum) lag_1_valor_x_D, by(codentid Fecha_tri)
rename lag_1_valor_x_D lag_1_all_valor_x_D
xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bys codentid (Fecha_tri): gen lag_`val'_all_valor_x_D = L`num'.lag_1_all_valor_x_D
		
}

replace lag_2_all_valor_x_D = 0 if lag_2_all_valor_x_D == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_valor_x_D = 0 if lag_3_all_valor_x_D == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_valor_x_D = 0 if lag_4_all_valor_x_D == . & Fecha_tri > yq(2000, 3)
	
tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

drop _merge

// reemplazamos las variables generadas por missing para los trimestres correspondientes

replace lag_1_all_valor_x_D = . if D == .

replace lag_2_all_valor_x_D = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_valor_x_D = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_valor_x_D = . if Fecha_tri == yq(2000, 4)

// restamos el crédito externo de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_valor_x_D_sin_i = lag_1_all_valor_x_D - lag_1_valor_x_D

bys firma_banco (Fecha_tri):gen lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - L1.lag_1_valor_x_D if L1.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - 0 if L1.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - L2.lag_1_valor_x_D if L2.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - 0 if L2.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - L3.lag_1_valor_x_D if L3.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - 0 if L3.lag_1_valor_x_D == .

// generamos la sumatoria del crédito externo de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en dólares con el banco b. A esta variable la llamaremos numerador

gen numerador = .

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i + lag_4_all_valor_x_D_sin_i if Fecha_tri > yq(2000, 4)

// generamos la sumatoria del lag del cambio en el crédito local en dólares de todas las firmas para cada trimestre, así como generamos los demás lags de esta variable 

preserve
collapse (sum) lag_1_var_capitalme_USD, by(codentid Fecha_tri)
rename lag_1_var_capitalme_USD lag_1_all_var_capitalme

xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bysort codentid (Fecha_tri): gen lag_`val'_all_var_capitalme = L`num'.lag_1_all_var_capitalme
		
}

replace lag_2_all_var_capitalme = 0 if lag_2_all_var_capitalme == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_var_capitalme = 0 if lag_3_all_var_capitalme == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_var_capitalme = 0 if lag_4_all_var_capitalme == . & Fecha_tri > yq(2000, 3)


tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

// reemplazamos las variables generadas por missing para los trimestres correspondientes

drop _merge

replace lag_1_all_var_capitalme = . if D == .

replace lag_2_all_var_capitalme = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_var_capitalme = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_var_capitalme = . if Fecha_tri == yq(2000, 4)

// restamos el crédito local en dólares de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_var_capitalme_sin_i = lag_1_all_var_capitalme - lag_1_var_capitalme_USD

bys firma_banco (Fecha_tri):gen lag_2_all_var_capitalme_sin_i = lag_2_all_var_capitalme - L1.lag_1_var_capitalme_USD if L1.lag_1_var_capitalme_USD != .
bys firma_banco (Fecha_tri): replace lag_2_all_var_capitalme_sin_i = lag_2_all_var_capitalme - 0 if L1.lag_1_var_capitalme_USD == .

bys firma_banco (Fecha_tri):gen lag_3_all_var_capitalme_sin_i = lag_3_all_var_capitalme - L2.lag_1_var_capitalme_USD if L2.lag_1_var_capitalme_USD != .
bys firma_banco (Fecha_tri): replace lag_3_all_var_capitalme_sin_i = lag_3_all_var_capitalme - 0 if L2.lag_1_var_capitalme_USD == .

bys firma_banco (Fecha_tri):gen lag_4_all_var_capitalme_sin_i = lag_4_all_var_capitalme - L3.lag_1_var_capitalme_USD if L3.lag_1_var_capitalme_USD != .
bys firma_banco (Fecha_tri): replace lag_4_all_var_capitalme_sin_i = lag_4_all_var_capitalme - 0 if L3.lag_1_var_capitalme_USD == .

// generamos la sumatoria del crédito local en dólares de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en dólares con el banco b. A esta variable la llamaremos denominador 

gen denominador = .

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i + lag_2_all_var_capitalme_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i + lag_2_all_var_capitalme_sin_i + lag_3_all_var_capitalme_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i + lag_2_all_var_capitalme_sin_i + lag_3_all_var_capitalme_sin_i + lag_4_all_var_capitalme_sin_i if Fecha_tri > yq(2001, 1)

// generamos el ratio entre el numerador y el denominador. A esta variable la llamaremos X

gen X = numerador / denominador

// eliminamos las observaciones que no tienen relación con ningún banco 

drop if codentid == 0

sort firma_banco Fecha_tri

// renombramos la variable de cambio en el crédito local en dólares 

rename var_capitalme_USD acum_0_capitalme_USD

// guardamos la base de datos

save "$input\base_reg_2_20_08_2024_pre_reg.dta", replace // base que contiene las observaciones y variables necesarias para la regresión 2 que toma como dependiente el crédito local en dólares 


**# 1.2) BASE REGRESIÓN 2 CON CRÉDITO LOCAL EN PESOS COMO VARIABLE DEPENDIENTE 

// llamamos la base general

use "$input\base_reg_2_20_08_2024.dta", clear

// conservamos solamente las observaciones de las firmas que en algún momento sacaron crédito local en pesos 

preserve

drop if (capitalml_USD == 0 | capitalml_USD == .) & (var_capitalml_USD == 0 | var_capitalml_USD == .)

keep identif

duplicates drop

tempfile nits

save `nits'

restore

merge m:1 identif using `nits'
keep if _merge==3 
drop _merge

unique identif // número de firmas: 2064927

// eliminamos la variable de firma-banco de la base anterior y la volvemos a generar para las firmas que conservamos

drop firma_banco

egen firma_banco = group(identif codentid)

save "$input\base_reg_2_20_08_2024_mon_local_sin_variables.dta", replace // base de datos que contiene las observaciones para la regresión 2 con crédito local en pesos como variable dependiente

// llamamos la base que acabamos de generar

use "$input\base_reg_2_20_08_2024_mon_local_sin_variables.dta", clear 

// mergeamos con la base de datos que contiene la llave firma-banco-tiempo en la que existió relación (en pesos) de la firma i con el banco b en el trimestre t

merge 1:1 codentid identif Fecha_tri using "$input\relacion_i_b_t_ml"

// eliminamos las observaciones que no mergean de la base "using"

drop if _merge == 2

drop _merge

// para aquellas observaciones en las que la variable de relación es missing, reemplazamos el valor por cero

replace relacion_i_b_t = 0 if relacion_i_b_t == .

// generamos una dummy que se activa si la firma i tuvo relación con el banco b en los cuatro trimestres anteriores

gen D = 0

by firma_banco (Fecha_tri), sort: replace D = 1 if L1.relacion_i_b_t == 1 | L2.relacion_i_b_t == 1 | L3.relacion_i_b_t == 1 | L4.relacion_i_b_t == 1

replace D = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos el primer lag del crédito externo (variable valor - recordemos que esta variable ya es un flujo) por la dummy. Esto lo hacemos generando una nueva variable

gen lag_1_valor_x_D = D * lag_1_valor

// generamos la sumatoria de la variable anterior para todas las firmas para cada trimestre, así como los lags de la misma. Para ello generamos un preserve

preserve
collapse (sum) lag_1_valor_x_D, by(codentid Fecha_tri)
rename lag_1_valor_x_D lag_1_all_valor_x_D
xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bys codentid (Fecha_tri): gen lag_`val'_all_valor_x_D = L`num'.lag_1_all_valor_x_D
		
}

replace lag_2_all_valor_x_D = 0 if lag_2_all_valor_x_D == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_valor_x_D = 0 if lag_3_all_valor_x_D == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_valor_x_D = 0 if lag_4_all_valor_x_D == . & Fecha_tri > yq(2000, 3)
	
tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

drop _merge

// reemplazamos las variables generadas por missing para los trimestres correspondientes

replace lag_1_all_valor_x_D = . if D == .

replace lag_2_all_valor_x_D = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_valor_x_D = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_valor_x_D = . if Fecha_tri == yq(2000, 4)

// restamos el crédito externo de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_valor_x_D_sin_i = lag_1_all_valor_x_D - lag_1_valor_x_D

bys firma_banco (Fecha_tri):gen lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - L1.lag_1_valor_x_D if L1.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - 0 if L1.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - L2.lag_1_valor_x_D if L2.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - 0 if L2.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - L3.lag_1_valor_x_D if L3.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - 0 if L3.lag_1_valor_x_D == .

// generamos la sumatoria del crédito externo de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en pesos con el banco b. A esta variable la llamaremos numerador

gen numerador = .

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i + lag_4_all_valor_x_D_sin_i if Fecha_tri > yq(2000, 4)

// generamos la sumatoria del lag del cambio en el crédito local en pesos de todas las firmas para cada trimestre, así como generamos los demás lags de esta variable 

preserve
collapse (sum) lag_1_var_capitalml_USD, by(codentid Fecha_tri)
rename lag_1_var_capitalml_USD lag_1_all_var_capitalml

xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bysort codentid (Fecha_tri): gen lag_`val'_all_var_capitalml = L`num'.lag_1_all_var_capitalml
		
}

replace lag_2_all_var_capitalml = 0 if lag_2_all_var_capitalml == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_var_capitalml = 0 if lag_3_all_var_capitalml == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_var_capitalml = 0 if lag_4_all_var_capitalml == . & Fecha_tri > yq(2000, 3)


tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

// reemplazamos las variables generadas por missing para los trimestres correspondientes

drop _merge

replace lag_1_all_var_capitalml = . if D == .

replace lag_2_all_var_capitalml = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_var_capitalml = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_var_capitalml = . if Fecha_tri == yq(2000, 4)

// restamos el crédito local en pesos de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_var_capitalml_sin_i = lag_1_all_var_capitalml - lag_1_var_capitalml_USD

bys firma_banco (Fecha_tri):gen lag_2_all_var_capitalml_sin_i = lag_2_all_var_capitalml - L1.lag_1_var_capitalml_USD if L1.lag_1_var_capitalml_USD != .
bys firma_banco (Fecha_tri): replace lag_2_all_var_capitalml_sin_i = lag_2_all_var_capitalml - 0 if L1.lag_1_var_capitalml_USD == .

bys firma_banco (Fecha_tri):gen lag_3_all_var_capitalml_sin_i = lag_3_all_var_capitalml - L2.lag_1_var_capitalml_USD if L2.lag_1_var_capitalml_USD != .
bys firma_banco (Fecha_tri): replace lag_3_all_var_capitalml_sin_i = lag_3_all_var_capitalml - 0 if L2.lag_1_var_capitalml_USD == .

bys firma_banco (Fecha_tri):gen lag_4_all_var_capitalml_sin_i = lag_4_all_var_capitalml - L3.lag_1_var_capitalml_USD if L3.lag_1_var_capitalml_USD != .
bys firma_banco (Fecha_tri): replace lag_4_all_var_capitalml_sin_i = lag_4_all_var_capitalml - 0 if L3.lag_1_var_capitalml_USD == .

// generamos la sumatoria del crédito local en pesos de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en pesos con el banco b. A esta variable la llamaremos denominador 

gen denominador = .

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i + lag_2_all_var_capitalml_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i + lag_2_all_var_capitalml_sin_i + lag_3_all_var_capitalml_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i + lag_2_all_var_capitalml_sin_i + lag_3_all_var_capitalml_sin_i + lag_4_all_var_capitalml_sin_i if Fecha_tri > yq(2001, 1)

// generamos el ratio entre el numerador y el denominador. A esta variable la llamaremos X

gen X = numerador / denominador

// eliminamos las observaciones que no tienen relación con ningún banco 

drop if codentid == 0

sort firma_banco Fecha_tri

// renombramos la variable de cambio en el crédito local en pesos 

rename var_capitalml_USD acum_0_capitalml_USD

// guardamos la base de datos

save "$input\base_reg_2_20_08_2024_mon_local_pre_reg.dta", replace // base que contiene las observaciones y variables necesarias para la regresión 2 que toma como dependiente el crédito local en pesos 


**# 1.3) BASE REGRESIÓN 2 CON CRÉDITO LOCAL TOTAL COMO VARIABLE DEPENDIENTE 

// llamamos la base general

use "$input\base_reg_2_20_08_2024.dta", clear

// conservamos solamente las observaciones de las firmas que en algún momento sacaron crédito local

preserve

drop if (capital_USD == 0 | capital_USD == .) & (var_capital_USD == 0 | var_capital_USD == .)

keep identif

duplicates drop

tempfile nits

save `nits'

restore

merge m:1 identif using `nits'
keep if _merge==3 
drop _merge

unique identif // número de firmas: 

// eliminamos la variable de firma-banco de la base anterior y la volvemos a generar para las firmas que conservamos

drop firma_banco

egen firma_banco = group(identif codentid)

save "$input\base_reg_2_20_08_2024_cred_total_sin_variables.dta", replace // base de datos que contiene las observaciones para la regresión 2 con crédito local total como variable dependiente

// llamamos la base que acabamos de generar

use "$input\base_reg_2_20_08_2024_cred_total_sin_variables.dta", clear 

// mergeamos con la base de datos que contiene la llave firma-banco-tiempo en la que existió relación de la firma i con el banco b en el trimestre t

merge 1:1 codentid identif Fecha_tri using "$input\relacion_i_b_t"

// eliminamos las observaciones que no mergean de la base "using"

drop if _merge == 2

drop _merge

// para aquellas observaciones en las que la variable de relación es missing, reemplazamos el valor por cero

replace relacion_i_b_t = 0 if relacion_i_b_t == .

// generamos una dummy que se activa si la firma i tuvo relación con el banco b en los cuatro trimestres anteriores

gen D = 0

by firma_banco (Fecha_tri), sort: replace D = 1 if L1.relacion_i_b_t == 1 | L2.relacion_i_b_t == 1 | L3.relacion_i_b_t == 1 | L4.relacion_i_b_t == 1

replace D = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos el primer lag del crédito externo (variable valor - recordemos que esta variable ya es un flujo) por la dummy. Esto lo hacemos generando una nueva variable

gen lag_1_valor_x_D = D * lag_1_valor

// generamos la sumatoria de la variable anterior para todas las firmas para cada trimestre, así como los lags de la misma. Para ello generamos un preserve

preserve
collapse (sum) lag_1_valor_x_D, by(codentid Fecha_tri)
rename lag_1_valor_x_D lag_1_all_valor_x_D
xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bys codentid (Fecha_tri): gen lag_`val'_all_valor_x_D = L`num'.lag_1_all_valor_x_D
		
}

replace lag_2_all_valor_x_D = 0 if lag_2_all_valor_x_D == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_valor_x_D = 0 if lag_3_all_valor_x_D == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_valor_x_D = 0 if lag_4_all_valor_x_D == . & Fecha_tri > yq(2000, 3)
	
tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

drop _merge

// reemplazamos las variables generadas por missing para los trimestres correspondientes

replace lag_1_all_valor_x_D = . if D == .

replace lag_2_all_valor_x_D = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_valor_x_D = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_valor_x_D = . if Fecha_tri == yq(2000, 4)

// restamos el crédito externo de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_valor_x_D_sin_i = lag_1_all_valor_x_D - lag_1_valor_x_D

bys firma_banco (Fecha_tri):gen lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - L1.lag_1_valor_x_D if L1.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - 0 if L1.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - L2.lag_1_valor_x_D if L2.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - 0 if L2.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - L3.lag_1_valor_x_D if L3.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - 0 if L3.lag_1_valor_x_D == .

// generamos la sumatoria del crédito externo de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación con el banco b. A esta variable la llamaremos numerador

gen numerador = .

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i + lag_4_all_valor_x_D_sin_i if Fecha_tri > yq(2000, 4)

// generamos la sumatoria del lag del cambio en el crédito local total de todas las firmas para cada trimestre, así como generamos los demás lags de esta variable 

preserve
collapse (sum) lag_1_var_capital_USD, by(codentid Fecha_tri)
rename lag_1_var_capital_USD lag_1_all_var_capital

xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bysort codentid (Fecha_tri): gen lag_`val'_all_var_capital = L`num'.lag_1_all_var_capital
		
}

replace lag_2_all_var_capital = 0 if lag_2_all_var_capital == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_var_capital = 0 if lag_3_all_var_capital == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_var_capital = 0 if lag_4_all_var_capital == . & Fecha_tri > yq(2000, 3)


tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

// reemplazamos las variables generadas por missing para los trimestres correspondientes

drop _merge

replace lag_1_all_var_capital = . if D == .

replace lag_2_all_var_capital = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_var_capital = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_var_capital = . if Fecha_tri == yq(2000, 4)

// restamos el crédito local total de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_var_capital_sin_i = lag_1_all_var_capital - lag_1_var_capital_USD

bys firma_banco (Fecha_tri):gen lag_2_all_var_capital_sin_i = lag_2_all_var_capital - L1.lag_1_var_capital_USD if L1.lag_1_var_capital_USD != .
bys firma_banco (Fecha_tri): replace lag_2_all_var_capital_sin_i = lag_2_all_var_capital - 0 if L1.lag_1_var_capital_USD == .

bys firma_banco (Fecha_tri):gen lag_3_all_var_capital_sin_i = lag_3_all_var_capital - L2.lag_1_var_capital_USD if L2.lag_1_var_capital_USD != .
bys firma_banco (Fecha_tri): replace lag_3_all_var_capital_sin_i = lag_3_all_var_capital - 0 if L2.lag_1_var_capital_USD == .

bys firma_banco (Fecha_tri):gen lag_4_all_var_capital_sin_i = lag_4_all_var_capital - L3.lag_1_var_capital_USD if L3.lag_1_var_capital_USD != .
bys firma_banco (Fecha_tri): replace lag_4_all_var_capital_sin_i = lag_4_all_var_capital - 0 if L3.lag_1_var_capital_USD == .

// generamos la sumatoria del crédito local total de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación con el banco b. A esta variable la llamaremos denominador 

gen denominador = .

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i + lag_2_all_var_capital_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i + lag_2_all_var_capital_sin_i + lag_3_all_var_capital_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i + lag_2_all_var_capital_sin_i + lag_3_all_var_capital_sin_i + lag_4_all_var_capital_sin_i if Fecha_tri > yq(2001, 1)

// generamos el ratio entre el numerador y el denominador. A esta variable la llamaremos X

gen X = numerador / denominador

// eliminamos las observaciones que no tienen relación con ningún banco 

drop if codentid == 0

sort firma_banco Fecha_tri

// renombramos la variable de cambio en el crédito local total 

rename var_capital_USD acum_0_capital_USD

// guardamos la base de datos

save "$input\base_reg_2_20_08_2024_cred_total_pre_reg.dta", replace // base que contiene las observaciones y variables necesarias para la regresión 2 que toma como dependiente el crédito local total


**# 2) BASES PARA REGRESIONES CON DENOMINADOR REDUCIDO

**# 2.1) BASE REGRESIÓN 2 CON CRÉDITO LOCAL EN DÓLARES COMO VARIABLE DEPENDIENTE

// llamamos la base que contiene las observaciones necesarias

use "$input\base_reg_2_20_08_2024_mon_extr_sin_variables.dta", clear 

// mergeamos con la base de datos que contiene la llave firma-banco-tiempo en la que existió relación (en dólares) de la firma i con el banco b en el trimestre t

merge 1:1 codentid identif Fecha_tri using "$input\relacion_i_b_t_me"

// eliminamos las observaciones que no mergean de la base "using"

drop if _merge == 2

drop _merge

// para aquellas observaciones en las que la variable de relación es missing, reemplazamos el valor por cero

replace relacion_i_b_t = 0 if relacion_i_b_t == .

// generamos una dummy que se activa si la firma i tuvo relación con el banco b en los cuatro trimestres anteriores

gen D = 0

by firma_banco (Fecha_tri), sort: replace D = 1 if L1.relacion_i_b_t == 1 | L2.relacion_i_b_t == 1 | L3.relacion_i_b_t == 1 | L4.relacion_i_b_t == 1

replace D = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos el primer lag del crédito externo (variable valor - recordemos que esta variable ya es un flujo) por la dummy. Esto lo hacemos generando una nueva variable

gen lag_1_valor_x_D = D * lag_1_valor

// generamos la sumatoria de la variable anterior para todas las firmas para cada trimestre, así como los lags de la misma. Para ello generamos un preserve

preserve
collapse (sum) lag_1_valor_x_D, by(codentid Fecha_tri)
rename lag_1_valor_x_D lag_1_all_valor_x_D
xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bys codentid (Fecha_tri): gen lag_`val'_all_valor_x_D = L`num'.lag_1_all_valor_x_D
		
}

replace lag_2_all_valor_x_D = 0 if lag_2_all_valor_x_D == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_valor_x_D = 0 if lag_3_all_valor_x_D == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_valor_x_D = 0 if lag_4_all_valor_x_D == . & Fecha_tri > yq(2000, 3)
	
tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

drop _merge

// reemplazamos las variables generadas por missing para los trimestres correspondientes

replace lag_1_all_valor_x_D = . if D == .

replace lag_2_all_valor_x_D = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_valor_x_D = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_valor_x_D = . if Fecha_tri == yq(2000, 4)

// restamos el crédito externo de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_valor_x_D_sin_i = lag_1_all_valor_x_D - lag_1_valor_x_D

bys firma_banco (Fecha_tri):gen lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - L1.lag_1_valor_x_D if L1.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - 0 if L1.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - L2.lag_1_valor_x_D if L2.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - 0 if L2.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - L3.lag_1_valor_x_D if L3.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - 0 if L3.lag_1_valor_x_D == .

// generamos la sumatoria del crédito externo de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en dólares con el banco b. A esta variable la llamaremos numerador

gen numerador = .

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i + lag_4_all_valor_x_D_sin_i if Fecha_tri > yq(2000, 4)

// generamos una dummy que se activa si la firma sacó crédito externo en los cuatro trimestres anteriores 

gen dummy = 0

by firma_banco (Fecha_tri), sort: replace dummy = 1 if (L1.valor != 0 & L1.valor != .) | (L2.valor != 0 & L2.valor != .) | (L3.valor != 0 & L3.valor != .) | (L4.valor != 0 & L4.valor != .)

replace dummy = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos la dummy anterior por la dummy que indica si la firma tuvo relación en dólares con el banco b en los cuatro trimestres anteriores. Esto nos da una variable que se activa solamente si la firma tuvo tanto relación con el banco b como crédito externo en los anteriores cuatro trimestres

gen Dxdummy = D * dummy

// multiplicamos el lag de la variación del crédito local en dólares por la variable anterior 

gen Dxdummy_x_lag_1_var_capitalme = Dxdummy * lag_1_var_capitalme_USD

// generamos la sumatoria del lag del cambio en el crédito local en dólares de las firmas que sacaron crédito externo en los anteriores cuatro trimestres para cada trimestre, así como generamos los demás lags de esta variable 

preserve
collapse (sum) Dxdummy_x_lag_1_var_capitalme, by(codentid Fecha_tri)
rename Dxdummy_x_lag_1_var_capitalme lag_1_all_var_capitalme

xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bysort codentid (Fecha_tri): gen lag_`val'_all_var_capitalme = L`num'.lag_1_all_var_capitalme
		
}

replace lag_2_all_var_capitalme = 0 if lag_2_all_var_capitalme == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_var_capitalme = 0 if lag_3_all_var_capitalme == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_var_capitalme = 0 if lag_4_all_var_capitalme == . & Fecha_tri > yq(2000, 3)


tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

// reemplazamos las variables generadas por missing para los trimestres correspondientes

drop _merge

replace lag_1_all_var_capitalme = . if D == .

replace lag_2_all_var_capitalme = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_var_capitalme = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_var_capitalme = . if Fecha_tri == yq(2000, 4)

// restamos el crédito local en dólares de la firma i a la sumatoria (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_var_capitalme_sin_i = lag_1_all_var_capitalme - Dxdummy_x_lag_1_var_capitalme

bys firma_banco (Fecha_tri):gen lag_2_all_var_capitalme_sin_i = lag_2_all_var_capitalme - L1.Dxdummy_x_lag_1_var_capitalme if L1.Dxdummy_x_lag_1_var_capitalme != .
bys firma_banco (Fecha_tri): replace lag_2_all_var_capitalme_sin_i = lag_2_all_var_capitalme - 0 if L1.Dxdummy_x_lag_1_var_capitalme == .

bys firma_banco (Fecha_tri):gen lag_3_all_var_capitalme_sin_i = lag_3_all_var_capitalme - L2.Dxdummy_x_lag_1_var_capitalme if L2.Dxdummy_x_lag_1_var_capitalme != .
bys firma_banco (Fecha_tri): replace lag_3_all_var_capitalme_sin_i = lag_3_all_var_capitalme - 0 if L2.Dxdummy_x_lag_1_var_capitalme == .

bys firma_banco (Fecha_tri):gen lag_4_all_var_capitalme_sin_i = lag_4_all_var_capitalme - L3.Dxdummy_x_lag_1_var_capitalme if L3.Dxdummy_x_lag_1_var_capitalme != .
bys firma_banco (Fecha_tri): replace lag_4_all_var_capitalme_sin_i = lag_4_all_var_capitalme - 0 if L3.Dxdummy_x_lag_1_var_capitalme == .

// generamos la sumatoria del crédito local en dólares de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en dólares con el banco b y que además sacaron crédito externo. A esta variable la llamaremos denominador 

gen denominador = .

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i + lag_2_all_var_capitalme_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i + lag_2_all_var_capitalme_sin_i + lag_3_all_var_capitalme_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalme_sin_i + lag_2_all_var_capitalme_sin_i + lag_3_all_var_capitalme_sin_i + lag_4_all_var_capitalme_sin_i if Fecha_tri > yq(2001, 1)

// generamos el ratio entre el numerador y el denominador. A esta variable la llamaremos X

gen X = numerador / denominador

// eliminamos las observaciones que no tienen relación con ningún banco 

drop if codentid == 0

sort firma_banco Fecha_tri

// renombramos la variable de cambio en el crédito local en dólares 

rename var_capitalme_USD acum_0_capitalme_USD

// guardamos la base de datos

save "$input\base_reg_2_20_08_2024_denom_reduc_pre_reg.dta", replace // base que contiene las observaciones y variables necesarias para la regresión 2 con denominador reducido que toma como dependiente el crédito local en dólares 


**# 2.2) BASE REGRESIÓN 2 CON CRÉDITO LOCAL EN PESOS COMO VARIABLE DEPENDIENTE

// llamamos la base que contiene las observaciones necesarias

use "$input\base_reg_2_20_08_2024_mon_local_sin_variables.dta", clear

// mergeamos con la base de datos que contiene la llave firma-banco-tiempo en la que existió relación (en pesos) de la firma i con el banco b en el trimestre t

merge 1:1 codentid identif Fecha_tri using "$input\relacion_i_b_t_ml"

// eliminamos las observaciones que no mergean de la base "using"

drop if _merge == 2

drop _merge

// para aquellas observaciones en las que la variable de relación es missing, reemplazamos el valor por cero

replace relacion_i_b_t = 0 if relacion_i_b_t == .

// generamos una dummy que se activa si la firma i tuvo relación con el banco b en los cuatro trimestres anteriores

gen D = 0

by firma_banco (Fecha_tri), sort: replace D = 1 if L1.relacion_i_b_t == 1 | L2.relacion_i_b_t == 1 | L3.relacion_i_b_t == 1 | L4.relacion_i_b_t == 1

replace D = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos el primer lag del crédito externo (variable valor - recordemos que esta variable ya es un flujo) por la dummy. Esto lo hacemos generando una nueva variable

gen lag_1_valor_x_D = D * lag_1_valor

// generamos la sumatoria de la variable anterior para todas las firmas para cada trimestre, así como los lags de la misma. Para ello generamos un preserve

preserve
collapse (sum) lag_1_valor_x_D, by(codentid Fecha_tri)
rename lag_1_valor_x_D lag_1_all_valor_x_D
xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bys codentid (Fecha_tri): gen lag_`val'_all_valor_x_D = L`num'.lag_1_all_valor_x_D
		
}

replace lag_2_all_valor_x_D = 0 if lag_2_all_valor_x_D == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_valor_x_D = 0 if lag_3_all_valor_x_D == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_valor_x_D = 0 if lag_4_all_valor_x_D == . & Fecha_tri > yq(2000, 3)
	
tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

drop _merge

// reemplazamos las variables generadas por missing para los trimestres correspondientes

replace lag_1_all_valor_x_D = . if D == .

replace lag_2_all_valor_x_D = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_valor_x_D = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_valor_x_D = . if Fecha_tri == yq(2000, 4)

// restamos el crédito externo de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_valor_x_D_sin_i = lag_1_all_valor_x_D - lag_1_valor_x_D

bys firma_banco (Fecha_tri):gen lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - L1.lag_1_valor_x_D if L1.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - 0 if L1.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - L2.lag_1_valor_x_D if L2.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - 0 if L2.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - L3.lag_1_valor_x_D if L3.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - 0 if L3.lag_1_valor_x_D == .

// generamos la sumatoria del crédito externo de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en pesos con el banco b. A esta variable la llamaremos numerador

gen numerador = .

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i + lag_4_all_valor_x_D_sin_i if Fecha_tri > yq(2000, 4)

// generamos una dummy que se activa si la firma sacó crédito externo en los cuatro trimestres anteriores 

gen dummy = 0

by firma_banco (Fecha_tri), sort: replace dummy = 1 if (L1.valor != 0 & L1.valor != .) | (L2.valor != 0 & L2.valor != .) | (L3.valor != 0 & L3.valor != .) | (L4.valor != 0 & L4.valor != .)

replace dummy = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos la dummy anterior por la dummy que indica si la firma tuvo relación en pesos con el banco b en los cuatro trimestres anteriores. Esto nos da una variable que se activa solamente si la firma tuvo tanto relación con el banco b como crédito externo en los anteriores cuatro trimestres

gen Dxdummy = D * dummy

// multiplicamos el lag de la variación del crédito local en pesos por la variable anterior 

gen Dxdummy_x_lag_1_var_capitalml = Dxdummy * lag_1_var_capitalml_USD

// generamos la sumatoria del lag del cambio en el crédito local en pesos de las firmas que sacaron crédito externo en los anteriores cuatro trimestres para cada trimestre, así como generamos los demás lags de esta variable 

preserve
collapse (sum) Dxdummy_x_lag_1_var_capitalml, by(codentid Fecha_tri)
rename Dxdummy_x_lag_1_var_capitalml lag_1_all_var_capitalml

xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bysort codentid (Fecha_tri): gen lag_`val'_all_var_capitalml = L`num'.lag_1_all_var_capitalml
		
}

replace lag_2_all_var_capitalml = 0 if lag_2_all_var_capitalml == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_var_capitalml = 0 if lag_3_all_var_capitalml == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_var_capitalml = 0 if lag_4_all_var_capitalml == . & Fecha_tri > yq(2000, 3)


tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

// reemplazamos las variables generadas por missing para los trimestres correspondientes

drop _merge

replace lag_1_all_var_capitalml = . if D == .

replace lag_2_all_var_capitalml = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_var_capitalml = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_var_capitalml = . if Fecha_tri == yq(2000, 4)

// restamos el crédito local en pesos de la firma i a la sumatoria (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_var_capitalml_sin_i = lag_1_all_var_capitalml - Dxdummy_x_lag_1_var_capitalml

bys firma_banco (Fecha_tri):gen lag_2_all_var_capitalml_sin_i = lag_2_all_var_capitalml - L1.Dxdummy_x_lag_1_var_capitalml if L1.Dxdummy_x_lag_1_var_capitalml != .
bys firma_banco (Fecha_tri): replace lag_2_all_var_capitalml_sin_i = lag_2_all_var_capitalml - 0 if L1.Dxdummy_x_lag_1_var_capitalml == .

bys firma_banco (Fecha_tri):gen lag_3_all_var_capitalml_sin_i = lag_3_all_var_capitalml - L2.Dxdummy_x_lag_1_var_capitalml if L2.Dxdummy_x_lag_1_var_capitalml != .
bys firma_banco (Fecha_tri): replace lag_3_all_var_capitalml_sin_i = lag_3_all_var_capitalml - 0 if L2.Dxdummy_x_lag_1_var_capitalml == .

bys firma_banco (Fecha_tri):gen lag_4_all_var_capitalml_sin_i = lag_4_all_var_capitalml - L3.Dxdummy_x_lag_1_var_capitalml if L3.Dxdummy_x_lag_1_var_capitalml != .
bys firma_banco (Fecha_tri): replace lag_4_all_var_capitalml_sin_i = lag_4_all_var_capitalml - 0 if L3.Dxdummy_x_lag_1_var_capitalml == .

// generamos la sumatoria del crédito local en pesos de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación en pesos con el banco b y que además sacaron crédito externo. A esta variable la llamaremos denominador 

gen denominador = .

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i + lag_2_all_var_capitalml_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i + lag_2_all_var_capitalml_sin_i + lag_3_all_var_capitalml_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capitalml_sin_i + lag_2_all_var_capitalml_sin_i + lag_3_all_var_capitalml_sin_i + lag_4_all_var_capitalml_sin_i if Fecha_tri > yq(2001, 1)

// generamos el ratio entre el numerador y el denominador. A esta variable la llamaremos X

gen X = numerador / denominador

// eliminamos las observaciones que no tienen relación con ningún banco 

drop if codentid == 0

sort firma_banco Fecha_tri

// renombramos la variable de cambio en el crédito local en pesos 

rename var_capitalml_USD acum_0_capitalml_USD

// guardamos la base de datos

save "$input\base_reg_2_20_08_2024_mon_local_denom_reduc_pre_reg.dta", replace // base que contiene las observaciones y variables necesarias para la regresión 2 con denominador reducido que toma como dependiente el crédito local en pesos 


**# 2.3) BASE REGRESIÓN 2 CON CRÉDITO LOCAL TOTAL COMO VARIABLE DEPENDIENTE

// llamamos la base que contiene las observaciones necesarias

use "$input\base_reg_2_20_08_2024_cred_total_sin_variables.dta", clear

// mergeamos con la base de datos que contiene la llave firma-banco-tiempo en la que existió relación de la firma i con el banco b en el trimestre t

merge 1:1 codentid identif Fecha_tri using "$input\relacion_i_b_t"

// eliminamos las observaciones que no mergean de la base "using"

drop if _merge == 2

drop _merge

// para aquellas observaciones en las que la variable de relación es missing, reemplazamos el valor por cero

replace relacion_i_b_t = 0 if relacion_i_b_t == .

// generamos una dummy que se activa si la firma i tuvo relación con el banco b en los cuatro trimestres anteriores

gen D = 0

by firma_banco (Fecha_tri), sort: replace D = 1 if L1.relacion_i_b_t == 1 | L2.relacion_i_b_t == 1 | L3.relacion_i_b_t == 1 | L4.relacion_i_b_t == 1

replace D = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos el primer lag del crédito externo (variable valor - recordemos que esta variable ya es un flujo) por la dummy. Esto lo hacemos generando una nueva variable

gen lag_1_valor_x_D = D * lag_1_valor

// generamos la sumatoria de la variable anterior para todas las firmas para cada trimestre, así como los lags de la misma. Para ello generamos un preserve

preserve
collapse (sum) lag_1_valor_x_D, by(codentid Fecha_tri)
rename lag_1_valor_x_D lag_1_all_valor_x_D
xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bys codentid (Fecha_tri): gen lag_`val'_all_valor_x_D = L`num'.lag_1_all_valor_x_D
		
}

replace lag_2_all_valor_x_D = 0 if lag_2_all_valor_x_D == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_valor_x_D = 0 if lag_3_all_valor_x_D == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_valor_x_D = 0 if lag_4_all_valor_x_D == . & Fecha_tri > yq(2000, 3)
	
tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

drop _merge

// reemplazamos las variables generadas por missing para los trimestres correspondientes

replace lag_1_all_valor_x_D = . if D == .

replace lag_2_all_valor_x_D = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_valor_x_D = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_valor_x_D = . if Fecha_tri == yq(2000, 4)

// restamos el crédito externo de la firma i a la suma de todo el sistema (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_valor_x_D_sin_i = lag_1_all_valor_x_D - lag_1_valor_x_D

bys firma_banco (Fecha_tri):gen lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - L1.lag_1_valor_x_D if L1.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_2_all_valor_x_D_sin_i = lag_2_all_valor_x_D - 0 if L1.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - L2.lag_1_valor_x_D if L2.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_3_all_valor_x_D_sin_i = lag_3_all_valor_x_D - 0 if L2.lag_1_valor_x_D == .

bys firma_banco (Fecha_tri):gen lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - L3.lag_1_valor_x_D if L3.lag_1_valor_x_D != .
bys firma_banco (Fecha_tri): replace lag_4_all_valor_x_D_sin_i = lag_4_all_valor_x_D - 0 if L3.lag_1_valor_x_D == .

// generamos la sumatoria del crédito externo de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación con el banco b. A esta variable la llamaremos numerador

gen numerador = .

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace numerador = lag_1_all_valor_x_D_sin_i + lag_2_all_valor_x_D_sin_i + lag_3_all_valor_x_D_sin_i + lag_4_all_valor_x_D_sin_i if Fecha_tri > yq(2000, 4)

// generamos una dummy que se activa si la firma sacó crédito externo en los cuatro trimestres anteriores 

gen dummy = 0

by firma_banco (Fecha_tri), sort: replace dummy = 1 if (L1.valor != 0 & L1.valor != .) | (L2.valor != 0 & L2.valor != .) | (L3.valor != 0 & L3.valor != .) | (L4.valor != 0 & L4.valor != .)

replace dummy = . if Fecha_tri == yq(2000, 1) // la dummy es missing para el trimestre 2000,1 ya que es nuestro primer periodo

// multiplicamos la dummy anterior por la dummy que indica si la firma tuvo relación con el banco b en los cuatro trimestres anteriores. Esto nos da una variable que se activa solamente si la firma tuvo tanto relación con el banco b como crédito externo en los anteriores cuatro trimestres

gen Dxdummy = D * dummy

// multiplicamos el lag de la variación del crédito local total por la variable anterior 

gen Dxdummy_x_lag_1_var_capital = Dxdummy * lag_1_var_capital_USD

// generamos la sumatoria del lag del cambio en el crédito local total de las firmas que sacaron crédito externo en los anteriores cuatro trimestres para cada trimestre, así como generamos los demás lags de esta variable 

preserve
collapse (sum) Dxdummy_x_lag_1_var_capital, by(codentid Fecha_tri)
rename Dxdummy_x_lag_1_var_capital lag_1_all_var_capital

xtset codentid Fecha_tri
forvalues num=1(1)3{
		local val = `num' + 1
		bysort codentid (Fecha_tri): gen lag_`val'_all_var_capital = L`num'.lag_1_all_var_capital
		
}

replace lag_2_all_var_capital = 0 if lag_2_all_var_capital == . & Fecha_tri != yq(2000, 1)
	
replace lag_3_all_var_capital = 0 if lag_3_all_var_capital == . & Fecha_tri > yq(2000, 2)
	
replace lag_4_all_var_capital = 0 if lag_4_all_var_capital == . & Fecha_tri > yq(2000, 3)


tempfile allcapital_merge
save `allcapital_merge'
restore 

merge m:1 codentid Fecha_tri using `allcapital_merge' 

// reemplazamos las variables generadas por missing para los trimestres correspondientes

drop _merge

replace lag_1_all_var_capital = . if D == .

replace lag_2_all_var_capital = . if Fecha_tri == yq(2000, 2)

replace lag_3_all_var_capital = . if Fecha_tri == yq(2000, 3)

replace lag_4_all_var_capital = . if Fecha_tri == yq(2000, 4)

// restamos el crédito local total de la firma i a la sumatoria (para cada uno de los 4 lags, según corresponda)

gen lag_1_all_var_capital_sin_i = lag_1_all_var_capital - Dxdummy_x_lag_1_var_capital

bys firma_banco (Fecha_tri):gen lag_2_all_var_capital_sin_i = lag_2_all_var_capital - L1.Dxdummy_x_lag_1_var_capital if L1.Dxdummy_x_lag_1_var_capital != .
bys firma_banco (Fecha_tri): replace lag_2_all_var_capital_sin_i = lag_2_all_var_capital - 0 if L1.Dxdummy_x_lag_1_var_capital == .

bys firma_banco (Fecha_tri):gen lag_3_all_var_capital_sin_i = lag_3_all_var_capital - L2.Dxdummy_x_lag_1_var_capital if L2.Dxdummy_x_lag_1_var_capital != .
bys firma_banco (Fecha_tri): replace lag_3_all_var_capital_sin_i = lag_3_all_var_capital - 0 if L2.Dxdummy_x_lag_1_var_capital == .

bys firma_banco (Fecha_tri):gen lag_4_all_var_capital_sin_i = lag_4_all_var_capital - L3.Dxdummy_x_lag_1_var_capital if L3.Dxdummy_x_lag_1_var_capital != .
bys firma_banco (Fecha_tri): replace lag_4_all_var_capital_sin_i = lag_4_all_var_capital - 0 if L3.Dxdummy_x_lag_1_var_capital == .

// generamos la sumatoria del crédito local total de los cuatro trimestres anteriores de todas las firmas (excepto i) que tuvieron relación con el banco b y que además sacaron crédito externo. A esta variable la llamaremos denominador 

gen denominador = .

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i if Fecha_tri == yq(2000, 2)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i + lag_2_all_var_capital_sin_i if Fecha_tri == yq(2000, 3)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i + lag_2_all_var_capital_sin_i + lag_3_all_var_capital_sin_i if Fecha_tri == yq(2000, 4)

by firma_banco (Fecha_tri), sort: replace denominador = lag_1_all_var_capital_sin_i + lag_2_all_var_capital_sin_i + lag_3_all_var_capital_sin_i + lag_4_all_var_capital_sin_i if Fecha_tri > yq(2001, 1)

// generamos el ratio entre el numerador y el denominador. A esta variable la llamaremos X

gen X = numerador / denominador

// eliminamos las observaciones que no tienen relación con ningún banco 

drop if codentid == 0

sort firma_banco Fecha_tri

// renombramos la variable de cambio en el crédito local total

rename var_capital_USD acum_0_capital_USD

// guardamos la base de datos

save "$input\base_reg_2_20_08_2024_cred_total_denom_reduc_pre_reg.dta", replace // base que contiene las observaciones y variables necesarias para la regresión 2 con denominador reducido que toma como dependiente el crédito local total 


**# 4) BASES REGRESIÓN 2.1

// llamamos la base de datos del merge de la 341 con EE (en flujo)

use "$input\Merge_341_EE_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// reemplazamos el código de las observaciones que no cuentan con ningún banco por 0

replace codentid = 0 if codentid == .

// eliminamos dichas observaciones

drop if codentid == 0

// collapsamos las variables de crédito a nivel banco-tiempo 

collapse (rawsum) capital_USD capitalme_USD capitalml_USD valor, by(Fecha_tri codentid)

// guardamos la base de datos 

save "$input\base_banco_tiempo_con cred_externo.dta", replace // base de nivel banco-tiempo que contiene las carteras de los bancos y también el cambio en el crédito externo total de las firmas que tuvieron relación con cada banco

**# 4.1) BASE REGRESIÓN 2.1 CON CARTERA EN DÓLARES COMO VARIABLE DEPENDIENTE

// llamamos la base de nivel-banco tiempo con crédito externo

use "$input\base_banco_tiempo_con cred_externo.dta", clear

// conservamos solamente las observaciones de los bancos que en algún momento tuvieron cartera en dólares 

preserve

keep if capitalme_USD != 0

keep codentid

duplicates drop 

gen cred_mon_extranj = 1 // variable que indica que estos bancos tuvieron cartera en moneda extranjera

tempfile bancos_capital_me

save `bancos_capital_me'

restore

merge m:1 codentid using `bancos_capital_me'

drop _merge

replace cred_mon_extranj = 0 if cred_mon_extranj == .

keep if cred_mon_extranj == 1 // así dejamos solamente las observaciones de los bancos que alguna vez tuvieron cartera en moneda extranjera

unique codentid // número de bancos: 26

// generamos la variable de banco 

egen banco = group(codentid)

// establecemos y balanceamos el panel

xtset banco Fecha_tri 
tsreport  Fecha_tri,  p 
tsfill, full 

// reemplazamos por cero los missings generados 

replace capital_USD = 0 if capital_USD == .
replace capitalme_USD = 0 if capitalme_USD == .
replace capitalml_USD = 0 if capitalml_USD == .
replace valor = 0 if valor == .

// generamos los flujos de las variables de cartera de los bancos 

bys banco (Fecha_tri): gen var_capital_USD = capital_USD - L1.capital_USD  // cambio de la cartera total

bys banco (Fecha_tri): gen var_capitalme_USD = capitalme_USD - L1.capitalme_USD  // cambio de la cartera en moneda extranjera

bys banco (Fecha_tri): gen var_capitalml_USD = capitalml_USD - L1.capitalml_USD  // cambio de la cartera en moneda local

replace var_capital_USD = 0 if var_capital_USD == . & capital_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capital_USD = capital_USD if var_capital_USD == . & capital_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalme_USD = 0 if var_capitalme_USD == . & capitalme_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalme_USD = capitalme_USD if var_capitalme_USD == . & capitalme_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalml_USD = 0 if var_capitalml_USD == . & capitalml_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalml_USD = capitalml_USD if var_capitalml_USD == . & capitalml_USD != 0 & Fecha_tri != yq(2000, 1)

// generamos los lags y los leads de las distintas variables 

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
    forvalues num=1(1)4{
		bys banco (Fecha_tri): gen lag_`num'_`var' = L`num'.`var'
		bys banco (Fecha_tri): gen lead_`num'_`var' = F`num'.`var'
		
	}
}

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
    replace lag_1_`var' = 0 if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	replace lead_1_`var' = 0 if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	replace lag_2_`var' = 0 if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	replace lead_2_`var' = 0 if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	replace lag_3_`var' = 0 if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	replace lead_3_`var' = 0 if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	replace lag_4_`var' = 0 if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	replace lead_4_`var' = 0 if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

// generamos los cambios acumulados de las carteras de los bancos 

foreach var in capital_USD capitalme_USD capitalml_USD {
	gen acum_1_`var' = lead_1_`var' - lag_1_`var'
	
	gen acum_2_`var' = lead_2_`var' - lag_1_`var'
	
	gen acum_3_`var' = lead_3_`var' - lag_1_`var'
	
	gen acum_4_`var' = lead_4_`var' - lag_1_`var'
}

// generamos la sumatoria del crédito externo que sacaron todas las firmas que tuvieron relación con el banco b en los cuatro trimestres anteriores. A esta variable la llamaremos numerador

gen numerador = .

by banco (Fecha_tri), sort: replace numerador = L1.valor if Fecha_tri == yq(2000, 2)

by banco (Fecha_tri), sort: replace numerador = L1.valor + L2.valor if Fecha_tri == yq(2000, 3)

by banco (Fecha_tri), sort: replace numerador = L1.valor + L2.valor + L3.valor if Fecha_tri == yq(2000, 4)

by banco (Fecha_tri), sort: replace numerador = L1.valor + L2.valor + L3.valor + L4.valor if Fecha_tri > yq(2000, 4)

// renombramos la variable del cambio en la cartera en dólares

rename var_capitalme_USD acum_0_capitalme_USD

// guardamos la base 

save "$input\base_reg_2_1.dta", replace // base para la regresión 2.2 con cartera en dólares como variable dependiente 


**# 4.2) BASE REGRESIÓN 2.1 CON CARTERA EN PESOS COMO VARIABLE DEPENDIENTE

// llamamos la base de nivel-banco tiempo con crédito externo

use "$input\base_banco_tiempo_con cred_externo.dta", clear

// conservamos solamente las observaciones de los bancos que en algún momento tuvieron cartera en pesos 

preserve

keep if capitalml_USD != 0

keep codentid

duplicates drop 

gen cred_mon_local = 1 // variable que indica que estos bancos tuvieron cartera en moneda local

tempfile bancos_capital_ml

save `bancos_capital_ml'

restore

merge m:1 codentid using `bancos_capital_ml'

drop _merge

replace cred_mon_local = 0 if cred_mon_local== .

keep if cred_mon_local == 1 // así dejamos solamente las observaciones de los bancos que alguna vez tuvieron cartera en moneda extranjera

unique codentid // número de bancos: 26

// generamos la variable de banco 

egen banco = group(codentid)

// establecemos y balanceamos el panel

xtset banco Fecha_tri 
tsreport  Fecha_tri,  p 
tsfill, full 

// reemplazamos por cero los missings generados 

replace capital_USD = 0 if capital_USD == .
replace capitalme_USD = 0 if capitalme_USD == .
replace capitalml_USD = 0 if capitalml_USD == .
replace valor = 0 if valor == .

// generamos los flujos de las variables de cartera de los bancos 

bys banco (Fecha_tri): gen var_capital_USD = capital_USD - L1.capital_USD  // cambio de la cartera total

bys banco (Fecha_tri): gen var_capitalme_USD = capitalme_USD - L1.capitalme_USD  // cambio de la cartera en moneda extranjera

bys banco (Fecha_tri): gen var_capitalml_USD = capitalml_USD - L1.capitalml_USD  // cambio de la cartera en moneda local

replace var_capital_USD = 0 if var_capital_USD == . & capital_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capital_USD = capital_USD if var_capital_USD == . & capital_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalme_USD = 0 if var_capitalme_USD == . & capitalme_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalme_USD = capitalme_USD if var_capitalme_USD == . & capitalme_USD != 0 & Fecha_tri != yq(2000, 1)

replace var_capitalml_USD = 0 if var_capitalml_USD == . & capitalml_USD == 0 & Fecha_tri != yq(2000, 1)
replace var_capitalml_USD = capitalml_USD if var_capitalml_USD == . & capitalml_USD != 0 & Fecha_tri != yq(2000, 1)

// generamos los lags y los leads de las distintas variables 

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
    forvalues num=1(1)4{
		bys banco (Fecha_tri): gen lag_`num'_`var' = L`num'.`var'
		bys banco (Fecha_tri): gen lead_`num'_`var' = F`num'.`var'
		
	}
}

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD valor capital_USD capitalme_USD capitalml_USD {
    replace lag_1_`var' = 0 if lag_1_`var' == . & Fecha_tri != yq(2000, 1)
	replace lead_1_`var' = 0 if lead_1_`var' == . & Fecha_tri != yq(2019, 4)
	
	replace lag_2_`var' = 0 if lag_2_`var' == . & Fecha_tri > yq(2000, 2)
	replace lead_2_`var' = 0 if lead_2_`var' == . & Fecha_tri < yq(2019, 3)
	
	replace lag_3_`var' = 0 if lag_3_`var' == . & Fecha_tri > yq(2000, 3)
	replace lead_3_`var' = 0 if lead_3_`var' == . & Fecha_tri < yq(2019, 2)
	
	replace lag_4_`var' = 0 if lag_4_`var' == . & Fecha_tri > yq(2000, 4)
	replace lead_4_`var' = 0 if lead_4_`var' == . & Fecha_tri < yq(2019, 1)
}

// generamos los cambios acumulados de las carteras de los bancos 

foreach var in capital_USD capitalme_USD capitalml_USD {
	gen acum_1_`var' = lead_1_`var' - lag_1_`var'
	
	gen acum_2_`var' = lead_2_`var' - lag_1_`var'
	
	gen acum_3_`var' = lead_3_`var' - lag_1_`var'
	
	gen acum_4_`var' = lead_4_`var' - lag_1_`var'
}

// generamos la sumatoria del crédito externo que sacaron todas las firmas que tuvieron relación con el banco b en los cuatro trimestres anteriores. A esta variable la llamaremos numerador

gen numerador = .

by banco (Fecha_tri), sort: replace numerador = L1.valor if Fecha_tri == yq(2000, 2)

by banco (Fecha_tri), sort: replace numerador = L1.valor + L2.valor if Fecha_tri == yq(2000, 3)

by banco (Fecha_tri), sort: replace numerador = L1.valor + L2.valor + L3.valor if Fecha_tri == yq(2000, 4)

by banco (Fecha_tri), sort: replace numerador = L1.valor + L2.valor + L3.valor + L4.valor if Fecha_tri > yq(2000, 4)

// generamos la sumatoria del cambio en la cartera en dólares para los cuatro trimestres anteriores. A esta variable la llamaremos denominador

gen denominador = .

by banco (Fecha_tri), sort: replace denominador = L1.var_capitalme_USD if Fecha_tri == yq(2000, 2)

by banco (Fecha_tri), sort: replace denominador = L1.var_capitalme_USD + L2.var_capitalme_USD if Fecha_tri == yq(2000, 3)

by banco (Fecha_tri), sort: replace denominador = L1.var_capitalme_USD + L2.var_capitalme_USD + L3.var_capitalme_USD if Fecha_tri == yq(2000, 4)

by banco (Fecha_tri), sort: replace denominador = L1.var_capitalme_USD + L2.var_capitalme_USD + L3.var_capitalme_USD + L4.var_capitalme_USD if Fecha_tri > yq(2000, 4)

// generamos el ratio entre numerador y denominador. A esta variable la llamaremos X

gen X = numerador /denominador

// renombramos la variable del cambio en la cartera en pesos

rename var_capitalml_USD acum_0_capitalml_USD

// guardamos la base 

save "$input\base_reg_2_1_mon_local.dta", replace // base para la regresión 2.2 con cartera en pesos como variable dependiente 