/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
IE7.addModule("ie7-dhtml", function() {

/* ---------------------------------------------------------------------
  This module is still in development and should not be used.
--------------------------------------------------------------------- */

ie7CSS.specialize("recalc", function() {
	this.inherit();
	for (var i = 0; i < this.recalcs.length; i++) {
		var $recalc = this.recalcs[i];
		for (var j = 0; i < $recalc[3].length; i++) {
			_addPropertyChangeHandler($recalc[3][j], _getPropertyName($recalc[2]), $recalc[1]);
		}
	}
});

// constants
var _PATTERNS = {
	width: "(width|paddingLeft|paddingRight|borderLeftWidth|borderRightWidth|borderLeftStyle|borderRightStyle)",
	height:	"(height|paddingTop|paddingBottom|borderTopHeight|borderBottomHeight|borderTopStyle|borderBottomStyle)"
};
var _PROPERTY_NAMES = {
	width: "fixedWidth",
	height: "fixedHeight",
	right: "width",
	bottom: "height"
};
var _DASH_LETTER = /-(\w)/g;
var _PROPERTY_NAME = /\w+/;

function _addPropertyChangeHandler($element, $propertyName, $fix) {
	addEventHandler($element, "onpropertychange", function() {
		if (_getPattern($propertyName).test(event.propertyName)) {
			_reset($element, $propertyName);
			$fix($element);
		}
	});
};
function _upper($match, $letter) {return $letter.toUpperCase()};
function _getPropertyName($pattern) {
	return String(String($pattern).toLowerCase().replace(_DASH_LETTER, _upper).match(_PROPERTY_NAME));
};
function _getPattern($propertyName) {
	return eval("/^style." + (_PATTERNS[$propertyName] || $propertyName) + "$/");
};
function _reset($element, $propertyName) {
	$element.runtimeStyle[$propertyName] = "";
	$propertyName = _PROPERTY_NAMES[$propertyName]
	if ($propertyName) $element.runtimeStyle[$propertyName] = "";
};

});
