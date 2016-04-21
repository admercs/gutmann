PRO convallouts

  day=[30, 30, 37, 38, 38, 30, 14, 46, 46]+3
  day[6]--
  FOR i=1,9 DO BEGIN
     cd, current=olddir, 'ihop'+strcompress(i, /remove_all)
     convouts2one, 'convoutslate', getday=day[i-1], /forceday
;     convouts2one, 'convouts1', getday=day[i-1]+1, /forceday
;     convouts2one, 'convouts2', getday=day[i-1]+2, /forceday
     cd, olddir
  ENDFOR
END
