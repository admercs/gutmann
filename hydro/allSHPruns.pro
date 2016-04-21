;;      Soil parameters:                                                                                              
;;        SMCMAX: MAX soil moisture content (porosity)                                                                
;;        SMCREF: Reference soil moisture  (field capacity)                                                           
;;        SMCWLT: Wilting point soil moisture                                                                         
;;        SMCWLT: Air dry soil moist content limits                                                                   
;;       SSATPSI: SAT (saturation) soil potential                                                                     
;;         DKSAT: SAT soil conductivity                                                                               
;;          BEXP: B parameter                                                                                         
;;        SSATDW: SAT soil diffusivity                                                                                
;;           F1: Soil thermal diffusivity/conductivity coef.                                                          
;;        QUARTZ: Soil quartz content                                                                                 
;; NOTE: SATDW = BB*SATDK*(SATPSI/MAXSMC)                                                                             
;;         F11 = ALOG10(SATPSI) + BB*ALOG10(MAXSMC) + 2.0                                                             
;;       REFSMC1=MAXSMC*(5.79E-9/SATDK)**(1/(2*BB+3)) 5.79E-9 m/s= 0.5 mm                                             
;;       REFSMC=REFSMC1+1./3.(MAXSMC-REFSMC1)                                                                         
;;       WLTSMC1=MAXSMC*(200./SATPSI)**(-1./BB)    (Wetzel and Chang, 198                                             
;;       WLTSMC=WLTSMC1-0.5*WLTSMC1                                                                                   

pro allSHPruns
;Param   min    max    step  idealstep
;-------------------------------------
;SATsmc  0.2  - 0.5  : 0.05    0.01
;SATpsi  0.03 - 0.8  : 0.1     0.01
;SATdk   1E-7 - 1E-4 : 1.5E-5  1E-6
;Bexp    1.5  - 13   : 1.5     0.1

  mxsmc= 0.5   &  mnsmc=0.2    &  stepsmc=0.05
  mxBB = 0.8   &  mnBB =0.03   &  stepBB =0.1
  mxSK = 1E-4  &  mnSK =1E-7   &  stepSK =1.5E-5
  mxPSI= 13    &  mnPSI=1.5    &  stepPSI=1.5

  nSMC = floor((mxsmc-mnsmc)/stepsmc)
  nBB  = floor((mxBB - mnBB)/stepBB)
  nSK  = floor((mxSK - mnSK)/stepSK)
  nPSI = floor((mxPSI-mnPSI)/stepPSI)

  diff=fltarr(nSMC, nBB, nSK, nPSI)

;; iterate over all parameters
  i=0
  for MAXSMC = mnSMC,mxSMC,stepSMC do begin
     j=0
     for BB  = mnBB, mxBB, stepBB  do begin
        k=0
        for SATDK = mnSK, mxSK, stepSK do begin
           l=0
           for SATPSI = mnPSI, mxPSI, stepPSI do begin

;              writeSoilFile, MAXSMC, BB, SATDK, SATPSI
;              spawn, '../bin/NOAH >out'
;              diff[i,j,k,l]=computeDiff('refFile', 'fort.111')

              l=l+1
           endfor
           k=k+1
        endfor
        j=j+1
     endfor
     i=i+1
  endfor

  print, i,j,k,l
  help, diff

;  openw, oun, /get, 

end
