********************************************************************************
************************** REGRESIÓN INTRODUCTORIA *****************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output"

**# 1) INTERACTUANDO CON PORCENTAJE DE CARTERA RIEGOSA

// llamamos la base de datos a nivel banco-tiempo con datos de cartera de los bancos y datos de hoja de balance

use "$input\base_reg_introductoria_activos.dta", clear

// agrupamos por tiempo (para usar los efectos fijos)

egen tiempo = group(Fecha_tri)

// la cartera riesgosa está como porcentaje (de 0 a 100)

// tomamos la cartera comercial riesgosa como proporcion de la cartera total

// media de la proporcion de cartera riesgosa: 5.043532

**# 1.1) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LA CARTERA EN PESOS

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.share_com_riesgosa_total acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\cartera riesgosa\reg_int_FE_riesgosa.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.share_com_riesgosa_total acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.share_com_riesgosa_total]*(5.043532))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.share_com_riesgosa_total]*(5.043532)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.043532)^2) * (_se[c.var_capitalme_USD#c.share_com_riesgosa_total]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.share_com_riesgosa_total]*(5.043532)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.043532)^2) * (_se[c.var_capitalme_USD#c.share_com_riesgosa_total]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa el porcentaje de cartera riesgosa en su" "media: 5.043532.")
	
graph export "$output\IRFs\reg introductoria\cartera riesgosa\reg_int_FE_riesgosa.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y el porcentaje de cartera riesgosa (var_capitalme_USD*share_com_riesgosa_total)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.share_com_riesgosa_total acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.share_com_riesgosa_total]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.share_com_riesgosa_total] + 1.65*_se[c.var_capitalme_USD#c.share_com_riesgosa_total]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.share_com_riesgosa_total] - 1.65*_se[c.var_capitalme_USD#c.share_com_riesgosa_total]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\cartera riesgosa\reg_int_FE_riesgosa_interac.png", replace


**# 1.2) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LAS INVERSIONES NETAS

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.share_com_riesgosa_total acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\cartera riesgosa\reg_int_inversiones_FE_riesgosa.xls", ctitle(lead `num' Inversiones) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.share_com_riesgosa_total acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.share_com_riesgosa_total]*(5.043532))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.share_com_riesgosa_total]*(5.043532)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.043532)^2) * (_se[c.var_capitalme_USD#c.share_com_riesgosa_total]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.share_com_riesgosa_total]*(5.043532)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.043532)^2) * (_se[c.var_capitalme_USD#c.share_com_riesgosa_total]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa el porcentaje de cartera riesgosa en su" "media: 5.043532.")
	
graph export "$output\IRFs\reg introductoria\cartera riesgosa\reg_int_inversiones_FE_riesgosa.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y el porcentaje de cartera riesgosa (var_capitalme_USD*share_com_riesgosa_total)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.share_com_riesgosa_total acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.share_com_riesgosa_total]    if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.share_com_riesgosa_total] + 1.65*_se[c.var_capitalme_USD#c.share_com_riesgosa_total]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.share_com_riesgosa_total] - 1.65*_se[c.var_capitalme_USD#c.share_com_riesgosa_total]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\cartera riesgosa\reg_int_inversiones_FE_riesgosa_interac.png", replace


**# 2) INTERACTUANDO CON BRECHA DE TASAS

// llamamos la base de datos a nivel banco-tiempo con datos de cartera de los bancos y datos de hoja de balance

use "$input\base_reg_introductoria_activos.dta", clear

// agrupamos por tiempo (para usar los efectos fijos)

egen tiempo = group(Fecha_tri)

// mergeamos con la base de datos que contiene la brecha de tasas para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_comparable.dta"

// recordemos que la brecha de tasas es la tasa de tes a 10 años transformada a dólares por medio de la CIP - la tasa de treasuries a 10 años 

// media de la brecha de tasas: 5.585048 (esto es cuando se saca la media habiendo collapsado por trimestre)

**# 2.1) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LA CARTERA EN PESOS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\brecha\reg_int_FE_brecha.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg introductoria\brecha\reg_int_FE_brecha.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la brecha de tasas (var_capitalme_USD*brecha_tasas_2)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_2 acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brecha_tasas_2]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brecha_tasas_2] + 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_2]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brecha_tasas_2] - 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_2]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\brecha\reg_int_FE_brecha_interac.png", replace


**# 2.2) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LAS INVERSIONES NETAS

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brecha_tasas_2 acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\brecha\reg_int_inversiones_FE_brecha.xls", ctitle(lead `num' Inversiones) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brecha_tasas_2 acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_2]*(5.585048)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((5.585048)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_2]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 5.585048")
	
graph export "$output\IRFs\reg introductoria\brecha\reg_int_inversiones_FE_brecha.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la brecha de tasas (var_capitalme_USD*brecha_tasas_2)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brecha_tasas_2 acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brecha_tasas_2]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brecha_tasas_2] + 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_2]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brecha_tasas_2] - 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_2]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\brecha\reg_int_inversiones_FE_brecha_interac.png", replace


**# 3) INTERACTUANDO CON POSICIÓN PROPIA (PP)

// llamamos la base de datos a nivel banco-tiempo con datos de cartera de los bancos y datos de hoja de balance

use "$input\base_reg_introductoria_activos.dta", clear

// agrupamos por tiempo (para usar los efectos fijos)

egen tiempo = group(Fecha_tri)

// mergeamos con la base que contiene los datos de PP

merge m:1 Fecha_tri codentid using "$input\PP_2003_2019.dta"

// recordemos que PP se encuentra como porcentaje del patrimonio técnico

// media de PP: 2.239615

**# 3.1) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LA CARTERA EN PESOS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.PP acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\PP\reg_int_FE_PP.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.PP , a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.PP]*(2.239615))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.PP]*(2.239615)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((2.239615)^2) * (_se[c.var_capitalme_USD#c.PP]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.PP]*(2.239615)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((2.239615)^2) * (_se[c.var_capitalme_USD#c.PP]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la posición propia en su media: 2.239615")
	
graph export "$output\IRFs\reg introductoria\PP\reg_int_FE_PP.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la PP (var_capitalme_USD*PP)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.PP , a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.PP]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.PP] + 1.65*_se[c.var_capitalme_USD#c.PP]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.PP] - 1.65*_se[c.var_capitalme_USD#c.PP]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\PP\reg_int_FE_PP_interac.png", replace


**# 3.2) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LAS INVERSIONES NETAS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.PP acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\PP\reg_int_inversiones_FE_PP.xls", ctitle(lead `num' Inversiones) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.PP , a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.PP]*(2.239615))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.PP]*(2.239615)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((2.239615)^2) * (_se[c.var_capitalme_USD#c.PP]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.PP]*(2.239615)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((2.239615)^2) * (_se[c.var_capitalme_USD#c.PP]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la posición propia en su media: 2.239615")
	
graph export "$output\IRFs\reg introductoria\PP\reg_int_inversiones_FE_PP.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la PP (var_capitalme_USD*PP)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.PP , a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.PP]    if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.PP] + 1.65*_se[c.var_capitalme_USD#c.PP]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.PP] - 1.65*_se[c.var_capitalme_USD#c.PP]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\PP\reg_int_inversiones_FE_PP_interac.png", replace


**# 4) INTERACTUANDO CON DUMMY DE CAMBIOS BRUSCOS POSITIVOS

// llamamos la base de datos a nivel banco-tiempo con datos de cartera de los bancos y datos de hoja de balance

use "$input\base_reg_introductoria_activos.dta", clear

// agrupamos por tiempo (para usar los efectos fijos)

egen tiempo = group(Fecha_tri)

// mergeamos con la base que contiene las variables de cambio brusco

merge m:1 Fecha_tri using "$input\variables_cambio_brusco.dta"

// recordemos que la dummy de cambios bruscos positivos se activa para los trimestres en que el cambio en el ratio EFE/(EFF+IMC) (donde EFE es el total de credito con entidades externas e IMC es el total del credito con entidades locales) se encuentra por encima del percentil 95.


**# 4.1) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LA CARTERA EN PESOS

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brusco_positivo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\cambio brusco positivo\reg_int_FE_brusco_positivo.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brusco_positivo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_positivo]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_positivo]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_positivo]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_positivo]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_positivo]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la dummy de cambio brusco en 1")
	
graph export "$output\IRFs\reg introductoria\cambio brusco positivo\reg_int_FE_brusco_positivo.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la dummy (var_capitalme_USD*brusco_positivo)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brusco_positivo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brusco_positivo]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brusco_positivo] + 1.65*_se[c.var_capitalme_USD#c.brusco_positivo]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brusco_positivo] - 1.65*_se[c.var_capitalme_USD#c.brusco_positivo]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\cambio brusco positivo\reg_int_FE_brusco_positivo_interac.png", replace


**# 4.2) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LAS INVERSIONES NETAS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brusco_positivo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\cambio brusco positivo\reg_int_inversiones_FE_brusco_positivo.xls", ctitle(lead `num' Inversiones) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brusco_positivo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_positivo]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_positivo]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_positivo]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_positivo]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_positivo]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la dummy de cambio brusco en 1.")
	
graph export "$output\IRFs\reg introductoria\cambio brusco positivo\reg_int_inversiones_FE_brusco_positivo.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la dummy (var_capitalme_USD*brusco_positivo)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brusco_positivo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brusco_positivo]    if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brusco_positivo] + 1.65*_se[c.var_capitalme_USD#c.brusco_positivo]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brusco_positivo] - 1.65*_se[c.var_capitalme_USD#c.brusco_positivo]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\cambio brusco positivo\reg_int_inversiones_FE_brusco_positivo_interac.png", replace


**# 5) INTERACTUANDO CON DUMMY DE CAMBIOS BRUSCOS NEGATIVOS

// recordemos que la dummy de cambios bruscos negativos se activa para los trimestres en que el cambio en el ratio EFE/(EFF+IMC) (donde EFE es el total de credito con entidades externas e IMC es el total del credito con entidades locales) se encuentra por debajo del percentil 5.


**# 5.1) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LA CARTERA EN PESOS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brusco_negativo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\cambio brusco negativo\reg_int_FE_brusco_negativo.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brusco_negativo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_negativo]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_negativo]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_negativo]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_negativo]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_negativo]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la dummy de cambio brusco en 1")
	
graph export "$output\IRFs\reg introductoria\cambio brusco negativo\reg_int_FE_brusco_negativo.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la dummy (var_capitalme_USD*brusco_negativo)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brusco_negativo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brusco_negativo]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brusco_negativo] + 1.65*_se[c.var_capitalme_USD#c.brusco_negativo]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brusco_negativo] - 1.65*_se[c.var_capitalme_USD#c.brusco_negativo]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\cambio brusco negativo\reg_int_FE_brusco_negativo_interac.png", replace


**# 5.2) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LAS INVERSIONES NETAS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brusco_negativo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\cambio brusco negativo\reg_int_inversiones_FE_brusco_negativo.xls", ctitle(lead `num' Inversiones) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brusco_negativo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_negativo ]*(1))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_negativo ]*(1)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_negativo]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brusco_negativo]*(1)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((1)^2) * (_se[c.var_capitalme_USD#c.brusco_negativo]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la dummy de cambio brusco en 1.")
	
graph export "$output\IRFs\reg introductoria\cambio brusco negativo\reg_int_inversiones_FE_brusco_negativo.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la dummy (var_capitalme_USD*brusco_negativo)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brusco_negativo acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brusco_negativo]    if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brusco_negativo] + 1.65*_se[c.var_capitalme_USD#c.brusco_negativo]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brusco_negativo] - 1.65*_se[c.var_capitalme_USD#c.brusco_negativo]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\cambio brusco negativo\reg_int_inversiones_FE_brusco_negativo_interac.png", replace


**# 6) INTERACTUANDO CON BRECHA DE TASAS DE CRÉDITOS

// llamamos la base de datos a nivel banco-tiempo con datos de cartera de los bancos y datos de hoja de balance

use "$input\base_reg_introductoria_activos.dta", clear

// agrupamos por tiempo (para usar los efectos fijos)

egen tiempo = group(Fecha_tri)

// mergeamos con la base de datos que contiene la brecha de tasas de créditos para cada trimestre

merge m:1 Fecha_tri using "$input\brecha_tasas_creditos.dta"

// recordemos que la brecha de tasas es el promedio ponderado de las tasas los créditos locales nuevos (tasa transformada a dólares por medio de la CIP) - el promedio ponderado de las tasas de los créditos externos nuevos

// media de la brecha de tasas: 6.352102 (esto es cuando se saca la media habiendo collapsado por trimestre)

**# 6.1) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LA CARTERA EN PESOS

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\brecha tasas de créditos\reg_int_FE_brecha_cred.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg introductoria\brecha tasas de créditos\reg_int_FE_brecha_cred.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la brecha de tasas (var_capitalme_USD*brecha_tasas_cred)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD c.var_capitalme_USD##c.brecha_tasas_cred acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brecha_tasas_cred]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brecha_tasas_cred] + 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_cred]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brecha_tasas_cred] - 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_cred]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\brecha tasas de créditos\reg_int_FE_brecha_cred_interac.png", replace


**# 6.2) VARIABLE DEPENDIENTE: CAMBIO ACUMULADO EN LAS INVERSIONES NETAS

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brecha_tasas_cred acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	outreg2 using "$output\regresiones\reg introductoria\brecha tasas de créditos\reg_int_inversiones_FE_brecha_cred.xls", ctitle(lead `num' Inversiones) append excel
	
}

// graficamos el IRF del efecto marginal del cambio en la cartera en dólares (var_capitalme_USD)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brecha_tasas_cred acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102))                     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) + 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD] + (_b[c.var_capitalme_USD#c.brecha_tasas_cred]*(6.352102)) - 1.65*sqrt((_se[c.var_capitalme_USD]^2) + (((6.352102)^2) * (_se[c.var_capitalme_USD#c.brecha_tasas_cred]^2)))  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Para el cálculo de estos efectos marginales se evalúa la brecha de tasas en su media: 6.352102")
	
graph export "$output\IRFs\reg introductoria\brecha tasas de créditos\reg_int_inversiones_FE_brecha_cred.png", replace

// graficamos el IRF de la interacción entre el cambio en la cartera en dólares y la brecha de tasas (var_capitalme_USD*brecha_tasas_cred)

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.

foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_Inversiones_USD c.var_capitalme_USD##c.brecha_tasas_cred acum_`num'_Activo_USD, a(banco tiempo) //vce(robust)
	
	replace b = _b[c.var_capitalme_USD#c.brecha_tasas_cred]     if _n == `num' +1
				replace u = _b[c.var_capitalme_USD#c.brecha_tasas_cred] + 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_cred]  if _n == `num'+1
				replace d = _b[c.var_capitalme_USD#c.brecha_tasas_cred] - 1.65*_se[c.var_capitalme_USD#c.brecha_tasas_cred]  if _n == `num'+1
				eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg introductoria\brecha tasas de créditos\reg_int_inversiones_FE_brecha_cred_interac.png", replace