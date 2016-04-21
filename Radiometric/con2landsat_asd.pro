; Name: con2landsat_asd
;
; Purpose: convolve a higher resolution spectrum to landsat bandpasses.  
;       Supports landsats 4, 5, 7.
; 
; Calling Sequence:
;       con2landsat, inwav, inspec, outspec, landsat=landsat
;
; Parameters:
;       inwav - wavelengths for spectrum to be convolved in nanometers
;       inspec - spectrum to be convolved
;       outspec - output convolved spectrum
;
; Keywords:
;       landsat - the landsat generation (4,5, or 7(default))
;
; Return Values: none
;
; Common Blocks: none
;
; Procedure: read in bandpasses for each band, normalize bandpasses to unit
;        sum, resample input spectrum to landsat bandpass wavelengths, then
;        multiply the landsat bandpass by the resampled spectrum and total
;        the values.

pro con2landsat_asd, inwav, inspec, outspec, landsat=landsat

; 6 band output spectrum 
outspec=fltarr(6)

; default to landsat 7 bandpasses
if (keyword_set(landsat) eq 0) then landsat = 7

; set the index to the column in the bandpass files
if (landsat eq 4) then begin
   index=2
endif else if (landsat eq 5) then begin
   index=3
endif else begin
   index=1
end

; for each band, read in the bandpass files, resample the input spectrum to
; the bandpass wavelengths, normalize the bandpass to unit sum, then multiply
; the resampled input spectrum by the normalized bandpass and add all values
; together to get a single value for each band.
for i=0,5 do begin
  if (i ne 5) then begin
    fname = 'band' + strcompress(string(i+1),/remove_all)
  endif else begin
    fname = 'band7'
  end

  junk = load_cols('/sundog/users/kathy/idl/landsat/bandpass/'+fname, bp)
  if (junk ne 4) then begin
    print,'/sundog/users/kathy/idl/landsat/bandpass/'+fname+' did not open successfully.  Exiting....'
    exit
  endif

  super_resample,inspec,inwav,resampspec,bp(0,*),1
  filter = bp(index,*)/total(bp(index,*))
  outspec(i) = total(filter*resampspec)
endfor

end ; con2landsat
