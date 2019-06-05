script "GraphMaker"

-- GraphMaker Library
-- make a graph / chart
constant kLibraryName = "GraphMaker"
constant kLibraryVersion = 0.1

local sADefaults, sAMarkers
local sAG  -- array holding graph-related calculated values
local sCountG, sCountT

-- XRangeIncludes - list of x values to be included (overall, only shared)
-- XFit - round limits to multiple of this

-- YRangeIncludes, YFit - same for Y
-- YRightRangeIncludes, YRightFit - same for Y on right
-- ?? XTopRangeIncludes, XTopFit - same for Y on right

-- DataIncludesX - T/F to say if ALL datasets contain X values (otherwiae, count them)
--               - startvalue, step value (0,1 == True)

-- Title - a title
--   etc.
-- XGridInterval - gap (in data units) between vertical grid lines (i.e. for X valuea)
--      set to 0 (default) or no grid
-- ?? XGridMinor - number of minor grids per major grid
-- ??     set to 0 (default) for no minor grid
-- XTickInterval - same as XGridInterval, but for ticks. 
--      0 = no axis at all, empty = (default) axis but no tick

-- YGridInterval, YGridMinor, YTickInterval - as X
-- YRGridInterval, YRGridMinor, YRTickInterval - as X for right side
-- ?? XTGridInterval, XTGridMinor, XTTickInterval - as X for top side

-- backgroundcolor - colour for background

-- Hints .... TODO

-- Data - 
-- each dataset has
--  name (currently not used)
--  YRaxis - TRUE means use the Right axis for scaling, etc.
--  allowColonDel - (default TRUE) replace ":" with CR (set FASLE if there are ':'s in labels )
--  values - lines of values, [X,]y1,y2,y3

----------------------------------------------------------------------
--| handler gmSetCustomMarker  
--|
--| Summary: create a custom marker
--|
--| Format:  gmSetCustomMarker pName, pPoints, pFilled 
--|
--| Parameters: pName - name for this marker
--|             pPoints - coords of the marker (t -> markersize)
--|             pFilled - where the marker should be filled (default TRUE)
--|
--| Return: nothing 
----------------------------------------------------------------------
on gmSetCustomMarker pName, pPoints, pFilled
   if pFilled is empty then put TRUE into pFilled
   if pName is among the keys of sAMarkers then
      put empty into sAMarkers[pName]
   end if
   put pFilled into sAMarkers[pName]["filled"]
   replace ":" with CR in pPoints
   put pPoints into sAMarkers[pName]["points"]
   --      if pLineSize is empty then put sADefaults["linesize"] into pLineSize
   --      put pLineSize into sAMarkers[pName]["linesize"]
   
end gmSetCustomMarker


----------------------------------------------------------------------
--| handler gmMakeGraph  
--|
--| Summary: make a graph / chart
--|
--| Format:  gmMakeGraph(pGrpId, pArray)
--|
--| Parameters: pString
--|
--| Return: nothing very much !?!
----------------------------------------------------------------------
function gmMakeGraph pId, pAG
   
   local temp
   local tName, tID
   
   local tRect    -- the rectangle of the (given) group
   put the rect of pId into tRect
   logInfo "rect = " && tRect && the number of controls of pID
   
   _gmCreateDefaults
   
   put empty into sAG 
   
   -- make ourselves a group to hold all our controls
   put _gmCreateGraph(pID) into temp
   put temp into pID
   set the vis of pID to TRUE
   set the rect of pID to tRect
   set the lockLoc of pID to TRUE
   
   -- temp variables to work out the range of data
   -- these will be stored into the sAG array when we're done
   local Xmin, Xmax, Ymin, Ymax, YRmin, YRmax
   
   put empty into Xmin
   put empty into Ymin
   put empty into YRmin
   
   local tX, tStart, tStep
   _gmInsertXValues pAG, tX, tStart, tStep
   
   --   repeat for each key K in pAG["data"]
   repeat with K = 1 to the number of lines in the keys of pAG["data"]
      put pAG["data"][K]["values"] into temp
      if pAG["allowColonDel"] is FALSE OR pAG["data"][K]["allowColonDel"] is FALSE then
      else
         replace ":" with CR in temp
      end if
      if pAG["DataIncludesX"] then
         put temp into sAG[K]["values"]
      else
         put tStart into tX
         repeat for each line L in temp
            put tX & COMMA & L & CR after sAG[K]["values"]
            add tStep to tX
         end repeat
      end if
      
      put firstOf(Xmin, item 1 of sAG[K]["values"]) into Xmin
      if pAG["data"][K]["YRaxis"] then
         put firstOf(YRmin, item 2 of line 1 of sAG[K]["values"]) into YRmin
      else
         put firstOf(Ymin, item 2 of line 1 of sAG[K]["values"]) into Ymin
      end if
   end repeat
   
   put Xmin into Xmax
   put Ymin into Ymax
   put YRmin into YRmax
   
   includeInRange Xmin, Xmax, pAG["XRangeIncludes"]
   includeInRange Ymin, Ymax, pAG["YRangeIncludes"]
   includeInRange YRmin, YRmax, pAG["YRRangeIncludes"]
   
   -- TODO offset for non-zero Ymin !!!
   
   -- Find Min / Max values
   local Yminthis, Ymaxthis
   repeat for each key K in sAG
      if K is not a number then next repeat
      if pAG["data"][K]["graphType"] ends with "labels" then next repeat
      -- get its min, max Y values
      put item 2 of line 1 of sAG[K]["values"] into Yminthis
      put Yminthis into Ymaxthis
      repeat for each line L in sAG[K]["values"]
         put min(item 1 of L, Xmin) into Xmin
         put max(item 1 of L, Xmax) into Xmax
         repeat for each item II in item 2 to -1 of L
            put min(II, Yminthis) into Yminthis
            put max(II, Ymaxthis) into Ymaxthis
         end repeat
      end repeat
      put Yminthis, Ymaxthis into sAG[K]["Yminmax"]
      if pAG["data"][K]["YRaxis"] then
         put min(Yminthis, YRmin) into YRmin
         put max(Ymaxthis, YRmax) into YRmax
      else
         put min(Yminthis, Ymin) into Ymin
         put max(Ymaxthis, Ymax) into Ymax
      end if
   end repeat
   
   -- 
   if pAG["XFit"] > 0 then
      put pAG["XFit"] * (Xmin div pAG["XFit"]) into Xmin
      put pAG["XFit"] * ceil(Xmax / pAG["XFit"]) into Xmax         
   end if
   
   if pAG["data"][K]["YRaxis"] then
      if pAG["YRightFit"] > 0 then
         put pAG["YRightFit"] * (YRmin div pAG["YRightFit"]) into YRmin
         put pAG["YRightFit"] * ceil(YRmax / pAG["YRightFit"]) into YRmax
      end if
   else
      if pAG["YFit"] > 0 then
         put pAG["YFit"] * (Ymin div pAG["YFit"]) into Ymin
         put pAG["YFit"] * ceil(Ymax / pAG["YFit"]) into Ymax         
      end if
   end if
   
   if pAG["XUnit"] is empty then
      if pAG["graphtype"] = "bar" then
         put sADefaults["XUnit"] into sAG["XUnit"]
      else
         repeat with K = 1 to the number of lines in the keys of pAG["data"] 
            if pAG["data"][K]["Graphtype"] = "bar" then
               put sADefaults["XUnit"] into sAG["XUnit"]
               exit repeat
            end if
         end repeat
      end if
   else
      put pAG["XUnit"] into sAG["XUnit"]
   end if
   
   subtract sAG["XUnit"] / 2 from Xmin
   add sAG["XUnit"] / 2 to Xmax
   
   logInfo "min/max X" && Xmin && Xmax && "Y" && Ymin && YMax
   
   -- set up the drawing area co-ords
   -- will account for legend, title, labels on axes, etc.
   
   local tGraphRect   -- rectangle for actual drawing
   put item 1 of tRect+10, item 2 of tRect+10, item 3 of tRect-10, item 4 of tRect-10 into tGraphRect
   add pAG["Lmargin"] to item 1 of tGraphRect
   add pAG["Tmargin"] to item 2 of tGraphRect
   subtract pAG["Rmargin"] from item 3 of tGraphRect
   subtract pAG["Bmargin"] from item 4 of tGraphRect
   
   put makeTitles (pID, pAG, tGraphRect) into temp
   put temp into tGraphRect
   
   --   pID, pLabelName, pNum, pPosition, pFormatFunction
   if pAG["YTickLabelSpacing"] <> 0 then
      put findSpaceForAxisLabels(pID, "YaxisLabel", Ymax, 6, pAG["YAxisLabelFormat"]) into temp
      add item 1 of temp to item 1 of tGraphRect
   end if
   
   if pAG["XTickLabelSpacing"] <> 0 then
      put findSpaceForAxisLabels(pID, "XaxisLabel", Xmax, 5, pAG["XAxisLabelFormat"]) into temp
      subtract item 2 of temp from item 4 of tGraphRect
   end if
   
   -- base of actual drawing area
   put item 1 of tGraphRect into sAG["XBase"]
   put item 4 of tGraphRect into sAG["YBase"]
   put item 4 of tGraphRect into sAG["YRBase"]
   
   put Xmin into sAG["Xmin"]
   put Xmax into sAG["Xmax"]
   put Ymin into sAG["Ymin"]
   put Ymax into sAG["Ymax"]
   put YRmin into sAG["YRmin"]
   put YRmax into sAG["YRmax"]
   
   
   -- set up scaling
   local  t1, t2
   
   put  (item 3 of tGraphRect-10) - (item 1 of tGraphRect+10) into t1
   put  (Xmax - Xmin) into t2
   if t2 <> 0 then put t1 / t2 into sAG["XS"]
   
   put  (item 4 of tGraphRect-10) - (item 2 of tGraphRect+10) into t1
   put  (Ymax - Ymin) into t2
   if t2 <> 0 then put t1 / t2 into sAG["YS"]
   
   put  (YRmax - YRmin) into t2
   if t2 <> 0 then put t1 / t2 into sAG["YRS"]
   
   --   put _scalexy(Xmin, YMin) into temp
   --   put _scalexy(Xmax, YMax) into temp
   
   makeXAxis pID, pAG
   makeYAxis pID, pAG
   
   local tGraphType
   
   local tPoints
   
   repeat with K = 1 to the number of lines in the keys of pAG["data"] 
      
      put firstOf(pAG["data"][K]["graphtype"], pAG["graphtype"], "line") into tGraphType
      switch tGraphType
         case "scatter"
            put TRUE into pAG["data"][K]["invisible"]
            put firstOf(pAG["data"][K]["marker"], "star") into pAG["data"][K]["marker"]
            -- and fall through - it's now just any old line chart
            
            -- simple line graph
         case "line"
         case "step"
            local tFilled
            put firstOf(pAG["data"][K]["Filled"], pAG["Filled"], "line") into tFilled
            
            put _scaledataset(sAG[K]["values"], pAG["data"][K]["YRAxis"]) into sAG[K]["XY"]
            put empty into tPoints
            
            repeat with i = 2 to the number of items in line 1 of sAG[K]["XY"]
               put _gmCreategrc(K & "_" & I, pID) into tName
               
               repeat for each line L in sAG[K]["XY"]
                  if pAG["data"][K]["graphtype"] = "step" then
                     local tHorizontalFirst
                     put firstOf(pAG["data"][K]["HorizontalFirst"], pAG["HorizontalFirst"]) into tHorizontalFirst
                     
                     if tPoints is empty then
                        put item 1 of l & comma & item i of L &CR after tPoints
                     else
                        if tHorizontalFirst then
                           put item 1 of L & comma & item i of line -1 of tPoints &CR after tPoints
                           put item 1 of L & comma & item i of L &CR after tPoints
                        else
                           put item 1 of line -1 of tPoints & comma & item i of L &CR after tPoints
                           put item 1 of l & comma & item i of L &CR after tPoints
                        end if
                     end if
                  else
                     put item 1 of l & comma & item i of L &CR after tPoints
                     if pAG["data"][K]["invisible"] then put CR after tPoints
                  end if
                  
               end repeat
               
               local tLineNumber, t
               put i-1 into tLineNumber
               
               if tFilled then
                  put _gmGetColor(pAG, "fillcolor", K, i-2) into temp
                  set the backgroundColor of tName to temp
                  set the opaque of tName to TRUE
                  local tXO, tYO
                  put _scalexy(0,0) into temp
                  put item 1 of temp into tXO
                  put item 2 of temp into tYO
                  put item 1 of line -1 of tPoints & COMMA & \-- X of last point
                        tYO & CR \
                        after tPoints
                  put item 1 of line 1 of tPoints & COMMA & \-- X of last point
                        tYO & CR \
                        after tPoints
                  put item 1 of line 1 of tPoints & COMMA & \-- X of first point
                        item i of line 1 of tPoints &CR \ -- Y of first point
                        after tPoints
               end if
               set the points of tName to tPoints
               set the style of tName to "polygon" -- NOT line - we need markers
               
               put _gmGetColor(pAG, "color", K, i-2) into temp
               set the foregroundColor of tName to temp
               
               put firstOf(pAG["data"][K]["lineSize"], pAG["lineSize"], sADefaults["linesize"]) into temp
               put max(tLineNumber, the number of lines in temp) into t
               set the lineSize of tName to line t of temp
               
               put firstOf(pAG["data"][K]["blendLevel"], pAG["blendLevel"], 30) into temp
               set the blendLevel of tName to temp
               
               switch
                  case pAG["data"][K]["dashed"] is true
                     put sADefaults["dashed"] into temp
                     break
                  case pAG["data"][K]["dotted"] is true
                     put sADefaults["dotted"] into temp
                     break
                  case pAG["data"][K]["dotdashed"] is true
                     put sADefaults["dotdashed"] into temp
                     break
                  case pAG["data"][K]["dotdashed"] is not empty
                     put pAG["data"][K]["dotdashed"] into temp
                     break
                  case pAG["data"][K]["dotted"] is not empty 
                     put pAG["data"][K]["dotted"] into temp
                     break
                  case pAG["data"][K]["dashed"] is not empty 
                     put pAG["data"][K]["dashed"] into temp
                     break
                  default
                     put empty into temp
               end switch
               if temp is not empty then
                  set the dashes of tName to temp
               end if
               
               local tA
               if pAG["data"][K]["dropshadow"] is not empty then
                  put sADefaults["dropShadow"]  into tA
                  if not pAG["data"][K]["dropshadow"] then
                     repeat for each line L in pAG["data"][K]["dropshadow"]
                        put item 2 to -1 of L into tA[item 1 of L]
                     end repeat
                  end if
                  set the dropshadow of tName to tA
               end if
               
               -- markers
               local tMarkerName
               if pAG["data"][K]["marker"] is not empty then
                  put pAG["data"][K]["marker"] into tMarkerName
                  if tMarkerName is not among the keys of sAMarkers then
                     put "square" into tMarkerName
                  end if
                  put expandMarker(tMarkerName, firstOf(pAG["data"][K]["markersize"], 5)) into temp
                  --                  put sAMarkers[tMarkerName]["points"] into temp
                  --                  replace "t" with firstOf(pAG["data"][K]["markersize"], 5) in temp
                  set the markerpoints of tName to temp
                  set the markerlinesize of tName to 2 -- TODO?? sAMarkers[tMarkerName]["linesize"]
                  set the markerfilled of tName to sAMarkers[tMarkerName]["filled"]
                  put _gmGetColor(pAG, "markercolor", K, i-2) into temp
                  if temp is empty then 
                     put sAMarkers[tMarkerName]["color"] into temp
                  end if
                  set the bordercolor of tName to temp
                  set the hilitecolor of tName to temp
                  set the markerdrawn of tName to TRUE
               end if
               
               --               set the dashes of tName to sAG["dashed"]
               set the vis of tName to TRUE
            end repeat
            break
            
         case "bar"            
            put _scaledataset(sAG[K]["values"], pAG["data"][K]["YRAxis"]) into sAG[K]["XY"]
            put empty into tPoints
            local tAName
            repeat with i = 2 to the number of items in line 1 of sAG[K]["XY"]
               put _gmCreategrc(K & "_" & I, pID) into tAName[i]
            end repeat
            local tAPts, tBase
            repeat for each line L in sAG[K]["XY"]
               repeat with i = 2 to the number of items in line 1 of sAG[K]["XY"]
                  if i = 2 then
                     put _scalexy(sAG["Xmin"], sAG["Ymin"]) into temp
                     put item 2 of temp into tBase
                  else
                     put item -1 of tAPts[i-1] into tBase
                  end if
                  put CR after tAPts[i]
                  put item 1 of L & comma & tBase &CR & \
                        item 1 of L & comma & item i of L &CR after tAPts[i]
                  if line -2 of tAPts[i] is empty then
                     delete line -2 of tAPts[i]
                  end if
                  --                  put item 1 of L & comma & tBase &CR after tAPts[i]
                  --                  put item 1 of L & comma & item i of L &CR after tAPts[i]
                  --                  logInfo i && ":" && the number of lines in tAPts[i]
               end repeat
            end repeat
            repeat with i = 2 to the number of items in line 1 of sAG[K]["XY"]               
               set the points of tAName[i] to tAPts[i]
               set the style of tAName[i] to "line"
               
               put _gmGetColor(pAG, "color", K, i-2) into temp
               set the foregroundColor of tAName[i] to temp
               
               put firstOf(pAG["barDensity"], sADefaults["barDensity"]) into t
               put sAG["XUnit"] * sAG["XS"] * t / 100 into temp
               set the lineSize of tAName[i] to temp
               set the capStyle of tAName[i] to "butt"
               
               set the vis of tAName[i] to TRUE
            end repeat
            break
            
            local tString
         case "XTickLabels"            
            local tY
            repeat for each line L in sAG[K]["values"]
               put _scalexy(item 1 of L, sAG["YMin"]) into temp
               put item 1 of temp into tX
               put item 2 of temp into tY
               -- NB do not format - this graphtype already has explicit labels
               -- put formatLabel(item 2 of L, pAG["XAxisLabelFormat"]) into tString
               put formatLabel(item 2 of L, empty) into tString
               put _gmCreateText(pID, tString, tX, tY,\
                     5, FALSE, \
                     empty, \ -- the name for this control
                     empty, \ -- the text info for it
                     "XAxisLabel") \-- the name for any default settings
                     into temp
               put item 1 of temp into tName
               put _gmGetColor(pAG, "color", K, i-2) into temp
               set the foregroundColor of tName to temp
               set the vis of tName to TRUE
            end repeat
            break
            
         case "YTickLabels"            
            repeat for each line L in sAG[K]["values"]
               put _scalexy(sAG["XMin"], item 2 of L) into temp
               put item 1 of temp into tX
               put item 2 of temp into tY
               -- NB do not format - this graphtype already has explicit labels
               -- put formatLabel(item 3 of L, pAG["YAxisLabelFormat"]) into tString
               put formatLabel(item 3 of L, empty) into tString
               
               put _gmCreateText(pID, tString, tX, tY,\
                     6, FALSE, \
                     empty, \ -- the name for this control
                     empty, \ -- the text info for it
                     "YAxisLabel") \-- the name for any default settings
                     into temp
               put item 1 of temp into tName
               put _gmGetColor(pAG, "color", K, i-2) into temp
               set the foregroundColor of tName to temp
               set the vis of tName to TRUE
            end repeat
            break
            
      end switch
      
   end repeat
   
   put empty into t1
   
end gmMakeGraph

-- not normally user-called, but can be in odd cases
on _gmCreateDefaults
   local temp
   
   put "20,20" into sADefaults["dashed"]
   put "2,10" into sADefaults["dotted"]
   put "12,8,2,8" into sADefaults["dotdashed"]
   
   local tDropShadow
   put "255,0,0" into tDropShadow["color"]
   put "normal" into tDropShadow["blendmode"]
   put 255 into tDropShadow["opacity"]
   put "box1pass" into tDropShadow["filter"]
   put 6 into tDropShadow["size"]
   put 100 into tDropShadow["spread"]
   put 3 into tDropShadow["distance"]
   put 45 into tDropShadow["angle"]
   put tDropShadow into sADefaults["dropshadow"]
   
   put 1 into sADefaults["hints"]["YtickInterval"]["Guess"]
   put 20 into sADefaults["hints"]["YtickInterval"]["min"]
   put 200 into sADefaults["hints"]["YtickInterval"]["max"]
   put 5 into sADefaults["hints"]["YtickInterval"]["mult"]
   put sADefaults["hints"]["YtickInterval"] into sADefaults["hints"]["XtickInterval"]
   put sADefaults["hints"]["YtickInterval"] into sADefaults["hints"]["YRtickInterval"]
   
   put 1 into sADefaults["hints"]["YTickLabelSpacing"]["Guess"]
   put 100 into sADefaults["hints"]["YTickLabelSpacing"]["min"]
   put 500 into sADefaults["hints"]["YTickLabelSpacing"]["max"]
   put 2.5 into sADefaults["hints"]["YTickLabelSpacing"]["mult"]
   put 140 into sADefaults["hints"]["YTickLabelSpacing"]["Target"]
   put sADefaults["hints"]["YTickLabelSpacing"] into sADefaults["hints"]["XTickLabelSpacing"]
   put sADefaults["hints"]["YTickLabelSpacing"] into sADefaults["hints"]["YRTickLabelSpacing"]
   
   
   
   
   
   put 2 into sADefaults["linesize"]
   
   put "255,0,0:0,255,0:0,0,255:255,255,0:255,0,255:0,255,255:200,200,200" into temp
   replace ":" with CR in temp
   put temp into sADefaults["colors"]
   replace 255 with 128 in temp
   replace 200 with 100 in temp
   put temp into sADefaults["fillcolors"]
   
   put "0,255,0:0,0,255:255,255,0:255,0,255:0,255,255:200,200,200:255,0,0" into temp
   replace ":" with CR in temp
   put temp into sADefaults["markercolors"]
   replace 255 with 128 in temp
   replace 200 with 100 in temp
   put temp into sADefaults["markerfillcolors"]
   
   -- put empty into sAMarkers  -- Don't empty it, just redefine the ones we need
   gmSetCustomMarker "square", \
         "-t,-t:-t,t:t,t:t,-t"
   gmSetCustomMarker "star", \
         "-t,-t:t,t::-t,t:t,-t", FALSE
   gmSetCustomMarker "diamond", \
         "0,t:t,0:0,-t:-t,0"
   gmSetCustomMarker "triangle", \
         "-t,t:t,t:0,-t"
   
   put 5 into sADefaults["markersize"]
   
   -- TextStyle is  color CR Size CR Style CR Name
   put "color,0,0,0:textsize,24:textstyle,bold" into temp
   split temp by ":" and COMMA
   put temp into sADefaults["TitleTextInfo"]
   
   put "color,0,0,0:size,18" into temp
   split temp by ":" and COMMA
   put temp into sADefaults["XTitleTextInfo"]
   put temp into sADefaults["YTitleTextInfo"]
   put temp into sADefaults["YRTitleTextInfo"]
   
   put "color,0,0,0:size,12" into temp
   split temp by ":" and COMMA
   put temp into sADefaults["LabelTextInfo"]
   
   put 1 into sADefaults["XUnit"]
   put 75 into sADefaults["barDensity"]
end _gmCreateDefaults

-- private handlers for internal use
command makeYAxis pID, pAG
   local tPoints
   -- draw a Y axis, if needed
   if pAG["YTickInterval"] = 0 then 
      exit makeYAxis
   end if
   
   local tName
   put _gmCreateGRC("Y_Axis", pID) into tName
   set the style of tName to "line"
   
   put _scalexy(sAG["Xmin"], sAG["Ymin"]) &CR into tPoints
   put _scalexy(sAG["Xmin"], sAG["Ymax"]) &CR after tPoints
   
   adaptTickSettings pAG, "YTick", sAG["YS"], sAG["Ymax"]-sAG["Ymin"]
   
   local temp
   if sAG["YTickInterval"] > 0 then
      local tBase, tY
      put sAG["YTickInterval"] * (sAG["Ymin"] div sAG["YTickInterval"]) into tBase
      repeat with i = tBase to sAG["Ymax"] step sAG["YTickInterval"]
         if i > sAG["Ymax"]  then 
            --            logInfo "exiting repeat" && i && Ymax
            exit repeat
         end if
         put i into tY
         if tY < sAG["Ymin"] then put sAG["Ymin"] into tY
         put CR after tPoints
         put _scalexy(sAG["Xmin"], tY) into temp
         put temp & CR after tPoints
         add 10 to item 1 of temp
         put temp & CR after tPoints
         --         logInfo "Y tick" && sAG["Xmin"] && i && sAG["YTickInterval"] && line -1 of tPoints
      end repeat
   end if
   
   
   if sAG["YTickLabelspacing"] > 0 then
      repeat with i = tBase to sAG["Ymax"] step sAG["YTickLabelspacing"] * sAG["YTickInterval"]
         if i > sAG["Ymax"]  then 
            --            logInfo "exiting repeat" && i && Ymax
            exit repeat
         end if
         put i into tY
         if tY < sAG["Ymin"] then put sAG["Ymin"] into tY
         put _scalexy(sAG["Xmin"], tY) into temp
         put formatLabel(tY, pAG["YAxisLabelFormat"]) into tY
         put _gmCreateText(pID, tY, item 1 of temp, item 2 of temp,\
               6, FALSE, \
               empty, \ -- the name for this control
               empty, \ -- the text info for it
               "YAxisLabel") \-- the name for any default settings
               into temp
         --         logInfo "Y label" && temp && sAG["YTickLabelspacing"] && line -1 of tPoints
         local tt
         put item 1 of temp into tt
         set the vis of tt to TRUE
      end repeat
   end if
   
   if sAG["YGridInterval"] > 0 then
      repeat with i = tBase to sAG["Ymax"] step sAG["YGridInterval"] * sAG["YTickInterval"]
         if i > sAG["Ymax"]  then 
            exit repeat
         end if
         put i into tY
         if tY < sAG["Ymin"] then put sAG["Ymin"] into tY
         put CR after tPoints
         put _scalexy(sAG["Xmin"], tY) & CR after tPoints
         put _scalexy(sAG["Xmax"], tY) & CR after tPoints
      end repeat
   end if
   set the points of tName to tPoints
   set the vis of tName to TRUE
   
end makeYAxis

-- private handlers for internal use
command makeXAxis pID, pAG
   local tPoints
   -- draw an X axis, if needed
   if pAG["XTickInterval"] < 0 then 
      exit makeXAxis
   end if
   
   local tName
   put _gmCreateGRC("X_Axis", pID) into tName
   set the style of tName to "line"
   
   put _scalexy(sAG["Xmin"], sAG["Ymin"]) &CR into tPoints
   put _scalexy(sAG["Xmax"], sAG["Ymin"]) &CR after tPoints
   
   
   adaptTickSettings pAG, "XTick", sAG["XS"], sAG["Xmax"]-sAG["Xmin"]
   
   local temp, tBase, tX
   if sAG["XTickInterval"] > 0 then
      put sAG["XTickInterval"] * (sAG["Xmin"] div sAG["XTickInterval"]) into tBase
      repeat with i = tBase to sAG["Xmax"] step sAG["XTickInterval"]
         if i > sAG["Xmax"]  then 
            --            logInfo "exiting repeat" && i && Ymax
            exit repeat
         end if
         put i into tX
         if tX < sAG["Xmin"] then put sAG["Xmin"] into tX
         put CR after tPoints
         put _scalexy(tX, sAG["Ymin"]) into temp
         put temp & CR after tPoints
         add -10 to item 2 of temp
         put temp & CR after tPoints
      end repeat
   end if
   set the points of tName to tPoints
   set the vis of tName to TRUE
   
   if sAG["XTickLabelspacing"] > 0 then
      repeat with i = tBase to sAG["Xmax"] step sAG["XTickLabelspacing"] * sAG["XTickInterval"]
         if i > sAG["Xmax"]  then 
            exit repeat
         end if
         put i into tX
         if tX < sAG["Xmin"] then put sAG["Xmin"] into tX
         put _scalexy(tX, sAG["Ymin"]) into temp
         put formatLabel(tX, pAG["XAxisLabelFormat"]) into tX
         put _gmCreateText(pID, tX, item 1 of temp, item 2 of temp,\
               5, FALSE, \
               empty, \ -- the name for this control
               empty, \ -- the text info for it
               "XAxisLabel") \-- the name for any default settings
               into temp
         local tt
         put item 1 of temp into tt
         set the vis of tt to TRUE
      end repeat
   end if
   
   if sAG["XGridInterval"] > 0 then
      repeat with i = tBase to sAG["Xmax"] step sAG["XGridInterval"] * sAG["XTickInterval"]
         if i > sAG["Xmax"]  then 
            exit repeat
         end if
         put i into tX
         if tX < sAG["Xmin"] then put sAG["Xmin"] into tX
         put CR after tPoints
         put _scalexy(tX, sAG["Ymin"]) & CR after tPoints
         put _scalexy(tX, sAG["Ymax"]) & CR after tPoints
      end repeat
   end if
   set the points of tName to tPoints
   set the vis of tName to TRUE
   
   
end makeXAxis

on _gmInsertXValues pAG, @pX, @pStart, @pStep
   switch pAG["DataIncludesX"]
      case TRUE
         break
         
      case empty
         put 0 into pStart
         put 1 into pStep
         break
         
      default
         if item 1 of pAG["DataIncludesX"] is a number then
            put item 1 of pAG["DataIncludesX"] into pX
            if item 2 of pAG["DataIncludesX"] is a number then
               put item 1 of pAG["DataIncludesX"] into pStep
            else
               put 1 into pStep
            end if
         else
            put 0 into pStart
            put 1 into pStep
         end if
         if pStep = 0 then
            put 1 into pStep
         end if
         break
   end switch
end _gmInsertXValues



----------------------------------------------------------------------
--| handler _gmCreateGraph  
--|
--| Summary: re-create the controls for a graph (i.e. can be called once only)
--|
--| Format:  _gmCreateGraph(pGrpId)
--|
--| Parameters: pGrpID - long id of the group to contain the controls
--|
--| Return: the long ID of the created group
----------------------------------------------------------------------
function _gmCreateGraph pId
   logInfo "pID = " && pID
   local temp, tName
   if there is a grp "GraphGroup" of pID then
      delete grp "GraphGroup" of pID 
   end if
   create invisible grp "GraphGroup" in pID 
   put the long ID of grp "GraphGroup" of pID into pID
   
   put 0 into sCountG -- counts of Grapchics, Ttiles, etc.
   put 0 into sCountT
   
   return pID
end _gmCreateGraph

private function _scaledataset pData, pRAxis
   local temp, t
   repeat for each line L in pData
      put sAG["Xbase"] + sAG["XS"] * (item 1 of L - sAG["Xmin"]) after temp
      repeat for each item II in item 2 to -1 of L
         put II into t
         put comma after temp
         if pRAxis is empty then
            put sAG["Ybase"] - sAG["YS"] * (II - sAG["Ymin"]) after temp
         else
            put sAG["YRbase"] - sAG["YRS"] * (II - sAG["YRmin"]) after temp
         end if
      end repeat
      put CR after temp
   end repeat
   return temp
end _scaledataset

private function _scalexy px, py, pRAxis
   local temp
   put sAG["Xbase"] + sAG["XS"] * (px - sAG["Xmin"]) into temp
   put comma after temp
   if pRAxis is empty then
      put sAG["Ybase"] - sAG["YS"] * (py - sAG["Ymin"]) after temp
   else
      put sAG["Ybase"] - sAG["YRS"] * (py - sAG["YRmin"]) after temp
   end if
   return temp
end _scalexy

private function _gmCreateGRC pName, pID
   local tName
   create invisible graphic ("G_" & pName) in pID
   put "grc " & q("G_" & pName) & " of " & pID into tName
   return tName
end _gmCreateGRC

function _gmCreateText pID, pText, pX, pY, pPosition, pRot, pName, pTextInfo, pTextName
   -- pPosition is 1...4 corner TL, TR, BT=R, BL
   --              5...8 mid-line T,R,B,L
   --              0/empty     centre
   if pPosition is empty then put 0 into pPosition
   replace ":" with CR in pTextInfo
   
   local tName
   if pName is empty then
      put "T_" & sCountT into pName
      add 1 to sCountT
   end if
   
   create invisible fld (pName) in pID
   put "fld " & q(pName) & " of " & pID into tName
   set the showborder of tName to FALSE
   set the opaque of tName to FALSE
   
   -- TextStyle is  color CR Size CR Style CR Name
   local temp, tADefaultTextInfo
   put sADefaults[pTextName & "TextInfo"] into tADefaultTextInfo
   replace ":" with CR in pTextInfo
   split pTextInfo by CR and COMMA
   put combineArrays(pTextInfo, tADefaultTextInfo) into pTextInfo
   put pTextInfo["color"] into temp
   if temp is not empty then
      set the foregroundcolor of tName to temp
   end if
   put pTextInfo["textsize"] into temp
   if temp is not empty then
      set the textsize of tName to temp
   end if
   put pTextInfo["textstyle"] into temp
   if temp is not empty then
      set the textStyle of tName to temp
   end if
   put pTextInfo["textfont"]  into temp
   if temp is not empty then
      set the textfont of tName to temp
   end if
   
   set the text of tName to pText
   
   -- now let's make it easy to work out sizes / position
   local tW2, tH2, tX, tY
   --   logInfo "fw before" && the formattedwidth of tName  && the formattedheight of tName 
   
   --   set the width of tName to the formattedwidth of tName
   set the width of tName to 4000
   set the width of tName to the formattedwidth of tName
   set the height of tName to the formattedheight of tName
   --   logInfo "fw" && the formattedwidth of tName  && the formattedheight of tName 
   put the formattedwidth of tName / 2 into tW2
   put the formattedheight of tName / 2 into tH2
   
   -- set X (for the loc of the field)
   if pPosition is among the items of "1,4,8" then put 10+tW2 into tX
   if pPosition is among the items of "2,3,6" then put -(tW2+10) into tX
   if pPosition is among the items of "0,5,7" then put 0 into tX
   -- set Y
   if pPosition is among the items of "1,2,5" then put 10+tH2 into tY
   if pPosition is among the items of "8,0,6" then put 0 into tY
   if pPosition is among the items of "3,4,7" then put -(tH2+10) into tY
   
   set the loc of tName to pX+tX, pY+tY
   return tName, the width of tName+20, the height of tName+20
end _gmCreateText


private function _gmGetColor pAG, pName, pNumber, pOffset
   local temp, tReturn, tNum
   put firstOf(pAG["data"][pNumber][pName], pAG[pName] ) into tReturn
   if tReturn is empty then
      put firstOf(sADefaults[pName], \
            sADefaults[pName & "s"], \
            sADefaults["colors"]) into temp
      put (pNumber-1+pOffset) mod the number of lines in temp into tNum
      put line (tNum+1) of temp into tReturn
   end if
   return tReturn
end _gmGetColor


-- things that would normally be in a common library
private command logInfo p
   put p &CR after msg
end logInfo

private function q p
   return quote & p & quote
end q

private function firstOf
   local temp
   repeat with i = 1 to paramcount()
      put param(i) into temp
      if temp is not empty then exit repeat
   end repeat
   return temp
end firstOf

private function combineArrays 
   local tAReturn, tA
   repeat with I = paramcount() down to 1
      put param(i) into tA
      repeat for each key K in tA
         put tA[K] into tAReturn[K]
      end repeat
   end repeat
   return tAReturn
end combineArrays

private function findSpaceForAxisLabels pID, pLabelName, pNum, pPosition, pFormatFunction
   local temp, tID, tReturn
   put _gmCreateText(pID, pNum, 0, 0,\
         pPosition, FALSE, \
         empty, \ -- the name for this control
         empty, \ -- the text info for it
         pLabelName) \-- the name for any default settings
         into temp
   put item 1 of temp into tID
   local tString
   put formatLabel(pNum, pFormatFunction) into tString
   set the text of tID to tString
   put the formattedwidth of tID & COMMA & the formattedheight of tID into tReturn
   delete tID
   return tReturn
end findSpaceForAxisLabels

private function formatLabel pLabel, pFormatFunction
   local tString
   if pFormatFunction is empty then
      put pLabel into tString
   else
      dispatch pFormatFunction to this card with pLabel
      put the result into tString
   end if
   return tString
end formatLabel

private function makeTitles pID, pAG, pGraphRect
   local temp
   -- Title
   if pAG["Title"] is not empty then
      --      function _gmCreateText pID, pText, pX, pY, pPosition, pRot, pName, pTextSInfo, pTextName
      put _gmCreateText(pID, pAG["title"], \
            (item 1 of pGraphRect + item 3 of pGraphRect) / 2, \
            item 2 of pGraphRect, \
            5, \ -- i.e. we have given middle top
            False, "T_title", \
            pAG["TitleTextInfo"], "Title") into temp
      add item 3 of temp to item 2 of pGraphRect
      local tt
      put item 1 of temp into tt
      set the vis of tt to TRUE
      --      set the vis of item 1 of temp to TRUE
   end if
   -- XTitle
   if pAG["XTitle"] is not empty then
      --      function _gmCreateText pID, pText, pX, pY, pPosition, pRot, pName, pTextSInfo, pTextName
      put _gmCreateText(pID, pAG["XTitle"], \
            (item 1 of pGraphRect + item 3 of pGraphRect) / 2, \
            item 4 of pGraphRect, \
            7, \ -- i.e. we have given middle top
            False, "T_XTitle", \
            pAG["TitleTextInfo"], "Title") into temp
      subtract item 3 of temp from item 4 of pGraphRect
      
      put item 1 of temp into tt
      set the vis of tt to TRUE
      --      set the vis of item 1 of temp to TRUE
   end if
   -- YTitle
   local tPict
   if pAG["YTitle"] is not empty then
      --      function _gmCreateText pID, pText, pX, pY, pPosition, pRot, pName, pTextSInfo, pTextName
      put _gmCreateText(pID, pAG["YTitle"], \
            (item 1 of pGraphRect + item 3 of pGraphRect) / 2, \
            item 4 of pGraphRect, \
            7, \ -- i.e. we have given middle top
            False, "T_YTitle", \
            pAG["TitleTextInfo"], "Title") into temp
      --      export snapshot from item 1 of temp to tPict as PNG
      local tHeight
      put item 3 of temp into tHeight
      add tHeight to item 1 of pGraphRect
      put item 1 of temp into tt
      import snapshot from tt
      local t1, t2, t3
      put it into t1
      copy t1 to pID
      put it into tt
      delete t1
      set the angle of tt to 90
      set the loc of tt to \
            item 1 of pGraphRect - tHeight/2, (item 2 of pGraphRect + item 4 of pGraphRect) / 2
      set the vis of tt to TRUE
      --      set the vis of item 1 of temp to TRUE
   end if
   
   return pGraphRect
end makeTitles

on adaptTickSettings pAG, pTickName, pScale, pPerfect
   -- pPerfect is max possible range for the axis
   local pTickIntervalName, pTickLabelName
   put pTickName & "Interval" into pTickIntervalName
   put pTickName & "LabelSpacing" into pTickLabelName
   
   -- work out an interval for this tick setting if needed
   if pAG[pTickIntervalName] is empty then
      local tMin, tMax, tGuess, tMult, tPerfect
      -- TODO get from defaults or hints
      local tAH1, tAH2
      put pAG["hints"][pTickIntervalName] into tAH1
      put sADefaults["hints"][pTickIntervalName] into tAH2
      put firstOf(tAH1["guess"], tAH2["guess"]) into tGuess
      put firstOf(tAH1["min"], tAH2["min"]) into tMin
      put firstOf(tAH1["max"], tAH2["max"]) into tMax
      put firstOf(tAH1["mult"], tAH2["mult"]) into tMult
      repeat 100 times
         switch
            case tGuess * pScale < tMin 
               put tGuess * tMult into tGuess
               break
            case tGuess * pScale > tMax
               put tGuess / tMult into tGuess
               break
            default
               exit repeat
         end switch
      end repeat
      put tGuess into sAG[pTickIntervalName]
   else
      put pAG[pTickIntervalName] into sAG[pTickIntervalName]
   end if
   
   -- and then work out the labelspacing / grid interval
   local tBest, tBAbs, tBTry, temp
   put 10000 into tBabs
   if pAG[pTickLabelName] > 0 then  -- user has specified a value, use it
      put pAG[pTickLabelName] into sAG[pTickLabelName]
      put pAG[pTickLabelName] into tBest
   else
      -- TODO get from defaults or hints
      put pAG["hints"][pTickLabelName] into tAH1
      put sADefaults["hints"][pTickLabelName] into tAH2
      put firstOf(tAH1["guess"], tAH2["guess"]) into tGuess
      put firstOf(tAH1["min"], tAH2["min"]) into tMin
      put firstOf(tAH1["max"], tAH2["max"]) into tMax
      put firstOf(tAH1["mult"], tAH2["mult"]) into tMult
      put firstOf(tAH1["target"], tAH2["target"]) into tPerfect
      if pPerfect is not empty then
         put min(tPerfect, pPerfect) into tPerfect
         put min(tMin, pPerfect) into tMin
      end if
      
      repeat  for each item II in "1,2,5,10,20,50,100,200,500"
         put II * sAG[pTickIntervalName] * pScale into temp
         if temp > tMin AND temp < tMax then
            put abs(tPerfect - temp) into tBTry
            if tBTry < tBAbs then
               --               logInfo "replacing" && tBest && tBabs && "with" && II && tBtry && "for" && temp
               put II into tBest
               put tBtry into tBabs
            else
               exit repeat
            end if
         end if
      end repeat
      if pAG[pTickLabelName] is empty then
         put tBest into sAG[pTickLabelName]
      else
         -- we don't want tick labels, but we have also calculated tBest which woul dbe right for grid interval
      end if
   end if
   local pGridName
   put char 1 of pTickLabelName & "GridInterval" into pGridName
   if pAG[pGridName] is empty OR pAG[pGridName] = 0 then
      put tBest into sAG[pGridName]
   else
      put pAG[pGridName] into sAG[pGridName]
   end if
   logInfo pTickIntervalName & " : " & sAG[pTickIntervalName]
   logInfo pTickLabelName & " : " & sAG[pTickLabelName]
   
end adaptTickSettings

private command includeInRange @p1, @p2, pList
   repeat for each item II in pList
      put min(II, p1) into p1
      put max(II, p2) into p2
   end repeat
end includeInRange

private function expandMarker pMarkerName, pSize
   local temp, tReturn
   put sAMarkers[pMarkerName]["points"] into temp
   replace ":" with CR in temp
   replace "t" with pSize in temp
   repeat for each line L in temp
      if L is empty then
         put CR after tReturn
      else
         repeat for each item II in L
            put value(II) &COMMA after tReturn
         end repeat
         put CR into char -1 of tReturn
      end if
   end repeat
   return tReturn
   --                  replace "t" with firstOf(pAG["data"][K]["markersize"], 5) in temp
end expandMarker
