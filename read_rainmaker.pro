FUNCTION read_rainmaker, fn, id, units=units
   ;Read in 'Rainmaker' data files for plotting
   ;These files have data from all components, AHRS, FIN, VN300, etc.
   ;Input 'id' is the field to read in, 'ahrs', 'fin', etc., as specified in the file header.

   s=''
   close,1
   openr,1,fn

   ;There are some calibration coefficients recorded at top of file, these will be skipped for now

   ;Read in field names
   REPEAT BEGIN
      readf,1,s
      v=str_sep(s,',')
   ENDREP UNTIL (strlowcase(v[0]) eq strlowcase(id)) or (eof(1) eq 1)
   IF eof(1) eq 1 THEN BEGIN
      print,'ID: '+id+', no field information found. Returning.'
      return,-1
   ENDIF
   units=v
   units[0]='time'   ;In the field string this is just component name
   units[1]='id'     ;This is unnamed in the files

   REPEAT readf,1,s UNTIL s eq '******'  ;Data start indicator

   ;Read in everything else

   all=dblarr(1000000,n_elements(units))
   IF units[n_elements(units)-1] eq 'CS' THEN checksum=1 ELSE checksum=0  ;Flag for checksum in use
   i=0L
   REPEAT BEGIN
      readf,1,s
      IF strpos(strlowcase(s), strlowcase(id)) ne -1 THEN BEGIN
         v=str_sep(s,',')
         timestamp=v[0]
         hms=str_sep(timestamp,'_')
         sfm=hms[3]*3600d + hms[4]*60d + hms[5]
         IF i eq 0 THEN date=hms[0]+hms[1]+hms[2]
         IF checksum eq 1 THEN reads, v[-1], checkval, format='(Z)'  ;Klugey way to convert hex to decimal
         
         ;Set the two string fields to floats before stuffing 'all' array
         v[0]=sfm
         v[1]=0.0
         IF checksum eq 1 THEN v[-1]=checkval
         all[i,*]=v
         i=i+1
      ENDIF
   ENDREP UNTIL eof(1)
   close,1
   IF i eq 0 THEN BEGIN
      print,'ID: '+id+', no data found. Returning.'
      return,-1
   END
   all=all[0:i-1,*]   ;Truncate to size

   ;Make a structure
   x={time:reform(all[*,0])}
   FOR i=1,n_elements(units)-1 DO BEGIN
      tagname=strlowcase((str_sep(units[i],' '))[0]) ;Select first word
      tagname=strjoin(str_sep(tagname,'-'))  ;Get rid of dashes
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