;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Reads the Rosetta soils data base from Schaap and Leij (1998)
;;  Converts the data base from van Genuchten (1980)
;;              into Noah (Cambell 1974) parameters
;;  FOR ALL SOILS : 
;;  Calculates theta, h, and K for both van Genuchten and Noah SHP models
;;
;; Returns vg and noah parameters as well as vg and noah h and k curves
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; calculate noah conductivity curve
FUNCTION noahK, T, b, ts, tr, ks=ks
  S=(T-tr)/(ts-tr)
  IF NOT keyword_set(ks) THEN ks=1.
  return, ks *S^(2.0*b+3.0)
END

; calculate noah diffusivity curve
FUNCTION noahD, theta, b, ts, ds=ds
;  S=(T-tr)/(ts-tr)
  IF NOT keyword_set(ds) THEN ds=1.
  return, ds *(theta/ts)^(b+2.0)
END

; calculate noah pressure head curve
FUNCTION noahH, T, b, ts, psi_s, tr
  S=(T-tr)/(ts-tr)
  return, psi_s *S^(-1.0*b)
END

; calculate van Genuchten conductivity curve
FUNCTION vgK, T, a, n, ts, tr, ks=ks
  IF NOT keyword_set(ks) THEN ks=1.
  S=(T-tr)/(ts-tr)
  m=1-1./n
  return, ks* S^0.5 *(1- (1- (S^(1/m)) )^m )^2
END 

; calculate van Genuchten pressure head curve
FUNCTION vgH, T, a,n,ts,tr
  S=(T-tr)/(ts-tr)
  m=1-1./n
  return, (1.0/a) * (S^(-1.0/m)-1)^(1.0/n)
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Translate van Genuchten to Brooks-Corey parameters, and from
;; there it is straight forward to convert to Noah (Cambell, 1974)
;; parameters.
;; 
;; from Morel-Seytoux et al. (1996)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION vg2noah, a,n
  p    = 1.0+2.0/(1.0-1.0/n)  ;p = BrooksCorey K=Ks*S^p
  b    = (p-3.0)/2.0          ;b = Noah/Cambell B parameter
  psi_s= (1.0/a) * (p+3)/(2.0*p*(p-1.0)) $
         * (147.8+8.1*p+0.092*p^2.0)/(55.6+7.4*p+p^2.0)

  return, {b:b,psi_s:psi_s}
END
;; and back again...
FUNCTION noah2vg, b, psi_s
  p = 3+2.0*b
  m = 2.0/(p-1.0)

  n = 1.0/(1.0-m)
  a = psi_s* (2*p*(p-1))/(p+3.0) * $
      ((55.6 + 7.4*p + p^2)/(147.8+8.1*p + 0.092*p^2))

  return, {a:a, n:n}
END


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  MAIN PROGRAM
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FUNCTION CompVG_Noah_Rosetta, inputdata
  print, ""
  print, ""
  print, "---WARNING---WARNING---WARNING---WARNING---WARNING---"
  print, "This is currently using residual moisture content within the Noah SHP model"
  print, "---WARNING---WARNING---WARNING---WARNING---WARNING---"
  print, ""
  print, ""

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Iniitialization and reading data
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; read in van Genuchten parameters from Rosetta database
  junk=load_cols(inputdata, data)

;; move the data into more useful variable names
  ks=data[7,*]  &  tr=data[8,*]  &  ts=data[9,*]
  a =data[10,*] &  n =data[11,*]

;; this is the number of SHPs in the file
  sz=n_elements(ts)
;; this is the number of points we will calculate for each SHP curve
  nVals=1000

;; unknown saturated conductivity are marked as -9.9
;;   change them to 1 to make them easier to see
  ks[where(ks EQ -9.9)]=1.0

;; create an array of saturation values  
  Theta=indgen(nVals)/(nVals-1.)

;; initialize the arrays we will store the results in
  noahCond=fltarr(sz,nVals)
  noahPsi =fltarr(sz,nVals)
  vgCond  =fltarr(sz,nVals)
  vgPsi   =fltarr(sz,nVals)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  REAL WORK DONE BELOW HERE
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; convert van Genuchten parameters to Noah (Cambell/Brooks-Corey) parameters
  NOAH=vg2noah(a,n)
  b=NOAH.b  &  psi_s=NOAH.psi_s
  
;; loop over all shps in the original file calculating the curves as we go
  FOR i=0,sz-1 DO BEGIN 
; convert saturation the moisture content
     T       = Theta*(ts[i]-tr[i])+tr[i]

; calculate van Geunchten curves for conductivity and head
     vgCond[i,*]  = vgK(T, a[i],n[i],ts[i],tr[i], ks=ks[i])
     vgPsi[i,*]   = vgH(T, a[i],n[i],ts[i],tr[i])

; calculate noah curves for conductivity and head
     noahCond[i,*]= noahK(T,b[i],ts[i], tr[i], ks=ks[i])
     noahPsi[i,*] = noahH(T,b[i],ts[i], psi_s[i], tr[i])
  ENDFOR

;; so that the lowest head value will plot on a log axis
  vgPsi+=0.00001

;; and we're done...
  return, {nk:noahCond, nh:noahPsi, vk:vgCond, vh:vgPsi, theta:T, $
           b:b, psi_s:psi_s, a:a, n:n, tr:tr, ts:ts, ks:ks}
END 
