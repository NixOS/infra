//
// JavaScript Browser Sniffer
// Eric Krok, Andy King, Michel Plungjan Jan. 31, 2002
// see http://www.webreference.com/ for more information
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
// please send any improvements to aking@internet.com and we'll
// roll the best ones in
//
// adapted from Netscape's Ultimate client-side JavaScript client sniffer
// and andy king's sniffer
// Revised May 7 99 to add is.nav5up and is.ie5up (see below). (see below).
// Revised June 11 99 to add additional props, checks
// Revised June 23 99 added screen props - gecko m6 doesn't support yet - abk
//		    converted to var is_ from is object to work everywhere
// 990624 - added cookie forms links frames checks - abk
// 001031 - ie4 mod 5.0 -> 5. (ie5.5 mididentified - abk)
//	  is_ie4 mod tp work with ie6+ - abk
// 001120 - ns6 released, document.layers false, put back in
//	- is_nav6 test added - abk
// 001121 - ns6+ added, used document.getElementById, better test, dom-compl
// 010117 - actual version for ie3-5.5 by Michel Plungjan
// 010118 - actual version for ns6 by Michel Plungjan
// 010217 - netscape 6/mz 6 ie5.5 onload defer bug docs - abk
// 011107 - added is_ie6 and is_ie6up variables - dmr
// 020128 - added link to netscape's sniffer, on which this is based - abk
//	  updated sniffer for aol4-6, ie5mac = js1.4, TVNavigator, AOLTV,
//	  hotjava
// 020131 - cleaned up links, added more links to example object detection
// 020131 - a couple small problems with Opera detection. First, when Opera
//	  is set to be compatible with other browsers it will contain their
//	  information in the userAgent strings. Thus, to be sure we have 
//	  Opera we should check for it before checking for the other bigs.
//	  (And make sure the others are !opera.) Also corrected a minor
//	  bug in the is_opera6up assignment.
// 020214 - Added link for Opera/JS compatibility; added improvements for 
//	  windows xp/2000 id in opera and aol 7 id (thanks to Les
//	  Hill, Les.Hill@getronics.com, for the suggestion).
// 020531 - Added N6/7 and moz identifiers. 
// 020605 - Added mozilla guessing, Netscape 7 identification, and cleaner
//	  identification for Netscape 6. (this comment added after code 
//	  changes)
// 020725 - Added is_gecko. -- dmr
// 021205 - Added is_Flash and is_FlashVersion, based on Doc JavaScript code. 
//	  Added Opera 7 variables. -- dmr
// 021209 - Added aol8. -- dmr
// 030110 - Added is_safari, added 1.5 js designation for Opera 7. --dmr
// 030128 - Added is_konq, per user suggestion (thanks to Sam Vilain).
//	  Removed duplicate Opera checks left over after last revision. - dmr
// 031124 - Added is_fb and version. We report this right after the is_moz
//	  report. - dmr
// 040325 - Added is_fx and version. We report this right after the is_moz
//	  report. - dmr
// 040421 - Added Debian check to is_moz. Thanks to Patrice Bridoux for
//	  reporting this.
// 040517 - Added is_fb/is_fx to plugins based flash detection. Thanks to 
//	  Martin Bischoff for pointing out this omission.
// 040617 - On Mac IE, appVersion differs from the version in the ua, 
//	  with the UA appearing to be more accurate. As an experiment, 
//	  for Mac we'll pull is_minor from the ua instead.
// 040831 - Fixed Opera bug in flash detection logic; when Opera has
//	  "enable plugins" unchecked in preferences, the "plugin" 
//	  variable is still true, but the "description" property 
//	  belonging to it is undefined.
//
// Everything you always wanted to know about your JavaScript client
// but were afraid to ask. Creates "is_" variables indicating:
// (1) browser vendor:
//     is_nav, is_ie, is_opera
// (2) browser version number:
//     is_major (integer indicating major version number: 2, 3, 4 ...)
//     is_minor (float   indicating full  version number: 2.02, 3.01, 4.04 ...)
// (3) browser vendor AND major version number
//     is_nav2, is_nav3, is_nav4, is_nav4up, is_nav5, is_nav5up, 
//     is_nav6, is_nav6up, is_ie3, is_ie4, is_ie4up, is_ie5up, is_ie6...
// (4) JavaScript version number:
//     is_js (float indicating full JavaScript version number: 1, 1.1, 1.2 ...)
// (5) OS platform and version:
//     is_win, is_win16, is_win32, is_win31, is_win95, is_winnt, is_win98
//     is_os2
//     is_mac, is_mac68k, is_macppc
//     is_unix
//	is_sun, is_sun4, is_sun5, is_suni86
//	is_irix, is_irix5, is_irix6
//	is_hpux, is_hpux9, is_hpux10
//	is_aix, is_aix1, is_aix2, is_aix3, is_aix4
//	is_linux, is_sco, is_unixware, is_mpras, is_reliant
//	is_dec, is_sinix, is_freebsd, is_bsd
//     is_vms
//
// based in part on 
// http://www.mozilla.org/docs/web-developer/sniffer/browser_type.html
// The Ultimate JavaScript Client Sniffer
// and Andy King's object detection sniffer
//
// Note: you don't want your Nav4 or IE4 code to "turn off" or
// stop working when Nav5 and IE5 (or later) are released, so
// in conditional code forks, use is_nav4up ("Nav4 or greater")
// and is_ie4up ("IE4 or greater") instead of is_nav4 or is_ie4
// to check version in code which you want to work on future
// versions. For DOM tests scripters commonly used the 
// is_getElementById test, but make sure you test your code as
// filter non-compliant browsers (Opera 5-6 for example) as some 
// browsers return true for this test, and don't fully support
// the W3C's DOM1.
//

    // convert all characters to lowercase to simplify testing
    var agt=navigator.userAgent.toLowerCase();
    var appVer = navigator.appVersion.toLowerCase();

    // *** BROWSER VERSION ***

    var is_minor = parseFloat(appVer);
    var is_major = parseInt(is_minor);

    var is_opera = (agt.indexOf("opera") != -1);
    var is_opera2 = (agt.indexOf("opera 2") != -1 || agt.indexOf("opera/2") != -1);
    var is_opera3 = (agt.indexOf("opera 3") != -1 || agt.indexOf("opera/3") != -1);
    var is_opera4 = (agt.indexOf("opera 4") != -1 || agt.indexOf("opera/4") != -1);
    var is_opera5 = (agt.indexOf("opera 5") != -1 || agt.indexOf("opera/5") != -1);
    var is_opera6 = (agt.indexOf("opera 6") != -1 || agt.indexOf("opera/6") != -1); // new 020128- abk
    var is_opera7 = (agt.indexOf("opera 7") != -1 || agt.indexOf("opera/7") != -1); // new 021205- dmr
    var is_opera5up = (is_opera && !is_opera2 && !is_opera3 && !is_opera4);
    var is_opera6up = (is_opera && !is_opera2 && !is_opera3 && !is_opera4 && !is_opera5); // new020128
    var is_opera7up = (is_opera && !is_opera2 && !is_opera3 && !is_opera4 && !is_opera5 && !is_opera6); // new021205 -- dmr

    // Note: On IE, start of appVersion return 3 or 4
    // which supposedly is the version of Netscape it is compatible with.
    // So we look for the real version further on in the string
    // And on Mac IE5+, we look for is_minor in the ua; since 
    // it appears to be more accurate than appVersion - 06/17/2004

    var is_mac = (agt.indexOf("mac")!=-1);
    var iePos  = appVer.indexOf('msie');
    if (iePos !=-1) {
       if(is_mac) {
	   var iePos = agt.indexOf('msie');
	   is_minor = parseFloat(agt.substring(iePos+5,agt.indexOf(';',iePos)));
       }
       else is_minor = parseFloat(appVer.substring(iePos+5,appVer.indexOf(';',iePos)));
       is_major = parseInt(is_minor);
    }

    // ditto Konqueror
				      
    var is_konq = false;
    var kqPos   = agt.indexOf('konqueror');
    if (kqPos !=-1) {		 
       is_konq  = true;
       is_minor = parseFloat(agt.substring(kqPos+10,agt.indexOf(';',kqPos)));
       is_major = parseInt(is_minor);
    }				 

    var is_getElementById   = (document.getElementById) ? "true" : "false"; // 001121-abk
    var is_getElementsByTagName = (document.getElementsByTagName) ? "true" : "false"; // 001127-abk
    var is_documentElement = (document.documentElement) ? "true" : "false"; // 001121-abk

    var is_safari = ((agt.indexOf('safari')!=-1)&&(agt.indexOf('mac')!=-1))?true:false;
    var is_khtml  = (is_safari || is_konq);

    var is_gecko = ((!is_khtml)&&(navigator.product)&&(navigator.product.toLowerCase()=="gecko"))?true:false;
    var is_gver  = 0;
    if (is_gecko) is_gver=navigator.productSub;

    var is_moz   = ((agt.indexOf('mozilla/5')!=-1) && (agt.indexOf('spoofer')==-1) &&
		    (agt.indexOf('compatible')==-1) && (agt.indexOf('opera')==-1)  &&
		    (agt.indexOf('webtv')==-1) && (agt.indexOf('hotjava')==-1)     &&
		    (is_gecko) && 
		    ((navigator.vendor=="")||(navigator.vendor=="Mozilla")||(navigator.vendor=="Debian")));
    var is_fb = ((agt.indexOf('mozilla/5')!=-1) && (agt.indexOf('spoofer')==-1) &&
		 (agt.indexOf('compatible')==-1) && (agt.indexOf('opera')==-1)  &&
		 (agt.indexOf('webtv')==-1) && (agt.indexOf('hotjava')==-1)     &&
		 (is_gecko) && (navigator.vendor=="Firebird"));
    var is_fx = ((agt.indexOf('mozilla/5')!=-1) && (agt.indexOf('spoofer')==-1) &&
		 (agt.indexOf('compatible')==-1) && (agt.indexOf('opera')==-1)  &&
		 (agt.indexOf('webtv')==-1) && (agt.indexOf('hotjava')==-1)     &&
		 (is_gecko) && (navigator.vendor=="Firefox"));
    if ((is_moz)||(is_fb)||(is_fx)) {  // 032504 - dmr
       var is_moz_ver = (navigator.vendorSub)?navigator.vendorSub:0;
       if(!(is_moz_ver)) {
	   is_moz_ver = agt.indexOf('rv:');
	   is_moz_ver = agt.substring(is_moz_ver+3);
	   is_paren   = is_moz_ver.indexOf(')');
	   is_moz_ver = is_moz_ver.substring(0,is_paren);
       }
       is_minor = is_moz_ver;
       is_major = parseInt(is_moz_ver);
    }
   var is_fb_ver = is_moz_ver;
   var is_fx_ver = is_moz_ver;

    var is_nav  = ((agt.indexOf('mozilla')!=-1) && (agt.indexOf('spoofer')==-1)
		&& (agt.indexOf('compatible') == -1) && (agt.indexOf('opera')==-1)
		&& (agt.indexOf('webtv')==-1) && (agt.indexOf('hotjava')==-1)
		&& (!is_khtml) && (!(is_moz)) && (!is_fb) && (!is_fx));

    // Netscape6 is mozilla/5 + Netscape6/6.0!!!
    // Mozilla/5.0 (Windows; U; Win98; en-US; m18) Gecko/20001108 Netscape6/6.0
    // Changed this to use navigator.vendor/vendorSub - dmr 060502   
    // var nav6Pos = agt.indexOf('netscape6');
    // if (nav6Pos !=-1) {
    if ((navigator.vendor)&&
	((navigator.vendor=="Netscape6")||(navigator.vendor=="Netscape"))&&
	(is_nav)) {
       is_major = parseInt(navigator.vendorSub);
       // here we need is_minor as a valid float for testing. We'll
       // revert to the actual content before printing the result. 
       is_minor = parseFloat(navigator.vendorSub);
    }

    var is_nav2 = (is_nav && (is_major == 2));
    var is_nav3 = (is_nav && (is_major == 3));
    var is_nav4 = (is_nav && (is_major == 4));
    var is_nav4up = (is_nav && is_minor >= 4);  // changed to is_minor for
						// consistency - dmr, 011001
    var is_navonly      = (is_nav && ((agt.indexOf(";nav") != -1) ||
			  (agt.indexOf("; nav") != -1)) );

    var is_nav6   = (is_nav && is_major==6);    // new 010118 mhp
    var is_nav6up = (is_nav && is_minor >= 6); // new 010118 mhp

    var is_nav5   = (is_nav && is_major == 5 && !is_nav6); // checked for ns6
    var is_nav5up = (is_nav && is_minor >= 5);

    var is_nav7   = (is_nav && is_major == 7);
    var is_nav7up = (is_nav && is_minor >= 7);

    var is_ie   = ((iePos!=-1) && (!is_opera) && (!is_khtml));
    var is_ie3  = (is_ie && (is_major < 4));

    var is_ie4   = (is_ie && is_major == 4);
    var is_ie4up = (is_ie && is_minor >= 4);
    var is_ie5   = (is_ie && is_major == 5);
    var is_ie5up = (is_ie && is_minor >= 5);
    
    var is_ie5_5  = (is_ie && (agt.indexOf("msie 5.5") !=-1)); // 020128 new - abk
    var is_ie5_5up =(is_ie && is_minor >= 5.5);		// 020128 new - abk
	
    var is_ie6   = (is_ie && is_major == 6);
    var is_ie6up = (is_ie && is_minor >= 6);

// KNOWN BUG: On AOL4, returns false if IE3 is embedded browser
    // or if this is the first browser window opened.  Thus the
    // variables is_aol, is_aol3, and is_aol4 aren't 100% reliable.

    var is_aol   = (agt.indexOf("aol") != -1);
    var is_aol3  = (is_aol && is_ie3);
    var is_aol4  = (is_aol && is_ie4);
    var is_aol5  = (agt.indexOf("aol 5") != -1);
    var is_aol6  = (agt.indexOf("aol 6") != -1);
    var is_aol7  = ((agt.indexOf("aol 7")!=-1) || (agt.indexOf("aol7")!=-1));
    var is_aol8  = ((agt.indexOf("aol 8")!=-1) || (agt.indexOf("aol8")!=-1));

    var is_webtv = (agt.indexOf("webtv") != -1);
    
    // new 020128 - abk
    
    var is_TVNavigator = ((agt.indexOf("navio") != -1) || (agt.indexOf("navio_aoltv") != -1)); 
    var is_AOLTV = is_TVNavigator;

    var is_hotjava = (agt.indexOf("hotjava") != -1);
    var is_hotjava3 = (is_hotjava && (is_major == 3));
    var is_hotjava3up = (is_hotjava && (is_major >= 3));

    // end new
	
    // *** JAVASCRIPT VERSION CHECK ***
    // Useful to workaround Nav3 bug in which Nav3
    // loads <SCRIPT LANGUAGE="JavaScript1.2">.
    // updated 020131 by dragle
    var is_js;
    if (is_nav2 || is_ie3) is_js = 1.0;
    else if (is_nav3) is_js = 1.1;
    else if ((is_opera5)||(is_opera6)) is_js = 1.3; // 020214 - dmr
    else if (is_opera7up) is_js = 1.5; // 031010 - dmr
    else if (is_khtml) is_js = 1.5;   // 030110 - dmr
    else if (is_opera) is_js = 1.1;
    else if ((is_nav4 && (is_minor <= 4.05)) || is_ie4) is_js = 1.2;
    else if ((is_nav4 && (is_minor > 4.05)) || is_ie5) is_js = 1.3;
    else if (is_nav5 && !(is_nav6)) is_js = 1.4;
    else if (is_hotjava3up) is_js = 1.4; // new 020128 - abk
    else if (is_nav6up) is_js = 1.5;

    // NOTE: In the future, update this code when newer versions of JS
    // are released. For now, we try to provide some upward compatibility
    // so that future versions of Nav and IE will show they are at
    // *least* JS 1.x capable. Always check for JS version compatibility
    // with > or >=.

    else if (is_nav && (is_major > 5)) is_js = 1.4;
    else if (is_ie && (is_major > 5)) is_js = 1.3;
    else if (is_moz) is_js = 1.5;
    else if (is_fb||is_fx) is_js = 1.5; // 032504 - dmr
    
    // what about ie6 and ie6up for js version? abk
    
    // HACK: no idea for other browsers; always check for JS version 
    // with > or >=
    else is_js = 0.0;
    // HACK FOR IE5 MAC = js vers = 1.4 (if put inside if/else jumps out at 1.3)
    if ((agt.indexOf("mac")!=-1) && is_ie5up) is_js = 1.4; // 020128 - abk
    
    // Done with is_minor testing; revert to real for N6/7
    if (is_nav6up) {
       is_minor = navigator.vendorSub;
    }

    // *** PLATFORM ***
    var is_win   = ( (agt.indexOf("win")!=-1) || (agt.indexOf("16bit")!=-1) );
    // NOTE: On Opera 3.0, the userAgent string includes "Windows 95/NT4" on all
    //	Win32, so you can't distinguish between Win95 and WinNT.
    var is_win95 = ((agt.indexOf("win95")!=-1) || (agt.indexOf("windows 95")!=-1));

    // is this a 16 bit compiled version?
    var is_win16 = ((agt.indexOf("win16")!=-1) ||
	       (agt.indexOf("16bit")!=-1) || (agt.indexOf("windows 3.1")!=-1) ||
	       (agt.indexOf("windows 16-bit")!=-1) );

    var is_win31 = ((agt.indexOf("windows 3.1")!=-1) || (agt.indexOf("win16")!=-1) ||
		    (agt.indexOf("windows 16-bit")!=-1));
	
	var is_winme = ((agt.indexOf("win 9x 4.90")!=-1));    // new 020128 - abk
    var is_win2k = ((agt.indexOf("windows nt 5.0")!=-1) || (agt.indexOf("windows 2000")!=-1)); // 020214 - dmr
    var is_winxp = ((agt.indexOf("windows nt 5.1")!=-1) || (agt.indexOf("windows xp")!=-1)); // 020214 - dmr

    // NOTE: Reliable detection of Win98 may not be possible. It appears that:
    //       - On Nav 4.x and before you'll get plain "Windows" in userAgent.
    //       - On Mercury client, the 32-bit version will return "Win98", but
    //	 the 16-bit version running on Win98 will still return "Win95".
    var is_win98 = ((agt.indexOf("win98")!=-1) || (agt.indexOf("windows 98")!=-1));
    var is_winnt = ((agt.indexOf("winnt")!=-1) || (agt.indexOf("windows nt")!=-1));
    var is_win32 = (is_win95 || is_winnt || is_win98 ||
		    ((is_major >= 4) && (navigator.platform == "Win32")) ||
		    (agt.indexOf("win32")!=-1) || (agt.indexOf("32bit")!=-1));

    var is_os2   = ((agt.indexOf("os/2")!=-1) ||
		    (navigator.appVersion.indexOf("OS/2")!=-1) ||
		    (agt.indexOf("ibm-webexplorer")!=-1));

    var is_mac    = (agt.indexOf("mac")!=-1);
    if (is_mac) { is_win = !is_mac; } // dmr - 06/20/2002
    var is_mac68k = (is_mac && ((agt.indexOf("68k")!=-1) ||
			       (agt.indexOf("68000")!=-1)));
    var is_macppc = (is_mac && ((agt.indexOf("ppc")!=-1) ||
				(agt.indexOf("powerpc")!=-1)));

    var is_sun   = (agt.indexOf("sunos")!=-1);
    var is_sun4  = (agt.indexOf("sunos 4")!=-1);
    var is_sun5  = (agt.indexOf("sunos 5")!=-1);
    var is_suni86= (is_sun && (agt.indexOf("i86")!=-1));
    var is_irix  = (agt.indexOf("irix") !=-1);    // SGI
    var is_irix5 = (agt.indexOf("irix 5") !=-1);
    var is_irix6 = ((agt.indexOf("irix 6") !=-1) || (agt.indexOf("irix6") !=-1));
    var is_hpux  = (agt.indexOf("hp-ux")!=-1);
    var is_hpux9 = (is_hpux && (agt.indexOf("09.")!=-1));
    var is_hpux10= (is_hpux && (agt.indexOf("10.")!=-1));
    var is_aix   = (agt.indexOf("aix") !=-1);      // IBM
    var is_aix1  = (agt.indexOf("aix 1") !=-1);
    var is_aix2  = (agt.indexOf("aix 2") !=-1);
    var is_aix3  = (agt.indexOf("aix 3") !=-1);
    var is_aix4  = (agt.indexOf("aix 4") !=-1);
    var is_linux = (agt.indexOf("inux")!=-1);
    var is_sco   = (agt.indexOf("sco")!=-1) || (agt.indexOf("unix_sv")!=-1);
    var is_unixware = (agt.indexOf("unix_system_v")!=-1);
    var is_mpras    = (agt.indexOf("ncr")!=-1);
    var is_reliant  = (agt.indexOf("reliantunix")!=-1);
    var is_dec   = ((agt.indexOf("dec")!=-1) || (agt.indexOf("osf1")!=-1) ||
	   (agt.indexOf("dec_alpha")!=-1) || (agt.indexOf("alphaserver")!=-1) ||
	   (agt.indexOf("ultrix")!=-1) || (agt.indexOf("alphastation")!=-1));
    var is_sinix = (agt.indexOf("sinix")!=-1);
    var is_freebsd = (agt.indexOf("freebsd")!=-1);
    var is_bsd = (agt.indexOf("bsd")!=-1);
    var is_unix  = ((agt.indexOf("x11")!=-1) || is_sun || is_irix || is_hpux ||
		 is_sco ||is_unixware || is_mpras || is_reliant ||
		 is_dec || is_sinix || is_aix || is_linux || is_bsd || is_freebsd);

    var is_vms   = ((agt.indexOf("vax")!=-1) || (agt.indexOf("openvms")!=-1));
// additional checks, abk
	var is_anchors = (document.anchors) ? "true":"false";
	var is_regexp = (window.RegExp) ? "true":"false";
	var is_option = (window.Option) ? "true":"false";
	var is_all = (document.all) ? "true":"false";
// cookies - 990624 - abk
	document.cookie = "cookies=true";
	var is_cookie = (document.cookie) ? "true" : "false";
	var is_images = (document.images) ? "true":"false";
	var is_layers = (document.layers) ? "true":"false"; // gecko m7 bug?
// new doc obj tests 990624-abk
	var is_forms = (document.forms) ? "true" : "false";
	var is_links = (document.links) ? "true" : "false";
	var is_frames = (window.frames) ? "true" : "false";
	var is_screen = (window.screen) ? "true" : "false";

// java
	var is_java = (navigator.javaEnabled());

// Flash checking code adapted from Doc JavaScript information; 
// see http://webref.com/js/column84/2.html

   var is_Flash	= false;
   var is_FlashVersion = 0;

   if ((is_nav||is_opera||is_moz||is_fb||is_fx)||
       (is_mac&&is_ie5up)) {
      var plugin = (navigator.mimeTypes && 
		    navigator.mimeTypes["application/x-shockwave-flash"] &&
		    navigator.mimeTypes["application/x-shockwave-flash"].enabledPlugin) ?
		    navigator.mimeTypes["application/x-shockwave-flash"].enabledPlugin : 0;
//      if (plugin) {
      if (plugin&&plugin.description) {
	 is_Flash = true;
	 is_FlashVersion = parseInt(plugin.description.substring(plugin.description.indexOf(".")-1));
      }
   }
