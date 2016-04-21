;; Reads in a list of filenames from an input file.  Assumes one file
;; name is on each line
FUNCTION readInput, input
  openr, un, /get, input
  line=''
  readf, un, line

  nameList=line

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     nameList=[nameList, line]
  ENDWHILE
  return, nameList
END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Run a principal components transform on a list of files as
;; specified in the input file.  
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRO multiPcomp, input

;; starts envi in batch mode
  envistart

;; read in the file names to be processed
  fnames=readInput(input)

  FOR i=0,n_elements(fnames)-1 DO BEGIN
     info=getFileInfo(fnames[i])
     
     envi_open_file, fnames[i], r_fid=fid
     IF fid EQ -1 THEN BEGIN
        print, 'ERROR : Could not open file : ', fnames[i]
        return
     ENDIF

;; setup variables for ENVI doit routines
     dims=[-1,0,info.ns-1, 0,info.nl-1]
;; NOTE, We do NOT want band 6 in there!
     IF info.nb eq 7 THEN BEGIN
        pos =lindgen(6)
        pos[5]=6
     ENDIF ELSE pos =lindgen(info.nb)

     outname = fnames[i]+'_PC'
;; compute statistics for the image
     envi_doit, 'envi_stats_doit', $
                fid=fid, pos=pos, dims=dims, $
                mean=mean, eval=eval, evec=evec, comp_flag=5
;; compute the principal components image
     envi_doit, 'pc_rotate', $
                fid=fid, pos=pos, dims=dims, $
                mean=mean, eval=eval, evec=evec, /forward, $
                out_name=outname, out_dt=4, r_fid=rfid, /no_plot
     envi_file_mng, id=fid, /remove
     envi_file_mng, id=rfid, /remove
  ENDFOR

END



