FUNCTION read_fin, fn, units=units
  ;Read in FIN data for plotting
  s=''
  close,1
  openr,1,fn
  readf,1,s  ;date
  readf,1,s  ;units
  units=str_sep(s,',')
  ;close,1
  ;for i=0,n_elements(units)-1 do print,i,' ',units[i]

  ;Read in everything else
  
  ;x=read_ascii(fn,data_start=3,delimiter=',')   ;Commented out since reads only single precision float
  ;all=x.field1
  all=dblarr(1000000,n_elements(units))
  i=0L
  REPEAT BEGIN
    readf,1,s
    nextline=str_sep(s,',')
    all[i,*]=nextline
    i=i+1
  ENDREP UNTIL eof(1)
  close,1
  all=all[0:i-1,*]   ;Truncate to size
  
  ;Make a structure
  x={time:reform(all[*,0])}
  FOR i=1,n_elements(units)-1 DO BEGIN
    tagname=strlowcase((str_sep(units[i],' '))[0]) ;Select first word
    tagname=strjoin(str_sep(tagname,'-'))	;Get rid of dashes
    IF units[i] eq 'TAS (m/s)' THEN tagname='TAS'     ;Special cases
    IF units[i] eq 'TAS (kts)' THEN tagname='TAS_knots'
    IF units[i] eq 'P-ALT (ft)' THEN tagname='palt_ft'
    IF units[i] eq 'Time(msec)' THEN tagname='time_milliseconds'
    IF (strmid(tagname,0,1) eq '2') or (strmid(tagname,0,1) eq '8') THEN tagname='x'+tagname
    IF total(strupcase(tagname) eq tag_names(x)) gt 0 THEN tagname=tagname+'_2'
    x=create_struct(x, tagname, reform(all[*,i]))
  ENDFOR
  return,x
END