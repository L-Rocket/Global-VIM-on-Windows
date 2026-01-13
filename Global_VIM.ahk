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

; 核心提示逻辑：导航模式常驻，编辑模式消失
UpdateStatus(msg := "") {
    if (IsNavMode) {
        ; 如果有临时消息（如误触警告）则显示消息，否则显示当前模式状态
        status := msg ? msg : (IsShiftSticky ? "🔥 选中模式 (VISUAL)" : "💡 移动模式 (NORMAL)")
        ToolTip(status) ; 常驻显示，不设计时器
    } else {
        ToolTip() ; 立即清除 ToolTip，确保编辑模式无干扰
    }
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
    UpdateStatus() ; 清除提示
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
        UpdateStatus() ; 开启常驻提示
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

; --- A. 独立功能键 (非等待状态触发) ---
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

; --- B. 拦截所有未定义字母键并常驻警告 ---
a::
e::
f::
g::
m::
p:: 
q::
s::
t::
r:: ; r 原本是重做，现在也纳入拦截（或根据需要保留）
{
    UpdateStatus("⚠️ 模式锁定中：请使用指令或 Caps 退出")
}

#HotIf IsNavMode

; --- C. 核心操作符 ---
d:: {
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
        UpdateStatus() ; 如果超时或按错，恢复正常常驻提示
    }
}

c:: {
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

z:: (Send("^z"), ExitNav(false))

Esc::ExitNav(true)

#HotIf