PRO one2one
  mn=min([!x.crange[0],!y.crange[0]])
  mx=max([!x.crange[1],!y.crange[1]])
  
  oplot, [mn,mx],[mn,mx]
END

