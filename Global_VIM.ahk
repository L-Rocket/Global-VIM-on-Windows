#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; 初始化与全局状态
; ==========================================================
SetCapsLockState "AlwaysOff"
global IsNavMode := false
global IsShiftSticky := false
global HasMoved := false 
global IsHookActive := false 

; 定义图标基础路径
global ICON_DIR := A_ScriptDir "\icon\assets\"

; 初始更新一次图标
UpdateStatus()

; --- 核心：更新状态提示与托盘图标 ---
UpdateStatus(msg := "") {
    if (IsNavMode) {
        if (IsShiftSticky) {
            TrySetModeIcon(ICON_DIR "selection.ico", "🔥 选中模式 (VISUAL)")
            status := msg ? msg : "🔥 选中模式 (VISUAL)"
        } else {
            TrySetModeIcon(ICON_DIR "arrows.ico", "💡 移动模式 (NORMAL)")
            status := msg ? msg : "💡 移动模式 (NORMAL)"
        }
        ToolTip(status)
    } else {
        TrySetModeIcon(ICON_DIR "pencil.ico", "模式: 编辑")
        ToolTip() 
    }
}

; 辅助函数：安全设置图标
TrySetModeIcon(iconPath, tipText) {
    if FileExist(iconPath) {
        TraySetIcon(iconPath)
    } else {
        TraySetIcon("*") 
    }
    A_IconTip := tipText
}

; 【核心清理】退出导航模式
ExitNav(shouldCollapse := true) {
    global IsNavMode := false
    global IsShiftSticky := false
    global IsHookActive := false
    
    Send("{Shift Up}{Ctrl Up}") 
    Sleep(20)
    
    if (shouldCollapse && HasMoved) {
        Send("{Left}") 
    }
    
    global HasMoved := false
    UpdateStatus() 
}

; ==========================================================
; 【模式切换】
; ==========================================================
CapsLock::
{
    global IsNavMode := !IsNavMode
    if (IsNavMode) {
        global IsShiftSticky := true  
        global HasMoved := false  
        UpdateStatus() 
    } else {
        ExitNav(HasMoved ? true : false) 
    }
}

; ==========================================================
; 【通用组合键】 (CapsLock + IJKL/UO)
; ==========================================================
CapsLock & i::Send("{Blind}{Up}")
CapsLock & k::Send("{Blind}{Down}")
CapsLock & j::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")
CapsLock & u::Send("{Blind}{Home}")
CapsLock & o::Send("{Blind}{End}")

^i::Send(IsNavMode && IsShiftSticky ? "+{Up 5}" : "{Up 5}")
^k::Send(IsNavMode && IsShiftSticky ? "+{Down 5}" : "{Down 5}")
^j::Send(IsNavMode && IsShiftSticky ? "^+{Left}" : "^{Left}")
^l::Send(IsNavMode && IsShiftSticky ? "^+{Right}" : "^{Right}")

+CapsLock::CapsLock

; ==========================================================
; 【导航模式专属逻辑】
; ==========================================================
#HotIf IsNavMode

; --- A. 独立功能键 ---
#HotIf IsNavMode and !IsHookActive

h:: {
    global HasMoved := true 
    Send("{Shift Up}{Home 2}") 
    Sleep(20)
    Send("+{End}") 
    UpdateStatus()
}

w:: {
    global HasMoved := true
    Send(IsShiftSticky ? "^+{Right}" : "^{Right}")
    UpdateStatus()
}

b:: {
    global HasMoved := true
    Send(IsShiftSticky ? "^+{Left}" : "^{Left}")
    UpdateStatus()
}

; --- B. 拦截所有未定义字母键 ---
a::
e::
f::
g::
m::
p:: 
q::
s::
t::
r:: 
{
    UpdateStatus("⚠️ 模式锁定中：请使用指令或 Caps 退出")
}

#HotIf IsNavMode

; --- C. 核心操作符 ---
d:: {
    ; 【修复关键点】必须先声明 global，否则 if (HasMoved) 会因为变量未定义而报错
    global HasMoved 
    if (HasMoved) {
        Send("{Del}")
        ExitNav(false)
        return
    }
    global IsHookActive := true 
    UpdateStatus("⏳ 等待指令 (h/w/b)...")
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    global IsHookActive := false 
    
    if (ih.Input == "h") {
        Send("{Shift Up}{Home 2}")
        Sleep(20)
        Send("+{End}{BackSpace}{Delete}")
        ExitNav(false) 
    } else if (ih.Input == "w") { 
        Send("^{Del}")
        ExitNav(false)
    } else if (ih.Input == "b") { 
        Send("^{BackSpace}")
        ExitNav(false)
    } else {
        UpdateStatus() 
    }
}

c:: {
    ; 【修复关键点】同上
    global HasMoved
    if (HasMoved) {
        Send("^c")
        ExitNav(true)
        return
    }
    global IsHookActive := true
    UpdateStatus("⏳ 等待指令 (h/w/b)...")
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
    global IsHookActive := false
    
    if (ih.Input == "h") {
        Send("{Shift Up}{Home 2}")
        Sleep(20)
        Send("+{End}^c")
        ExitNav(true) 
    } else if (ih.Input == "w") { 
        Send("{Shift Up}^+{Right}^c")
        ExitNav(true)
    } else if (ih.Input == "b") { 
        Send("{Shift Up}^+{Left}^c")
        ExitNav(true)
    } else {
        UpdateStatus()
    }
}

; --- D. 基础移动 ---
*i:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Up}")
}
*k:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Down}")
}
*j:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Left}")
}
*l:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Right}")
}
*u:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{Home}")
}
*o:: {
    global HasMoved := true
    Send("{Blind}" (IsShiftSticky ? "+" : "") "{End}")
}

; --- E. 动作逻辑 ---
y::
^c:: {
    Send("^c")
    Sleep(100)
    ExitNav(true)
}

x::
^x:: {
    Send("^x")
    ExitNav(false)
}

v:: {
    global IsShiftSticky := !IsShiftSticky
    global HasMoved := false 
    if (!IsShiftSticky) Send("{Shift Up}{Right}")
    UpdateStatus() 
}

n:: {
    Send("{End}{Enter}")
    ExitNav(false)
}

; 【修复关键点】给 z 键加上大括号，避免单行表达式的解析错误
z:: { 
    Send("^z")
    ExitNav(false)
}

Esc::ExitNav(true)

#HotIf