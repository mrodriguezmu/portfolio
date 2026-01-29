********************************************************************************
*************** ANÁLISIS DESCRIPTIVO CREDIT DEBT SUBSTITUTION ******************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output\descriptivas"


**# 1) GRÁFICAS DESCRIPTIVAS ENDEUDAMIENTO EXTERNO

// como primer paso, llamamos la base de Endeudamiento Externo original para recuperar la variable de actividad economica

use "$input\Base_Flujos_EE.dta" , clear

// eliminamos observaciones con formato erroneo

destring anio, replace force 
drop if anio == .

// renombramos la variable nit

rename nit identif
*destring identif, replace force
generate str identif_string = identif
replace identif = ""
compress identif
replace identif = identif_string
drop identif_string
describe identif

// modificamos el formato de la variable identif (nit de las empresas)

gen nit_len=strlen(identif)
tab nit_len
rename identif nit_original
gen identif=nit_original
replace identif=substr(identif,1,9) if nit_len==10

// nos quedamos solamente con la variable de nit y de actividad economica 

keep identif actividadeconomica

// eliminamos duplicados

duplicates drop

// collapsamos 

collapse (lastnm) actividadeconomica, by(identif)

// guardamos esta base de datos 

save "$input\actividad_economica_firmas_EE.dta", replace // base de datos que contiene la actividad economica de cada firma de la base EE

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-tiempo

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos aquellas observaciones que no tienen crédito externo

drop if valor == 0

// guardamos una sub base que contenga solamente los nits de las firmas que sacaron crédito externo, la fecha trimestral y el año

preserve

	keep identif Fecha_tri

	// generamos la variable de año 

	gen year = floor(Fecha_tri/4) + 1960

	// guardamos esta base de datos 

	save "$input\nits_cred_externo_por_trimestre.dta", replace

restore

// mergeamos con la base de actividad economica

merge m:1 identif using "$input\actividad_economica_firmas_EE.dta"

// nos quedamos solo con las que mergean

keep if _merge == 3

// eliminamos la variable _merge 

drop _merge

// por trimestre, asignemosle a cada firma a qué percentil pertenece 

sort Fecha_tri identif

egen rank = rank(valor), by(Fecha_tri)

egen total_firmas = count(valor), by(Fecha_tri)

gen percentil = (rank/total_firmas) * 100

gen group_percentil = .

replace group_percentil = 25 if percentil <= 25

replace group_percentil = 50 if percentil > 25 & percentil <= 50 

replace group_percentil = 75 if percentil > 50 & percentil <= 75

replace group_percentil = 100 if percentil > 75

// marquemos, por trimestre, a las firmas por encima el percentil 75 (aquellas que más sacaron crédito externo). Dicho de otra forma, para cada trimestre conservaremos el Top 25% de firmas que más desembolsos de crédito externo tomaron.

preserve

	gen top_externo = 0

	replace top_externo = 1 if group_percentil == 100

	// guardemos esta información en una base de datos 

	keep identif Fecha_tri top_externo valor

	rename valor desem_externo

	keep if top_externo == 1

	save "$input\top_firmas_cred_externo.dta", replace // Base de datos que, para cada trimestre, contiene los desembolsos de 	crédito externo del Top 25% de firmas que más desembolsos de crédito externo tomaron.

restore

**# 1.1) TOTAL DE FIRMAS QUE TOMAN DESEMBOLSOS POR TRIMESTRE

preserve

	gen num_firmas = 1

	collapse (sum) num_firmas, by(Fecha_tri)

	twoway (line num_firmas  Fecha_tri, lcolor(red) lpattern(solid)), ytitle("Firmas") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) note("Se muestra el total de firmas a las que se les desembolsa crédito externo en cada trimestre.")

	graph export "$output\total firmas cred externo.png", replace

restore

**# 1.2) TOTAL DE DESEMBOLSOS POR TRIMESTRE

preserve

	collapse (sum) valor, by(Fecha_tri)

	twoway (line valor  Fecha_tri, lcolor(blue) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Desembolsos crédito externo")) note("Se muestra el total de desembolsos de crédito externo de todo el sistema para cada trimestre.")

	graph export "$output\total desembolsos cred externo.png", replace

restore

**# 1.3) PROMEDIO DE DESEMBOLSOS POR TRIMESTRE

preserve

	collapse (mean) valor, by(Fecha_tri)

	twoway (line valor  Fecha_tri, lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Desembolsos crédito externo")) note("Se muestra el promedio de desembolsos de crédito externo de las firmas para cada trimestre.")

	graph export "$output\promedio desembolsos cred externo.png", replace

restore

**# 1.4) TOTAL DESEMBOLSOS POR TRIMESTRE DISTINGUIENDO POR PERCENTIL

preserve 

	collapse (sum) valor, by(Fecha_tri group_percentil)

	**# 1.4.1) POR DEBAJO DEL PERCENTIL 75

	twoway (line valor Fecha_tri if group_percentil == 25, lcolor(blue) lpattern(solid)) ///
	(line valor Fecha_tri if group_percentil == 50, lcolor(red) lpattern(solid)) ///
	(line valor Fecha_tri if group_percentil == 75, lcolor(green) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Menor o igual al percentil 25" 2 "Entre el percentil 25 y 50" 3 "Entre el percentil 50 y 75")) note("Se muestra el total de desembolsos de crédito externo, agrupando por percentil, para cada" "trimestre.")

	graph export "$output\total desembolsos cred externo por percentil.png", replace

	**# 1.4.2) POR ENCIMA DEL PERCENTIL 75

	twoway (line valor Fecha_tri if group_percentil == 100, lcolor(gold) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Mayor al percentil 75")) note("Se muestra el total de desembolsos de crédito externo para las firmas por encima del" "percentil 75 en cada trimestre.")

	graph export "$output\total desembolsos cred externo mayor percentil 75.png", replace

restore

**# 1.5) PROMEDIO DESEMBOLSOS POR TRIMESTRE DISTINGUIENDO POR PERCENTIL

preserve 

	collapse (mean) valor, by(Fecha_tri group_percentil)

	**# 1.5.1) POR DEBAJO DEL PERCENTIL 75

	twoway (line valor Fecha_tri if group_percentil == 25, lcolor(blue) lpattern(solid)) ///
	(line valor Fecha_tri if group_percentil == 50, lcolor(red) lpattern(solid)) ///
	(line valor Fecha_tri if group_percentil == 75, lcolor(green) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Menor o igual al percentil 25" 2 "Entre el percentil 25 y 50" 3 "Entre el percentil 50 y 75")) note("Se muestra el promedio de desembolsos de crédito externo, agrupando por percentil, para cada" "trimestre.")

	graph export "$output\promedio desembolsos cred externo por percentil.png", replace

	**# 1.5.2) POR ENCIMA DEL PERCENTIL 75

	twoway (line valor Fecha_tri if group_percentil == 100, lcolor(gold) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Mayor al percentil 75")) note("Se muestra el promedio de desembolsos de crédito externo para las firmas por encima del" "percentil 75 en cada trimestre.")

	graph export "$output\promedio desembolsos cred externo mayor percentil 75.png", replace

restore

**# 1.6) PROPORCIÓN NÚMERO DE FIRMAS POR ACTIVIDAD ECONÓMICA 2000-2019

preserve

	collapse (count) valor, by(actividadeconomica)

	encode actividadeconomica, gen(actividad)

	// NOTA: para el siguiente gráfico, se modifica manualmente (en el editor de gráficos de Stata) la ubicación de las etiquetas.

	graph pie valor, over(actividad) plabel(_all percent) legend(size(small) order(1 "Agricultura, ganaderia, caza" 2 "Hotelería y restaurantes" 3 "Construcción" 4 "Electricidad gas y agua" 5 "Explotacion minas y canteras" 6 "Financiero, inmobiliario" 7 "Manufacturas" 8 "Servicios comunales, sociales y personales                       " 9 "Transporte, almacenamiento y comunicaciones")) note("Porcentaje del número de firmas por actividad económica a las que se les desembolsa crédito externo para" "el periodo 2000-2019.") graphregion(color(white)) plotregion(color(white) style(none))

	graph export "$output\numero de firmas por actividad 2000_2019.png", replace

restore

**# 1.7) PROPORCIÓN MONTO DESEMBOLSADO POR ACTIVIDAD ECONÓMICA 2000-2019

preserve

	collapse (sum) valor, by(actividadeconomica)

	encode actividadeconomica, gen(actividad)

	// NOTA: para el siguiente gráfico, se modifica manualmente (en el editor de gráficos de Stata) la ubicación de las etiquetas.

	graph pie valor, over(actividad) plabel(_all percent) legend(size(small) order(1 "Agricultura, ganaderia, caza" 2 "Hotelería y restaurantes" 3 "Construcción" 4 "Electricidad gas y agua" 5 "Explotacion minas y canteras" 6 "Financiero, inmobiliario" 7 "Manufacturas" 8 "Servicios comunales, sociales y personales                       " 9 "Transporte, almacenamiento y comunicaciones")) note("Porcentaje sobre el total de desembolsos de crédito externo por actividad económica para el periodo" "2000-2019.") graphregion(color(white)) plotregion(color(white) style(none))

	graph export "$output\monto desembolso por actividad 2000_2019.png", replace

restore

**# 1.8) PROPORCIÓN NÚMERO DE FIRMAS POR ACTIVIDAD ECONÓMICA 2000-2009

preserve

	keep if Fecha_tri < yq(2010,1)

	collapse (count) valor, by(actividadeconomica)

	encode actividadeconomica, gen(actividad)

	// NOTA: para el siguiente gráfico, se modifica manualmente (en el editor de gráficos de Stata) la ubicación de las etiquetas.

	graph pie valor, over(actividad) plabel(_all percent) legend(size(small) order(1 "Agricultura, ganaderia, caza" 2 "Hotelería y restaurantes" 3 "Construcción" 4 "Electricidad gas y agua" 5 "Explotacion minas y canteras" 6 "Financiero, inmobiliario" 7 "Manufacturas" 8 "Servicios comunales, sociales y personales                       " 9 "Transporte, almacenamiento y comunicaciones")) note("Porcentaje del número de firmas por actividad económica a las que se les desembolsa crédito externo para" "el periodo 2000-2009.") graphregion(color(white)) plotregion(color(white) style(none))

	graph export "$output\numero de firmas por actividad 2000_2009.png", replace

restore

**# 1.9) PROPORCIÓN MONTO DESEMBOLSADO POR ACTIVIDAD ECONÓMICA 2000-2009

preserve

	keep if Fecha_tri < yq(2010,1)

	collapse (sum) valor, by(actividadeconomica)

	encode actividadeconomica, gen(actividad)

	// NOTA: para el siguiente gráfico, se modifica manualmente (en el editor de gráficos de Stata) la ubicación de las etiquetas.

	graph pie valor, over(actividad) plabel(_all percent) legend(size(small) order(1 "Agricultura, ganaderia, caza" 2 "Hotelería y restaurantes" 3 "Construcción" 4 "Electricidad gas y agua" 5 "Explotacion minas y canteras" 6 "Financiero, inmobiliario" 7 "Manufacturas" 8 "Servicios comunales, sociales y personales                       " 9 "Transporte, almacenamiento y comunicaciones")) note("Porcentaje sobre el total de desembolsos de crédito externo por actividad económica para el periodo" "2000-2009.") graphregion(color(white)) plotregion(color(white) style(none))

	graph export "$output\monto desembolso por actividad 2000_2009.png", replace

restore

**# 1.10) PROPORCIÓN NÚMERO DE FIRMAS POR ACTIVIDAD ECONÓMICA 2010-2019

preserve

	keep if Fecha_tri >= yq(2010,1)

	collapse (count) valor, by(actividadeconomica)

	encode actividadeconomica, gen(actividad)

	// NOTA: para el siguiente gráfico, se modifica manualmente (en el editor de gráficos de Stata) la ubicación de las etiquetas.

	graph pie valor, over(actividad) plabel(_all percent) legend(size(small) order(1 "Agricultura, ganaderia, caza" 2 "Hotelería y restaurantes" 3 "Construcción" 4 "Electricidad gas y agua" 5 "Explotacion minas y canteras" 6 "Financiero, inmobiliario" 7 "Manufacturas" 8 "Servicios comunales, sociales y personales                       " 9 "Transporte, almacenamiento y comunicaciones")) note("Porcentaje del número de firmas por actividad económica a las que se les desembolsa crédito externo para" "el periodo 2010-2019.") graphregion(color(white)) plotregion(color(white) style(none))

	graph export "$output\numero de firmas por actividad 2010_2019.png", replace

restore

**# 1.11) PROPORCIÓN MONTO DESEMBOLSADO POR ACTIVIDAD ECONÓMICA 2010-2019

preserve

	keep if Fecha_tri >= yq(2010,1)

	collapse (sum) valor, by(actividadeconomica)

	encode actividadeconomica, gen(actividad)

	// NOTA: para el siguiente gráfico, se modifica manualmente (en el editor de gráficos de Stata) la ubicación de las etiquetas.

	graph pie valor, over(actividad) plabel(_all percent) legend(size(small) order(1 "Agricultura, ganaderia, caza" 2 "Hotelería y restaurantes" 3 "Construcción" 4 "Electricidad gas y agua" 5 "Explotacion minas y canteras" 6 "Financiero, inmobiliario" 7 "Manufacturas" 8 "Servicios comunales, sociales y personales                       " 9 "Transporte, almacenamiento y comunicaciones")) note("Porcentaje sobre el total de desembolsos de crédito externo por actividad económica para el periodo" "2010-2019.") graphregion(color(white)) plotregion(color(white) style(none))

	graph export "$output\monto desembolso por actividad 2010_2019.png", replace

restore

**# 1.12) DISTRIBUCIÓN DE ACTIVOS DE LAS FIRMAS

// llamamos la base de datos de supersociedades

import delimited \\sgee128985\E\Proyectos\Delinquency_Kursat\Jose_WorkColombia\Input\data_csv_excel\SuperSociedades\BASE_SS_99-21.csv, clear

// nos quedamos solamente con las variables que no interesan (periodo, nit de las firmas, nombre las firmas, activo total)

keep periodo bg_1 bg_2 bg_130 // NOTA: la variable periodo es el año. Es decir, las observaciones son anuales

rename bg_1 identif

rename bg_2 nom_firma

rename bg_130 total_activo // NOTA: estos activos están medidos en miles de pesos

// modificamos la variable de nit de las firmas (identif) para que corresponda con el formato que hemos trabajado en las demás bases de datos

gen nu_identif = substr(identif, 1, 20)

drop identif

rename nu_identif identif

// modificamos el año para que esté en formato de número

destring periodo, replace force

drop if periodo == .

rename periodo year

// mergeamos con la base de TRM trimestral

gen Fecha_tri = yq(year, 4)

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

keep if _merge == 3

drop _merge

// generamos la variable de activos medida en miles de dólares

gen total_activo_USD = total_activo/TRM

// transformamos las variables de activo para que este medidas en millones de dólares

replace total_activo_USD=total_activo_USD/1000 // se divide por 1000 porque las variables ya estan en miles

keep identif nom_firma total_activo_USD year

// generamos el panel

egen firma = group(identif)

xtset firma year

// generamos el lag de los activos 

bys firma (year): gen lag_total_activo_USD = L1.total_activo_USD

drop firma

// cambiamos el formato de la variale year

recast float year

// guardamos esta base de datos 

save "$input\activos_firmas.dta", replace // base de datos que contiene los activos de las firmas en cada año

// llamamos la base de datos que contiene los nits de las firmas que toman desembolsos de crédito externo en cada año

use "$input\nits_cred_externo_por_trimestre.dta", clear

// mergeamos con la base de activos que acabamos de generar

merge m:1 identif year using "$input\activos_firmas.dta"

keep if _merge == 3

**# 1.12.1) DISTRIBUCIÓN DE ACTIVOS POR TRIMESTRE

// por temas de estética, agregamos una observacion adicional al dataset, que corresponda al trimestre 2020q1 (va a ser una observacino vacia)

insobs 1

replace Fecha_tri = yq(2020, 1) if Fecha_tri == .

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// Modificar el color de la barra 46 (correspondiente al trimestre 2011-2) para que sea rojo.
	
graph box lag_total_activo_USD, over(Fecha_tri, relabel(1 "2000q1" 2 " " 3 " " 4 " " 5 " " 6 " " 7 " " 8 " " 9 " " 10 " " 11 " " 12 " " 13 " " 14 " " 15 " " 16 " " 17 " " 18 " " 19 " " 20 " " 21 "2005q1" 22 " " 23 " " 24 " " 25 " " 26 " " 27 " " 28 " " 29 " " 30 " " 31 " " 32 " " 33 " " 34 " " 35 " " 36 " " 37 " " 38 " " 39 " " 40 " " 41 "2010q1" 42 " " 43 " " 44 " " 45 " " 46 " " 47 " " 48 " " 49 " " 50 " " 51 " " 52 " " 53 " " 54 " " 55 " " 56 " " 57 " " 58 " " 59 " " 60 " " 61 "2015q1" 62 " " 63 " " 64 " " 65 " " 66 " " 67 " " 68 " " 69 " " 70 " " 71 " " 72 " " 73 " " 74 " " 75 " " 76 " " 77 " " 78 " " 79 " " 80 " " 81 "2020q1") ) nooutsides note("Se muestra la distribución de activos totales de las firmas con desembolsos de crédito externo en" "cada trimestre." "En rojo se muestra el trimestre 2011q2." "Se excluyen valores atípicos.") ytitle("Millones de dólares") 

graph export "$output\distribucion activos firmas cred externo por trimestre.png", replace

**# 1.12.2) DISTRIBUCIÓN DE ACTIVOS POR AÑO

// por temas de estética, agregamos una observacion adicional al dataset, que corresponda al trimestre 2020q1 (va a ser una observacino vacia)

collapse (lastnm) total_activo lag_total_activo_USD, by(year identif)

// eliminamos los años vacios

drop if year == 2020

drop if year == 2000

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// Modificar el color de la barra 11 (correspondiente al año 2011) para que sea rojo.

graph box lag_total_activo_USD, over(year, label(angle(90))) nooutsides note("Se muestra la distribución de activos totales de las firmas con desembolsos de crédito externo en" "cada año." "En rojo se muestra el año 2011." "Se excluyen valores atípicos.") ytitle("Millones de dólares")

graph export "$output\distribucion activos firmas cred externo por año.png", replace



**# 2) DESEMBOLSOS POR PAIS 

// A partir de la base original de Endeudamiento Externo, vamos a cuál fue el monto total desembolsado por cada pais (excluyendo Colombia) a firmas colombianas en cada trimestre

// partimos de la base original de EE

use "$input\Base_Flujos_EE.dta" , clear

// eliminamos observaciones con formato erroneo

destring anio, replace force 
drop if anio == .

// generamos variable de Fecha trimestral para cada crédito 

gen Fecha_men = date(fecha_m, "YMD")
replace Fecha_men = mofd(Fecha_men)
format %tm Fecha_men

gen Fecha_tri = date(fecha_m, "YMD")
replace Fecha_tri = qofd(Fecha_tri)
format %tq Fecha_tri

// eliminamos observaciones posteriores a nuestro periodo de interés

drop if Fecha_tri > yq(2019, 4)

// modificamos el formato de la variable valor (monto del flujo)

replace valor = float(valor)

// renombramos la variable nit

rename nit identif
*destring identif, replace force
generate str identif_string = identif
replace identif = ""
compress identif
replace identif = identif_string
drop identif_string
describe identif

// dejamos solo las observaciones que son desembolsos (recordemos que hay tanto desembolsos como amortizaciones)

keep if concepto == "Desembolsos" 

// modificamos el formato de la variable identif (nit de las empresas)

gen nit_len=strlen(identif)
tab nit_len
rename identif nit_original
gen identif=nit_original
replace identif=substr(identif,1,9) if nit_len==10

// eliminamos las observaciones de bancos colombianos

drop if pais == "COLOMBIA" | pais == "CO0"

drop if tipoacreedor == 1 | tipoacreedor == 2 | tipoacreedor == 6 | tipoacreedor == 7 | tipoacreedor == 12 // eliminamos las observaciones para las cuales el acreedor es IMC, filial o sucursal de banco colombiano, IMC redescontado Bancoldex, IMC redescontado Banco de la República, o IMC redescontado IFI

// como hay tantas observaciones con codigo de pais en vez de nombre, debemos cambiar esos codigos por el nombre respectivo, uno por uno

replace pais = "ANDORRA" if pais == "AD0"
replace pais = "EMIRATOS ARABES UNIDOS" if pais == "AE0"
replace pais = "AFGANISTAN" if pais == "AF0"
replace pais = "ANTIGUA Y BARBUDA" if pais == "AG0"
replace pais = "ALBANIA" if pais == "AL0"
replace pais = "ARMENIA" if pais == "AM0"
replace pais = "ANGOLA" if pais == "AO0"
replace pais = "ARGENTINA" if pais == "AR0"
replace pais = "AUSTRIA" if pais == "AT0"
replace pais = "AUSTRALIA" if pais == "AU0"
replace pais = "BARBADOS" if pais == "BB0"
replace pais = "BANGLADESH" if pais == "BD0"
replace pais = "BELGICA" if pais == "BE0"
replace pais = "BULGARIA" if pais == "BG0"
replace pais = "BAHRAIN" if pais == "BH0"
replace pais = "BOLIVIA" if pais == "BO0"
replace pais = "BRASIL" if pais == "BR0"
replace pais = "BAHAMAS" if pais == "BS0"
replace pais = "BOTSUANA" if pais == "BW0"
replace pais = "BELICE" if pais == "BZ0"
replace pais = "CANADA" if pais == "CA0"
replace pais = "ISLA DE COCOS" if pais == "CC0"
replace pais = "CONGO" if pais == "CG0"
replace pais = "SUIZA" if pais == "CH0"
replace pais = "COSTA DE MARFIL" if pais == "CI0"
replace pais = "ISLAS COOK" if pais == "CK0"
replace pais = "CHILE" if pais == "CL0"
replace pais = "CAMERUN" if pais == "CM0"
replace pais = "CHINA" if pais == "CN0"
replace pais = "CHINA" if pais == "CN1"
replace pais = "CHINA" if pais == "CN2"
replace pais = "COSTA RICA" if pais == "CR0"
replace pais = "SERBIA Y MONTENEGRO" if pais == "CS0"
replace pais = "CUBA" if pais == "CU0"
replace pais = "CHIPRE" if pais == "CY0"
replace pais = "REPUBLICA CHECA" if pais == "CZ0"
replace pais = "ALEMANIA" if pais == "DE0"
replace pais = "DINAMARCA" if pais == "DK0"
replace pais = "DOMINICA" if pais == "DM0"
replace pais = "REPUBLICA DOMINICANA" if pais == "DO0"
replace pais = "ARGELIA" if pais == "DZ0"
replace pais = "ECUADOR" if pais == "EC0"
replace pais = "ESTONIA" if pais == "EE0"
replace pais = "EGIPTO" if pais == "EG0"
replace pais = "ESPAÑA" if pais == "ES0"
replace pais = "FINLANDIA" if pais == "FI0"
replace pais = "ISLAS FEROE" if pais == "FO0"
replace pais = "FRANCIA" if pais == "FR0"
replace pais = "GRAN BRETAÑA" if pais == "GB0"
replace pais = "GRAN BRETAÑA" if pais == "GB1"
replace pais = "GRAN BRETAÑA" if pais == "GB2"
replace pais = "GRAN BRETAÑA" if pais == "GB3"
replace pais = "GRAN BRETAÑA" if pais == "GB4"
replace pais = "GRAN BRETAÑA" if pais == "GB5"
replace pais = "GRAN BRETAÑA" if pais == "GB8"
replace pais = "GRANADA" if pais == "GD0"
replace pais = "GEORGIA" if pais == "GE0"
replace pais = "GHANA" if pais == "GH0"
replace pais = "PAPUA NUEVA GUINEA" if pais == "GP0"
replace pais = "GRECIA" if pais == "GR0"
replace pais = "GUATEMALA" if pais == "GT0"
replace pais = "GUYANA" if pais == "GY0"
replace pais = "HONG KONG" if pais == "HK"
replace pais = "HONG KONG" if pais == "HK0"
replace pais = "HONDURAS" if pais == "HN0"
replace pais = "CROACIA" if pais == "HR0"
replace pais = "HAITI" if pais == "HT0"
replace pais = "HUNGRIA" if pais == "HU0"
replace pais = "INDONESIA" if pais == "ID0"
replace pais = "IRLANDA" if pais == "IE0"
replace pais = "ISRAEL" if pais == "IL0"
replace pais = "INDIA" if pais == "IN0"
replace pais = "IRAQ" if pais == "IQ0"
replace pais = "IRAN" if pais == "IR0"
replace pais = "ISLANDIA" if pais == "IS0"
replace pais = "ITALIA" if pais == "IT0"
replace pais = "JAMAICA" if pais == "JM0"
replace pais = "JORDANIA" if pais == "JO0"
replace pais = "JAPON" if pais == "JP0"
replace pais = "KENIA" if pais == "KE0"
replace pais = "COREA DEL NORTE" if pais == "KP0"
replace pais = "COREA DEL SUR" if pais == "KR0"
replace pais = "KUWAIT" if pais == "KW0"
replace pais = "ISLAS CAYMAN" if pais == "KY0"
replace pais = "KAZAJSTAN" if pais == "KZ0"
replace pais = "LIBANO" if pais == "LB0"
replace pais = "SANTA LUCIA" if pais == "LC0"
replace pais = "LIECHTENSTEIN" if pais == "LI0"
replace pais = "SRI LANKA" if pais == "LK0"
replace pais = "LITUANIA" if pais == "LT0"
replace pais = "LUXEMBURGO" if pais == "LU0"
replace pais = "LETONIA" if pais == "LV0"
replace pais = "MARRUECOS" if pais == "MA0"
replace pais = "MONACO" if pais == "MC0"
replace pais = "MADAGASCAR" if pais == "MG0"
replace pais = "ISLAS MARSHALL" if pais == "MH0"
replace pais = "MACAO" if pais == "MO0"
replace pais = "MALTA" if pais == "MT0"
replace pais = "MAURICIO" if pais == "MU0"
replace pais = "MEXICO" if pais == "MX0"
replace pais = "MALASIA" if pais == "MY0"
replace pais = "MOZAMBIQUE" if pais == "MZ0"
replace pais = "NUEVA CALEDONIA" if pais == "NC0"
replace pais = "NICARAGUA" if pais == "NI0"
replace pais = "HOLANDA" if pais == "NL0"
replace pais = "HOLANDA" if pais == "NL1"
replace pais = "HOLANDA" if pais == "NL2"
replace pais = "HOLANDA" if pais == "NL3"
replace pais = "HOLANDA" if pais == "NL4"
replace pais = "NORUEGA" if pais == "NO0"
replace pais = "NAURU" if pais == "NR0"
replace pais = "NUEVA ZELANDA" if pais == "NZ0"
replace pais = "OMAN" if pais == "OM0"
replace pais = "PANAMA" if pais == "PA0"
replace pais = "PERU" if pais == "PE0"
replace pais = "FILIPINAS" if pais == "PH0"
replace pais = "PAKISTAN" if pais == "PK0"
replace pais = "POLONIA" if pais == "PL0"
replace pais = "PUERTO RICO" if pais == "PR0"
replace pais = "PORTUGAL" if pais == "PT0"
replace pais = "PARAGUAY" if pais == "PY0"
replace pais = "RUMANIA" if pais == "RO0"
replace pais = "RUSIA" if pais == "RU0"
replace pais = "ARABIA SAUDITA" if pais == "SA0"
replace pais = "SEYCHELLES" if pais == "SC0"
replace pais = "SUECIA" if pais == "SE0"
replace pais = "SINGAPUR" if pais == "SG0"
replace pais = "SANTA ELENA" if pais == "SH0"
replace pais = "ESLOVENIA" if pais == "SI0"
replace pais = "ESLOVAQUIA" if pais == "SK0"
replace pais = "SOMALIA" if pais == "SO0"
replace pais = "SURINAM" if pais == "SR0"
replace pais = "EL SALVADOR" if pais == "SV0"
replace pais = "SIRIA" if pais == "SY0"
replace pais = "ISLAS TURCAS Y CAICOS" if pais == "TC0"
replace pais = "TOGO" if pais == "TG0"
replace pais = "TAILANDIA" if pais == "TH0"
replace pais = "TURQUIA" if pais == "TR0"
replace pais = "TRINIDAD Y TOBAGO" if pais == "TT0"
replace pais = "TAIWAN" if pais == "TW0"
replace pais = "TANZANIA" if pais == "TZ0"
replace pais = "UCRANIA" if pais == "UA0"
replace pais = "ISALAS MENORES ALEJADAS DE LOS EEUU" if pais == "UM0"
replace pais = "ESTADOS UNIDOS" if pais == "US0"
replace pais = "ESTADOS UNIDOS" if pais == "US1"
replace pais = "URUGUAY" if pais == "UY0"
replace pais = "SAN VICENTE Y LAS GRANADINAS" if pais == "VC0"
replace pais = "VENEZUELA" if pais == "VE0"
replace pais = "ISLAS VIRGENES DE LOS ESTADOS UNIDOS" if pais == "VI0"
replace pais = "VIETNAM" if pais == "VN0"
replace pais = "SAMOA" if pais == "WS"
replace pais = "SUDAFRICA" if pais == "ZA0"
replace pais = "ZONA FRANCA" if pais == "ZF0"
drop if pais == "GF0"
drop if pais == "MQ0"
drop if pais == "RE0"
drop if pais == "YU0"

// ahora collapsamos todo a nivel pais-tiempo

preserve

	collapse (rawsum) valor, by(pais Fecha_tri)

	// veamos el total de desembolsos por pais para todo el periodo y seleccionemos a los paises con mayores montos

	bys pais (Fecha_tri): gen desembolsos_acum = sum(valor)

	bys pais (Fecha_tri): gen desem_final = desembolsos_acum[_N]

	// TOP:
		// 1) EEUU 
		// 2) PANAMA
		// 3) ESPAÑA
		// 4) INGLATERRA
		// 5) HOLANDA (PAISES BAJOS)
		// 6) SUIZA
		// 7) VENEZUELA 
		// 8) BAHAMAS
		// 9) ALEMANIA
		// 10) CHILE

	**# 2.1) TOTAL DESEMBOLSOS DE CRÉDITO EXTERNO POR PAIS: TOP 10

	twoway (line valor Fecha_tri if pais == "ESTADOS UNIDOS", lcolor(blue) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "PANAMA", lcolor(red) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ESPAÑA", lcolor(green) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "INGLATERRA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "HOLANDA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "SUIZA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "VENEZUELA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "BAHAMAS", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ALEMANIA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "CHILE", lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "EEUU" 2 "PANAMÁ" 3 "ESPAÑA" 4 "INGLATERRA" 5 "PAISES BAJOS" 6 "SUIZA" 7 "VENEZUELA" 8 "BAHAMAS" 9 "ALEMANIA" 10 "CHILE") cols(3) size(small)) note("Se muestra el total de desembolsos de crédito externo por pais.")

	graph export "$output\total desembolsos por pais.png", replace

	**# 2.2) TOTAL DESEMBOLSOS DE CRÉDITO EXTERNO POR PAIS: TOP 10 SIN EEUU

	twoway (line valor Fecha_tri if pais == "PANAMA", lcolor(red) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ESPAÑA", lcolor(green) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "INGLATERRA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "HOLANDA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "SUIZA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "VENEZUELA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "BAHAMAS", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ALEMANIA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "CHILE", lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "PANAMÁ" 2 "ESPAÑA" 3 "INGLATERRA" 4 "PAISES BAJOS" 5 "SUIZA" 6 "VENEZUELA" 7 "BAHAMAS" 8 "ALEMANIA" 9 "CHILE") cols(3) size(small)) note("Se muestra el total de desembolsos de crédito externo por pais.")

	graph export "$output\total desembolsos sin EEUU.png", replace

restore

preserve

	collapse (mean) valor, by(pais Fecha_tri)

	**# 2.3) PROMEDIO DESEMBOLSOS DE CRÉDITO EXTERNO POR PAIS: TOP 10	

	twoway (line valor Fecha_tri if pais == "ESTADOS UNIDOS", lcolor(blue) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "PANAMA", lcolor(red) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ESPAÑA", lcolor(green) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "INGLATERRA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "HOLANDA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "SUIZA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "VENEZUELA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "BAHAMAS", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ALEMANIA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "CHILE", lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "EEUU" 2 "PANAMÁ" 3 "ESPAÑA" 4 "INGLATERRA" 5 "PAISES BAJOS" 6 "SUIZA" 7 "VENEZUELA" 8 "BAHAMAS" 9 "ALEMANIA" 10 "CHILE") cols(3) size(small)) note("Se muestra el promedio de desembolsos de crédito externo por pais.")

	graph export "$output\promedio desembolsos por pais.png", replace

	**# 2.4) PROMEDIO DESEMBOLSOS DE CRÉDITO EXTERNO POR PAIS: TOP 10 SIN EEUU	

	twoway (line valor Fecha_tri if pais == "PANAMA", lcolor(red) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ESPAÑA", lcolor(green) lpattern(solid)) ///
	(line valor Fecha_tri if pais == "INGLATERRA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "HOLANDA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "SUIZA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "VENEZUELA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "BAHAMAS", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "ALEMANIA", lpattern(solid)) ///
	(line valor Fecha_tri if pais == "CHILE", lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "PANAMÁ" 2 "ESPAÑA" 3 "INGLATERRA" 4 "PAISES BAJOS" 5 "SUIZA" 6 "VENEZUELA" 7 "BAHAMAS" 8 "ALEMANIA" 9 "CHILE") cols(3) size(small)) note("Se muestra el promedio de desembolsos de crédito externo por pais.")

	graph export "$output\promedio desembolsos sin EEUU.png", replace

restore



**# 3) RELACIONES BANCARIAS POR FIRMA: TOP 25%

// a continuación vamos a contar el número de relaciones bancarias domésticas de cada firma que hace parte del Top 25% que más desembolsos de crédito externo tuvo en cada trimestre.

// llamamos la base de datos del merge de la 341 con EE (en saldos)

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// contamos el número de relaciones bancarias domésticas para cada firma en cada trimestre

sort Fecha_tri identif

egen relaciones_bancarias = count(codentid), by(Fecha_tri identif)

// collapsamos todo a nivel firma-tiempo 

collapse (mean) relaciones_bancarias, by(Fecha_tri identif)

// mergeamos con la base de datos de firmas que más sacaron credito externo

merge 1:1 Fecha_tri identif using "$input\top_firmas_cred_externo.dta"

// establecemos el panel 

egen firma = group(identif)

xtset firma Fecha_tri

// generamos el lag de las relaciones bancarias

foreach var in relaciones_bancarias {

	bys firma (Fecha_tri): gen lag_`var' = L1.`var'

}

// nos quedamos solo con las que mergean (Top 25% que sacan cred externo en cada trimestre)

keep if _merge == 3

// eliminamos la variable _merge

drop _merge

// reemplazamos los missing por cero

foreach var in relaciones_bancarias {

	bys firma (Fecha_tri): replace lag_`var' = 0 if lag_`var' == .

} 

// vamos a clasificar las firmas en grupos según su número de relaciones:

gen group_rel = "0"

replace group_rel = "1" if relaciones_bancarias == 1

replace group_rel = "2" if relaciones_bancarias == 2

replace group_rel = "3" if relaciones_bancarias == 3

replace group_rel = "4" if relaciones_bancarias == 4

replace group_rel = ">4" if relaciones_bancarias > 4


gen lag_group_rel = "0"

replace lag_group_rel = "1" if lag_relaciones_bancarias == 1

replace lag_group_rel = "2" if lag_relaciones_bancarias == 2

replace lag_group_rel = "3" if lag_relaciones_bancarias == 3

replace lag_group_rel = "4" if lag_relaciones_bancarias == 4

replace lag_group_rel = ">4" if lag_relaciones_bancarias > 4

// generamos una sub base que tenga el número total de firmas por grupo en el periodo t

preserve

	collapse (sum) top_externo, by(Fecha_tri group_rel) 

	save "$input\firmas_por_num_de_relaciones.dta"

restore

// hacemos lo mismo para t-1

preserve

	collapse (sum) top_externo, by(Fecha_tri lag_group_rel) 

	rename top_externo firmas_t_1

	rename lag_group_rel group_rel

	save "$input\firmas_por_num_de_relaciones_t_1.dta", replace

restore

// y mergeamos ambas bases de datos

use "$input\firmas_por_num_de_relaciones.dta", clear

rename top_externo firmas_t

merge 1:1 Fecha_tri group_rel using "$input\firmas_por_num_de_relaciones_t_1.dta"

drop _merge

// De esta forma, ya contamos para cada trimestre con el número total de firmas por número de relaciones en t y en t-1. Exportamos esta información a Excel

export excel using "$output\num firmas por num de relaciones.xlsx", sheetmodify firstrow(variables)



**# 4) COMPORTAMIENTO DEL TOP 25% EN EL MERCADO DE CRÉDITO DOMÉSTICO 

// veamos un poco el comportamiento en el mercado doméstico del Top 25% de firmas que más desembolsos de crédito externo tuvo en cada trimestre

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-tiempo

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// mergeamos con la base de datos de top firmas que sacaron credito externo

merge 1:1 Fecha_tri identif using "$input\top_firmas_cred_externo.dta"

// establecemos el panel 

egen firma = group(identif)

xtset firma Fecha_tri

// nos quedamos solo con las que mergean (Top 25% que más sacan cred externo en cada trimestre)

keep if _merge == 3

// eliminamos la variable _merge

drop _merge

**# 4.1) TOTAL DE NUEVO CRÉDITO DOMÉSTICO POR TRIMESTRE: TOP 25%

// graficamos el total de nuevo crédito doméstico sacado por le Top 25% de firmas que más desembolsos de crédito externo tomó en cada trimestre

preserve

collapse (sum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri)

twoway (line capital_USD Fecha_tri, lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri, lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri, lcolor(green) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Crédito doméstico total" 2 "Crédito doméstico en" "dólares" 3 "Crédito doméstico en pesos")) note("Se muestra el total de crédito doméstico sacado por el 25% de firmas que más sacaron crédito" "externo en cada trimestre.")

graph export "$output\total cred local top firmas cred externo.png", replace

restore

**# 4.2) PROMEDIO DE NUEVO CRÉDITO DOMÉSTICO POR TRIMESTRE: TOP 25%

// graficamos el promedio de nuevo crédito doméstico sacado por le Top 25% de firmas que más desembolsos de crédito externo tomó en cada trimestre

preserve

collapse (mean) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri)

twoway (line capital_USD Fecha_tri, lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri, lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri, lcolor(green) lpattern(solid)), ytitle("Millones de dólares") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Crédito doméstico total" 2 "Crédito doméstico en" "dólares" 3 "Crédito doméstico en pesos")) note("Se muestra el promedio de crédito doméstico sacado por el 25% de firmas que más sacaron" "crédito externo en cada trimestre.")

graph export "$output\promedio cred local top firmas cred externo.png", replace

restore



**# 5) HISTOGRAMAS RELACIÓN CRÉDITO EXTERNO Y CRÉDITO DOMÉSTICO 

// vamos a generar distintos histogramas que muestren la relación entre los desembolsos de crédito externo y el crédito doméstico (saldos y nuevos créditos) del Top 25% de firmas que más desembolsos de crédito externo tomó 

**# 5.1) RELACIÓN CON NUEVOS CRÉDITOS 

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-tiempo

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// mergeamos con la base de nits del top 25% por trimestre

merge 1:1 identif Fecha_tri using "$input\top_firmas_cred_externo.dta"

// conservamos solo las firmas del top 25% en cada trimestre 

keep if top_externo == 1

// generamos el ratio desembolso crédito externo / nuevo crédito doméstico en dólares

gen ratio_dol = desem_externo/capitalme_USD // 4227 non missings

// generamos el ratio desembolso crédito externo / nuevo crédito doméstico en pesos

gen ratio_pes = desem_externo/capitalml_USD // 9484 non missings

// winsoreamos

winsor2 ratio_dol ratio_pes, c(1 99) suffix(_w)

// generamos los ratios en logaritmo

gen log_ratio_dol_w = log(ratio_dol_w)

gen log_ratio_pes_w = log(ratio_pes_w)

**# 5.1.1) HISTOGRAMA RATIO SOBRE NUEVO CRÉDITO DOMÉSTICO EN DÓLARES

histogram ratio_dol_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Desembolsos externo/Nuevo crédito doméstico en dólares") note("Se toman los datos de la relación entre los desembolsos de crédito externo y el nuevo crédito" "doméstico en dólares para el Top 25% de firmas con mayores montos de crédito externo para" "cada trimestre." " "  "Se utilizan 4227 observaciones.") bin(20)

graph export "$output\histograma desem_flujo_local_dol.png", replace

**# 5.1.2) HISTOGRAMA RATIO SOBRE NUEVO CRÉDITO DOMÉSTICO EN DÓLARES (LOGS)

histogram log_ratio_dol_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("log(Desembolsos externo/Nuevo crédito doméstico en dólares)") note("Se toman los datos del logaritmo de la relación entre los desembolsos de crédito externo y el" "nuevo crédito doméstico en dólares para el Top 25% de firmas con mayores montos de crédi-" "to externo para cada trimestre." " " "Se utilizan 4227 observaciones.") bin(20)

graph export "$output\histograma log desem_flujo_local_dol.png", replace

**# 5.1.3) HISTOGRAMA RATIO SOBRE NUEVO CRÉDITO DOMÉSTICO EN PESOS

histogram ratio_pes_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Desembolsos externo/Nuevo crédito doméstico en pesos") note("Se toman los datos de la relación entre los desembolsos de crédito externo y el nuevo crédito" "doméstico en pesos para el Top 25% de firmas con mayores montos de crédito externo para" "cada trimestre." "Se utilizan 9484 observaciones.") bin(20)

graph export "$output\histograma desems_flujo_local_pes.png", replace

**# 5.1.4) HISTOGRAMA RATIO SOBRE NUEVO CRÉDITO DOMÉSTICO EN PESOS (LOGS)

histogram log_ratio_pes_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("log(Desembolsos externo/Nuevo crédito doméstico en pesos)") note("Se toman los datos del logaritmo de la relación entre los desembolsos de crédito externo y el" "nuevo crédito doméstico en pesos para el Top 25% de firmas con mayores montos de crédi-" "to externo para cada trimestre." " " "Se utilizan 9484 observaciones.") bin(20)

graph export "$output\histograma log desem_flujo_local_pes.png", replace


**# 5.2) RELACIÓN CON SALDOS

// llamamos la base de datos del merge de la 341 con EE (en saldos)

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// mergeamos con la base de nits del top 25% por trimestre

merge m:1 identif Fecha_tri using "$input\top_firmas_cred_externo.dta"

// conservamos solo las firmas del top 25% en cada trimestre 

keep if top_externo == 1

// collapsamos a nivel firma-tiempo para las variables que nos interesan 

collapse (rawsum) capital_USD capitalme_USD capitalml_USD (lastnm) desem_externo, by(Fecha_tri identif)

// generamos el ratio desembolso crédito externo / nuevo crédito doméstico en dólares

gen ratio_dol = desem_externo/capitalme_USD // 7745 non missings

// generamos el ratio desembolso crédito externo / nuevo crédito doméstico en pesos

gen ratio_pes = desem_externo/capitalml_USD // 15805 non missings

// winsoreamos

winsor2 ratio_dol ratio_pes, c(1 99) suffix(_w)

// generamos los ratios en logaritmo

gen log_ratio_dol_w = log(ratio_dol_w)

gen log_ratio_pes_w = log(ratio_pes_w)

**# 5.2.1) HISTOGRAMA RATIO SOBRE SALDO CRÉDITO DOMÉSTICO EN DÓLARES

histogram ratio_dol_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Desembolsos externo/Saldos crédito doméstico en dólares") note("Se toman los datos de la relación entre los desembolsos de crédito externo y los saldos de" "crédito doméstico en dólares para el Top 25% de firmas con mayores montos de crédito externo" "para cada trimestre." " "  "Se utilizan 7745 observaciones.") bin(20)

graph export "$output\histograma desem_saldos_local_dol.png", replace

**# 5.2.2) HISTOGRAMA RATIO SOBRE SALDO CRÉDITO DOMÉSTICO EN DÓLARES (LOGS)

histogram log_ratio_dol_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("log(Desembolsos externo/Saldos crédito doméstico en dólares)") note("Se toman los datos del logaritmo de la relación entre los desembolsos de crédito externo y los" "saldos de crédito doméstico en dólares para el Top 25% de firmas con mayores montos de cré-" "dito externo para cada trimestre." " " "Se utilizan 7745 observaciones.") bin(20)

graph export "$output\histograma log desem_saldos_local_dol.png", replace

**# 5.2.3) HISTOGRAMA RATIO SOBRE SALDO CRÉDITO DOMÉSTICO EN PESOS

histogram ratio_pes_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Desembolsos externo/Saldos crédito doméstico en pesos") note("Se toman los datos de la relación entre los desembolsos de crédito externo y los saldos de" "crédito doméstico en pesos para el Top 25% de firmas con mayores montos de crédito externo" "para cada trimestre." "Se utilizan 15805 observaciones.") bin(20)

graph export "$output\histograma desems_saldos_local_pes.png", replace

**# 5.2.4) HISTOGRAMA RATIO SOBRE SALDO CRÉDITO DOMÉSTICO EN PESOS (LOGS)

histogram log_ratio_pes_w, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("log(Desembolsos externo/Saldos crédito doméstico en pesos)") note("Se toman los datos del logaritmo de la relación entre los desembolsos de crédito externo y los" "saldos de crédito doméstico en pesos para el Top 25% de firmas con mayores montos de cré-" "dito externo para cada trimestre." " " "Se utilizan 15805 observaciones.") bin(20)

graph export "$output\histograma log desem_saldos_local_pes.png", replace


**# 6) ESTUDIO DE EVENTOS BANCOS DOMÉSTICOS 2014-3

// Para el trimestre 2014-3 vamos a seleccionar tres bancos "expuestos" y tres "no expuestos" y analizaremos y compararemos la evolución de algunos de los rubros de sus hojas de balance.

// En este caso, la "exposición" de un banco está determinada por el número de relaciones que tuvo con firmas del Top 25% que más crédito externo sacó en 2014-3. Mientras mayor sea el número de relaciones, más expuesto el banco.

// llamamos la base de datos del merge de la 341 con EE (en saldos)

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear  

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos las variables de variación ya incluidas en la base

drop var_*

// para aquellas observaciones que no cuentan con un banco (codentid = .), reemplazaremos el código por 0

replace codentid = 0 if codentid == .

// para 2014-3:

// vamos a marcar el Top 25% de las firmas que sacaron cred externo en 2014-3

preserve

	use "$input\top_firmas_cred_externo.dta", clear

	keep if Fecha_tri == yq(2014, 3)

	keep identif top_externo

	rename top_externo firmas_2014_3

	duplicates drop

	tempfile nits

	save `nits'

restore

// conservamos solo las observaciones del 2014-2 (periodo anterior al evento)

keep if Fecha_tri == yq(2014, 2)

// mergeamos con la base de nits que nos interesan

merge m:1 identif using `nits'

// conservamos solo las observaciones que mergean

keep if _merge == 3

// generamos relacion firma-banco

gen relacion = 1

// collapsamos para saber con cuántas firmas del Top 25% se relacionó cada banco antes del trimestre del evento 

collapse (sum) relacion, by(codentid)

// eliminamos el banco 0

drop if codentid == 0

// ordenamos 

sort relacion

// guardemos esta base de datos 

save "$input\relaciones_de_bancos_con_top_firmas_externo.dta", replace // base de datos con el numero de relaciones que tuvo cada banco en 2014-2 con el top 25% de firmas que mas cred externo sacaron en 2014-3. 

// bancos más expuestos:

// 1) 7 - bancolombia - 94 firmas
// 2) 1 - bogotá - 83 firmas
// 3) 6 - Itaú - 78 firmas

// bancos menos expuestos:

// 1) 55 - finandina - 2 firmas
// 3) 58 - coopcentral - 3 firmas 
// 4) 10 - 2 firmas
// 5) 30 - caja social - 3 firmas


// sabiendo cuales son los bancos más y menos expuestos, vamos a ver que pasó con distintos rubros de hoja de balance de estos bancos antes y después del evento 

// importamos el panel de balance de los bancos 

import delimited "\\sgee128985\E\Proyectos\Datos\Balance general Bancos\Variables financieras\Panel_Entidad_Sistema_Financiero.csv", clear

// nos quedamos solamente con las entidades tipo 1

keep if tipo_entidad == 1

// generamos la variable de trimestre

gen date=date(fecha, "YMD")
format %td date
gen year_month=mofd(date)
format %tm year_month

gen Fecha_tri = qofd(dofm(year_month))

format Fecha_tri %tq

// generamos una sub base solo con los codigos y nombres de los bancos 

preserve 

	rename cod_entidad codentid 

	keep codentid nombre

	duplicates drop codentid, force
	
	// generamos una nueva variable que sea el nombre corto para cada banco 
	
	gen corto = nombre
	replace corto = "BOGOTÁ" if codentid == 1
	replace corto = "BBVA" if codentid == 13
	replace corto = "ANDINO" if codentid == 16
	replace corto = "CAJA SOCIAL" if codentid == 30
	replace corto = "POPULAR" if codentid == 2
	replace corto = "GRANAHORRAR" if codentid == 45
	replace corto = "DAVIVIENDA" if codentid == 39
	replace corto = "AV VILLAS" if codentid == 49
	replace corto = "COLMENA" if codentid == 46
	replace corto = "MERCANTIL" if codentid == 28
	replace corto = "TEQUENDAMA" if codentid == 29
	replace corto = "GNB SUDAMERIS" if codentid == 12
	replace corto = "UNIÓN COLOMBIANO" if codentid == 22
	replace corto = "GNB COLOMBIA" if codentid == 10
	replace corto = "BANK OF AMERICA" if codentid == 26
	replace corto = "CITIBANK" if codentid == 9
	replace corto = "SCOTIABANK" if codentid == 8
	replace corto = "COLPATRIA" if codentid == 19
	replace corto = "STANDARD CHATERED" if codentid == 24
	replace corto = "SANTANDER" if codentid == 17
	replace corto = "OCCIDENTE" if codentid == 23
	replace corto = "NACIONAL DEL COMERCIO" if codentid == 18
	replace corto = "CORPBANCA" if codentid == 6
	replace corto = "BANCOLOMBIA" if codentid == 7
	replace corto = "CONAVI" if codentid == 47
	replace corto = "DEL ESTADO" if codentid == 20
	replace corto = "UNIÓN COOPERATIVA" if codentid == 32
	replace corto = "DEL PACÍFICO" if codentid == 33
	replace corto = "BOSTON" if codentid == 36
	replace corto = "ABN AMRO" if codentid == 40
	replace corto = "COLPATRIA" if codentid == 42
	replace corto = "PROCREDIT" if codentid == 51
	replace corto = "WWB" if codentid == 53
	replace corto = "FINANDINA" if codentid == 55
	replace corto = "COOMEVA" if codentid == 54
	replace corto = "PICHINCHA" if codentid == 57
	replace corto = "FALABELLA" if codentid == 56
	replace corto = "COOPCENTRAL" if codentid == 58
	replace corto = "SANTANDER" if codentid == 59
	replace corto = "MULTIBANK" if codentid == 61
	replace corto = "MUNDO MUJER" if codentid == 60
	replace corto = "BOGOTÁ" if codentid == 1

	save "$input\codigos_nombres_bancos.dta", replace

restore

// conservamos la última observación de cada banco en cada trimestre (es decir, nos quedamos con el saldo del trimestre para cada banco)

bysort cod_entidad Fecha_tri (year_month): keep if _n == _N

// eliminamos la variable de mes

drop year_month

// renombramos la variable de codigo de los bancos

rename cod_entidad codentid

// conservamos solamente los periodos y bancos que nos interesan

keep if (Fecha_tri == yq(2014, 2) | Fecha_tri == yq(2014, 3)) & (codentid == 1 | codentid == 7 | codentid == 6 | codentid == 55 | codentid == 58 | codentid == 30)

// nos quedamos solamente con las variables que nos interesan 

keep codentid Fecha_tri bruta_total bruta_comercial bruta_consumo bruta_vivienda bruta_microcredito vencida_total vencida_comercial vencida_consumo vencida_vivienda vencida_microcredito riesgosa_total riesgosa_comercial riesgosa_consumo riesgosa_vivienda riesgosa_microcredito castigada_total castigada_comercial castigada_consumo castigada_vivienda castigada_microcredito inversiones_netas

// NOTA: las variables de hoja de balance se encuentran en miles de pesos

// mergeamos con la base de la TRM trimestral

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

// conservamos solo las observaciones que mergean

keep if _merge == 3

drop _merge

// generamos las variables en millones de dólares

foreach var in bruta_total bruta_comercial bruta_consumo bruta_vivienda bruta_microcredito vencida_total vencida_comercial vencida_consumo vencida_vivienda vencida_microcredito riesgosa_total riesgosa_comercial riesgosa_consumo riesgosa_vivienda riesgosa_microcredito castigada_total castigada_comercial castigada_consumo castigada_vivienda castigada_microcredito inversiones_netas {
    
	replace `var' = (`var'/TRM)/1000
	
}

sort codentid 

// guardamos esta base de datos

save "$input\rubros_balance_bancos_2014_2_&_2014_3.dta", replace 

// ahora traemos la cartera comercial de estos bancos para estos periodos, tanto en saldos como en nueva cartera

// primero saldos

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear  

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos las variables de variación ya incluidas en la base

drop var_*

// dejamos solamente los periodos y bancos que nos interesan 

keep if (Fecha_tri == yq(2014, 2) | Fecha_tri == yq(2014, 3)) & (codentid == 1 | codentid == 7 | codentid == 6 | codentid == 55 | codentid == 58 | codentid == 30) 

// collapsamos todo a nivel banco-tiempo

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri codentid)

// llamamos la base de nuevo credito y desembolsos 

preserve 

	use "$input\base341_nuevos_creditos_USD.dta", clear
	
	// nos quedamos con las observaciones que nos interesan

	keep if (Fecha_tri == yq(2014, 2) | Fecha_tri == yq(2014, 3)) & (codentid == 1 | codentid == 7 | codentid == 6 | codentid == 55 | codentid == 58 | codentid == 30) 

	// collapsamos todo a nivel banco-tiempo

	collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri codentid)
	
	// renombramos las variables para que no se confundan con las de saldos
	
	rename capital_USD nuevo_capital_USD
	
	rename capitalme_USD nuevo_capitalme_USD
	
	rename capitalml_USD nuevo_capitalml_USD

	// guardamos en un archivo temporal

	tempfile nuevos 

	save `nuevos'

restore

// mergeamos los saldos y los nuevos créditos 

merge 1:1 codentid Fecha_tri using `nuevos'

drop _merge

// mergeamos con la base de hoja de balance 

merge 1:1 codentid Fecha_tri using "$input\rubros_balance_bancos_2014_2_&_2014_3.dta"

drop _merge TRM

// exportamos esta base de datos a Excel 

export excel using "$output\analisis de eventos.xlsx", sheetmodify firstrow(variables)


**# 7) GRÁFICAS BANCOS DOMÉSTICOS 2014-3

// Ahora, para cada banco de 2014-3 vamos a graficar el cambio porcentual de la nueva cartera comercial total, nueva cartera comercial en dólares y nueva cartera comercial en pesos, con respecto al trimestre 2014-2. Igualemente, distintguiremos cada banco por su nivel de exposición, que como explicamos más arriba, esta determinado por el número de relaciones que tuvo el banco con firmas del Top 25% que más desembolsos de crédito externo tomó en 2014-3.

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-banco-tiempo

use "$input\base341_nuevos_creditos_USD.dta", clear

// eliminamos a MinHacienda

drop if identif == "899999090"

// nos quedamos con los trimestres que nos interesan

keep if Fecha_tri == yq(2014, 2) | Fecha_tri == yq(2014, 3)

// collapsamos todo a nivel banco-tiempo

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri codentid)

// mergeamos con la base que contiene los códigos y nombres de los bancos

merge m:1 codentid using "$input\codigos_nombres_bancos.dta"

// conservamos solo las observaciones que mergean 

keep if _merge == 3

drop _merge

// mergeamos con la base que tiene el numero de relaciones con las firmas top 25%

merge m:1 codentid using "$input\relaciones_de_bancos_con_top_firmas_externo.dta"

// eliminamos el banco 51, ya que no aparece para 2014-3

drop if codentid == 51

replace relacion = 0 if relacion == .

drop _merge

sort relacion

// generemos una variable continua de exposición. Esta será igual a 1 para el banco con mayor numero de relaciones y a partir de alli se asignaran valores entre 0 y 1 a los demas según su número de relaciones

gen exposicion = .

replace exposicion = relacion / 94 // el número máximo de relaciones es 94

// generaremos una paleta de colores según la exposición
// la paleta ira de rojo para el mas expuesto a azul para el menos; el componente de rojo es R=255 G=0 B=0, mientras que el de azul es R=0 G=0 B=255. Generaremos intermedios entre esos dos según la exposicion

gen R = round(0 + (255) * exposicion)
gen G = round(0)
gen B = round(255 - (255) * exposicion)

// establecemos el panel 

egen banco = group(codentid)

xtset banco Fecha_tri

// generamos el cambio porcentual de la nueva cartera

foreach var in capital_USD capitalme_USD capitalml_USD {

	bys banco (Fecha_tri): gen cambio_porc_`var' = ((`var' - L1.`var') / L1.`var') * 100

}

// ya con el cambio porcentual, conservamos solo el periodo 2014-3

keep if Fecha_tri == yq(2014, 3)

**# 7.1) CAMBIO PORCENTUAL NUEVA CARTERA TOTAL

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar cambio_porc_capital_USD, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos que tuvieron relación con un mayor número de firmas" "que hacen parte del Top 25% que más crédito externo sacó en 2014-3.") ylabel(, angle(0)) 

graph export "$output\cambio porcentual cred total bancos.png", replace

**# 7.2) CAMBIO PORCENTUAL NUEVA CARTERA PESOS

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar cambio_porc_capitalml_USD, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos que tuvieron relación con un mayor número de firmas" "que hacen parte del Top 25% que más crédito externo sacó en 2014-3.") ylabel(, angle(0)) 

graph export "$output\cambio porcentual cred pesos bancos.png", replace

**# 7.3) CAMBIO PORCENTUAL NUEVA CARTERA DÓLARES

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar cambio_porc_capitalme_USD, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos que tuvieron relación con un mayor número de firmas" "que hacen parte del Top 25% que más crédito externo sacó en 2014-3." "Bancamia, WWB, Finandina, Pichincha, Coopcentral, Coomeva y Citibank no contaron con nue" "va cartera en moneda extranjera en 2014-2 ni en 2014-3" "Banco Santander pasó de emitir 0 USD de nuevo crédito en moneda extranjera en 2014-2 a" "emitir 20.0756 MILL USD en 2014-3, razón por la cual su cambio porcentual es indeterminado.") ylabel(, angle(0)) 

graph export "$output\cambio porcentual cred dolares bancos.png", replace


**# 8) NUEVO CRÉDITO DOMÉSTICO COMO PORCENTAJE DE PASIVOS

// Lo siguiente es generar algunas gráficas tomando solamente el Top 25% de firmas que más desembolsos de crédito externo tuvieron en 2014-3. Para cada firma se generarán sus nuevos créditos acumulados domésticos y desembolsos de crédito externo a lo largo de 2014 como porcentaje de sus pasivos de 2013. Luego se graficará el promedio de esos porcentajes.

// llamamos la base de datos de supersociedades

import delimited \\sgee128985\E\Proyectos\Delinquency_Kursat\Jose_WorkColombia\Input\data_csv_excel\SuperSociedades\BASE_SS_99-21.csv, clear

// conservamos las variables que nos interesan (año, nit y nombre de la firma y pasivos totales)

keep periodo bg_1 bg_2 bg_237

// nos quedamos solo con 2013

keep if periodo == "2013" 

// renombramos las variables

rename bg_1 identif

rename bg_2 nom_firma

rename bg_237 total_pasivo

rename total_pasivo total_pasivo_2013

drop periodo

// generamos la variable de trimestre

gen Fecha_tri = yq(2013, 4)

format %tq Fecha_tri

// mergeamos con la base de TRM trimestral

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

keep if _merge == 3

drop _merge

// generamos pasivo medida en miles de dólares (se encuentran en miles de pesos)

gen total_pasivo_USD_2013 = total_pasivo_2013/TRM

// transformamos la variable para que esté medida en millones de dólares

replace total_pasivo_USD_2013=total_pasivo_USD_2013/1000 // se divide por 1000 porque las variables ya estan en miles

keep identif nom_firma total_pasivo_USD_2013

// generamos la variable "identif" para que coincida con las de las bases que hemos venido trabajando

gen nu_identif = substr(identif, 1, 20)

drop identif

rename nu_identif identif

// guardamos esta base de datos 

save "$input\total_pasivos_firmas_2013.dta", replace // base de datos que contiene los pasivos de las firmas en 2013 (en millones de dólares)

// Ahora vamos a generar los datos necesario para realizar las graficas con desembolsos y nuevos créditos

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-tiempo

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos aquellas que no tienen crédito externo

drop if valor == 0

// conservamos solamente los periodos que nos interesan que son de 2013-4 a 2016-4

keep if Fecha_tri >= yq(2013,4) & Fecha_tri <= yq(2016,4) 

// renombramos la variable de desembolsos de crédito externo

rename valor desem_cred_externo

// generamos una sub base solo con los nits de las firmas que sacaron crédito exteno en 2014-3

preserve

	keep if Fecha_tri == yq(2014,3)

	keep identif 

	duplicates drop
	
	tempfile nits

	save "$input\nits_cred_externo_2014_3.dta", replace

restore

// y nos quedamos solo con esos nits

merge m:1 identif using "$input\nits_cred_externo_2014_3.dta"

keep if _merge == 3

drop _merge

// balanceamos el panel

egen firma = group(identif)

xtset firma Fecha_tri

tsfill, full 

// recuperamos los nits perdidos

preserve 

	keep firma identif

	drop if identif == ""

	duplicates drop

	rename identif nit

	tempfile nits

	save `nits'

restore

merge m:1 firma using `nits'

replace identif = nit if identif == ""

drop nit _merge

// reemplazamos los missings por 0

replace capital_USD = 0 if capital_USD == .

replace capitalme_USD = 0 if capitalme_USD == .

replace capitalml_USD = 0 if capitalml_USD == .

replace desem_cred_externo = 0 if desem_cred_externo == .

// mergeamos con la base de pasivos de 2013 

merge m:1 identif using "$input\total_pasivos_firmas_2013.dta"

keep if _merge == 3 // no contamos con datos pasivos para todas las firmas 

// generamos la proporción de desembolsos de crédito externo y de nuevos créditos domésticos con respecto a la deuda total de 2013-4. Lo que haremos es que el denominador para cada trimestre seran los pasivos totales de la firma en 2013-4, mientras que el numerador será los desembolsos o los nuevos créditos acumulados para cada trimestre.

// generamos las variables acumuladas

bys identif (Fecha_tri): gen desembolsos_acum = sum(desem_cred_externo)

bys identif (Fecha_tri): gen capital_USD_acum = sum(capital_USD)

bys identif (Fecha_tri): gen capitalme_USD_acum = sum(capitalme_USD)

bys identif (Fecha_tri): gen capitalml_USD_acum = sum(capitalml_USD)

// generamos las proporciones (como porcentaje)

gen prop_externo = (desembolsos_acum/total_pasivo_USD_2013) *100 // proporcion de los desembolsos de crédito externo (acumulados) sobre los pasivos totales de la firma en 2013-4

gen prop_capital = (capital_USD_acum/total_pasivo_USD_2013) *100 // proporcion de los nuevos créditos locales (acumulados) sobre los pasivos totales de la firma en 2013-4

gen prop_capitalme = (capitalme_USD_acum/total_pasivo_USD_2013) * 100 // proporcion de los nuevos créditos locales en dólares (acumulados) sobre los pasivos totales de la firma en 2013-4

gen prop_capitalml = (capitalml_USD_acum/total_pasivo_USD_2013) * 100 // proporcion de los nuevos créditos locales en pesos (acumulados) sobre los pasivos totales de la firma en 2013-4

**# 8.1) PROMEDIO DESEMBOLSOS Y NUEVO CRÉDITO COMO PORCENTAJE DE PASIVOS

preserve

	collapse (mean) prop*, by(Fecha_tri)

	twoway (line prop_externo Fecha_tri, lcolor(blue) lpattern(solid)) ///
	(line prop_capitalme Fecha_tri, lcolor(red) lpattern(solid)) ///
	(line prop_capitalml Fecha_tri, lcolor(green) lpattern(solid)), ytitle("Porcentaje") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito externo" 2 "Nuevo crédito doméstico" "moneda extranjera" 3 "Nuevo crédito doméstico" "moneda local")) note("Se muestra el promedio trimestral de desembolsos acumulados de crédito externo y de nuevo" "crédito doméstico acumulado en moneda extranjera y moneda local, como porcentaje de pasi" "vos totales de 2013-4." "Se utilizan solamente las firmas con desembolsos de crédito externo en 2014-3." "Los datos de pasivos se toman de la base de datos de Supersociedades.") xtick(`=tq(2013q4)' (2) `=tq(2016q4)') xlabel(`=tq(2013q4)' (2) `=tq(2016q4)')

	graph export "$output\promedio nuevos créditos como proporción de pasivos de 2013.png", replace

restore

// Lo siguiente es generar los datos necesarios para los gráficas con saldos 

// llamamos la base de datos del merge de la 341 con EE (en saldos)

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// dejamos solo los trimestres que nos interesan 

keep if Fecha_tri == yq(2014, 2) | Fecha_tri == yq(2014, 3) | Fecha_tri == yq(2014, 1) | Fecha_tri == yq(2014, 4) | Fecha_tri == yq(2013, 4)

// collapsamos todo a nivel firma-tiempo (recordemos que los datos de la EE ya estan a nivel firma-tiempo, pero los de 341 están a nivel firma-banco-tiempo)

collapse (mean) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri identif)

// mergamos con la base de los nits de las firmas que nos interesan (las que sacaron cred externo en 2014-3)

merge m:1 identif using "$input\nits_cred_externo_2014_3.dta"

keep if _merge == 3

drop _merge

// balanceamos el panel

egen firma = group(identif)

xtset firma Fecha_tri

tsfill, full 

// recuperamos los nits perdidos

preserve 

	keep firma identif

	drop if identif == ""

	duplicates drop

	rename identif nit

	tempfile nits

	save `nits'

restore

merge m:1 firma using `nits'

replace identif = nit if identif == ""

drop nit _merge

// reemplazamos los missings por 0

replace capital_USD = 0 if capital_USD == .

replace capitalme_USD = 0 if capitalme_USD == .

replace capitalml_USD = 0 if capitalml_USD == .

// mergeamos con la base de pasivos de 2013 

merge m:1 identif using "$input\total_pasivos_firmas_2013.dta"

keep if _merge == 3 // no contamos con datos pasivos para todas las firmas 

// generamos la proporción de saldos de cred local con respecto a la deuda total de 2013-4. Lo que haremos es que el denominador para cada trimestre seran los pasivos totales de la firma en 2013-4, mientras que el numerador será los saldos de deuda local para cada trimestre.

// generamos las proporciones (como porcentaje)

gen prop_capital = (capital_USD/total_pasivo_USD_2013) *100 // proporcion de los saldos cred locales sobre los pasivos totales de la firma en 2013-4

gen prop_capitalme = (capitalme_USD/total_pasivo_USD_2013) * 100 // proporcion de los saldos cred locales en dólares sobre los pasivos totales de la firma en 2013-4

gen prop_capitalml = (capitalml_USD/total_pasivo_USD_2013) * 100 // proporcion de los saldos cred locales en pesos sobre los pasivos totales de la firma en 2013-4

**# 8.2) PROMEDIO SALDOS CRÉDITO DOMÉSTICO COMO PORCENTAJE DE PASIVOS

preserve

	collapse (mean) prop*, by(Fecha_tri)

	twoway (line prop_capitalme Fecha_tri, lcolor(red) lpattern(solid)) ///
	(line prop_capitalml Fecha_tri, lcolor(green) lpattern(solid)), ytitle("Porcentaje") xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(order(1 "Saldos crédito doméstico" "moneda extranjera" 2 "Saldos crédito doméstico" "moneda local")) note("Se muestra el promedio trimestral de saldos de crédito doméstico en moneda extranjera y" "moneda local, como porcentaje de pasivos totales de 2013-4." " " "Se utilizan solamente las firmas con desembolsos de crédito externo en 2014-3." " " "Los datos de pasivos se tomaron de la base de datos de Supersociedades.")

	graph export "$output\promedio saldos como proporción de pasivos de 2013.png", replace

restore