//checks if a file exists and contains text
//returns text as a string if these conditions are met
/proc/return_file_text(filename)
	if(!fexists(filename))
		error("File not found ([filename])")
		return

	var/text = file2text(filename)
	if(!text)
		error("File empty ([filename])")
		return

	return text

//Sends resource files to client cache
/client/proc/getFiles()
	for(var/file in args)
		send_rsc(src, file, null)

/client/proc/browse_files(root="data/logs/", max_iterations=10, list/valid_extensions=list(".txt",".log",".htm"))
	var/path = root

	for(var/i=0, i<max_iterations, i++)
		var/list/choices = sortList(flist(path))
		if(path != root)
			choices.Insert(1,"/")

		var/choice = input(src,"Choose a file to access:","Download",null) as null|anything in choices
		switch(choice)
			if(null)
				return
			if("/")
				path = root
				continue
		path += choice

		if(copytext(path,-1,0) != "/")		//didn't choose a directory, no need to iterate again
			break

	var/extension = copytext(path,-4,0)
	if( !fexists(path) || !(extension in valid_extensions) )
		to_chat(src, "<font color='red'>Error: browse_files(): File not found/Invalid file([path]).</font>")
		return

	return path

#define FTPDELAY 200	//200 tick delay to discourage spam
/*	This proc is a failsafe to prevent spamming of file requests.
	It is just a timer that only permits a download every [FTPDELAY] ticks.
	This can be changed by modifying FTPDELAY's value above.

	PLEASE USE RESPONSIBLY, Some log files can reach sizes of 4MB!	*/
// Return value determines if spam check failed, TRUE means the request was too fast and should be rejected.
/client/proc/file_spam_check()
	var/time_to_wait = fileaccess_timer - world.time
	if(time_to_wait > 0)
		to_chat(src, "<font color='red'>Error: file_spam_check(): Spam. Please wait [round(time_to_wait/10)] seconds.</font>")
		return TRUE
	fileaccess_timer = world.time + FTPDELAY
	return FALSE
#undef FTPDELAY

/*   Returns a list of all files (as file objects) in the directory path provided, as well as all files in any subdirectories, recursively!
    The list returned is flat, so all items can be accessed with a simple loop.
    This is designed to work with browse_rsc(), which doesn't currently support subdirectories in the browser cache.*/
/proc/getallfiles(path, remove_folders = TRUE, recursion = TRUE)
	set background = TRUE
	. = list()
	for(var/f in flist(path))
		if(copytext("[f]", -1) == "/")
			if(recursion)
				. += .("[path][f]")
		else
			. += file("[path][f]")

	if(remove_folders)
		for(var/file in .)
			if(copytext("[file]", -1) == "/")
				. -= file
