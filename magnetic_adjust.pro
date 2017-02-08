;Run a series of magnetic corrections to find the minimum wind
n=360
flightnum=1
adjust=findgen(n)-30
meanwind=fltarr(n)
heading=fltarr(n)
course=fltarr(n)
corr=fltarr(n)
udl=fltarr(n)
vdl=fltarr(n)
wind_stddev=fltarr(n)

print,'Need to delvar fin if changing flight'
for i=0,n_elements(adjust)-1 do begin
out=analyze_fin(flightnum,adjust[i],fin,ahrs,wind,/noplot) ;Fin ahrs wind to avoid re-reading
meanwind[i]=out.mean_wind
heading[i]=out.mean_heading
course[i]=out.mean_course
corr[i]=out.corr
udl[i]=out.udl
vdl[i]=out.vdl
wind_stddev[i]=out.wind_std  ;Standard deviation of wind, should be minimized
if i mod 50 eq 0 THEN print,i
endfor

window,flightnum,xsize=800,ysize=1000
!p.multi=[0,1,5,0,0]
!p.charsize=2
plot,adjust,meanwind,ytit='Mean Wind'
plot,adjust,abs(heading-course),ytit='Head-Course'
plot,adjust,corr,ytit='tgs/wspd Corr'
plot,adjust,udl,ytit='udl vdl'
oplot,adjust,vdl,color=100
plot,adjust,wind_stddev,ytit='Wspd stddev'
end