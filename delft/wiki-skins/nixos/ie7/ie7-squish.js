/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
IE7.addModule("ie7-squish", function() {

/* ---------------------------------------------------------------------

  Squish some IE bugs!

  Some of these bug fixes may have adverse effects so they are
  not included in the standard library. Add your own if you want.

  -dean

--------------------------------------------------------------------- */

// @NOTE: ie7Layout.boxSizing is the same as the "Holly Hack"

// "doubled margin" bug
// http://www.positioniseverything.net/explorer/doubled-margin.html
ie7CSS.addFix(/float\s*:\s*(left|right)/, "display:inline;$1");

if (ie7Layout) {
	// "peekaboo" bug
	// http://www.positioniseverything.net/explorer/peekaboo.html
	if (appVersion >= 6) ie7CSS.addRecalc("float", "left|right", function($element) {
		ie7Layout.boxSizing($element.parentElement);
		// "doubled margin" bug
		$element.runtimeStyle.display = "inline";
	});

	// "unscrollable content" bug
	// http://www.positioniseverything.net/explorer/unscrollable.html
	ie7CSS.addRecalc("position", "absolute|fixed", function($element) {
		if ($element.offsetParent && $element.offsetParent.currentStyle.position == "relative")
			ie7Layout.boxSizing($element.offsetParent);
	});
}

//# // get rid of Microsoft's pesky image toolbar
//# if (!complete) document.write('<meta http-equiv="imagetoolbar" content="no">');

});
