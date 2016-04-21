FUNCTION readMeta, metafile
  openr, un, /get, metafile
  line=''
  filelist=''

  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     filelist=[filelist, line]
  ENDWHILE
  return, filelist[1:n_elements(filelist)-1]
END

PRO batchNDVIcomb, metafile, combfile
  envistart
  fnames=readMeta(metafile)

  openw, oun, /get, 'combmeta'
  printf, oun, n_elements(fnames)+1
  printf, oun, combfile
  FOR i=0, n_elements(fnames)-1 DO BEGIN
     file=strsplit(fnames[i], '/', /extract)
     file=file[n_elements(file)-1]+'.ndvi'

     FileToNDVI, fnames[i], file
     printf, oun, file
  ENDFOR

  close, oun  & free_lun, oun
  combunequal, 'combmeta', 'NDVI', /split
END
