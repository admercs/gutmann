pro Fixer, infile, outfile, samples, lines, bands

;;Reads a floating point image, fixes it, and outputs
;;
;;	because we don't do anything to the file we don't care whether it is
;;	bsq, bil, or bip, just read on "line" at a time, and we will end up ok

openr, /get, inun, infile
openw, /get, outun, outfile

tmpline = fltarr(lines, bands)
newline = intarr(lines, bands)

for i=1, samples do begin
	readu, inun, tmpline
	newline = fix(tmpline)
	writeu, outun, newline
end

close, inun
close, outun
free_lun, inun
free_lun, outun

end