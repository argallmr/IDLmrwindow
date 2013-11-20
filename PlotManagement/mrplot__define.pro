; docformat = 'rst'
;
; NAME:
;       MrPlot__Define
;
;*****************************************************************************************
;   Copyright (c) 2013, Matthew Argall                                                   ;
;   All rights reserved.                                                                 ;
;                                                                                        ;
;   Redistribution and use in source and binary forms, with or without modification,     ;
;   are permitted provided that the following conditions are met:                        ;
;                                                                                        ;
;       * Redistributions of source code must retain the above copyright notice,         ;
;         this list of conditions and the following disclaimer.                          ;
;       * Redistributions in binary form must reproduce the above copyright notice,      ;
;         this list of conditions and the following disclaimer in the documentation      ;
;         and/or other materials provided with the distribution.                         ;
;       * Neither the name of the <ORGANIZATION> nor the names of its contributors may   ;
;         be used to endorse or promote products derived from this software without      ;
;         specific prior written permission.                                             ;
;                                                                                        ;
;   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY  ;
;   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES ;
;   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT  ;
;   SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,       ;
;   INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED ;
;   TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR   ;
;   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     ;
;   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN   ;
;   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  ;
;   DAMAGE.                                                                              ;
;*****************************************************************************************
;
; PURPOSE:
;+
;   The purpose of this method is to create an object out of the cgPlot routine.
;
; :Examples:
;   Plot an Nx2 array as two line plots on a single axis.
;       x = findgen(101)/100
;       y = sin(2*!pi*x)
;       z = cos(2*!pi*x)
;       a = obj_new('MrPlot', x, [[y],[z]], DIMENSION=2, TITLE='Sin(x) & Cos(x)', $
;                                   COLOR=['black', 'blue'], XTITLE='Time (s)', $
;                                   YTITLE='Amplitude', /DRAW)
;       obj_destroy, a
;
; :Author:
;   Matthew Argall::
;       University of New Hampshire
;       Morse Hall, Room 113
;       8 College Rd.
;       Durham, NH, 03824
;       matthew.argall@wildcats.unh.edu
;
; :Copyright:
;       Matthew Argall 2013
;
; :History:
;   Modification History::
;       05/18/2013  -   Written by Matthew Argall
;       06/28/2013  -   Added the DIMENSION keyword. Removed the AXES and COLORBARS
;                           properties because the former was not being used and the
;                           latter interfered with the COLOR keyword. - MRA
;       07/04/2013  -   Added the COLOR keyword so that each column or row in DIMENSION
;                           can be plotted in a different color. - MRA
;       07/31/2013  -   Added the ConvertCoord method. - MRA
;       08/09/2013  -   Inherit MrIDL_Container - MRA
;       08/10/2013  -   Added the LAYOUT keyword. - MRA
;       08/22/2013  -   Added the NOERASE keyword to Draw. Was forgetting to set the
;                           position property in SetProperty. Fixed. - MRA
;       08/23/2013  -   Added the IsInside method. - MRA
;       08/30/2013  -   Missed the SYMCOLOR keyword. Now included. - MRA
;       09/08/2013  -   Number of default colors now matches the number of dimensions
;                           being plotted. - MRA
;                           PLOT_INDEX keyword in IsAvailable now works. - MRA
;       09/27/2013  -   Use N_Elements instead of N_Params in case `Y` is present but 
;                           undefined. Position and layout properties are now handled
;                           by MrGraphicAtom. Renamed from MrPlotObject to MrPlot. - MRA
;       09/29/2013  -   Ensure that the layout is updated only when a layout keyword is
;                           passed in. - MRA
;       10/07/2013  -   Added the HIDE keyword. - MRA
;       2013/11/17  -   CHARSIZE is now a MrGraphicAtom property. Use _EXTRA instead of
;                           _STRICT_EXTRA in some cases to make setting and getting
;                           properties easier and to reduce list of keywords. - MRA
;       2013/11/20  -   MrIDL_Container no longer inherited. Added the NAME property.
;-
;*****************************************************************************************
;+
;   The purpose of this method is to draw the plot in the draw window.
;-
pro MrPlot::Draw, $
NOERASE = noerase
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return
    endif

    ;Draw the plot
    if self.hide eq 0 then begin
        self -> doPlot, NOERASE=noerase
    
        ;Save the system variables
        self.x_sysvar = !X
        self.y_sysvar = !Y
        self.p_sysvar = !P
    endif
end


;+
;   The purpose of this method is to do the actual plotting. Basically, having this here
;   merely to saves space in the Draw method.
;-
pro MrPlot::doPlot, $
NOERASE=noerase
    compile_opt idl2
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return
    endif
    
    if n_elements(noerase) eq 0 then noerase = *self.noerase

    ;Draw the plot.
    wePlot, *self.indep, *self.dep, $
            DIMENSION = self.dimension, $
            OUTPUT    = output, $
            LABEL     = self.label, $
            
            ;cgPlot Keywords
            SYMCOLOR = *self.symcolor, $
                   
            ;MrGraphicsAtom Keywords
            POSITION      = self.position, $

            ;Graphics Keywords
            MAX_VALUE = *self.max_value, $
            MIN_VALUE = *self.min_value, $
            XLOG      = *self.xlog, $
            YLOG      = *self.ylog, $
            YNOZERO   = *self.ynozero, $
               
            ;weGraphicsKeywords
            AXISCOLOR     = *self.axiscolor, $
            BACKGROUND    = *self.background, $
            CHARSIZE      =  self.charsize, $
            CHARTHICK     = *self.charthick, $
            CLIP          = *self.clip, $
            COLOR         = *self.color, $
            DATA          = *self.data, $
            DEVICE        = *self.device, $
            NORMAL        = *self.normal, $
            FONT          = *self.font, $
            NOCLIP        = *self.noclip, $
            NODATA        = *self.nodata, $
            NOERASE       =       noerase, $
            PSYM          = *self.psym, $
            SUBTITLE      = *self.subtitle, $
            SYMSIZE       = *self.symsize, $
            T3D           = *self.t3d, $
            THICK         = *self.thick, $
            TICKLEN       = *self.ticklen, $
            TITLE         = *self.title, $
            XCHARSIZE     = *self.xcharsize, $
            XGRIDSTYLE    = *self.xgridstyle, $
            XMINOR        = *self.xminor, $
            XRANGE        = *self.xrange, $
            XSTYLE        = *self.xstyle, $
            XTHICK        = *self.xthick, $
            XTICK_GET     = *self.xtick_get, $
            XTICKFORMAT   = *self.xtickformat, $
            XTICKINTERVAL = *self.xtickinterval, $
            XTICKLAYOUT   = *self.xticklayout, $
            XTICKLEN      = *self.xticklen, $
            XTICKNAME     = *self.xtickname, $
            XTICKS        = *self.xticks, $
            XTICKUNITS    = *self.xtickunits, $
            XTICKV        = *self.xtickv, $
            XTITLE        = *self.xtitle, $
            YCHARSIZE     = *self.ycharsize, $
            YGRIDSTYLE    = *self.ygridstyle, $
            YMINOR        = *self.yminor, $
            YRANGE        = *self.yrange, $
            YSTYLE        = *self.ystyle, $
            YTHICK        = *self.ythick, $
            YTICK_GET     = *self.ytick_get, $
            YTICKFORMAT   = *self.ytickformat, $
            YTICKINTERVAL = *self.ytickinterval, $
            YTICKLAYOUT   = *self.yticklayout, $
            YTICKLEN      = *self.yticklen, $
            YTICKNAME     = *self.ytickname, $
            YTICKS        = *self.yticks, $
            YTICKUNITS    = *self.ytickunits, $
            YTICKV        = *self.ytickv, $
            YTITLE        = *self.ytitle, $
            ZCHARSIZE     = *self.zcharsize, $
            ZGRIDSTYLE    = *self.zgridstyle, $
            ZMARGIN       = *self.zmargin, $
            ZMINOR        = *self.zminor, $
            ZRANGE        = *self.zrange, $
            ZSTYLE        = *self.zstyle, $
            ZTHICK        = *self.zthick, $
            ZTICK_GET     = *self.ztick_get, $
            ZTICKFORMAT   = *self.ztickformat, $
            ZTICKINTERVAL = *self.ztickinterval, $
            ZTICKLAYOUT   = *self.zticklayout, $
            ZTICKLEN      = *self.zticklen, $
            ZTICKNAME     = *self.ztickname, $
            ZTICKS        = *self.zticks, $
            ZTICKUNITS    = *self.ztickunits, $
            ZTICKV        = *self.ztickv, $
            ZTITLE        = *self.ztitle, $
            ZVALUE        = *self.zvalue
end


;+
;   The purpose of this method is to retrieve object properties
;
; :Keywords:
;       DEP:                out, optional, type=any
;                           Data associated with the dependent variable.
;       DIMENSION:          in, optional, type=int
;                           The dimension over which to plot.
;       INDEP:              out, optional, type=any
;                           Data associated with the independent variable.
;       INIT_XRANGE:        out, optional, type=fltarr(2)
;                           The initial state of the XRANGE keyword. This is used to reset
;                               the zoom to its original state.
;       INIT_YRANGE:        out, optional, type=fltarr(2)
;                           The initial state of the YRANGE keyword. This is used to reset
;                               the zoom to its original state.
;       HIDE:               out, optional, type=boolean
;                           If set, the graphic is hidden.
;       LABEL:              out, optional, type=string
;                           A label is similar to a plot title, but it is aligned to the
;                               left edge of the plot and is written in hardware fonts.
;                               Use of the label keyword will suppress the plot title.
;       MAX_VALUE:          out, optional, type=float
;                           The maximum value plotted. Any values larger than this are
;                               treated as missing.
;       MIN_VALUE:          out, optional, type=float
;                           The minimum value plotted. Any values smaller than this are
;                               treated as missing.
;       NAME:               out, optional, type=string
;                           Name of the graphic.
;       NSUM:               out, optional, type=integer
;                           The presence of this keyword indicates the number of data
;                               points to average when plotting.
;       P_SYSVAR:           out, optional, type=structure
;                           The !P system variable state associated with this plot.
;       POLAR:              out, optional, type=boolean
;                           Indicates that X and Y are actually R and Theta and that the
;                               plot is in polar coordinates.
;       X_SYSVAR:           out, optional, type=structure
;                           The !X system variable state associated with the image
;       XLOG:               out, optional, type=boolean
;                           Indicates that a log scale is used on the x-axis
;       YLOG:               out, optional, type=boolean
;                           Indicates that a log scale is used on the y-axis
;       Y_SYSVAR:           out, optional, type=structure
;                           The !Y system variable state associated with the image
;       YNOZERO:            out, optional, type=boolean, default=0
;                           Inhibit setting the y  axis value to zero when all Y > 0 and
;                               no explicit minimum is set.
;       _REF_EXTRA:         out, optional, type=any
;                           Keyword accepted by the superclasses are also accepted for
;                               keyword inheritance.
;-
pro MrPlot::GetProperty, $
INDEP = indep, $
DEP = dep, $

;MrPlot Properties
DIMENSION = dimension, $
INIT_XRANGE = init_xrange, $
INIT_YRANGE = init_yrange, $
HIDE = hide, $
LABEL = label, $
NAME = name, $
P_SYSVAR = p_sysvar, $
X_SYSVAR = x_sysvar, $
Y_SYSVAR = y_sysvar, $

;cgPlot Properties
SYMCOLOR = symcolor, $

;Graphics Properties
MAX_VALUE = max_value, $
MIN_VALUE = min_value, $
NSUM = nsum, $
POLAR = polar, $
XLOG = xlog, $
YLOG = ylog, $
YNOZERO = ynozero, $

;weGraphicsKeywords Properties
_REF_EXTRA = extra
    compile_opt idl2
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return
    endif
    
    ;Data Properties
    if arg_present(INDEP) then if n_elements(*self.indep) ne 0 then indep = *self.indep
    if arg_present(DEP)   then if n_elements(*self.dep)   ne 0 then dep = *self.dep

    ;MrPlot Properties
    if arg_present(dimension)   then dimension   =  self.dimension
    if arg_present(init_xrange) then init_xrange =  self.init_xrange
    if arg_present(init_yrange) then init_yrange =  self.init_yrange
    if arg_present(hide)        then hide        =  self.hide
    if arg_present(label)       then label       =  self.label
    if arg_present(name)        then name        =  self.name
    if arg_present(p_sysvar)    then p_sysvar    =  self.p_sysvar
    if arg_present(x_sysvar)    then x_sysvar    =  self.x_sysvar
    if arg_present(y_sysvar)    then y_sysvar    =  self.y_sysvar
    
    ;cgPlot Properties
    if arg_present(symcolor)  and n_elements(*self.symcolor)  ne 0 then symcolor = *self.symcolor
    
    ;Graphics Properties
    if arg_present(MAX_VALUE) and n_elements(*self.MAX_VALUE) ne 0 then max_value = *self.max_value
    if arg_present(MIN_VALUE) and n_elements(*self.MIN_VALUE) ne 0 then min_value = *self.min_value
    if arg_present(nsum)      and n_elements(*self.nsum)      ne 0 then nsum = *self.nsum
    if arg_present(XLOG)      and n_elements(*self.XLOG)      ne 0 then xlog = *self.xlog
    if arg_present(YLOG)      and n_elements(*self.YLOG)      ne 0 then ylog = *self.ylog
    if arg_present(POLAR)     and n_elements(*self.POLAR)     ne 0 then polar = *self.polar
    if arg_present(YNOZERO)   and n_elements(*self.YNOZERO)   ne 0 then ynozero = *self.ynozero
    
    ;Get all of the remaining keywords from weGraphicsKeywords
    if n_elements(EXTRA) gt 0 then begin
        self -> MrGraphicAtom::GetProperty, _EXTRA=extra
        self -> weGraphicsKeywords::GetProperty, _EXTRA=extra
    endif
end


;+
;   Create a MrPlot object to be drawn in the device window.
;
; :Keywords:
;       DRAW:               in, optional, type=boolean, default=0
;                           Call the Draw method after adding the plot to the list.
;       _REF_EXTRA:         in, optional, type=structure
;                           Any keyword accepted by MrPlot__define.
;   
;-
pro MrPlot::Plot, $
DRAW = draw, $
_REF_EXTRA = extra
    compile_opt idl2
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return
    endif

    ;Create the plot
    thePlot = obj_new('MrPlot', _STRICT_EXTRA=extra)
    
    ;Add the plot
    self -> Add, thePlot
    
    ;Draw    
    if keyword_set(draw) then self -> Draw
end


;+
;   The purpose of this method is to set object properties. 
;
; :Keywords:
;       DEP:                in, optional, type=any
;                           Data associated with the dependent variable.
;       DIMENSION:          in, optional, type=int
;                           The dimension over which to plot.
;       DRAW:               in, optional, type=boolean, default=0
;                           Redraw the plot after setting the object properties.
;       INDEP:              in, optional, type=any
;                           Data associated with the independent variable.
;       INIT_XRANGE:        in, optional, type=fltarr(2)
;                           The initial state of the XRANGE keyword. This is used to reset
;                               the zoom to its original state.
;       INIT_YRANGE:        in, optional, type=fltarr(2)
;                           The initial state of the YRANGE keyword. This is used to reset
;                               the zoom to its original state.
;       HIDE:               in, optional, type=boolean
;                           Indicates whether the graphic is hidden or not.
;       LABEL:              in, optional, type=string
;                           A label is similar to a plot title, but it is aligned to the
;                               left edge of the plot and is written in hardware fonts.
;                               Use of the label keyword will suppress the plot title.
;       MAX_VALUE:          in, optional, type=float
;                           The maximum value plotted. Any values larger than this are
;                               treated as missing.
;       MIN_VALUE:          in, optional, type=float
;                           The minimum value plotted. Any values smaller than this are
;                               treated as missing.
;       NAME:               in, optional, type=string
;                           Specifies the name of the graphic.
;       NSUM:               in, optional, type=integer
;                           The presence of this keyword indicates the number of data
;                               points to average when plotting.
;       P_SYSVAR:           in, optional, type=structure
;                           The !P system variable state associated with this plot.
;       POLAR:              in, optional, type=boolean
;                           Indicates that X and Y are actually R and Theta and that the
;                               plot is in polar coordinates.
;       X_SYSVAR:           in, optional, type=structure
;                           The !X system variable state associated with the image
;       XLOG:               in, optional, type=boolean
;                           Indicates that a log scale is used on the x-axis
;       YLOG:               in, optional, type=boolean
;                           Indicates that a log scale is used on the y-axis
;       Y_SYSVAR:           in, optional, type=structure
;                           The !Y system variable state associated with the image
;       YNOZERO:            in, optional, type=boolean, default=0
;                           Inhibit setting the y  axis value to zero when all Y > 0 and
;                               no explicit minimum is set.
;       _REF_EXTRA:         in, optional, type=any
;                           Keyword accepted by the superclasses are also accepted for
;                               keyword inheritance.
;-
pro MrPlot::SetProperty, $
DRAW = draw, $

;Data Properties
INDEP = indep, $
DEP = dep, $

;MrPlot Properties
DIMENSION = dimension, $
INIT_XRANGE = init_xrange, $
INIT_YRANGE = init_yrange, $
HIDE = hide, $
LABEL = label, $
P_SYSVAR = p_sysvar, $
X_SYSVAR = x_sysvar, $
Y_SYSVAR = y_sysvar, $

;cgPlot Properties
SYMCOLOR = symcolor, $

;Graphics Properties
MAX_VALUE = max_value, $
MIN_VALUE = min_value, $
NAME = name, $
NSUM = nsum, $
POLAR = polar, $
XLOG = xlog, $
YLOG = ylog, $
YNOZERO = ynozero, $

;weGraphics Properties
XSTYLE = xstyle, $
YSTYLE = ystyle, $
_REF_EXTRA = extra
    compile_opt idl2
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return
    endif
    
    ;Data Properties
    if n_elements(INDEP) ne 0 then *self.indep = indep
    if n_elements(DEP) ne 0 then *self.dep = dep

    ;MrPlot Properties
    if n_elements(DIMENSION)   ne 0 then  self.dimension = dimension
    if n_elements(HIDE)        ne 0 then  self.hide = hide
    if n_elements(LABEL)       ne 0 then  self.label = label
    if n_elements(INIT_XRANGE) ne 0 then  self.init_xrange = init_xrange
    if n_elements(INIT_YRANGE) ne 0 then  self.init_yrange = init_yrange
    if n_elements(P_SYSVAR)    ne 0 then  self.p_sysvar = p_sysvar
    if n_elements(X_SYSVAR)    ne 0 then  self.x_sysvar = x_sysvar
    if n_elements(Y_SYSVAR)    ne 0 then  self.y_sysvar = y_sysvar
    
    ;cgPlot Properties
    if n_elements(SYMCOLOR) ne 0 then *self.symcolor = symcolor
    
    ;Graphics Properties
    if n_elements(MAX_VALUE) ne 0 then *self.max_value = max_value
    if n_elements(MIN_VALUE) ne 0 then *self.min_value = min_value
    if n_elements(name)      gt 0 then  self.name = name
    if n_elements(NSUM)      ne 0 then *self.nsum = nsum
    if n_elements(POLAR)     ne 0 then *self.polar = keyword_set(polar)
    if n_elements(XLOG)      ne 0 then *self.xlog = keyword_set(xlog)
    if n_elements(YLOG)      ne 0 then *self.ylog = keyword_set(ylog)
    if n_elements(YNOZERO)   ne 0 then *self.ynozero = keyword_set(ynozero)
    
    ;Superclass properties
    if n_elements(extra) gt 0 then begin
        ;MrGraphicAtom -- We must pick out each keyword here to prevent MrGraphicAtom
        ;                 from updating the position every time (i.e. when the layout
        ;                 remains unchanged).
        atom_kwds = ['ASPECT', 'CHARSIZE', 'LAYOUT', 'POSITION', 'XMARGIN', 'XGAP', 'YMARGIN', 'YGAP', 'UPDATE_LAYOUT']
        void = IsMember(atom_kwds, extra, iAtom, N_MATCHES=nAtom, NONMEMBER_INDS=iExtra, N_NONMEMBER=nExtra)
        if nAtom gt 0 then self -> MrGraphicAtom::SetProperty, _STRICT_EXTRA=extra[iAtom]
    
        ;weGraphicsKeywords Properties
        if nExtra gt 0 then self -> weGraphicsKeywords::SetProperty, _STRICT_EXTRA=extra[iExtra]
    endif
    
    if n_elements(xstyle) ne 0 then *self.xstyle = ~(xstyle and 1) + xstyle
    if n_elements(ystyle) ne 0 then *self.ystyle = ~(ystyle and 1) + ystyle
    
    ;Draw?
    if keyword_set(draw) then self -> draw
end


;+
;   Clean up after the object is destroyed -- destroy pointers and object references.
;-
pro MrPlot::cleanup
    compile_opt idl2
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return
    endif
    
    ;free all pointers
    ptr_free, self.indep
    ptr_free, self.dep
    ptr_free, self.max_value
    ptr_free, self.min_value
    ptr_free, self.nsum
    ptr_free, self.xlog
    ptr_free, self.ylog
    ptr_free, self.polar
    ptr_free, self.symcolor
    
    ;Cleanup the superclass.
    self -> weGraphicsKeywords::CLEANUP
    self -> MrGraphicAtom::Cleanup
end


;+
;   The purpose of this method is to create line plot in a zoomable, resizeable window
;   that contains several analysis options (with more to be added). Only certain features
;   are available at any one time, but all can be selected from the menu bar.
;
; :Params:
;       X:                  in, required, type=any
;                           If Y is given, a vector representing the independent variable
;                               to be plotted. If Y is not given, a vector or array of
;                               representing the dependent variable to be plotted. Each
;                               column of X will then be overplotted as individual vectors
;                               in the same set of axes.
;       Y:                  in, optional, type=any
;                           A vector or array of representing the dependent variable to be
;                               plotted. Each column of Y will then be overplotted
;                               as individual vectors in the same set of axes.
;
; :Keywords:
;       COLOR:              in, optional, type=string/strarr, default='opposite'
;                           Color of the line plots. If `DIMENSION` is used, there must
;                               be one color per component.
;       DIMENSION:          in, optional, type=int, default=0
;                           The dimension over which to plot. As an example, say `Y` is
;                               an N1xN2 array and settind DIMENSION=2. Then, N1 plots
;                               will be overplotted on top of each other, one for each
;                               DATA[i,*]. If DIMENSION=0, then a single plot of all
;                               points will be made.
;       DRAW:               in, optional, type=boolean, default=1
;                           If set, the data will be drawn to the plot. DRAW=1 always if
;                               `GUI`=1.
;       HIDE:               in, optional, type=boolean, default=0
;                           If set, the graphic will be hidden.
;       LEGENDS:            in, optional, type=object/obj_arr
;                           weLegendItem or cgLegendItem objects to be added to the plot.
;       MAX_VALUE:          in, optional, type=float
;                           The maximum value plotted. Any values larger than this are
;                               treated as missing.
;       MIN_VALUE:          in, optional, type=float
;                           The minimum value plotted. Any values smaller than this are
;                               treated as missing.
;       NAME:               in, optional, type=string, default='MrPlot'
;                           Specifies the name of the graphic.
;       POLAR:              in, optional, type=boolean
;                           Indicates that X and Y are actually R and Theta and that the
;                               plot is in polar coordinates.
;       POSITION:           in, optional, type=fltarr(4)
;                           A vector of the form [x0, y0, x1, y1], where [x0,y0] and [x1,y1]
;                               specify the position of the lower-left and upper-right
;                               corner of the plotting region, respectively.
;       XLOG:               in, optional, type=boolean
;                           Indicates that a log scale is used on the x-axis
;       XRANGE:             in, optional, type=fltarr(2), default=[min(`X`)\, max(`X`)]
;                           The x-axis range over which the data will be displayed.
;       YLOG:               in, optional, type=boolean
;                           Indicates that a log scale is used on the y-axis
;       YNOZERO:            in, optional, type=boolean, default=0
;                           Inhibit setting the y  axis value to zero when all Y > 0 and
;                               no explicit minimum is set.
;       YRANGE:             in, optional, type=fltarr(2), default=[min(`X`)\, max(`X`)]
;                           The y-axis range over which the data will be displayed.
;       _REF_EXTRA:         in, optional, type=any
;                           Keywords accepted by the any of the superclasses are also
;                               accepted for keyword inheritcance.
;
; :Uses:
;   Uses the following external programs::
;       binary.pro (Coyote Graphics)
;       weGraphicsKeywords__define.pro (Coyote Graphics)
;       error_message.pro (Coyote Graphics)
;       MrDrawWindow__define.pro
;       MrPlotLayout.pro
;       MrGetWindow.pro
;-
function MrPlot::init, x, y, $
;MrPlot Keywords
DIMENSION = dimension, $
DRAW = draw, $
HIDE = hide, $
OVERPLOT = overplot, $

;cgPlot Keywords
SYMCOLOR = symcolor, $

;Graphics Keywords
COLOR = color, $
MAX_VALUE = max_value, $
MIN_VALUE = min_value, $
NAME = name, $
NSUM = nsum, $
POLAR = polar, $
XRANGE = xrange, $
XLOG = xlog, $
YLOG = ylog, $
YNOZERO = ynozero, $
YRANGE = yrange, $
_REF_EXTRA = extra
    compile_opt idl2

    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = error_message()
        return, 0
    endif

    dims = size(x, /DIMENSIONS)
    setDefaultValue, dimension, 0
    setDefaultValue, draw, 1, /BOOLEAN
    setDefaultValue, gui, 1, /BOOLEAN
    setDefaultValue, hide, 0, /BOOLEAN
    setDefaultValue, name, 'MrPlot'
    setDefaultValue, xsize, 600
    setDefaultValue, ysize, 340
    nx = n_elements(x)
    ny = n_elements(y)

;---------------------------------------------------------------------
;Superclass Properties ///////////////////////////////////////////////
;---------------------------------------------------------------------

    ;Call the superclass init method. Prevent some Coyote Graphics
    ;defaults from taking effect. The EXTRA structure has precedence over
    ;the keywords, so if AXISCOLOR is supplied by the user,
    ;the one shown in the call will be ignored.
    if self -> weGraphicsKeywords::INIT(AXISCOLOR='black', _EXTRA=extra) eq 0 then $
        message, 'Unable to initialize MrGraphicsKeywords.'
    
    ;Graphic Atom
    if self -> MrGraphicAtom::INIT(_EXTRA=extra) eq 0 then $
        message, 'Unable to initialize MrGraphicAtom.'

;---------------------------------------------------------------------
;Dependent and Independent Variables /////////////////////////////////
;---------------------------------------------------------------------

    ;Figure out the dependent variable
    if ny eq 0 $
        then dep = x $
        else dep = y
    
    ;Make the independent variable index the chosen DIMENSION of y.
    if ny eq 0 then begin
        if dimension eq 0 $
            then indep = lindgen(n_elements(dep)) $
            else indep = lindgen(dims[dimension])
    
    ;The independent variable was given.
    endif else begin
        dims = size(y, /dimensions)
        indep = x
    endelse
    
    ;Make sure arrays were given, not scalars
    if n_elements(indep) eq 1 then indep = [indep]
    if n_elements(dep) eq 1 then dep = [dep]

    ;The dimension not being plotted.
    case dimension of
        0: xdim = 0
        1: xdim = 2
        2: xdim = 1
    endcase
        
    ;Number of defaults to use.
    if xdim eq 0 then nDefaults = 1 else nDefaults = dims[xdim-1]

;---------------------------------------------------------------------
;Keywords ////////////////////////////////////////////////////////////
;---------------------------------------------------------------------
    
    ;Allocate heap for the variables
    self.indep = ptr_new(/ALLOCATE_HEAP)
    self.dep = ptr_new(/ALLOCATE_HEAP)
    self.min_value = ptr_new(/ALLOCATE_HEAP)
    self.max_value = ptr_new(/ALLOCATE_HEAP)
    self.nsum = ptr_new(/ALLOCATE_HEAP)
    self.xlog = ptr_new(/ALLOCATE_HEAP)
    self.ylog = ptr_new(/ALLOCATE_HEAP)
    self.polar = ptr_new(/ALLOCATE_HEAP)
    self.symcolor = ptr_new(/ALLOCATE_HEAP)
    self.ynozero = ptr_new(/ALLOCATE_HEAP)
    
    ;Add overplots and legends. Serves as an Init method.
    if n_elements(oplots)  ne 0 then self -> Add, oplots
    if n_elements(legends) ne 0 then self -> Add, legends
    
    ;Set the initial x- and y-range
    if n_elements(xrange) eq 0 then xrange = [min(indep, max=maxIndep), maxIndep]
    if n_elements(yrange) eq 0 then begin
        yrange = [min(dep, max=maxdep), maxdep]
        yrange += [-abs(yrange[0]), abs(yrange[1])]*0.05
    endif
    self.init_xrange = xrange
    self.init_yrange = yrange

    ;Pick a set of default colors so not everything is the same color.
    default_colors = ['opposite', 'Blue', 'Forest_Green', 'Red', 'Magenta', 'Orange']
    if nDefaults gt 5 then default_colors = [default_colors, replicate('opposite', nDefaults-5)]
    if nDefaults eq 1 then d_color = default_colors[0] else d_color = default_colors[1:nDefaults]
    SetDefaultValue, color, d_color

    ;Set the object properties
    self -> setProperty, INDEP = indep, $
                         DEP = dep, $
                         COLOR = color, $
                         DIMENSION = dimension, $
                         HIDE = hide, $
                         LABEL = label, $
                         MAX_VALUE = max_value, $
                         MIN_VALUE = min_value, $
                         NAME = name, $
                         NSUM = nsum, $
                         POLAR = polar, $
                         SYMCOLOR = symcolor, $
                         XLOG = keyword_set(xlog), $
                         XRANGE = xrange, $
                         YLOG = keyword_set(ylog), $
                         YNOZERO = ynozero, $
                         YRANGE = yrange

    ;Make sure the x- and y-style keywords have the 2^0 bit set to force
    ;exact axis ranges.    
    if n_elements(*self.xstyle) eq 0 $
        then *self.xstyle = 1 $
        else *self.xstyle += ~(*self.xstyle and 1)
        
    if n_elements(*self.ystyle) eq 0 $
        then *self.ystyle = 1 $
        else *self.ystyle += ~(*self.ystyle and 1)

    ;Draw?
    if keyword_set(draw) then self -> draw

    return, 1
end


;+
;   Object class definition
;
; :Params:
;       CLASS:          out, optional, type=structure
;                       The class definition structure.
;-
pro MrPlot__define, class
    compile_opt idl2
    
    class = {MrPlot, $
             inherits MrGraphicAtom, $
             inherits weGraphicsKeywords, $
             
             ;Data Properties
             indep: ptr_new(), $               ;independent variable
             dep: ptr_new(), $                 ;dependent variable
             
             ;Graphics Properties
             max_value: ptr_new(), $           ;maximum value displayed in plot
             min_value: ptr_new(), $           ;minimum value displayed in plot
             name: '', $                       ;name of the graphic
             xlog: ptr_new(), $                ;log-scale the x-axis?
             ylog: ptr_new(), $                ;log-scale the y-axis?
             polar: ptr_new(), $               ;create a polar plot?
             ynozero: ptr_new(), $             ;do not make ymin=0
             nsum: ptr_new(), $                ;*number of points to average when plotting
             
             ;cgPlot Properties
             symcolor: ptr_new(), $            ;color of each symbol
             
             ;MrPlot Properties
             dimension: 0, $                   ;The over which plots will be made
             hide: 0, $                        ;Show the plot?
             label: '', $                      ;*
             init_xrange: dblarr(2), $         ;Initial y-range
             init_yrange: dblarr(2), $         ;Initial x-range
             x_sysvar: !X, $                   ;Save the X system variable
             y_sysvar: !Y, $                   ;Save the Y system variable
             p_sysvar: !P}                     ;Save the P system variable
end