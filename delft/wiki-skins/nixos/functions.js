
	var menuShowing = false;
	var currentMenu = "";
	var currentMenuParent = "";
	var coordX = 0;
	var coordY = 0;

	function newPage(pathname)
	{
		var newPageName =
			prompt("Enter the name for your new page. " +
				"Please avoid using punctuation:", "");
		if (newPageName == null || newPageName == "")
			return;
		else {
			path = new String(pathname);
			path = path.replace("$1", newPageName);
			document.location = path;
		}
	}

	function setMouseEvents(turnOnEvents)
	{
		if (turnOnEvents) {
			if (!is_ie)
				document.captureEvents(Event.MOUSEMOVE)
			document.onmousemove = getMouseXY;
		} else {
			if (!is_ie)
				document.releaseEvents(Event.MOUSEMOVE)
			document.onmousemove = "";
		}
	}

	function showMenu(menuID, parentID, alignment)
	{
		if (currentMenu == menuID)
			return;
		hideCurrentMenu();

		menuDiv = document.getElementById(menuID);
		menuParent = document.getElementById(parentID);
		menuDiv.style.display = "block";
		menuX = findPosX(menuParent);
		menuY = findPosY(menuParent);
		menuH = findHeight(menuParent);
		menuW = findWidth(menuDiv);
		parentW = findWidth(menuParent);
		if (alignment == "right")
			menuDiv.style.left = menuX - menuW + parentW + "px";
		else
			menuDiv.style.left = menuX + "px";
		if (menuID == "mainMenu")
			menuY++;
		menuDiv.style.top = menuY + menuH + "px";
		fader = new Fadomatic(menuDiv, 20, 0);
		fader.fadeIn();

		currentMenu = menuID;
		currentMenuParent = parentID;
		menuShowing = true;
		setMouseEvents(true);
	}

	function hideCurrentMenu()
	{
		if (menuShowing == false)
			return;
		hideMenu(currentMenu);
	}

	function hideMenu(menuID)
	{
		if (menuShowing == false)
			return;
		menuDiv = document.getElementById(menuID);
		fader = new Fadomatic(menuDiv, 20, 100);
		fader.fadeOut();
		menuShowing = false;
		currentMenu = "";
		currentMenuParent = "";
	}

	function getBodyHeight()
	{
		height = 0;
		if (typeof(window.innerWidth) == 'number') {
			height = window.innerHeight;
		} else if (window.document.body &&
		typeof(window.document.body.clientWidth) == 'number') {
			height = window.document.body.clientHeight;      
		}
		return height;
	}

	function adjustBody()
	{
		md = document.getElementById("middleDiv");
		w = findWidth(md);
               	if (w > 850)
                       	md.style.width = "850px";
	}

	function safariSearch()
	{
		if (is_safari) {
			searchField = document.getElementById("searchField");
			searchField.setAttribute('type','search');
		}
	}

	function resizeImgs()
	{
		maxWidth = 560;
		var bodyEl = document.getElementById("bodyDiv");
		var imgs = bodyEl.getElementsByTagName('img');
		for (var j = 0; j < imgs.length; j++) {
			el = imgs[j];
			w = el.getAttribute('width');
			h = el.getAttribute('height');
			if (w && w > maxWidth) {
				el.setAttribute('width', maxWidth);
				el.setAttribute('height', h * (maxWidth / w));
			}
		}
	}

	function newtabaction()
	{
		oldsecid = this.parentNode.parentNode.selectedid;
		newsec = document.getElementById(this.secid);
		if (oldsecid != this.secid) {
			ul = document.getElementById('preftoc');
			document.getElementById(oldsecid).style.display =
				'none';
			newsec.style.display = 'block';
			ul.selectedid = this.secid;
			lis = ul.getElementsByTagName('li');
			for (i = 0; i < lis.length; i++) {
				lis[i].className = '';
			}
			this.parentNode.className = 'selected';
		}
		adjustBody();
		return false;
	}

	function modifyTabPrefs()
	{
		prefform = document.getElementById('preferences');
		if (!prefform || !document.createElement) return;
		if (prefform.nodeName.toLowerCase() == 'a') return;
		lis = document.getElementsByTagName('li');
		for (i = 0; i < lis.length; i++) {
			ael = lis[i].childNodes[0];
			ael.onclick = newtabaction;
		}
	}

/*
	addEvent function found at
	http://www.scottandrew.com/weblog/articles/cbs-events
*/

	function addEvent(obj, evType, fn)
	{
		if (obj.addEventListener) {
			obj.addEventListener(evType, fn, true);
			return true;
		} else if (obj.attachEvent) {
			var r = obj.attachEvent("on"+evType, fn);
			return r;
		} else {
			return false;
		}
	}

	if (document.getElementById && document.createTextNode)
	{
		addEvent(window, 'load', safariSearch);
		addEvent(window, 'load', adjustBody);
		addEvent(window, 'load', resizeImgs);
		addEvent(window, 'load', modifyTabPrefs);
		addEvent(window, 'resize', adjustBody);
	}

	function findPosX(obj)
	{
	       	var curleft = 0;
		if (obj.offsetParent) {
			while (obj.offsetParent) {
				curleft += obj.offsetLeft;
				obj = obj.offsetParent;
			}
		} else if (obj.x)
			curleft += obj.x;
		return curleft;
	}

	function findPosY(obj)
	{
		var curtop = 0;
		if (obj.offsetParent) {
			while (obj.offsetParent) {
				curtop += obj.offsetTop;
				obj = obj.offsetParent;
			}
		} else if (obj.y)
			curtop += obj.y;
		return curtop;
	}

	function findHeight(obj)
	{
		if (obj.offsetHeight)
			return obj.offsetHeight;
		else if (obj.height)
			return obj.height;
		else if (obj.style.height)
			return obj.style.height;
	}

	function findWidth(obj)
	{
		if (obj.offsetWidth)
			return obj.offsetWidth;
		else if (obj.width)
			return obj.width;
		else if (obj.style.width)
			return obj.style.width;
	}

	function getMouseXY(e)
	{
		if (currentMenu == "")
			return;

		if (is_ie) {
			coordX = event.clientX + document.body.scrollLeft;
			coordY = event.clientY + document.body.scrollTop;
		} else {
			coordX = e.pageX;
			coordY = e.pageY;
		}  

		if (coordX < 0)
			coordX = 0;
		if (coordY < 0)
			coordY = 0;

		testMenuBounds(currentMenuParent, currentMenu, coordX, coordY);

		return true;
	}

	function testMenuBounds(testid, id, x, y)
	{
		menuDivParent = document.getElementById(testid);
		menuDiv = document.getElementById(id);

		menuY = findPosY(menuDiv);
		menuX = findPosX(menuDiv);
		menuH = findHeight(menuDiv);
		menuW = findWidth(menuDiv);

		menuPY = findPosY(menuDivParent);
		menuPX = findPosX(menuDivParent);
		menuPH = findHeight(menuDivParent);
		menuPW = findWidth(menuDivParent);

		$isInMenu = true;
		$isInParent = true;
		if (x < menuX || x > menuX + menuW ||
		y < menuY || y > menuY + menuH)
			$isInMenu = false;
		if (x < menuPX || x > menuPX + menuPW ||
		y < menuPY || y > menuPY + menuPH)
			$isInParent = false;

		if ($isInMenu == false && $isInParent == false)
			hideMenu(id);
	}
