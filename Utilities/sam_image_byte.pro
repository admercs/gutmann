pro sam_image_byte,image1,image2,outfile,ns,nl,nb
;
; PURPOSE: to perform a specialized type of SAM (Spectral Angle Mapper)
;          processing on 2 images.  An angle is computed between the 
;          spectra at the same pixel locations in the 2 images.
;
;          Algorithm:
;          1) read a spectral slice from each image
;          2) compute the angle between each spectrum pair
;          3) output the angle for each spectrum pair
;
;
; INPUT:   image1  - file name of first float bsq data file
;          image2  - file name of second float bsq data file.  NOTE:  both
;                    image1 and image2 must have the same dimensions
;          outfile - file name for output results
;          ns      - number of samples, default is 2868
;          nl      - number of samples, default is 2952
;          nb      - number of bands, default is 6
;          
; OUTPUT: the output are written to a user specified file.  The file is a
;         BSQ, floating point with dimensions ns x nl.  The data are stored as
;         angles in units of radians.
;
; MODIFICATION HISTORY: Author - Kathy Heidebrecht  4/14/97


if (n_elements(ns) eq 0) then ns=2868
if (n_elements(nl) eq 0) then nl=2952
if (n_elements(nb) eq 0) then nb=6

data_size = 1                          ; 4 bytes in floating point number

openr,un1,/get,image1
openr,un2,/get,image2
openw,un3,/get,outfile

slice1=bytarr(ns,nb)
slice2=bytarr(ns,nb)
tmpslice=bytarr(ns)

for i=0,nl-1 do begin

  ; get a spectral slice from each of the input images
  for j=0,nb-1 do begin

    point_lun,un1,(long(ns)*nl*j*data_size + long(ns)*i*data_size)
    readu,un1,tmpslice
    slice1(*,j) = tmpslice

    point_lun,un2,(long(ns)*nl*j*data_size + long(ns)*i*data_size)
    readu,un2,tmpslice
    slice2(*,j) = tmpslice

  endfor

  ; compute SAM result one spectral slice at a time, see SIPS Manual,
  ; page 26 for equation

  prod = float(slice1) * slice2
  sum = total(prod,2)
  sq1 = float(slice1)^2
  sq2 = float(slice2)^2
  sqsum1 = total(sq1,2)
  sqsum2 = total(sq2,2)
  sqrt1 = sqsum1^(.5)
  sqrt2 = sqsum2^(.5)
  sam_result = acos(sum/(sqrt1*sqrt2))
  writeu,un3,sam_result
endfor

free_lun,un1,un2,un3

end
