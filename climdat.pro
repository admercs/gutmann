function readnextline, unit	s=''	tmp=0l	data=lonarr(15)	readf, unit, s	sepstring=str_sep(s, ' ')	redstring=sepstring(where(sepstring ne ''))		reads, redstring(0), tmp	data(0)=tmp	n=n_elements(redstring)	for i=n-14, n-1 do begin		reads, redstring(i), tmp		data(i-n+15) = tmp	end	return, dataend;;for outputing to century format;IDL> i=string(format='(F7.2)', 34.5);IDL> print, i;  34.50;; reads climate data from an ascii file and out puts it in long binary form seperated by locationpro climdat, infileopenr, inun, /get, infiles=''readf, inun, scurfile=''data=lonarr(200, 15)count=0tmp=0lwhile not eof(inun) do begin;; read first line to intialize everything	readf, inun, s	sepstring=str_sep(s, ' ')	redstring=sepstring(where(sepstring ne ''))		reads, redstring(0), tmp	data(count, 0) = tmp	n=n_elements(redstring)	for i=n-14, n-1 do begin		reads, redstring(i), tmp		data(count, i-n+15) = tmp	end	curfile=redstring(1);; main read loop	while not eof(inun) and data(count, 0) eq data(0,0) do begin		count=count+1		data(count,*)=readnextline(inun)	endwhile;;output the current data file	if count le 1 then begin 		print, 'ERROR : ', curfile	endif else begin		if not eof(inun) then begin			openw, oun, /get, curfile+strcompress(string(data(0,0)))+ $				strcompress(string(data(0,1)))+strcompress(string(data(count-1,1)))		endif else begin			openw, oun, /get, curfile+strcompress(string(data(0,0)))+ $				strcompress(string(data(0,1)))+strcompress(string(data(count,1)))		endelse		writeu, oun, data(0:count-1,*)		close, oun & free_lun, oun	endelse	data(0,*)=data(count,*)	count=1endwhileend