#Requires AutoHotkey v2.0
#include Array.ahk
#include DPI.ahk
; 实现窗口平滑移动，越小越平滑，最小为-1
SetWinDelay(5)

; 隐藏时留出的长度以及显示时距离屏幕边缘的长度
; 由于DPI关系，margin设置，不同DPI可能不同
margin := 10
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

; 设置托盘图标
TraySetIcon("./assest/自动贴边.png")
; 加入右键菜单
myMenu := A_TrayMenu
myMenu.Delete()
myMenu.Add("重置所有贴边窗口", Reset)
myMenu.SetIcon("重置所有贴边窗口", "imageres.dll", 230)
myMenu.Add("退出", (*) => ExitApp())
myMenu.SetIcon("退出", "imageres.dll", 231)


; 重置所有贴边窗口的函数
Reset(*){
	; 获取多显示器的边界信息
	results := getSide()
	; 获取左侧显示器索引
	leftMonitor := results[1]
	; 获取右侧显示器索引
	rightMonitor := results[2]
	; 获取左边界坐标
	leftEdge := results[3]
	; 获取右边界坐标
	rightEdge := results[4]
	; 获取左侧显示器顶部边界
	MonitorGet leftMonitor,,&leftTopEdge
	; 获取右侧显示器顶部边界
	MonitorGet rightMonitor,,&rightTopEdge
	; 获取左侧显示器DPI缩放
	leftDPI := getDPI(leftMonitor)
	; 获取右侧显示器DPI缩放
	rightDPI := getDPI(rightMonitor)
	; 多显示器支持
	global leftEdge
	global rightEdge
	global leftTopEdge
	global rightTopEdge
	global leftDPI
	global rightDPI

	; 获取隐藏窗口列表长度
	hiddenLength := hiddenWindowList.Length
	; 循环处理所有隐藏的窗口
	Loop hiddenLength {
		; 获取最后一个隐藏窗口
		window := hiddenWindowList.Get(hiddenWindowList.Length)
		; 从隐藏列表中移除
		hiddenWindowList.RemoveAt(hiddenWindowList.Length)
		; 移动窗口到显示位置
		WinMove(showMargin+leftEdge,showMargin+leftTopEdge,,,"ahk_id" window.id)
		; 取消窗口置顶
		WinSetAlwaysOnTop(0,"ahk_id" window.id)
	}
	; 获取悬停窗口列表长度
	suspendLength := suspendWindowList.Length
	; 清空悬停窗口列表
	Loop suspendLength {
		suspendWindowList.RemoveAt(suspendWindowList.Length)
	}

}



; 每200毫秒执行一次WatchCursor函数，用于监控鼠标位置和窗口状态
SetTimer WatchCursor, 200

; 监视鼠标光标位置的函数
; 主要功能:
; 1. 检测鼠标是否悬停在窗口上
; 2. 处理窗口的显示和隐藏状态
; 3. 处理窗口的拖动操作
WatchCursor(){
	; DPI.MouseGetPos 某些时候会出错
	Try{
		DPI.MouseGetPos , , &ahkId, &control
	    ; 判断是否为中间态，是则不需要移动
	    suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	    if suspendWindowIndex > 0{
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
		    ; 隐藏窗口则显示
		    if hiddenWindowIndex>0 {
		    	window := hiddenWindowList.Get(hiddenWindowIndex)
		    	showWindow(window)
		    }
		    else{
		    	;按顺序隐藏
		    	if suspendWindowList.Length > 0{
		    		suspendWindow := suspendWindowList.Get(suspendWindowList.Length)
			    	suspendWindowList.RemoveAt(suspendWindowList.Length)
			    	hideWindow(suspendWindow)
	    		} 
		    }
	    }
	}
}



; 将当前活动窗口隐藏到屏幕左侧，贴边隐藏
#!Left::{
	results := getSide()
	leftMonitor := results[1]
	rightMonitor := results[2]
	leftEdge := results[3]
	rightEdge := results[4]
	MonitorGet leftMonitor,,&leftTopEdge
	MonitorGet rightMonitor,,&rightTopEdge
	leftDPI := getDPI(leftMonitor)
	rightDPI := getDPI(rightMonitor)
	; 多显示器支持
	global leftEdge
	global rightEdge
	global leftTopEdge
	global rightTopEdge
	global leftDPI
	global rightDPI

	ahkId := WinGetID("A")
	hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	if hiddenWindowIndex >0 {
		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	}
	if suspendWindowIndex > 0{
		suspendWindowList.RemoveAt(suspendWindowIndex)
	}
	hideWindow({id:ahkId,mode:"left"})
}

; 将当前活动窗口隐藏到屏幕右侧，贴边隐藏
#!Right::{
	results := getSide()
	leftMonitor := results[1]
	rightMonitor := results[2]
	leftEdge := results[3]
	rightEdge := results[4]
	MonitorGet leftMonitor,,&leftTopEdge
	MonitorGet rightMonitor,,&rightTopEdge
	leftDPI := getDPI(leftMonitor)
	rightDPI := getDPI(rightMonitor)
	; 多显示器支持
	global leftEdge
	global rightEdge
	global leftTopEdge
	global rightTopEdge
	global leftDPI
	global rightDPI

	ahkId := WinGetID("A")
	;判断当前窗口是否已经隐藏，若已存在则删除
	hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
	suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
	if hiddenWindowIndex >0 {
		hiddenWindowList.RemoveAt(hiddenWindowIndex)
	}
	if suspendWindowIndex > 0{
		suspendWindowList.RemoveAt(suspendWindowIndex)
	}
	hideWindow({id:ahkId,mode:"right"})
	
}

; 将当前活动窗口隐藏到屏幕顶部，贴边隐藏
#!Up::{
    results := getSide()
    leftMonitor := results[1]
    rightMonitor := results[2]
    leftEdge := results[3]
    rightEdge := results[4]
    MonitorGet leftMonitor,,&leftTopEdge
    MonitorGet rightMonitor,,&rightTopEdge
    leftDPI := getDPI(leftMonitor)
    rightDPI := getDPI(rightMonitor)
    ; 多显示器支持
    global leftEdge
    global rightEdge
    global leftTopEdge
    global rightTopEdge
    global leftDPI
    global rightDPI

    ahkId := WinGetID("A")
    hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
    suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
    if hiddenWindowIndex >0 {
        hiddenWindowList.RemoveAt(hiddenWindowIndex)
    }
    if suspendWindowIndex > 0{
        suspendWindowList.RemoveAt(suspendWindowIndex)
    }
    hideWindow({id:ahkId,mode:"top"})
}

; 将当前活动窗口隐藏到屏幕底部，贴边隐藏
#!Down::{
    results := getSide()
    leftMonitor := results[1]
    rightMonitor := results[2]
    leftEdge := results[3]
    rightEdge := results[4]
    MonitorGet leftMonitor,,&leftTopEdge
    MonitorGet rightMonitor,,&rightTopEdge
    leftDPI := getDPI(leftMonitor)
    rightDPI := getDPI(rightMonitor)
    ; 多显示器支持
    global leftEdge
    global rightEdge
    global leftTopEdge
    global rightTopEdge
    global leftDPI
    global rightDPI

    ahkId := WinGetID("A")
    hiddenWindowIndex := hiddenWindowList.Find((v) => (v.id =ahkId))
    suspendWindowIndex := suspendWindowList.Find((v) => (v.id =ahkId))
    if hiddenWindowIndex >0 {
        hiddenWindowList.RemoveAt(hiddenWindowIndex)
    }
    if suspendWindowIndex > 0{
        suspendWindowList.RemoveAt(suspendWindowIndex)
    }
    hideWindow({id:ahkId,mode:"bottom"})
}

^F4::{
	Reset()
}

hideWindow(window){
    windowText := "ahk_id" window.id

    ; 最大化窗口不可隐藏
    if WinExist(windowText) and WinGetMinMax(windowText) != 1{
        DPI.WinGetPos(&X, &Y, &W, &H, windowText)
        ; 乘以dpi 使用DPI缩放
        mode := window.mode
        ; 如果是左侧隐藏模式
        if mode = "left"{
            ; 计算新的X坐标:
            ; 1. 将窗口宽度乘以DPI比例得到实际像素宽度
            ; 2. 减去这个宽度使窗口向左移动到屏幕外
            ; 3. 加上左边界位置
            ; 4. 保留一小部分margin在屏幕内
            NewX := -Round(W * leftDPI) + leftEdge + Round(margin * leftDPI)
            ; 确保窗口Y坐标不小于屏幕顶部边界
            Y := Max(Y, leftTopEdge)
            NewY := Y ; 确保 NewY 被定义
        }
        ; 如果是右侧隐藏模式
        else if mode = "right"{
            ; 计算新的X坐标:
            ; 1. 将窗口移动到右边界
            ; 2. 减去一小部分margin保留在屏幕内
            ; 3. 使用rightDPI进行DPI缩放
            NewX := rightEdge - Round(margin * rightDPI)
            ; 确保窗口Y坐标不小于屏幕顶部边界
            Y := Max(Y, rightTopEdge)
            NewY := Y ; 确保 NewY 被定义
        }
        ; 如果是顶部隐藏模式
        else if mode = "top"{
            ; 计算新的Y坐标:
            ; 1. 将窗口高度乘以DPI比例得到实际像素高度
            ; 2. 减去这个高度使窗口向上移动到屏幕外
            ; 3. 加上顶部边界位置
            ; 4. 保留一小部分margin在屏幕内
            NewY := Round(H * leftDPI) + leftTopEdge + Round(margin * leftDPI)
            ; 确保窗口X坐标不小于屏幕左边界
            X := Max(X, leftEdge)
            NewX := X ; 确保 NewX 被定义
        }
        ; 如果是底部隐藏模式
        else if mode = "bottom"{
            ; 计算新的Y坐标:
            ; 1. 将窗口移动到底部边界
            ; 2. 减去一小部分margin保留在屏幕内
            ; 3. 使用rightDPI进行DPI缩放
            ; leftTopEdge 是屏幕顶部边缘的Y坐标
            MonitorGet ,,,, &rightBottomEdge
            NewY := rightBottomEdge - Round(margin * rightDPI)
            ; 确保窗口X坐标不小于屏幕左边界
            X := Max(X, leftEdge)
            NewX := X ; 确保 NewX 被定义
        }
        
        ; 仅在窗口高度超过 maxHeight 时调整高度
        if H > maxHeight {
            H := maxHeight
        }
        winSmoothMove(NewX, NewY, windowText)
        WinSetAlwaysOnTop(1, windowText)
        pushTo(hiddenWindowList, window)
    }
}


; 显示窗口函数
; 参数:
;   window - 包含窗口信息的对象，必须包含 id 和 mode 属性
;   id: 窗口句柄
;   mode: 窗口显示模式，可以是 "left"、"right"、"top" 或 "bottom"
showWindow(window){
    windowText := "ahk_id" window.id
    mode := window.mode
    DPI.WinGetPos(&X, &Y, &W, &H, windowText)
    if mode = "left"{
        NewX := showMargin + leftEdge
        NewY := Y ; 确保 NewY 被定义
    }
    else if mode = "right"{
        NewX := rightEdge - Round(showMargin * rightDPI) - Round(W * rightDPI) + 5
        NewY := Y ; 确保 NewY 被定义
    }
    else if mode = "top"{
        NewY := showMargin + leftTopEdge
        NewX := X ; 确保 NewX 被定义
	}
    else if mode = "bottom"{
        ; 获取显示器底部边界
        MonitorGet ,,,, &bottomEdge
        ; 计算新的Y坐标，使窗口贴近底部边界，并考虑DPI缩放和边距
        NewY := bottomEdge - Round(showMargin * rightDPI) - Round(H * rightDPI) + 5
        NewX := X ; 确保 NewX 被定义
    }
    winSmoothMove(NewX, NewY, windowText)
    pushTo(suspendWindowList, window)
}

winSmoothMove(newX, newY, windowText){
    DPI.WinGetPos(&X, &Y, &W, &H, windowText)
    arrX := createArray(X, newX, 10)
    arrY := createArray(Y, newY, 10)
    for i, v in arrX{
        WinMove(v, arrY[i], , , windowText)
    }
}

isWindowMove(window){
    windowText := "ahk_id" window.id
    mode := window.mode
    DPI.WinGetPos(&X, &Y, &W, &H, windowText)
    ; 当窗口横坐标大于margin一定程度，认为移动
    if mode = "left"{
        if (X > Round(showMargin * leftDPI) + leftEdge + moveDistance){
            return 1
        }
        else{
            return 0
        }
    }
    else if mode = "right"{
        if (X < rightEdge - moveDistance - Round(showMargin * rightDPI) - Round(W * rightDPI)){
            return 1
        }
        else{
            return 0
        }
    }
    else if mode = "top"{
        if (Y > Round(showMargin * leftDPI) + leftTopEdge + moveDistance){
            return 1
        }
        else{
            return 0
        }
    }
    else if mode = "bottom"{
        if (Y < rightTopEdge - moveDistance - Round(showMargin * rightDPI) - Round(H * rightDPI)){
            return 1
        }
        else{
            return 0
        }
    }
}

; 列表不允许存在相同的窗口
pushTo(array, value){
    if array.Find((v) => (v.id = value.id)) <= 0{
        array.push(value)
    }
}

; 从a到b的数组
createArray(a, b, length) {
    ; Calculate the step to divide the range into length parts
    arr := []
    step := (b - a) / (length - 1)
    value := a
    Loop length {
        arr.Push(Round(value))
        value += step  ; Increase each value by step
    }
    arr.Push(b)
    return arr
}

; 多显示器支持
; 获取左右边界和显示器索引
getSide(){
    leftEdge := 1
    rightEdge := -1
    leftMonitor := 0
    rightMonitor := 0
    i := 1
    while i <= MonitorGetCount(){
        MonitorGet i, &leftEdgeTemp,, &rightEdgeTemp
        if leftEdge > leftEdgeTemp{
            leftEdge := leftEdgeTemp
            leftMonitor := i
        }
        if rightEdge < rightEdgeTemp{
            rightEdge := rightEdgeTemp
            rightMonitor := i
        }
        i += 1
    }
    return [leftMonitor, rightMonitor, leftEdge, rightEdge]
}

getDPI(monitorIndex){
    monitorHandles := DPI.GetMonitorHandles()
    dpiValue := DPI.GetForMonitor(monitorHandles.Get(monitorIndex))
    dpiValue := dpiValue / 96
    return dpiValue
}