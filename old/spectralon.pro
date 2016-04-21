pro spectralon

junk=load_cols('/khroma/users/warneras/spectralon.ascii',spec)
cd, '/photon/dune2/imagery/flight_season_99/bad_specs/ascii'

spawn, 'ls', fname
fnamecor='c'+fname
print, fname, fnamecor
num_files=n_elements(fname)
print,'num_files=',num_files
cor=fltarr(2151,num_files)
cor1=fltarr(2, 2151)

for i=0, num_files-1 do begin
       blah = load_cols(fname(i), spectrum)
	cor(*, i)=spectrum(1,*)*spec(2,*)
endfor

help, spectrum
help, cor
cd, '..'
cd,'/photon/dune2/imagery/flight_season_99/bad_specs/spectralon/'

for i=0, num_files-1 do begin
	for j=0, 2150 do begin
	cor1(0,j)=j+350
	cor1(1,j)=cor(j,i)
    endfor
	openw,un1,fnamecor(i),/get
	printf,un1, cor1
	free_lun, un1
endfor

$cd, '..'

end
