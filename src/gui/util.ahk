default_font()
{
    return "Segoe UI"
}

enable_gui(my_gui, guiObj)
{
    my_gui.Opt("-Disabled")
}

try_do(f, &output?)
{
    try
    {
        output := f()
    }
    catch Error as e
    {
        output := e

        return false
    }

    return true
}