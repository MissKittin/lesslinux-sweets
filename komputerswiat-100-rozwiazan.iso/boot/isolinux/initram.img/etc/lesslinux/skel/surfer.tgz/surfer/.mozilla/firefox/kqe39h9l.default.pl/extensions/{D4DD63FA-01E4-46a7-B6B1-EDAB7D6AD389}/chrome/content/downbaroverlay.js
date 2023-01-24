/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Download Statusbar.
 *
 * The Initial Developer of the Original Code is
 * Devon Jensen.
 *
 * Portions created by the Initial Developer are Copyright (C) 2003
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s): Devon Jensen <velcrospud@hotmail.com>
 *
 * download_manager.png from Crystal_SVG by everaldo - kde-look.org
 *
 * Uninstall observer code adapted from Ook? Video Ook! extension by tnarik
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */


var db_gDownloadManager;
//var db_queueNum;
var db_pref = Components.classes["@mozilla.org/preferences-service;1"].getService(Components.interfaces.nsIPrefBranch);
var db_miniMode = false;
var db_useGradients = true;
var db_speedColorsEnabled = false;
var db_speedDivision1, db_speedDivision2, db_speedDivision3;
var db_speedColor0, db_speedColor1, db_speedColor2, db_speedColor3;
window.addEventListener("load", downbarInit, true);
window.addEventListener('unload', downbarClose, false);
window.addEventListener("focus", db_newWindowFocus, true);
window.addEventListener("blur", db_hideOnBlur, true);
var db_strings;
var db_currTooltipAnchor;
//var db_downbarComp = Components.classes['@devonjensen.com/downbar/downbar;1'].getService().wrappedJSObject;

function downbarInit() {

	var downbarelem = document.getElementById("downbar");

	const db_dlmgrContractID = "@mozilla.org/download-manager;1";
	const db_dlmgrIID = Components.interfaces.nsIDownloadManager;
	db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);
	
	db_strings = document.getElementById("downbarbundle");
	
	// Keeping this first run stuff here instead of downbar component because I need a browser window anyway to show the about page
	try {
		var firstRun = db_pref.getBoolPref("downbar.function.firstRun");
		var oldVersion = db_pref.getCharPref("downbar.function.version"); // needs to be last because it's likely not there (throws error)
	} catch (e) {}

	if (firstRun) {
		db_pref.setBoolPref("browser.download.manager.showWhenStarting", false);
		db_pref.setBoolPref("browser.download.manager.showAlertOnComplete", false);
		db_pref.setBoolPref("downbar.function.firstRun", false);

		// Give first runner time before the donate text shows up in the add-ons manager
		var now = ( new Date() ).getTime();
		db_pref.setCharPref("downbar.function.donateTextInterval", now);
		
		try {
			db_showSampleDownload();
		} catch(e){}
		
		try {
			// Set "keep download history" pref
			// browser.download.manager.retention must be 2, set their downbar history pref, based on their previous setting
			var retenPref = db_pref.getIntPref('browser.download.manager.retention');
			if(retenPref == 2)  // "Remember what I've downloaded"
				db_pref.setBoolPref('downbar.function.keepHistory', true);
			else
				db_pref.setBoolPref('downbar.function.keepHistory', false);
			db_pref.setIntPref('browser.download.manager.retention', 2);  // must be 2
		} catch(e){}
		
	}

	db_readPrefs();
	db_setStyles();
	db_checkMiniMode();
	db_populateDownloads();
	db_startInProgress();
	db_checkShouldShow();
	
	// Tooltips needs a delayed startup because for some reason it breaks the back button in Linux and Mac when run in line, see bug 17384
	// Also do integration load here
	window.setTimeout(function(){
		db_setupTooltips();
		
		// xxx this doesn't work for some reason - function calls to this script are not found, put in xul overlay instead
	/*	
		// XXX test if integration is enabled
		// Load DownThemAll integration
		var scriptLoader = Components.classes["@mozilla.org/moz/jssubscript-loader;1"].getService(Components.interfaces.mozIJSSubScriptLoader);
		var srvScope = {};
		scriptLoader.loadSubScript("chrome://downbar/content/dtaIntegration.js", srvScope);
	*/
	}, 10);
	
	// Don't show Firefox's new built-in status notification
	document.getElementById("download-monitor").collapsed = true;

	// Listen for the switch to/from private browsing
	var observ = Components.classes["@mozilla.org/observer-service;1"].getService(Components.interfaces.nsIObserverService);
  	observ.addObserver(db_privateBrowsingObs, "private-browsing", false);
	
	// Show "About Dlsb" on first time this version is used - currversion 0.9.6
	// XXX ? need to add that donate text is shown again in addons mgr, set supressDonateText to false, Interval reset too?

	var showAbout = false;
	if(oldVersion) {
		var oldVersionArray = oldVersion.split(".");
		if(oldVersionArray[0] < "0")
			showAbout = true;
		else if (oldVersionArray[0] == "0") {
			if(oldVersionArray[1] < "9")
				showAbout = true;
			else if(oldVersionArray[1] == "9") {
				if(oldVersionArray[2] < "6")
					showAbout = true;
			}
		}
		
		if(oldVersion == "0.9.6")   // Just for upgrate to 0.9.6.6 and 0.9.6.7, want to show about page this time 
			showAbout = true;
		
	}
	else  // there was no pref set
		showAbout = true;

	if(showAbout) {
		
	    window.setTimeout(function() {
	    	// Open page in new tab
			var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService();
	    	var wmed = wm.QueryInterface(Components.interfaces.nsIWindowMediator);
	    
	    	var win = wmed.getMostRecentWindow("navigator:browser");
	    	
	    	var content = win.document.getElementById("content");
	    	content.selectedTab = content.addTab("chrome://downbar/content/aboutdownbar.xul");	
	    }, 1250);
		
		db_pref.setCharPref("downbar.function.version", "0.9.6.7");
		
		// Remove the persist height and width attributes for downbarprefs window from localstore.rdf - only want to run this once (although it wouldn't hurt)
		// This should be able to be taken out in the future...unless people upgrade from old versions...
		try {
			
			var RDF = Components.classes['@mozilla.org/rdf/rdf-service;1'].getService().QueryInterface(Components.interfaces.nsIRDFService);
			var localStore = RDF.GetDataSource("rdf:local-store");
			
			var widthRes = RDF.GetResource("width");
			var heightRes = RDF.GetResource("height");
			var dbprefsRes = RDF.GetResource("chrome://downbar/content/downbarprefs.xul#downbarprefs");
			
			var oldWidth = localStore.GetTarget(dbprefsRes, widthRes, true);
			var oldHeight = localStore.GetTarget(dbprefsRes, heightRes, true);
			// If these exist, unassert them
			if (oldWidth) {
				localStore.Unassert(dbprefsRes, widthRes, oldWidth, true);
			}
			if (oldHeight) {
				localStore.Unassert(dbprefsRes, heightRes, oldHeight, true);
			}
			
		} catch(e) {}
	}
	
	// The default hide key is CTRL+SHIFT+z for hide,  CRTL+SHIFT+, (comma) for undo clear
	// Doing it this way should allow the user to change it with the downbar pref, or with the keyconfig extension
	try {
		var hideKey = db_pref.getCharPref("downbar.function.hideKey");
		if(hideKey != "z")
			document.getElementById("key_togDownbar").setAttribute("key", hideKey);
		
		var undoClearKey = db_pref.getCharPref("downbar.function.undoClearKey");
		if(undoClearKey != "VK_INSERT")
			document.getElementById("key_undoClearDownbar").setAttribute("keycode", undoClearKey);
	} catch(e) {}
	
	// User pressed the donate link in the pre-browser addon update window, so open new tab with donate page
	try {
		if(db_pref.getBoolPref("downbar.function.openDonatePage")) {

			window.setTimeout(function(){	
					var wm2 = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService();
		    		var wmed2 = wm2.QueryInterface(Components.interfaces.nsIWindowMediator);
		    		var win2 = wmed2.getMostRecentWindow("navigator:browser");
					
					var content2 = win2.document.getElementById("content");
		    		content2.selectedTab = content2.addTab("http://downloadstatusbar.mozdev.org/donateRedirect.html");
	    		}, 1500);
			
			db_pref.clearUserPref("downbar.function.openDonatePage");
		}
	} catch(e) {}

	// Developer features to be disabled on release
	//toJavaScriptConsole();
	//BrowserOpenExtensions('extensions');
	//document.getElementById("menu_FilePopup").parentNode.setAttribute("onclick", "if(event.button == 1) goQuitApplication();");

	window.removeEventListener("load", downbarInit, true);
}

function downbarClose() {
	
	// Make sure download statusbar popups up in another browser window if one is available
	//   or if that was the last browser window, check if we need to open the download manager to continue downloads
	var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
	                  
	var recentBrowser = wm.getMostRecentWindow("navigator:browser");
	if(recentBrowser)
		recentBrowser.db_newWindowFocus();
		
	else {  // That was the last browser window

		try {
			var launchDLWin = db_pref.getBoolPref("downbar.function.launchOnClose");
		} catch(e){}
		
		var db_dlmgrContractID = "@mozilla.org/download-manager;1";
		var db_dlmgrIID = Components.interfaces.nsIDownloadManager;
		db_gDownloadManager = Components.classes[db_dlmgrContractID].getService(db_dlmgrIID);

        // Check if a DLwin is already open, if so don't open it again
        if(wm.getMostRecentWindow("Download:Manager"))
            var dlwinExists = true;
        else
            var dlwinExists = false;
            
		// xxx paused downloads are included in activeDownloadCount, should I ignore paused downloads?
		if(launchDLWin && db_gDownloadManager.activeDownloadCount > 0 && !dlwinExists) {
			
			var ww = Components.classes["@mozilla.org/embedcomp/window-watcher;1"].getService(Components.interfaces.nsIWindowWatcher);
			var dlWin = ww.openWindow(null, 'chrome://mozapps/content/downloads/downloads.xul', null, 'chrome,dialog=no,resizable', null);
		}
	}

}

// Called on browser open to get all downloads from database that are supposed to show on the downbar
function db_populateDownloads() {
	
	// Remove all current downloads if any (if Options window was just applied, styles may have been changed and need to be reset)
	var downbar = document.getElementById("downbar");
	while (downbar.firstChild) {
    	downbar.removeChild(downbar.firstChild);
 	}

	var dbase = db_gDownloadManager.DBConnection;
	try {
		// XXX save this statement for later reuse?
		var stmt = dbase.createStatement("SELECT id, target, name, source, state, startTime, referrer " + 
                         "FROM moz_downloads " +
                         "WHERE DownbarShow = 1");
	}
	catch(e) {
		// The downbarshow column hasn't been added to the database yet, add it now
		dbase.executeSimpleSQL("ALTER TABLE moz_downloads ADD COLUMN DownbarShow INTEGER");
		return;
	}
	
	try {
		var id;
		while (stmt.executeStep()) {
			id = "db_" + stmt.getInt32(0);
			db_insertNewDownload(id, stmt.getString(1), stmt.getString(2), stmt.getString(3), 
								 stmt.getInt32(4), stmt.getInt64(5), stmt.getString(6));
		}
	}
	finally {
		stmt.reset();
	}
}

function db_insertNewDownload(aId, aTarget, aName, aSource, aState, aStartTime, aReferrer) {
	
	// Check if that download item already exists on the downbar
	if(document.getElementById(aId)) {
		db_setStateSpecific(aId, aState);
		return;
	}
	
	var newDownloadElem = document.getElementById("db_downloadTemplate").cloneNode(true);
	newDownloadElem.id = aId;
	newDownloadElem.lastChild.firstChild.nextSibling.setAttribute("value", aName);
	newDownloadElem.setAttribute("state", aState);
	newDownloadElem.setAttribute("referrer", aReferrer);
	newDownloadElem.setAttribute("startTime", aStartTime);  // Don't have this yet when download is still queued, but need this while populating downloads at beginning
	newDownloadElem.setAttribute("target", aTarget);
	newDownloadElem.setAttribute("source", aSource);
	newDownloadElem.setAttribute("name", aName);
	
	var downbar = document.getElementById("downbar");
	downbar.appendChild(newDownloadElem);
	
	db_setStateSpecific(newDownloadElem.id, aState);
	
	newDownloadElem.hidden = false;
	
}

function db_setStateSpecific(aDLElemID, aState) {

	var dlElem = document.getElementById(aDLElemID);
	
	var dl = db_gDownloadManager.getDownload(aDLElemID.substring(3));
	try {
		var styleDefault = db_pref.getBoolPref("downbar.style.default");
	} catch (e){}
	
	dlElem.setAttribute("state", dl.state);

	switch(aState) {
		
		case -1: // Not started
		break;
		
		case 0:  // In progress
		
			// Set startTime and referrer on download element
			dlElem.setAttribute("startTime", dl.startTime);
			try {
				dlElem.setAttribute("referrer", dl.referrer.spec);  // some downloads don't have referrers and return an error here, attribute will be left as ""
			} catch(e){}
			
			
			dlElem.setAttribute("class", "db_progressStack");
			dlElem.setAttribute("context", "progresscontext");
			dlElem.setAttribute("onclick", "db_progressClickHandle(this, event); event.stopPropagation();");
			dlElem.setAttribute("ondblclick", "");
			dlElem.setAttribute("ondraggesture", "");
			
			dlElem.firstChild.hidden = false;            // Progress bar and remainder
			dlElem.lastChild.firstChild.hidden = true;  // Icon stack
			dlElem.lastChild.lastChild.hidden = false;  // Progress indicators
			
			if(!styleDefault) {
				try {
					var progressStyle = db_pref.getCharPref("downbar.style.db_progressStack");
					dlElem.setAttribute("style", progressStyle);
				} catch (e){}	
			}
		
		break;
			
		case 4:  // Paused

			dlElem.setAttribute("class", "db_pauseStack");
			dlElem.setAttribute("context", "pausecontext");
			dlElem.setAttribute("onclick", "db_progressClickHandle(this, event); event.stopPropagation();");
			dlElem.setAttribute("ondblclick", "");
			dlElem.setAttribute("ondraggesture", "");
			
			dlElem.firstChild.hidden = false;            // Progress bar and remainder
			dlElem.lastChild.firstChild.hidden = true;  // Icon stack
			dlElem.lastChild.lastChild.hidden = false;  // Progress indicators
			
			if(!styleDefault) {
				try {
					var pausedStyle = db_pref.getCharPref("downbar.style.db_pausedHbox");
					dlElem.setAttribute("style", pausedStyle);
				} catch (e){}	
			}
			
		break;
		
		// XXX make queued downloads look different so they don't look stuck
		case 5:  // Queued
			dlElem.setAttribute("class", "db_progressStack");
			dlElem.setAttribute("context", "progresscontext");
			dlElem.setAttribute("onclick", "db_progressClickHandle(this, event); event.stopPropagation();");
			dlElem.setAttribute("ondblclick", "");
			dlElem.setAttribute("ondraggesture", "");
			
			dlElem.firstChild.hidden = false;            // Progress bar and remainder
			dlElem.lastChild.firstChild.hidden = true;  // Icon stack
			dlElem.lastChild.lastChild.hidden = true;  // Progress indicators - these won't have anything useful while queued
			
			if(!styleDefault) {
				try {
					var progressStyle = db_pref.getCharPref("downbar.style.db_progressStack");
					dlElem.setAttribute("style", progressStyle);
				} catch (e){}
			}
			
		break;
		
		case 1:  // Finished
		case 6:  // Parental Blocked
		case 7:  // AV Scanning
		case 8:  // AV Dirty
			
			// Put on the correct overlay icon based on the state
			if(aState == 6 | aState == 8)
				dlElem.lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.setAttribute("src", "chrome://downbar/skin/blocked.png");
			else if(aState == 7)
				dlElem.lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.setAttribute("src", "chrome://downbar/skin/scanAnimation.png");
			else
				dlElem.lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.setAttribute("src", "");
		
			// set endTime on download element
			var dbase = db_gDownloadManager.DBConnection;
			try {
				// XXX save this statement for later reuse? (bind parameters at run)
				var stmt = dbase.createStatement("SELECT endTime " + 
		                         "FROM moz_downloads " +
		                         "WHERE id = " + aDLElemID.substring(3));
		        
				stmt.executeStep();
				var endTime = stmt.getInt64(0);
				stmt.reset();
			} catch(e) {}
			
			dlElem.setAttribute("endTime", endTime);

			dlElem.setAttribute("class", "db_finishedHbox");
			dlElem.setAttribute("context", "donecontext");
			dlElem.setAttribute("onclick", "db_finishedClickHandle(this, event); event.stopPropagation();");
			dlElem.setAttribute("ondblclick", "db_startOpenFinished(this.id); event.stopPropagation();");
			//dlElem.setAttribute("ondragstart", "db_startDLElemDrag(this, event);");
			//dlElem.setAttribute("ondragstart", "nsDragAndDrop.startDrag(event, db_dragDropObserver);");
			//dlElem.setAttribute("ondragend", "db_endDLElemDrag(this, event);");
			
			// Get icon, fx dlmgr uses contentType to bypass cache, but I've found specifying a size will also bypass cache, 
			//     - just can't specify same icon size in the inprogress tooltips or that will be cached here
			// this way allows custom executable icons
			dlElem.lastChild.firstChild.firstChild.setAttribute("src", "moz-icon:" + dlElem.getAttribute("target") + "?size=16");
			
		/*	
		    // Keeping fx dlmgr implementatation here for now - just in case
			// Set icon - Tacking on contentType in moz-icon bypasses cache, allows custom .exe icons
			try {
				//const kExternalHelperAppServContractID = "@mozilla.org/uriloader/external-helper-app-service;1";
				//var mimeService = Components.classes[kExternalHelperAppServContractID].getService(Components.interfaces.nsIMIMEService);
				//var contentType = mimeService.getTypeFromFile(dl.targetFile);  // getting 'component not available' error, but I'm getting back a good value - not sure why the error
				
				//dlElem.lastChild.firstChild.firstChild.setAttribute("src", "moz-icon:" + dlElem.getAttribute("target") + "?size=32&contentType=" + contentType);
				
			} catch(e) {
				//dlElem.lastChild.firstChild.firstChild.setAttribute("src", "moz-icon:" + dlElem.getAttribute("target") + "?size=32");
			}
		*/
    
			dlElem.firstChild.hidden = true;              // Progress bar and remainder
			dlElem.lastChild.firstChild.hidden = false;   // Icon stack
			dlElem.lastChild.lastChild.hidden = true;     // Progress indicators
			
			if(!styleDefault) {
				try {
					var finishedStyle = db_pref.getCharPref("downbar.style.db_finishedHbox");
					dlElem.setAttribute("style", finishedStyle);
				} catch (e){}	
			}
			
		break;
		
		case 2:  // Failed
		case 3:  // Canceled
			
			// set endTime on download element
			var dbase = db_gDownloadManager.DBConnection;
			try {
				// XXX save this statement for later reuse? (bind parameters at run)
				var stmt = dbase.createStatement("SELECT endTime " + 
		                         "FROM moz_downloads " +
		                         "WHERE id = " + aDLElemID.substring(3));
		        
				stmt.executeStep();
				var endTime = stmt.getInt64(0);
				stmt.reset();
			} catch(e) {}
			
			dlElem.setAttribute("endTime", endTime);
		
			dlElem.setAttribute("class", "db_notdoneHbox");
			dlElem.setAttribute("context", "notdonecontext");
			dlElem.setAttribute("onclick", "db_finishedClickHandle(this, event); event.stopPropagation();");
			dlElem.setAttribute("ondblclick", "db_startit(this.id); event.stopPropagation();");
			dlElem.setAttribute("ondraggesture", "");
			
			dlElem.firstChild.hidden = true;  // Do canceled downloads keep the percent done?  keep the progress bar there?
			dlElem.lastChild.firstChild.hidden = false;
			dlElem.lastChild.lastChild.hidden = true;
			
			if(!styleDefault) {
				try {
					var notdoneStyle = db_pref.getCharPref("downbar.style.db_notdoneHbox");
					dlElem.setAttribute("style", notdoneStyle);
				} catch (e){}	
			}
			
		break;
	}
	
}

function db_newWindowFocus() {

	db_checkShouldShow();
	db_updateMini();

	if (db_miniMode)
		window.document.getElementById("downbarMini").collapsed = false;
	else
		window.document.getElementById("downbarHolder").collapsed = false;

}

// When a new window is opened, wait, then test if it is a browser window.  If so, collapse the downbar in the old window.  (It won't get updated anyway)
function db_hideOnBlur() {
	window.setTimeout("db_blurWait()", 100);
}

function db_blurWait() {
		
	var ww = Components.classes["@mozilla.org/embedcomp/window-watcher;1"].getService(Components.interfaces.nsIWindowWatcher);

	if (window != ww.activeWindow && ww.activeWindow != null) {
		var wintype = ww.activeWindow.document.documentElement.getAttribute('windowtype');
		if (wintype == "navigator:browser") {
			if (db_miniMode)
				window.document.getElementById("downbarMini").collapsed = true;
			else
				window.document.getElementById("downbarHolder").collapsed = true;
		}
	}
}
/*
// if there are more downloads than the queue allows, return false
function db_checkQueue() {
	var currDLs = db_gDownloadManager.activeDownloadCount;
	//d(currDLs);
	//d(db_queueNum);
	if (currDLs > db_queueNum)
		return false;
	else
		return true;
}*/

// Update inprogress downloads every sec, calls a timeout to itself at the end
function db_updateDLrepeat(progElemID) {
	var progElem = document.getElementById(progElemID);
	try {
		var state = progElem.getAttribute("state");  // just check if it's a valid element
	} catch(e) {return;}

	// xxx do i really need to keep repeating paused downloads now that elements are static (not on rdf template)
	if(state == 0 | state == 4) {  // now see if it's an in progress element
		db_calcAndSetProgress(progElemID);
		progElem.pTimeout = window.setTimeout(function(){db_updateDLrepeat(progElemID);}, 1000);
		return;
	}
	
	if(state == 5) {  // queued downloads won't have any progress yet, come back later
		progElem.pTimeout = window.setTimeout(function(){db_updateDLrepeat(progElemID);}, 300);
	}
}

function db_calcAndSetProgress(progElemID) {

	var progElem = document.getElementById(progElemID);
	var aDownload = db_gDownloadManager.getDownload(progElemID.substring(3));
	
	var newsize = parseInt(aDownload.amountTransferred / 1024);
	var totalsize = parseInt(aDownload.size / 1024);
	progElem.pTotalKBytes = totalsize;
	var oldsize = progElem.pOldSavedKBytes;
	if (!oldsize) oldsize = 0;

	// If download stops, Download manager will incorrectly tell us the last positive speed, this fixes that - speed can go to zero
	// Count up to 3 intervals of no progress and only set speed to zero if we hit that
	var dlRate = aDownload.speed  / 1024;
	var noProgressIntervals = progElem.noProgressIntervals;
	if(!noProgressIntervals)
		noProgressIntervals = 0;

	if(newsize - oldsize > 0) {
		progElem.noProgressIntervals = 0;
	}
	else {
		// There was no progress
		noProgressIntervals++;
		progElem.noProgressIntervals = noProgressIntervals;
		if(noProgressIntervals > 3) {
			dlRate = 0;
		}
	}

	// XXX setting the progress for a paused download after a refresh or new window should get easier
	// https://bugzilla.mozilla.org/show_bug.cgi?id=394548
	
	// Firefox download manager doesn't set the speed to zero when the download is paused
	if(progElem.getAttribute("state") == 4)
		dlRate = 0;
	
	progElem.pOldSavedKBytes = newsize;

	// Fix and set the size downloaded so far
	if(newsize > 1024)
		var currSize = db_convertToMB(newsize) + " " + db_strings.getString("MegaBytesAbbr");
	else
		var currSize = newsize + " " + db_strings.getString("KiloBytesAbbr");
	progElem.lastChild.lastChild.lastChild.previousSibling.value = currSize;
	
	// Fix and set the speed
	var fraction = parseInt( ( dlRate - ( dlRate = parseInt( dlRate ) ) ) * 10);
	var newrate = dlRate + "." + fraction;
	progElem.lastChild.lastChild.firstChild.nextSibling.value = newrate;
	newrate = parseFloat(newrate);

	// If the mode is undetermined, just count up the MB
	// Firefox bug - totalsize should be -1 when the filesize is unknown?
	if (parseInt(newsize) > parseInt(totalsize) ) {

		var db_unkAbbr = db_strings.getString("unknownAbbreviation");  // "Unk." in english

		// Percent and remaining time will be unknown
		progElem.lastChild.lastChild.firstChild.value = db_unkAbbr;
		progElem.lastChild.lastChild.lastChild.value = db_unkAbbr;

	}
	else {
		// Get and set percent
		var currpercent = aDownload.percentComplete;
		var newWidth = parseInt(currpercent/100 *  progElem.firstChild.boxObject.width);  // progElem.firstChild = inner width, not incl borders of DL element
		progElem.firstChild.firstChild.minWidth = newWidth;
		progElem.lastChild.lastChild.firstChild.setAttribute("value", (currpercent + "%"));

		// Calculate and set the remaining time
		var remainingkb = parseInt(totalsize - newsize);
		if(dlRate != 0) {
			var secsleft = (1 / newrate) * remainingkb;
			var remaintime = db_formatSeconds(secsleft);
			progElem.lastChild.lastChild.lastChild.value = remaintime;
		}
		else {
			var db_unkAbbr = db_strings.getString("unknownAbbreviation");  // "Unk." in english
			progElem.lastChild.lastChild.lastChild.value = "--:--";
		}
	}
	
//d(remaintime + "   " + (currpercent + "%") + "   " + currSize + "   " + newrate);
	
	// Speed sensitive color
	if(db_speedColorsEnabled) {
		// Incremental
		var newcolor = db_speedColor0;
		if(newrate > db_speedDivision3)
			newcolor = db_speedColor3;
		else if (newrate > db_speedDivision2)
			newcolor = db_speedColor2;
		else if (newrate > db_speedDivision1)
			newcolor = db_speedColor1;

		if(db_useGradients)
			progElem.firstChild.firstChild.setAttribute("style", "background-color:" + newcolor + ";background-image:url(chrome://downbar/skin/whiteToTransGrad.png);border-right:0px solid transparent");
		else
			progElem.firstChild.firstChild.setAttribute("style", "background-color:" + newcolor + ";background-image:url();border-right:0px solid transparent");

		/*// Continuously Variable
		var baseRed = 0;
		var baseGreen = 0;
		var baseBlue = 254;
		var finalRed = 90;
		var finalGreen = 90;
		var finalBlue = 255;

		var maxSpeed = 700;
		var conversionRed = maxSpeed / (finalRed - baseRed);
		var conversionGreen = maxSpeed / (finalGreen - baseGreen);
		var conversionBlue = maxSpeed / (finalBlue - baseBlue);
		d("convR " + conversionRed);
		d("convG " + conversionGreen);
		d("convB " + conversionBlue);
		var newRed = parseInt(baseRed + newrate / conversionRed);
		var newGreen = parseInt(baseGreen + newrate / conversionGreen);
		var newBlue = parseInt(baseBlue + newrate / conversionBlue);
		if(newRed > 255)
			newRed = 255;
		if(newGreen > 255)
			newGreen = 255;
		if(newBlue > 255)
			newBlue = 255;

		d("newGreen: " + newGreen + "   " + "newRed: " + newRed);
		progElem.firstChild.firstChild.setAttribute("style", "background-color:rgb("+ newRed + "," + newGreen + "," + newBlue + ");");
	*/
	}
}

// The clicked-on node could be a child of the actual download element we want
// The child nodes won't have an id
function db_findDLNode(popupNode) {
	while(!popupNode.id) {
		popupNode = popupNode.parentNode;
	}
	return(popupNode.id);
}

function db_startOpenFinished(idtoopen) {

	var dlElem = document.getElementById(idtoopen);
	var localFile = dlElem.getAttribute("target");
	var state = dlElem.getAttribute("state");
	
	if(state == 6 | state == 8) {  // Don't open Anti-virus Blocked downloads
		var browserStrings = document.getElementById("bundle_browser");
		document.getElementById("statusbar-display").label = "Download Statusbar: " + db_strings.getString("avCannotOpen");
    	window.setTimeout(function(){document.getElementById("statusbar-display").label = browserStrings.getString("nv_done");}, 4000);
		return;
	}
		
	if(db_useAnimation) {
		document.getElementById(idtoopen).lastChild.firstChild.firstChild.src = "chrome://downbar/skin/greenArrow16.png";
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.id = "slidePic";
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.lastChild.flex = "0";

		// Do shift to right, after right is done, it calls shift from left
		db_openFinishedContRight(idtoopen, 16, localFile);
		window.setTimeout(function(){db_finishOpen(idtoopen);}, 150);
	}
	else {
		db_finishOpen(idtoopen);
	}
}

function db_openFinishedContRight(idtoopen, currshift, localFile) {

	if(currshift < 0) {
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.lastChild.flex = "1";
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.flex = "0";
		db_openFinishedContLeft(idtoopen, 16, localFile)
	}
	else {
		var styleAttr = "list-style-image:url('moz-icon:" + localFile + "');-moz-image-region:rect(0px " + currshift + "px 16px 0px);";
		document.getElementById("slidePic").setAttribute("style", styleAttr);
		window.setTimeout(function(){db_openFinishedContRight(idtoopen, currshift-2, localFile);}, 10);
	}
}

function db_openFinishedContLeft(idtoopen, currshift, localFile) {

	if(currshift < 0) {
		//d("exiting");
		//db_finishOpen(idtoopen);
		document.getElementById(idtoopen).lastChild.firstChild.firstChild.src = "moz-icon:" + localFile;
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.id = "";
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.setAttribute("style", "");
		document.getElementById(idtoopen).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.flex = "1";
	}
	else {
		var styleAttr = "list-style-image:url('moz-icon:" + localFile + "');-moz-image-region:rect(0px 16px 16px " + currshift + "px);";
		document.getElementById("slidePic").setAttribute("style", styleAttr);
		window.setTimeout(function(){db_openFinishedContLeft(idtoopen, currshift-2, localFile);}, 10);
	}
}

function db_finishOpen(idtoopen) {
	
	var file = document.getElementById(idtoopen).getAttribute("target");
	file = db_getLocalFileFromNativePathOrUrl(file);
	if(!file.exists()) {
		var browserStrings = document.getElementById("bundle_browser");
		document.getElementById("statusbar-display").label = "Download Statusbar: " + db_strings.getString("fileNotFound");
    	window.setTimeout(function(){document.getElementById("statusbar-display").label = browserStrings.getString("nv_done");}, 4000);
		return;
	}

	try {
    	file.launch();
    } catch (ex) {
    	// if launch fails, try sending it through the system's external
    	// file: URL handler
    	db_openExternal(file);
    }

	try {
		var removeOnOpen = db_pref.getBoolPref("downbar.function.removeOnOpen");
		if (removeOnOpen) {
			db_animateDecide(idtoopen, "clear", {shiftKey:false});
		}
	} catch (e) {}

}

function db_startShowFile(idtoshow) {

	if(db_useAnimation) {
		document.getElementById(idtoshow).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.id = "picToShrink";
		document.getElementById("picToShrink").src = "moz-icon:" + document.getElementById(idtoshow).getAttribute("target");
		document.getElementById(idtoshow).lastChild.firstChild.firstChild.src = "chrome://downbar/skin/folder.png";
		document.getElementById("picToShrink").style.MozOpacity = .5;
		db_showAnimateCont(idtoshow, 16);
		window.setTimeout(function(){db_finishShow(idtoshow);}, 50);
	}
	else {
		db_finishShow(idtoshow);
	}
}

function db_showAnimateCont(idtoshow, newsize) {

	if(newsize < 8) {

		// put the icon back how it's supposed to be after 1 sec.
		window.setTimeout(function(){	try{
											document.getElementById("picToShrink").src = "";
											document.getElementById("picToShrink").setAttribute("style", "height:16px;width:16px;");
											document.getElementById(idtoshow).lastChild.firstChild.firstChild.src = "moz-icon:" + document.getElementById(idtoshow).getAttribute("target");
											document.getElementById("picToShrink").id = "";
										} catch(e){}
									}, 1000);
	}
	else {
		document.getElementById("picToShrink").setAttribute("style", "height:" + newsize + "px;width:" + newsize + "px;");
		window.setTimeout(function(){db_showAnimateCont(idtoshow, newsize-2);}, 25);
	}
}

function db_finishShow(idtoshow) {

	var file = document.getElementById(idtoshow).getAttribute("target");
	file = db_getLocalFileFromNativePathOrUrl(file);
	try {
		file.reveal();
	} catch(e) {
		var parent = file.parent;
      if (parent) {
        db_openExternal(parent);
      }
	}

	try {
		var removeOnShow = db_pref.getBoolPref("downbar.function.removeOnShow");
		if (removeOnShow) {
			db_animateDecide(idtoshow, "clear", {shiftKey:false});
		}
	} catch (e) {}
}

// This is needed to do timeouts in multiple browser windows from the downbar.js component, (enumerating each window and calling timeout doesn't work)
function db_startAutoClear(idtoclear, timeout) {

	window.setTimeout(function(){db_animateDecide(idtoclear, "clear", {shiftKey:false});}, timeout)

}

function db_animateDecide(elemid, doWhenDone, event) {

	if(db_useAnimation && !event.shiftKey) {
		if(db_miniMode)
			db_clearAnimate(elemid, 1, 20, "height", doWhenDone);
		else
			db_clearAnimate(elemid, 1, 125, "width", doWhenDone);
	}

   	else {
   		if(doWhenDone == "clear")
   			db_clearOne(elemid);
   		//else if(doWhenDone == "remove")
   		//	db_removeit(elemid);
   		else
   			db_startDelete(elemid, event);
   	}
}

function db_clearAnimate(idtoanimate, curropacity, currsize, heightOrWidth, doWhenDone) {

	if(curropacity < .05) {
		if(doWhenDone == "clear")
			db_clearOne(idtoanimate);
		else
			db_finishDelete(idtoanimate);
		return;
	}
	document.getElementById(idtoanimate).style.MozOpacity = curropacity-.04;
	if(heightOrWidth == "width") {
		document.getElementById(idtoanimate).maxWidth = currsize-5.2;
		window.setTimeout(function(){db_clearAnimate(idtoanimate, curropacity-.04, currsize-5.2, "width", doWhenDone);}, 10);
	}
	else {
		document.getElementById(idtoanimate).maxHeight = currsize-0.8;
		window.setTimeout(function(){db_clearAnimate(idtoanimate, curropacity-.04, currsize-0.8, "height", doWhenDone);}, 10);
	}

}

// xxx move this to the downbar component
function db_clearOne(idtoclear) {
		
	// Clear the download item in all browser windows
	var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
	var e = wm.getEnumerator("navigator:browser");
	var win, winElem;

	while (e.hasMoreElements()) {
		win = e.getNext();
		
		try {
			winElem = win.document.getElementById(idtoclear);
			win.document.getElementById("downbar").removeChild(winElem);
			
			win.db_checkShouldShow();
			win.db_updateMini();
		} catch(e){}
	}
	
	var DLid = idtoclear.substring(3);
	try {
		var keepHist = db_pref.getBoolPref('downbar.function.keepHistory');
		if(keepHist) {
			var dbase = db_gDownloadManager.DBConnection;
			dbase.executeSimpleSQL("UPDATE moz_downloads SET DownbarShow=0 WHERE id=" + DLid);
			
			var db_downbarComp = Components.classes['@devonjensen.com/downbar/downbar;1'].getService().wrappedJSObject;
			db_downbarComp.db_recentCleared.push(DLid);
				
		}
		else {
			db_gDownloadManager.removeDownload(DLid);
		}
	} catch(e){}
}

function db_clearAll() {
	
	var db_downbarComp = Components.classes['@devonjensen.com/downbar/downbar;1'].getService().wrappedJSObject;
	db_downbarComp.db_clearAllFinished();
	
}

function db_undoClear() {
	
	var db_downbarComp = Components.classes['@devonjensen.com/downbar/downbar;1'].getService().wrappedJSObject;
	db_downbarComp.db_undoClearOne();
	
}

function db_startDelete(elemIDtodelete, event) {
	
	// Get the nsiFile.path representation so the path is formatted pretty (rather than "file:///...")
	var localFile = db_getLocalFileFromNativePathOrUrl(document.getElementById(elemIDtodelete).getAttribute("target"))
	var localFilePath = localFile.path;
	try {
		var askOnDelete = db_pref.getBoolPref("downbar.function.askOnDelete");
	} catch (e) {}
	
	if (askOnDelete) {
		var db_confirmMsg = db_strings.getString("deleteConfirm") + "\n\n" + localFilePath + "\n ";
		
		var promptSer = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
		if(!promptSer.confirm(null, "Download Statusbar", db_confirmMsg))
			return;
	}

	if(db_useAnimation && !event.shiftKey) {
		document.getElementById(elemIDtodelete).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.src = "chrome://downbar/skin/delete1.png";
		window.setTimeout(function(){db_deleteAnimateCont(elemIDtodelete);}, 150);
	}
	else
		db_finishDelete(elemIDtodelete);

}

function db_deleteAnimateCont(elemIDtodelete) {

	document.getElementById(elemIDtodelete).lastChild.firstChild.lastChild.firstChild.nextSibling.firstChild.nextSibling.src = "chrome://downbar/skin/delete2.png";

	if(db_miniMode)
		db_clearAnimate(elemIDtodelete, 1, 20, "height", "delete");
	else
		db_clearAnimate(elemIDtodelete, 1, 125, "width", "delete");
}

function db_finishDelete(elemIDtodelete) {
	
	var file = document.getElementById(elemIDtodelete).getAttribute("target");
	file = db_getLocalFileFromNativePathOrUrl(file);
	db_clearOne(elemIDtodelete);

	if (file.exists()) {
		try {
			file.remove(false); // false is the recursive setting
			
		} catch (e) {
			try {
				// May have failed because of file permissions, set some permissions and try to delete again
				file.permissions = 438;
				file.remove(false);
			} catch(e){}
		}

	}
}

function db_cancelprogress(elemtocancel) {
	
	var localFileUrl = document.getElementById(elemtocancel).getAttribute("target");
	db_gDownloadManager.cancelDownload(elemtocancel.substring(3));
	db_checkShouldShow();
	db_clearOne(elemtocancel);

	var localFile = db_getLocalFileFromNativePathOrUrl(localFileUrl);
	if (localFile.exists())
		localFile.remove(false);
}

function db_cancelAll() {
	
	var dbelems = document.getElementById("downbar").childNodes;
	var cancPos = new Array(); // hold the child id of elements that are canceled, so that they can be removed in the 2nd for loop
	var posCount = 1;
	var state;
	for (var i = 0; i <= dbelems.length - 1; ++i) {
			state = dbelems[i].getAttribute("state");
			if (state == 0 | state == 4 | state == 5) {
				db_gDownloadManager.cancelDownload(dbelems[i].id.substring(3));
				cancPos[posCount] = dbelems[i];
				++posCount;
			}
	}

	var localFile;
	// Need to clear them after the first for loop is complete
	for (var j = 1; j < posCount; ++j) {
		try {  // canceling queued downloads will cause and error (b/c there isn't a local file yet i think?)
			db_clearOne(cancPos[j].id);
			localFile = db_getLocalFileFromNativePathOrUrl(cancPos[j].getAttribute("target"));
			if (localFile.exists());
				localFile.remove(false);		
		} catch(e) {}
	}
	db_checkShouldShow();
}

function db_pause(elemid, aEvent) {
		
	// Stop repeating tooltip updates and close tooltip if present
	db_stopTooltip(elemid);
	document.getElementById("db_progTip").hidePopup();
	
	
	db_gDownloadManager.pauseDownload(elemid.substring(3));
	// Update display now so there is no lag time without good values
	db_calcAndSetProgress(elemid);
}

function db_resume(elemid, aEvent) {
	
	// Stop repeating tooltip updates and close tooltip if present
	db_stopTooltip(elemid);
	document.getElementById("db_progTip").hidePopup();
	
	db_gDownloadManager.resumeDownload(elemid.substring(3));
	// Update display now so there is no lag time without good values
	db_calcAndSetProgress(elemid);
}

function db_pauseAll() {
	var dbelems = document.getElementById("downbar").childNodes;
	var i = 0;
	// I don't know why a for loop won't work here but okay
	while (i < dbelems.length) {

		if (dbelems[i].getAttribute("state") == 0 | dbelems[i].getAttribute("state") == 5) {
			db_pause(dbelems[i].id, null);
		}
		i = i + 1;
	}
}

function db_resumeAll() {
	var dbelems = document.getElementById("downbar").childNodes;
	var i = 0;
	while (i < dbelems.length) {
		if (dbelems[i].getAttribute("state") == 4) {
			db_resume(dbelems[i].id, null);
		}
		i = i + 1;
	}
}

function db_copyURL(elemtocopy) {

	const gClipboardHelper = Components.classes["@mozilla.org/widget/clipboardhelper;1"]
														.getService(Components.interfaces.nsIClipboardHelper);
	gClipboardHelper.copyString(document.getElementById(elemtocopy).getAttribute("source"));
}

function db_setupReferrerContextMenuItem(aMenuItem, dlElemID) {
	
	if(document.getElementById(dlElemID).getAttribute("referrer") == "")
		document.getElementById(aMenuItem).disabled = true;
	else
		document.getElementById(aMenuItem).disabled = false;
	
}

function db_visitRefWebsite(dlElemID) {

	var refURL = document.getElementById(dlElemID).getAttribute("referrer");
	
	if(refURL != "") {
		// Open page in new tab
		var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService();
	    var wmed = wm.QueryInterface(Components.interfaces.nsIWindowMediator);
	    
	    var win = wmed.getMostRecentWindow("navigator:browser");
	    if (!win)
	    	win = window.openDialog("chrome://browser/content/browser.xul", "_blank", "chrome,all,dialog=no", refURL, null, null);
	    else {
	    	var content = win.document.getElementById("content");
	    	content.selectedTab = content.addTab(refURL);	
	    }
		
	}
}

function db_startit(elemid) {
	
	db_gDownloadManager.retryDownload(elemid.substring(3));
}
/*
function db_stopit(elemtostop) {
	db_gDownloadManager.cancelDownload(elemtostop.substring(3));
	var DLelem = document.getElementById(elemtostop);
	var f = db_getLocalFileFromNativePathOrUrl(DLelem.getAttribute("target"));
	if (f.exists())
		f.remove(false); // false is the recursive setting

	window.setTimeout("db_updateMini()", 444);
}

function db_stopAll() {

	var dbelems = document.getElementById("downbar").childNodes;
	for (i = 1; i <= dbelems.length - 1; ++i) {
		if (dbelems[i].getAttribute("context") == "progresscontext") {  // just using context as an indicator of that type of element
			db_gDownloadManager.cancelDownload(dbelems[i].id);
		}
	}
}
*/

// Determine if downbar holder should be shown based on presence of downloads
function db_checkShouldShow() {

	var downbarelem = document.getElementById("downbar");

	if(!db_miniMode) {

		if (downbarelem.childNodes.length > 0) {
			document.getElementById("downbarHolder").hidden = false;
		}
		else {
			document.getElementById("downbarHolder").hidden = true;
		}
	}
}

function db_setStyles() {

	var downbarelem = document.getElementById("downbar");
	var dlItemTemplate = document.getElementById("db_downloadTemplate");

	try {
		var styleDefault = db_pref.getBoolPref("downbar.style.default");
		var showMainButton = db_pref.getBoolPref("downbar.display.mainButton");
		var showClearButton = db_pref.getBoolPref("downbar.display.clearButton");
		var showToMiniButton = db_pref.getBoolPref("downbar.display.toMiniButton");
	} catch (e){}

	if(showMainButton)
		document.getElementById("downbarMainMenuButton").hidden = false;
	else
		document.getElementById("downbarMainMenuButton").hidden = true;

	if(showClearButton) {
		document.getElementById("downbarClearButton").hidden = false;
		document.getElementById("downbarClearButtonMini").hidden = false;
	}
	else {
		document.getElementById("downbarClearButton").hidden = true;
		document.getElementById("downbarClearButtonMini").hidden = true;
	}
		

	if(showToMiniButton) {
		document.getElementById("downbarToMiniButton").hidden = false;
		document.getElementById("downbarToFullButton").hidden = false;
	}
	else {
		document.getElementById("downbarToMiniButton").hidden = true;
		document.getElementById("downbarToFullButton").hidden = true;
	}
		

	if(styleDefault) {
		// Set style to nothing ("") so that class css will be used
		downbarelem.setAttribute("style", "");
		
		dlItemTemplate.firstChild.firstChild.setAttribute("style", "");
		dlItemTemplate.firstChild.lastChild.setAttribute("style", "");
		dlItemTemplate.lastChild.firstChild.nextSibling.setAttribute("style", "");
		
		for(var i=0; i<4; ++i)
			dlItemTemplate.lastChild.lastChild.childNodes[i].setAttribute("style", "");
		
		document.getElementById("db_widthSpacer").setAttribute("style", "min-width:135px;");
		
		document.getElementById("downbarMainMenuButton").setAttribute("style", "");
		document.getElementById("downbarClearButton").setAttribute("style", "");
		document.getElementById("downbarToMiniButton").setAttribute("style", "");
		document.getElementById("downbarHolder").setAttribute("style", "");

		if(db_useGradients) {
			dlItemTemplate.firstChild.firstChild.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
			dlItemTemplate.setAttribute("style", "background-image:url(chrome://downbar/skin/whiteToTransGrad.png);");
		}
		else {
			dlItemTemplate.firstChild.firstChild.setAttribute("style", "");
			dlItemTemplate.setAttribute("style", "");
		}

	}
	else {
		// Read custom prefs
		try {
			var downbarStyle = db_pref.getCharPref("downbar.style.db_downbar");
			var downbarPopupStyle = db_pref.getCharPref("downbar.style.db_downbarPopup");
			var finishedHboxStyle = db_pref.getCharPref("downbar.style.db_finishedHbox");
			var progressbarStyle = db_pref.getCharPref("downbar.style.db_progressbar");
			var progressremainderStyle = db_pref.getCharPref("downbar.style.db_progressremainder");
			var filenameLabelStyle = db_pref.getCharPref("downbar.style.db_filenameLabel");
			var progressIndicatorStyle = db_pref.getCharPref("downbar.style.db_progressIndicator");
			var buttonStyle = db_pref.getCharPref("downbar.style.db_buttons");
		} catch (e){}

		// Set styles to the new style - automatically overrides the class css rules
		if(db_miniMode)
			downbarelem.setAttribute("style", downbarPopupStyle);
		else
			downbarelem.setAttribute("style", downbarStyle);
		
		dlItemTemplate.firstChild.firstChild.setAttribute("style", progressbarStyle);
		dlItemTemplate.firstChild.lastChild.setAttribute("style", progressremainderStyle);
		dlItemTemplate.lastChild.firstChild.nextSibling.setAttribute("style", filenameLabelStyle);
		
		for(var i=0; i<4; ++i)
			dlItemTemplate.lastChild.lastChild.childNodes[i].setAttribute("style", progressIndicatorStyle);

		var spacerW = parseInt(finishedHboxStyle.split(":")[2]);  // This is for getting the minimode popup the correct custom width
		document.getElementById("db_widthSpacer").setAttribute("style", "min-width:" + spacerW + "px;");
		
		document.getElementById("downbarMainMenuButton").setAttribute("style", buttonStyle);
		document.getElementById("downbarClearButton").setAttribute("style", buttonStyle);
		document.getElementById("downbarToMiniButton").setAttribute("style", buttonStyle);
		
		// Set the background of the buttons to the same color as the downbar) background (using the downbar mini popup style color which is the same)
		//  (partially transparent buttons show the downbarHolder behind)
		document.getElementById("downbarHolder").setAttribute("style", downbarPopupStyle);
	}
}

function db_setupTooltips() {
	
	// Setup whether to use default partially transparent tooltips (windows) or opaque solid backed tooltips (linux, mac)
	try {
		var useOpTooltips = db_pref.getBoolPref("downbar.function.useTooltipOpacity"); // Null on first install
	} catch (e) {}
	
	if(useOpTooltips == null) {
		// xxx this should probably go with the "first run" stuff in the future
		var os = Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULRuntime).OS;
		if(os != "WINNT") {
			db_pref.setBoolPref("downbar.function.useTooltipOpacity", false);
			useOpTooltips = false;
		}
		else {
			db_pref.setBoolPref("downbar.function.useTooltipOpacity", true);
			useOpTooltips = true;
		}	
	}
	
	// Because tooltip background transparency cannot be set on the fly, 
	//   (not sure why this is, seems like the background is cached or 
	//    set permanently to opaque if is not explicitly transparent at startup)
	// There are two tooltips each for "finshed" downloads and "progress" downloads. 
	// We decide which to use, then move the tooltip content from a temporary tooltip
	// onto the one we want.
	// Right now, tooltip background transparency is crashing linux (June 2007)
	
	if(useOpTooltips == true) {
		
		var finTooltipContent = document.getElementById("db_finTipContent");
		var fintip_tr = document.getElementById("fintip_transparent");
		fintip_tr.removeChild(fintip_tr.firstChild);
		fintip_tr.appendChild(finTooltipContent);
		fintip_tr.setAttribute("id", "db_finTip");
		
		var progTooltipContent = document.getElementById("db_progTipContent");
		var progtip_tr = document.getElementById("progresstip_transparent");
		progtip_tr.removeChild(progtip_tr.firstChild);
		progtip_tr.appendChild(progTooltipContent);
		progtip_tr.setAttribute("id", "db_progTip");
		
	}
	else {
		var finTooltipContent = document.getElementById("db_finTipContent");
		var fintip_op = document.getElementById("fintip_opaque");
		fintip_op.removeChild(fintip_op.firstChild);
		fintip_op.appendChild(finTooltipContent);
		fintip_op.setAttribute("id", "db_finTip");
		
		var progTooltipContent = document.getElementById("db_progTipContent");
		var progtip_op = document.getElementById("progresstip_opaque");
		progtip_op.removeChild(progtip_op.firstChild);
		progtip_op.appendChild(progTooltipContent);
		progtip_op.setAttribute("id", "db_progTip");
		
		// Set the proper background images for opaque tooltips, (default is for transparent)
		document.getElementById("db_finTipLeftImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/leftTooltip_white_square.png');");
		document.getElementById("db_finTipRightImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/rightTooltip_white_square.png');");
		document.getElementById("db_finTipMiddle").setAttribute("style", "background-image: url('chrome://downbar/skin/middleTooltip_white_160.png');");
		document.getElementById("db_progTipLeftImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/leftTooltip_white_square.png');");
		document.getElementById("db_progTipRightImg").setAttribute("style", "list-style-image: url('chrome://downbar/skin/rightTooltip_white_square.png');");
		document.getElementById("db_progTipMiddle").setAttribute("style", "background-image: url('chrome://downbar/skin/middleTooltip_white_160.png');");
		document.getElementById("db_finTipImgPreviewBox").setAttribute("style", "background-image: url('chrome://downbar/skin/middleTooltip_white_160.png');");
		
	}
}

function db_stopTooltip(dlElem) {
	//d("in stopTooltip");
	try {
		var elem = document.getElementById(dlElem);
		window.clearTimeout(elem.getAttribute("pTimeCode"));
		elem.removeAttribute("pTimeCode");  // Remove it so we can detect and prevent duplicate update repeats
	} catch(e) {}
}

function db_setupProgTooltip(progElem) {
	//d("in setupProgTooltip");
	
	var elem = document.getElementById(progElem);
	
	// If there is already a timeout for continuing this tooltip, don't start another one
	if(elem.getAttribute("pTimeCode"))
		return;
	
	document.getElementById("db_progTipIcon").setAttribute("src", "moz-icon:" + elem.getAttribute("target") + "?size=64"); // ask for a different size than the finished tooltips so that it will bypass cache
	document.getElementById("db_progTipSource").value = elem.getAttribute("source");
	
	var localFile = db_getLocalFileFromNativePathOrUrl(elem.getAttribute("target"));
	document.getElementById("db_progTipTarget").value = " " + localFile.path;  // This way it is formatted without the 'file:///'

	db_makeTooltip(progElem);
}


// Calls a timeout to itself at the end so the tooltip keeps updating with in progress info
function db_makeTooltip(dlElemID) {
	//d("in makeTooltip: " + dlElemID);
	try {
		var elem = document.getElementById(dlElemID);
		
		var state = elem.getAttribute("state");
		if(state != 0 && state != 4 && state != 5) {  // if it isn't inprog, paused, or queued, return 
			document.getElementById("db_progTip").hidePopup();
			return;
		}
		
		var additionalText = " ";  // status text to be added after filename
		var db_unkStr = db_strings.getString("unknown");
		
		// if the state is queued, we won't know these
		if (state == 5) {
			percent = db_unkStr;
			totalSize = db_unkStr;
			remainTime = "--:--";
			currSize = "0 " + db_strings.getString("KiloBytesAbbr");
			speed = "0.0"
			additionalText = " - " + db_strings.getString("starting") + " ";
		}
		else { // state is inprog or paused
			
			try {
				var percent = elem.lastChild.lastChild.firstChild.value;
				var speed = elem.lastChild.lastChild.firstChild.nextSibling.value;
				var currSize = elem.lastChild.lastChild.lastChild.previousSibling.value;
				var remainTime = elem.lastChild.lastChild.lastChild.value;
				var totalSize = elem.pTotalKBytes;
			} catch(e) {} 	
			
			if (state == 4) {
				additionalText = " - " + db_strings.getString("paused") + " ";
			}
			
			// If the mode is undetermined, we won't know these - should totalsize be -1?
			if (parseInt(currSize) > parseInt(totalSize)) {
				percent = db_unkStr;
				totalSize = db_unkStr;
				remainTime = db_unkStr;
			}
			else {
				if (totalSize > 1024)
					totalSize = db_convertToMB(totalSize) + " " + db_strings.getString("MegaBytesAbbr");
				else
					totalSize = totalSize + " " + db_strings.getString("KiloBytesAbbr");
			}
		}
		
		document.getElementById("db_progTipFileName").value = elem.getAttribute("name") + additionalText;   // for some reason the last char is getting cut off by about 2px, adding a space after fixes it
		document.getElementById("db_progTipStatus").value = " " + currSize + " of " + totalSize + " (at " + speed + " " + db_strings.getString("KBperSecond") + ") ";
		document.getElementById("db_progTipTimeLeft").value = " " + remainTime + " ";   // for some reason the first and last number is getting cut off by about 2px, this fixes it
		document.getElementById("db_progTipPercentText").value = " " + percent + " ";
		
		elem.setAttribute("pTimeCode", window.setTimeout(function(){db_makeTooltip(dlElemID);}, 1000));
	} catch(e) {
		document.getElementById("db_progTip").hidePopup();
	}
}

function db_makeFinTip(idtoview) {

	var dlElem = document.getElementById(idtoview);
	var dl = db_gDownloadManager.getDownload(idtoview.substring(3));
	
	var localFile = db_getLocalFileFromNativePathOrUrl(dlElem.getAttribute("target"));
	var url = dlElem.getAttribute("source");
	var localFilename = dlElem.getAttribute("name");
	
	// if the download is cancelled or failed, indicate after the filename, otherwise, only print the filename
	// for some reason the last char is getting cut off by about 2px, adding a trailing space fixes it
	var state = dlElem.getAttribute("state");
	var additionalText = " ";
	
	if (state == 2)
		additionalText = " - " + db_strings.getString("failed") + " ";
	else if (state == 3)
		additionalText = " - " + db_strings.getString("cancelled") + " ";
	else if (state == 6 | state == 8)
		additionalText = " - " + db_strings.getString("avBlocked") + " ";
	else if (state == 7)
		additionalText = " - " + db_strings.getString("avScanning") + " ";
	
	document.getElementById("db_finTipFileName").value = localFilename + additionalText;

	if (state == 6 | state == 8) {  // antivirus blocked - use the firefox error icon like the download manager
		document.getElementById("db_finTipIcon").setAttribute("src", "chrome://global/skin/icons/Error.png");
	}
	else {
		// Get icon, fx dlmgr uses contentType to bypass cache, but I've found specifying a size will also bypass cache, 
		//     - just can't specify same icon size in the inprogress tooltips or that will be cached here
		// this way allows custom executable icons
		// Actually this doesn't work on linux - not sure why b/c the size attribute is fine in the dlmgr implementation, and size=16 work fine for the finished dl item in setStateSpecific
		//document.getElementById("db_finTipIcon").setAttribute("src", "moz-icon:" + dlElem.getAttribute("target") + "?size=32");
		
		
	    // Keeping fx dlmgr implementation here for now - just in case
		// Set icon - Tacking on contentType in moz-icon bypasses cache, allows custom .exe icons
		try {
			const kExternalHelperAppServContractID = "@mozilla.org/uriloader/external-helper-app-service;1";
			var mimeService = Components.classes[kExternalHelperAppServContractID].getService(Components.interfaces.nsIMIMEService);
			var contentType = mimeService.getTypeFromFile(dl.targetFile);  // getting 'component not available' error, but I'm getting back a good value - not sure why the error
	
			document.getElementById("db_finTipIcon").setAttribute("src", "moz-icon:" + dlElem.getAttribute("target") + "?size=32&contentType=" + contentType);
			
		} catch(e) {
			//document.getElementById("db_finTipIcon").setAttribute("src", "moz-icon:" + dlElem.getAttribute("target") + "?size=32");
		}
	}
	
/**/
	
	var localFileSplit = localFilename.split(".");
	var fileext = localFileSplit[localFileSplit.length-1].toLowerCase();
	
	if(fileext == "gif" | fileext == "jpg" | fileext == "png" | fileext == "jpeg") {
		db_getImgSize(localFile);
		document.getElementById("db_finTipImgPreviewBox").hidden = false;
	}
	
	try {
		var startTime = dlElem.getAttribute("startTime");
		var endTime = dlElem.getAttribute("endTime");
		seconds = (endTime-startTime)/1000000;
		var completeTime = db_formatSeconds(seconds);
		if (completeTime == "00:00")
			completeTime = "<00:01";
		
	} catch(e) {
		seconds = -1;
		completeTime = db_strings.getString("unknown");
	}
	
	// Get DL size from the filesystem
	try {
		var dlSize = parseInt(localFile.fileSize / 1024);  // convert bytes to kilobytes
		var sizeString = dlSize;
		
		if (sizeString > 1024) {
			sizeString = db_convertToMB(sizeString);
			sizeString = sizeString + " " + db_strings.getString("MegaBytesAbbr");
		}
		else
			sizeString = sizeString + " " + db_strings.getString("KiloBytesAbbr");
		
	} catch(e) {
		// File doesn't exist
		dlSize = -1;
		var sizeString = db_strings.getString("fileNotFound");
	}

	try {
		if(dlSize != -1 && seconds != -1) {
			if(seconds == 0) 
				seconds = 1;
			var avgSpeed = dlSize / seconds;
			avgSpeed = Math.round(avgSpeed*100)/100;  // two decimal points
			avgSpeed = avgSpeed + " " + db_strings.getString("KBperSecond");
		}
		else {
			var avgSpeed = db_strings.getString("unknown");
		}
	} catch(e) {}

	document.getElementById("db_finTipSource").value = url;
	document.getElementById("db_finTipTarget").value = " " + localFile.path + " ";
	document.getElementById("db_finTipSize").value = " " + sizeString + " ";
	document.getElementById("db_finTipTime").value = " " + completeTime + " "; // for some reason the first and last number is getting cut off by about 2px, these spaces fix it
	document.getElementById("db_finTipSpeed").value = " " + avgSpeed + " ";

}

function db_getImgSize(localFile) {
	//d("in getImgSize");
	
	// xxx Test if image is still in filesystem and display a "file not found" if it isn't
	
	var aImage = new Image();
	aImage.onload = function() {
		db_resizeShowImg(aImage.width, aImage.height, localFile);
	}
	aImage.src = "file://" + localFile.path;

}

function db_resizeShowImg(width, height, localFile) {
	//d("in resizeShowImg");

	//d(width + " x " + height);
	var newHeight = 100;
	var newWidth = 100;
	
	if(width>height) {
		ratio = width / 100;
		newHeight = parseInt(height / ratio);
	//	d(newHeight);
		
	}
	if(height>width) {
		ratio = height / 100;
		newWidth = parseInt(width / ratio);
	//	d(newWidth);
		
	}
	
	document.getElementById("db_finTipImgPreview").setAttribute("width", newWidth);
	document.getElementById("db_finTipImgPreview").setAttribute("height", newHeight);
	
	document.getElementById("db_finTipImgPreview").setAttribute("src", "file://" + localFile.path);
	
}

function db_closeFinTip() {
	//d("in closeFinTip");
	document.getElementById("db_finTipImgPreview").setAttribute("src", "");
	document.getElementById("db_finTipImgPreviewBox").hidden = true;
	document.getElementById("db_finTipIcon").setAttribute("src", "");
	
}

// Intercept the tooltip and show my fancy tooltip (placed at the correct corner) instead
function db_redirectTooltip(elem) {

	// Find base download element
    var popupAnchor = elem;
    while(!popupAnchor.id) {
		popupAnchor = popupAnchor.parentNode;
	}

	var dlstate = popupAnchor.getAttribute("state");
	if(dlstate == 1 | dlstate == 2 | dlstate == 3 | dlstate == 6 | dlstate == 7| dlstate == 8)
    	document.getElementById("db_finTip").showPopup(popupAnchor,  -1, -1, 'popup', 'topleft' , 'bottomleft');

    if(dlstate == 0 | dlstate == 4 | dlstate == 5)
    	document.getElementById("db_progTip").showPopup(popupAnchor,  -1, -1, 'popup', 'topleft' , 'bottomleft');

    // holds a ref to this anchor node so we can remove the onmouseout later
    db_currTooltipAnchor = popupAnchor;
    //document.popupNode = popupAnchor;
    
    // xxx In linux, a mouseout event is sent right away and the popup never shows, delay to avoid that
    // unless I can get rid of the special case below "if(!relTarget && (db_currTooltipAnchor.id == expOriTarget.id)) {"
    window.setTimeout(function(){
    	popupAnchor.setAttribute("onmouseout", "db_hideRedirPopup(event);");
    }, 50);
	
    return false;  // don't show the default tooltip

}

function db_hideRedirPopup(aEvent) {
	
	//d("in hideRedir");
	//d("tooltipanchor " + db_currTooltipAnchor.id);
	try {
		if(aEvent) {
	/*		
		try {
			var target = aEvent.target;
		    while(!target.id) {
				target = target.parentNode;
			}
			d('      tar - ' + aEvent.target.id + " : " + target.id);	
		} catch(e){}
	*/		
		try {
			var relTarget = aEvent.relatedTarget;
			// Find a parent node with an id so that I know which element I'm on
		    while(!relTarget.id) {
				relTarget = relTarget.parentNode;
			}
			//d('   reltar - ' + aEvent.relatedTarget.id + " : " + relTarget.id);	
		} catch(e){
			//d('errorinreltarget');
		}
	/*		
		try {	
			var currtarget = aEvent.currentTarget;
		    while(!currtarget.id) {
				currtarget = currtarget.parentNode;
			}
			d('  currtar - ' + aEvent.currentTarget.id + " : " + currtarget.id);
		} catch(e){}		
		
		try {
			var oritarget = aEvent.originalTarget;
		    while(!oritarget.id) {
				oritarget = oritarget.parentNode;
			}
			d('   oritar - ' + aEvent.originalTarget.id + " : " + oritarget.id);	
		} catch(e){}
	*/	
		try {
			var expOriTarget = aEvent.explicitOriginalTarget;
		    while(!expOriTarget.id) {
				expOriTarget = expOriTarget.parentNode;
			}
			//d('expOritar - ' + aEvent.explicitOriginalTarget.id + " : " + expOriTarget.id);		
		} catch(e){}
		
		
		// These event targets are quirky - basically I want to not close the tooltip if I'm on another part of the same download element, 
		// or if I mouse up onto the popup
		try {
			var matchTarget;
			if(relTarget)
				matchTarget = relTarget.id;
			else
				matchTarget = expOriTarget.id;

			//d('matchingto: ' + matchTarget);
			//d(" ");
			// Allow cursor to go up on the tooltip and not close, Note: transparent tooltip background images have a 2px transparent
				// bottom so that the cursor can move directly between DL elem and tooltip
				// Opaque tooltips are flush with the dl element
			if(matchTarget.substring(0,9) == "db_finTip" | matchTarget.substring(0,10) == "db_progTip")
				return;	

			// xxx Can i do this in a differnet way so that linux works correctly?	without needing the timeout at the end of db_redirectTooltip()
			// Sometimes events don't work right, this is a special case where it messes up
			// This needs to be before the next if statement
			if(!relTarget && (db_currTooltipAnchor.id == expOriTarget.id)) {
				document.getElementById("db_finTip").hidePopup();
   				document.getElementById("db_progTip").hidePopup();
   				return;
			}
		
			// we are still on the same elem
			if(db_currTooltipAnchor.id == matchTarget)
				return;	
			
		} catch(e){}
		}
		
	} catch(e) {
		//d("error in hideredir");
	}
	
	// If there was no proper event, hide the popup by default anyway
	document.getElementById("db_finTip").hidePopup();
   	document.getElementById("db_progTip").hidePopup();
}

function db_mouseOutPopup(aEvent) {

	// need to close the popup if the mouse goes outside the popup

/*	
	try {
		var target = aEvent.target;
	    while(!target.id) {
			target = target.parentNode;
		}
		d('     popup tar - ' + aEvent.target.id + " : " + target.id);	
	} catch(e){}
*/		
	try {
		var relTarget = aEvent.relatedTarget;
	    while(!relTarget.id) {
			relTarget = relTarget.parentNode;
		}
		//d('  popup reltar - ' + aEvent.relatedTarget.id + " : " + relTarget.id);	
	} catch(e){
		//d('errorinreltarget');
	}
/*
	try {	
		var currtarget = aEvent.currentTarget;
	    while(!currtarget.id) {
			currtarget = currtarget.parentNode;
		}
		d(' popup currtar - ' + aEvent.currentTarget.id + " : " + currtarget.id);
	} catch(e){}		
	
	try {
		var oritarget = aEvent.originalTarget;
	    while(!oritarget.id) {
			oritarget = oritarget.parentNode;
		}
		d('  popup oritar - ' + aEvent.originalTarget.id + " : " + oritarget.id);	
	} catch(e){}
	
	try {
		var expOriTarget = aEvent.explicitOriginalTarget;
	    while(!expOriTarget.id) {
			expOriTarget = expOriTarget.parentNode;
		}
		d('popup expOritar - ' + aEvent.explicitOriginalTarget.id + " : " + expOriTarget.id);		
	} catch(e){}

	d(' ');
*/	
	// These rules are weird I know... there are all kinda of quirky things here
	// I just had to study they outputs of each target type and find something that 
	// works when I want to close it and doesn't close when I don't want it to. 
	try {
		if(!relTarget && (aEvent.explicitOriginalTarget.id == "")) {
			return;
		}
		
		if(relTarget.id.substring(0,9) == "db_finTip" | relTarget.id.substring(0,10) == "db_progTip") {
			return;
		}
			
	} catch(e) {}
	
	document.getElementById("db_finTip").hidePopup();
   	document.getElementById("db_progTip").hidePopup();
}

function db_convertToMB(size) {
	size = size/1024;
	size = Math.round(size*100)/100;  // two decimal points
	return size;
}

function db_formatSeconds(secs) {
// Round the number of seconds to remove fractions.
	secs = parseInt( secs + .5 );
	var hours = parseInt( secs/3600 );
	secs -= hours*3600;
	var mins = parseInt( secs/60 );
	secs -= mins*60;
	var result;

    if ( mins < 10 )
        mins = "0" + mins;
    if ( secs < 10 )
        secs = "0" + secs;

    if (hours) {
    	if ( hours < 10 ) hours = "0" + hours;
    	result = hours + ":" + mins + ":" + secs;
	}
	else result = mins + ":" + secs;

    return result;
}

function db_readPrefs() {
	// Get and save display prefs
	try {
		var percentDisp = db_pref.getBoolPref("downbar.display.percent");
		var speedDisp = db_pref.getBoolPref("downbar.display.speed");
		var sizeDisp = db_pref.getBoolPref("downbar.display.size");
		var timeDisp = db_pref.getBoolPref("downbar.display.time");
	} catch (e){}

	var dlTemplate = document.getElementById("db_downloadTemplate");
	// set which progress notifications are set to display on the download element template
	dlTemplate.lastChild.lastChild.firstChild.hidden = !percentDisp;
	dlTemplate.lastChild.lastChild.firstChild.nextSibling.hidden = !speedDisp;
	dlTemplate.lastChild.lastChild.lastChild.previousSibling.hidden = !sizeDisp;
	dlTemplate.lastChild.lastChild.lastChild.hidden = !timeDisp;

	// Get the anti-virus filetype exclude list and num for queue
	try {
		var excludeRaw = db_pref.getCharPref("downbar.function.virusExclude");
		excludeRaw = excludeRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		db_excludeList = excludeRaw.split(",");
		//db_queueNum = db_pref.getIntPref("downbar.function.queueNum");
	} catch(e){}

	// Get autoClear and ignore filetypes
	try {
		var clearRaw = db_pref.getCharPref("downbar.function.clearFiletypes");
		clearRaw = clearRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		db_clearList = clearRaw.split(",");

		var ignoreRaw = db_pref.getCharPref("downbar.function.ignoreFiletypes");
		ignoreRaw = ignoreRaw.toLowerCase().replace(/\s/g,'');  // remove all whitespace
		db_ignoreList = ignoreRaw.split(",");
	} catch(e){}

	//Get SpeedColor settings
	try{
		db_speedColorsEnabled = db_pref.getBoolPref("downbar.style.speedColorsEnabled");
		if(db_speedColorsEnabled) {
			var speedRaw0 = db_pref.getCharPref("downbar.style.speedColor0");
			db_speedColor0 = speedRaw0.split(";")[1];
			// no division necessary should always be 0
			var speedRaw1 = db_pref.getCharPref("downbar.style.speedColor1");
			db_speedDivision1 = speedRaw1.split(";")[0];
			db_speedColor1 = speedRaw1.split(";")[1];
			var speedRaw2 = db_pref.getCharPref("downbar.style.speedColor2");
			db_speedDivision2 = speedRaw2.split(";")[0];
			db_speedColor2 = speedRaw2.split(";")[1];
			var speedRaw3 = db_pref.getCharPref("downbar.style.speedColor3");
			db_speedDivision3 = speedRaw3.split(";")[0];
			db_speedColor3 = speedRaw3.split(";")[1];
		}
	} catch(e){}

	// Open dlmgr onclose settings
	// If I'm launching the download manager with in-prog downloads onclose, then the download manager doesn't need to ask the cancel or exit prompt, so remove that observer from the download manager
	var db_observerService = Components.classes["@mozilla.org/observer-service;1"]
	                                  .getService(Components.interfaces.nsIObserverService);
	// first remove the observer to avoid adding duplicate observers
	try{
		db_observerService.removeObserver(db_gDownloadManager, "quit-application-requested");
	} catch(e){}
	try{
		var launchDLWin = db_pref.getBoolPref("downbar.function.launchOnClose");
	} catch(e){}
	// Add back the download manager observer if we don't want to control onclose downloads
	if(!launchDLWin)
		 db_observerService.addObserver(db_gDownloadManager, "quit-application-requested", false);
	// Animation setting
	try{
		db_useAnimation = db_pref.getBoolPref("downbar.function.useAnimation");
	} catch(e){}
	// Color Gradients Setting
	try{
		db_useGradients = db_pref.getBoolPref("downbar.style.useGradients");
	} catch(e){}
	try {
		db_miniMode = db_pref.getBoolPref("downbar.function.miniMode");
	} catch(e){}
}

function db_finishedClickHandle(aElem, aEvent) {

	if(aEvent.button == 0 && aEvent.shiftKey)
		db_renameFinished(aElem.id);

	if(aEvent.button == 1) {
		// Hide the tooltip if present, otherwise it shifts to top left corner of the screen
		document.getElementById("db_finTip").hidePopup();
		
		if(aEvent.ctrlKey)
			db_startDelete(aElem.id, aEvent);
		else
			db_animateDecide(aElem.id, "clear", aEvent);
	}
	
	if(aEvent.button == 2) {
		// Hide the tooltip if present, otherwise both right-click menu and tooltip will disappear together
		document.getElementById("db_finTip").hidePopup();
	}
	
}

function db_progressClickHandle(aElem, aEvent) {
	
	var state = aElem.getAttribute("state");

	if(aEvent.button == 0) {  // left click
		if(state == 0 | state == 5) {
			db_pause(aElem.id); 
		}
			
		if(state == 4) {
			db_resume(aElem.id);
		}
	}
		
	if(aEvent.button == 1) {  // middle click
		
		// Hide the tooltip if present, otherwise it shifts to top left corner of the screen
   		document.getElementById("db_progTip").hidePopup();
		db_cancelprogress(aElem.id);
	}
	
	if(aEvent.button == 2) {
		// Hide the tooltip if present, otherwise both right-click menu and tooltip will disappear together
   		document.getElementById("db_progTip").hidePopup();
	}
	
}

function db_clearButtonClick(aEvent) {
	
	if(aEvent.button == 0) {  // left click
		db_clearAll();
	}
	
	if(aEvent.button == 1) {  // middle click
		db_undoClear();
	}
	
	if(aEvent.button == 2) {  // right click
	  // do nothing	
	}
	
}

var db_aPromptObj = {value:""};

function db_renameFinished(elemid) {

	var dlElem = document.getElementById(elemid);
	
	var rename = db_strings.getString("rename");
	var to = db_strings.getString("to");
	var promptTitle = db_strings.getString("renameTitle");
	
	var oldfilename = dlElem.getAttribute("name");
	var ext = "";
	var oldArray = oldfilename.split(".");
	if(oldArray.length > 1)
		ext = oldArray.pop();
	var oldname = oldArray.join(".");
	if(ext != "")
		ext = "." + ext;

	var promptText = rename + "\n" + oldname + "\n" + to;
	db_aPromptObj.value = oldname;
	var ps = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
	var nameChanged = ps.prompt(window, promptTitle, promptText, db_aPromptObj, null, {value: null});

	if(nameChanged) {
		var file = db_getLocalFileFromNativePathOrUrl(dlElem.getAttribute("target"));
		var newfilename = db_aPromptObj.value + ext;
		if(oldfilename == newfilename)
			return;
			
		// Check if the filename already exists	
		var newFile = file.parent;
		newFile.append(newfilename);
		if(newFile.exists()) {
			// ask to replace or cancel instead? or go back to rename prompt?
			var promptSer = Components.classes["@mozilla.org/embedcomp/prompt-service;1"].getService(Components.interfaces.nsIPromptService);
			promptSer.alert(null, "Download Statusbar", db_strings.getString("fileExists"));
			return;
		}
			
		try {
			file.moveTo(null, newfilename);
		} catch(e) {
			// File not found
			var browserStrings = document.getElementById("bundle_browser");
			document.getElementById("statusbar-display").label = db_strings.getString("fileNotFound");
    		window.setTimeout(function(){document.getElementById("statusbar-display").label = browserStrings.getString("nv_done");}, 3000);
			return;
		}
		
		try {
			// Fix the database
			// Convert filepath to its URI representation as it is stored in the database
			var nsIIOService = Components.classes['@mozilla.org/network/io-service;1'].getService(Components.interfaces.nsIIOService);
			var fileURI = nsIIOService.newFileURI(newFile,null,null).spec;
			
			var dbase = db_gDownloadManager.DBConnection;
			dbase.executeSimpleSQL("UPDATE moz_downloads SET name='" + newfilename + "' WHERE id=" + elemid.substring(3));
			dbase.executeSimpleSQL("UPDATE moz_downloads SET target='" + fileURI + "' WHERE id=" + elemid.substring(3));
		} catch(e) {}
		
		// Change the download item data in all windows
		var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
		var e = wm.getEnumerator("navigator:browser");
		var win, winElem;

		while (e.hasMoreElements()) {
			win = e.getNext();
			winElem = win.document.getElementById(elemid);

			winElem.setAttribute("name", newfilename);
			winElem.setAttribute("target", fileURI);
			winElem.lastChild.firstChild.nextSibling.value = newfilename;
		}
		
		// make the filename text bold for 2 sec - this way works for both default and custom styles
		var origStyle = dlElem.lastChild.getAttribute("style");
		var tempStyle = origStyle + "font-weight:bold;";

		dlElem.lastChild.firstChild.nextSibling.setAttribute("style", tempStyle);
		window.setTimeout(function(){
			dlElem.lastChild.firstChild.nextSibling.setAttribute("style", origStyle);
		}, 2000);
	}
}

// xxx still needed?
function db_toggleDownbar() {

	var downbarHoldElem = document.getElementById("downbarHolder");
	if (downbarHoldElem.hidden) {
		downbarHoldElem.hidden = false;
		db_checkShouldShow();
	}
	else
		downbarHoldElem.hidden = true;
}

function db_checkMiniMode() {

	var currDownbar = document.getElementById("downbar").localName;
	var downbarHolder = document.getElementById("downbarHolder");

	if(db_miniMode) {

		if(currDownbar == "hbox") { // convert to miniMode
			
			document.getElementById("downbar").id = "downbarHboxTemp";
			document.getElementById("downbarPopupTemp").id = "downbar";
			
			// Remove all current downloads if any
			var oldDownbar = document.getElementById("downbarHboxTemp");
			while (oldDownbar.firstChild) {
		    	oldDownbar.removeChild(oldDownbar.firstChild);
		 	}

			downbarHolder.hidden = true;
			document.getElementById("downbarMini").collapsed = false;

		}
		document.getElementById("changeModeContext").label = db_strings.getString("toFullMode");
		document.getElementById("changeModeContext2").label = db_strings.getString("toFullMode");
	}
	else {
		if(currDownbar == "vbox") { // convert to fullMode
			document.getElementById("downbar").id = "downbarPopupTemp";
			document.getElementById("downbarHboxTemp").id = "downbar";
			
			// Remove all current downloads if any
			var oldDownbar = document.getElementById("downbarPopupTemp");
			while (oldDownbar.firstChild) {
		    	oldDownbar.removeChild(oldDownbar.firstChild);
		 	}
			
			document.getElementById("downbarMini").collapsed = true;
			downbarHolder.hidden = false;
		}
		document.getElementById("changeModeContext").label = db_strings.getString("toMiniMode");
		document.getElementById("changeModeContext2").label = db_strings.getString("toMiniMode");
	}
}

function db_startUpdateMini() {

	window.setTimeout(function(){db_updateMini();}, 444);

}

function db_updateMini() {
	
	try {
		var activeDownloads = db_gDownloadManager.activeDownloadCount;
		var dbelems = document.getElementById("downbar").childNodes;
		var finishedDownloads = dbelems.length - activeDownloads;
		document.getElementById("downbarMiniText").value = activeDownloads + ":" + finishedDownloads;
		//downbarMini:  Collapsed if it isn't being used, hidden if it is being used but there is nothing in it
		if(activeDownloads + finishedDownloads == 0)
			document.getElementById("downbarMini").hidden = true;
		else
			document.getElementById("downbarMini").hidden = false;
		
	} catch(e){}
}

function db_showMiniPopup(miniElem, event) {

	if(event.button == 1)
		db_modeToggle();

	if(event.button == 0)
		document.getElementById("downbarPopup").showPopup(miniElem,  -1, -1, 'popup', 'topright' , 'bottomright');

	var dbelems = document.getElementById("downbar").childNodes;
	for (var i = 1; i <= dbelems.length - 1; ++i) {
		contextAttr = dbelems[i].getAttribute("context");
		if (contextAttr == "progresscontext") {
			window.clearTimeout(dbelems[i].pTimeout);
			db_updateDLrepeat(dbelems[i].id);
		}
	}
}

function db_modeToggle() {

	db_pref.setBoolPref("downbar.function.miniMode", !db_miniMode);
	db_miniMode = !db_miniMode;

	db_checkMiniMode();
	db_populateDownloads();
	db_updateMini();
}

function db_showMainPopup(buttonElem, event) {

	if(event.button == 0)
		document.getElementById("db_mainButtonMenu").showPopup(buttonElem,  -1, -1, 'popup', 'topleft' , 'bottomleft');

}

// This is in case a new window is opened while a download is already in progress - need to start the update repeat
function db_startInProgress() {

	var dbelems = document.getElementById("downbar").childNodes;
	for (var i = 0; i <= dbelems.length - 1; ++i) {
		state = dbelems[i].getAttribute("state");
		if (state == 0 | state == 5 | state == 4) {   // in progress, queued, or paused
				db_updateDLrepeat(dbelems[i].id);
		}
	}
}

function db_checkHideMiniPopup() {
	
	// This function will prevent an empty mini mode popup from showing after all the downloads are cleared
	// This is called from onDOMNodeRemoved from the mini mode, it executes before the element is actually gone, so check if there is 1 left
	if(document.getElementById('downbar').childNodes.length == 1) 
		db_hideDownbarPopup();
}

function db_hideDownbarPopup() {
	try {
		// This is only for the miniDownbar - prevents the downbar popup from getting stuck after using the context menu on an item
		// gets called from the onpopuphidden of each download item context menu
		document.getElementById("downbarPopup").hidePopup();
	} catch(e){}
}

// this function and following comments from firefox 1.0.4 download manager
// we should be using real URLs all the time, but until
// bug 239948 is fully fixed, this will do...
function db_getLocalFileFromNativePathOrUrl(aPathOrUrl) {
  if (aPathOrUrl.substring(0,7) == "file://") {

    // if this is a URL, get the file from that
    ioSvc = Components.classes["@mozilla.org/network/io-service;1"]
      .getService(Components.interfaces.nsIIOService);

    // XXX it's possible that using a null char-set here is bad
    const fileUrl = ioSvc.newURI(aPathOrUrl, null, null).
      QueryInterface(Components.interfaces.nsIFileURL);
    return fileUrl.file.clone().
      QueryInterface(Components.interfaces.nsILocalFile);

  } else {

    // if it's a pathname, create the nsILocalFile directly
    f = Components.classes["@mozilla.org/file/local;1"].
      createInstance(Components.interfaces.nsILocalFile);
    f.initWithPath(aPathOrUrl);

    return f;
  }
}

// This function from firefox 1.5beta2
function db_openExternal(aFile)
{
  var uri = Components.classes["@mozilla.org/network/io-service;1"]
                      .getService(Components.interfaces.nsIIOService)
                      .newFileURI(aFile);

  var protocolSvc =
      Components.classes["@mozilla.org/uriloader/external-protocol-service;1"]
                .getService(Components.interfaces.nsIExternalProtocolService);

  protocolSvc.loadUrl(uri);

  return;
}

function db_openDownloadWindow() {
    
    var wm = Components.classes["@mozilla.org/appshell/window-mediator;1"].getService(Components.interfaces.nsIWindowMediator);
    
	var dlwin = wm.getMostRecentWindow("Download:Manager");
    if(dlwin)
            var dlwinExists = true;
        else
            var dlwinExists = false;
    if(!dlwinExists)
		window.open('chrome://mozapps/content/downloads/downloads.xul', '', 'chrome');
	else
		dlwin.focus();
}


function db_showSampleDownload() {
	
	var dbase = db_gDownloadManager.DBConnection;
	
	// Set the most recent download to show
	try {
		dbase.executeSimpleSQL("UPDATE moz_downloads SET DownbarShow=1 WHERE id IN (SELECT id FROM moz_downloads WHERE state=1 ORDER BY id DESC LIMIT 1)");
	} catch(e) {}
}

var db_privateBrowsingObs = {
  observe: function db_observe(aSubject, aTopic, aData) {
    switch (aTopic) {
      case "private-browsing":
        if (aData == "enter" || aData == "exit") {
         
          // Upon switching to/from private browsing, the download manager backend 
          // switches databases (nsDownloadManager.cpp) - switch is transparent to us  
          // but need to repopulate the download statusbar using the new database
          
           // Warning from built-in downloads.js:
          // "We might get this notification before the download manager
          // service, so the new database connection might not be ready
          // yet.  Defer this until all private-browsing notifications
          // have been processed."

          setTimeout(function() {
            db_populateDownloads();
			db_startInProgress();
			db_checkShouldShow();
          }, 0);
        }
        break;
    }
  }
};

/*
// Supposed to be the *new* API to drag and drop but it's still crap...
function db_startDLElemDrag(aElem, event) {

	d('here startDLELEMDRAG');
	var aElem = event.target;
		
	// need the base DL elem, go up to find it, it is the first with an id
	while(!aElem.id) {
		aElem = aElem.parentNode;
	}
	
	var fileUrl = aElem.getAttribute("target");
	d("url: " + fileUrl);
	var localFile = db_getLocalFileFromNativePathOrUrl(fileUrl);
	if (!localFile.exists()) 
		return;

	var dataT = event.dataTransfer;
	dataT.mozSetDataAt("application/x-moz-file", localFile, 0);
	dataT.effectAllowed = "copyMove";

	
	
	
	var mimeServ = Components.classes["@mozilla.org/mime;1"].getService(Components.interfaces.nsIMIMEService);
	var contentType = mimeServ.getTypeFromFile(localFile);
	d("cont: " + contentType);
	d("leaf: " + encodeURIComponent(localFile.leafName));

	var info = fileUrl + "&type=" + contentType + "&filename=" + encodeURIComponent(localFile.leafName);
	var localFile = db_getLocalFileFromNativePathOrUrl(aElem.getAttribute("target"));


	// xxx check that file exists before proceeding
	event.dataTransfer.mozSetDataAt("application/x-moz-file-promise", new db_nsFlavorDataProvider(), 0);
	event.dataTransfer.mozSetDataAt("application/x-moz-file-promise-url", fileUrl, 1);
	event.dataTransfer.mozSetDataAt("text/x-moz-url", info + "\n" + localFile.leafName, 2);
	event.dataTransfer.mozSetDataAt("text/x-moz-url-data", fileUrl, 3);
	event.dataTransfer.mozSetDataAt("text/x-moz-url-desc", localFile.leafName, 4);

	var iconImage = aElem.lastChild.firstChild.firstChild;
	event.dataTransfer.setDragImage(iconImage, 8, 16);
	
	event.dataTransfer.effectAllowed = "move";

	d('end of startDLELEM');
}
*/

// Trying to get the destination directory, but it doesn't work like it does in thunderbird from the flavordataprovider
/*
function db_endDLElemDrag(aElem, event) {
	
	d('inenddrag');
	d(event.dataTransfer);
	var dirPrimitive = {};
	var dataSize = {};
    var dir = event.dataTransfer.getData("application/x-moz-file-promise-dir");
    //var destDirectory = dirPrimitive.value.QueryInterface(Components.interfaces.nsILocalFile);
	d("dir: " + event.dataTransfer.types.item(0));

}
*/
/*
// Drag and drop TO the filesystem, Don't understand why this has to be so complicated.  
// Modeled after the thunderbird drag and drop of email attachments.  
// See msgHdrViewOverlay.js, but it doesn't work quite the same way
// This is a mess because mozilla doesn't support this properly...  flavordataprovider is not actually used 
// This will copy a file, not move it - asking it to move still copies
var db_dragDropObserver = {

	onDragStart: function (event, transferData, aDragAction) {

		//d('here');
		//d(event.dataTransfer);
		var aElem = event.target;
		
		// need the base DL elem, go up to find it, it is the first with an id
		while(!aElem.id) {
			aElem = aElem.parentNode;
		}
		
		var fileUrl = aElem.getAttribute("target");
		//d("url: " + fileUrl);
		var localFile = db_getLocalFileFromNativePathOrUrl(fileUrl);
		
		var mimeServ = Components.classes["@mozilla.org/mime;1"].getService(Components.interfaces.nsIMIMEService);
		var contentType = mimeServ.getTypeFromFile(localFile);
		//d("cont: " + contentType);
		//d("leaf: " + encodeURIComponent(localFile.leafName));
		
		
		var data = new TransferData();

		var info = fileUrl + "&type=" + contentType + "&filename=" + encodeURIComponent(localFile.leafName);
		//d("info: " + info);
		
		data.addDataForFlavour("text/x-moz-url", info + "\n" + localFile.leafName);
		//data.addDataForFlavour("text/x-moz-url", encodeURIComponent(localFile.path);
		//data.addDataForFlavour("text/x-moz-url-data", fileUrl);
		//data.addDataForFlavour("text/x-moz-url-desc", localFile.leafName);
		//data.addDataForFlavour("text/plain", localFile.path);
		data.addDataForFlavour("application/x-moz-file-promise-url", fileUrl);
		//data.addDataForFlavour("application/x-moz-file-promise", new db_nsFlavorDataProvider(), 0, Components.interfaces.nsISupports);
		
		// xxx This is stupid - it doesn't actually use the flavorDataProvider, but this flavor is still necessary, though it has bogus contents
		data.addDataForFlavour("application/x-moz-file-promise", "a");
		transferData.data = data;
		
		// This doesn't appear to do what it should - file gets copied
		aDragAction.action = Components.interfaces.nsIDragService.DRAGDROP_ACTION_MOVE;
		//event.dataTransfer.effectAllowed = "move";
		//d('got here');
				
	// need to remove file from bar after it is moved by dragging 
	//  or change the database if I could get the drag location (but I can't)
	//  but for now it is actually just copying the file, do nothing
	}

};
*/
/*
// Thunderbird uses this, but for some reason it is never actually called here
function db_nsFlavorDataProvider()
{
}

db_nsFlavorDataProvider.prototype =
{
  QueryInterface : function(iid)
  {
  
      if (iid.equals(Components.interfaces.nsIFlavorDataProvider) ||
          iid.equals(Components.interfaces.nsISupports))
        return this;
      throw Components.results.NS_NOINTERFACE;
  },

  getFlavorData : function(aTransferable, aFlavor, aData, aDataLen)
  {
alert('here3');	
    // get the url for the attachment
    if (aFlavor == "application/x-moz-file-promise")
    {
      var urlPrimitive = { };
      var dataSize = { };
      aTransferable.getTransferData("application/x-moz-file-promise-url", urlPrimitive, dataSize);

      var srcUrlPrimitive = urlPrimitive.value.QueryInterface(Components.interfaces.nsISupportsString);

      // now get the destination file location from kFilePromiseDirectoryMime
      var dirPrimitive = {};
      aTransferable.getTransferData("application/x-moz-file-promise-dir", dirPrimitive, dataSize);
      var destDirectory = dirPrimitive.value.QueryInterface(Components.interfaces.nsILocalFile);
d(destDirectory);
      // now save the attachment to the specified location
      // XXX: we need more information than just the attachment url to save it, fortunately, we have an array
      // of all the current attachments so we can cheat and scan through them

      var attachment = null;
      for (index in currentAttachments)
      {
        attachment = currentAttachments[index];
        if (attachment.url == srcUrlPrimitive)
          break;
      }

      // call our code for saving attachments
      if (attachment)
      {
        var destFilePath = messenger.saveAttachmentToFolder(attachment.contentType, attachment.url, encodeURIComponent(attachment.displayName), attachment.uri, destDirectory);
        aData.value = destFilePath.QueryInterface(Components.interfaces.nsISupports);
        aDataLen.value = 4;
      }
	  
    }
  }

};
*/

/*
// Dump a message to Javascript Console
function d(msg){
	var acs = Components.classes["@mozilla.org/consoleservice;1"].getService(Components.interfaces.nsIConsoleService);
	acs.logStringMessage(msg);
}*/