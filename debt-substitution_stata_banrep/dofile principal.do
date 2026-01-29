********************************************************************************
******************************* DOFILE PRINCIPAL *******************************
********************************************************************************

**# RUTA

// definimos la ruta a la carpeta donde se encuentran los dofiles

global ruta ="C:\Users\mrodrimu\OneDrive - Banco de la República\Escritorio\insularidad\dofiles"

**# PREPROCESAMIENTO

// Se cuenta con dos fuentes principales de información: el formato 341 (saldos de créditos comerciales con bancos locales) y la base de Endeudamiento Externo (EE) (flujos de crédito en moneda extranjera)

// el preprocesamiento de ambas fuentes de información, así como la generación de distintas bases de datos relevantes se realiza en el siguiente dofile:

do "$ruta\preprocesamiento bases 341 EE e insularidades"


**# GRÁFICAS Y DESCRIPTIVAS

// A partir de la base de datos en saldos generada, procedemos a realizar gráficas y descriptivas en el siguiente dofile:

do "$ruta\graficas y descriptivas saldos"


**# REGRESIÓN INTRODUCTORIA

// Primero generamos la base de datos que usaremos para las distintas versiones de la regresión introductoria, así como los demás datos que necesitamos como los datos de hoja de balance, la brecha de tasas, la posición propia y los cambios bruscos. Igualmente, generamos el histograma del cambio en el ratio EFE/(EFF+IMC) y la correlación de dicho ratio con la brecha de tasas. Todo esto lo hacemos en el siguiente dofile:

do "$ruta\datos regresion introductoria"

// Las regresiones, así como los IRF se realizan en el siguiente dofile:

do "$ruta\regresion introductoria"


**# REGRESIÓN 1 Y 1.1

// Primero generamos las bases de datos que vamos a necesitar para las distintas regresiones en el siguiente dofile:

do "$ruta\datos regresión 1"

// Las regresiones, así como los IRF se realizan en el siguiente dofile:

do "$ruta\regresión 1 y 1_1"


**# REGRESIÓN 2 Y 2.1

// Primero generamos las bases de datos que vamos a necesitar para las distintas regresiones en el siguiente dofile:

do "$ruta\datos regresión 2"

// Las regresiones, así como los IRF se realizan en el siguiente dofile:

do "$ruta\regresión 2 y 2_1"


**# ANÁLISIS DESCRIPTIVO CREDIT DEBT SUBSTITUTION

// La información y las gráficas descriptivas de las diapositivas "descriptivas sustitución" y "descriptivas sustitución 2" (además de otras gráficas) se generan en los siguientes dofiles:

do "$ruta\análisis descriptivo credit debt substitution"

do "$ruta\gráficas 2014_3"

do "$ruta\gráficas 2015_4"

do "$ruta\gráficas 2009_3"

do "$ruta\análisis ratio desembolsos sobre crédito total"