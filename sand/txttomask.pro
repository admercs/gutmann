pro txttomask, roitxt, outfile, size

openr, un, /get, roitxt

s= ' '
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;skip past the header, we could read the file size here...
for i=0, 8 do begin
	readf, un, s
endfor

tmp=str_sep(s, ':')
npoints=0l
reads, s, npoints

if n_elements(size) eq 0 then begin
	ns=0
	nl=0
	tmp=str_sep(s, ' ')
	reads, tmp(3), ns
	reads, tmp(5), nl

	size=long(ns)*nl
	readf, un, s

endif	else begin
	readf, un, s
	readf, un, s
endelse

data=bytarr(size)
print, size


i=lonarr(7)
j=0l
while not eof(un) and j le npoints-7 do begin
	readf, un, i
	data(i) = 1
	j=j+7
endwhile

i=lonarr(npoints-j)
readf, un, i
data(i) = 1


openw, oun, /get, outfile
writeu, oun, data

close, oun, un
free_lun, oun, un

end