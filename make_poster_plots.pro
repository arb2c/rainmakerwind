
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
   printf,1,'time','lat','lon','wspd[m/s]','wdir[deg]','tas[m/s]','gs[m/s]','uwind[m/s]','vwind[m/s]',$
          'course[deg]','heading[deg]','pitch[deg]','roll[deg]','aoa[deg]','sideslip[deg]','coursewind[m/s]',$
          'crosswind[m/s]',format='(30a14)'
   coursewind=x.uwind*sin(x.course*!pi/180) + x.vwind*cos(x.course*!pi/180)
   crosswind=x.uwind*cos(x.course*!pi/180) + x.vwind*sin(x.course*!pi/180)
   for i=0,n_Elements(x.time)-2 do begin   ;-2 since occasionally wind array one short
       printf,1,x.time[i], x.lat[i], x.lon[i], x.wspd[i], x.wdir[i], x.tas[i], x.tgs[i], x.uwind[i],$
              x.vwind[i], x.course[i], x.truehead[i], x.extra.pitch[i], x.extra.roll[i], x.aoa[i],$
              x.ss[i],coursewind[i], crosswind[i], format='(30f14.6)'
   endfor
   close,1

   ;Plots
   airborne=where(x.tas gt 15)
   i1=min(airborne)-350
   i2=max(airborne)+350
   etime=x.time[i1:i2]-x.time[i1]
   !p.charsize=1.3
   !p.thick=4
   red='firebrick' ;indian red,
   blue='dodger blue'  ;steel blue,
   green='sea green' ;sea

   cgps_open,date+'_wspd.ps'
   cgplot,etime,x.wspd[i1:i2],xtitle='Elapsed Time (s)', ytitle='Wind Speed (m/s)', color=red,$
          yr=[0,20],/xs
   cgps_close,/png,width=1500

   cgps_open,date+'_wdir.ps'
   cgplot,etime,x.wdir[i1:i2],xtitle='Elapsed Time (s)', ytitle='Wind Direction (deg)', color=blue,$
          yr=[0,380],/ys,/xs
   cgps_close,/png,width=1500


 
   cgps_open,date+'_gpsalt.ps'
   cgplot,etime,x.extra.alt[i1:i2],xtitle='Elapsed Time (s)', ytitle='Altitude (m)', color=green,$
          yr=[1500, 1750],/ys,/xs
   cgps_close,/png,width=1500

   cgps_open,date+'_pitch.ps'
   cgplot,etime,fltarr(n_elements(etime)),xtitle='Elapsed Time (s)', ytitle='Pitch (deg)',$
          yr=[-30,30],/ys,/xs,line=1
   cgoplot,etime,x.extra.pitch[i1:i2],color=red
 cgps_close,/png,width=1500

   cgps_open,date+'_roll.ps'
   cgplot,etime,fltarr(n_elements(etime)),xtitle='Elapsed Time (s)', ytitle='Roll (deg)',$
          yr=[-60,60],/ys,/xs, line=1
   cgoplot,etime,x.extra.roll[i1:i2],color=blue
   cgps_close,/png,width=1500


   cgps_open,date+'_heading.ps'
   cgplot,etime,(x.extra.heading[i1:i2] + 36000) mod 360,xtitle='Elapsed Time (s)', ytitle='Heading (deg)', color=blue,$
          yr=[0,380],/ys,psym=16,symsize=0.25,/xs
   cgoplot,etime,x.course[i1:i2],color=red,psym=16,symsize=0.25
   cgLegend, TITLES=['Heading', 'Course'], COLOR=[blue,red], charsize=1.0,/box,/background,align=3,location=[0.15,0.17]
   cgps_close,/png,width=1500

   cgps_open,date+'_speed.ps'
   cgplot,etime,x.tas[i1:i2],xtitle='Elapsed Time (s)', ytitle='Speed (m/s)', color=blue,$
          yr=[0,50],/ys,/xs
   cgoplot,etime,x.tgs[i1:i2],color=red
   cgLegend, TITLES=['Air Speed', 'Ground Speed'], COLOR=[blue,red], /box,charsize=1.0,/background,align=3,location=[0.2,0.15]
cgps_close,/png,width=1500




END
   
   
   
   
