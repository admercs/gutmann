; $Id: super_resample.pro,v 1.2 94/01/07 16:53:30 shapiro Exp $
;+
; NAME: super_resample 
;
; PURPOSE: given an input wavelength and reflectance, and output
;	wavlength, resample the reflectance into the output wavelength
;	space.
;	 
; PROCEDURE: use the gauss_conv library function for each point.  fwhm
;	is either a constant value, or an array of one value for each
;	point. 
;
; INPUTS: inspec - input relfectance 
;         inwl   - input wavelength associated with inspec
;         outwl  - output wavelength to resample to
;         fwhm   - output fwhm to resample to.  This can be one constant
;                  fwhm for all wavelengths, or an array with one fwhm 
;                  corresponding to each wavelength
;
; KEYWORD PARAMETERS: none 
;
; RETURN VALUE: none 
;
; OUTPUTS: outspec - output resampled reflectance 
;
; COMMON BLOCKS: none 
;
; MODIFICATION HISTORY: jwb 7/91 
;                       kbh 11/95 - handles input spectra whose wavelengths
;                                   are not equally spaced (such as output
;                                   from MODTRAN that is originally in 
;                                   frequency (cm-1) or for HYDICE data)
;-
function gauss_conv,inspec,inwl,center,fwhm,gaus
gaus = fltarr(n_elements(inspec))
gaus = exp((-4.*alog(2.)*((inwl-center)/fwhm)^2)>(-40))

totinwl = n_elements(inwl)
diff = fltarr(totinwl)
diff(1:totinwl-2) = (inwl(2:totinwl-1)-inwl(0:totinwl-3))/2.
diff(0) = (inwl(1)-inwl(0))
diff(totinwl-1) = (inwl(totinwl-1)-inwl(totinwl-2))
gaus=gaus*diff

out = total(inspec*gaus)/total(gaus)
return,out
end

pro super_resample,inspec,inwl,outspec,outwl,fwhm,bp=bp
n = n_elements(outwl)
outspec = fltarr(n)
bp = fltarr(n,n_elements(inspec))
if (n_elements(fwhm) eq 1) then begin
   for i=0,n-1 do begin 
      outspec(i)=gauss_conv(inspec,inwl,outwl(i),fwhm,gaus)
      bp(i,*) = gaus
   endfor
endif else begin
   for i=0,n-1 do begin
     outspec(i)=gauss_conv(inspec,inwl,outwl(i),fwhm(i),gaus)
     bp(i,*) = gaus
   endfor
endelse
end
