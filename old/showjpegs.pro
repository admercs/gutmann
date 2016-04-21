pro showjpegs, delay=delay, suffix=suffix, prefix=prefix

if not keyword_set(suffix) then suffix = '.jpg'
if not keyword_set(prefix) then prefix = '*'
if not keyword_set(delay) then delay=2

list= findfile(prefix+'*'+suffix)

if list(0) ne '' then $
  for i=0,n_elements(list)-1 do begin
	read_jpeg,list(i), image
	tv,image,true=1
	wait, delay
  endfor


end


