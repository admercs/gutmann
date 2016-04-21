function ddTOdms, ddinput
  dd=abs(ddinput)
  deg = byte(dd)
  minute = fix((dd-deg)*60)
  sec = (((dd-deg)*60)-minute)*60.

  print, deg, minute, sec
  return, [float(deg), float(minute), float(sec)]
end
