* MONITOR.ADO - Sends a notification in case of error
* USAGE:
* a) monitor install
* b) monitor, [note(..) DEVICEs(..) SUCCESS] : cmd

program define monitor

	* Install
	if (`"`0'"'=="install") {
		di as text "To use monitor.ado you need to:"
		di as text " 1) install python and run <pip install pushbullet.py>"
		di as text " 2) in profile.do, add the globals pushbullet_api (api key), pushbullet_mobile (mobile nickname), pushbullet_desktop, etc."
		local path = c(sysdir_stata)
		if ("$S_OS"=="Windows") local path = subinstr("`path'", "/", "\", .)
		local fn "`path'profile.do"
		cap conf file "`fn'"
		if (_rc) {
			file open fh using "`fn'", write
			file write fh "* Pushbullet" _n
			file write fh `"global pushbullet_api "ENTER_API""' _n
			file write fh `"global pushbullet_mobile "ENTER_MOBILE_DEVICE_NICKNAME""' _n
			file close fh
		}
		doedit "`fn'"
		exit
	}

	* Verify API token is set
	if ("$pushbullet_api"=="") {
		di as error "[monitor] global pushbullet_api is empty, save it!"
		exit 654
	}

	* Parse
	_on_colon_parse `0'
    local cmd `s(after)'
    local 0 `s(before)'
    syntax [, NOTEs(string) DEVICEs(string) SUCCESS DONE VERBOSE]

    if ("`devices'"=="") local devices "mobile"
    if ("`done'"!="") local success success
    foreach device of local devices {
    	if ("$pushbullet_`device'"=="") {
    		di as error "[monitor] device nickname unknown (global pushbullet_`device' is empty)"
    		exit 654
    	}
    }

    * Execute command
	cap noi `cmd'
	local rc = _rc

	* Deal with 3 cases
	if (`rc'==1) {
		* User pressed break key, don't report that
		exit `rc'
	}
	else if (`rc'>1) {
		local msg "(rc=`rc') (cmd=`cmd') `note'"
		local title "Stata Error"
	}
	else if (`rc'==0) {
		local msg "(cmd=`cmd') `note'"
		local title "Stata Done"
	}

	* Notify if appropriate for each device
	if (`rc' | ("`success'"!="")) {
	    qui findfile "pushbullet.py.ado"
	    local fn "`r(fn)'"
	    foreach device of local devices {
	    	local python `"python "`r(fn)'" $pushbullet_api "${pushbullet_`device'}" "`title'" "`msg'" "'
	    	if ("`verbose'"!="") di as input `"<`python'>"'
	    	!`python'
	    }
	}

	* Stop if appropriate
	if (`rc') {
		exit `rc'
	}

end
