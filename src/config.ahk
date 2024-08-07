better_ini_read(filename, section, key, default?)
{
    try
    {
        return IniRead(filename, section, key)
    }
    catch Error as e ; OSError somehow is not thrown but other unidentified Error
    {
        ; https://learn.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-getprivateprofilestring#return-value
        if A_LastError = 2
        {
            throw ValueError("The option `"" key "`" in [" section "] is not found", -1)
        }
        else
        {
            throw e
        }
    }
}

read_config(filename)
{
    result := {}
    result.general := {}
    result.general.update_interval := better_ini_read(filename, "general", "update_interval")
    result.general.monitored_keys := better_ini_read(filename, "general", "monitored_keys")

    if result.general.monitored_keys = ""
    {
        result.general.monitored_keys := "{All}"
    }

    result.KPS := {}
    result.KPS.bg_color := better_ini_read(filename, "KPS", "bg_color")
    result.KPS.fg_color := better_ini_read(filename, "KPS", "fg_color")
    result.KPS.style := better_ini_read(filename, "KPS", "style")
    result.KPS.align := better_ini_read(filename, "KPS", "align")
    
    result.custom_kps := Map()

    captured_kps := better_ini_read(filename, "custom_kps", "captured_kps")
    kps_key := []

    loop parse captured_kps, " "
    {
        kps := Integer(A_LoopField)

        if kps < 0
        {
            throw ValueError("KPS cannot be negative. Found " kps, -1, kps)
        }

        kps_key.Push(kps)
    }

    for kps in kps_key
    {
        result.custom_kps[kps] = better_ini_read(filename, "custom_kps", String(kps))
    }

    return result
}