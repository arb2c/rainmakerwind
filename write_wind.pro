pro write_wind, x
   close,1
   openw,1,'out.txt'
   printf,1,'time','lat','lon','wspd[m/s]','wdir[deg]','tas[m/s]','gs[m/s]','uwind[m/s]','vwind[m/s]',format='(20a14)'
   for i=0,n_Elements(x.time)-2 do begin   ;-2 since occasionally wind array one short
       printf,1,x.time[i], x.lat[i], x.lon[i], x.wspd[i], x.wdir[i], x.tas[i], x.tgs[i], x.uwind[i], x.vwind[i], format='(20f14.6)'
   endfor
   close,1
end