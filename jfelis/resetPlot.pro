PRO resetPlot, old
  device, /close
  !p=old.p &  !x=old.x &  !y=old.y
  set_plot, old.olddev
END

