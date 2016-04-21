;;effectivly load_cols into a float array 
;; but modified to that it figures out what the largest number of columns is

function my_read_ascii, file

i=0
s=''
maxcols=0;
openr, un, /get, file

while not eof(un) do begin
	readf, un, s
	i=i+1
	j=str_sep(s,' ')
	maxcols=max([maxcols,n_elements(j)])
endwhile

point_lun, un, 0
s=''
result=fltarr(maxcols,i)

for a=0, i-1 do begin 
	readf, un, s
	j=str_sep(s, ' ')
	for k=0,n_elements(j)-1 do begin
		result(k,a)=float(j(k))
;	break
	endfor
endfor

return, result
end