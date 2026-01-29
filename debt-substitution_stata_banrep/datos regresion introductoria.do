********************************************************************************
******************* BASES DE DATOS REGRESIÓN INTRODUCTORIA *********************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output"

**# DATOS HOJAS DE BALANCE

// importamos el panel de balance de los bancos 

import delimited "\\sgee128985\E\Proyectos\Datos\Balance general Bancos\Variables financieras\Panel_Entidad_Sistema_Financiero.csv", clear

// nos quedamos solamente con las entidades tipo 1

keep if tipo_entidad == 1

// conservamos solamente las variables que nos interesan (patrimonio, inversiones netas, cartera total, cartera comercial, cartera riesgosa total, cartera comercial riesgosa, activo total)

keep patrimonio inversiones_netas fecha bruta_total bruta_comercial riesgosa_total riesgosa_comercial activo_total cod_entidad

// generamos la cartera riesgosa total como proporcion del total de cartera

gen share_riesgosa = riesgosa_total / bruta_total 

// generamos la cartera comercial riesgosa como proporcion del total de cartera comercial

gen share_com_riesgosa = riesgosa_comercial/bruta_comercial 

// generamos la cartera comercial riesgosa como proporcion del total de cartera total

gen share_com_riesgosa_total = riesgosa_comercial/bruta_total 

// generamos la variable de trimestre

gen date=date(fecha, "YMD")
format %td date
gen year_month=mofd(date)
format %tm year_month

gen Fecha_tri = qofd(dofm(year_month))

format Fecha_tri %tq

// conservamos la última observación  de cada banco en cada trimestre (es decir, nos quedamos con el saldo del trimestre para cada banco)

bysort cod_entidad Fecha_tri (year_month): keep if _n == _N

// eliminamos la variable de mes

drop year_month

// dado que las variables en saldo están en miles, las reescalamos a su valor original. Solo hacemos la transformación para patrimonio, inversiones y activos ya que son los únicos saldos que nos interesan

replace activo_total = activo_total*1000 

replace inversiones_netas = inversiones_netas*1000 

replace patrimonio = patrimonio*1000 

// pasamos los saldos a millones de dolares

// mergeamos con la base de la TRM trimestral

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

// conservamos solo las observaciones que mergean

keep if _merge == 3

drop _merge

// generamos las variables en millones de dólares

gen Activo_USD = activo_total/TRM

gen Inversiones_USD = inversiones_netas/TRM

gen patrimonio_USD = patrimonio/TRM

replace Activo_USD = Activo_USD/1000000

replace Inversiones_USD = Inversiones_USD/1000000

replace patrimonio_USD = patrimonio_USD/1000000

// renombramos la variable de codigo de los bancos

rename cod_entidad codentid

// conservamos las variables que nos interesan

keep codentid Fecha_tri Activo_USD Inversiones_USD share* 

// pasamos las proporciones de cartera riesgosa a porcentaje

replace share_com_riesgosa_total = share_com_riesgosa_total * 100

replace share_riesgosa = share_riesgosa * 100

replace share_com_riesgosa = share_com_riesgosa * 100

// guardamos la base de datos

save "$input\datos_balance_reg_int_full.dta", replace  // base de datos que contiene los datos de hoja de balance de los bancos que utilizaremos en la regresión introductoria


**# GENERACIÓN BASE PARA LA REGRESIÓN

// llamamos la base de datos del merge en flujo de la 341 y la EE

use "$input\Merge_341_EE_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090" 

// collapsamos todo a nivel banco-tiempo

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri codentid)

// eliminamos las observaciones que no corresponden a ningún banco

drop if codentid == .

// nos quedaremos solo con los bancos que en algún trimestre tuvieron cartera en moneda extranjera

// hacemos un preserve para generar una sub base con los identificadores de los bancos que en algún momento tuvieron cartera en moneda extranjera

preserve

keep if capitalme_USD != 0

keep codentid

duplicates drop 

gen cred_mon_extranj = 1 // variable que indica que estos bancos tuvieron cartera en moneda extranjera

tempfile bancos_capital_me

// guardamos la sub base en un archivo temporal

save `bancos_capital_me'

restore

// mergeamos el archivo temporal con la base 

merge m:1 codentid using `bancos_capital_me'

drop _merge

// reemplazamos el indicador para que sea cero para aquellos bancos que no tuvieron cartera en moneda extranjera

replace cred_mon_extranj = 0 if cred_mon_extranj == .

// dejamos solamente las observaciones para las cuales el indicador es igual a 1

keep if cred_mon_extranj == 1

// con esto ya nos hemos quedado solamente con las observaciones de los bancos que en algún momento tuvieron cartera en moneda extranjera

unique codentid // nos quedamos con 26 bancos

// balanceamos el panel 

egen banco = group(codentid)

xtset banco Fecha_tri 
tsreport  Fecha_tri,  p 
tsfill, full 

// reemplazamos los missing por cero

replace capital_USD = 0 if capital_USD == .
replace capitalme_USD = 0 if capitalme_USD == .
replace capitalml_USD = 0 if capitalml_USD == .

// generamos el cambio en las carteras

bys banco (Fecha_tri): gen var_capital_USD = capital_USD - L1.capital_USD  // cambio del credito local total

bys banco (Fecha_tri): gen var_capitalme_USD = capitalme_USD - L1.capitalme_USD  // cambio del credito local en moneda extranjera

bys banco (Fecha_tri): gen var_capitalml_USD = capitalml_USD - L1.capitalml_USD  // cambio del credito local en moneda local

// generamos los lags y los leads de las carteras 

foreach var in var_capital_USD var_capitalme_USD var_capitalml_USD {
    forvalues num=1(1)4{
		bys banco (Fecha_tri): gen lag_`num'_`var' = L`num'.`var'
		bys banco (Fecha_tri): gen lead_`num'_`var' = F`num'.`var'
		
	}
}

// generamos los cambios acumulados en las carteras 

foreach var in capital_USD capitalme_USD capitalml_USD {
    forvalues num=1(1)4{
		bys banco (Fecha_tri): gen acum_`num'_`var' = F`num'.`var' - L1.`var'
		
	}
}

// renombramos el cambio en la cartera en moneda local para poder usarla en un loop más adelante

rename var_capitalml_USD acum_0_capitalml_USD

// recuperaremos los codigos de banco de las observaciones generadas al balancear

preserve

drop if codentid == .

keep codentid banco

duplicates drop

rename codentid cod_recu

tempfile cod

save `cod'

restore

merge m:1 banco using `cod'

replace codentid = cod_recu if codentid == .

drop _merge cod_recu

// mergamos con la base que contiene los datos de hoja de balance

merge 1:1 codentid Fecha_tri using "$input\datos_balance_reg_int_full.dta"

// mergean 1556 observaciones 

// eliminamos las observaciones que no mergean de la base de hojas de balance

drop if _merge == 2

// generemos el cambio de los activos y de la inversión

bys banco (Fecha_tri): gen acum_0_Activo_USD = Activo_USD - L1.Activo_USD  // cambio del activo

bys banco (Fecha_tri): gen acum_0_Inversiones_USD = Inversiones_USD - L1.Inversiones_USD  // cambio de las inversiones

// generamos los cambios acumulados de los activos y de la inversión

foreach var in Activo_USD Inversiones_USD {
    forvalues num=1(1)4{
		bys banco (Fecha_tri): gen acum_`num'_`var' = F`num'.`var' - L1.`var'
		
	}
}

// eliminamos la variable de _merge

drop _merge

// guardamos la base de datos

save "$input\base_reg_introductoria_activos.dta", replace // base de datos con la cartera en moneda local y en moneda extranjera de los bancos, así como con datos de hoja de balance 


**# DATOS BRECHA DE TASAS

// llamamos la base de datos de forwards

use "$input\Forwarsd_data_full", clear

// renombramos la variable de plazo en dias

rename plazo plazo_dias 

// generamos la variable de trimestre

gen Fecha_tri=qofd(date)
format Fecha_tri %tq

// generamos una variable de rango para los plazos. Clasificaremos los forwards en plazos de menor a 360 dias y mayor a 360 dias 

gen plazo_amplio = ""

replace  plazo_amplio = "<=360" if plazo_dias <= 360
replace  plazo_amplio = ">360" if plazo_dias > 360

keep if plazo_amplio == ">360"

// conservamos solo los forwards de plazo mayor a 360 dias 

keep if plazo_amplio == ">360"

// eliminamos las observaciones que no tienen datos de tasa

drop if (tasap_us == 0 | tasap_us == .) & (tasac_us == 0 | tasac_us == .)

// para las observaciones que no tienen tasap_us usamos la tasac_us

replace tasap_us = tasac_us if tasap_us == 0 & tasac_us != 0 & tasac_us != .

// eliminamos observaciones con montos negativos

drop if montous < 0

// sacamos el promedio ponderado de la tasa forward para cada trimestre

collapse (mean) tasap_us [aw=montous], by(Fecha_tri)

// guardamos la base de datos 

save "$input\Forwarsd_merge_bonos", replace // base de datos que contiene el promedio ponderado de la tasa forward para los forwards mayores a 360 dias para cada trimestre

// llamamos la base de datos de tasa de interés de TES y treasuries a 10 años y TRM trimestral 

use "$input\tasas_bonos_10y_TRM.dta", clear

// mergeamos con la base de forwards que generamos

merge 1:1 Fecha_tri using  "$input\Forwarsd_merge_bonos"

// conservamos solamente las observaciones que mergean

keep if _merge==3

// transformamos la tasa de TES a dolares por medio de la CIP 

gen tasa_col_comparable_1= tasa_COL_10y - ln(tasap_us) + ln(TRM)
gen tasa_col_comparable_2=((TRM/tasap_us)*(1+tasa_COL_10y))-1

// generamos la brecha de tasas como la diferencia entre la tasa de TES (transformada) y la tasa de Treasuries

gen brecha_tasas_1=tasa_col_comparable_1-tasa_US_10y 
gen brecha_tasas_2=tasa_col_comparable_2-tasa_US_10y

// eliminamos las observaciones para las cuales no existe brecha 

drop if  brecha_tasas_2 == .

// eliminamos la variable _merge 

drop _merge

// eliminamos las observaciones posteriores a 2019, 4

drop if Fecha_tri > yq(2019,4)

// guardamos la base de datos 

save "$input\brecha_tasas_comparable.dta", replace // base de datos que contiene la brecha de tasas 


**# DATOS BRECHA DE TASAS DE CRÉDITOS

// llamamos la base de datos de saldos

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090" 

// dejamos solamente la primera observación de cada crédito

bysort identif codentid fechinic fechfin plazo_inic_dias tasa_comparable_2: keep if _n == 1

// collapsamos todo a nivel firma-tiempo (recordemos que los datos de EE ya se encuentran a nivel firma-tiempo, pero los de 341 están a nivel firma-banco-tiempo)

collapse (rawsum) capital_USD capitalme_USD capitalml_USD (lastnm) tasa_originacion_EE saldo (max) marca_forward_preciso insularidad_definitiva (mean) tasa_comparable_2 tasa_originacion [aw = capital_USD], by(Fecha_tri identif)

// generamos una variable de tasa de credito local (toma tanto las tasas de los créditos en dólares como las de los créditos en pesos transformada por medio de la CIP)

rename tasa_comparable_2 tasa_local

// los siguientes preserve son para generar sub bases que contengan el promedio ponderado (por monto) de cada una de las tasas para cada trimestre

// promedio ponderado de la tasa local

preserve

collapse (mean) tasa_local [aw = capital_USD], by(Fecha_tri)
*collapse (mean) tasa_ml [aw = capital], by(Fecha_tri)

save "$input\tasas_locales_trimestre", replace

restore

// mergeamos cada una de las subbases que contienen los promedios ponderados de las tasas locales y externas por trimestre 

use "$input\tasas_locales_trimestre", clear

merge 1:1 Fecha_tri using "$input\tasas_EE_trimestre"

drop _merge

// generamos la brecha de tasas (diferencia entre las tasas de créditos locales y las tasas de créditos externos)

gen brecha_tasas_cred= tasa_local - tasa_originacion_EE

// conservamos solamente la brecha de tasas 

keep Fecha_tri brecha_tasas_cred

sum brecha_tasas_cred // la media de la brecha de tasas es 6.352102

// guardamos la base de datos 

save "$input\brecha_tasas_creditos.dta", replace // base de datos que contiene la brecha de tasas de los créditos 


**# DATOS DE POSICIÓN PROPIA (PP)

// llamamos la base que contiene los datos de posición propia (pp) (como porporcion del patrimonio técnico) para antes de 2015

use "Z:\Tomas\PP y PPC\Base_PP_PPC_PT.dta", clear

// la base está en formato wide

// conservamos solamente las variables de fecha y de pp para cada entidad

keep date *PP

// pasamos la base de formato wide a formato long

reshape long @PP, i(date) j(nomentid) string

// generamos la variable codentid (codigo de banco) 

gen codentid = .

// reemplazamos el código para cada banco uno por uno

replace codentid = 8 if nomentid == "ABNAMROBank"

replace codentid = 13 if nomentid == "BBVA"

replace codentid = 43 if nomentid == "BanAgrario"

replace codentid = 52 if nomentid == "Bancamia"

replace codentid = 49 if nomentid == "BancoAVvillas"

replace codentid = 30 if nomentid == "BancoCajaSocial"

replace codentid = 6 if nomentid == "BancoSantander"

replace codentid = 1 if nomentid == "BancodeBogotá"

replace codentid = 23 if nomentid == "BancodeOccidente"

replace codentid = 7 if nomentid == "Bancolombia"

replace codentid = 9 if nomentid == "Citibank"

replace codentid = 42 if nomentid == "Colpatria"

replace codentid = 39 if nomentid == "Davivienda"

replace codentid = 56 if nomentid == "FALABELLA"

replace codentid = 62 if nomentid == "FINAMERICA"

replace codentid = 10 if nomentid == "HSBC"

replace codentid = 14 if nomentid == "HelmBank"

replace codentid = 14 if nomentid == "Itau"

replace codentid = 64 if nomentid == "JPMorgan"

replace codentid = 57 if nomentid == "Pichincha"

replace codentid = 2 if nomentid == "Popular"

replace codentid = 51 if nomentid == "Procredit"

replace codentid = 12 if nomentid == "Sudameris"

replace codentid = 53 if nomentid == "WWB"

replace codentid = 66 if nomentid == "BTGPactual"

// eliminamos las observaciones que no tienen codigo (corresponden a entidades que no nos interesan)

drop if codentid == .

// eliminamos la variable de nombre de entidad 

drop nomentid

// generamos la variable de trimestre 

gen Fecha_tri = yq(year(date), quarter(date))

format Fecha_tri %tq

// nos quedamos solamente con la última observación de cada trimestre para cada entidad 

bysort Fecha_tri codentid: keep if _n == _N

// eliminamos la variable de fecha

drop date

// guardamos la base de datos 

save "$input\PP_2003_2015.dta", replace // base de datos que contiene los datos de posición propia de 2003 a 2015 para cada entidad con periodicidad trimestral

// llamamos la base con los datos de posición propia de 2015 en adelante 

use "$input\Posicion_propia_def.dta", clear

// conservamos solamente las variables de código de la entidad, de fecha y de pp (como proporcion del patrimonio técnico)

keep CODIGO_ENTIDAD FECHA PP_PT

// generamos la variable de trimestre

gen Fecha_tri = yq(year(FECHA), quarter(FECHA))

format Fecha_tri %tq

// dejamos solamente la úlima observación de cada trimestre para cada banco 

bysort CODIGO_ENTIDAD Fecha_tri: keep if _n == _N

// eliminamos la variable de fecha

drop FECHA

// renombramos las variables de pp y de codigo

rename PP_PT PP

rename CODIGO_ENTIDAD codentid

// dejamos solamente los datos para el periodo que nos interesa

drop if Fecha_tri < yq(2015, 3) | Fecha_tri > yq(2019, 4)

// guardamos la base de datos 

save "$input\PP_2015_2019.dta", replace // base de datos que contiene los datos de posición propia de 2015 a 2019 para cada entidad con periodicidad trimestral

// appendeamos las bases de datos para ambos periodos

use "$input\PP_2003_2015.dta", clear

append using "$input\PP_2015_2019.dta"

// eliminamos las observaciones que no cuentan con datos de pp

drop if PP == .

// pasamos la posicion propia a porcentaje (recordemos que esta como proporción del patrimonio técnico)

replace PP = PP * 100

// guardamos la base de datos 

save "$input\PP_2003_2019.dta", replace // base de datos que contiene los datos de posición propia de 2003 a 2019 para cada entidad con periodicidad trimestral


**# DATOS CAMBIO BRUSCO

// llamamos la base de saldos 

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// collapsamos todo a firma-tiempo (recordando que los datos de EE ya estaban en nivel firma-tiempo pero los de 341 estaban a nivel firma-banco-tiempo)

collapse (rawsum) capital_USD capitalme_USD capitalml_USD (lastnm) saldo, by(Fecha_tri identif)

// collapsamos a nivel de tiempo 

collapse (rawsum) capital_USD capitalme_USD capitalml_USD saldo, by(Fecha_tri)

// ahora generamos la variable (EFE/(EFF+IMC)) donde EFE es el total de credito con entidades externas e IMC es el total del credito con entidades locales (todo por trimestre).

gen ratio_EFE_IMC = saldo/(saldo + capital_USD)

// sacamos el cambio de este ratio 

gen var_ratio_EFE_IMC = ratio_EFE_IMC - ratio_EFE_IMC[_n - 1]

// generaremos distintas variables que indiquen si el cambio en el ratio es brusco o no, según distintos criterios 

// primero generamos un criterio que toma los datos se encuentran por debajo del percentil 5 o por encima del percentil 95:

gen cambio_brusco_1 = 0

replace cambio_brusco_1 = 1 if var_ratio_EFE_IMC < -.0292897 | var_ratio_EFE_IMC > .0341147

// generamos un criterio que solo toma los datos por encima del percentil 95

gen brusco_positivo = 0 

replace brusco_positivo = 1 if var_ratio_EFE_IMC > .0341147 

// generamos un criterio que solo toma los datos por debajo del percentil 5

gen brusco_negativo = 0 

replace brusco_negativo = 1 if var_ratio_EFE_IMC < -.0292897 

// generamos un segundo criterio que toma los datos que estan por debajo del 10 y encima del 90

gen cambio_brusco_2 = 0

replace cambio_brusco_2 = 1 if var_ratio_EFE_IMC < -.024961 | var_ratio_EFE_IMC > .0274745 // esto nos da 16 trimestres en los que hay cambios bruscos

// un último criterio que toma los datos para los cuales el cambio (en valor absoluto) aleja mas de 1.5 desviaciones estandar de la media

// vemos las descriptivas del cambio en el ratio

summ var_ratio_EFE_IMC

// guardamos la media y la desviación estandar

local media = r(mean)
local sd = r(sd)

// generamos la variable

gen cambio_brusco_3 = 0

replace cambio_brusco_3 = 1 if abs(var_ratio_EFE_IMC) > `media' + 1.5*`sd'

// reemplazamos los cambios bruscos para que sean missing para las observaciones que no tienen cambio en el ratio

replace cambio_brusco_1 = . if var_ratio_EFE_IMC == .
replace cambio_brusco_2 = . if var_ratio_EFE_IMC == .
replace cambio_brusco_3 = . if var_ratio_EFE_IMC == .

// nos quedamos solamente con las variables que nos interesan

keep Fecha_tri ratio_EFE_IMC var_ratio_EFE_IMC cambio_brusco* brusco_negativo brusco_positivo

// guardamos esta base de datos

save "$input\variables_cambio_brusco.dta", replace // base de datos que contiene las variables de cambio brusco en el ratio entre crédito externo y el crédito total de todo el sistema para cada trimestre 


**# HISTOGRAMA DEL CAMBIO EN (EFE/(EFF+IMC))

// generaremos un histograma para ver la distribución del cambio en el ratio (EFE/(EFF+IMC))

// llamamos la base de datos con las variables de cambio brusco

use "$input\variables_cambio_brusco.dta", clear

// eliminamos las observaciones posteriores a 2019, 4

drop if Fecha_tri > yq(2019, 4)

// graficamos el histograma 

histogram var_ratio_EFE_IMC, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Δ (crédito externo/(crédito externo+crédito local))") note("La variable se calcula por trimestre para todo el sistema.") bin(20) xlabel(-.05(0.025).15)

graph export "$output\descriptivas\histograma cambio ratio EFE_IMC.png", replace


**# CORRELACIÓN (EFE/(EFF+IMC)) CON BRECHA DE TASAS 

// utilizando la misma base, mergeamos con los datos de brecha de tasas 

merge 1:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// realizamos la correlación

pwcorr ratio_EFE_IMC brecha_tasas_2, sig