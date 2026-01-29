********************************************************************************
****************************** REGRESIÓN 2 Y 2.1 *******************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"

global output="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\output"

**# 1) REGRESIONES EN FORMA BÁSICA

**# 1.1) REGRESIÓN 2: VARIABLE DEPENDIENTE: CRÉDITO LOCAL EN DÓLARES

// llamamos la base correspondiente

use "$input\base_reg_2_20_08_2024_pre_reg.dta", clear

// winsoreamos las variables X, numerador y denominador 

winsor2 numerador denominador X, c(1 99) suffix(_w) 

// generamos la variable firma-tiempo para los efectos fijos 

egen firma_tiempo = group(identif Fecha_tri)

**# 1.1.1) SIN WINSOR

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD X, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\forma basica\reg_2_FE_firma_tiempo_X.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD X, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X]                     if _n == `num' + 1
	replace u = _b[X] + 1.65* _se[X]  if _n == `num' + 1
	replace d = _b[X] - 1.65* _se[X]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2\forma basica\reg_2_FE_firma_tiempo_X.png", replace


**# 1.1.2) CON WINSOR

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD X_w, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\forma basica\reg_2_FE_firma_tiempo_X_winsor.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD X_w, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X_w]                     if _n == `num' + 1
	replace u = _b[X_w] + 1.65* _se[X_w]  if _n == `num' + 1
	replace d = _b[X_w] - 1.65* _se[X_w]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Variable X winsoreada al 99.")
	
graph export "$output\IRFs\reg 2\forma basica\reg_2_FE_firma_tiempo_X_winsor.png", replace


**# 1.2) REGRESIÓN 2: VARIABLE DEPENDIENTE: CRÉDITO LOCAL EN PESOS

// llamamos la base correspondiente

use "$input\base_reg_2_20_08_2024_mon_local_pre_reg.dta", clear

// winsoreamos las variables X, numerador y denominador 

winsor2 numerador denominador X, c(1 99) suffix(_w) 

// generamos la variable firma-tiempo para los efectos fijos 

egen firma_tiempo = group(identif Fecha_tri)

**# 1.2.1) SIN WINSOR

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD X, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\forma basica\reg_2_FE_firma_tiempo_mon_local_X.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD X, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X]                     if _n == `num' + 1
	replace u = _b[X] + 1.65* _se[X]  if _n == `num' + 1
	replace d = _b[X] - 1.65* _se[X]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2\forma basica\reg_2_FE_firma_tiempo_mon_local_X.png", replace


**# 1.2.2) CON WINSOR

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD X_w, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\forma basica\reg_2_FE_firma_tiempo_mon_local_X_w.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD X_w, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X_w]                     if _n == `num' + 1
	replace u = _b[X_w] + 1.65* _se[X_w]  if _n == `num' + 1
	replace d = _b[X_w] - 1.65* _se[X_w]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Variable X winsoreada al 99.")
	
graph export "$output\IRFs\reg 2\forma basica\reg_2_FE_firma_tiempo_mon_local_X_w.png", replace


**# 1.3) REGRESIÓN 2: VARIABLE DEPENDIENTE: CRÉDITO LOCAL TOTAL

// llamamos la base correspondiente

use "$input\base_reg_2_20_08_2024_cred_total_pre_reg.dta", clear

// winsoreamos las variables X, numerador y denominador 

winsor2 numerador denominador X, c(1 99) suffix(_w) 

// generamos la variable firma-tiempo para los efectos fijos 

egen firma_tiempo = group(identif Fecha_tri)

**# 1.3.1) SIN WINSOR

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD X, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\forma basica\reg_2_FE_firma_tiempo_cred_total_X.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD X, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X]                     if _n == `num' + 1
	replace u = _b[X] + 1.65* _se[X]  if _n == `num' + 1
	replace d = _b[X] - 1.65* _se[X]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2\forma basica\reg_2_FE_firma_tiempo_cred_total_X.png", replace


**# 1.3.2) CON WINSOR

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD X_w, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\forma basica\reg_2_FE_firma_tiempo_cred_total_X_w.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD X_w, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X_w]                     if _n == `num' + 1
	replace u = _b[X_w] + 1.65* _se[X_w]  if _n == `num' + 1
	replace d = _b[X_w] - 1.65* _se[X_w]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Variable X winsoreada al 99.")
	
graph export "$output\IRFs\reg 2\forma basica\reg_2_FE_firma_tiempo_cred_total_X_w.png", replace


**# 2) REGRESIONES CON DENOMINADOR REDUCIDO

**# 2.1) REGRESIÓN 2: VARIABLE DEPENDIENTE: CRÉDITO LOCAL EN DÓLARES

// llamamos la base correspondiente

use "$input\base_reg_2_20_08_2024_denom_reduc_pre_reg.dta", clear

// winsoreamos las variables X, numerador y denominador 

winsor2 numerador denominador X, c(1 99) suffix(_w) 

// generamos la variable firma-tiempo para los efectos fijos 

egen firma_tiempo = group(identif Fecha_tri)

**# 2.1.1) SIN WINSOR

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD X, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\denom reducido\reg_2_FE_firma_tiempo_d_reduc_X.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD X, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X]                     if _n == `num' + 1
	replace u = _b[X] + 1.65* _se[X]  if _n == `num' + 1
	replace d = _b[X] - 1.65* _se[X]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2\denom reducido\reg_2_FE_firma_tiempo_d_reduc_X.png", replace


**# 2.1.2) CON WINSOR

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD X_w, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\denom reducido\reg_2_FE_firma_tiempo_d_reduc_X_winsor.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD X_w, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X_w]                     if _n == `num' + 1
	replace u = _b[X_w] + 1.65* _se[X_w]  if _n == `num' + 1
	replace d = _b[X_w] - 1.65* _se[X_w]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Variable X winsoreada al 99.")
	
graph export "$output\IRFs\reg 2\denom reducido\reg_2_FE_firma_tiempo_d_reduc_X_winsor.png", replace


**# 2.2) REGRESIÓN 2: VARIABLE DEPENDIENTE: CRÉDITO LOCAL EN PESOS

// llamamos la base correspondiente

use "$input\base_reg_2_20_08_2024_mon_local_denom_reduc_pre_reg.dta", clear

// winsoreamos las variables X, numerador y denominador 

winsor2 numerador denominador X, c(1 99) suffix(_w) 

// generamos la variable firma-tiempo para los efectos fijos 

egen firma_tiempo = group(identif Fecha_tri)

**# 2.2.1) SIN WINSOR

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD X, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\denom reducido\reg_2_FE_firma_tiempo_mon_local_d_red_X.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD X, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X]                     if _n == `num' + 1
	replace u = _b[X] + 1.65* _se[X]  if _n == `num' + 1
	replace d = _b[X] - 1.65* _se[X]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2\denom reducido\reg_2_FE_firma_tiempo_mon_local_d_red_X.png", replace

**# 2.2.2) CON WINSOR

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD X_w, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\denom reducido\reg_2_FE_firma_tiempo_mon_local_d_red_X_w.xls", ctitle(lead `num' capitalml_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD X_w, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X_w]                     if _n == `num' + 1
	replace u = _b[X_w] + 1.65* _se[X_w]  if _n == `num' + 1
	replace d = _b[X_w] - 1.65* _se[X_w]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Variable X winsoreada al 99.")
	
graph export "$output\IRFs\reg 2\denom reducido\reg_2_FE_firma_tiempo_mon_local_d_red_X_w.png", replace


**# 2.3) REGRESIÓN 2: VARIABLE DEPENDIENTE: CRÉDITO LOCAL TOTAL

// llamamos la base correspondiente

use "$input\base_reg_2_20_08_2024_cred_total_denom_reduc_pre_reg.dta", clear

// winsoreamos las variables X, numerador y denominador 

winsor2 numerador denominador X, c(1 99) suffix(_w) 

// generamos la variable firma-tiempo para los efectos fijos 

egen firma_tiempo = group(identif Fecha_tri)

**# 2.3.1) SIN WINSOR

// realizamos la regresión

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD X, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\denom reducido\reg_2_FE_firma_tiempo_cred_total_d_red_X.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD X, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X]                     if _n == `num' + 1
	replace u = _b[X] + 1.65* _se[X]  if _n == `num' + 1
	replace d = _b[X] - 1.65* _se[X]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2\denom reducido\reg_2_FE_firma_tiempo_cred_total_d_red_X.png", replace


**# 2.3.2) CON WINSOR

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capital_USD X_w, a(firma_tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2\denom reducido\reg_2_FE_firma_tiempo_cred_total_d_red_X_w.xls", ctitle(lead `num' capital_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable X

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capital_USD X_w, a(firma_tiempo) // vce(robust)
	
	replace b = _b[X_w]                     if _n == `num' + 1
	replace u = _b[X_w] + 1.65* _se[X_w]  if _n == `num' + 1
	replace d = _b[X_w] - 1.65* _se[X_w]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%." "Variable X winsoreada al 99.")
	
graph export "$output\IRFs\reg 2\denom reducido\reg_2_FE_firma_tiempo_cred_total_d_red_X_w.png", replace


**# 3) REGRESIÓN 2.1

**# 3.1) REGRESIÓN 2.1: VARIABLE DEPENDIENTE: CARTERA EN DÓLARES 

// llamamos la base correspondiente 

use "$input\base_reg_2_1.dta", clear

// generamos la variable de tiempo para los efectos fijos

gen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalme_USD numerador, a(banco tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2.1\reg_2_1_FE_banco_tiempo.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la varible numerador

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalme_USD numerador, a(banco tiempo) // vce(robust)
	
	replace b = _b[numerador]                     if _n == `num' + 1
	replace u = _b[numerador] + 1.65* _se[numerador]  if _n == `num' + 1
	replace d = _b[numerador] - 1.65* _se[numerador]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2.1\reg_2_1_FE_banco_tiempo.png", replace

**# 3.2) REGRESIÓN 2.1: VARIABLE DEPENDIENTE: CARTERA EN PESOS

// llamamos la base correspondiente 

use "$input\base_reg_2_1_mon_local.dta", clear

// generamos la variable de tiempo para los efectos fijos

gen tiempo = group(Fecha_tri)

// realizamos la regresión 

foreach num in 0 1 2 3 {
    
	reghdfe acum_`num'_capitalml_USD numerador denominador, a(banco tiempo) // vce(robust)
	
	outreg2 using "$output\regresiones\reg 2.1\reg_2_1_FE_banco_tiempo_mon_local.xls", ctitle(lead `num' capitalme_USD) append excel
	
}

// graficamos el IRF del efecto marginal de la variable numerador

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD numerador denominador, a(banco tiempo) // vce(robust)
	
	replace b = _b[numerador]                     if _n == `num' + 1
	replace u = _b[numerador] + 1.65* _se[numerador]  if _n == `num' + 1
	replace d = _b[numerador] - 1.65* _se[numerador]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2.1\reg_2_1_FE_banco_tiempo_mon_local_num.png", replace

// graficamos el IRF del efecto marginal de la variable denominador

eststo clear
cap drop b u d Years Zero
gen Years = _n -1  if _n<=4
gen Zero =  0    if _n<=4
gen b=.
gen u=.
gen d=.


foreach num in 0 1 2 3 {
    
	quiet reghdfe acum_`num'_capitalml_USD numerador denominador, a(banco tiempo) // vce(robust)
	
	replace b = _b[denominador]                     if _n == `num' + 1
	replace u = _b[denominador] + 1.65* _se[denominador]  if _n == `num' + 1
	replace d = _b[denominador] - 1.65* _se[denominador]  if _n == `num' + 1
	eststo 
	
}

twoway (rarea u d  Years, fcolor(gs13) lcolor(gs13) lw(none) lpattern(solid)) ///
(line b Years, lcolor(blue) lpattern(solid) lwidth(thick)) (line Zero Years, 		lcolor(black)), legend(off)  ytitle("Millones de USD", size(medsmall)) xtitle(			"Trimestre", size(medsmall) ) xscale(range(3)) graphregion(color(white)) 			plotregion(color(white)) xlabel(0 1 2 3) note("Intervalo de confianza al 10%.")
	
graph export "$output\IRFs\reg 2.1\reg_2_1_FE_banco_tiempo_mon_local_denom.png", replace