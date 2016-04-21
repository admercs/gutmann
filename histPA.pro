function histPA, filenames

openr, un, /get, filenames

mns=fltarr(50)

s=''
i=0
while not EOF(un) do begin

	readf, un, s
	cols=load_cols(s, data)
        
        mns(i) = mean(data)
	hist=histogram(data, binsize=0.01)
	if i eq 0 then begin
		plot, hist, xr=[0,20]
	endif else	oplot, hist
	i=i+1;
endwhile

;wait, 5

plot, mns(0:i-1)
print, i
print, mns(0:i-1)
close, un
free_lun, un
return, mns(0:i-1)
end

