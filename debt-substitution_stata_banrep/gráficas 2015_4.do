********************************************************************************
******************************** GRÁFICAS 2015-4 *******************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output\descriptivas"

// En este dofile generaremos algunas gráficas a nivel de banco y a nivel de firmas con información correspondiente al 2014.

**# 1) DEFINICIÓN DE EXPOSICIÓN (BANCOS)

// A continuación vamos a generar la "exposición" de los bancos en 2015-3 y 2015-4. La definición de "exposición" es distinta a la utilizada en el dofile "análisis descriptivo credit debt substitution". En este caso, la exposición está dada por cuánto representan los creditos del Top 25% de firmas que más desembolsos de crédito externo tuvo en 2015-4 sobre el total de cartera comercial del banco.

// primero haremos una base que contenga la cartera total de cada banco en 2015-3 con las firmas Top 25% de 2015-4

// llamamos la base de datos del merge de la 341 con EE (en saldos)

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear  

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos las variables de variación ya incluidas en la base

drop var_*

// para aquellas observaciones que no cuentan con un banco (codentid = .), reemplazaremos el código por 0

replace codentid = 0 if codentid == .

// para 2015-4:

// vamos a marcar el top 25% de las firmas que sacaron cred externo en 2015-4

preserve

	use "$input\top_firmas_cred_externo.dta", clear

	keep if Fecha_tri == yq(2015, 4)

	keep identif top_externo

	rename top_externo firmas_2015_4

	duplicates drop

	tempfile nits

	save `nits'

restore

// conservamos solo las observaciones del 2015-3 (periodo anterior al evento)

keep if Fecha_tri == yq(2015, 3)

// mergeamos con la base de nits que nos interesa

merge m:1 identif using `nits'

// conservamos solo las obs que mergean (es decir, solo las observaciones de las firmas top 25%)

keep if _merge == 3

// collapsamos para tener la cartera total del banco (en dolares, pesos y total) con las firmas Top 25% antes del trimestre del evento 

collapse (sum) capitalml_USD capitalme_USD capital_USD, by(codentid)

// eliminamos el banco 0

drop if codentid == 0

// guardemos esta base de datos 

save "$input\cartera_de_bancos_con_top_firmas_externo_2015_3.dta", replace // base de datos que contiene la cartera total de cada banco con las firmas top 25%. Esta cartera es solo para el trimestre 2015-3 (trimestre anterior al evento)

// ahora veamos la cartera total de cada banco en 2015-3

use "$input\Merge_341_EE_saldos_tasas_comparables.dta", clear  

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos las variables de variación ya incluidas en la base

drop var_*

// para aquellas observaciones que no cuentan con un banco (codentid = .), reemplazaremos el código por 0

replace codentid = 0 if codentid == .

// conservamos solo las observaciones del 2015-3 (periodo anterior al evento)

keep if Fecha_tri == yq(2015, 3)

// collapsamos para tener la cartera total del banco (en dolares, pesos y total) 

collapse (sum) capitalml_USD capitalme_USD capital_USD, by(codentid)

// eliminamos el banco 0

drop if codentid == 0

// renombremos las variables de cartera 

rename capital_USD cartera_total

rename capitalme_USD cartera_USD_total

rename capitalml_USD cartera_COP_total

// guardamos esta base de datos

save "$input\cartera_bancos_2015_3_y_2015_4.dta", replace // base de datos que contiene la cartera comercial total de los bancos en 2015-3 y 2015-4

// mergeamos con la base que contiene la cartera solo con el top 25% 

merge 1:1 codentid using "$input\cartera_de_bancos_con_top_firmas_externo_2015_3.dta"

// eliminamos la variable _merge

drop _merge

// renombramos variables

rename capital_USD cartera_top25

rename capitalme_USD cartera_USD_top25

rename capitalml_USD cartera_COP_top25

// reemplazamos missings por 0 

replace cartera_top25 = 0 if cartera_top25 == .

replace cartera_USD_top25 = 0 if cartera_USD_top25 == .

replace cartera_COP_top25 = 0 if cartera_COP_top25 == .

// generamos una variable que muestre la proporción de que representa la cartera con el top 25% sobre la cartera total (esta va a ser la exposicion)

gen exposicion = cartera_top25 / cartera_total 

// reescalamos la variable de exposicion para que sea igual a 1 para el más expuesto:

gen exposicion_resc = exposicion / .1631189

gen R = round(0 + (255) * exposicion_resc)
gen G = round(0)
gen B = round(255 - (255) * exposicion_resc)

// eliminamos las variables de cartera

drop cartera*

// guardamos esta base de datos 

save "$input\exposicion_y_colores_bancos_2015_4.dta", replace // base de datos que contiene las exposiciones y la paleta de colores para cada banco en 2015-3 y 2015-4


**# 2) GRÁFICAS BANCOS DOMÉSTICOS 2015-4

**# 2.1) PARA EL TOP 25%

// vamos a generar una base que contenga los nuevos créditos que cada banco le otorgó en 2015-3 y 2015-4 al Top 25% de firmas que más desembolsos de crédito externo tomó en 2015-4

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-banco-tiempo

use "$input\base341_nuevos_creditos_USD.dta", clear

// nos quedamos con los periodos que nos interesan 

keep if Fecha_tri == yq(2015, 3) | Fecha_tri == yq(2015, 4)

// mergeamos con la base que tiene los nits del Top 25% de 2015-4

merge m:1 identif using "$input\top_firmas_cred_externo_2015_4.dta"

keep if _merge == 3

drop _merge

// collapsamos a nivel banco tiempo

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri codentid)

// mergeamos esta base con la que tiene las carteras totales

merge 1:1 codentid Fecha_tri using "$input\cartera_bancos_2015_3_y_2015_4.dta"

drop _merge

// guardemos esta base 

save "$input\base_graficas_bancos_expo_2015_3_2015_4.dta", replace // base de datos que contiene los nuevos creditos otorgados por cada banco al Top 25% y la cartera comercial total de los bancos en 2015-3 y 2015-4.

// llamamos la que contiene los desembolsos de crédito externo y vamos a dejar solamente las firmas que nos interesan en los trimestres que nos interesan

use "$input\Merge_341_EE_tasas_comparables.dta", clear

// nos quedamos solamente con nit, banco, desembolso y trimestre 

keep identif codentid Fecha_tri valor

// nos quedamos solo con los trimestres 2015-3 y 2015-4

keep if Fecha_tri == yq(2015, 3) | Fecha_tri == yq(2015, 4)

// mergeamos con la base que tiene los nits del Top 25% de 2015-4

merge m:1 identif using "$input\top_firmas_cred_externo_2015_4.dta"

keep if _merge == 3

drop _merge

// collapsamos a nivel banco tiempo

collapse (sum) valor, by(codentid Fecha_tri)

drop if codentid == .

// renombramos la variable de desembolsos 

rename valor desem_exter

// mergeamos con la base de cartera total y nuevo crédito con el Top 25%

merge 1:1 codentid Fecha_tri using "$input\base_graficas_bancos_expo_2015_3_2015_4.dta"

drop _merge

replace desem_exter = 0 if desem_exter == .

// dividimos la nueva cartera con el Top 25% por la cartera total y lo expresamos en porcentaje 

gen prop_top25 = (capital_USD / cartera_total) *100

gen prop_top25_USD = (capitalme_USD / cartera_USD_total) *100

gen prop_top25_COP = (capitalml_USD / cartera_COP_total) *100

// dividimos los desembolsos del Top 25% por la cartera total de los bancos y lo expresamos en porcentaje 

gen prop_exter = (desem_exter / cartera_total) * 100

// ahora vamos a mergear con la base que tiene la exposición 

merge m:1 codentid using "$input\exposicion_y_colores_bancos_2015_4.dta"

drop _merge

// y mergeamos con la base que tiene los nombres de los bancos 

merge m:1 codentid using "$input\codigos_nombres_bancos.dta"

keep if _merge == 3

drop _merge

// establecemos el panel

egen banco = group(codentid)

xtset banco Fecha_tri

// generamos el lag de las variable de proporción

foreach var in prop_top25 prop_top25_COP prop_top25_USD prop_exter {

	bys banco (Fecha_tri): gen lag_`var' = L1.`var'

}

// nos quedamos solamente con el trimestre 2015-4

keep if Fecha_tri == yq(2015, 4)

**# 2.1.1) NUEVOS CRÉDITOS TOP 25% COMO PORCENTAJE DE CARTERA TOTAL

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar lag_prop_top25 prop_top25, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) bar(2, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos para los cuales la cartera comercial con firmas que" "hacen parte del Top 25% que más crédito externo sacó en 2015-4 representó un mayor por" "centaje de su cartera comercial total." "Para cada banco, la barra de la izquierda corresponde al trimestre 2015-3, mientras que la de" "la derecha corresponde a 2015-4.") legend(off) ylabel(, angle(0)) 

graph export "$output\nuevo credito como porcentaje de cartera bancos 2015.png", replace

**# 2.1.2) NUEVOS CRÉDITOS TOP 25% COMO PORCENTAJE DE CARTERA EN DÓLARES

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar lag_prop_top25_USD prop_top25_USD if exposicion_USD != ., over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) bar(2, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos para los cuales la cartera comercial con firmas que" "hacen parte del Top 25% que más crédito externo sacó en 2015-4 representó un mayor por" "centaje de su cartera comercial total." "Para cada banco, la barra de la izquierda corresponde al trimestre 2015-3, mientras que la de" "la derecha corresponde a 2015-4." "Los bancos omitidos no cuentan con cartera comercial en dólares.") legend(off) ylabel(, angle(0))

graph export "$output\nuevo credito dolares como porcentaje de cartera bancos 2015.png", replace

**# 2.1.3) NUEVOS CRÉDITOS TOP 25% COMO PORCENTAJE DE CARTERA EN PESOS

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar lag_prop_top25_COP prop_top25_COP, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) bar(2, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos para los cuales la cartera comercial con firmas que" "hacen parte del Top 25% que más crédito externo sacó en 2015-4 representó un mayor por" "centaje de su cartera comercial total." "Para cada banco, la barra de la izquierda corresponde al trimestre 2015-3, mientras que la de" "la derecha corresponde a 2015-4.") legend(off) ylabel(, angle(0))

graph export "$output\nuevo credito pesos como porcentaje de cartera bancos 2015.png", replace


**# 2.2) PARA LAS DEMÁS FIRMAS

// vamos a generar una base que contenga los nuevos créditos que cada banco le otorgó en 2015-3 y 2015-4 a las firmas distintas al Top 25% de firmas que más desembolsos de crédito externo tomó en 2015-4

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-banco-tiempo

use "$input\base341_nuevos_creditos_USD.dta", clear

// nos quedamos con los periodos que nos interesan 

keep if Fecha_tri == yq(2015, 3) | Fecha_tri == yq(2015, 4)

// mergeamos con la base que tiene los nits del Top 25% de 2015-4

merge m:1 identif using "$input\top_firmas_cred_externo_2015_4.dta"

keep if _merge != 3

drop _merge

// collapsamos a nivel banco tiempo

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri codentid)

// mergeamos esta base con la que tiene las carteras totales

merge 1:1 codentid Fecha_tri using "$input\cartera_bancos_2015_3_y_2015_4.dta"

drop _merge

// dividimos la nueva cartera con el Top 25% por la cartera total y lo expresamos en porcentaje 

gen prop_top25 = (capital_USD / cartera_total) *100

gen prop_top25_USD = (capitalme_USD / cartera_USD_total) *100

gen prop_top25_COP = (capitalml_USD / cartera_COP_total) *100

// ahora vamos a mergear con la base que tiene la exposición 

merge m:1 codentid using "$input\exposicion_y_colores_bancos_2015_4.dta"

drop _merge

// y mergeamos con la base que tiene los nombres de los bancos 

merge m:1 codentid using "$input\codigos_nombres_bancos.dta"

keep if _merge == 3

drop _merge

// establecemos el panel

egen banco = group(codentid)

xtset banco Fecha_tri

// generamos el lag de las variable de proporción

foreach var in prop_top25 prop_top25_COP prop_top25_USD {

	bys banco (Fecha_tri): gen lag_`var' = L1.`var'

}

// nos quedamos solamente con el trimestre 2015-4

keep if Fecha_tri == yq(2015, 4)

**# 2.2.1) NUEVOS CRÉDITOS DEMÁS FIRMAS COMO PORCENTAJE DE CARTERA TOTAL

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar lag_prop_top25 prop_top25, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) bar(2, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos para los cuales la cartera comercial con firmas que" "hacen parte del Top 25% que más crédito externo sacó en 2015-4 representó un mayor por" "centaje de su cartera comercial total." "Para cada banco, la barra de la izquierda corresponde al trimestre 2015-3, mientras que la de" "la derecha corresponde a 2015-4.") legend(off) ylabel(, angle(0)) 

graph export "$output\nuevo credito como porcentaje de cartera bancos otras firmas 2015.png", replace

**# 2.2.2) NUEVOS CRÉDITOS DEMÁS FIRMAS COMO PORCENTAJE DE CARTERA EN DÓLARES

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar lag_prop_top25_USD prop_top25_USD if exposicion_USD != ., over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) bar(2, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos para los cuales la cartera comercial con firmas que" "hacen parte del Top 25% que más crédito externo sacó en 2015-4 representó un mayor por" "centaje de su cartera comercial total." "Para cada banco, la barra de la izquierda corresponde al trimestre 2015-3, mientras que la de" "la derecha corresponde a 2015-4." "Los bancos omitidos no cuentan con cartera comercial en dólares.") legend(off) ylabel(, angle(0))

graph export "$output\nuevo credito dolares como porcentaje de cartera bancos otras firmas 2015.png", replace

**# 2.2.3) NUEVOS CRÉDITOS DEMÁS FIRMAS COMO PORCENTAJE DE CARTERA EN PESOS

// NOTA: para la siguiente gráfica se debe hacer la siguiente modificación de forma manual (en el editor de Stata) antes de guardar:
	// 1) Agregar el título del eje x, "Banco". Para ello, también se debe desmarcar la opción "Esconder caja de texto" en la sección "Avanzado".
	// 2) Modificar manualmente el color de cada barra según el nivel de exposición de cada banco. Para ello se debe tomar de referencia las variables "R", "G" Y "B". Se deben seguir los siguientes pasos:
		// - Dar click derecho a la barra a la cual se le quiera cambiar el color.
		// - Seleccionar "Propiedades especificas de objeto".
		// - En la casilla "Color", seleccionar "Confeccionar".
		// - Seleccionar "Definir colores personalizados".
		// - Modificar las casillas "R", "G" y "B" para que coincida con los valores de la base de datos correspondientes a ese banco.

graph bar lag_prop_top25_COP prop_top25_COP, over(corto, sort(exposicion) label(angle(45) labsize(vsmall))) bar(1, color("blue")) bar(2, color("blue")) ytitle("Porcentaje") graphregion(color(white)) plotregion(color(white) style(none)) note("Se ordenan los bancos según su nivel de exposición; de menos expuestos (izquierda) a más" "expuestos (derecha)." "Los bancos más expuestos son aquellos para los cuales la cartera comercial con firmas que" "hacen parte del Top 25% que más crédito externo sacó en 2015-4 representó un mayor por" "centaje de su cartera comercial total." "Para cada banco, la barra de la izquierda corresponde al trimestre 2015-3, mientras que la de" "la derecha corresponde a 2015-4.") legend(off) ylabel(, angle(0))

graph export "$output\nuevo credito dolares como porcentaje de cartera bancos otras firmas 2015.png", replace


**# 3) EVOLUCIÓN CRÉDITO EXTERNO Y DOMÉSTICO FIRMAS 

// Por último, generaremos una grafica que muestre el total de desembolsos de crédito externo y nuevos créditos doméstico de todas las firmas que tomaron desembolsos de crédito externo en 2015-4. El periodo de tiempo para esta gráfica será de 2014-4 a 2017-4

// llamamos la base de datos que contiene los nuevos créditos de 341 y desembolsos de crédito externo de la EE a nivel firma-tiempo

use "$input\nuevos_creditos_341_&_desembolsos_EE.dta", clear 

// eliminamos a MinHacienda

drop if identif == "899999090"

// eliminamos aquellas que no tienen crédito externo

drop if valor == 0

// conservamos solamente los periodos que nos interesan que son de 2014-4 a 2017-4

keep if Fecha_tri >= yq(2014,4) & Fecha_tri <= yq(2017,4) 

// renombramos la variable de desembolsos de crédito externo

rename valor desem_cred_externo

// y nos quedamos solo con esos nits

merge m:1 identif using "$input\nits_cred_externo_2015_4.dta" // mergeamos con la base que contiene los nits de todas las firmas con desembolsos en 2015-4

keep if _merge == 3

drop _merge 

// graficamos 

preserve

	collapse (sum) capital* desem, by(Fecha_tri)

	twoway (line desem Fecha_tri, yaxis(1) lcolor(blue) lpattern(solid)) ///
	(line capitalme_USD Fecha_tri, yaxis(2) lcolor(red) lpattern(solid)) ///
	(line capitalml_USD Fecha_tri, yaxis(2) lcolor(green) lpattern(solid)), ytitle("Millones de dólares" "(crédito externo)", axis(1)) ytitle("Millones de dólares" "(crédito doméstico)", axis(2)) xtitle("Trimestre") graphregion(color(white)) plotregion(color(white) style(none)) legend(size(small) order(1 "Desembolsos crédito" "externo" 2 "Nuevo crédito doméstico      " "moneda extranjera" 3 "Nuevos crédito doméstico" "moneda local")) note("Se muestra el total trimestral de desembolsos de crédito externo y de nuevo crédito" "doméstico en moneda extranjera y moneda local." "Se utilizan solamente las firmas con desembolsos de crédito externo en 2015-4." "El eje de la izquierda muestra los valores para los desembolsos de crédito externo," "mientras que el de la derecha muestra los valores para el nuevo crédito doméstico.") xtick(`=tq(2014q4)' (2) `=tq(2017q4)') xlabel(`=tq(2014q4)' (2) `=tq(2017q4)') ylabel(, angle(0) axis(1)) ylabel(200 (200) 1400, angle(0) axis(2)) 

	graph export "$output\total desembolsos y nuevo credito firmas con desem en 2015_4.png", replace

restore