#-------------------------------------------------------#
####          Trabajo econometria espacial           ####
#--------------Arlet Valeria Martínez Vaca--------------#
#--------------Martin--------------#
#--------------Nicolas Pineda--------------#

#### Limpiar entorno ####

remove(list = ls())

#======================================================#
####             Paquetes y librerias               ####
#======================================================#

library(spdep)
library(sf)
library(sp)
library(raster)
library(tidyverse)
library(dplyr)
library(stargazer)
library(readxl)
library(sfdep)
library(spatialreg)
library(tmap)
library(RColorBrewer)
library(classInt)
library(lmtest)
library(nortest)
library(car)

#======================================================#
####            Importar bases de datos             ####
#======================================================#

mapa.upz = st_read(dsn = "G:/Mi unidad/Economia/8 Semestre/Econometria Espacial/Trabajo Espacial/Base trabajo final/base_final.shp")

#Se hizo un proceso aparte para unir las variables y generar el shapefile

#======================================================#
####             Analisis de variables              ####
#======================================================#

# sd, quantile, jenks

x11()
tm_shape(mapa.upz) +
  tm_fill("PET__",title="Población en edad de trabajar", n=7, style="jenks", 
          palette = "Greens") + 
  tm_borders() +
  tm_layout(legend.outside = TRUE, legend.outside.position = "right")


x11()
tm_shape(mapa.upz) +
  tm_fill("primr",title="Maxima educación fue primaria", n=7, style="jenks", 
          palette = "Greens") + 
  tm_borders() +
  tm_layout(legend.outside = TRUE, legend.outside.position = "right")

x11()
tm_shape(mapa.upz) +
  tm_fill("scndr",title="Maxima educación fue secundaria", n=7, style="jenks", 
          palette = "Greens") + 
  tm_borders() +
  tm_layout(legend.outside = TRUE, legend.outside.position = "right")

x11()
tm_shape(mapa.upz) +
  tm_fill("tcnlg",title="Maxima educación fue secundaria", n=7, style="jenks", 
          palette = "Greens") + 
  tm_borders() +
  tm_layout(legend.outside = TRUE, legend.outside.position = "right")


#======================================================#
####                   Modelo OLS                   ####
#======================================================#

# Especificación de la fórmula del modelo

# fm = fr___ ~ ndst_1_+ndsi_1_+Dnsdd_P+tsdlf+tdtt__+Ingrs+snnvl+prscl+
#  primr+scndr+tecnc+tcnlg+unvrstc+unvrsti+p_nc_

# fm = fr___ ~ tsdlf + tdtt__

# fm = fr___ ~ primr+scndr+tecnc+tcnlg+unvrstc+unvrsti+tsdlf

fm = tscpc ~ PET__+primr+scndr+tecnc+tcnlg+unvrstc+
  unvrsti+tdtt__+ndst_1_+ndsi_1_

##### Modelo OLS ####

ols <- lm(fm, data = mapa.upz)
summary(ols)
AIC(ols)

##### Pruebas ####

vif(ols) # prueba que dice si hay multicolinealidad si los valores son mayores a 10
resettest(ols) # Rampsey reset H0: no hay problema de especificación
shapiro.test(ols$residual) # Prueba de normalidad
ad.test(ols$residual) # los errores son normales
qqPlot(ols$residual, pch = 16, col = c("#178A56AA"), col.lines = 6, cex = 1.5, main = "NORMAL Q-Q PLOT", id = F)
bptest(ols)

mapa.upz$lm_res = ols$residual #nueva variable de residuales

##### Mapa residuales ####

X11()
tm_shape(mapa.upz) +
  tm_fill("lm_res",title="Residuales Modelo OLS", n=5, style="jenks", 
          palette = "-RdBu") + 
  tm_borders() +
  tm_layout(legend.outside = TRUE, legend.outside.position = "right")

#===================================================================#
#####   Prueba de autocorrelación espacial sobre los residuales  ####
#===================================================================#

list.queen<-poly2nb(mapa.upz,row.names = mapa.upz$Nom_UPZ, queen=TRUE)
W<-nb2listw(list.queen, style="W", zero.policy=TRUE)

moran.test(ols$residual, listw=W,
           randomisation = FALSE,
           alternative = "two.sided")

# Hay autocorrelación espacial p-value < 0.05 

moran.plot(ols$residual, listw=W, labels=FALSE,
           quiet=TRUE,
           ylab="Residuales OLS espacialmente rezagados",
           xlab="Residuales OLS")

#======================================================#
####              Modelos Espaciales                ####
#======================================================#

##### Modelo SAR/SLM ####

sar.upz<-lagsarlm(fm,data=mapa.upz, W, tol.solve=1.0e-30)
summary(sar.upz,Nagelkerke=T)
sar.R2 = 1- var(sar.upz$residuals)/var(sar.upz$y)
sar.R2
AIC(sar.upz)
moran.test(sar.upz$residual, listw=W, randomisation = FALSE,
           alternative = "two.sided")
# no hay autocorrelación espacial p-valor no se rechaza
moran.plot(sar.upz$residual, listw=W, labels=FALSE, quiet=TRUE,
           ylab="Residuales SAR espacialmente rezagados", xlab="Residuales SAR")

##### Modelo SEM ####

upz.sem<-errorsarlm(formula= fm, data=mapa.upz, listw=W, tol.solve=1.0e-30)
summary(upz.sem, Naguelkerke=T)
AIC(upz.sem)
sem.R2 = 1- var(upz.sem$residuals)/var(upz.sem$y)
sem.R2
moran.test(upz.sem$residual, listw=W, randomisation = TRUE, alternative = "two.sided")
moran.plot(upz.sem$residual, listw=W, labels=FALSE, quiet=TRUE,
           ylab="Residuales SEM espacialmente rezagados", xlab="Residuales SEM")

##### Modelo SARAR ####

upz.sarar<-sacsarlm(formula= fm, data=mapa.upz, listw=W,tol.solve=1.0e-30)
summary(upz.sarar, Naguelkerke=T)
AIC(upz.sarar)
sarar.R2 = 1- var(upz.sarar$residuals)/var(upz.sarar$y)
sarar.R2
moran.test(upz.sarar$residual, listw=W, randomisation = TRUE, alternative = "two.sided")
moran.plot(upz.sarar$residual, listw=W, labels=FALSE, quiet=TRUE,
           ylab="Residuales SARAR espacialmente rezagados", xlab="Residuales SARAR")

##### Modelo SDM ####

upz.sdm<-lagsarlm(fm,data=mapa.upz, W, type="mixed",tol.solve=1.0e-30)
summary(upz.sdm)
AIC(upz.sdm)
sdm.R2 = 1- var(upz.sdm$residuals)/var(upz.sdm$y)
sdm.R2
moran.test(upz.sdm$residual, listw=W, randomisation = TRUE, alternative = "two.sided")
moran.plot(upz.sdm$residual, listw=W, labels=FALSE, quiet=TRUE,
           ylab="Residuales SDM espacialmente rezagados", xlab="Residuales SDM")

##### Stargazer ####

stargazer(ols, sar.upz, upz.sem, upz.sdm,
          column.labels=c("OLS","SAR", "SEM", "SDM"),
          type ="latex",keep.stat=c("n","rsq"),  style = "aer")

stargazer(upz.sarar) # no permite 