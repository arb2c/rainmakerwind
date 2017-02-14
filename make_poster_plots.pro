PRO make_poster_plots,flight
   ;Make plots and data files for poster.  2/13/2017
   ;Also make a datafile with all the data
   ;Enter flight 4 or 5
   ;Flight 3 just does a track
   
   IF flight eq 3 THEN BEGIN
      date='20161121'
      x=analyze_fin2(3,-1.5,/noplot)
      google_map,x.extra.lat,x.extra.lon,/ps
      return
   ENDIF

   IF flight eq 4 THEN BEGIN
      date='20170120'
      x=analyze_fin2(4,-1.5,/noplot,pitot=1.15)
   ENDIF

   IF flight eq 5 THEN BEGIN
      date='20170207'
      x=analyze_fin2(5,-1.5,/noplot,pitot=1.10)
   ENDIF

   ;Data file
   close,1
   openw,1,'albatross_'+date+'.txt'
   printf,1,'time','lat','lon','wspd[m/s]','wdir[deg]','tas[m/s]','gs[m/s]','uwind[m/s]','vwind[m/s]','course[deg]','heading[deg]','pitch[deg]','roll[deg]','aoa[deg]','ss[deg]',format='(30a14)'
   for i=0,n_Elements(x.time)-2 do begin   ;-2 since occasionally wind array one short
       printf,1,x.time[i], x.lat[i], x.lon[i], x.wspd[i], x.wdir[i], x.tas[i], x.tgs[i], x.uwind[i], x.vwind[i], x.course[i], x.truehead[i], x.extra.pitch[i], x.extra.roll[i], x.aoa[i], x.ss[i],x.format='(30f14.6)'
   endfor
   close,1

   ;Plots
   cgps_open,date+_'wspd.ps'
   cgplot,x.time,x.wspd,xtitle='Elapsed Time (s)', ytitle='Wind Speed (m/s)', color='red'
   cgps_close,/png
   
   
   
   