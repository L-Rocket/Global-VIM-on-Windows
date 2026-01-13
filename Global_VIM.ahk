#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
; 初始化与全局状态
; ==========================================================
SetCapsLockState "AlwaysOff"
global IsNavMode := false
global IsShiftSticky := false
global HasMoved := false 

UpdateStatus() {
    if (IsNavMode) {
        status := IsShiftSticky ? "🔥 选中模式 (VISUAL)" : "💡 移动模式 (NORMAL)"
        ToolTip(status)
    } else {
        ToolTip("✅ 编辑模式")
        SetTimer(() => ToolTip(), 800)
    }
}

; 【核心修复】退出导航模式
ExitNav(shouldCollapse := true) {
    global IsNavMode := false
    global IsShiftSticky := false
    
    Send("{Shift Up}") 
    Sleep(20)
    
    ; 修复点：只有在真正动过、且需要坍缩选区时才按键
    if (shouldCollapse && HasMoved) {
        ; 为了防止 h 选中整行后跳到下一行，我们采用“左移再右移”或者简单的“左移”
        ; 这里建议用 {Left}，它会停留在选中区域的开头，最稳且不跳行
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
        global HasMoved := false ; 进场重置
        UpdateStatus()
    } else {
        ; 修复点：如果进场后没动过，退出时不坍缩选区，防止光标平移
        ExitNav(HasMoved ? true : false) 
    }
}

; 组合键微调
CapsLock & i::Send("{Blind}{Up}")
CapsLock & k::Send("{Blind}{Down}")
CapsLock & j::Send("{Blind}{Left}")
CapsLock & l::Send("{Blind}{Right}")
CapsLock & u::Send("{Blind}{Home}")
CapsLock & o::Send("{Blind}{End}")

; ==========================================================
; 【全域快捷键】
; ==========================================================
^i::Send(IsNavMode && IsShiftSticky ? "+{Up 5}" : "{Up 5}")
^k::Send(IsNavMode && IsShiftSticky ? "+{Down 5}" : "{Down 5}")
^j::Send(IsNavMode && IsShiftSticky ? "^+{Left}" : "^{Left}")
^l::Send(IsNavMode && IsShiftSticky ? "^+{Right}" : "^{Right}")

+CapsLock::CapsLock

; ==========================================================
; 【导航模式专属逻辑】
; ==========================================================
#HotIf IsNavMode

; --- 选中整行 ---
h:: {
    global HasMoved := true 
    Send("{Shift Up}")
    Send("{Home 2}") 
    Sleep(20)
    Send("+{End}") 
}

; --- 核心 1：多态 d 键 ---
d:: {
    if (HasMoved) {
        Send("{Del}")
        ExitNav(false) ; 删除后不需要坍缩动作
        return
    }
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
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
    }
}

; --- 核心 2：多态 c 键 (Copy 系列) ---
c:: {
    if (HasMoved) {
        Send("^c")
        ExitNav(true) ; 复制完需要坍缩
        return
    }
    ih := InputHook("L1 T0.5", "{Esc}{CapsLock}")
    ih.Start(), ih.Wait()
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
    }
}

; --- 基础移动 ---
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

; --- 统一动作 ---
y::
^c:: { 
    Send("^c")       
    Sleep(100)       
    ExitNav(true)        
}

p::
^v:: { 
    Send("^v")
    ExitNav(false)
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

z::Send("^z")
r::Send("^y")
Esc::ExitNav(true)

#HotIf