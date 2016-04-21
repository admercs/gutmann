pro planck, T, wave

IF n_elements(wave) EQ 0 THEN BEGIN 
   wave=float(indgen(10000))
   wave=1.5*wave/1000.
END


output=(3.74151*10.^8)/((wave^5)*(2.71828^((1.43879*10^4)/(wave*T))-1))
IF n_elements(wave) GT 1 THEN BEGIN 
   plot, wave,output, xr=[0,1], /xstyle
ENDIF ELSE IF n_elements(output) EQ 1 THEN print, wave, output
;print, 3.74151*10.^8
;print, (wave[50]^5)
;print, 2.71828^((1.43879*10^4)/(wave(50)*T))
index= (where(output GT 101481/!pi))[0]
print, index
IF index[0] NE -1 THEN $
  print, T[index]
end
