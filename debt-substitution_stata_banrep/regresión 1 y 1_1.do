********************************************************************************
****************************** REGRESIÓN 1 Y 1.1 *******************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output"

**# 1) REGRESIÓN 1: VARIABLE DEPENDIENTE: CRÉDITO LOCAL EN DÓLARES

// llamamos la base de datos 

use "$input\base_reg_1_mon_extranj_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// Es importante recordar que el coeficiente de ins_5 se omite en todas las regresiones ya que es mutuamente excluyente con las demás dummies de insularidad.

// Igualmente, dado que se usan efectos fijos de firma-tiempo, la constante en las regresiones es irrelevante, ya que se le asigna una constante particular a cada grupo. Por lo mismo, no es posible omitir la constante para estimar el coeficiente de ins_5 en su lugar.

**# 1.1) FORMA BÁSICA

// generamos la variable de tiempo 

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\forma basica\reg_1_FE_firma_tiempo.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[valor]                     if _n == `num' + 1
	replace u = _b[valor] + 1.65* _se[valor]  if _n == `num' + 1
	replace d = _b[valor] - 1.65* _se[valor]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5.")
	
graph export "$output\IRFs\reg 1\forma basica\reg_1_FE_ins_5.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor] + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4.")
	
graph export "$output\IRFs\reg 1\forma basica\reg_1_FE_ins_4.png", replace


**# 1.2) INTERACTUANDO CON BRECHA DE TASAS 

// llamamos la base de datos 

use "$input\base_reg_1_mon_extranj_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// recordemos que la brecha de tasas es la tasa de tes a 10 años transformada a dólares por medio de la CIP - la tasa de treasuries a 10 años 

// media de la brecha de tasas: 5.585048 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\brecha\reg_1_FE_firma_tiempo_brecha.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) - 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_ins5_brecha.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_ins4_brecha.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_2)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor#c.brecha_tasas_2]     if _n == `num' +1
				replace u = _b[c.valor#c.brecha_tasas_2] + 1.65*_se[c.valor#c.brecha_tasas_2]  if _n == `num'+1
				replace d = _b[c.valor#c.brecha_tasas_2] - 1.65*_se[c.valor#c.brecha_tasas_2]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_brecha_interac.png", replace


**# 1.3) INTERACTUANDO CON BRECHA DE TASAS DE CRÉDITOS

// llamamos la base de datos 

use "$input\base_reg_1_mon_extranj_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_creditos.dta"

// recordemos que la brecha de tasas es el promedio ponderado de las tasas los créditos locales nuevos (tasa transformada a dólares por medio de la CIP) - el promedio ponderado de las tasas de los créditos externos nuevos

// media de la brecha de tasas: 6.352102 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\brecha tasas de créditos\reg_1_FE_firma_tiempo_brecha_cred.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) - 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_ins5_brecha_cred.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_ins4_brecha_cred.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_cred)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor#c.brecha_tasas_cred]     if _n == `num' +1
				replace u = _b[c.valor#c.brecha_tasas_cred] + 1.65*_se[c.valor#c.brecha_tasas_cred]  if _n == `num'+1
				replace d = _b[c.valor#c.brecha_tasas_cred] - 1.65*_se[c.valor#c.brecha_tasas_cred]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_brecha_cred_interac.png", replace


**# 2) REGRESIÓN 1: VARIABLE DEPENDIENTE: CRÉDITO LOCAL EN PESOS

// llamamos la base de datos 

use "$input\base_reg_1_mon_local_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// Es importante recordar que el coeficiente de ins_5 se omite en todas las regresiones ya que es mutuamente excluyente con las demás dummies de insularidad.

// Igualmente, dado que se usan efectos fijos de firma-tiempo, la constante en las regresiones es irrelevante, ya que se le asigna una constante particular a cada grupo. Por lo mismo, no es posible omitir la constante para estimar el coeficiente de ins_5 en su lugar.

**# 2.1) FORMA BÁSICA

// generamos la variable de tiempo 

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\forma basica\reg_1_FE_firma_tiempo_mon_local.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[valor]                     if _n == `num' + 1
	replace u = _b[valor] + 1.65* _se[valor]  if _n == `num' + 1
	replace d = _b[valor] - 1.65* _se[valor]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5.")
	
graph export "$output\IRFs\reg 1\forma basica\reg_1_FE_ins_5_mon_local.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor] + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4.")
	
graph export "$output\IRFs\reg 1\forma basica\reg_1_FE_ins_4_mon_local.png", replace


**# 2.2) INTERACTUANDO CON BRECHA DE TASAS 

// llamamos la base de datos 

use "$input\base_reg_1_mon_local_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// recordemos que la brecha de tasas es la tasa de tes a 10 años transformada a dólares por medio de la CIP - la tasa de treasuries a 10 años 

// media de la brecha de tasas: 5.585048 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\brecha\reg_1_FE_firma_tiempo_mon_local_brecha.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) - 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_ins5_mon_local_brecha.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_ins4_mon_local_brecha.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_2)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor#c.brecha_tasas_2]     if _n == `num' +1
				replace u = _b[c.valor#c.brecha_tasas_2] + 1.65*_se[c.valor#c.brecha_tasas_2]  if _n == `num'+1
				replace d = _b[c.valor#c.brecha_tasas_2] - 1.65*_se[c.valor#c.brecha_tasas_2]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_mon_local_brecha_interac.png", replace


**# 2.3) INTERACTUANDO CON BRECHA DE TASAS DE CRÉDITOS

// llamamos la base de datos 

use "$input\base_reg_1_mon_local_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_creditos.dta"

// recordemos que la brecha de tasas es el promedio ponderado de las tasas los créditos locales nuevos (tasa transformada a dólares por medio de la CIP) - el promedio ponderado de las tasas de los créditos externos nuevos

// media de la brecha de tasas: 6.352102 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\brecha tasas de créditos\reg_1_FE_firma_tiempo_mon_local_brecha_cred.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) - 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_ins5_mon_local_brecha_cred.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_ins4_mon_local_brecha_cred.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_cred)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor#c.brecha_tasas_cred]     if _n == `num' +1
				replace u = _b[c.valor#c.brecha_tasas_cred] + 1.65*_se[c.valor#c.brecha_tasas_cred]  if _n == `num'+1
				replace d = _b[c.valor#c.brecha_tasas_cred] - 1.65*_se[c.valor#c.brecha_tasas_cred]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_mon_local_brecha_cred_interac.png", replace


**# 3) REGRESIÓN 1: VARIABLE DEPENDIENTE: CRÉDITO LOCAL TOTAL

// llamamos la base de datos 

use "$input\base_reg_1_cred_total_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// Es importante recordar que el coeficiente de ins_5 se omite en todas las regresiones ya que es mutuamente excluyente con las demás dummies de insularidad.

// Igualmente, dado que se usan efectos fijos de firma-tiempo, la constante en las regresiones es irrelevante, ya que se le asigna una constante particular a cada grupo. Por lo mismo, no es posible omitir la constante para estimar el coeficiente de ins_5 en su lugar.

**# 3.1) FORMA BÁSICA

// generamos la variable de tiempo 

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\forma basica\reg_1_FE_firma_tiempo_cred_total.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[valor]                     if _n == `num' + 1
	replace u = _b[valor] + 1.65* _se[valor]  if _n == `num' + 1
	replace d = _b[valor] - 1.65* _se[valor]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5.")
	
graph export "$output\IRFs\reg 1\forma basica\reg_1_FE_ins_5_cred_total.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor] + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4.")
	
graph export "$output\IRFs\reg 1\forma basica\reg_1_FE_ins_4_cred_total.png", replace



**# 3.2) INTERACTUANDO CON BRECHA DE TASAS 

// llamamos la base de datos 

use "$input\base_reg_1_cred_total_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// recordemos que la brecha de tasas es la tasa de tes a 10 años transformada a dólares por medio de la CIP - la tasa de treasuries a 10 años 

// media de la brecha de tasas: 5.585048 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\brecha\reg_1_FE_firma_tiempo_cred_total_brecha.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) - 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_ins5_cred_total_brecha.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_2]*(5.585048)) + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((5.585048)^2) * (_se[c.valor#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_ins4_cred_total_brecha.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_2)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_2 c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor#c.brecha_tasas_2]     if _n == `num' +1
				replace u = _b[c.valor#c.brecha_tasas_2] + 1.65*_se[c.valor#c.brecha_tasas_2]  if _n == `num'+1
				replace d = _b[c.valor#c.brecha_tasas_2] - 1.65*_se[c.valor#c.brecha_tasas_2]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1\brecha\reg_1_FE_cred_total_brecha_interac.png", replace


**# 3.3) INTERACTUANDO CON BRECHA DE TASAS DE CRÉDITOS

// llamamos la base de datos 

use "$input\base_reg_1_cred_total_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_creditos.dta"

// recordemos que la brecha de tasas es el promedio ponderado de las tasas los créditos locales nuevos (tasa transformada a dólares por medio de la CIP) - el promedio ponderado de las tasas de los créditos externos nuevos

// media de la brecha de tasas: 6.352102 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1\brecha tasas de créditos\reg_1_FE_firma_tiempo_cred_total_brecha_cred.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) - 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_ins5_cred_total_brecha_cred.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1)) + 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.valor] + (_b[c.valor#c.brecha_tasas_cred]*(6.352102)) + (_b[c.valor#c.ins_4]*(1)) - 1.65*sqrt((_se[c.valor]^2) + (((6.352102)^2) * (_se[c.valor#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.valor#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_ins4_cred_total_brecha_cred.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_cred)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD c.valor##c.brecha_tasas_cred c.valor##c.ins_1 c.valor##c.ins_2 c.valor##c.ins_3 c.valor##c.ins_4 c.valor##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.valor#c.brecha_tasas_cred]     if _n == `num' +1
				replace u = _b[c.valor#c.brecha_tasas_cred] + 1.65*_se[c.valor#c.brecha_tasas_cred]  if _n == `num'+1
				replace d = _b[c.valor#c.brecha_tasas_cred] - 1.65*_se[c.valor#c.brecha_tasas_cred]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1\brecha tasas de créditos\reg_1_FE_cred_total_brecha_cred_interac.png", replace


**# 4) REGRESIÓN 1.1

// llamamos la base de datos 

use "$input\base_reg_1_1_mon_local_vs_mon_extranj_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// Es importante recordar que el coeficiente de ins_5 se omite en todas las regresiones ya que es mutuamente excluyente con las demás dummies de insularidad.

// Igualmente, dado que se usan efectos fijos de firma-tiempo, la constante en las regresiones es irrelevante, ya que se le asigna una constante particular a cada grupo. Por lo mismo, no es posible omitir la constante para estimar el coeficiente de ins_5 en su lugar.

**# 4.1) FORMA BÁSICA

// generamos la variable de tiempo 

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1.1\forma basica\reg_1_1_FE_firma_tiempo.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[var_capitalme_USD]                     if _n == `num' + 1
	replace u = _b[var_capitalme_USD] + 1.65* _se[var_capitalme_USD]  if _n == `num' + 1
	replace d = _b[var_capitalme_USD] - 1.65* _se[var_capitalme_USD]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5.")
	
graph export "$output\IRFs\reg 1.1\forma basica\reg_1_1_FE_ins_5.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.ins_4]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.ins_4]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_4]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4.")
	
graph export "$output\IRFs\reg 1.1\forma basica\reg_1_1_FE_ins_4.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 3

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.ins_3]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.ins_3]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_3]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.ins_3]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_3]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 3.")
	
graph export "$output\IRFs\reg 1.1\forma basica\reg_1_1_FE_ins_3.png", replace


**# 4.2) INTERACTUANDO CON BRECHA DE TASAS 

// llamamos la base de datos 

use "$input\base_reg_1_1_mon_local_vs_mon_extranj_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// recordemos que la brecha de tasas es la tasa de tes a 10 años transformada a dólares por medio de la CIP - la tasa de treasuries a 10 años 

// media de la brecha de tasas: 5.585048 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1.1\brecha\reg_1_1_FE_firma_tiempo_brecha.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1.1\brecha\reg_1_1_FE_ins5_brecha.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + (_b[c.var_capitalme_USD#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + (_b[c.var_capitalme_USD#c.ins_4]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + (_b[c.var_capitalme_USD#c.ins_4]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1.1\brecha\reg_1_1_FE_ins4_brecha.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 3


eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + (_b[c.var_capitalme_USD#c.ins_3]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + (_b[c.var_capitalme_USD#c.ins_3]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_3]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + (_b[c.var_capitalme_USD#c.ins_3]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_3]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 3." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg 1.1\brecha\reg_1_1_FE_ins3_brecha.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_2)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brecha_tasas_2]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brecha_tasas_2] + 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_2]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brecha_tasas_2] - 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_2]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1.1\brecha\reg_1_1_FE_brecha_interac.png", replace


**# 4.3) INTERACTUANDO CON BRECHA DE TASAS DE CRÉDITOS

// llamamos la base de datos 

use "$input\base_reg_1_1_mon_local_vs_mon_extranj_insu.dta", clear

// generamos una dummy para cada insularidad

gen ins_1 = 0
replace ins_1 = 1 if insularidad_definitiva == 1

gen ins_2 = 0
replace ins_2 = 1 if insularidad_definitiva == 2

gen ins_3 = 0
replace ins_3 = 1 if insularidad_definitiva == 3

gen ins_4 = 0
replace ins_4 = 1 if insularidad_definitiva == 4

gen ins_5 = 0
replace ins_5 = 1 if insularidad_definitiva == 5

// mergeamos con la base de datos que contiene los datos de brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_creditos.dta"

// recordemos que la brecha de tasas es el promedio ponderado de las tasas los créditos locales nuevos (tasa transformada a dólares por medio de la CIP) - el promedio ponderado de las tasas de los créditos externos nuevos

// media de la brecha de tasas: 6.352102 (esto es cuando se saca la media habiendo collapsado por trimestre)

// generamos la variable de tiempo

egen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	outreg2 using "$output\regresiones\reg 1.1\brecha tasas de créditos\reg_1_1_FE_firma_tiempo_brecha_cred.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 5

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 5." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1.1\brecha tasas de créditos\reg_1_1_FE_ins5_brecha_cred.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 4

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + (_b[c.var_capitalme_USD#c.ins_4]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + (_b[c.var_capitalme_USD#c.ins_4]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_4]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + (_b[c.var_capitalme_USD#c.ins_4]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_4]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 4." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1.1\brecha tasas de créditos\reg_1_1_FE_ins4_brecha_cred.png", replace

// graficamos el IRF del efecto marginal del crédito externo para las firmas de insularidad 3


eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons // vce(robust)
	
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + (_b[c.var_capitalme_USD#c.ins_3]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + (_b[c.var_capitalme_USD#c.ins_3]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_3]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + (_b[c.var_capitalme_USD#c.ins_3]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)) + (((1)^2) * (_se[c.var_capitalme_USD#c.ins_3]^2)))   if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Se muestra el efecto marginal del crédito externo para las firmas de insularidad 3." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg 1.1\brecha tasas de créditos\reg_1_1_FE_ins3_brecha_cred.png", replace

// graficamos el IRF de la interacción entre el crédito externo y la brecha de tasas (valor*brecha_tasas_cred)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred c.var_capitalme_USD##c.ins_1 c.var_capitalme_USD##c.ins_2 c.var_capitalme_USD##c.ins_3 c.var_capitalme_USD##c.ins_4 c.var_capitalme_USD##c.ins_5, a(firma tiempo) nocons //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brecha_tasas_cred]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brecha_tasas_cred] + 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_cred]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brecha_tasas_cred] - 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_cred]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 1.1\brecha tasas de créditos\reg_1_1_FE_brecha_cred_interac.png", replace