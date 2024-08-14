/*
 * Copyright (c) 2024 CarrieForle
 * This file is part of KPS Display.
 *
 * KPS Display is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.
 *
 * KPS Display is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with KPS Display. If not, see <https://www.gnu.org/licenses/>.
 */

about_gui_name()
{
    return "About"
}

init_about_gui(main_gui, *)
{
    about_gui := Gui("+Owner" main_gui.Hwnd " +ToolWindow")
    
    about_gui.Title := about_gui_name()
    about_gui.SetFont("S9", default_font())
    about_link := about_gui.AddLink("Center vabout_link", "KPS (Key per second) display`nis made by CarrieForle © 2024")
    about_gui.OnEvent("Close", enable_main_and_destroy_self.Bind(main_gui))
    
    return about_gui
}