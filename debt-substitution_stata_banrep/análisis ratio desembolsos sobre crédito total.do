********************************************************************************
**************** ANÁLISIS RATIO DESEMBOLSOS SOBRE CRÉDITO TOTAL ****************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output\descriptivas"

// En este dofile, para cada firma en cada trimestre vamos a generar el siguiente ratio: desembolsos de crédito externo/total de nuevo crédito (esto incluye nuevo crédito doméstico y desembolsos de crédito externo). A partir de ese ratio, realizaremos distintos análisis.

**# 1) GENERACIÓN DATOS 

// llamamos la base que tiene los nuevos créditos de 341 y desembolsos de EE a nivel firma-tiempo

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear

// eliminamos a min hacienda

drop if identif == "899999090"

// generamos una variable que es los desembolsos de crédito externo sobre los nuevos créditos totales (nuevo crédito doméstico + desembolsos de crédito externo) para cada firma en vcada trimestre 

gen ratio_exter_total = valor / (valor + capital_USD)

// nos quedamos solo las observaciones que tienen desembolsos de cred externo 

keep if valor != 0

// generamos el panel para calcular la variacion del ratio 

egen firma = group(identif)

xtset firma Fecha_tri 

bys firma (Fecha_tri): gen var_ratio = ratio_exter_total - L1.ratio_exter_total

// reemplacemos los missings de esa variable por su valor correspondiente 

bys firma (Fecha_tri): replace var_ratio = ratio_exter_total if ratio_exter_total > 0 & var_ratio == . 
replace var_ratio = . if Fecha_tri == yq(2000, 1)

// igualmente generamos el ratio pero ponderado por lo que representa la deuda externa de esa firma sobre el total de la deuda externa de todo el sistema en cada trimestre 

// generamos la variable de proporcion, la cual es la deuda externa de cada firma sobre el total de deuda externa en cada trimestre

preserve

	collapse (rawsum) valor, by(Fecha_tri)

	rename valor total_trimestre

	tempfile total

	save `total'

restore

merge m:1 Fecha_tri using `total'

drop _merge

gen proporcion = valor / total_trimestre

// generamos el ratio ponderado 

gen ratio_pon = ratio_exter_total * proporcion

// y su variación

bys firma (Fecha_tri): gen var_ratio_pon = ratio_pon - L1.ratio_pon

// reemplacemos los missings de esa variable por su valor correspondiente 

bys firma (Fecha_tri): replace var_ratio_pon = ratio_pon if ratio_pon > 0 & var_ratio_pon == .
replace var_ratio_pon = . if Fecha_tri == yq(2000, 1)

// generamos la desviación estandar del ratio y del ratio ponderado para cada firma a lo largo de todo el periodo

// para ello, en un preserve, vamos a collapsar la variable del ratio como desviacion estandar a nivel de firma. Luego lo mergeamos con la base original

preserve

	collapse (sd) ratio_exter_total ratio_pon, by(identif)

	gen sd = (ratio_exter_total) ^ 2
	
	gen sd_pon = (ratio_pon) ^ 2

	keep identif sd sd_pon

	tempfile sd

	save `sd'
	
	// 9,562 firmas de 21,087 solo sacan cred externo una sola vez en todo el periodo (por ello su desviación estandar es .)

restore

merge m:1 identif using `sd'

drop _merge

// las firmas que tienen desviación estandar de . es porque solo sacaron crédito externo una sola vez en todo el periodo

// mergeamos con la base de datos de la tasa de cambio trimestral 

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

keep if _merge == 3

drop _merge

// mergeamos con la base de datos de brecha de tasas 

merge m:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// recordemos que la brecha de tasas es la tasa de tes a 10 años transformada a dólares por medio de la CIP - la tasa de treasuries a 10 años. Se tienen datos desde 2003

drop tasa* brecha_tasas_1

drop _merge

// tambien con la base que tiene la brecha de tasas de los créditos 

merge m:1 Fecha_tri using "$input\brecha_tasas_creditos.dta"

drop _merge

drop total_trimestre

// como alternativa a la desviación estandar, generemos la diferencia entre el valor maximo y el valor minimo de cada firma 

egen max_ratio = max(ratio_exter_total), by(firma)
egen min_ratio = min(ratio_exter_total), by(firma)

gen rango_ratio = max_ratio - min_ratio

egen max_ratio_pon = max(ratio_pon), by(firma)
egen min_ratio_pon = min(ratio_pon), by(firma)

gen rango_ratio_pon = max_ratio - min_ratio

// reemplazamos esos rangos por missing para las firmas que solo aparecen una vez 

egen apariciones = count(firma), by(firma)

replace rango_ratio = . if apariciones == 1

replace rango_ratio_pon = . if apariciones == 1

egen max_apariciones = max(apariciones) // el numero maximo de apariciones es 79

drop min* max*

// guardemos esta base de datos 

save "$input\base_analisis_firmas.dta", replace // base de datos que contiene todas las variables necesarias para hacer el analisis del ratio de las firmas


**# 2) ANÁLISIS RATIO 

// llamamos la base de datos creada en la sección 1

use "$input\base_analisis_firmas.dta", clear

// veamos en qué trimestres cambió más el ratio (en promedio)

preserve 

	**# 2.1) PROMEDIO RATIO POR TRIMESTRE

	collapse (mean) var_ratio ratio_exter_total, by(Fecha_tri)
	
	twoway (line ratio_exter_total Fecha_tri, yaxis(1) lcolor(blue) lpattern(solid)), ytitle("Ratio", axis(1)) xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(off) note("Se muestra el promedio trimestral del ratio de desembolsos de crédito externo sobre el total" "de nuevo crédito (doméstico y externo).") 
	
	graph export "$output\promedio_trimestral_ratio.png", replace
	
	**# 2.2) PROMEDIO CAMBIO EN EL RATIO POR TRIMESTRE
	
	// por temas de estética, agregamos una observacion adicional al dataset, que corresponda al trimestre 2020q1 (va a ser una observación vacia)

	insobs 1

	replace Fecha_tri = yq(2020, 1) if Fecha_tri == .
	
	graph bar var_ratio, over(Fecha_tri, relabel(1 "2000q1" 2 " " 3 " " 4 " " 5 " " 6 " " 7 " " 8 " " 9 " " 10 " " 11 " " 12 " " 13 " " 14 " " 15 " " 16 " " 17 " " 18 " " 19 " " 20 " " 21 "2005q1" 22 " " 23 " " 24 " " 25 " " 26 " " 27 " " 28 " " 29 " " 30 " " 31 " " 32 " " 33 " " 34 " " 35 " " 36 " " 37 " " 38 " " 39 " " 40 " " 41 "2010q1" 42 " " 43 " " 44 " " 45 " " 46 " " 47 " " 48 " " 49 " " 50 " " 51 " " 52 " " 53 " " 54 " " 55 " " 56 " " 57 " " 58 " " 59 " " 60 " " 61 "2015q1" 62 " " 63 " " 64 " " 65 " " 66 " " 67 " " 68 " " 69 " " 70 " " 71 " " 72 " " 73 " " 74 " " 75 " " 76 " " 77 " " 78 " " 79 " " 80 " " 81 "2020q1")) bar(1, color(green)) ytitle("Cambio en el Ratio") graphregion(color(white)) plotregion(color(white) style(none)) legend(off) note("Se muestra el promedio trimestral del cambio del ratio de desembolsos de crédito externo" "sobre el total de nuevo crédito (doméstico y externo).") 
	
	graph export "$output\promedio_trimestral_cambio_ratio.png", replace
	
	// organicemos las variables según el cambio en el ratio, en orden descendente 
	
	gsort -var_ratio
	
	// los siguientes son los trimestres en los que el cambio en el ratio (en promedio) fue mayor
	
	/*
	
	Fecha_tri	var_ratio
		2017q3	.5925205
		2008q4	.5783824
		2015q3	.5705252
		2012q1	.5643754
		2011q2	.5642854
		2014q4	.5594182
		2011q4	.5591754
		2011q3	.5579127
		2012q4	.5575098
		2012q3	.5467658
		2015q2	.538924
		2016q1	.5377697
		2013q4	.5355484
		2015q4	.5342609
		2013q1	.5232913
*/

restore

**# 2.3) HISTOGRAMA DESVIACIÓN ESTANDAR DEL RATIO

preserve

	collapse (lastnm) sd apariciones, by(identif)
	
	// reescalamos las apariciones para que esten de 0 a 1
	
	gen apariciones_rees = apariciones / 79 // el número máximo de apariciones es 79
	
	// multiplicamos la desviacion por las apariciones. Esto es para darle más peso a la desviación de aquellas firmas que más veces aparecieron en la base de datos
	
	gen sd_pon = sd * apariciones_rees

	histogram sd_pon, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Desviación estandar ratio") note("Se muestra el histograma de la desviación estandar del ratio de desembolsos de crédito externo" "sobre el total de nuevo crédito (doméstico y externo) de cada firma." "Algunas firmas solo aparecen una vez en la base de datos. Por ello, no cuentan con desviación" "estandar." "Se muestra la desviación estandar ponderada por el número de apariciones de cada firma.")

	graph export "$output\histograma_sd_ratio.png", replace
	
	// organizamos las observaciones según la desviación estandar (ponderada por el número de apariciones), en orden descendente
	
	gsort -sd_pon
	
	// las 15 firmas con mayor desviación estandar son:
	
	/*
	identif		sd_pon
	860027136	.1160289
	830037330	.10063
	890100251	.0984374
	890900286	.0982678
	860031028	.0970477
	890301960	.0956482
	890300431	.0956414
	890900308	.0913821
	860007538	.0903644
	860525060	.0901616
	890906119	.0864688
	860049313	.0863197
	891800111	.0855215
	800103903	.0838947
	890106527	.0807403

	*/

restore


// veamos un poco el comportamiento de dos firmas, a modo de ejemplo. Estas serán las dos firmas con la desviación estandar ponderada más alta. Veamos el comportamiento de estas dos firmas durante todo el periodo, tanto en el mercado doméstico como externo.

// llamamos la base de datos nuevos créditos domésticos y desembolsos de crédito externo a nivel de firma

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear

// nos quedamos solo con estas dos firmas 

keep if identif == "860027136" | identif == "830037330" 

**# 2.4) NUEVO CRÉDITO Y DESEMBOLSOS - TEXTILIA S.AS

// grafiquemos la serie de tiempo de desembolsos de cred externo y de nuevo crédito doméstico para la firma 860027136 - Textilia S.A.S

sort identif Fecha_tri

// un solo eje 

twoway (line valor Fecha_tri if identif == "860027136", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "860027136", yaxis(1) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "860027136", yaxis(1) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito doméstico" "en moneda extranjera y moneda local de la firma Textilia S.A.S." ) ylabel(, angle(0) axis(1)) 

graph export "$output\desembolsos y nuevo cred textilia.png", replace

// dos ejes

twoway (line valor Fecha_tri if identif == "860027136", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "860027136", yaxis(2) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "860027136", yaxis(2) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1)) ytitle("Millones de dólares" "(crédito doméstico)", axis(2))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito doméstico" "en moneda extranjera y moneda local de la firma Textilia S.A.S." "El eje de la izquierda muestra los valores para los desembolsos de crédito externo, mientras que" "el de la derecha muestra los valores para el nuevo crédito doméstico.") ylabel(, angle(0) axis(1))  ylabel(, angle(0) axis(2)) 

graph export "$output\desembolsos y nuevo cred textilia dos ejes.png", replace

**# 2.5) NUEVO CRÉDITO Y DESEMBOLSOS - TELEFÓNICA MÓVILES MONTERÍA

// grafiquemos la serie de tiempo de desembolsos de cred externo y de nuevo crédito doméstico para la firma 830037330 - Telefonica Moviles Monteria

sort identif Fecha_tri

// un solo eje 

twoway (line valor Fecha_tri if identif == "830037330", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "830037330", yaxis(1) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "830037330", yaxis(1) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito doméstico" "en moneda extranjera y moneda local de la firma Telefonica Moviles Monteria." ) ylabel(, angle(0) axis(1)) 

graph export "$output\desembolsos y nuevo cred telefonica.png", replace

// dos ejes

twoway (line valor Fecha_tri if identif == "830037330", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "830037330", yaxis(2) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "830037330", yaxis(2) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1)) ytitle("Millones de dólares" "(crédito doméstico)", axis(2))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito doméstico" "en moneda extranjera y moneda local de la firma Telefonica Moviles Monteria." "El eje de la izquierda muestra los valores para los desembolsos de crédito externo, mientras que" "el de la derecha muestra los valores para el nuevo crédito doméstico.") ylabel(, angle(0) axis(1))  ylabel(, angle(0) axis(2)) 

graph export "$output\desembolsos y nuevo cred telefonica dos ejes.png", replace


**# 3) ANÁLISIS RATIO PONDERADO

// llamamos la base de datos generada en la primera sección

use "$input\base_analisis_firmas.dta", clear

// veamos en qué trimestres cambió más el ratio ponderado (en promedio)

preserve 

	**# 3.1) PROMEDIO RATIO PONDERADO POR TRIMESTRE

	collapse (mean) var_ratio_pon ratio_pon, by(Fecha_tri)
	
	twoway (line ratio_pon Fecha_tri, yaxis(1) lcolor(blue) lpattern(solid)), ytitle("Ratio", axis(1)) xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(off) note("Se muestra el promedio trimestral del ratio de desembolsos de crédito externo sobre el total de nuevo" "crédito (doméstico y externo)." "El ratio de cada firma en cada trimestre  es ponderado por cuánto representa el desembolso de" "crédito externo de esa firma sobre el total de desembolsos de crédito externo de todo el sistema.") 
	
	graph export "$output\promedio_trimestral_ratio_ponderado.png", replace
	
	**# 3.2) PROMEDIO CAMBIO EN EL RATIO POR TRIMESTRE
	
	// por temas de estética, agregamos una observacion adicional al dataset, que corresponda al trimestre 2020q1 (va a ser una observación vacia)

	insobs 1

	replace Fecha_tri = yq(2020, 1) if Fecha_tri == .
	
	graph bar var_ratio_pon, over(Fecha_tri, relabel(1 "2000q1" 2 " " 3 " " 4 " " 5 " " 6 " " 7 " " 8 " " 9 " " 10 " " 11 " " 12 " " 13 " " 14 " " 15 " " 16 " " 17 " " 18 " " 19 " " 20 " " 21 "2005q1" 22 " " 23 " " 24 " " 25 " " 26 " " 27 " " 28 " " 29 " " 30 " " 31 " " 32 " " 33 " " 34 " " 35 " " 36 " " 37 " " 38 " " 39 " " 40 " " 41 "2010q1" 42 " " 43 " " 44 " " 45 " " 46 " " 47 " " 48 " " 49 " " 50 " " 51 " " 52 " " 53 " " 54 " " 55 " " 56 " " 57 " " 58 " " 59 " " 60 " " 61 "2015q1" 62 " " 63 " " 64 " " 65 " " 66 " " 67 " " 68 " " 69 " " 70 " " 71 " " 72 " " 73 " " 74 " " 75 " " 76 " " 77 " " 78 " " 79 " " 80 " " 81 "2020q1")) bar(1, color(green)) ytitle("Cambio en el Ratio") graphregion(color(white)) plotregion(color(white) style(none)) legend(off) note("Se muestra el promedio trimestral del cambio del ratio de desembolsos de crédito externo" "sobre el total de nuevo crédito (doméstico y externo)." "El ratio de cada firma en cada trimestre  es ponderado por cuánto representa el desembolso de" "crédito externo de esa firma sobre el total de desembolsos de crédito externo de todo el sistema.") 
	
	graph export "$output\promedio_trimestral_cambio_ratio_ponderado.png", replace
	
	// organicemos las variables según el cambio en el ratio ponderado, en orden descendente 
	
	gsort -var_ratio
	
	// los siguientes son los trimestres en los que el cambio en el ratio ponderado (en promedio) fue mayor
	
	/*
	
	Fecha_tri	var_ratio_pon
		2011q2	.0015582
		2011q4	.0013832
		2016q1	.0009529
		2012q1	.0008485
		2007q3	.0008008
		2011q3	.0007873
		2013q3	.0007739
		2017q1	.0007695
		2013q1	.0006816
		2012q4	.0006327
		2014q1	.000608
		2001q1	.0005859
		2012q2	.0005821
		2015q3	.0005729
		2016q3	.0005548
*/

restore

**# 3.3) HISTOGRAMA DESVIACIÓN ESTANDAR DEL RATIO PONDERADO

preserve

	collapse (lastnm) sd_pon apariciones, by(identif)
	
	// reescalamos las apariciones para que esten de 0 a 1
	
	gen apariciones_rees = apariciones / 79
	
	// multiplicamos la desviacion por las apariciones. Esto es para darle más peso a la desviación de aquellas firmas que más veces aparecieron en la base de datos
	
	gen sd_pon_2 = sd * apariciones_rees

	histogram sd_pon_2, graphregion(color(white)) plotregion(color(white) style(none)) xtitle("Desviación estandar ratio") note("Se muestra el histograma de la desviación estandar del ratio de desembolsos de crédito externo" "sobre el total de nuevo crédito (doméstico y externo) de cada firma." "El ratio de cada firma en cada trimestre  es ponderado por cuánto representa el desembolso de" "crédito externo de esa firma sobre el total de desembolsos de crédito externo de todo el sistema." "Algunas firmas solo aparecen una vez en la base de datos. Por ello, no cuentan con desviación" "estandar." "Se muestra la desviación estandar ponderada por el número de apariciones de cada firma.") bin(20)

	graph export "$output\histograma_sd_ratio_ponderado.png", replace
	
	// organizamos las observaciones según la desviación estandar (ponderada por el número de apariciones), en orden descendente
	
	gsort -sd_pon_2
	
	// las 15 firmas con mayor desviación estandar son:
	
	/*
	identif		sd_pon_2
	830070235	.0192344
	830054539	.0052909
	899999068	.0049699
	900342628	.0042628
	811000740	.0021004
	890100577	.0018372
	860041312	.0015249
	800153993	.0014614
	890904996	.001294
	830037330	.0011394
	860002964	.0011134
	900112515	.001093
	860005224	.0009856
	899999061	.0009434
	900134459	.0009257
	*/

restore


// veamos un poco el comportamiento de dos firmas, a modo de ejemplo. Estas serán las dos firmas con la desviación estandar ponderada más alta. Veamos el comportamiento de estas dos firmas durante todo el periodo, tanto en el mercado doméstico como externo.

// llamamos la base de datos nuevos créditos desembolsos a nivel de firma

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear

// nos quedamos solo con estas dos firmas 

keep if identif == "830070235" | identif == "899999068" 

**# 3.4) NUEVO CRÉDITO Y DESEMBOLSOS - REMBRANDT

// grafiquemos la serie de tiempo de desembolsos de cred externo y de nuevo crédito doméstico para la firma 830070235 - Rembrandt

sort identif Fecha_tri

// un solo eje 

twoway (line valor Fecha_tri if identif == "830070235", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "830070235", yaxis(1) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "830070235", yaxis(1) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito doméstico" "en moneda extranjera y moneda local de la firma Rembrandt." ) ylabel(, angle(0) axis(1)) 

graph export "$output\desembolsos y nuevo cred Rembrandt.png", replace

// dos ejes

twoway (line valor Fecha_tri if identif == "830070235", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "830070235", yaxis(2) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "830070235", yaxis(2) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1)) ytitle("Millones de dólares" "(crédito doméstico)", axis(2))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito" "doméstico en moneda extranjera y moneda local de la firma Rembrandt." "El eje de la izquierda muestra los valores para los desembolsos de crédito externo," "mientras que el de la derecha muestra los valores para el nuevo crédito doméstico.") ylabel(, angle(0) axis(1))  ylabel(, angle(0) axis(2)) 

graph export "$output\desembolsos y nuevo cred Rembrandt dos ejes.png", replace


**# 3.5) NUEVO CRÉDITO Y DESEMBOLSOS - ECOPETROL

// grafiquemos la serie de tiempo de desembolsos de cred externo y de nuevo crédito doméstico para la firma 899999068 - Ecopetrol

sort identif Fecha_tri

// un solo eje 

twoway (line valor Fecha_tri if identif == "899999068", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "899999068", yaxis(1) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "899999068", yaxis(1) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito doméstico" "en moneda extranjera y moneda local de la firma Ecopetrol." ) ylabel(, angle(0) axis(1)) 

graph export "$output\desembolsos y nuevo cred Ecopetrol.png", replace

// dos ejes

twoway (line valor Fecha_tri if identif == "899999068", yaxis(1) lcolor(blue) lpattern(solid)) ///
(line capitalme_USD Fecha_tri if identif == "899999068", yaxis(2) lcolor(red) lpattern(solid)) ///
(line capitalml_USD Fecha_tri if identif == "899999068", yaxis(2) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1)) ytitle("Millones de dólares" "(crédito doméstico)", axis(2))  xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito" "doméstico en moneda extranjera y moneda local de la firma Ecopetrol." "El eje de la izquierda muestra los valores para los desembolsos de crédito externo," "mientras que el de la derecha muestra los valores para el nuevo crédito doméstico.") ylabel(, angle(0) axis(1))  ylabel(, angle(0) axis(2)) 

graph export "$output\desembolsos y nuevo cred Ecopetrol dos ejes.png", replace


**# 4) REGRESIONES

// llamamos la base de datos generada en la sección 1

use "$input\base_analisis_firmas.dta", clear

// vamos a hacer dos regresiones. La dependiente siempre va a ser el ratio, mientra que la explicativa será 1) la tasa de cambio y 2) la brecha de tasas (la brecha de tasas de tes y treasuries)

**# 4.1) FORMA ESTANDAR

**# 4.1.1) EXPLICATIVA: TASA DE CAMBIO

reghdfe ratio_exter_total TRM, a(firma) //vce(robust)
	
outreg2 using "$output\reg_TRM.xls", append excel

**# 4.1.2) EXPLICATIVA: BRECHA DE TASA

reghdfe ratio_exter_total brecha_tasas_2, a(firma) //vce(robust)
	
outreg2 using "$output\reg_brecha.xls", append excel // recordar que se pierden las observaciones antes de 2003

**# 4.2) CONTROLANDO POR PROPORCIÓN DE LA DEUDA (DESEMBOLSOS DE LA FIRMA/DESEMBOLSOS DEL SISTEMA)

**# 4.2.1) EXPLICATIVA: TASA DE CAMBIO

reghdfe ratio_exter_total TRM proporcion, a(firma) //vce(robust)
	
outreg2 using "$output\reg_TRM.xls", append excel

**# 4.2.2) EXPLICATIVA: BRECHA DE TASA

reghdfe ratio_exter_total brecha_tasas_2 proporcion, a(firma) //vce(robust)
	
outreg2 using "$output\reg_brecha.xls", append excel // recordar que se pierden las observaciones antes de 2003