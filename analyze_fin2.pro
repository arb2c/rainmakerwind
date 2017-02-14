function analyze_fin2, flight, psi_correct, fin, ahrs, wind, noplot=noplot, pitot_correct=pitot_correct
;This version reads data straight from the RainmakerData files

IF n_elements(flight) eq 0 THEN flight=3
IF n_elements(psi_correct) eq 0 THEN psi_correct=0  ;test a correction, degrees
IF n_elements(pitot_correct) eq 0 THEN pitot_correct=1.0  ;pitot correction, mulitplication factor
IF n_elements(noplot) eq 0 THEN noplot=0
IF !version.release ge 8 THEN nan=1 ELSE nan=0  ;Workaround since GDL doesn't do NaN in smooth operation

;Read in data
IF n_elements(fin) eq 0 THEN BEGIN  ;Line to avoid re-reading if data already exists
   CASE flight OF
      1:fn='RainmakerData_2016_10_25_19_30_04.csv'
      2:fn='RainmakerData_2016_11_21_09_07_04.csv'
      3:fn='RainmakerData_2016_11_21_09_47_27.csv'
      4:fn='RainmakerData_2017_01_20_12_34_12.csv'
      5:fn='RainmakerData_2017_02_07_08_49_19.csv'
   ENDCASE

   fin=read_rainmaker(fn, 'fin', units=finunits)
   wind=read_rainmaker(fn, 'wind', units=windunits)
   ahrs=read_rainmaker(fn, 'ahrs', units=windunits)
   gps=read_rainmaker(fn, 'gps', units=gpsunits)
   vn300=read_rainmaker(fn, 'vn300', units=gpsunits)
   
   ;Some code to workaround data with vn300 instead of gps and ahrs
   IF vn300.ioerror eq 0 THEN BEGIN
      ;Do a proper interpolation of yaw angle, by 'unwinding' the direction to avoid rollovers
      yaw=vn300.yaw
      dyaw=yaw[1:*]-yaw
      plus=where(dyaw gt 200)
      minus=where(dyaw lt -200)
      for i=0,n_elements(plus)-1 do yaw[plus[i]+1:*]=yaw[plus[i]+1:*]-360
      for i=0,n_elements(minus)-1 do yaw[minus[i]+1:*]=yaw[minus[i]+1:*]+360
      
      
      ;Create an 'extra' array, just to get all this mess interpolated to the same time as 'fin'
      extra={time:fin.time, $
         heading:interpol(yaw, vn300.time, fin.time),$
         pitch:interpol(vn300.pitch, vn300.time, fin.time),$
         roll:interpol(vn300.roll, vn300.time, fin.time),$
         lat:interpol(vn300.lat, vn300.time, fin.time),$
         lon:interpol(vn300.long, vn300.time, fin.time),$
         velx:interpol(vn300.vel_x, vn300.time, fin.time),$
         vely:interpol(vn300.vel_y, vn300.time, fin.time)}
         
      bad=where(extra.heading lt 0, nbad)       ;Get range to 0:360, rather than -180:180
      IF nbad gt 0 THEN extra.heading[bad] = extra.heading[bad]+360
   ENDIF ELSE BEGIN
      extra={time:fin.time, $
         heading:interpol(ahrs.mag_head, ahrs.time, fin.time),$
         pitch:interpol(ahrs.pitch, ahrs.time, fin.time),$
         roll:interpol(ahrs.roll, ahrs.time, fin.time),$
         lat:interpol(gps.lat, gps.time, fin.time),$
         lon:interpol(gps.lon, gps.time, fin.time),$
         velx:interpol(gps.vel_x, gps.time, fin.time),$
         vely:interpol(gps.vel_y, gps.time, fin.time)}
   ENDELSE
   
   ;Data cleanup
   bad=where(extra.lat eq 0, nbad)
   IF nbad gt 0 THEN extra.lat[bad]=!values.f_nan
   bad=where(extra.lon eq 0, nbad)
   IF nbad gt 0 THEN extra.lon[bad]=!values.f_nan
ENDIF

;Constants
rconst=287.04  ;J/kg/K ideal gas constant
cp=1.01*1e3    ;J/kg/K specific heat at constant pressure
cv=0.718*1e3   ;J/kg/K specific heat at constant volume
gamma=1.40     ;cp/cv specific heat ratio, this is 'kappa' sometimes

;Note: Moist air corrections also possible, generally <1% change in TAS, neglect for now.

q=fin.pitot_pres * pitot_correct  ;This is actually pitot-static, q in Lenschow
ps=fin.static_pres
pt=(q+fin.static_pres)
tr=fin.amb_temp + 273.15
recov=1.0  ;Lets assume unity for now

;Compute TAS, matches RainMaker exactly
m2= 2/(gamma-1) * ((pt/ps)^((gamma-1)/gamma) - 1)           ;Mach number (squared)
tas_sq= gamma*rconst*m2*tr / (recov * (gamma-1)/2 * m2 +1)  ;Eq B.10 in TechNote 23
tas= sqrt(tas_sq)             ; * tas_correct

;Compute wind, use RainMaker calculations of aircraft attitude first
time=fin.time
alpha=fin.aoa_deg * !pi/180   ;attack
beta=fin.x24v_monitor * !pi/180  ;sideslip, 8V is pressure, 24V is degrees
;Data from AHRS is at a higher rate, need to downsample with interpolation
theta=extra.pitch * !pi/180   ;pitch
phi=extra.roll * !pi/180  ;roll


psi=(extra.heading+psi_correct) * !pi/180   ;true heading
utas=tas*sin(psi)
vtas=tas*cos(psi)
lat=extra.lat
lon=extra.lon
gpstime=extra.time

;From Khelif eq. 4 and 5
d=(1 + tan(alpha)^2 + tan(beta)^2)^(-0.5)
ell=0.5  ;Distance from GPS to pitot
dt=gpstime[1:*]-gpstime   ;delta time
psidot=(psi[1:*]-psi)/dt
thetadot=(theta[1:*]-theta)/dt
mpd=111325.0  ;m per degree latitude at equator
up=mpd*(lon[1:*]-lon)/dt * cos(lat*!pi/180) 
vp=mpd*(lat[1:*]-lat)/dt

IF vn300.ioerror eq 0 THEN BEGIN
   print,'***UP and VP override until GPS is fixed ***'
   upold=up
   vpold=vp
   ;NOTE up and vp are backwards in the VN300 data
   vp=extra.velx
   up=extra.vely
ENDIF


course=atan(up,vp) * 180/!pi
bad=where(course lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN course[bad] = course[bad]+360
;psi_course=course * !pi/180   ;Use this as a test case in place of mag_head
;psi=psi_course
tgs=sqrt(up^2+vp^2)   ;Ground speed

;Khelif equations
uwind = up - tas*d * (sin(psi)*cos(theta) + tan(beta)*(cos(psi)*cos(phi) + sin(psi)*sin(theta)*sin(phi)) + $
         tan(alpha)*(sin(psi)*sin(theta)*cos(phi) - cos(psi)*sin(phi))) - $
         ell*(thetadot*sin(theta)*sin(psi)-psidot*cos(psi)*cos(theta))
vwind = vp -tas*d * (cos(psi)*cos(theta) + tan(beta)*(sin(psi)*cos(phi) - cos(psi)*sin(theta)*sin(phi)) + $
         tan(alpha)*(cos(psi)*sin(theta)*cos(phi) - sin(psi)*sin(phi))) - $
         ell*(psidot*sin(psi)*cos(theta) + thetadot*cos(psi)*sin(theta))

;Calculate using the simple approximations in TechNote eq 2.11
uwind2 = up - tas*sin(psi+beta)
vwind2 = vp - tas*cos(psi+beta)

uwind_sm=smooth(uwind,5,nan=nan)
vwind_sm=smooth(vwind,5,nan=nan)
wspd=sqrt(uwind_sm^2 + vwind_sm^2)
wdir=atan(-uwind_sm, -vwind_sm) * 180/!pi
bad=where(wdir lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN wdir[bad] = wdir[bad]+360

uwind2_sm=smooth(uwind2,5,nan=nan)
vwind2_sm=smooth(vwind2,5,nan=nan)
wspd2=sqrt(uwind2_sm^2 + vwind2_sm^2)
wdir2=atan(-uwind2_sm, -vwind2_sm) * 180/!pi
bad=where(wdir2 lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN wdir2[bad] = wdir2[bad]+360
 
;My own simple derivation, using difference between tas and groundspeed
psi=(extra.heading+psi_correct) * !pi/180   ;true heading
utas=tas*sin(psi)
vtas=tas*cos(psi)
uwind3_sm = smooth(up-utas,5,nan=nan)
vwind3_sm = smooth(vp-vtas,5,nan=nan)
wspd3=sqrt(uwind3_sm^2 + vwind3_sm^2)
wdir3=atan(-uwind3_sm, -vwind3_sm) * 180/!pi
bad=where(wdir3 lt 0, nbad)       ;Get range to 0:360, rather than -180:180
IF nbad gt 0 THEN wdir3[bad] = wdir3[bad]+360

etime=time-time[0]  ;elapsed time

;stop
IF noplot eq 0 THEN BEGIN
   ;Compare to RainMaker wind  ** matches pretty well
   !p.multi=[0,1,4,0,0]
   !p.charsize=1.5
   window,2,xsize=900,ysize=800
   etime_hires=fin.time-fin.time[0]
   cgplot,etime,wspd,ytitle='Wind Speed (m/s)',xtitle='Elapsed Time (s)',/xstyle  ;Had wind.wspd here, but no longer computed
   cgoplot,etime,wspd,color='red'
   cgoplot,etime,wspd2,color='green'
   cgoplot,etime,wspd3,color='blue'

   cgplot,etime,wdir,ytitle='Wind Direction (deg)',psym=16,symsize=0.5,xtitle='Elapsed Time (s)',/xstyle
   cgoplot,etime,wdir,color='red',psym=16,symsize=0.5
   cgoplot,etime,wdir2,color='green',psym=16,symsize=0.5
   cgoplot,etime,wdir3,color='blue',psym=16,symsize=0.5

   cgplot,etime, tgs,title='TGS, TAS(red)',yr=[0,50],/xstyle
   cgoplot,etime,tas,color=250

   cgplot, etime,course, title='Course, Mag_head(red)',/xstyle
   cgoplot,etime, extra.heading+psi_correct,color=250

   ;plot,wdir,title='wind dir'
   ;plot,psi*180/!pi,color=200,title='heading'
   ;write_png,'wind_comparison_flight1.png',reverse(tvrd(/true),3)
ENDIF

good=where(tas gt 10)  ;Only use in-air points for calucations
mean_wind=mean(wspd3[good],/nan)
mean_heading=mean(sin(psi[good]), /nan)
mean_course=mean(sin(course[good]*!pi/180),/nan)
corr=correlate(tgs[good],wspd3[good])
udl=total(up[good] * uwind3_sm[good], /nan)
vdl=total(vp[good] * vwind3_sm[good], /nan)
wind_std=stddev(wspd3[good],/nan)
wdir_std=stddev(wdir3[good],/nan)

IF noplot eq 0 THEN BEGIN
   window,3,xsize=900,ysize=800
   !p.multi=[0,1,3,0,0]
   !p.charsize=3
   cgplot,etime,wspd,ytitle='Wind Speed (m/s)',xtitle='Elapsed Time (s)',color='red',yr=[0,20],/xstyle
   cgoplot,etime,wspd2,color='green'
   cgoplot,etime,wspd3,color='blue'
   cgplot,etime,wdir,ytitle='Wind Direction (deg)',psym=16,symsize=0.5,xtitle='Elapsed Time (s)',color='red',/xstyle
   cgoplot,etime,wdir2,color='green',psym=16,symsize=0.5
   cgoplot,etime,wdir3,color='blue',psym=16,symsize=0.5 
   cgplot,etime, tgs,ytitle='GroundSpeed, TAS(red)',yr=[0,50],xtitle='Elapsed Time (s)',/xstyle
   cgoplot,etime,tas,color='red'

   window,4,xsize=900,ysize=800
   !p.multi=[0,1,3,0,0]
   cgplot,etime,theta*180/!pi,ytitle='Pitch (deg)',xtitle='Elapsed Time (s)',color='red',/xstyle
   cgplot,etime,phi*180/!pi,ytitle='Roll (deg)',xtitle='Elapsed Time (s)',color='red',/xstyle
   cgplot,etime,(extra.heading+36000) mod 360,ytitle='Heading(red)/Course (deg)',xtitle='Elapsed Time (s)',color='red',psym=16,symsize=0.5,yr=[0,400],/xstyle   
   cgoplot,etime,course,psym=16,symsize=0.5
ENDIF

return,{time:time, mean_wind:mean_wind, mean_heading:mean_heading, mean_course:mean_course, corr:corr, udl:udl, vdl:vdl, up:up, vp:vp, $
          course:course, truehead:psi*180/!pi, udl_all:up[good] * uwind3_sm[good], vdl_all:vp[good] * vwind3_sm[good],$
            tas:tas, tgs:tgs, wspd:wspd, wdir:wdir, wind_std:wind_std, wdir_std:wdir_std, lat:lat, lon:lon, uwind:uwind, vwind:vwind, $
            aoa:fin.aoa_deg, ss:fin.x24v_monitorextra:extra}
END
