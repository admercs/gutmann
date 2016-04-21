
PRO batchSAM, metafile
  openr, un, /get, metafile
  line=''
  readf, un, line
  ref=line

;; read through the meta file correcting each image to the first image
  WHILE NOT eof(un) DO BEGIN

;; read the input file name
     readf, un, line

;; set up the output filename
     out=strsplit(line, '/', /extract)
     out=strsplit(out[n_elements(out)-1], '.', /extract)
     out=string(out[0],".norm")

     print, ""
     print, " Correcting input = ", line
     print, "   output    file = ", out
     print, "   reference file = ", ref
     print, ""
;; perform the correction
     tmp=ref  ;prevents overwriting ref file name 
     SAM_normalize, tmp, line, out
  ENDWHILE

;cleanup
  close, un
  free_lun, un
END

