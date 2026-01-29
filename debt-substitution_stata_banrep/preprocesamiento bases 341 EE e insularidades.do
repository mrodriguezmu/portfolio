********************************************************************************
********************** PREPROCESAMIENTO 341, EE Y MERGE ************************
********************************************************************************

clear all

global input="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\input"


**# TRATAMIENTO 341

// partimos de la base 341 comercial original

use "$input\base341Com", clear

// conservamos solo los créditos con entidades tipo 1

keep if tipoentid == 1

// generamos variable de Fecha trimestral para cada crédito 

gen mes = trimestre*3
gen Fecha=""
replace Fecha=string(anio,"%04.0f") + "-" + string(mes,"%02.0f") + "-31" if mes == 3 | mes == 12
replace Fecha=string(anio,"%04.0f") + "-" + string(mes,"%02.0f") + "-30" if mes == 6 | mes == 9
gen Fecha_tri=date(Fecha,"YMD")
replace Fecha_tri=qofd(Fecha_tri)
format %tq Fecha_tri

// rename de la variable de capital en moneda extranjera y de la variable de año

rename capital_me capitalme

rename anio year

// modificamos el formato de la variable identif (nit de las empresas)

format %20.0f identif
tostring identif,  replace   format(%20.0f)
gen nit_len=strlen(identif)

// generamos la variable de credito en moneda local

gen capitalml = capital - capitalme

// generaremos una sub base a nivel firma-banco-tiempo que, para cada observación, contendrá una dummy que indicará que la firma i tuvo relación en dólares con el banco b en el trimestre t

preserve

// eliminamos todas las observaciones que no tuvieron relacion en moneda extranjera

drop if capitalme == 0

// collapsamos a nivel firma-banco-tiempo

collapse (rawsum) capital capitalme (mean) tasa [aweight = capital], by(Fecha_tri identif codentid )

// generamos la variable firma-banco

egen firma_banco = group(identif codentid)

sort firma_banco Fecha_tri

// generamos la dummy

gen relacion_i_b_t = 1

// conservamos solo las variables que nos interesan

keep codentid identif Fecha_tri relacion_i_b_t

// guardamos la base de datos

save "$input\relacion_i_b_t_me", replace // base que guarda la llave firma-banco-tiempo en la que existió relación (en dólares) de la firma i con el banco b en el trimestre t.

restore

// generaremos una sub base a nivel firma-banco-tiempo que, para cada observación, contendrá una dummy que indicará que la firma i tuvo relación en pesos con el banco b en el trimestre t

preserve

// eliminamos todas las observaciones que no tuvieron relación en moneda local

drop if capitalml == 0

// collapsamos a nivel firma-banco-tiempo

collapse (rawsum) capital capitalml (mean) tasa [aweight = capital], by(Fecha_tri identif codentid )

// generamos la variable firma-banco

egen firma_banco = group(identif codentid)

sort firma_banco Fecha_tri

// generamos la dummy

gen relacion_i_b_t = 1

// conservamos solo las variables que nos interesan

keep codentid identif Fecha_tri relacion_i_b_t

// guardamos la base de datos

save "$input\relacion_i_b_t_ml", replace // base que guarda la llave firma-banco-tiempo en la que existió relación (en pesos) de la firma i con el banco b en el trimestre t.

restore

// generaremos una sub base a nivel firma-banco-tiempo que, para cada observación, contendrá una dummy que indicará que la firma i tuvo relación (independiente de la moneda) con el banco b en el trimestre t

preserve

// eliminamos todas las observaciones que no tuvieron relación

drop if capital == 0

// collapsamos a nivel firma-banco-tiempo

collapse (rawsum) capital (mean) tasa [aweight = capital], by(Fecha_tri identif codentid )

// generamos la variable firma-banco

egen firma_banco = group(identif codentid)

sort firma_banco Fecha_tri

// generamos la dummy

gen relacion_i_b_t = 1

// conservamos solo las variables que nos interesan

keep codentid identif Fecha_tri relacion_i_b_t

// guardamos la base de datos

save "$input\relacion_i_b_t", replace // base que guarda la llave firma-banco-tiempo en la que existió relación (independiente de la moneda) de la firma i con el banco b en el trimestre t.

restore

// transformamos las fechas de inicio y vencimiento de los créditos

decode fechinic, gen(fechinic_1)

decode fechfin, gen(fechfin_1)


gen es_fechainic = regexm(fechinic_1, "^[0-9]+\-[0-9]+\-[0-9]+$")

gen es_fechafin = regexm(fechfin_1, "^[0-9]+\-[0-9]+\-[0-9]+$")


gen fechinic_2 = .

replace fechinic_2 = real(fechinic_1) if es_fechainic == 0

replace fechinic_2 = date(fechinic_1, "YMD") if es_fechainic == 1


gen fechfin_2 = .

replace fechfin_2 = real(fechfin_1) if es_fechafin == 0

replace fechfin_2 = date(fechfin_1, "YMD") if es_fechafin == 1


format fechinic_2 %td 

format fechfin_2 %td

// las fechas por alguna razón estan atrasadas 10 años en esta base de datos, asi que vamos a corregirlo sumandole el numero de dias aproximados de 10 años (3653)

replace fechinic_2 = fechinic_2 + 3653 if es_fechainic == 0

replace fechfin_2 = fechfin_2 + 3653 if es_fechafin == 0

drop es_fechainic es_fechafin fechinic_1 fechfin_1 fechinic fechfin

rename fechinic_2 fechinic // esta es la fecha de originación de los créditos

rename fechfin_2 fechfin // esta es la fecha de vencimiento de los créditos


// Ahora calculamos el plazo inicial del crédito (fecha de vencimiento - fecha de originación)

gen plazo_inic_dias = fechfin - fechinic // plazo en dias

// Y el plazo actual (fecha de vencimiento - fecha de corte)

gen Fecha_corte = date(Fecha, "YMD")
format Fecha_corte %td
drop Fecha
rename Fecha_corte Fecha

gen plazo_actu_dias = fechfin - Fecha // plazo en dias

// Generamos rangos de plazo 

gen rango_plazo_inic = ""

replace rango_plazo_inic = "30 o menos" if plazo_inic_dias <= 30
replace rango_plazo_inic = "31 a 60" if plazo_inic_dias > 30 & plazo_inic_dias <= 60
replace rango_plazo_inic = "61 a 90" if plazo_inic_dias > 60 & plazo_inic_dias <= 90
replace rango_plazo_inic = "91 a 180" if plazo_inic_dias > 90 & plazo_inic_dias <= 180
replace rango_plazo_inic = "181 a 360" if plazo_inic_dias > 180 & plazo_inic_dias <= 360
replace rango_plazo_inic = ">360" if plazo_inic_dias > 360


gen rango_plazo_actu = ""

replace rango_plazo_actu = "30 o menos" if plazo_actu_dias <= 30
replace rango_plazo_actu = "31 a 60" if plazo_actu_dias > 30 & plazo_actu_dias <= 60
replace rango_plazo_actu = "61 a 90" if plazo_actu_dias > 60 & plazo_actu_dias <= 90
replace rango_plazo_actu = "91 a 180" if plazo_actu_dias > 90 & plazo_actu_dias <= 180
replace rango_plazo_actu = "181 a 360" if plazo_actu_dias > 180 & plazo_actu_dias <= 360
replace rango_plazo_actu = ">360" if plazo_actu_dias > 360


// eliminamos observacines con fecha de vencimiento previas a nuestro periodo

drop if fechfin < date("2000-01-01", "YMD")

// eliminamos las observaciones de después de 2019

drop if Fecha_tri > yq(2019, 4)


// generamos una sub base solamente con las observaciones que no tienen fecha de originación 

preserve

drop if fechinic != .

// guardamos esta base

save "$input\base341_obs_sin_fechinic", replace // base que cuenta solo con las observacion de 341 que no tienen fecha de originación

restore


*** LO SIGUIENTE ES TOMAR LA PRIMERA TASA DE CADA CRÉDITO Y APLICARLA A TODAS SUS APARICIONES

// eliminamos las observaciones sin fecha de originacion ni de vencimiento (la enorme mayoria estan en 2002-2, 2002-3 y 2003-2)

drop if fechinic == .

// organizamos la base 

sort identif codentid fechinic fechfin plazo_inic_dias Fecha_tri 

// sacamos una sub base en la que solo se encuentre la primera aparicion de cada crédito

preserve

bysort identif codentid fechinic fechfin plazo_inic_dias: keep if _n == 1 // tomamos esta combinación de variables como identificador único de cada crédito

// ya con una unica observacion por crédito, dejamos solamente las variables que nos interesan (la combinacion anterior y la tasa)

keep identif codentid fechinic fechfin plazo_inic_dias tasa 

rename tasa tasa_originacion // capturamos la tasa de originacion (no para todos los créditos, ya que algunos se originaron antes)

tempfile tasas
save `tasas' 

restore

merge m:1 identif codentid fechinic fechfin plazo_inic_dias using `tasas' // con esto ya tenemos la tasa de originación para todas las observaciones

drop _merge


*** AHORA, DEJAREMOS SOLO LAS OBSERVACIONES DE LOS CRÉDITOS CON UN CAMBIO SUPERIOR A LA INFLACIÓN EN CADA TRIMESTRE


// collapsamos a nivel credito-tiempo (identif codentid fechinic fechfin plazo_inic_dias Fecha_tri)

collapse (lastnm) nomentid califica ciiu rango_plazo_actu rango_plazo_inic (rawsum) capital capitalme capitalml (mean) tasa tasa_originacion [aw = capital], by(identif codentid fechinic fechfin plazo_inic_dias Fecha_tri)

// generamos el panel

egen credito = group(identif codentid fechinic fechfin plazo_inic_dias)

xtset credito Fecha_tri 
tsreport  Fecha_tri,  p 

// generamos los lags del capital (total, en moneda local y en moneda extranjera)

bysort credito (Fecha_tri): gen lag_capital = L1.capital

bysort credito (Fecha_tri): gen lag_capitalme = L1.capitalme

bysort credito (Fecha_tri): gen lag_capitalml = L1.capitalml

replace lag_capital = 0 if lag_capital == .

replace lag_capitalme = 0 if lag_capitalme == .

replace lag_capitalml = 0 if lag_capitalml == .

// generamos la variación del capital

gen var_capital = capital - lag_capital

gen var_capitalme = capitalme - lag_capitalme

gen var_capitalml = capitalml - lag_capitalml

// generamos un marcador

gen marcador = 0

replace marcador = 1 if lag_capital == 0 & capital > 0 // marcamos los nuevos créditos

// generamos el cambio porcentual del capital

gen var_cap_porcen = ((capital - lag_capital)/lag_capital) *100

// mergeamos con la base de inflación trimestral para comparar el cambio porcentual con la inflación

merge m:1 Fecha_tri using "$input\inflacion_trimestral" // base que contiene la inflación para cada trimestre

drop if _merge == 2

drop _merge

// marcamos las observaciones que tuvieron un crecimiento porcentual superior a la inflacion de su respectivo trimestre

replace marcador = 1 if marcador == 0 & var_cap_porcen > inflacion & var_cap_porcen !=.

// Desmarcamos los créditos origniados antes de nuestro periodo

replace marcador = 0 if fechinic < date("2000-01-01", "YMD") 

// eliminamos variables que ya no necesitaremos

drop lag_capital credito var_cap_porcen inflacion

// guardamos la base de datos 

save "$input\base341_solo_tipo1_con plazo_dias", replace // en esta base tenemos todas las observaciones, pero estan marcadas aquellas que tuvieron cambio en su credito superior a la inflacion


**# BASE FORWARDS

// En esta sección utilizaremos los datos de forwards para, posteriormente, transformar las tasas de los créditos en moneda pesos a tasas en dólares, por medio de la CIP


** GENERAMOS LA BASE COLLAPSADA DIARIA POR LOS MISMOS RANGOS DE PLAZO DE LA 341

use "$input\Forwarsd_data_full", clear

// renombramos la variable de plazo de los forwards

rename plazo plazo_dias

// generamos rangos de plazo, igual a como hicimos con los créditos de la 341

gen plazo = "" 

replace  plazo = "30 o menos" if plazo_dias <= 30
replace  plazo = "31 a 60" if plazo_dias > 30 & plazo_dias <= 60
replace  plazo = "61 a 90" if plazo_dias > 60 & plazo_dias <= 90
replace  plazo = "91 a 180" if plazo_dias > 90 & plazo_dias <= 180
replace  plazo = "181 a 360" if plazo_dias > 180 & plazo_dias <= 360
replace  plazo = ">360" if plazo_dias > 360

// vamos a tomar como tasa forward la variable tasap_us. Sin embargo, hay trimestres para los cuales esta variable es 0 en todas las observaciones. Por ello, para estos casos vamos a tomar la tasac_us

drop if (tasap_us == 0 | tasap_us == .) & (tasac_us == 0 | tasac_us == .)

replace tasap_us = tasac_us if tasap_us == 0 & tasac_us != 0 & tasac_us != .

// eliminamos observaciones con montos negativos

drop if montous < 0

// collapsamos por plazo y por fecha de negociacion

collapse (mean) tasap_us [aw=montous], by(date plazo) 

// renombramos la variable de tasa y de fecha

rename tasap_us forward

rename date fechinic // le cambiamos el nombre para poder hacer el merge con la base de TRM

// guardamos esta base de datos

save "$input\forwards_tasas_&_plazos", replace // cuenta con los forwards por dia y los seis rangos de plazo


** GENERAMOS LA BASE COLLAPSADA DIARIA POR LOS RANGOS DE PLAZO AMPLIO

use "$input\Forwarsd_data_full", clear

// renombramos la variable de plazo de los forwards

rename plazo plazo_dias

// generamos los plazos amplios

gen plazo_amplio = ""

replace  plazo_amplio = "<=360" if plazo_dias <= 360
replace  plazo_amplio = ">360" if plazo_dias > 360

// vamos a tomar como tasa forward la variable tasap_us. Sin embargo, hay trimestres para los cuales esta variable es 0 en todas las observaciones. Por ello, para estos casos vamos a tomar la tasac_us

drop if (tasap_us == 0 | tasap_us == .) & (tasac_us == 0 | tasac_us == .)

replace tasap_us = tasac_us if tasap_us == 0 & tasac_us != 0 & tasac_us != .

// eliminamos observaciones con montos negativos

drop if montous < 0

// collapsamos por plazo y por fecha de negociacion

collapse (mean) tasap_us [aw=montous], by(date plazo_amplio) 

// renombramos la variable de tasa y de fecha

rename tasap_us forward_2 // el nombre es distinto al de las bases anteriores

rename date fechinic // le cambiamos el nombre para poder hacer el merge con la base de TRM

// guardamos esta base de datos

save "$input\forwards_tasas_&_plazos_amplios", replace  // cuenta con los forwards por dia y los dos rangos amplios 


** GENERAMOS LA BASE COLLAPSADA DIARIA SIN DISTINGUIR POR PLAZO

use "$input\Forwarsd_data_full", clear

// vamos a tomar como tasa forward la variable tasap_us. Sin embargo, hay trimestres para los cuales esta variable es 0 en todas las observaciones. Por ello, para estos casos vamos a tomar la tasac_us

drop if (tasap_us == 0 | tasap_us == .) & (tasac_us == 0 | tasac_us == .)

replace tasap_us = tasac_us if tasap_us == 0 & tasac_us != 0 & tasac_us != .

// eliminamos observaciones con montos negativos

drop if montous < 0

// collapsamos por fecha de negociacion

collapse (mean) tasap_us [aw=montous], by(date) 

// renombramos la variable de tasa y de fecha

rename tasap_us forward_3 // el nombre es distinto al de las bases anteriores

rename date fechinic // le cambiamos el nombre para poder hacer el merge con la base de TRM

// guardamos esta base de datos

save "$input\forwards_tasas_sin_plazos", replace  // cuenta con los forwards por dia pero sin distinguir por plazo


** GENERAMOS LA BASE COLLAPSADA SEMANAL POR LOS MISMOS RANGOS DE PLAZO DE LA 341

use "$input\Forwarsd_data_full", clear

// renombramos la variable de plazo de los forwards

rename plazo plazo_dias

gen plazo = "" 

replace  plazo = "30 o menos" if plazo_dias <= 30
replace  plazo = "31 a 60" if plazo_dias > 30 & plazo_dias <= 60
replace  plazo = "61 a 90" if plazo_dias > 60 & plazo_dias <= 90
replace  plazo = "91 a 180" if plazo_dias > 90 & plazo_dias <= 180
replace  plazo = "181 a 360" if plazo_dias > 180 & plazo_dias <= 360
replace  plazo = ">360" if plazo_dias > 360

// vamos a tomar como tasa forward la variable tasap_us. Sin embargo, hay trimestres para los cuales esta variable es 0 en todas las observaciones. Por ello, para estos casos vamos a tomar la tasac_us

drop if (tasap_us == 0 | tasap_us == .) & (tasac_us == 0 | tasac_us == .)

replace tasap_us = tasac_us if tasap_us == 0 & tasac_us != 0 & tasac_us != .

// generamos la variable de semana a partir de la fecha de negociacion

gen semana = wofd(date)

// eliminamos observaciones con montos negativos

drop if montous < 0

// collapsamos por plazo y por semana de negociacion

collapse (mean) tasap_us [aw=montous], by(semana plazo) 

// renombramos la variable de tasa

rename tasap_us forward_4 // el nombre es distinto al de las bases anteriores

// guardamos esta base de datos

save "$input\forwards_tasas_&_plazos_semana", replace // cuenta con los forwards por semana y los seis rangos de plazo


** GENERAMOS LA BASE COLLAPSADA SEMANAL SIN DISTINGUIR POR PLAZO

use "$input\Forwarsd_data_full", clear

// vamos a tomar como tasa forward la variable tasap_us. Sin embargo, hay trimestres para los cuales esta variable es 0 en todas las observaciones. Por ello, para estos casos vamos a tomar la tasac_us

drop if (tasap_us == 0 | tasap_us == .) & (tasac_us == 0 | tasac_us == .)

replace tasap_us = tasac_us if tasap_us == 0 & tasac_us != 0 & tasac_us != .

// generamos la variable de semana a partir de la fecha de negociacion

gen semana = wofd(date)

// eliminamos observaciones con montos negativos

drop if montous < 0

// collapsamos por semana de negociacion

collapse (mean) tasap_us [aw=montous], by(semana) 

// renombramos la variable de tasa

rename tasap_us forward_5 // el nombre es distinto al de las bases anteriores

// guardamos esta base de datos

save "$input\forwards_tasas_semana", replace  // cuenta con los forwards por semana pero sin distinguir por plazo


**# MERGE BASE 341 TRATADA CON DATOS DE FORWARDS

// llamamos la base 341 tratada

use "$input\base341_solo_tipo1_con plazo_dias", clear

// renombramos el plazo inicial

rename rango_plazo_inic plazo

// generamos el plazo amplio

gen plazo_amplio = ""

replace  plazo_amplio = "<=360" if plazo_inic_dias <= 360
replace  plazo_amplio = ">360" if plazo_inic_dias > 360

// generamos la variable de semana

gen semana = wofd(fechinic)

// mergeamos con la base de forwards diaria y con los seis plazos

merge m:1 fechinic plazo using "$input\forwards_tasas_&_plazos"

drop if _merge == 2

drop _merge

// mergeamos con la base de forwards diaria y con los dos plazos amplios

merge m:1 fechinic plazo_amplio using "$input\forwards_tasas_&_plazos_amplios"

drop if _merge == 2

drop _merge

replace forward = forward_2 if forward == . // recuperamos la tasa forward para algunas de las observaciones

gen marca_forward_preciso = 0
replace marca_forward_preciso = 1 if forward != . // con esto indicamos cuales son las observaciones para las cuales se pudo transformar la tasa usando los forwards más precisos

// mergeamos con la base de forwards semanal y con los seis plazos

merge m:1 semana plazo using "$input\forwards_tasas_&_plazos_semana"

drop if _merge == 2

drop _merge

replace forward = forward_4 if forward == . // recuperamos la tasa forward para algunas de las observaciones


// mergeamos con la base de forwards diaria sin plazo

merge m:1 fechinic using "$input\forwards_tasas_sin_plazos"

drop if _merge == 2

drop _merge

replace forward = forward_3 if forward == . // recuperamos la tasa forward para algunas de las observaciones


// mergeamos con la base de forwards semanal sin plazo

merge m:1 semana using "$input\forwards_tasas_semana"

drop if _merge == 2

drop _merge

replace forward = forward_5 if forward == . // recuperamos la tasa forward para algunas de las observaciones

// ya las que no mergean es porque no tienen fecha de originacion

// eliminamos las variables que no necesitamos

drop forward_2 forward_3 forward_4 forward_5

// mergamos con la base de TRM

merge m:1 fechinic using "$input\TRM_1991_2023.dta"

drop if _merge == 2

drop semana _merge


*** TRANSFORMAREMOS LAS TASAS DE LOS CREDITOS EN PESOS A TASAS EN DOLARES POR MEDIO DE LA CIP

// generamos una variable que se llame "tasas comparables"

* esta primera version la hacemos usando la version de la paridad cubierta con logaritmos

gen tasa_comparable = .

replace tasa_comparable = tasa_originacion if capitalme == capital // esta tasa comparable es igual a la tasa original de la 341 para aquellos creditos que se encuentran totalmente en dolares

// usamos la uip para transformar la tasa de los demas creditos (aquellos que estan en pesos, ya sea total o parcialmente)

// esto es i_USD = i_COP - LN(forward) + LN(TRM)

replace tasa_comparable = tasa_originacion - ln(forward) + ln(TRM) if capitalml != 0  // obtenemos las tasas en dolares


* ahora una version con la paridad cubierta sin logs

gen tasa_comparable_2 = .

replace tasa_comparable_2 = tasa_originacion if capitalme == capital // esta tasa comparable es igual a la tasa original de la 341 para aquellos creditos que se encuentran totalmente en dolares

// usamos la uip para transformar la tasa de los demas creditos (aquellos que estan en pesos, ya sea total o parcialmente)

// esto es i_USD = (1+i_COP)(TRM/forward) - 1

replace tasa_comparable_2 = ((TRM/forward)*(1+tasa_originacion))-1 if capitalml != 0  // obtenemos las tasas en dolares

// guardamos la base de datos

save "$input\base341_tasas_comparables", replace // base de datos que contiene los datos de la 341 ya tratados e incluye las tasas de interés transformadas para que sean directamente comparables las de créditos en pesos con las de créditos en dólares.



**# TRATAMIENTO ENDEUDAMIENTO EXTERNO (EE)

// partimos de la base original de EE (recordemos que esta base contiene flujos)

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

*** LO SIGUIENTE ES TOMAR LA PRIMERA TASA DE CADA CRÉDITO Y APLICARLA A TODAS SUS APARICIONES

// organizamos la base por crédito-fecha

sort prestamo Fecha_tri

// vamos a sacar una sub base en la que solo se encuentre la primera aparicion de cada crédito

preserve

bysort prestamo: keep if _n == 1

// ya con una unica observacion por crédito, dejamos solamente las variables que nos interesan (el crédito y la tasa)

keep prestamo tasa_final

rename tasa_final tasa_originacion_EE // capturamos la tasa de originacion (no para todos los creditos, ya que algunos se originaron antes)

tempfile tasas
save `tasas' 

restore

merge m:1 prestamo using `tasas' 

drop _merge


*** DEFINIMOS LAS INSULARIDADES (RECORDEMOS QUE ESTAS SON CON BASE EN LOS FLUJOS)

// insularidad 3

gen Insularidad_3 = 0

replace Insularidad_3 = 1 if (pais == "COLOMBIA" | pais == "CO0") & (tipoacreedor == 1 | tipoacreedor == 2 | tipoacreedor == 6 | tipoacreedor == 7 | tipoacreedor == 12)

// insularidad 4

gen Insularidad_4 = 0

replace Insularidad_4  = 1 if pais != "COLOMBIA" & pais != "CO0" & (tipoacreedor == 2 | tipoacreedor == 3 | tipoacreedor == 9)

// insularidad 5

gen Insularidad_5 = 0

replace Insularidad_5 = 1 if tipoacreedor != 1 & tipoacreedor != 6 & tipoacreedor != 7 & tipoacreedor != 12 & tipoacreedor != 2 & tipoacreedor != 3 & tipoacreedor != 9

// eliminamos las observaciones que no entran en ninguna de las insularidades

drop if Insularidad_3 == 0 & Insularidad_4 == 0 & Insularidad_5 == 0

// generamos el crédito local en moneda extranjera para las firmas de insularidad 3

gen capitalme_USD_EE = 0
replace capitalme_USD_EE = valor if Insularidad_3 == 1

// hacemos que la variable valor (crédito externo) sea cero para esas observaciones

replace valor = 0 if capitalme_USD_EE != 0

replace valor = 0 if Insularidad_3 == 1

gen tasa_origi_ins_3_EE = . 
replace tasa_origi_ins_3_EE = tasa_originacion_EE if Insularidad_3 == 1
replace tasa_originacion_EE = . if Insularidad_3 == 1
replace tasa_originacion_EE = . if Insularidad_3 == 1


// dejamos solo las observaciones que son desembolsos (recordemos que hay tanto desembolsos como amortizaciones)

keep if concepto == "Desembolsos" 

// modificamos el formato de la variable identif (nit de las empresas)

gen nit_len=strlen(identif)
tab nit_len
rename identif nit_original
gen identif=nit_original
replace identif=substr(identif,1,9) if nit_len==10

// collapsamos a nivel firma-tiempo 

// este primer collapse es para collapsar la tasa de las insularidades 4 y 5 (endeudamiento externo)

preserve

collapse (rawsum) valor (max) Insularidad_3 Insularidad_4 Insularidad_5 (lastnm) empresa (mean) tasa_originacion_EE [aweight = abs(valor)], by(identif Fecha_tri)

save "$input\Flujos_EE_sin_ins_3.dta", replace


restore

// cambiamos el nombre de las siguientes variables para que se distingan de los de la base que generamos con el anterior collapse

rename Insularidad_3 Insularidad_3_v2
rename Insularidad_4 Insularidad_4_v2
rename Insularidad_5 Insularidad_5_v2

// este segundo collapse es para collapsar la tasa de la insularidad 3 (credito local en moneda extranjera)

collapse (rawsum) capitalme_USD_EE (max) Insularidad_3 Insularidad_4 Insularidad_5 (lastnm) empresa (mean) tasa_origi_ins_3_EE [aweight = abs(capitalme_USD_EE)], by(identif Fecha_tri)

// mergeamos los dos collpase

merge 1:1 identif Fecha_tri using "$input\Flujos_EE_sin_ins_3.dta"

replace Insularidad_3 = Insularidad_3_v2 if Insularidad_3 == . | (Insularidad_3 < Insularidad_3_v2 & Insularidad_3_v2 != .)
replace Insularidad_4 = Insularidad_4_v2 if Insularidad_4 == . | (Insularidad_4 < Insularidad_4_v2 & Insularidad_4_v2 != .)
replace Insularidad_5 = Insularidad_5_v2 if Insularidad_5 == . | (Insularidad_5 < Insularidad_5_v2 & Insularidad_5_v2 != .)

drop Insularidad_3_v2 Insularidad_4_v2 Insularidad_5_v2 _merge

// reemplazamos los missing por 0

replace valor = 0 if valor == .
replace capitalme_USD_EE = 0 if capitalme_USD_EE == .

// guardamos la base de datos 

save "$input\Flujos_EE_para_nuevo_merge_14_03_2024.dta", replace // base que contiene los flujos de EE tratados



**# GENERACIÓN SALDOS DE EE

// vamos a generar los saldos de EE apartir de los flujos. Estos saldos los usaremos para: 1) realizar gráficas y déscriptivas; 2) generar las insularidades.

// partimos de la base original de flujos de EE

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

// generamos el valor absoluto de los flujos para poder usarlos como pesos para el promedio ponderado de las tasas

gen abs_valor = abs(valor)

// collapsamos para dejar una unica observacion por credito para cada trimestre

collapse (rawsum) valor (lastnm) identif instrumento plazo plazom acreedor proposito fechregistro tipo_tasa imcefe pais tipoacreedor (mean) tasa_final spread [aweight = abs_valor], by(Fecha_tri prestamo)

// vemos que luego de este collapse, el "valor" ya no representa un desembolso o amortizacion, sino el movimiento neto de ese credito para cada trimestre. Por ello le vamos a cambiar el nombre

rename valor valor_movimiento

// teniendo en cuenta que la base tiene algunos huecos en cuanto a los creditos (no aparecen en algunos trimestres entre el primer y ultimo trimestre que salen) vamos a generar dos variables, que indiquen el primer y ultimo trimestre de cada creditos

bysort prestamo (Fecha_tri): gen primer_trimestre = Fecha_tri if _n == 1

bysort prestamo (Fecha_tri): gen ultimo_trimestre = Fecha_tri if _n == _N

format primer_trimestre %tq
format ultimo_trimestre %tq

preserve

collapse (lastnm) primer_trimestre ultimo_trimestre, by(prestamo)

tempfile tri

save `tri'

restore

drop primer_trimestre ultimo_trimestre

merge m:1 prestamo using `tri' // con esto, ahora cada observaciones cuanta con una variable que indica su trimestre de originación y el trimestre de su última aparición

drop _merge

// guardemos esta base 

save "$input\Base_EE_mov_trimestral.dta", replace // base que cuenta con los movimientos de EE por cada firma en cada trimestre. Sin embargo, esta base cuenta con huecos (no son saldos)

*** GENERAREMOS UNA BASE CON LAS DIMENSIONES QUE DEBE TENER LA BASE SIN HUECOS

// volvemos a llamar la base que acabamos de generar

use "$input\Base_EE_mov_trimestral.dta", clear

// nos quedamos con una sola observacion por credito

bysort prestamo: keep if _n == 1  

// calculamos cuantos trimestre debe haber por credito

gen n_trimestres = (ultimo_trimestre - primer_trimestre) +1 

// expandimos la base de datos para que cada credito tenga el numero de trimestres correspondiente

expand n_trimestres 

// El problema de lo anterior es que todas las observaciones generadas por cada credito son duplicados de la primera observacion de ese credito. Vamos a indicar si la variable es un duplicado con una dummy

gen duplicado = 1

bysort prestamo: replace duplicado = 0 if _n == 1

// reemplazamos algunas variables por missing en los duplicados

replace valor_movimiento = . if duplicado == 1
replace tasa_final = . if duplicado == 1
replace spread = . if duplicado == 1

// finalmente cambiamos las fechas para que cada observacion tenga una unica llave prestamo-trimestre

bysort prestamo (Fecha_tri): replace Fecha_tri = primer_trimestre + _n - 1 if _n != 1

// guardamos esta base 

save "$input\Base_EE_cascaron_saldos.dta", replace // base "cascaron" de lo que será la base de saldos de la EE


// volvemos a llamar la basa que generamos originalmente

use "$input\Base_EE_mov_trimestral.dta", clear

// la mergeamos con el cascaron

merge 1:1 Fecha_tri prestamo using "$input\Base_EE_cascaron_saldos.dta"

drop _merge

// reemplazamos los missing por 0

replace valor_movimiento = 0 if valor_movimiento == .

// generamos los saldos

bysort prestamo (Fecha_tri): gen saldo = sum(valor_movimiento)

// Dado que tenemos algunos saldos negativos, vamos a eliminarlos

drop if saldo < 0

// eliminamos algunas de las variables que ya no necesitamos

drop n_trimestres duplicado

// organizamos la base por crédito-trimestre

sort prestamo Fecha_tri

// vamos a sacar una sub base en la que solo se encuentre la primera aparicion de cada crédito

preserve

bysort prestamo: keep if _n == 1

// ya con una unica observacion por crédito, dejamos solamente las variables que nos interesan (el crédito y la tasa)

keep prestamo tasa_final

rename tasa_final tasa_originacion_EE // capturamos la tasa de originacion (no para todos los creditos, ya que algunos se originaron antes)

tempfile tasas
save `tasas' 

restore

merge m:1 prestamo using `tasas' 

drop _merge

// guardamos la base 

save "$input\Base_saldos_EE.dta", replace // base que contiene los saldos de la EE

*** DEFINIMOS LAS INSULARIDADES (RECORDEMOS QUE ESTAS SON CON BASE EN LOS FLUJOS)

// llamamos la base de saldos

use "$input\Base_saldos_EE.dta", clear

// insularidad 3

gen Insularidad_3 = 0
replace Insularidad_3 = 1 if (pais == "COLOMBIA" | pais == "CO0") & (tipoacreedor == 1 | tipoacreedor == 2 | tipoacreedor == 6 | tipoacreedor == 7 | tipoacreedor == 12)

// insularidad 4

gen Insularidad_4 = 0
replace Insularidad_4  = 1 if pais != "COLOMBIA" & pais != "CO0" & (tipoacreedor == 2 | tipoacreedor == 3 | tipoacreedor == 9)

// insularidad 5

gen Insularidad_5 = 0
replace Insularidad_5 = 1 if tipoacreedor != 1 & tipoacreedor != 6 & tipoacreedor != 7 & tipoacreedor != 12 & tipoacreedor != 2 & tipoacreedor != 3 & tipoacreedor != 9

// eliminamos las observaciones que no entran en ninguna de las insularidades

drop if Insularidad_3 == 0 & Insularidad_4 == 0 & Insularidad_5 == 0

// generamos el crédito local en moneda extranjera para las firmas de insularidad 3

gen capitalme_USD_EE = 0
replace capitalme_USD_EE = saldo if Insularidad_3 == 1

// hacemos que la variable saldo (crédito externo) sea cero para esas observaciones

replace saldo = 0 if capitalme_USD_EE != 0 

replace saldo = 0 if Insularidad_3 == 1

gen tasa_origi_ins_3_EE = . 
replace tasa_origi_ins_3_EE = tasa_originacion_EE if Insularidad_3 == 1
replace tasa_originacion_EE = . if Insularidad_3 == 1
replace tasa_originacion_EE = . if Insularidad_3 == 1

// modificamos el formato de la variable identif (nit de las empresas)

gen nit_len=strlen(identif)
tab nit_len
rename identif nit_original
gen identif=nit_original
replace identif=substr(identif,1,9) if nit_len==10

// collapsamos a nivel firma-tiempo 

// este primer collapse es para collapsar la tasa de las insularidades 4 y 5 (endeudamiento externo)

preserve

collapse (rawsum) saldo (max) Insularidad_3 Insularidad_4 Insularidad_5 (mean) tasa_originacion_EE [aw = saldo], by(identif Fecha_tri)

save "$input\saldos_EE_sin_ins_3.dta", replace


restore

// cambiamos el nombre de las siguientes variables para que se distingan de los de la base que generamos con el anterior collapse

rename Insularidad_3 Insularidad_3_v2
rename Insularidad_4 Insularidad_4_v2
rename Insularidad_5 Insularidad_5_v2

// este segundo collapse es para collapsar la tasa de la insularidad 3 (credito local en moneda extranjera)

collapse (rawsum) capitalme_USD_EE (max) Insularidad_3 Insularidad_4 Insularidad_5 (mean) tasa_origi_ins_3_EE [aweight = abs(capitalme_USD_EE)], by(identif Fecha_tri)

// mergeamos los dos collapse

merge 1:1 identif Fecha_tri using "$input\saldos_EE_sin_ins_3.dta"

replace Insularidad_3 = Insularidad_3_v2 if Insularidad_3 == . | (Insularidad_3 < Insularidad_3_v2 & Insularidad_3_v2 != .)
replace Insularidad_4 = Insularidad_4_v2 if Insularidad_4 == . | (Insularidad_4 < Insularidad_4_v2 & Insularidad_4_v2 != .)
replace Insularidad_5 = Insularidad_5_v2 if Insularidad_5 == . | (Insularidad_5 < Insularidad_5_v2 & Insularidad_5_v2 != .)

drop Insularidad_3_v2 Insularidad_4_v2 Insularidad_5_v2 _merge

// reemplazamos los missing por cero

replace saldo = 0 if saldo == .
replace capitalme_USD_EE = 0 if capitalme_USD_EE == .

// guardamos esta base de datos

save "$input\saldos_EE_para_merge.dta", replace // base que contiene los saldos de EE tratados


**# MERGE 341 Y SALDOS EE

// vamos a mergear la base tratada de 341 con la de saldos de EE

// llamamos la base 341 tratada y con tasas comparables

use "$input\base341_tasas_comparables", clear

// appendeamos con la base de las observaciones sin que no tienen fecha de originación

append using "$input\base341_obs_sin_fechinic"

// cambiamos el nombre de la variable TRM que ya esta en la base

rename TRM TRM_fecha_origen

// mergeamos con la base de TRM trimestral

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

// generamos las variables de capital medidas en dólares

gen capital_USD = capital/TRM
gen capitalme_USD = capitalme/TRM
gen capitalml_USD = capitalml/TRM
gen var_capital_USD = var_capital/TRM
gen var_capitalme_USD = var_capitalme/TRM
gen var_capitalml_USD = var_capitalml/TRM

// transformamos las variables de capital para que este medidas en millones (de pesos o de dolares, según corresponda)

replace capital=capital/1000000
replace capitalme=capitalme/1000000
replace capitalml=capitalml/1000000
replace capital_USD=capital_USD/1000000
replace capitalme_USD=capitalme_USD/1000000
replace capitalml_USD=capitalml_USD/1000000
replace var_capital_USD=var_capital_USD/1000000
replace var_capitalme_USD=var_capitalme_USD/1000000
replace var_capitalml_USD=var_capitalml_USD/1000000

// collapsamos a nivel firma-banco-tiempo

collapse (rawsum) capital capitalme capitalml capital_USD capitalme_USD capitalml_USD var_capital_USD var_capitalme_USD var_capitalml_USD (max)  marca_forward_preciso (lastnm) fechinic fechfin plazo_inic_dias (mean) tasa tasa_originacion tasa_comparable tasa_comparable_2 [aweight = capital_USD], by(Fecha_tri identif codentid)

// mergeamos con la base de saldos EE tratados

merge m:1 Fecha_tri identif  using "$input\saldos_EE_para_merge.dta"

rename _merge mergeEE341

// reemplazamos los missing por cero

replace capitalme_USD = 0 if capitalme_USD == .
replace capitalml_USD = 0 if capitalml_USD == .
replace capital_USD = 0 if capital_USD == .
replace saldo = 0 if saldo == .
replace capitalme_USD_EE = 0 if capitalme_USD_EE == .

// guardamos la base

save "$input\Merge_341_EE_saldos_tasas_comparables_v0.dta", replace // base merge de 341 y saldos de EE. En esta base, las variables de la 341 están a nivel firma-banco-tiempo, mientras que las variables de la EE estan a nivel firma-tiempo


**# GENERACIÓN INSULARIDADES

// vamos a generar las insularidades definitivas a partir de la base que acabamos de generar

// partimos de la base del merge de 341 y saldos EE

use "$input\Merge_341_EE_saldos_tasas_comparables_v0.dta", clear

// agregamos el codigo 0 para las observaciones que no tienen banco

replace codentid=0 if codentid==.

// generar numero de relaciones bancarias locales (341) y endeudamiento usd (341)

gen unos_local=1 if codentid!=0
bys identif Fecha_tri: egen ralacion_bancaria=total(unos_local) 
bys identif Fecha_tri: gen credito_usd_locales=1 if capitalme_USD>0 & codentid!=0 & capitalme_USD !=.

// renombramos las insularidades 

rename Insularidad_3 Insularidad_3_EE
rename Insularidad_4 Insularidad_4_EE
rename Insularidad_5 Insularidad_5_EE

// hacemos un preserve

preserve

// collapsamos a nivel firma-tiempo solamente las variables necesarias para generar las insularidades.

collapse (mean) ralacion_bancaria credito_usd_locales (max) Insularidad_3_EE Insularidad_4_EE Insularidad_5_EE, by(identif Fecha_tri) 
**

// Guardamos esta base de datos

save "$input\variables_para_generar_insularidades_firma_tiempo.dta", replace // base de datos que contiene las variables necesarias para generar las insularidades

restore

// collapsamos todo a nivel firma-tiempo 

collapse (rawsum) capital_USD capitalme_USD (mean) capitalme_USD_EE saldo ralacion_bancaria credito_usd_locales (max) Insularidad_3_EE Insularidad_4_EE Insularidad_5_EE, by(identif Fecha_tri) 

// generamos el panel

egen firma_=group(identif)
xtset firma_ Fecha_tri

// generamos los lags (hasta tres periodos atrás) de las variables con las que generaremos las insularidades

forvalues x=0(1)3{
    di `x' 
	bys firma_ : gen lag_ralacion_bancaria_`x'=L`x'.ralacion_bancaria
	bys firma_ : gen lag_credito_usd_locales_`x'=L`x'.credito_usd_locales
	bys firma_ : gen lag_Insularidad_3_EE_`x'=L`x'.Insularidad_3_EE
	bys firma_ : gen lag_Insularidad_4_EE_`x'=L`x'.Insularidad_4_EE
	bys firma_ : gen lag_Insularidad_5_EE_`x'=L`x'.Insularidad_5_EE
}

drop firma_

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

rename Insularidad_1_341  Insularidad_1
rename Insularidad_2_341  Insularidad_2
rename Insularidad_3_EE_341 Insularidad_3
rename Insularidad_4_EE_completa Insularidad_4
rename Insularidad_5_EE_completa Insularidad_5

// generamos la insularidad definitiva

gen insularidad_definitiva=.
replace insularidad_definitiva=1 if Insularidad_1==1
replace insularidad_definitiva=2 if Insularidad_2 ==1
replace insularidad_definitiva=3 if Insularidad_3==1
replace insularidad_definitiva=4 if Insularidad_4==1
replace insularidad_definitiva=5 if Insularidad_5==1

tab insularidad_definitiva

// conservamos solamente las variables de insularidad, identif (nit de las firmas) y de trimestre

keep identif Fecha_tri Insularidad_1 Insularidad_2 Insularidad_3 Insularidad_3_EE_completa Insularidad_4 Insularidad_5 insularidad_definitiva

// guardamos la base 

save "$input\Insularidades_definitivo_EE_saldos.dta", replace // base de las insularidades de cada firma en cada trimestre


**# MERGE 341-SALDOS CON INSULARIDADES 

// ya con las insularidades, mergeamos la base del merge 341 y saldos de EE con las insularidades

// partimos de la base del merge de 341 y saldos EE

use "$input\Merge_341_EE_saldos_tasas_comparables_v0.dta", clear

// eliminamos las insularidades que ya tiene esta base 

drop Insularidad_3 Insularidad_4 Insularidad_5

// mergeamos con las insularidades 

merge m:1 Fecha_tri identif using "$input\Insularidades_definitivo_EE_saldos.dta" // recordemos que estas insularidades se generaron a partir de los saldos

*keep if _merge == 3

drop _merge

// guardamos la base

save "$input\Merge_341_EE_saldos_tasas_comparables.dta", replace // base merge de 341 tratada con saldos de EE tratada e insularidades. Esta base la usaremos para las gráficas y descriptivas introductorias


**# MERGE 341 Y FLUJOS DE EE

// finalmente mergearemos la base 341 tratada con la base de flujos EE tratada, dejando solamente los flujos de AMBAS fuentes de datos 

// llamamos la base 341 tratada y con tasas comparables

use "$input\base341_tasas_comparables", clear 

// dejamos solamente las observaciones para las cuales el cambio en el capital (saldo del crédito) fue mayor a la inflación en el trimestre correspondiente.

keep if marcador == 1

// cambiamos el nombre de la variable TRM de la base

rename TRM TRM_fecha_origen

// mergeamos con la base de TRM trimestral

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

// generamos las variables de capital medidas en dólares

gen capital_USD = capital/TRM
gen capitalme_USD = capitalme/TRM
gen capitalml_USD = capitalml/TRM
gen var_capital_USD = var_capital/TRM
gen var_capitalme_USD = var_capitalme/TRM
gen var_capitalml_USD = var_capitalml/TRM

// transformamos las variables de capital para que este medidas en millones (de pesos o de dolares, según corresponda)

replace capital=capital/1000000
replace capitalme=capitalme/1000000
replace capitalml=capitalml/1000000
replace capital_USD=capital_USD/1000000
replace capitalme_USD=capitalme_USD/1000000
replace capitalml_USD=capitalml_USD/1000000
replace var_capital_USD=var_capital_USD/1000000
replace var_capitalme_USD=var_capitalme_USD/1000000
replace var_capitalml_USD=var_capitalml_USD/1000000

// collapsamos a nivel firma-banco-tiempo

collapse (rawsum) capital capitalme capitalml capital_USD capitalme_USD capitalml_USD var_capital_USD var_capitalme_USD var_capitalml_USD (max)  marca_forward_preciso (mean) tasa tasa_originacion tasa_comparable tasa_comparable_2 [aweight = capital_USD], by(Fecha_tri identif codentid)

// mergeamos con la base de flujos de EE tratada

merge m:1 Fecha_tri identif  using "$input\Flujos_EE_para_nuevo_merge_14_03_2024.dta"

rename _merge mergeEE341

// reemplazamos los missing por cero

replace capitalme_USD = 0 if capitalme_USD == .
replace capitalml_USD = 0 if capitalml_USD == .
replace capital_USD = 0 if capital_USD == .
replace valor = 0 if valor == .
replace capitalme_USD_EE = 0 if capitalme_USD_EE == .

// eliminamos las variables de insularidad de esta base

drop Insularidad_3 Insularidad_4 Insularidad_5

// mergeamos con las insularidades (generadas a partir de los saldos)

merge m:1 Fecha_tri identif using "$input\Insularidades_definitivo_EE_saldos.dta"

// conservamos solo las observaciones que mergean

keep if _merge == 3

drop _merge

// guardamos la base de datos

save "$input\Merge_341_EE_tasas_comparables.dta", replace // base merge de 341 tratada con flujos de EE tratada e insularidades. Cuenta con las variables de flujos de 341 a nivel firma-banco-tiempo y con las variables de flujos de EE a nivel firma-tiempo. Esta base será el punto de partida para todas las regresiones.


**# GENERACIÓN MERGE 341 (NUEVOS CRÉDITOS) Y DESEMBOLSOS DE EE

// generaremos una base de datos que contenga solamente los nuevos créditos de la base 341 y los desembolsos de la base de Endeudamiento Externo. De esta forma, esta base de datos solo contará con las siguientes variables: identif (nit de la firma), Fecha_tri (trimestre y año), 

// llamamos la 341 de créditos comerciales completa

use "$input\base341Com", clear

// conservamos solo los créditos con entidades tipo 1

keep if tipoentid == 1

keep if nuevo_credito == 1

// generamos variable de Fecha trimestral para cada crédito 

gen mes = trimestre*3
gen Fecha=""
replace Fecha=string(anio,"%04.0f") + "-" + string(mes,"%02.0f") + "-31" if mes == 3 | mes == 12
replace Fecha=string(anio,"%04.0f") + "-" + string(mes,"%02.0f") + "-30" if mes == 6 | mes == 9
gen Fecha_tri=date(Fecha,"YMD")
replace Fecha_tri=qofd(Fecha_tri)
format %tq Fecha_tri

// rename de la variable de capital en moneda extranjera y de la variable de año

rename capital_me capitalme

rename anio year

// modificamos el formato de la variable identif (nit de las empresas)

format %20.0f identif
tostring identif,  replace   format(%20.0f)
gen nit_len=strlen(identif)

// generamos la variable de credito en moneda local

gen capitalml = capital - capitalme

// por alguna razon hay nuevos creditos iguales a 0, por lo que vamos a eliminar esas observaciones

drop if capital == 0

// mergeamos con la base de TRM trimestral

merge m:1 Fecha_tri using "$input\TRM_tri.dta"

// generamos las variables de capital medidas en dólares

gen capital_USD = capital/TRM
gen capitalme_USD = capitalme/TRM
gen capitalml_USD = capitalml/TRM

// transformamos las variables de capital para que este medida en millones (de pesos o de dolares, según corresponda)

replace capital_USD=capital_USD/1000000
replace capitalme_USD=capitalme_USD/1000000
replace capitalml_USD=capitalml_USD/1000000

keep if _merge == 3

// colapsamos a nivel firma banco tiempo (solamente las variables medidas en millones de dolares )

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri identif codentid)

// guardamos esta base 

save "$input\base341_nuevos_creditos_USD.dta", replace // base que contiene todos los nuevos creditos de la 341 a nivel firma banco tiempo, medidos en millones de dolares 

// collapsamos a nivel firma tiempo

collapse (rawsum) capital_USD capitalme_USD capitalml_USD, by(Fecha_tri identif)

// guardamos 

save "$input\base341_nuevos_creditos_USD_firma_tiempo.dta", replace // base que contiene todos los nuevos creditos de la 341 a nivel firma tiempo, medidos en millones de dolares 

// ahora llamamos la base del merge de la 341 y la EE (en flujos). De esta base nos quedaremos solo con los desembolsos de crédito externo

use "$input\Merge_341_EE_tasas_comparables.dta", clear

// nos quedamos solamente con nit, banco, desembolso y trimestre 

keep identif codentid Fecha_tri valor

// collapsamos a nivel firma tiempo

collapse (lastnm) valor, by(Fecha_tri identif) // ya con esto nos quedamos con los desembolsos de credito externo en millones de dolares a nivel firma tiempo

// eliminamos los que son 0

drop if valor == 0

// mergamos con la de nuevo credito domestico

merge 1:1 identif Fecha_tri using "$input\base341_nuevos_creditos_USD_firma_tiempo.dta"

// eliminamos variable _merge 

drop _merge

// eliminamos valores posteriores a 2019-4

drop if Fecha_tri > yq(2019,4)

// reemplazamos missings por 0

replace valor = 0 if valor == .
replace capital_USD = 0 if capital_USD == .
replace capitalme_USD = 0 if capitalme_USD == .
replace capitalml_USD = 0 if capitalml_USD == .

// guardamos esta base de datos 

save "$input\nuevos_creditos_341_&_desembolsos_EE.dta", replace  // base que contiene los nuevos creditos domesticos y los desembolsos de credito externo, medidos en millones de dólares a nivel firma-tiempo