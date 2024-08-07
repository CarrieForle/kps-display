; https://learn.microsoft.com/en-us/windows/win32/menurc/using-resources
; Code by https://www.autohotkey.com/board/topic/57631-crazy-scripting-resource-only-dll-for-dummies-36l-v07/page-4#entry609282
; Modified by CarrieForle
res_read(key, res_type) { 
    if !A_IsCompiled {
        return FileRead(key, "RAW")
    }

    hMod := DllCall("GetModuleHandle", "UInt", 0)
    hRes := DllCall("FindResource", "UInt", hMod, "Str", key, "UInt", 
        DllCall("MAKEINTRESOURCE", "UInt", res_type
    ))
    hData := DllCall("LoadResource", "UInt", hMod, "UInt", hRes)
    pData := DllCall("LockResource", "UInt", "hData")
    
    return Buffer(DllCall("SizeofResource", "UInt", hMod, "UInt", hRes), pData)
}
