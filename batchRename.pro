PRO batchRename
  openr, un, /get, "filelist"
  line=""
  i=1
  WHILE NOT eof(un) DO BEGIN
     readf, un, line
     FILE_COPY, line, strcompress(i,/remove_all)+".jpg"
     print, line
     i++
  ENDWHILE 
  close, un
  free_lun, un
END

