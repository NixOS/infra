/*
	IE7, version 0.9 (alpha) (2005-08-19)
	Copyright: 2004-2005, Dean Edwards (http://dean.edwards.name/)
	License: http://creativecommons.org/licenses/LGPL/2.1/
*/
IE7.addModule("ie7-css-strict",function(){if(!modules["ie7-css2-selectors"])return;StyleSheet.prototype.specialize({parse:function(){this.inherit();var r=[].concat(this.rules);r.sort(ie7CSS.Rule.compare);this.cssText=r.join("\n")},createRule:function(s,c){var m;if(m=s.match(ie7CSS.PseudoElement.MATCH))return new ie7CSS.PseudoElement(m[1],m[2],c);else if(m=s.match(ie7CSS.DynamicRule.MATCH))return new ie7CSS.DynamicRule(s,m[1],m[2],m[3],c);else return new ie7CSS.Rule(s,c)}});ie7CSS.specialize({apply:function(){this.inherit();this.Rule.MATCH=/([^{}]+)(\{[^{}]*\})/g}});ie7CSS.Rule.compare=function(r1,r2){return r1.specificity-r2.specificity};var N=[],I=/#/g,C=/[.:\[]/g,T=/^\w|[\s>+~]\w/g;ie7CSS.Rule.score=function(s){return(s.match(I)||N).length*10000+(s.match(C)||N).length*100+(s.match(T)||N).length};ie7CSS.Rule.simple=function(){return""};ie7CSS.Rule.prototype.specialize({specificity:0,init:function(){this.specificity=ie7CSS.Rule.score(this.selector)}})});
