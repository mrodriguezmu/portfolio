********************************************************************************
**************************** GRÁFICAS Y DESCRIPTIVAS ***************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output"


**# SALDOS DE CRÉDITO PARA TODO EL SISTEMA

// llamamos la base de datos de saldos

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear

// collapsamos todo a nivel firma-tiempo (recordemos que, si bien las variables de EE ya estan a nivel firma-tiempo, las de 341 estan a nivel firma-banco-tiempo)

collapse (rawsum) capital_USD capitalme_USD capitalml_USD (lastnm) capitalme_USD_EE saldo (max) insularidad_definitiva, by(Fecha_tri identif)

// eliminamos a MinHacienda de la base de datos

drop if identif == "899999090"

// generamos un preserve

preserve

// collapsamos (suma) las variables capitalme_USD (crédito local en moneda extranjera), capitalml_USD (crédito local en moneda local) y saldo (crédito externo) a nivel de trimestre. De esta forma, obtendremos lo saldos de cada una de esas variables de para todo el sistema en cada trimestre

collapse (rawsum) capitalme_USD capitalml_USD saldo, by(Fecha_tri)

// realizamos el gráfico de los saldos de crédito local en moneda extranjera, crédito local en moneda local y crédito externo (todo medido en millones de dolares) para todo el sistema

twoway (line capitalme_USD Fecha_tri, lcolor(blue) lpattern(solid)) ///
(line capitalml_USD Fecha_tri, lcolor(red) lpattern(solid)) ///
(line saldo Fecha_tri, lcolor(green) lpattern(solid)), ytitle("Millones de dolares") xtitle("trimestre") legend(order(1 "Crédito local en" "moneda extranjera"  2 "Crédito local en" "moneda local" 3 "Crédito externo")) graphregion(color(white)) plotregion(color(white) style(none))

graph export "$output\descriptivas\saldos sistema.png", replace

// restauramos la base de datos

restore


**# PROMEDIO DE CRÉDITO DE LAS FIRMAS

// a partir de la misma base a nivel firma-tiempo realizaremos también la gráfica del promedio de crédito de las firmas para cada trimestre

// generamos un preserve

preserve

// collapsamos (promedio) las variables capitalme_USD (crédito local en moneda extranjera), capitalml_USD (crédito local en moneda local) y saldo (crédito externo) a nivel de trimestre. De esta forma, obtendremos el promedio por firma de cada una de esas variables en cada trimestre

collapse (mean) capitalme_USD capitalml_USD saldo, by(Fecha_tri)

// realizamos el gráfico del promedio por firma de crédito local en moneda extranjera, crédito local en moneda local y crédito externo (todo medido en millones de dolares)

twoway (line capitalme_USD Fecha_tri, lcolor(blue) lpattern(solid)) ///
(line capitalml_USD Fecha_tri, lcolor(red) lpattern(solid)) ///
(line saldo Fecha_tri, lcolor(green) lpattern(solid)), ytitle("Millones de dolares") xtitle("trimestre") legend(order(1 "Crédito local en" "moneda extranjera"  2 "Crédito local en" "moneda local" 3 "Crédito externo")) graphregion(color(white)) plotregion(color(white) style(none))

graph export "$output\descriptivas\promedios crédito.png", replace

restore


**# CRÉDITO EN PESOS VS CRÉDITO EN DÓLARES POR INSULARIDAD

// de nuevo, partimos de la base ya collapsada a nivel firma-tiempo 

// generamos una unica variable de crédito local en moneda extranjera, usando tanto los datos de la 341 como los de la EE. Lo que haremos será tomar como fuente principal los datos de la 341; es decir que si una observacion cuenta con capitalme para la 341 y tambien para la EE, solo se toma el valor de la 341. Pero si una observacion sale sin capitalme en la 341 pero si en la EE, entonces se toma la de la EE

replace capitalme_USD = capitalme_USD_EE if capitalme_USD == 0 & capitalme_USD_EE != 0

// collapsamos (suma) las variables capitalme_USD (crédito local en moneda extranjera), capitalml_USD (crédito local en moneda local) y saldo (crédito externo) a nivel de trimestre-insularidad. De esta forma, obtendremos el saldo de cada tipo de crédito ´pr firma en cada trimestre.

collapse (rawsum) capitalme_USD capitalml_USD saldo, by(Fecha_tri insularidad_definitiva)

// renombramos el capital local en moneda local

rename capitalml_USD moneda_local

// generamos una sola variable de crédito en moneda extranjera

gen moneda_extranjera = capitalme_USD + saldo

// eliminamos las variables que no necesitamos

drop capitalme_USD saldo 

// generamos la gráfica de crédito en pesos vs crédito en dólares por insularidad (medido en millones de dólares)

twoway (line moneda_local Fecha_tri if insularidad_definitiva == 1, lcolor(blue) lpattern(solid)) ///
(line moneda_local Fecha_tri if insularidad_definitiva == 2, lcolor(red) lpattern(solid)) ///
(line moneda_local Fecha_tri if insularidad_definitiva == 3, lcolor(green) lpattern(solid)) ///
	(line moneda_local Fecha_tri if insularidad_definitiva == 4, lcolor(orange) lpattern(solid)) ///
	(line moneda_local Fecha_tri if insularidad_definitiva == 5, lcolor(purple) lpattern(solid)) /// name(panel1, replace)
	(line moneda_extranjera Fecha_tri if insularidad_definitiva == 3, lcolor(green) lpattern(dash)) ///
	(line moneda_extranjera Fecha_tri if insularidad_definitiva == 4, lcolor(orange) lpattern(dash)) ///
	(line moneda_extranjera Fecha_tri if insularidad_definitiva == 5, lcolor(purple) lpattern(dash)), ytitle("Millones de dolares") xtitle("trimestre")  legend(order(1 "Crédito COP insularidad 1"  2 "Crédito COP insularidad 2" 3 "Crédito COP insularidad 3" 4 "Crédito COP insularidad 4" 5 "Crédito COP insularidad 5" 6 "Crédito USD insularidad 3" 7 "Crédito USD insularidad 4" 8 "Crédito USD insularidad 5")) graphregion(color(white)) plotregion(color(white) style(none))
	
graph export "$output\descriptivas\pesos vs dólares por insularidad.png", replace
	

**# HISTOGRAMAS RATIO FORWARD/TRM

// llamamos la base con los datos de 341 preprocesada y con tasas de interés comparables

use "$input\base341_tasas_comparables", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// dejamos solamente la primera observación de cada crédito

bysort identif codentid fechinic fechfin plazo_inic_dias tasa_comparable_2: keep if _n == 1

// dejamos solamente las observaciones para las cuales se transformó la tasa; es decir, los créditos en moneda local

keep if capitalml != 0

// generamos el ratio forward/TRM para cada observación

gen F_E = forward/TRM

// graficamos el histograma del ratio forward/TRM

histogram F_E, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Forward/TRM") note("Se toman solamente las tasas de los créditos nuevos en cada trimestre.")

graph export "$output\descriptivas\histograma ratio forward_TRM.png", replace

// se observa que la relación en la enorme mayoría está entre 1 y 1.1 (lo que explica el cambio mínimo en las tasas al transformarlas por medio de la CIP)

// graficamos el histograma del ratio forward/TRM solamente para los créditos menores a un año

// br if plazo != ">360" // para ver cuantas observaciones toma el gráfico

histogram F_E if plazo != ">360", graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Forward/TRM") note("Se muestran solamente los datos para los creditos de plazo menor o igual a 360 días:" "2,660,454 observaciones." "Se toman solamente las tasas de los créditos nuevos en cada trimestre.")

graph export "$output\descriptivas\histograma ratio forward_TRM menor a 360.png", replace

// graficamos el histograma del ratio forward/TRM solamente para los créditos mayores a un año

// br if plazo == ">360" // para ver cuantas observaciones toma el gráfico

histogram F_E if plazo == ">360", graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Forward/TRM") note("Se muestran solamente los datos para los créditos de plazo mayor a 360 días:" "6,611,413 observaciones." "Se toman solamente las tasas de los créditos nuevos en cada trimestre.") xlabel(.8(0.2)1.8)

graph export "$output\descriptivas\histograma ratio forward_TRM mayor a 360.png", replace


**# COMPARACIÓN TASA CRÉDITOS EN PESOS SIN TRANSFORMAR VS TASA CRÉDITOS EN PESOS TRANSFORMADA POR MEDIO DE LA CIP

// llamamos la base de datos de saldos

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090" 

// dejamos solamente la primera observación de cada crédito

bysort identif codentid fechinic fechfin plazo_inic_dias tasa_comparable_2: keep if _n == 1

// collapsamos todo a nivel firma-tiempo (recordemos que los datos de EE ya se encuentran a nivel firma-tiempo, pero los de 341 están a nivel firma-banco-tiempo)

collapse (rawsum) capital_USD capitalme_USD capitalml_USD (lastnm) tasa_originacion_EE saldo (max) marca_forward_preciso insularidad_definitiva (mean) tasa_comparable_2 tasa_originacion [aw = capital_USD], by(Fecha_tri identif)

// generamos una variable de tasa de credito local en moneda local sin transformar

gen tasa_ml_nt = .
replace tasa_ml_nt = tasa_originacion if capitalme_USD != capital_USD

// generamos una variable de tasa de credito local en moneda extranjera

gen tasa_me = .
replace tasa_me = tasa_comparable_2 if capitalme_USD == capital_USD

// generamos una variable de tasa de credito local en moneda local transformada por medio de la CIP

gen tasa_ml = .
replace tasa_ml = tasa_comparable_2 if capitalme_USD != capital_USD

// los siguientes preserve son para generar sub bases que contengan el promedio ponderado (por monto) de cada una de las tasas para cada trimestre

preserve

// promedio ponderado de la tasa local en moneda local sin transformar

collapse (mean) tasa_ml_nt  [aw = capital_USD], by(Fecha_tri)

save "$input\tasas_ml_nt_341_trimestre", replace

restore


preserve

// promedio ponderado de la tasa local en moneda extranjera

collapse (mean) tasa_me [aw = capital_USD], by(Fecha_tri)

save "$input\tasas_me_341_trimestre", replace

restore


preserve

// promedio ponderado de la tasa local en moneda local transformada

collapse (mean) tasa_ml [aw = capital_USD], by(Fecha_tri)
*collapse (mean) tasa_ml [aw = capital], by(Fecha_tri)

save "$input\tasas_ml_341_trimestre", replace

restore


// realizamos el mismo proceso para las tasas de los créditos externos

// para ello, llamamos la base de saldos de EE

use "$input\Base_saldos_EE.dta", clear

// dejamos solamente la primera observación de cada crédito

bysort prestamo: keep if _n == 1

preserve

// promedio ponderado de la tasa externa

collapse (mean) tasa_originacion_EE [aw = saldo], by(Fecha_tri)

save "$input\tasas_EE_trimestre", replace

restore

// mergeamos cada una de las subbases que contienen los promedios ponderados de las tasas por trimestre 

use "$input\tasas_ml_341_trimestre", clear

merge 1:1 Fecha_tri using "$input\tasas_me_341_trimestre"

drop _merge

merge 1:1 Fecha_tri using "$input\tasas_EE_trimestre"

drop _merge

merge 1:1 Fecha_tri using "$input\tasas_ml_nt_341_trimestre"

drop _merge

// graficamos la comparación entre la tasa de los créditos en pesos sin transformar vs la tasa de los créditos en pesos transformada por medio de la CIP

twoway (line tasa_ml Fecha_tri, lcolor(blue) lpattern(solid)) ///
(line tasa_ml_nt Fecha_tri, lcolor(red) lpattern(solid)), ytitle("porcentaje") xtitle("trimestre") legend(order(1 "Tasa transformada"  2 "Tasa sin transformar")) graphregion(color(white)) plotregion(color(white) style(none)) note("Se toman solamente las tasas de los créditos nuevos en cada trimestre.")

graph export "$output\descriptivas\tasa pesos transformada vs sin transformar.png", replace


**# COMPARACIÓN TASAS DE INTERÉS

// a partir de la base anterior compararemos las tasas de: créditos locales en moneda local (transformada por medio de la CIP) vs créditos locales en moneda extranjera vs créditos externos

twoway (line tasa_me Fecha_tri, lcolor(blue) lpattern(solid)) ///
(line tasa_ml Fecha_tri, lcolor(red) lpattern(solid)) ///
(line tasa_originacion_EE Fecha_tri, lcolor(green) lpattern(solid)), ytitle("porcentaje") xtitle("trimestre") legend(order(1 "Tasa crédito local" "en moneda extranjera"  2 "Tasa crédito local" "en moneda local" 3 "Tasa crédito externo")) note("La tasa del crédito local en moneda local fue transformada por medio de la CIP." "Se toman solamente las tasas de los créditos nuevos en cada trimestre.") graphregion(color(white)) plotregion(color(white) style(none))

graph export "$output\descriptivas\comparación tasas de interés.png", replace