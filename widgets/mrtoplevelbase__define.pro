;+
; NAME:
;       MrTopLevelBase__Define
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
; PURPOSE
;+
;   The purpose of this program is to create a top-level widget base class. For non-TLB
;   widget bases, use the MrWidgetBase widget class.
;
;   MRWIDGETATOM
;       MrWidgetAtom::Init() method must be called after the widget has been created (with
;       the Widget_Base function). It makes calls to Widget_Control.
;
;   MRBASEWIDGET
;       The MrBaseWidget::Init should not be called when the top-level base is created.
;       If it were to be called, within the INIT method below, a second base would be
;       created. We do not want that.
;
;   METHOD EVENT HANDLING:
;       The following keywords::
;           FUNC_GET_VALUE
;           PRO_GET_VALUE
;           KILL_NOTIFY
;           NOTIFY_REALIZE
;           Any keyword that forwards events to EVENT_PRO or EVENT_FUNC
;
;       In addition to their normal IDL properties, can be structures of the form::
;           KWRD = {object: objRef, $
;                   method: 'Event_Hanlder'}
;
;       where "objRef" is a valid object reference with method "Event_Handler" to which
;       events will be forwarded.
;
;       When the keywords are structures, the following event handling functions will be
;       called::
;           FUNC_GET_VALUE: 'MrWidgetAtom_Func_Get_Value'
;           PRO_GET_VALUE : 'MrWidgetAtom_Pro_Get_Value'
;           KILL_NOTIFY   : 'MrWidgetAtom_Kill_Notify'
;           NOTIFY_REALIZE: 'MrWidgetAtom_Notify_Realize'
;           EVENT_PRO     : 'MrTopLevelBase_Event_Pro'
;           EVENT_FUNC    : 'MrTopLevelBase_Event_Func'
;
;       The above procedures/functions, then, will forward events to the method defined
;       in the structure, KWRD. This is true unless EVENT_PRO or EVENT_FUNC are defined
;       by the user. In this case, event hanlding will be undertaken by the given
;       procedure or function.
;
;   UVALUE
;       The UValue of the widget is automatically set equal to the class's object
;       object reference (self). This way the widget object is retrievable from within
;       event handling procedures and functions. It should not be changed. Instead, use
;       the UVALUE property of the object via the SetProperty and GetProperty methods.
;
;   CLEANUP:
;       If CLEANUP was not provided when XManager was initiated in the Draw method, then
;       XManager will forward cleanup detail to the procedure specified by KILL_NOTIFY.
;       If KILL_NOTIFY was not given when the object was created, MrTopLevelBase::Init
;       defaults to:
;
;           KILL_NOTIFY = 'MrWidgetAtom_Kill_Notify'
;           Method Event Handler: {object: self, $
;                                  method: 'Kill_Notify'}
;
;       Thus, when this widget is destroyed, MrWidgetAtom::Kill_Notify will be called
;       This method destroys the widget object reference.
;
;       If you do not want the widget object to be destroyed when the widget itself is
;       destroyed, you must provide a CLEANUP routine to the Draw method or a KILL_NOTIFY
;       routine when the object is created.
;
; :Author:
;   Matthew Argall::
;       University of New Hampshire
;       Morse Hall, Room 113
;       8 College Rd.
;       Durham, NH, 03824
;       matthew.argall@wildcats.unh.edu
;
; :History:
;	Modification History::
;       10/15/2013  -   Written by Matthew Argall
;-
;******************************************************************************************
;+
;   General event handler for the MrTopLevelBase widget class. Its purpose is to forward
;   the different events generated by the XManager to their respective event handling
;   methods.
;
; :Params:
;       EVENT:              in, optional, type=structure
;                           An event structure returned by the windows manager.
;-
pro MrTopLevelBase_Event_Pro, event
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif
    
    ;Type of event that was generated.
    event_name = size(event, /SNAME)
    widget_control, event.id, GET_UVALUE=oRef
    
;---------------------------------------------------------------------
;Callback Object /////////////////////////////////////////////////////
;---------------------------------------------------------------------
    ;If another object is handling events, forward the event and exit.
    oRef -> GetProperty, EVENT_HANDLER=event_handler
    if obj_valid(event_handler) then begin
        Call_Method, event_handler.method, event_handler.object, event
        return
    endif
    
;---------------------------------------------------------------------
;Callback Pro/Method /////////////////////////////////////////////////
;---------------------------------------------------------------------
    ;
    ; From the IDL HELP page:
    ;   If both TLB_SIZE_EVENTS and TLB_MOVE_EVENTS are enabled, a user resize operation
    ;   that causes the top left corner of the base to move will generate both a move
    ;   event and a resize event.
    ;
    ; This suggests that TLB_SIZE_EVENTS should be handled before TLB_MOVE_EVENTS so that
    ; the window is not moved before it is resized.
    ;
    
    ;Forward the event to the event-handling method
    case event_name of
        'WIDGET_BASE': begin
            oRef -> GetProperty, TLB_SIZE_HANDLER=size_handler
            case size(size_handler, /TNAME) of
                'STRUCT': Call_Method, size_handler.method, size_handler.object, event
                'STRING': if size_handler ne '' then Call_Procedure, size_handler, event
            endcase
        endcase
        
        'WIDGET_TLB_ICONIFY': begin
            oRef -> GetProperty, TLB_ICONIFY_HANDLER=iconify_handler
            case size(iconify_handler, /TNAME) of
                'STRUCT': Call_Method, iconify_handler.method, iconify_handler.object, event
                'STRING': if iconify_handler ne '' then Call_Procedure, iconify_handler, event
            endcase
        endcase
        
        'WIDGET_TLB_MOVE': begin
            oRef -> GetProperty, TLB_MOVE_HANDLER=move_handler
            case size(move_handler, /TNAME) of
                'STRUCT': Call_Method, move_handler.method, move_handler.object, event
                'STRING': if move_handler ne '' then Call_Procedure, move_handler, event
            endcase
        endcase
                
        'WIDGET_KILL_REQUEST': begin
            oRef -> GetProperty, TLB_KILL_REQUEST_HANDLER=kill_request_handler
            case size(kill_request_handler, /TNAME) of
                'STRUCT': Call_Method, kill_request_handler.method, kill_request_handler.object, event
                'STRING': if kill_request_handler ne '' then Call_Procedure, kill_request_handler, event
            endcase
        endcase
            
        else: MrWidgetBase_Event_Pro, event
    endcase
end


;+
;   Event handling function for Event_Func.
;
; :Params:
;       EVENT:              in, optional, type=structure
;                           An event structure returned by the windows manager.
;-
function MrTopLevelBase_Event_Func, event
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return, 0
    endif
    
    ;Type of event that was generated.
    event_name = size(event, /SNAME)
    widget_control, event.id, GET_UVALUE=oRef
    
;---------------------------------------------------------------------
;Callback Object /////////////////////////////////////////////////////
;---------------------------------------------------------------------
    ;If another object is handling events, forward the event and exit.
    oRef -> GetProperty, EVENT_HANDLER=event_handler
    if obj_valid(event_handler) then begin
        result = Call_Method(event_handler.method, event_handler.object, event)
        return, result
    endif
    
;---------------------------------------------------------------------
;Callback Func/Method ////////////////////////////////////////////////
;---------------------------------------------------------------------
    ;
    ; From the IDL HELP page:
    ;   If both TLB_SIZE_EVENTS and TLB_MOVE_EVENTS are enabled, a user resize operation
    ;   that causes the top left corner of the base to move will generate both a move
    ;   event and a resize event.
    ;
    ; This suggests that TLB_SIZE_EVENTS should be handled before TLB_MOVE_EVENTS so that
    ; the window is not moved before it is resized.
    ;
    
    ;Forward the event to the event-handling method
    case event_name of
        'WIDGET_BASE': begin
            oRef -> GetProperty, SIZE_EVENT_HANDLER=size_handler
            case size(size_handler, /TNAME) of
                'OBJREF': result = Call_Method(size_handler.method, size_handler.object, event)
                'STRING': if size_handler ne '' then result = Call_Function(size_handler, event)
            endcase
        endcase
        
        'WIDGET_TLB_ICONIFY': begin
            oRef -> GetProperty, ICONIFY_EVENT_HANDLER=iconify_handler
            case size(iconify_handler, /TNAME) of
                'OBJREF': result = Call_Method(iconify_handler.method, context_eh.object, event)
                'STRING': if iconify_handler ne '' then result = Call_Function(iconify_handler, event)
            endcase
        endcase
        
        'WIDGET_TLB_MOVE': begin
            oRef -> GetProperty, MOVE_EVENT_HANDLER=move_handler
            case size(move_handler, /TNAME) of
                'OBJREF': result = Call_Method(move_handler.method, move_handler.object, event)
                'STRING': if move_handler ne '' then result = Call_Function(move_handler, event)
            endcase
        endcase
                
        'WIDGET_KILL_REQUEST': begin
            oRef -> GetProperty, KILL_REQUEST_EVENT_HANDLER=kill_request_handler
            case size(kill_request_handler, /TNAME) of
                'OBJREF': result = Call_Method(kill_request_handler.method, kill_request_handler.object, event)
                'STRING': if kill_request_handler ne '' then result = Call_Function(kill_request_handler, event)
            endcase
        endcase
            
        else: result = MrWidgetBase_Event_Func(event)
    endcase
    
    return, result
end


;+
;   Event handling function for TLB_Iconify_Events.
;
; :Params:
;       EVENT:              in, optional, type=structure
;                           An event structure returned by the windows manager.
;-
function MrTopLevelBase::Iconify_Events, event
    ;Nothing to do yet.
end


;+
;   Event handling function for TLB_Kill_Request_Events.
;
; :Params:
;       EVENT:              in, optional, type=structure
;                           An event structure returned by the windows manager.
;-
function MrTopLevelBase::Kill_Request_Events, event
    ;Nothing to do yet.
end


;+
;   This method is used to obtain the MrTopLevelBase object's properties
;
; KEYWORDS:
;
;       ICONIFY_EVENTS: Set to 1 if ICONIFY events are set for this top-level base widget.
;
;       MAP:            Returns a 0 or 1 to indicate if the current base widget hierarchy is
;                       mapped (1) or not (0).
;
;       MODAL:          Returns a 0 or 1 to indicate if the current base widget hierarchy is modal (1) or not (0).
;
;       MOVE_EVENTS:    Set to 1 if move events are set for this top-level base widget.
;
;       SIZE_EVENTS:    Set to 1 if size events are set for this top-level base widget.
;
;       _EXTRA:         Any keyword appropriate for the supercalss Draw methods.
;-
PRO MrTopLevelBase::GetProperty, $
 MODAL=modal, $
 TITLE=title, $
 TLB_FRAME_ATTR=tlb_frame_attr, $
 
 ;Events
 TLB_ICONIFY_EVENTS=tlb_iconify_events, $
 TLB_KILL_REQUEST_EVENTS=tlb_kill_request_events, $
 TLB_MOVE_EVENTS=tlb_move_events, $
 TLB_SIZE_EVENTS=tlb_size_events, $
 
 ;Event Hanlders
 TLB_ICONTIFY_HANDLER=tlb_iconify_handler, $
 TLB_KILL_REQUEST_HANDLER=tlb_kill_request_handler, $
 TLB_MOVE_HANDLER=tlb_move_handler, $
 TLB_SIZE_HANDLER=tlb_size_handler, $
_REF_EXTRA=extra
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif

    if arg_present(tlb_frame_attr) then tlb_frame_attr = self._tlb_frame_attr
    if arg_present(title)          then title          = self.title
    
;---------------------------------------------------------------------
;Widget_Info & Widget_Control Options ////////////////////////////////
;---------------------------------------------------------------------
    if arg_present(modal) then modal = widget_info(self._id, /MODAL)
    
    ;Superclasses
    if n_elements(extra) ne 0 then self -> MrWidgetBase::GetProperty, _STRICT_EXTRA=extra
    
;---------------------------------------------------------------------
;Are Events On or Off? ///////////////////////////////////////////////
;---------------------------------------------------------------------
    if arg_present(tlb_iconify_events)      then iconify_events          = widget_info(self._id, /TLB_ICONIFY_EVENTS)
    if arg_present(tlb_kill_request_events) then tlb_kill_request_events = widget_info(self._id, /TLB_KILL_REQUEST_EVENTS)
    if arg_present(tlb_move_events)         then move_events             = widget_info(self._id, /TLB_MOVE_EVENTS)
    if arg_present(tlb_size_events)         then size_events             = widget_info(self._id, /TLB_SIZE_EVENTS)
    
;---------------------------------------------------------------------
;Callback Func/Pro/Method/Object /////////////////////////////////////
;---------------------------------------------------------------------
    if arg_present(tlb_iconify_handler)      then tlb_iconify_handler      = *self._tlb_iconify_handler
    if arg_present(tlb_kill_request_handler) then tlb_kill_request_handler = *self._tlb_kill_request_handler
    if arg_present(tlb_move_handler)         then tlb_move_handler         = *self._tlb_move_handler
    if arg_present(tlb_size_handler)         then tlb_size_handler         = *self._tlb_size_handler
    
end


;+
;   Event handling function for TLB_Move_Events.
;
; :Params:
;       EVENT:              in, optional, type=structure
;                           An event structure returned by the windows manager.
;-
function MrTopLevelBase::Move_Events, event
    ;Nothing to do yet.
end


;+
;   This is a utility method to position the top-level base
;   on the display at an arbitrary location. By default the
;   widget is centered on the display.
;
; INPUTS:
;
;       x:  Set this equal to a normalized position for the center
;           of the widget as measured from the left-hand side of the screen.
;           The default value is 0.5 (the center)  Setting this equal to 1.0
;           places the widget at the far right-hand side of the screen.
;
;       y:  Set this equal to a normalized position for the center
;           of the widget as measured from the top of the screen.
;           The default value is 0.5 (the center) Setting this equal to 1.0
;           places the widget at the top of the screen.
;
; KEYWORDS:
;
;      DEVICE:   Normally, the x and y parameters are specified in normalized
;                coordinates. If this keyword is set, they are taken to be in DEVICE
;                coordinates.
;
;      NOCENTER: Typically, the center of the widget is positioned at the
;                x, y point. Setting this keyword, forces the top-left
;                corner to be at x, y.
;-
pro MrTopLevelBase::Position, x, y, $
DEVICE=device, $
NOCENTER=nocenter
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif

    if n_elements(x) eq 0 then xc = 0.5 else xc = float(x[0])
    if n_elements(y) eq 0 then yc = 0.5 else yc = float(y[0])
    center = 1 - keyword_set(nocenter)
    
    screensize = get_screen_size()
    if screensize[0] gt 2000 then screensize[0] = screensize[0]/2 ; dual monitors.
    if ~keyword_set(device) then begin ; normalized coordinates
       xcenter = screensize[0] * xc
       ycenter = screensize[1] * yc
    endif else begin ; device coordinates
       xcenter = xc
       ycenter = yc
    endelse
    
    ; get the screen sizes of the tlb. divide by 2.
    geom = widget_info(self._id, /GEOMETRY)
    xhalfsize = geom.scr_xsize / 2
    yhalfsize = geom.scr_ysize / 2
    
    ; are you centering, or placing upper-left corner?
    if center then begin
       xoffset = 0 > (xcenter - xhalfsize) < (screensize[0] - geom.scr_xsize)
       yoffset = 0 > (ycenter - yhalfsize) < (screensize[1] - geom.scr_ysize)
    endif else begin
       xoffset = xcenter
       yoffset = ycenter
    endelse
    
    ; set the offsets.
    widget_control, self._id, xoffset=xoffset, yoffset=yoffset

end


;+
;   This method is used to realize the widget hierarchy.
;-
pro MrTopLevelBase::Realize
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif

    ; Realize the widget hierarchy.
    if self._centertlb then self -> Position
    widget_control, self._id, /REALIZE
end


;+
;   This method is used to set the MrTopLevelBase object's properties
;-
pro MrTopLevelBase::SetProperty, $
 CENTER=center, $
 TITLE=title, $
 TLB_FRAME_ATTR=tlb_frame_attr, $
 
 ;Turn Events On or Off
 TLB_ICONIFY_EVENTS=tlb_iconify_events, $
 TLB_KILL_REQUEST_EVENTS=tlb_kill_request_events, $
 TLB_MOVE_EVENTS=tlb_move_events, $
 TLB_SIZE_EVENTS=tlb_size_events, $
 
 ;Callback Functions/Methods/Procedures
 TLB_ICONIFY_HANDLER=tlb_iconify_handler, $
 TLB_KILL_REQUEST_HANDLER=tlb_kill_request_handler, $
 TLB_MOVE_HANDLER=tlb_move_handler, $
 TLB_SIZE_HANDLER=tlb_size_handler, $
_REF_EXTRA=extra
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif

    if n_elements(center) gt 0 then self._centerTLB = keyword_set(center)
    
;---------------------------------------------------------------------
;Widget_Control Options //////////////////////////////////////////////
;---------------------------------------------------------------------
    if n_elements(title) ne 0 then widget_control, self._id, TLB_SET_TITLE=title
    
    ;Superclass
    if n_elements(extra) gt 0 then self -> MrWidgetBase::SetProperty, _STRICT_EXTRA=extra
    
;---------------------------------------------------------------------
;Turn Events On or Off ///////////////////////////////////////////////
;---------------------------------------------------------------------
    if n_elements(tlb_iconify_events)      gt 0 then widget_control, self._id, TLB_ICONIFY_EVENTS=keyword_set(tlb_iconify_events)
    if n_elements(tlb_kill_request_events) gt 0 then widget_control, self._id, TLB_KILL_REQUEST_EVENTS=keyword_set(tlb_kill_request_events)
    if n_elements(tlb_move_events)         gt 0 then widget_control, self._id, TLB_MOVE_EVENTS=keyword_set(tlb_move_events)
    if n_elements(tlb_size_events)         gt 0 then widget_control, self._id, TLB_SIZE_EVENTS=keyword_set(tlb_size_events)

;---------------------------------------------------------------------
;Callback Functions/Methods/Procedures ///////////////////////////////
;---------------------------------------------------------------------
    ;TLB_ICONIFY_HANDLER
    if n_elements(tlb_iconify_handler) gt 0 then begin
        case size(tlb_iconify_handler, /TNAME) of
            'STRUCT': begin
                test = {MrEventHandler}
                struct_assign, tlb_iconify_handler, test
                *self._tlb_iconify_handler = test
            endcase
            
            'STRING': *self._tlb_iconify_handler = tlb_iconify_handler            
            else: message, 'TLB_ICONIFY_HANDLER must be a string or structure.'
        endcase
    endif
    
    ;TLB_KILL_REQUEST_HANDLER
    if n_elements(tlb_kill_request_handler) gt 0 then begin
        case size(tlb_kill_request_handler, /TNAME) of
            'STRUCT': begin
                test = {MrEventHandler}
                struct_assign, tlb_kill_request_handler, test
                *self._tlb_kill_request_handler = test
            endcase
            
            'STRING': *self._tlb_kill_request_handler = tlb_kill_request_handler            
            else: message, 'TLB_KILL_REQUEST_HANDLER must be a string or structure.'
        endcase
    endif
    
    ;TLB_MOVE_HANDLER
    if n_elements(tlb_move_handler) gt 0 then begin
        case size(tlb_move_handler, /TNAME) of
            'STRUCT': begin
                test = {MrEventHandler}
                struct_assign, tlb_move_handler, test
                *self._tlb_move_handler = test
            endcase
            
            'STRING': *self._tlb_move_handler = tlb_move_handler            
            else: message, 'TLB_MOVE_HANDLER must be a string or structure.'
        endcase
    endif
    
    ;TLB_SIZE_HANDLER
    if n_elements(tlb_size_handler) gt 0 then begin
        case size(tlb_size_handler, /TNAME) of
            'STRUCT': begin
                test = {MrEventHandler}
                struct_assign, tlb_size_handler, test
                *self._tlb_size_handler = test
            endcase
            
            'STRING': *self._tlb_size_handler = tlb_size_handler            
            else: message, 'TLB_SIZE_HANDLER must be a string or structure.'
        endcase
    endif
END


;+
;   Event handling function for TLB_Size_Events.
;
; :Params:
;       EVENT:              in, optional, type=structure
;                           An event structure returned by the windows manager.
;-
function MrTopLevelBase::Size_Events, event
    ;Nothing to do yet.
end


;+
;   This method is used to realize and draw the widget hierarchy. It also starts
;   XMANAGER to managing the widget hierarchy.
;
; KEYWORDS:
;
;       BLOCK:         Set this keyword to create a blocking widget hierarchy.
;
;       CENTER:        Set this keyword to center the TLB before display.
;
;       REGISTER_NAME: The name by which the program will be registered with XManager.
;
;       GROUP_LEADER:  The widget identifier of a group leader for this widget hierarchy.
;
;       JUST_REGISTER: Set his keyword to just register with XManager, but not to fire it up.
;
;       _EXTRA:        To pass additional keywords BaseWidget::Draw
;-
PRO MrTopLevelBase::XManager, $
CENTER=center, $
EVENT_HANDLER = event_handler, $
REGISTER_NAME=register_name, $
BLOCK=block, $
GROUP_LEADER=group_leader, $
JUST_REGISTER=just_register, $
XOFFSET=xoffset, $
YOFFSET=yoffset
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif

    ;Event Handler
    if n_elements(event_handler) eq 0 then begin
         if self._event_pro ne '' $
            then event_handler = self._event_pro $
            else event_handler = 'MrTopLevelBase_Event_Pro'
    endif

    ;Position the base on the screen
    if keyword_set(center) $
        then self -> Position $
        else if (n_elements(xoffset) ne 0) or (n_elements(yoffset) ne 0) $
            then self -> Position, xoffset, yoffset

    ;Get a unique name if one is not provided.
    if self._register_name eq "" then begin
        if (n_elements(register_name) eq 0) $
            then self._register_name = 'Program_' + strtrim(self._id, 2) $
            else self._register_name = register_name
    endif

    ;Realize the widget hierarchy.
    if widget_info(self._id, /REALIZED) eq 0 then self -> Realize

    ;Start xmanager
    if keyword_set(just_register) then begin
        xmanager, self._register_name, self._id, JUST_REG=1, /NO_BLOCK, $
                  EVENT_HANDLER=event_handler, CLEANUP=cleanup
    endif else begin
        xmanager, self._register_name, self._id, GROUP_LEADER=group_leader, $
                  NO_BLOCK=1-keyword_set(block), EVENT_HANDLER=event_handler
    endelse
end


;+
;   This is the MrTopLevelBase object class destructor method.
;-
pro MrTopLevelBase::CLEANUP
    compile_opt strictarr
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return
    endif
    
    ;Free event handlers (but do not destroy event handling objects)
    ptr_free, self._tlb_iconify_handler
    ptr_free, self._tlb_kill_request_handler
    ptr_free, self._tlb_move_handler
    ptr_free, self._tlb_size_handler
    
    ;Clean up the superclasses
    self -> MrWidgetBase::Cleanup
end


;+
;   This is the MrTopLevelBase object class initialization method
;
; :Keywords:
;       EVENT_FUNC:             in, optional, type=string, default=''
;                               A string specifying the name of a function to be called
;                                   when events are generated. This procedure will handle
;                                   `TLB_SIZE_EVENTS`, `TLB_MOVE_EVENTS`, `TLB_IDONIFY_EVENTS`,
;                                   `KBRD_FOCUS_EVENTS`, `TLB_KILL_REQUEST_EVENTS`, and
;                                   `CONTEXT_EVENTS`. If neither `EVENT_FUNC` nor `EVENT_PRO`
;                                   are set and these keywords are structures, the default
;                                   is to use 'MrTopLevelBase_Event_Pro' to forward events
;                                   (see `EVENT_PRO`). If the methods given are functions,
;                                   set this keyword to 'MrTopLevelBase_Event_Func' instead.
;       EVENT_PRO:              in, optional, type=string, default=''
;                               A string specifying the name of a procedure to be called
;                                   when events are generated. This procedure will handle
;                                   `TLB_SIZE_EVENTS`, `TLB_MOVE_EVENTS`, `TLB_IDONIFY_EVENTS`,
;                                   `KBRD_FOCUS_EVENTS`, `TLB_KILL_REQUEST_EVENTS`, and
;                                   `CONTEXT_EVENTS`. These keywords can be structures
;                                   (instead of boolean values) of the form::
;                                       KWRD = {object: objRef, $
;                                               method: 'Event_Handler'}
;                                   where "objRef" is a valid object reference and
;                                   "Event_Handler" is a string containing the name of a
;                                   method to be used to handle events. In this case, the
;                                   procedure 'MrTopLevelBase_Event_Pro' will forward events
;                                   to the proper event handling method. Finally, note that
;                                   if XManager is handling events, top level bases should
;                                   use the EVENT_HANDLER keyword to XManager instead of
;                                   EVENT_PRO. If XManager is called (in the Draw method)
;                                   and EVENT_HANDLER is not specified, then EVENT_PRO will
;                                   be used (if provided).
;       FUNC_GET_VALUE:         in, optional, type=string/structure, default=''
;                               A string specifying the name of a function to be called
;                                   when the value of the base is changed. If a structure
;                                   is provided (see `EVENT_PRO`), then 'MrTopLevelBase_Func_Get_Value'
;                                   will forward events to the given object method.
;       KBRD_FOCUS_EVENTS:      in, optional, type=boolean/structure, default=0
;                               If set, keyboard focus events will be turned on. See
;                                   `EVENT_PRO` for handling events with object methods.
;       KILL_NOTIFY:            in, optional, type=string/structure, default=''
;                               A string containing the name of a procedure to be called
;                                   when the widget dies. If a structure is provided
;                                   (see `EVENT_PRO`), then 'MrTopLevelBase_Kill_Notify'
;                                   will forward events to the given object method.
;       NOTIFY_REALIZE:         in, optional, type=string/structure, default=''
;                               A string containing the name of a procedure to be called
;                                   when the widget is realized. If a structure is provided
;                                   (see `EVENT_PRO`), then 'MrTopLevelBase_Notify_Realize'
;                                   will forward events to the given object method.
;       PRO_GET_VALUE:          in, optional, type=string, default=''
;                               A string specifying the name of a function to be called
;                                   when the value of the base is changed. If a structure
;                                   is provided (see `EVENT_PRO`), then 'MrTopLevelBase_Pro_Get_Value'
;                                   will forward events to the given object method.
;       TLB_ICONIFY_EVENTS:     in, optional, type=boolean/structure, default=0
;                               If set, TLB size events will be turned on. See `EVENT_PRO`
;                                   for handling events with object methods.
;      TLB_KILL_REQUEST_EVENTS: in, optional, type=boolean/structure, default=0
;                               If set, TLB kill request events will be turned on. See
;                                   `EVENT_PRO` for handling events with object methods.
;       TLB_MOVE_EVENTS:        in, optional, type=boolean/structure, default=0
;                               If set, TLB move events will be turned on. See `EVENT_PRO`
;                                   for handling events with object methods.
;       TLB_SIZE_EVENTS:        in, optional, type=boolean/structure, default=0
;                               If set, TLB size events will be turned on. See `EVENT_PRO`
;                                   for handling events with object methods.
;       _REF_EXTRA:             in, optional, type=any
;                               Any keyword accepted by IDL's `WIDGET_BASE
;                                   <http://www.exelisvis.com/docs/WIDGET_BASE.html>`
;                                   procedure is also accepted for keyword inheritance.
;-
function MrTopLevelBase::init, $
 ALIGN_BOTTOM=align_bottom,$
 ALIGN_CENTER=align_center, $
 ALIGN_LEFT=align_left, $
 ALIGN_RIGHT=align_right, $
 ALIGN_TOP=align_top, $
 BASE_ALIGN_BOTTOM=base_align_bottom, $
 BASE_ALIGN_CENTER=base_align_center, $
 BASE_ALIGN_LEFT=base_align_left, $
 BASE_ALIGN_RIGHT=base_align_right, $
 BASE_ALIGN_TOP=base_align_top, $
 BITMAP=bitmap, $
 COLUMN=column, $
 CONTEXT_EVENTS=context_events, $
 CONTEXT_HANDLER=context_handler, $
 CONTEXT_MENU=context_menu, $
 EXCLUSIVE=exclusive, $
 FLOATING=floating, $
 FRAME=frame, $
 GRID_LAYOUT=grid_layout, $
 GROUP_LEADER=group_leader, $
 KBRD_FOCUS_EVENTS=kbrd_focus_events, $
 KBRD_FOCUS_HANDLER=kbrd_focus_handler, $
 MBAR=mbar, $
 MAP=map, $
 MODAL=modal, $
 NONEXCLUSIVE=nonexclusive, $
 NOTIFY_REALIZE=notify_realize, $
 ROW=row, $
 SCR_XSIZE=scr_xsize, $
 SCR_YSIZE=scr_ysize, $
 SCROLL=scroll, $
 SPACE=space, $
 TITLE=title, $
 TLB_FRAME_ATTR=tlb_frame_attr, $
 TLB_ICONIFY_EVENTS=tlb_iconify_events, $
 TLB_ICONIFY_HANDLER=tlb_iconify_handler, $
 TLB_KILL_REQUEST_EVENTS=tlb_kill_request_events, $
 TLB_KILL_REQUEST_HANDLER=tlb_kill_request_handler, $
 TLB_MOVE_EVENTS=tlb_move_events, $
 TLB_MOVE_HANDLER=tlb_move_handler, $
 TLB_SIZE_EVENTS=tlb_size_events, $
 TLB_SIZE_HANDLER=tlb_size_handler, $
 TOOLBAR=toolbar, $
 UNITS=units, $
 X_SCROLL_SIZE=x_scroll_size, $
 XOFFSET=xoffset, $
 XPAD=xpad, $
 XSIZE=xsize, $
 Y_SCROLL_SIZE=y_scroll_size, $
 YOFFSET=yoffset, $
 YPAD=ypad, $
 YSIZE=ysize, $
_REF_EXTRA=extra
    
    ;Error handling
    catch, the_error
    if the_error ne 0 then begin
        catch, /cancel
        void = cgErrorMsg()
        return, 0
    endif
    
    ;Defaults
    if n_elements(title) eq 0 then title = 'MrTopLevelBase'
    
    ;Default handlers
    if n_elements(tlb_iconify_handler)      eq 0 then tlb_iconify_handler      = {obj: self, method: 'Iconify_Events'}
    if n_elements(tlb_kill_request_handler) eq 0 then tlb_kill_request_handler = {obj: self, method: 'Kill_Request_Events'}
    if n_elements(tlb_move_handler)         eq 0 then tlb_move_handler         = {obj: self, method: 'Move_Events'}
    if n_elements(tlb_size_handler)         eq 0 then tlb_size_handler         = {obj: self, method: 'Size_Events'}

    ;Allocate Heap
    self._tlb_iconify_handler      = ptr_new(/ALLOCATE_HEAP)
    self._tlb_kill_request_handler = ptr_new(/ALLOCATE_HEAP)
    self._tlb_move_handler         = ptr_new(/ALLOCATE_HEAP)
    self._tlb_size_handler         = ptr_new(/ALLOCATE_HEAP)

;---------------------------------------------------------------------
;Allow Only One Instance? ////////////////////////////////////////////
;---------------------------------------------------------------------
    if n_elements(register_name) ne 0 then self._register_name = register_name
        if keyword_set(only_one) then begin
            if self._register_name ne "" then begin
                test = xregistered(self._register_name, /NOSHOW)
                if test ne 0 then begin
                message, 'Only one version of this application can be running at the same time. Returning...', /INFORMATIONAL
                return, 0
            endif
        endif
    endif

;---------------------------------------------------------------------
;Floating Widget? ////////////////////////////////////////////////////
;---------------------------------------------------------------------
    if keyword_set(floating) then begin
        ;Was a group leader defined?
        if n_elements(group_leader) eq 0 then $
            message, 'Floating top-level bases must have a group leader defined for them.'
    endif

;---------------------------------------------------------------------
;Modal Widget? ///////////////////////////////////////////////////////
;---------------------------------------------------------------------
    if keyword_set(modal) then begin
        ;Can never have menu bars, ever.
        if (menu eq 1) then begin
            message, 'Modal widgets cannot have menubars. Setting MENU=0', /INFORMATIONAL
            menu = 0
        endif
        
        ;Must have a group leader.
        if n_elements(group_leader) eq 0 then $
            message, 'Modal top-level bases must have a group leader defined for them.'
            
        ;Modal widgets cannot be unmapped
        if n_elements(map) gt 0 then begin
            message, 'Modal widgets cannot be mapped or unmapped. Ignoring MAP.', /INFORMATIONAL
            void = temporary(map)
        endif
        
        ;Cannot specify SCROLL and MODAL
        if n_elements(scroll) gt 0 then begin
            message, 'SCROLL cannot be used with MODAL. Setting SCROLL=0' /INFORMATIONAL
            void = temporary(scroll)
        endif
    endif

;---------------------------------------------------------------------
;Create the Widget ///////////////////////////////////////////////////
;---------------------------------------------------------------------

    ;If MBAR is present, a menu bar will be created no matter what.
    if arg_present(mbar) then begin
        self._id = WIDGET_BASE( $
                                ALIGN_BOTTOM            = align_bottom,$
                                ALIGN_CENTER            = align_center, $
                                ALIGN_LEFT              = align_left, $
                                ALIGN_RIGHT             = align_right, $
                                ALIGN_TOP               = align_top, $
                                BASE_ALIGN_BOTTOM       = base_align_bottom, $
                                BASE_ALIGN_CENTER       = base_align_center, $
                                BASE_ALIGN_LEFT         = base_align_left, $
                                BASE_ALIGN_RIGHT        = base_align_right, $
                                BASE_ALIGN_TOP          = base_align_top, $
                                BITMAP                  = bitmap, $
                                COLUMN                  = column, $
                                CONTEXT_EVENTS          = context_events, $
                                CONTEXT_MENU            = context_menu, $
                                EXCLUSIVE               = exclusive, $
                                FLOATING                = floating, $
                                FRAME                   = frame, $
                                GRID_LAYOUT             = grid_layout, $
                                GROUP_LEADER            = group_leader, $
                                KBRD_FOCUS_EVENTS       = kbrd_focus_events, $
                                MBAR                    = mbar, $
                                MAP                     = map, $
                                MODAL                   = modal, $
                                NONEXCLUSIVE            = nonexclusive, $
; Set in MrWidgetAtom::Init     NOTIFY_REALIZE          = notify_realize, $
                                ROW                     = row, $
                                SCR_XSIZE               = scr_xsize, $
                                SCR_YSIZE               = scr_ysize, $
                                SCROLL                  = scroll, $
                                SPACE                   = space, $
                                TITLE                   = title, $
                                TLB_FRAME_ATTR          = tlb_frame_attr, $
                                TLB_ICONIFY_EVENTS      = tlb_iconify_events, $
                                TLB_KILL_REQUEST_EVENTS = tlb_kill_request_events, $
                                TLB_MOVE_EVENTS         = tlb_move_events, $
                                TLB_SIZE_EVENTS         = tlb_size_events, $
                                TOOLBAR                 = toolbar, $
                                UNITS                   = units, $
                                X_SCROLL_SIZE           = x_scroll_size, $
                                XOFFSET                 = xoffset, $
                                XPAD                    = xpad, $
                                XSIZE                   = xsize, $
                                Y_SCROLL_SIZE           = y_scroll_size, $
                                YOFFSET                 = yoffset, $
                                YPAD                    = ypad, $
                                YSIZE                   = ysize $
                              )
    
    ;Otherwise, MBAR must be omitted.
    endif else begin
        self._id = WIDGET_BASE( $
                                ALIGN_BOTTOM            = align_bottom,$
                                ALIGN_CENTER            = align_center, $
                                ALIGN_LEFT              = align_left, $
                                ALIGN_RIGHT             = align_right, $
                                ALIGN_TOP               = align_top, $
                                BASE_ALIGN_BOTTOM       = base_align_bottom, $
                                BASE_ALIGN_CENTER       = base_align_center, $
                                BASE_ALIGN_LEFT         = base_align_left, $
                                BASE_ALIGN_RIGHT        = base_align_right, $
                                BASE_ALIGN_TOP          = base_align_top, $
                                BITMAP                  = bitmap, $
                                COLUMN                  = column, $
                                CONTEXT_MENU            = context_menu, $
                                EXCLUSIVE               = exclusive, $
                                FLOATING                = floating, $
                                FRAME                   = frame, $
                                GRID_LAYOUT             = grid_layout, $
                                GROUP_LEADER            = group_leader, $
                                KBRD_FOCUS_EVENTS       = kbrd_focus_events, $
; Must Be Omitted!!             MBAR                    = mbar, $
                                MAP                     = map, $
                                MODAL                   = modal, $
                                NONEXCLUSIVE            = nonexclusive, $
                                ROW                     = row, $
                                SCR_XSIZE               = scr_xsize, $
                                SCR_YSIZE               = scr_ysize, $
                                SCROLL                  = scroll, $
                                SPACE                   = space, $
                                TITLE                   = title, $
                                TLB_FRAME_ATTR          = tlb_frame_attr, $
                                TLB_ICONIFY_EVENTS      = tlb_iconify_events, $
                                TLB_KILL_REQUEST_EVENTS = tlb_kill_request_events, $
                                TLB_MOVE_EVENTS         = tlb_move_events, $
                                TLB_SIZE_EVENTS         = tlb_size_events, $
                                TOOLBAR                 = toolbar, $
                                UNITS                   = units, $
                                X_SCROLL_SIZE           = x_scroll_size, $
                                XOFFSET                 = xoffset, $
                                XPAD                    = xpad, $
                                XSIZE                   = xsize, $
                                Y_SCROLL_SIZE           = y_scroll_size, $
                                YOFFSET                 = yoffset, $
                                YPAD                    = ypad, $
                                YSIZE                   = ysize $
                              )
    endelse  

;---------------------------------------------------------------------
;Superclass INIT /////////////////////////////////////////////////////
;---------------------------------------------------------------------

    ;Widget must be realized first (i.e. via Widget_Base())
    success = self -> MrWidgetAtom::INIT(NOTIFY_REALIZE=notify_realize, _STRICT_EXTRA=extra)
    if success eq 0 then message, 'MrWidgetAtom could not be initialized.'
    
    ;Set the callback func/pro -- must be after MrWidgetAtom is initialized.
    if keyword_set(function_callback) $
        then self -> _Set_Event_Func, 'MrTopLevelBase_Event_Func' $
        else self -> _Set_Event_Pro,  'MrTopLevelBase_Event_Pro'
    
    self -> SetProperty, TITLE=title, $
                         CENTER=center, $
                         CONTEXT_HANDLER=context_handler, $
                         KBRD_FOCUS_HANDLER=kbrd_focus_handler, $
                         TLB_FRAME_ATTR=tlb_frame_attr, $
                         TLB_ICONIFY_HANDLER=tlb_iconify_handler, $
                         TLB_KILL_REQUEST_HANDLER=tlb_kill_request_handler, $
                         TLB_MOVE_HANDLER=tlb_move_handler, $
                         TLB_SIZE_HANDLER=tlb_size_handler
                         
;---------------------------------------------------------------------
;Create the Widget ///////////////////////////////////////////////////
;---------------------------------------------------------------------

    ;Set the user value of the widget as the TLB object reference.
    widget_control, self._id, SET_UVALUE=self
    
    return, 1
end


;+
;   The class definition statement.
;
; :Fields:
;       _ID:                    Widget ID of the top level base
;       _ICONIFY_HANDLER:       Method event handler for iconify events.
;       _KILL_REQUEST_HANDLER:  Method event handler for kill request events.
;       _MOVE_HANDLER:          Method event handler for move events.
;       _SIZE_HANDLER:          Method event handler for size events.
;
; :Params:
;       CLASS:          out, optional, type=structure
;                       The class definition structure.
;-
pro MrTopLevelBase__define, class
    compile_opt strictarr

    class =  { MrTopLevelBase, $         ; The MrTopLevelBase object class name.
               inherits MrWidgetBase, $

               ;Event Handling Methods
               _tlb_iconify_handler:      ptr_new(), $
               _tlb_kill_request_handler: ptr_new(), $
               _tlb_move_handler:         ptr_new(), $
               _tlb_size_handler:         ptr_new(), $
               _centerTLB:                0L, $
               _register_name:            "" $
            }
end
