<?php
/**
 * nixos, a MediaWiki skin
 * Version 1.0
 * Made for MediaWiki 1.16
 * By Joachim Schiele, js@lastlog.de, 14.jun.2011
 * Based on 'clean' by Kevin Hughes, kev@kevcom.com, 11/17/2005
 * see CHANGELOG
 *
 * This work is licensed under a Creative Commons Attribution-ShareAlike 3.0 Unported License:
 * http://creativecommons.org/licenses/by-sa/3.0/
 *
 * Local settings that affect this skin (in LocalSettings.php):
 * $wgDefaultSkin       change to "clean" to use as your default skin
 * $wgSitename          this is displayed as the site name
 * $wgLanguageCode      this affects the UI language
 * $wgGroupPermissions  this affects whether or not editing widgets are shown
 * $wgRightsPage, etc.  this affects the copyright statement in the footer
 *
 * $wgLogo has no effect on this skin.
 *
 * Please see:
 *  - nixos/header.php  (this contains the top level links)
 *  - nixos/footer.php  (this contains the 'about us' link)
 * both can contain links to a) external pages or b) wiki pages:
 * example for a): <li><a href="http://nixos.org/about-us.html">About us</a></li> 
 * example for b): <li><a href="Demo">Demo</a></li> 
 *
 * @package MediaWiki
 * @subpackage Skins
 */

if(!defined('MEDIAWIKI'))
	die();

/** */
require_once('includes/SkinTemplate.php');

/**
 * @package MediaWiki
 * @subpackage Skins
 */
class SkinNixOS extends SkinTemplate {
	function initPage( OutputPage $out ) {
		SkinTemplate::initPage( $out );
		$this->skinname  = 'nixos';
		$this->stylename = 'nixos';
		$this->template  = 'NixOSTemplate';
	}
}

/**
 * @package MediaWiki
 * @subpackage Skins
 */
class NixOSTemplate extends QuickTemplate {

	/**
	 * @access private
	 */
	function execute() {

	global $wgLanguageCode;
	global $wgArticlePath;
	global $wgSitename;
	global $wgUser;

	wfSuppressWarnings();

	// Set up all needed template variables first!

	$homeLink = htmlspecialchars($this->data['nav_urls']
		['mainpage']['href']);
	$isEnglish = false;
	if ($wgLanguageCode == "en")
		$isEnglish = true;
	$canEdit = false;
	if ($wgUser->isAllowed('edit'))
		$canEdit = true;

	// Set up login text

	$loginText = "";
	foreach ($this->data['personal_urls'] as $key => $item) {
		$href = htmlspecialchars($item['href']);
		$text = htmlspecialchars($item['text']);
		if ($key != "userpage")
			$text = strtolower($text);
		$link = "<a href='$href'>$text</a>";
		if ($key == "anonlogin" || $key == "logout" ||
		$key == "userpage" || $key == "preferences")
			$loginText .= $link;
		if ($key == "userpage" || $key == "preferences")
			$loginText .= " / ";
	}
	if (!$loginText && !$userpage) {
		$text = strtolower(htmlspecialchars(
			$this->translator->translate("userlogin")));
		$path = str_replace('$1', "Special:Userlogin", $wgArticlePath);
		$loginText = "<a href='$path'>$text</a>";
	}

	// Navigation links

	foreach ($this->data['nav_urls'] as $key => $item) {
		$href = htmlspecialchars($item['href']);
		$text = strtolower(htmlspecialchars(
			$this->translator->translate($key)));
		if ($key == "upload" && $isEnglish)
			$text = "upload files";
		$link = "<a href='$href'>$text</a>";
		if ($key == "help")
			$helpLink = $link;
		if ($key == "recentchanges")
			$recentLink = $link;
		if ($key == "upload")
			$uploadLink = $link;
		if ($key == "specialpages")
			$specialLink = $link;
		if ($key == "recentchangeslinked")
			$relatedLink = $link;
	}

	// Content action links

	foreach ($this->data['content_actions'] as $key => $item) {
		$href = htmlspecialchars($item['href']);
		$text = htmlspecialchars($item['text']);
		if ($key == "talk" && $isEnglish)
			$text = "discuss";
		if ($key == "history" && $isEnglish)
			$text = "changes";
		if ($key == "move" && $isEnglish)
			$text = "rename";
		if ($key == "nstab-main")
			$text = $this->data['title'];
		else
			$text = strtolower($text);
		$link =  "<a href='$href'>$text</a>";
		if ($key == "talk")
			$talkLink = $link;
		if ($key == "edit")
			$editLink = $link;
		if ($key == "history")
			$historyLink = $link;
		if ($key == "protect")
			$protectLink = $link;
		if ($key == "delete")
			$deleteLink = $link;
		if ($key == "move")
			$moveLink = $link;
		if ($key == "watch")
			$watchLink = $link;
		if ($key == "nstab-main")
			$pageLink = $link;
	}

	if (!$pageLink)
		$pageLink = $this->data['title'];

	$text = strtolower(htmlspecialchars(
		$this->translator->translate("allpages")));
	$path = str_replace('$1', "Special:Allpages", $wgArticlePath);
	$allLink = "<a href='$path'>$text</a>";

	$searchLabel = strtolower(htmlspecialchars(
		$this->translator->translate("search")));
	$newPageLabel = strtolower(htmlspecialchars(
		$this->translator->translate("newpage")));
	if ($canEdit)
		$moreLabel = strtolower(htmlspecialchars(
			$this->translator->translate("moredotdotdot")));
	else
		$moreLabel = strtolower(htmlspecialchars(
			$this->translator->translate("qbpageoptions")));
	$moreLabel = str_replace("...", "", $moreLabel);
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="<?php $this->text('lang') ?>" lang="<?php $this->text('lang') ?>" dir="<?php $this->text('dir') ?>">
<head>
<meta http-equiv="Content-Type" content="<?php $this->text('mimetype') ?>; charset=<?php $this->text('charset') ?>" />
<?php $this->html('headlinks') ?>
<title><?php $this->text('pagetitle') ?></title>

<!--[if lt IE 7]><script src="<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/ie7/ie7-standard-p.js" type="text/javascript"></script><![endif]-->

<style type="text/css" media="screen, projection"> @import "<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/main.css"; </style>

<?php if($this->data['jsvarurl']) { ?><script type="<?php $this->text('jsmimetype') ?>" src="<?php $this->text('jsvarurl') ?>"></script><?php } ?>
<script type="<?php $this->text('jsmimetype') ?>" src="<?php $this->text('stylepath') ?>/common/wikibits.js"></script>
<?php if($this->data['usercss']) { ?><style type="text/css"><?php $this->html('usercss') ?></style><?php } ?>

<?php if($this->data['userjs']) { ?><script type="<?php $this->text('jsmimetype') ?>" src="<?php $this->text('userjs') ?>"></script><?php } ?>
<?php if($this->data['userjsprev']) { ?><script type="<?php $this->text('jsmimetype') ?>"><?php $this->html('userjsprev') ?></script><?php } ?>
<style type="text/css"><?php $this->html('usercss') ?></style>

<script type="<?php $this->text('jsmimetype') ?>" src="<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/browser.detect.js"></script>
<script type="<?php $this->text('jsmimetype') ?>" src="<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/fadomatic.js"></script>
<script type="<?php $this->text('jsmimetype') ?>" src="<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/functions.js"></script>

</head>
<body>

<script type="<?php $this->text('jsmimetype') ?>">
	if (is_win) {
		document.write("<style type='text/css' media='screen, projection'> @import '<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/main.win.css';</style>");
	}
</script>

<?php
	if (!$canEdit) {
?>
<style type="text/css">
.editsection { display: none; visibility: hidden; }
</style>
<?php
	}
?>

<div id="header">
   <div id="logo"><a class="no-hover" href="http://nixos.org"><img border="0px" src="<?php $this->text('stylepath') ?>/<?php $this->text('stylename') ?>/nixos-lores.png" alt="Nix Logo"/></a></div>
   <ul class="short-menu" id="top-menu">
<?php
require_once('nixos/header.php');
?>
   </ul>
</div>


<table cellpadding="0" cellspacing="0" border="0" summary="" id="bodyTable">
<tr valign="top">

<!--
<td id="leftDiv" nowrap width="20"></td>
-->
<td id="middleDiv" valign="top">



<div id="bodyDiv">

<div id="topBackground">
<!--
<div id="siteLogoDiv">
</div>
<div id="siteTitle"><a href="<?php echo $homeLink ?>"><?php echo $wgSitename ?></a></div>
-->
<div id="loginText"><?php echo $loginText ?></div>
</div>

<table cellpadding="0" cellspacing="0" border="0" width="100%" id="menuTable">
<tr valign="center">
<td class="menuItem" onmouseover="showMenu('mainMenu', 'homeLink', 'left');" nowrap><a href="<?php echo $homeLink ?>" id="homeLink">wiki</a></td>
<td class="menuItem" nowrap><?php echo $helpLink; ?></td>
<td nowrap width="100%"></td>
<td class="menuItem" nowrap><?php echo $searchLabel; ?></td>
<td class="menuItem" nowrap><form id="searchForm" name="searchForm" action="<?php $this->text('searchaction') ?>"><input id="searchField" name="search" type="text" autosave="wiki" results="20" accesskey="<?php $this->msg('accesskey-search') ?>" value="<?php $this->text('search') ?>" /></form></td>
</tr>
</table>

<div id="mainMenu" style="display:none;visibility:hidden">
<?php
	if ($canEdit) {
?>
<div class="mainMenuItem"><a href="javascript:newPage('<?php echo $wgArticlePath; ?>');"><?php echo $newPageLabel; ?></a></div>
<?php
	}
?>
<div class="mainMenuItem"><?php echo $allLink; ?></div>
<?php
	if ($canEdit) {
?>
<div class="mainMenuItem"><?php echo $specialLink; ?></div>
<div class="mainMenuItemDiv"></div>
<div class="mainMenuItem"><?php echo $recentLink; ?></div>
<div class="mainMenuItemDiv"></div>
<div class="mainMenuItem"><?php echo $uploadLink; ?></div>
<?php
	}
?>
</div>

<div id="editMiniMenu" style="display:none;visibility:hidden">
<div class="editMiniItem"><?php echo $historyLink; ?></div>
<div class="editMiniItem"><?php echo $relatedLink; ?></div>
<?php
	if ($deleteLink) {
?>
<div class="editMiniItemDiv"></div>
<div class="editMiniItem"><?php echo $protectLink; ?></div>
<div class="editMiniItem"><?php echo $deleteLink; ?></div>
<div class="editMiniItem"><?php echo $moveLink; ?></div>
<div class="editMiniItem"><?php echo $watchLink; ?></div>
<?php
	}
?>
</div>

<div id="pageHeader">

<div id="editMenu">
<?php
	if ($editLink && $canEdit) {
?>
<div class="editMenuItem editMenuItemLast" onmouseover="showMenu('editMiniMenu', 'dropLink', 'right');" id="dropLink"><?php echo $moreLabel; ?></div>
<div class="editMenuItem"><?php echo $talkLink; ?></div>
<div class="editMenuItem"><?php echo $editLink; ?></div>
<?php
	}
?>
</div>

<div id="pageTitle"><?php echo $pageLink; ?></div>

</div>

<div id="bodyContent">
<!-- start content -->
<?php
	// A few things must be done to the content in
	// order to make it more CSS-friendly

	$openP = false;
	$openSpan = false;
	if ($_REQUEST['title'] == "Special:Search") {
		echo "<span id='searchContent'>";
		$openSpan = true;
	} else if (strstr($_REQUEST['title'], "Special:Recentchangeslinked")
	!== false) {
		echo "<span id='relatedChanges'>";
		$openSpan = true;
	} else if ($_REQUEST['title'] == "Special:Userlogout") {
		$openP = true;
	} else if (strstr($_REQUEST['title'], "Special:Recentchangeslinked")
	!= false) {
		$openP = true;
	}
	if ($_REQUEST['action'] == "history")
		$openP = true;

	if ($openP)
		echo "<p>";
	echo "<div id='emptyDiv'></div>\n";

	$bodytext = $this->data['bodytext'];
	$bodytext = preg_replace("/editsection.*\[(.*)\]/",
		"editsection\">$1", $bodytext);
	echo $bodytext;

	if ($openP)
		echo "</p>";
	if ($openSpan)
		echo "</span>";

	if ($this->data['catlinks']) {
		echo '<div id="catlinks">';
		$this->html('catlinks');
		echo '</div>';
	}

	echo "<div id='lastmod'>\n";
	$modtime = $this->data['lastmod'];
	$pos = strpos($modtime, "modified");
	$modtime = substr($modtime, $pos + 9);
	$modtime = str_replace(",", "", $modtime);
	$modtime = str_replace(".", "", $modtime);
	$prefix = substr($modtime, 0, 5);
	$suffix = substr($modtime, 6);
	$time = strtotime($suffix);
	$year = date("Y", $time);
	$day = date("j", $time);
	$month = date("n", $time);
	$pieces = explode(":", $prefix);
	$hour = $pieces[0];
	$minute = $pieces[1];
	$time = mktime($hour, $minute, $second, $month, $day, $year);
	if ($time > 0) {
		echo "Last modified " . date("F j, Y g:i a", $time);
		if ($this->data['copyright'])
			echo " / " . $this->data['copyright'];
		echo " / " . '<a href="http://www.ipbwiki.com/forums/index.php?showtopic=411">Skin by Kevin Hughes</a>';
	}
	echo "</div>";
?>

<!-- end content -->
</div>
<hr>
<div id="footer">
  <ul class="short-menu" id="bottom-menu">
<?php
	require_once('nixos/footer.php');
?>
  </ul>
</div>

<?php
		if($this->data['poweredbyico']) { ?>
				<!--<center><?php $this->html('poweredbyico') ?></center>-->
<?php 	} ?>

</div>

</td>


<!--
<td id="rightDiv" nowrap width="20"></td>
-->
</tr>
</table>

</body>
</html>

<?php
	wfRestoreWarnings();
	}
}
?>
