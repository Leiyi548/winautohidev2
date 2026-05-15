#Requires AutoHotkey v2.0
#include Array.ahk
#include DPI.ahk
#include WinEvent.ahk

WinEvent.Active(ActiveWindowChanged)
Persistent()
OnExit(ExitCleanup)
showTmp:=1
global showTmp
ActiveWindowChanged(hWnd, *) {
	global showTmp
	
	; 过滤掉无效句柄或系统托盘/任务栏等窗口
	if !hWnd || !WinExist("ahk_id" hWnd)
		return
		
	; 过滤掉任务切换窗口 (Alt+Tab), 开始菜单, 任务栏等
	try {
		class := WinGetClass("ahk_id" hWnd)
		; log("ActiveWindowChanged: hWnd=" hWnd " Class=" class)
		if (class ~= "i)^(MultitaskingViewFrame|Shell_TrayWnd|Shell_SecondaryTrayWnd|Windows\.Internal\.Shell\.Experience\.TextAreaContextView|Button|ComboLBox|TaskSwitcherWnd|WorkerW|Progman)$")
			return
	}

	hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =hWnd))
	; 只有当鼠标真的在窗口位置附近，或者是有意激活时才显示
	if hiddenWindowIndex>0 {
		; 检查鼠标是否在屏幕边缘（如果是任务切换导致的激活，鼠标通常不在边缘）
		MouseGetPos &mx, &my
		window := hiddenWindowList.Get(hiddenWindowIndex)
		
		; 如果是通过键盘任务切换激活的，我们检查鼠标是否在触发区域
		; 如果鼠标不在边缘区域，我们认为这是非主动触发，不予显示
		; 这里的逻辑是：如果窗口被激活，但鼠标不在窗口范围内，则不显示
		windowText := "ahk_id " . window.id
		WinGetPos(&wx, &wy, &ww, &wh, windowText)
		if !(mx >= wx && mx <= wx + ww && my >= wy && my <= wy + wh) {
			; 虽然被激活了，但鼠标不在它上面，说明是任务切换导致的“虚假激活”
			; 我们不做任何操作，让它继续保持隐藏状态
			return
		}

		showWindow(window)
		showTmp := 1
	}
}
; 实现窗口平滑移动，越小越平滑，最小为-1
SetWinDelay(0.5)

; 隐藏时留出的长度以及显示时距离屏幕边缘的长度
; 由于DPI关系，margin设置，不同DPI可能不同
margin := 35
showMargin := 0
global margin
global showMargin
; 移动范围
moveDistance := 30
global moveDistance

; 隐藏的窗口
hiddenWindowList := []
global hiddenWindowList
; 中间态窗口，鼠标放置暂时显示的窗口
suspendWindowList := []
global suspendWindowList

maxHeight := 800

TraySetIcon("./assest/移动窗口.png")
; 加入右键菜单
myMenu := A_TrayMenu
myMenu.Delete()
myMenu.Add("重置所有贴边窗口", Reset)
myMenu.SetIcon("重置所有贴边窗口", "imageres.dll", 230)

myMenu.Add("退出", (*) => ExitApp())
myMenu.SetIcon("退出", "imageres.dll", 231)

ExitCleanup(*) {
	; 记录当前活跃窗口，以便最后恢复焦点
	originalActive := WinActive("A")
	
	; 恢复所有隐藏和中间态的窗口
	restoreList := []
	Loop hiddenWindowList.Length {
		restoreList.Push(hiddenWindowList.Get(A_Index))
	}
	Loop suspendWindowList.Length {
		restoreList.Push(suspendWindowList.Get(A_Index))
	}

	for window in restoreList {
		windowText := "ahk_id" window.id
		if WinExist(windowText) {
			WinSetAlwaysOnTop(0, windowText)    ; 取消置顶
			WinSetTransparent("Off", windowText) ; 取消透明度
			; 使用 PostMessage 发送最大化指令（SC_MAXIMIZE = 0xF030）
			; 相比 WinMaximize，PostMessage 更有可能在后台完成操作而不强制夺取焦点
			PostMessage(0x0112, 0xF030, 0, , windowText) 
			; 立即将其推送到窗口堆栈的最底层
			WinMoveBottom(windowText)
		}
	}
	
	; 如果之前的活跃窗口还在，确保它保持焦点
	if originalActive && WinExist("ahk_id" originalActive) {
		WinActivate("ahk_id" originalActive)
	}
}
CoordMode "Mouse", "Screen"
log(message) {
  OutputDebug message  ; 输出到调试控制台
}
Reset(*){
	hiddenLength := hiddenWindowList.Length
	Loop hiddenLength {
		window := hiddenWindowList.Get(hiddenWindowList.Length)
		hiddenWindowList.RemoveAt(hiddenWindowList.Length)

		; 使用隐藏时存储的显示器索引，或回退到窗口当前位置检测
		monIndex := 0
		try monIndex := window.monitorIndex
		mon := GetMonitorInfoByIndex(monIndex || 1)

		WinMove(showMargin+mon.left, showMargin+mon.top, , , "ahk_id" window.id)
		WinSetAlwaysOnTop(0, "ahk_id" window.id)
		WinSetTransparent("Off", "ahk_id" window.id)
	}
	suspendLength := suspendWindowList.Length
	Loop suspendLength {
		suspendWindowList.RemoveAt(suspendWindowList.Length)
	}
}


SetTimer WatchCursor, 200

WatchCursor(){
	global showTmp
	; DPI.MouseGetPos 某些时候会出错
	Try{
		MouseGetPos &px, &py, &ahkId, &control
	    ; 判断是否为中间态，是则不需要移动
	    suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
		;log("suspendWindowIndex:=" . suspendWindowIndex)
		;log("showTmp:=" . showTmp)
	    if suspendWindowIndex > 0{
			showTmp := 0
	    	;拖动窗口去除隐藏
	    	window := suspendWindowList.Get(suspendWindowIndex)
	    	if (isWindowMove(window)=1){
	    		hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	    		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	    		suspendWindowList.RemoveAt(suspendWindowIndex)
	    		WinSetAlwaysOnTop(0,"ahk_id" ahkId)
	    	}
	    }
	    else{
	    	; 不为中间态时，则若为其他隐藏窗口则不隐藏，接着判断是否为隐藏的窗口
		    hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
		    
		    ; 如果通过ID没找到，尝试通过坐标寻找（处理窗口被遮挡或ID获取失败的情况）
		    if (hiddenWindowIndex == 0) {
		         Loop hiddenWindowList.Length {
		            tempWindow := hiddenWindowList.Get(A_Index)
		            tempId := tempWindow.id
		            windowText := "ahk_id " . tempId
		            if WinExist(windowText) {
		                 WinGetPos(&wx, &wy, &ww, &wh, windowText)
		                 ; 简单的矩形碰撞检测
		                 if (px >= wx && px <= wx + ww && py >= wy && py <= wy + wh) {
		                     hiddenWindowIndex := A_Index
		                     break
		                 }
		            }
		        }
		    }

		    ; 隐藏窗口则显示
		if hiddenWindowIndex>0 {
			window := hiddenWindowList.Get(hiddenWindowIndex)
			WinSetAlwaysOnTop(1, "ahk_id " . window.id) ; 确保置顶
			WinSetTransparent("Off", "ahk_id" window.id)
			showWindow(window)
		}
		    else{
		    	;按顺序隐藏
				;ToolTip suspendWindowList.Length . "|". showTmp
		    	if suspendWindowList.Length > 0 and showTmp <1{
		    		suspendWindow := suspendWindowList.Get(suspendWindowList.Length)
					windowText := "ahk_id" suspendWindow.id
					if WinExist(windowText) {
						WinGetPos(&X, &Y, &W, &H,windowText)
						if px>X and py>Y and px<X+W and py<Y+H{
							a:=1 
						}else{
							suspendWindowList.RemoveAt(suspendWindowList.Length)
							hideWindow(suspendWindow)
						}
					} else {
						suspendWindowList.RemoveAt(suspendWindowList.Length)
					}
	    		} 
		    }
	    }
	}
}



UpdateGlobals(){
	results := getSide()
	leftMonitor := results[1]
	rightMonitor := results[2]
	topMonitor := results[3]
	bottomMonitor := results[4]
	
	global leftEdge := results[5]
	global rightEdge := results[6]
	global topEdge := results[7]
	global bottomEdge := results[8]

	MonitorGet leftMonitor,,&leftTopEdge
	MonitorGet rightMonitor,,&rightTopEdge
	MonitorGet topMonitor,&topMonitorLeft
	MonitorGet bottomMonitor,&bottomMonitorLeft
	
	global leftTopEdge := leftTopEdge
	global rightTopEdge := rightTopEdge
	global topMonitorLeft := topMonitorLeft
	global bottomMonitorLeft := bottomMonitorLeft

	global leftDPI := getDPI(leftMonitor)
	global rightDPI := getDPI(rightMonitor)
	global topDPI := getDPI(topMonitor)
	global bottomDPI := getDPI(bottomMonitor)
}

HideActiveWindow(mode){
	ahkId := WinGetID("A")
	hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	if hiddenWindowIndex >0 {
		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	}
	if suspendWindowIndex > 0{
		suspendWindowList.RemoveAt(suspendWindowIndex)
	}
	hideWindow({id:ahkId,mode:mode})
}

#!Left::{
	HideActiveWindow("left")
}

#!Right::{
	HideActiveWindow("right")
}

#!Up::{
	HideActiveWindow("top")
}

#!Down::{
	HideActiveWindow("bottom")
}

^+F4::{
	Reset()
}


hideWindow(window){

	windowText := "ahk_id" window.id

	;最大化窗口不可隐藏
	if WinExist(windowText) and WinGetMinMax(windowText) != 1{
		DPI.WinGetPos(&X, &Y, &W, &H,windowText)
		; 乘以dpi 使用DPI缩放
		mode := window.mode

		; 获取当前窗口所在的显示器信息
		mon := GetMonitorInfo(window.id)
		window.monitorIndex := mon.index

		NewX := X
		NewY := Y
		if mode="left"{
			NewX := -Round(W*mon.dpi)+mon.left+Round(margin*mon.dpi)
			NewY :=Max(Y,mon.top)
		}
		else if mode="right"{
			NewX := mon.right-Round(margin*mon.dpi)
			NewY :=Max(Y,mon.top)
		}
		else if mode="top"{
			NewY := -Round(H*mon.dpi)+mon.top+Round(margin*mon.dpi)
			NewX := Max(X, mon.left)
		}
		else if mode="bottom"{
			NewY := mon.bottom-Round(margin*mon.dpi)
			NewX := Max(X, mon.left)
		}

		winSmoothMove(NewX, NewY, windowText)
		WinSetAlwaysOnTop(1, windowText)
		WinSetTransparent(150, windowText)
		pushTo(hiddenWindowList,window)
	}
}

showWindow(window){
	; 只显示最新的窗口，隐藏之前已滑出的中间态窗口
	while suspendWindowList.Length > 0 {
		oldWindow := suspendWindowList.RemoveAt(1)
		if oldWindow.id != window.id {
			hideWindow(oldWindow)
		}
	}

	windowText := "ahk_id" window.id
	mode := window.mode
	DPI.WinGetPos(&X, &Y, &W, &H,windowText)

	; 使用隐藏时存储的显示器索引
	monIndex := 0
	try monIndex := window.monitorIndex
	mon := GetMonitorInfoByIndex(monIndex || 1)

	NewX := X
	NewY := Y
	if mode="left"{
		NewX := showMargin+mon.left
	}
	else if mode="right"{
		NewX := mon.right-Round(showMargin*mon.dpi)-Round(W*mon.dpi)+5
	}
	else if mode="top"{
		NewY := mon.top+showMargin
	}
	else if mode="bottom"{
		NewY := mon.bottom-Round(showMargin*mon.dpi)-Round(H*mon.dpi)+5
	}
	; WinMove(NewX, Y,,,window)
	WinSetTransparent("Off", windowText)
	winSmoothMove(NewX,NewY,windowText)
	pushTo(suspendWindowList,window)
}
isWindowMove(window){
	windowText := "ahk_id" window.id
	mode := window.mode
	DPI.WinGetPos(&X, &Y, &W, &H,windowText)

	; 使用隐藏时存储的显示器索引
	monIndex := 0
	try monIndex := window.monitorIndex
	mon := GetMonitorInfoByIndex(monIndex || 1)

	; 当窗口横坐标大于margin一定程度，认为移动
	if mode = "left"{
		if (X>Round(showMargin*mon.dpi)+mon.left+moveDistance){
			return 1
		}
		else{
			return 0
		}
	}
	else if mode="right"{
		if (X<mon.right-moveDistance-Round(showMargin*mon.dpi) - Round(W*mon.dpi)){
			return 1
		}
		else{
			return 0
		}
	}
	else if mode="top"{
		if (Y>Round(showMargin*mon.dpi)+mon.top+moveDistance){
			return 1
		}
		else{
			return 0
		}
	}
	else if mode="bottom"{
		if (Y<mon.bottom-moveDistance-Round(showMargin*mon.dpi) - Round(H*mon.dpi)){
			return 1
		}
		else{
			return 0
		}
	}

}
; 列表不允许存在相同的窗口
pushTo(array,value){
	if array.Find((v) => (v.id =value.id)) <= 0{
		array.push(value)
	}
}
;从a到b的数组
createArray(a, b, length) {
	arr := []
	if (length <= 1) {
		arr.Push(b)
		return arr
	}
	step := (b - a) / (length - 1)
	Loop length {
		arr.Push(Round(a + step * (A_Index - 1)))
	}
	; 确保最后一个值精确等于 b
	arr[length] := b
	return arr
}
; 平滑移动
winSmoothMove(newX, newY, windowText) {
	WinGetPos(&X, &Y, ,, windowText)
	if (X == newX && Y == newY) {
		return
	}

	steps := 12
	arrX := createArray(X, newX, steps)
	arrY := createArray(Y, newY, steps)

	for i, vx in arrX {
		vy := arrY[i]
		WinMove(vx, vy, , , windowText)
		Sleep(10) ; 每次移动后暂停一小会儿，形成动画效果
	}
}

;多显示器支持
;获取左右边界和显示器索引
getSide(){
	leftEdge := 0
	rightEdge := 0
	topEdge := 0
	bottomEdge := 0
	
	leftMonitor :=0
	rightMonitor :=0
	topMonitor := 0
	bottomMonitor := 0

	i:=1
	while i<=MonitorGetCount(){
		MonitorGet i, &leftEdgeTemp, &topEdgeTemp, &rightEdgeTemp, &bottomEdgeTemp
		
		if (i==1) {
			leftEdge := leftEdgeTemp
			rightEdge := rightEdgeTemp
			topEdge := topEdgeTemp
			bottomEdge := bottomEdgeTemp
			leftMonitor := i
			rightMonitor := i
			topMonitor := i
			bottomMonitor := i
		} else {
			if leftEdge > leftEdgeTemp{
				leftEdge := leftEdgeTemp
				leftMonitor := i
			}
			if rightEdge < rightEdgeTemp{
				rightEdge := rightEdgeTemp
				rightMonitor := i
			}
			if topEdge > topEdgeTemp{
				topEdge := topEdgeTemp
				topMonitor := i
			}
			if bottomEdge < bottomEdgeTemp{
				bottomEdge := bottomEdgeTemp
				bottomMonitor := i
			}
		}
		i+=1
	}
	return [leftMonitor, rightMonitor, topMonitor, bottomMonitor, leftEdge, rightEdge, topEdge, bottomEdge]
}

getDPI(monitorIndex){
	monitorHandles := DPI.GetMonitorHandles()
	dpiValue := DPI.GetForMonitor(monitorHandles.Get(monitorIndex))
	dpiValue := dpiValue / 96
	return dpiValue
}

; 获取窗口所在显示器的信息（基于窗口中心点）
GetMonitorInfo(hWnd) {
	WinGetPos(&wx, &wy, &ww, &wh, "ahk_id" hWnd)
	centerX := wx + ww / 2
	centerY := wy + wh / 2

	monitorIndex := 0
	Loop MonitorGetCount() {
		MonitorGet(A_Index, &ml, &mt, &mr, &mb)
		if (centerX >= ml && centerX < mr && centerY >= mt && centerY < mb) {
			monitorIndex := A_Index
			break
		}
	}

	if (monitorIndex == 0)
		monitorIndex := 1

	MonitorGet(monitorIndex, &ml, &mt, &mr, &mb)
	dpi := getDPI(monitorIndex)

	return {index: monitorIndex, left: ml, top: mt, right: mr, bottom: mb, dpi: dpi}
}

; 根据显示器索引获取显示器信息
GetMonitorInfoByIndex(monitorIndex) {
	if !monitorIndex || monitorIndex < 1 || monitorIndex > MonitorGetCount()
		monitorIndex := 1

	MonitorGet(monitorIndex, &ml, &mt, &mr, &mb)
	dpi := getDPI(monitorIndex)

	return {index: monitorIndex, left: ml, top: mt, right: mr, bottom: mb, dpi: dpi}
}

#ErrorStdOut
!`::
{
    ;OutputDebug 'cmd+`` `n'
    changeActiveWindow("forward")
}

<+!`::
{
    ;OutputDebug 'cmd+shift+`` `n'
    changeActiveWindow("back")
}

changeActiveWindow(dir)
{
    static windowOrder := []
    static expectedOrder := []
    currentOrder := []
    CatchWindowsExplorerErrors := true ; Windows Explorer creates a number of invisible windows which breaks behavior when using the alt menu. Set this to false to let these errors through.
    debugging := false

    ; Get all windows the same as the active window
    OldClass := WinGetClass("A")
    ActiveProcessName := WinGetProcessName("A")
    WinClassCount := WinGetCount("ahk_exe " ActiveProcessName)
    ActiveId := WinGetID("A")
    OutputDebug 'Current Window:    ' ActiveId '/' OldClass '/' ActiveProcessName '/' WinGetTitle("ahk_id" ActiveId) '`n'
    
    ; If there's only one window, do nothing
    if (WinClassCount = 1)
        Return

    ; Get all windows of the same process
    ids := WinGetList("ahk_exe " ActiveProcessName)
    for SiblingID in ids {
        if (WinGetTitle(SiblingID) != ""){
            if (CatchWindowsExplorerErrors){
                if ( WinGetClass(SiblingID) != "KbxLabelClass" && WinGetTitle(SiblingID) != "Program Manager"){
                    currentOrder.Push(SiblingID)
                }
            } else {
                currentOrder.Push(SiblingID)
            }
        }
    }

    ; Check first run and populate
    if windowOrder.Length = 0 {
        resetWindows()
    }
    printDebugging()

    ; Check if current order and length match expected order and length
    ; If they don't, expected order has changed or a window has been removed or inserted
    if (currentOrder.Length = expectedOrder.Length) {
        Loop currentOrder.Length {
            if (currentOrder[A_Index] != expectedOrder[A_Index]){
                resetWindows()
                break
            }
        }
    } else {
        resetWindows()
    }

    windowOrder := moveToNextIndex(windowOrder, dir)
    changeActiveWindow()
    expectedOrder := updateExpectedOrder(expectedOrder, windowOrder)
    printDebugging()

    OutputDebug '`n'


    ; Functions
    ; Reset the windows to the current state - used if the order doesn't match the expected order e.g. a new window is introduced or the user has clicked and changed order
    resetWindows(){
        OutputDebug 'Restting memory`n'
        windowOrder := currentOrder.Clone()
        expectedOrder := currentOrder.Clone()
        return
    }

    ; Used to update the active window tracked by windowOrder
    changeActiveWindow(){
        WinActivate("ahk_id" windowOrder[1])
        try {
            OutputDebug 'Switching to:    ' WinGetTitle("ahk_id" windowOrder[1]) ' -- ' windowOrder[1] '`n'
        } catch Error as e {
            OutputDebug "An error was thrown!`nSpecifically: " e.Message
            Exit
        }
    }

    ; Print debugging information
    printDebugging(){
        if (debugging){
            OutputDebug '---------------------- currentOrder: ----------------------`n'
            for e in currentOrder {
                OutputDebug WinGetTitle("ahk_id" e) ' -- ' e '`n'
            }
            OutputDebug '---------------------- windowOrder: ----------------------`n'
            for e in windowOrder {
                OutputDebug WinGetTitle("ahk_id" e) ' -- ' e '`n'
            }
            OutputDebug '---------------------- expectedOrder: ----------------------`n'
            for e in expectedOrder {
                OutputDebug WinGetTitle("ahk_id" e) ' -- ' e '`n'
            }
        }
    }
}



getArrayValueIndex(arr, val){
    Loop arr.Length {
        if (arr[A_Index] == val)
			return A_Index
    }
}

moveToNextIndex(arr, dir){
    if (dir == "forward"){
        e := arr[1]
        arr.RemoveAt(1)
        arr.Push(e)
        return arr
    } else if (dir == "back"){
        e := arr[arr.Length]
        arr.RemoveAt(arr.Length)
        arr.InsertAt(1, e)
        return arr
    }
}

moveLastIndexToFirst(arr){
    e := arr[1]
    arr.RemoveAt(1)
    arr.Push(e)
    return arr
}

updateExpectedOrder(eo, wo){
    activeWindowIndex := getArrayValueIndex(eo, wo[1])
    activeWindow := eo[activeWindowIndex]
    eo.RemoveAt(activeWindowIndex)
    eo.InsertAt(1, activeWindow)
    return eo
}
