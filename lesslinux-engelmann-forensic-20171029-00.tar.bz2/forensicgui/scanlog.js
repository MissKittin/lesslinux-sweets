		
		function jsinit() {
			var showcomp = document.getElementById('showcomp');
			showcomp.onclick = showcompbox; 
			var hidecomp = document.getElementById('hidecomp');
			hidecomp.onclick = hidecompbox; 
			var showavira = document.getElementById('showavira');
			showavira.onclick = showavirabox; 
			var hideavira = document.getElementById('hideavira');
			hideavira.onclick = hideavirabox; 
		}
		function showcompbox() {
			compbox = document.getElementById('dmipre');
			compbox.style.setProperty("display", "block", null);
			showcomp = document.getElementById('showcomp');
			showcomp.style.setProperty("display", "none", null);
			hidecomp = document.getElementById('hidecomp');
			hidecomp.style.setProperty("display", "block", null);
			return false;
		}
		function hidecompbox() {
			compbox = document.getElementById('dmipre');
			compbox.style.setProperty("display", "none", null);
			showcomp = document.getElementById('showcomp');
			showcomp.style.setProperty("display", "block", null);
			hidecomp = document.getElementById('hidecomp');
			hidecomp.style.setProperty("display", "none", null);
			return false;
		}
		function showavirabox() {
			compbox = document.getElementById('avrpre');
			compbox.style.setProperty("display", "block", null);
			showcomp = document.getElementById('showavira');
			showcomp.style.setProperty("display", "none", null);
			hidecomp = document.getElementById('hideavira');
			hidecomp.style.setProperty("display", "block", null);
			return false;
		}
		function hideavirabox() {
			compbox = document.getElementById('avrpre');
			compbox.style.setProperty("display", "none", null);
			showcomp = document.getElementById('showavira');
			showcomp.style.setProperty("display", "block", null);
			hidecomp = document.getElementById('hideavira');
			hidecomp.style.setProperty("display", "none", null);
			return false;
		}
		function showsmart(drive) {
			var parent = document.getElementById('smart-' + drive);
			var box = parent.getElementsByClassName("smartinfo")[0];
			var showlink = document.getElementById('showsmart-' + drive);
			var hidelink = document.getElementById('hidesmart-' + drive);
			box.style.setProperty("display", "block", null);
			hidelink.style.setProperty("display", "block", null);
			showlink.style.setProperty("display", "none", null);
			try {
				var err = parent.getElementsByClassName("smarterror")[0];
				err.style.setProperty("display", "block", null);
			} catch(e) {
				/* Do nothing */
			}
			return false;
		}
		function hidesmart(drive) {
			var parent = document.getElementById('smart-' + drive);
			var box = parent.getElementsByClassName("smartinfo")[0];
			var showlink = document.getElementById('showsmart-' + drive);
			var hidelink = document.getElementById('hidesmart-' + drive);
			box.style.setProperty("display", "none", null);
			hidelink.style.setProperty("display", "none", null);
			showlink.style.setProperty("display", "block", null);
			try {
				var err = parent.getElementsByClassName("smarterror")[0];
				err.style.setProperty("display", "none", null);
			} catch(e) {
				/* Do nothing */
			}
			return false;
		}
		