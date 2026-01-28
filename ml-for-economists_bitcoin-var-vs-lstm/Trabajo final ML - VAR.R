# Librerias -----

library(vars)
library(urca)
library(ggplot2)
library(ggfortify)
library(gridExtra)
library(dplyr)
library(tidyr)
library(readxl)
library(quantmod )
library(tidyr)
library(stargazer)
library(xtable)
library(ggpubr)
library(quantmod)
library(ggplot2)
library(aTSA)
library(bayesforecast)
library(forecast)
library(VAR.etp)

# Datos ---------

rm(list = ls()) # Se limpia el entorno

# En este script estaremos trabajando con dos series de tiempo financieras: los precios de cierre historicos
# de las criptomonedas Bitcoin y Ethereum. Con estas dos series se construirá un modelo VAR con el objetivo de 
# medir la bondad de predicción del modelo respecto del precio de Bitcoin (el proposito de la serie de Ethereum
# es ser usada como información adicional en las predicciones de Bitcoin)

getSymbols("ETH-USD",src = "yahoo",periodicity = "weekly") # Traemos la serie de Ethereum con periodicidad semanal desde Yahoo Finance

serie1=`ETH-USD`[,4]["2018-01-01/2020-08-03"] # Se crea el Data frame que contiene los datos con los que se construirá el modelo. Estos 
# Abarcan de la semana del primero de enero de 2018 hasta la semana del 3 de agosto del 2020
# para un total de 139 observaciones

plot(serie1,main="ETH-USD",ylab="precio") # Graficamos la serie de Ethereum


getSymbols("BTC-USD",src = "yahoo",periodicity = "weekly") # Traemos la serie de Bitcoin con periodicidad semanal desde Yahoo Finance

serie2=`BTC-USD`[,4]["2018-01-01/2020-08-03"] # Se crea el Data frame que contiene los datos con los que se construirá el modelo. Abarca el mismo
# periodo de Ethereum y cuneta con el mismo número de observaciones

test_BTc=`BTC-USD`[,4]["2020-08-10/2020-12-21"] # Igualmente, se crea otro Data frame que contiene los datos empíricos para los siguientes 20 
# periodos de Bitcoin, de la semana del 10 de agosto de 2020 a la semana del 21 de diciembre del 
# mismo año. Estos datos se usarán para medir la capacidad de predicción del modelo

plot(serie2,main="BTC-USD",ylab="precio") # Graficamos la serie de Bitcoin


# Para trabajar con un modelo VAR necesitamos que las series sean estacionarias, por lo que gráficamos la autocorrelación y la 
# autocorrelación parcial de ambas series, lo cual nos da un indicativo de su estacionareidad

lags<-25
ggAcf(serie1,lag.max=lags,plot=T,lwd=2) + ggtitle("ACF del precio de cierre de ETH")
ggPacf(serie1,lag.max=lags,plot=T,lwd=2) + ggtitle("PACF del precio de cierre de ETH")


lags<-25
ggAcf(serie2,lag.max=lags,plot=T,lwd=2) + ggtitle("ACF del precio de cierre de BTC")
ggPacf(serie2,lag.max=lags,plot=T,lwd=2) + ggtitle("PACF del precio de cierre de BTC")

# Parecieran estar bien comportadas pero sin tanta claridad, por lo que hacemos pruebas de raiz unitaria
# para verificar si son estacionarias:

# serie1 - Ethereum

adf.trend<- ur.df(serie1, type="trend", selectlags = "AIC");plot(adf.trend)
summary(adf.trend) # La prueba tipo trend es suficiente para afirmar que la serie es estacionaria

# serie2 - Bitcoin

adf.trend<- ur.df(serie2, type="trend", selectlags = "AIC");plot(adf.trend)
summary(adf.trend) # Tomando un nivel de significancia del 10%, la prueba tipo trend es suficiente
# para afirmar que la serie es estacionaria

# Sabiendo que ambas series son estacionarias, pasamos a identificar qué modelo VAR es adecuado estimar


# Identificación del modelo ---------

y_t<-merge(serie1,serie2) # Unimos las series en un solo objeto

# Con la funcion VARselect se estiman modelos de distinto orden y calcula los criterios de información
# que indican cual de todos es óptimo


#SelecciÃ³n de rezagos para un VAR con tendencia e intercepto.
VARselect(y_t, lag.max=6,type = "both", season = NULL) # Dos criterios indican que se debe seleccionar un rezago, mientras
# que otros dos criterios indican que se deben seleccionar 5 rezagos.
# Elegimos 5 rezagos.

#SelecciÃ³n de rezagos para un VAR con sÃ³lo intercepto.
VARselect(y_t, lag.max=6,type = "const", season = NULL) # Dos criterios indican que se debe seleccionar un rezago, mientras
# que otros dos criterios indican que se deben seleccionar 5 rezagos.
# Elegimos 5 rezagos.

#SelecciÃ³n de rezagos para un VAR sin tÃ©rminos determinÃ­sticos.
VARselect(y_t, lag.max=6,type = "none", season = NULL) # Dos criterios indican que se debe seleccionar un rezago, mientras
# que otros dos criterios indican que se deben seleccionar 5 rezagos.
# Elegimos 5 rezagos.

# Ya habiendo seleccionado el número de rezagos para los tres casos anteriores, vamos a estimar cada tipo de modelo y a 
# decidir si el modelo adecuado cuenta con tendencia e intercecpto, solo con intercepto o sin terminos deterministicos

#VAR con tendencia e intercepto
V.tr = VAR(y_t, p=5, type="both", season=NULL)
summary(V.tr) # La tendencia es ligeramente significativa en solo una de las dos ecuaciones, mientras que la constante no 
# es significativa en ninguna.

#VAR con solo intercepto.
V.dr= VAR(y_t, p=5, type="const", season=NULL) 
summary(V.dr) # La constante no es significativa en ninguna de las ecuaciones

#VAR sin tÃ©rminos determinÃ­sticos.
V.no = VAR(y_t, p=5, type="none", season=NULL)  
summary(V.no)

# Dados los resultados anteriores, el modelo con el que se trabajará es un VAR de orden 5 sin términos determinísticos


# Validación de los supuestos --------

# Procedemos a verificar si el modelo cumple los supuestos. Recordemos que un modelo VAR debe cumplir 3 supuestos sobre los residuales:
# No autocorrelación, homocedasticidad y normalidad.

# No autocorrelación

P.75=serial.test(V.no, lags.pt =50, type = "PT.asymptotic");P.75 
P.30=serial.test(V.no, lags.pt = 30, type = "PT.asymptotic");P.30 
P.20=serial.test(V.no, lags.pt = 20, type = "PT.asymptotic");P.20  

# Las tres pruebas indican que se cumple el supuesto

#Homocedasticidad

vars::arch.test(V.tr, lags.multi = 30, multivariate.only = TRUE)
vars::arch.test(V.tr, lags.multi = 20, multivariate.only = TRUE) 
vars::arch.test(V.tr, lags.multi = 10, multivariate.only = TRUE) 

# Las tres pruebas indican que se cumple el supuesto

# Normalidad

normality.test(V.tr) # La prueba indica que no se cumple el supuesto

# Como no se cumple el supuesto de normalidad, es necesario utilizar bootstraping para simular la 
# distribución real de los residuales y así encontrar los verdaderos intervalos para las predicciones

Y = cbind(serie1,serie2)

For.Boot= VAR.BPR(data.frame(Y), 3, 20, nboot = 1000, type = "none", alpha = 0.95)

For.Boot # Ya se cuenta con los intervalos adecuados y con ello se puede pasar a hacer las predicciones.


# Predicción --------

p<-predict(V.no, n.ahead = 20, ci=0.95) # Generamos la prediccón 20 pasos adelante

p # Resultados de la predicción. Hay que recordar que solo nos interesan los valores predichos para Bitcoin

# Error cuadrático medio (ECM)--------

# Por medio del erro cuadrático medio mediremos la bondad de prediccón del modelo VAR

MSE_VAR_total=mean(( p$fcst$BTC.USD.Close[,1] - test_BTc)^2) # ECM para el modelo VAR

MSE_RNN_total=3394711.4720898177 # ECM para el modelo de redes neuronales (revisar script de Python)

indicador_total=MSE_VAR_total/MSE_RNN_total # Proporción de los errores de ambos modelos. Se ve que el
# error del VAR es casi 10 veces mayor que el de redes neuronales

# Sin embargo, la gráfica que compara la predicción de ambos modelos con los valores empíricos (ver script de Python)
#parece indicar que el modelo VAR se ajusta mejor en los primeros periodos. Por ello, calculamos un ECM parcial para los 
# primeros 10 periodos:

MSE_VAR_par=mean((p$fcst$BTC.USD.Close[1:10,1] - test_BTc[1:10])^2) # ECM del VAR para los primeros 10 periodos

MSE_RNN_par=611360.3370871014 # ECM del modelo de redes neuronales para los primeros 10 periodos

indicador_par=MSE_VAR_par/MSE_RNN_par # En efecto, se confirma que para los primeros 10 periodos el VAR tiene mayor bondad de predicción
