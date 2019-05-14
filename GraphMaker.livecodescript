script "GraphMaker"

-- GraphMaker Library
-- make a graph / chart
constant kLibraryName = "GraphMaker"
constant kLibraryVersion = 1.1

local sAGraphicGroup

local Xbase, YBase, XS, YS, YLS, YRS

-- XRange - specify min/max in X fro drwing (i.e. ignore values in datasets)
-- XRangeIncludes - list of x values to be included (overall, only shared)
-- XFit - round limits to multiple of this

-- YRange, YRangeIncludes, YFit - same for Y
-- YRightRange, YRightRangeIncludes, YRightFit - same for Y on right

-- Title - a title
--   etc.
-- XGridInterval - gap (in data units) between vertical grid lines (i.e. for X valuea)
--      set to 0 (default) or no grid
-- XGridMinor - number of minor grids per major grid
--      set to 0 (default) for no minor grid
-- XTickInterval - same as XGridInterval, but for ticks. 
--      0 = no axis at all, empty = (default) axis but no tick

-- YGridInterval, YGridMinor, YTickInterval - as X
-- YRGridInterval, YRGridMinor, YRTickInterval - as X for right side
-- XTGridInterval, XTGridMinor, XTTickInterval - as X for top side


-- Data - 
-- each dataset has
--  name (used as key)
--  'values' - list of values
--  'DataIncludesX' - T/F to say if this dataset contains X value (otherwiae, count them)
--  'Xlabels' - a list of labels, corresponding to the X values  (CR delim)
--  'Ylabels' - list of labels for Y value    (CR delim)
--  'YRaxis' - use the Right axis for scaling, etc.

----------------------------------------------------------------------
--| handler gmCreateGraph  
--|
--| Summary: create the controls for a graph (i.e. can be called once only)
--|
--| Format:  gmCreateGraph(pGrpId)
--|
--| Parameters: pGrpID - long id of the group to contain the controls
--|
--| Return: nothing very much !?!
----------------------------------------------------------------------
command gmCreateGraph pId
   logInfo "pID = " &&  pID
   local temp, tName
   
   put TRUE into sAGraphicGroup[pID]
   
   repeat with I = the number of controls of pID down to  1
      put the short name of control I of pID into tName
      if (tName begins with "G_" and char 3 to -1 of tName is a number) OR \
            (tName is among the items of "XM,XG,XA,YM,YG,YA,YR,Title" ) OR \
            (tName begins with "T_" and char 3 to -1 of tName is a number) then
         put the long ID of control I of pID into temp
         --         logInfo "deleteing" && temp 
         delete temp
      end if
   end repeat
   
   -- then create the controls needed
   repeat for each item II in "XM,XG,XA,YM,YG,YA,YR,Title"
      create invisible grc in pID
      set the name of it to II
      set the style of it to "line"
   end repeat
   
   -- then create the controls needed for data graphs
   repeat with I = 1 to 10
      create invisible grc in pID
      set the name of it to ("G_" & I)
      set the style of it to "line"
   end repeat
   
   -- then create the controls needed for labels
   repeat with I = 1 to 100
      create invisible fld in pID
      set the name of it to ("T_" & I)
   end repeat
   
end gmCreateGraph

command gmHideGraph pId
   local temp, tName
   
   repeat with I = the number of controls of pID down to  1
      put the short name of control I of pID into tName
      if (tName begins with "G_" and char 3 to -1 of tName is a number) OR \
            (tName is among the items of "XM,XG,XA,YM,YG,YA,YR,Title" ) OR \
            (tName begins with "T_" and char 3 to -1 of tName is a number) then
         put the long ID of control I of pID into temp
         set the vis of temp to FALSE
      end if
   end repeat
   
end gmHideGraph

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
   
   local tRect, tR
   local tName, tID
   
   if NOT (sAGraphicGroup[pID]) then
      logInfo "try to make graph with not-yet-created" && pID
   end if
   
   gmHideGraph pID
   put the rect of pId into tRect
   logInfo "rect = " && tRect && the number of controls of pID
   local temp
   
   local tt1
   local Xmin, Xmax, Ymin, Ymax, YRmin, YRmax
   
   put empty into Xmin
   put empty into Ymin
   put empty into YRmin
   if pAG["DataIncludesX"] then
      repeat for each key K in pAG["data"]
         put  pAG["data"][K]["values"] into  pAG["data"][K]["XY"]
         put firstOf(Xmin, item 1 of pAG["data"][K]["values"]) into Xmin
         if pAG["data"][K]["YRaxis"] then
            put firstOf(YRmin, item 2 of line 1 of pAG["data"][K]["values"]) into YRmin
         else
            put firstOf(Ymin, item 2 of line 1 of pAG["data"][K]["values"]) into Ymin
         end if
      end repeat
   else
      put 0 into Xmin
      put empty into Ymin
      repeat for each key K in pAG["data"]
         put empty into temp
         put 0 into tt1
         repeat for each line L in  pAG["data"][K]["values"]
            put tt1 & comma & CR after temp
         end repeat
         put temp into pAG["data"][K]["XY"]
         if pAG["data"][K]["YRaxis"] then
            put firstOf(YRmin, item 2 of line 1 of pAG["data"][K]["values"]) into YRmin
         else
            put firstOf(Ymin, item 2 of line 1 of pAG["data"][K]["values"]) into Ymin
         end if
      end repeat
   end if
   put Xmin into Xmax
   put Ymin into Ymax
   put YRmin into YRmax
   
   repeat for each item II in pAG["XRangeIncludes"]
      put min(II, Xmin) into Xmin
      put max(II, Xmax) into Xmax
   end repeat
   
   repeat for each item II in pAG["YRangeIncludes"]
      put min(II, Ymin) into Ymin
      put max(II, Ymax) into Ymax
   end repeat
   
   repeat for each item II in pAG["YRightRangeIncludes"]
      put min(II, YRmin) into YRmin
      put max(II, YRmax) into YRmax
   end repeat
   
   
   -- TODO offset for non-zero Ymin !!!
   
   local Yminthis, Ymaxthis
   repeat for each key K in pAG["data"]
      -- get its min, max Y values
      put item 2 of line 1 of pAG["data"][K]["XY"] into Yminthis
      put Yminthis into Ymaxthis
      repeat for each line L in pAG["data"][K]["XY"]
         put min(item 1 of L, Xmin) into Xmin
         put max(item 1 of L, Xmax) into Xmax
         put min(item 2 of L, Yminthis) into Yminthis
         put max(item 2 of L, Ymaxthis) into Ymaxthis
      end repeat
      put Yminthis, Ymaxthis into pAG["data"][K]["Yminmax"]
      if pAG["data"][K]["YRaxis"] then
         put min(Yminthis, YRmin) into YRmin
         put max(Ymaxthis, YRmax) into YRmax
      else
         put min(Yminthis, Ymin) into Ymin
         put max(Ymaxthis, Ymax) into Ymax
      end if
   end repeat
   
   -- 
   if pAG["XRange"] is not empty then
      put item 1 of pAG["XRange"] into Xmin
      put item 2 of pAG["XRange"] into Xmax
   else
      if pAG["XFit"] > 0 then
         put pAG["XFit"] * (Xmin div pAG["XFit"]) into Xmin
         put (pAG["XFit"] + 1) * (Xmax div pAG["XFit"]) into Xmax         
      end if
   end if
   
   if pAG["YRange"] is not empty then
      put item 1 of pAG["YRange"] into Ymin
      put item 2 of pAG["YRange"] into Ymax
   else
      if pAG["YFit"] > 0 then
         put pAG["YFit"] * (Ymin div pAG["YFit"]) into Ymin
         put (pAG["YFit"] + 1) * (Ymax div pAG["YFit"]) into Ymax         
      end if
   end if
   
   if pAG["YRightRange"] is not empty then
      put item 1 of pAG["YRightRange"] into YRmin
      put item 2 of pAG["YRightRange"] into YRmax
   else
      if pAG["YRightFit"] > 0 then
         put pAG["YRightFit"] * (YRmin div pAG["YRightFit"]) into YRmin
         put (pAG["YRightFit"] + 1) * (YRmax div pAG["YRightFit"]) into YRmax
      end if
   end if
   
   logInfo "min/max X" && Xmin && Xmax && "Y" && Ymin && yMax
   
   -- set up the drawing area co-ords
   -- will create a rect "r" in which the axes and actual graph go
   -- will account for legend, title, labels on axes, etc.
   -- BUT for now, just create basic rect
   --   --   --   --   create graphic "r" in pID
   
   local tGraphRect   -- rectangle for actual drawing
   set the style of grc "r" of pID to rectangle
   put item 1 of tRect+10, item 2 of tRect+10, item 3 of tRect-10, item 4 of tRect-10 into tRect
   set the rect of grc "r" of pID to tRect
   put tRect into tGraphRect
   add pAG["Lmargin"] to item 1 of tGraphRect
   add pAG["Tmargin"] to item 2 of tGraphRect
   subtract pAG["Rmargin"] from item 3 of tGraphRect
   subtract pAG["Bmargin"] from item 4 of tGraphRect
   
   -- base of actual drawing area
   put item 1 of tGraphRect into XBase
   put item 4 of tGraphRect into YBase
   
   -- set up scaling
   local  t1, t2
   put  (item 3 of tGraphRect-10) - (item 1 of tGraphRect+10) into t1
   put  (Xmax - Xmin) into t2
   if t2 <> 0 then put t1 / t2 into XS
   
   put  (item 4 of tGraphRect-10) - (item 2 of tGraphRect+10) into t1
   put  (Ymax - Ymin) into t2
   if t2 <> 0 then put t1 / t2 into YLS
   
   put  (YRmax - YRmin) into t2
   if t2 <> 0 then put t1 / t2 into YRS
   
   makeYAxis pID, pAG, XS, YS, YRS, Xmin, Ymin, Xmax, Ymax, YRmin, YRMax
   
   local tPoints
   
   repeat with K = 1 to the number of lines in the keys of pAG["data"] 
      
      if pAG["data"][K]["YRAxis"] then
         put YRS into YS
      else
         put YLS into YS
      end if
      
      
      put "grc " & q("G_" & K) & " of " & pID into tName
      
      put firstOf(pAG["data"][K]["color"], the foregroundColor of tName) into temp
      set the foregroundColor of tName to temp
      
      put firstOf(pAG["data"][K]["lineSize"], 2) into temp
      set the lineSize of tName to temp
      
      switch pAG["data"][K]["graphtype"]
         -- simple line graph
         case "line"
            set the style of tName to "line"
            set the points of tName to empty
            put empty into tPoints
            repeat for each line L in pAG["data"][K]["XY"]
               --               put XBase + item 1 of L * XS, YBase - item 2 of L * YS &CR after tPoints
               put _scalexy(item 1 of L, item 2 of L, XS, YS) &CR after tPoints
            end repeat
            set the points of tName to tPoints
            break
            
            -- battlement graph
         case "battlement"
         case "battlement_filled"
            set the style of tName to "line"
            set the points of tName to empty
            put empty into tPoints
            local tLastX, tLastY
            put 0 into ii
            put 0 into tLastX
            put 0 into tLastY
            repeat for each line L in pAG["data"][K]["XY"]
               add 1 to ii
               -- first go vertically
               --               put XBase + tLastX * XS, YBase - item 2 of L * YS &CR after tPoints
               put _scalexy(tLastX, item 2 of L, XS, YS) &CR after tPoints
               -- then horozontally
               put _scalexy(item 1 of L, item 2 of L, XS, YS) &CR after tPoints
               --               put XBase + item 1 of L * XS, YBase - item 2 of L * YS &CR after tPoints
               put item 1 of L into tLastX
               put item 2 of L into tLastY
            end repeat
            if pAG["data"][K]["graphtype"] = "battlement" then
               set the points of tName to tPoints
            else
               -- ...filled : close off; vertical at end then base
               --               put XBase + item 1 of L * XS, YBase - 0 * YS &CR after tPoints
               put _scalexy(item 1 of L, 0, XS, YS) &CR after tPoints
               --               put XBase + item 1 of line 1 of pAG["data"][K]["XY"] * XS, \
               --                     YBase - 0 * YS &CR after tPoints
               put _scalexy(item 1 of line 1 of pAG["data"][K]["XY"], 0, XS, YS) &CR after tPoints
               put firstOf(pAG["data"][K]["color"], the backgroundColor of tName) into temp
               set the backgroundColor of tName to temp
               set the opaque of tName to TRUE
               
               put firstOf(pAG["data"][K]["lineSize"], 1) into temp
               set the lineSize of tName to 1 -- ALWAYS min size lines in filled shapes
               
               set the points of tName to tPoints
               set the style of tName to "polygon"
            end if
            break
      end switch
      set the vis of tName to TRUE
   end repeat
   
   put empty into t1
   
end gmMakeGraph

function _scalexy px, py, pXS, pYS
   local temp
   put XBase + item 1 of px * pXS, YBase - py * pYS into temp
   return temp
end _scalexy

command makeYAxis pID, pAG, pXS, pYS, pYRS, pXmin, pYmin, pXmax, pYmax, pYRmin, pYRMax
   local tPoints
   -- draw a Y axis, if needed
   if pAG["YTickInterval"] = 0 then 
      set the vis of grc "YA" of pID to FALSE
      set the vis of grc "YG" of pID to FALSE
      -- Hmmm assumption that we never have Right axis without also Left axis ???
      set the vis of grc "YR" of pID to FALSE
      set the vis of grc "YRG" of pID to FALSE
      exit makeYAxis
   end if
   
   put _scalexy(pXmin, pYmin, pXS, pYS) &CR into tPoints
   put _scalexy(pXmin, pYmax, pXS, pYS) &CR after tPoints
   
   local temp
   if pAG["YTickInterval"] > 0 then
      repeat with i = pYmin to pYmax step pAG["YTickInterval"]
         if i > pYmax then 
            --            logInfo "exiting repeat" && i && Ymax
            exit repeat
         end if
         put CR after tPoints
         put _scalexy(pXmin, i, pXS, pYS) into temp
         put temp & CR after tPoints
         add 10 to item 1 of temp
         put temp & CR after tPoints
         logInfo "Y tick" && pXmin && i && pAG["YTickInterval"] && line -1 of tPoints
      end repeat
      set the points of grc "YA" of pID to tPoints
      set the vis of grc "YA" of pID to TRUE
   end if
   
   if pAG["YGridInterval"] > 0 then
      put empty into tPoints
      repeat with i = pYmin to pYmax step pAG["YGridInterval"]
         if i > pYmax then 
            --            logInfo "exiting repeat" && i && Ymax
            exit repeat
         end if
         put CR after tPoints
         put _scalexy(pXmin, i, pXS, pYS) &CR after tPoints
         put _scalexy(pXmax, i, pXS, pYS) &CR after tPoints
         logInfo "Y grid" && pXmin && i && pAG["YGridInterval"] && line -1 of tPoints
      end repeat
      set the points of grc "YG" of pID to tPoints
      set the vis of grc "YG" of pID to TRUE
   end if
   
   if pAG["YRTickInterval"] > 0 then
      put _scalexy(pXmax, pYRmin, pXS, pYRS) &CR into tPoints
      put _scalexy(pXmax, pYRmax, pXS, pYRS) &CR after tPoints
      
      repeat with i = pYmin to pYmax step pAG["YRTickInterval"]
         if i > pYmax then 
            --            logInfo "exiting repeat" && i && Ymax
            exit repeat
         end if
         put CR after tPoints
         put _scalexy(pXmax-10, i, pXS, pYRS) &CR after tPoints
         put _scalexy(pXmax, i, pXS, pYRS) &CR after tPoints
         logInfo "YR grid" && pXS && i && pAG["YRTickInterval"] && line -1 of tPoints
      end repeat
      set the points of grc "YR" of pID to tPoints
      set the vis of grc "YR" of pID to TRUE
   end if
   
end makeYAxis
