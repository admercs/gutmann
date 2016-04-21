pro getEM, avfile, ns, nl, nb, emfile, outfile

avcub = intarr(nb, ns, nl)
spec  = fltarr(nb)

openr, avun, /get, avfile
readu, avun, avcub
close, avun
free_lun, avun

jnk=load_cols(emfile, coord)
dims=size(coord, /dimensions)
if jnk ne 2 then begin
	print, string('coordinates have' + string(jnk) + ' columns')
	return
endif

spec=0
for i=0, (dims(1)-1) do begin
	spec= spec+avcub(*, coord(0,i), coord(1,i))
endfor

spec= spec/dims(1)
help
spec=fix(spec)
help

openw, outun, /get, outfile
writeu, outun, spec
close, outun
free_lun, outun

end