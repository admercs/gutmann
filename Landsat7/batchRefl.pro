PRO batchRefl, inputfile, outputdir, makeNDVI=makeNDVI

  IF NOT keyword_set(outputdir) THEN outputdir=""

  openr, un, /get, inputfile

  line=''
  WHILE NOT eof(un) DO BEGIN 
     readf, un, line
     parsed=strsplit(line, /extract)
     filename=parsed[0]
     Landsat =fix(parsed[1])

;; find the outputfilename
     outfile = strsplit(filename, '/', /extract)
     outfile=outfile[n_elements(outfile)-1]

;; just makes the L7 filenames a little more reasonable
     tmp=strsplit(outfile, '_', /extract)
     IF n_elements(tmp) GT 3 THEN outfile=tmp[1]

;place the output files in the right place and add a .refl to the name
     outfile = string(outputdir,outfile,".refl")

     print, "Correcting ", filename, " to ", outfile
     IF Landsat EQ 7 THEN BEGIN
        L7toRefl, filename, parsed[2], outfile, makeNDVI=makeNDVI
     ENDIF ELSE IF Landsat EQ 5 THEN BEGIN
        L7toRefl, filename, outfile, Landsat=Landsat, makeNDVI=makeNDVI
     ENDIF

  ENDWHILE
  close, un
  free_lun, un
END
