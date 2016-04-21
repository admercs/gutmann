PRO getGOES, startDay, endDay, prefix=prefix
  IF NOT keyword_set(prefix) THEN prefix="WCVS05"

  openw, oun, /get, "getGoes.sh"
  printf, oun, "#!/bin/sh"

  FOR day=startDay, endDay DO BEGIN
     FOR time=0.0,23.5,0.5 DO BEGIN
        line='wget http://www.goes-arch.noaa.gov/'+prefix
        IF day LT 10 THEN line=line+'0'
        IF day LT 100 THEN line=line+'0'
        line=line+strcompress(day,/remove_all)

        hour=strcompress(fix(time), /remove_all)
        IF hour LT 10 THEN line=line+'0'
        line=line+hour
        IF (time MOD 1) EQ 0.5 THEN minute='45' else minute='15'
        line=line+minute
        line=line+'.GIF'
        
        printf, oun, line
;        printf, oun, 'sleep '+strcompress(fix(abs(randomn(seed)*10))
     endFOR

  ENDFOR
END
