;+
; Name: process_asd_specs
;
; Purpose: to process spectra measured on an ASD-FR spectrometer, converting
;       the spectra from raw to a final usable spectrum in ascii format
;
; Calling Sequence:
;       pro process_asd_specs,dir,                $
;                             copydisk=copydisk,  $
;                             swap=swap,          $
;                             darkdir=darkdir,    $
;                             rcalc=rcalc,        $
;                             calibdir=calibdir,  $
;                             pcorrect=pcorrect,  $
;                             vnir_wl=vnir_wl,    $
;                             swir_wl=swir_wl
;
; Parameters:
;        dir - parent directory that will contain "raw", "ascii", and "info"
;              subdirectories.  The raw ASD spectra should already be in the 
;              "raw" directory, or the user can specify to copy the raw spectra
;              from floppy disk
;             
; Keywords:
;        copydisk - if set, raw spectra will be copied from floppy disk
;        swap     - if set, spectrum header values and raw DN values will be
;                   byteswapped
;        darkdir  - if set, the dark current will be subtracted from the raw
;                   spectral data.  The format is a string containing name of 
;                   directory where dark current files are found.  The dark
;                   current filenames are of the format "dark_NNN_IIIms.spec'
;                   where NNN is the instrument number and III is the 
;                   integration time.
;                   if not set, then no dark current will be subtracted
;        rcalc    - if set, the spectra will be radiometrically calibrated.
;                   By default, rcalc will use the calibration files found in
;                   /khroma/kathy/g3/spectra/calib_files/default.  You can 
;                   choose your own calibration files by using the "calibdir"
;                   keyword.
;                   If the "rcalc" keyword is not set, then the spectra will 
;                   NOT be radiometrically calibrated
;        calibdir - if set, the radiometric calibration files from this 
;                   directory will be used.  The format is a string containing
;                   the name of the directory.  If not set and the user 
;                   specifies the "rcalc" option, then the calibration files
;                   will come from /khroma/kathy/g3/spectra/calib_files/default.
;        pcorrect - if set, the spectra will be pcorrected
;        vnir_wl  - if set, it will be used as the vnir vertex in pcorrect.  If
;                   not set, the default is 750.
;        swir_wl  - if set, it will be used as the swir2 vertex in pcorrect.  If
;                   not set, the default is 1975.
;
; Return Values: none
;
; Common Blocks: none
;
; Procedure:
;   1. change to user input parent directory 
;   2. make the following temporary and permanent directories
;            raw           ; permanent
;            info          ; permanent
;            ascii         ; permanent
;            pctounix      ; temporary
;            darkcorr      ; temporary
;            rcalc         ; temporary
;            pcorrect      ; temporary
;   3. copy raw spectra from floppy disk if needed
;   4. convert header to Unix compatible format.  Output goes in "pctounix"
;      directory.
;   5. subtract dark current if needed.  Output goes in "darkcorr" directory.
;   6. copy appropriate calibration files if needed 
;   7. do radiometric calibration if needed.  Output goes in "rcalc" directory.
;   8. delete calibration files if needed
;   9. use pcorrect to fix VNIR and SWIR boundaries if needed.  Output goes 
;      in "pcorrect" directory
;   10. convert resulting spectra to ascii.  Output goes in "ascii" directory.
;   11. append additional header information to ascii files.
;   12. remove temporary directories
;
; Modification History: 
;   1/3/97 - original version KBH CSES/University of Colorado
; 
@load_cols_hdr
@save_cols

pro append_info,fname,darkfile,rcalc,calibdir,pcorrect,vnir_wl,swir_wl

; read spectral info
; open file
; read header info
; write header info plus new info
; write spectral info
; close file

cols=load_cols_hdr(fname,spec,hdr,hdr_count)

num_hdr_lines = hdr_count + 3
newhdr = strarr(num_hdr_lines)
newhdr(0:hdr_count-1) = hdr(0:hdr_count-1)

if (n_elements(darkfile) eq 1) then begin
  newhdr(hdr_count) = 'Dark current subtracted from file: ' + darkfile
  hdr_count=hdr_count+1
endif

if (n_elements(rcalc) eq 1) then begin
  newhdr(hdr_count) = 'Spectrum calibrated from files in directory: ' + calibdir
  hdr_count=hdr_count+1
endif

if (n_elements(pcorrect) eq 1) then begin
  newhdr(hdr_count) = 'Spectrum pcorrected at' + strcompress(string(vnir_wl)) $
                      + ' nm and' + strcompress(string(swir_wl)) + ' nm'
endif else begin
  newhdr(hdr_count) = 'Spectrum was not pcorrected'
endelse

save_cols,fname,spec,comment=newhdr(0:hdr_count)

end


pro darkcorr,ifname,ofname,darkdir,darkfile

; define constants

ASD_HEADER_SIZE  = 484
UNIX_HEADER_SIZE = 504
INT_TIME_INDEX   = 102
INST_NUM_INDEX   = 209
ASD_SPEC_SIZE    = 2151

; get integration time from header
openr,un1,/get,ifname
hdr=lonarr(UNIX_HEADER_SIZE/4)
readu,un1,hdr
int_time=hdr(INT_TIME_INDEX)

; get instrument number from the header
point_lun,un1,0
hdr=intarr(UNIX_HEADER_SIZE/2)
readu,un1,hdr
inst_num=hdr(INST_NUM_INDEX)
free_lun,un1

; create dark current file name and open file
darkfile=darkdir + '/dark_' + strcompress(string(inst_num),/rem) + '_' + $
	 strcompress(string(int_time),/rem) + 'ms.spec'
print,'subtracting dark current from directory:' + darkfile
junk=load_cols(darkfile,dark)
print,junk
plot,dark(1,*)

; subtract dark current
openr,un1,/get,ifname
hdr=bytarr(UNIX_HEADER_SIZE)
spec=fltarr(ASD_SPEC_SIZE)
readu,un1,hdr
readu,un1,spec

outspec = spec - dark(1,*)

; write dark current subtracted spectrum

openw,un2,/get,ofname
writeu,un2,hdr
writeu,un2,float(outspec)

free_lun,un1,un2

end

pro process_asd_specs,dir,                $
                      copydisk=copydisk,  $
                      swap=swap,          $
                      darkdir=darkdir,    $
                      rcalc=rcalc,        $
                      calibdir=calibdir,  $
                      pcorrect=pcorrect,  $
                      vnir_wl=vnir_wl,    $
                      swir_wl=swir_wl

; - change to spectra directory 
; - make temporary and permanent directories
; - copy raw spectra from disk if needed
; - convert header to Unix compatible format
; - subtract dark current if needed
; - copy appropriate calibration files if needed
; - do radiometric calibration if needed
; - delete calibration files if needed
; - fix VNIR and SWIR boundaries if needed
; - convert to ascii
; - append additional header information
; - remove temporary directories
; 


; initialize variables

if (n_elements(calibdir) eq 0) then begin
   calibdir='/khroma/kathy/g3/spectra/calib_files/default'
endif

if (n_elements(swap) eq 0) then begin
   swap_option = ' '
endif else begin
   swap_option = '-b'
endelse

if (n_elements(vnir_wl) eq 0) then begin
   vnir_wl = 750
endif

if (n_elements(swir_wl) eq 0) then begin
   swir_wl = 1975
endif

; make directories in spectrum directory

print,'creating directories...'
cd,dir
spawn,'mkdir raw'          ; permanent
spawn,'mkdir info'         ; permanent
spawn,'mkdir ascii'        ; permanent
spawn,'mkdir pctounix'     ; temporary
spawn,'mkdir darkcorr'     ; temporary
spawn,'mkdir rcalc'        ; temporary
spawn,'mkdir pcorrect'     ; temporary


; copy raw spectra from disk if necessary

if (n_elements(copydisk) eq 1) then begin
  print,'copying files from floppy disk...'
  cd,'raw'
  spawn,'mcopy a:\* .' 
  cd,'..'
endif

; get spectrum filenames and number of files

cd,'raw'                              ; currently in raw DIR
spawn,'ls ',fname
info = size(fname)
num_files = info(1)

; convert headers to Unix compatible format

for i=0,num_files-1 do begin
  spawn,'pctounix ' + swap_option + ' ' + fname(i) + ' ' + $
        '../pctounix/' + fname(i)
endfor
cd,'../pctounix'                    ; currently in pctounix DIR

; subtract dark current if necessary
; dark current file should be in the form of two-column ascii, wavelength value

if (n_elements(darkdir) eq 1) then begin
  for i=0,num_files-1 do begin
    darkcorr,fname(i), '../darkcorr/' + fname(i), darkdir, darkfile
  endfor
  cd,'../darkcorr'                    ; currently in darkcorr DIR
endif else begin
  print,' '
  print,'spectra will not have dark current subtracted'
  print,' '
endelse

; do radiometric calibration

; get calibration files
if (n_elements(rcalc) eq 1) then begin
  print,'calibration files from directory: ' + calibdir
  spawn,'ls ' + calibdir, calibfiles
  spawn,'cp ' + calibdir + '/* .'
  for i=0, num_files-1 do begin
    spawn,'rcalc ' + fname(i) + ' ' + $
          '../rcalc/' + fname(i)
  endfor
  spawn,'rm ' + calibfiles
  cd,'../rcalc'                       ; currently in rcalc DIR
endif else begin
  print,' '
  print,'spectra will not be radiometrically calibrated'
  print,' '
endelse

; do VNIR and SWIR edge corrections
if (n_elements(pcorrect) eq 1) then begin
  for i=0, num_files-1 do begin
    spawn,'pcorrect ' + string(vnir_wl) + ' ' + string(swir_wl) + ' ' +  $
           fname(i) + ' ' + '../pcorrect/' + fname(i)
  endfor
  cd,'../pcorrect'                  ; currently in pcorrect DIR
endif else begin
  print,' '
  print,'spectra will not be pcorrected'
  print,' '
endelse

; convert to ascii
for i=0, num_files-1 do begin
  spawn,'portspec -a ' + fname(i) + ' ' + $
        '../ascii/' + fname(i)
endfor
cd,'../ascii'                       ; currently in ascii DIR

; append additional header information

print,'appending additional information to ascii files...'
for i=0, num_files-1 do begin
  append_info,fname(i),darkfile,rcalc,calibdir,pcorrect,vnir_wl,swir_wl
endfor

; remove temporary directories

print,'removing temporary directories...'
cd,'..'                               ; currently at main level
spawn,'rm -fr pctounix'     
spawn,'rm -fr darkcorr'    
spawn,'rm -fr pcorrect'   
spawn,'rm -fr rcalc'        

end
