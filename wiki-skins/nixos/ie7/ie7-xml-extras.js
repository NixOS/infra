/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
function XMLHttpRequest(){var l=(ScriptEngineMajorVersion()>=5)?"Msxml2":"Microsoft";return new ActiveXObject(l+".XMLHTTP")};function DOMParser(){};DOMParser.prototype={toString:function(){return"[object DOMParser]"},parseFromString:function(s,c){var x=new ActiveXObject("Microsoft.XMLDOM");x.loadXML(s);return x},parseFromStream:new Function,baseURI:""};function XMLSerializer(){};XMLSerializer.prototype={toString:function(){return"[object XMLSerializer]"},serializeToString:function(r){return r.xml||r.outerHTML},serializeToStream:new Function};
