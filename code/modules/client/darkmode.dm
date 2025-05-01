/*
This lets you switch chat themes by using winset and CSS loading, you must relog to see this change (or rebuild your browseroutput datum)

Things to note:
If you change ANYTHING in interface/skin.dmf you need to change it here:
Format:
winset(src, "window as appears in skin.dmf after elem", "var to change = currentvalue;var to change = desired value")

How this works:
I've added a function to browseroutput.js which registers a cookie for darkmode and swaps the chat accordingly. You can find the button to do this under the "cog" icon next to the ping button (top right of chat)
This then swaps the window theme automatically

Thanks to spacemaniac and mcdonald for help with the JS side of this.

*/

/client/proc/force_white_theme() //There's no way round it. We're essentially changing the skin by hand. It's painful but it works, and is the way Lummox suggested.
	set background = TRUE
	winset(src, null ,{"
	infowindow.background-color = none;
	infowindow.text-color = #000000;
	info.background-color = none;
	info.text-color = #000000;
	tgui_chat.background-color = none;
	tgui_chat.text-color = #000000;
	byond_chat.background-color = none;
	byond_chat.text-color = #000000;
	mainwindow.background-color = none;
	mainvsplit.background-color = none;

	output.background-color = none;
	output.text-color = #000000;
	byond_chat.background-color = none;
	byond_chat.text-color = #000000;
	statwindow.background-color = none;
	statwindow.text-color = #000000;
	stat.background-color = #FFFFFF;
	stat.tab-background-color = none;
	stat.text-color = #000000;
	stat.tab-text-color = #000000;
	stat.prefix-color = #000000;
	stat.suffix-color = #000000;

	hotkey_toggle.background-color = none;
	hotkey_toggle.text-color = #000000;
	saybutton.background-color = none;
	saybutton.text-color = #000000;
	asset_cache_browser.background-color = none;
	asset_cache_browser.background-color = none;
	input.background-color = none;
	input.text-color = #000000;

	hotkey_toggle_alt.background-color = none;
	hotkey_toggle_alt.text-color = #000000;
	saybutton_alt.background-color = none;
	saybutton_alt.text-color = #000000;
	input_alt.background-color = none;
	input_alt.text-color = #000000;
	"})

/client/proc/force_dark_theme() //Inversely, if theyre using the superior white theme and want to swap to dark theme, let's get WINSET() ing
	set background = TRUE
	winset(src, null, {"
	infowindow.background-color = [COLOR_DARKMODE_BACKGROUND];
	infowindow.text-color = [COLOR_DARKMODE_TEXT];
	info.background-color = [COLOR_DARKMODE_BACKGROUND];
	info.text-color = [COLOR_DARKMODE_TEXT];
	tgui_chat.background-color = [COLOR_DARKMODE_BACKGROUND];
	tgui_chat.text-color = [COLOR_DARKMODE_TEXT];
	byond_chat.background-color = [COLOR_DARKMODE_BACKGROUND];
	byond_chat.text-color = [COLOR_DARKMODE_TEXT];
	mainwindow.background-color = [COLOR_DARKMODE_BACKGROUND];
	mainvsplit.background-color = [COLOR_DARKMODE_BACKGROUND];

	output.background-color = [COLOR_DARKMODE_DARKBACKGROUND];
	output.text-color = [COLOR_DARKMODE_TEXT];
	byond_chat.background-color = [COLOR_DARKMODE_DARKBACKGROUND];
	byond_chat.text-color = [COLOR_DARKMODE_TEXT];
	statwindow.background-color = [COLOR_DARKMODE_DARKBACKGROUND];
	statwindow.text-color = [COLOR_DARKMODE_TEXT];
	stat.background-color = [COLOR_DARKMODE_DARKBACKGROUND];
	stat.tab-background-color = [COLOR_DARKMODE_BACKGROUND];
	stat.text-color = [COLOR_DARKMODE_TEXT];
	stat.tab-text-color = [COLOR_DARKMODE_TEXT];
	stat.prefix-color = [COLOR_DARKMODE_TEXT];
	stat.suffix-color = [COLOR_DARKMODE_TEXT];

	saybutton.background-color = #494949;
	saybutton.text-color = [COLOR_DARKMODE_TEXT];
	asset_cache_browser.background-color = [COLOR_DARKMODE_BACKGROUND];
	asset_cache_browser.text-color = [COLOR_DARKMODE_TEXT];
	hotkey_toggle.background-color = #494949;
	hotkey_toggle.text-color = [COLOR_DARKMODE_TEXT];
	input.background-color = [COLOR_DARKMODE_BACKGROUND];
	input.text-color = [COLOR_DARKMODE_TEXT];

	saybutton_alt.background-color = #494949;
	saybutton_alt.text-color = [COLOR_DARKMODE_TEXT];
	hotkey_toggle_alt.background-color = #494949;
	hotkey_toggle_alt.text-color = [COLOR_DARKMODE_TEXT];
	input_alt.background-color = [COLOR_DARKMODE_BACKGROUND];
	input_alt.text-color = [COLOR_DARKMODE_TEXT];
	"})

/client/proc/force_marines_mode()
	set background = TRUE
	winset(src, null, {"
	infowindow.background-color = [COLOR_MARINEMODE_BACKGROUND];
	infowindow.text-color = [COLOR_MARINEMODE_TEXT];
	info.background-color = [COLOR_MARINEMODE_BACKGROUND];
	info.text-color = [COLOR_MARINEMODE_TEXT];
	tgui_chat.background-color = [COLOR_MARINEMODE_BACKGROUND];
	tgui_chat.text-color = [COLOR_MARINEMODE_TEXT];
	byond_chat.background-color = [COLOR_MARINEMODE_BACKGROUND];
	byond_chat.text-color = [COLOR_MARINEMODE_TEXT];
	mainwindow.background-color = [COLOR_MARINEMODE_BACKGROUND];
	mainvsplit.background-color = [COLOR_MARINEMODE_BACKGROUND];

	output.background-color = [COLOR_MARINEMODE_BACKGROUND];
	output.text-color = [COLOR_MARINEMODE_TEXT];
	byond_chat.background-color = [COLOR_MARINEMODE_BACKGROUND];
	byond_chat.text-color = [COLOR_MARINEMODE_TEXT];
	statwindow.background-color = [COLOR_MARINEMODE_BACKGROUND];
	statwindow.text-color = [COLOR_MARINEMODE_TEXT];
	stat.background-color = [COLOR_MARINEMODE_BACKGROUND];
	stat.tab-background-color = [COLOR_MARINEMODE_BACKGROUND];
	stat.text-color = [COLOR_MARINEMODE_TEXT];
	stat.tab-text-color = [COLOR_MARINEMODE_TEXT];
	stat.prefix-color = [COLOR_MARINEMODE_TEXT];
	stat.suffix-color = [COLOR_MARINEMODE_TEXT];

	saybutton.background-color = [COLOR_MARINEMODE_GRAYBUTTON];
	saybutton.text-color = [COLOR_MARINEMODE_TEXT];
	asset_cache_browser.background-color = [COLOR_MARINEMODE_GRAYBUTTON];
	asset_cache_browser.text-color = [COLOR_MARINEMODE_TEXT];
	hotkey_toggle.background-color = [COLOR_MARINEMODE_GRAYBUTTON];
	hotkey_toggle.text-color = [COLOR_MARINEMODE_TEXT];
	input.background-color = [COLOR_MARINEMODE_BACKGROUND];
	input.text-color = [COLOR_MARINEMODE_TEXT];

	saybutton_alt.background-color = [COLOR_MARINEMODE_GRAYBUTTON];
	saybutton_alt.text-color = [COLOR_MARINEMODE_TEXT];
	hotkey_toggle_alt.background-color = [COLOR_MARINEMODE_GRAYBUTTON];
	hotkey_toggle_alt.text-color = [COLOR_MARINEMODE_TEXT];
	input_alt.background-color = [COLOR_MARINEMODE_BACKGROUND];
	input_alt.text-color = [COLOR_MARINEMODE_TEXT];
	"})
