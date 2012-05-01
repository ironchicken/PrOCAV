<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

<xsl:variable name="URI_ROOT">http://localhost</xsl:variable>

<xsl:template name="page-tools">
  <script type="text/javascript" src="/public/js/jquery-1.7.1.min.js"> //script </script>
  <link href="http://fonts.googleapis.com/css?family=Crimson+Text|Droid+Sans|Dosis:400,500" rel="stylesheet" type="text/css" />
  <link rel="stylesheet" type="text/css" href="/public/css/composercat.css" />
</xsl:template>

<xsl:template name="page-header">
  <div id="title-area">
    <h1>PrOCAV</h1>
    <div id="page-subtitle">Prokofiev Online Catalogue Archive and Visualization</div>
  </div>
</xsl:template>

<xsl:template name="page-menu">
  <div id="left-area">
    <form id="fulltext-search" name="fulltext-search" action="{$URI_ROOT}/search" method="GET">
      <input type="hidden" name="start" id="start" value="1" />
      <input type="hidden" name="limit" id="limit" value="10" />
      <p>Search: <input type="text" name="terms" id="terms" onchange="document.forms[1].submit()" /></p>
    </form>
    <ul id="catalogue-menu">
      <li><a href="{$URI_ROOT}">Home</a></li>
      <li><a href="{$URI_ROOT}/browse">Browse</a></li>
      <li><a href="#">Search</a></li>
      <li><a href="{$URI_ROOT}/about">About</a></li>
    </ul>
    <img src="/public/img/prokofiev-piano.png" alt="Prokofiev at piano" style="margin:25px" />
  </div>
</xsl:template>

<xsl:template name="user-tools">
  <div id="right-area">
    <!--<span style="color:#FFFFFF">User tools</span>-->
  </div>
</xsl:template>

<xsl:template name="page-footer">
  <div id="footer">
    <table style="border:none">
      <tr>
        <td colspan="3" style="text-align:center">
          PrOCAV is supported by the <a
          href="http://www.sprkfv.net/">Serge Prokofiev
          Foundation</a>, <a href="http://www.gold.ac.uk/">Goldsmiths,
          University of London</a>, and <a
          href="http://www.princeton.edu/">Princeton University</a>
	</td>
      </tr>
      <tr>
        <td>
          <a href="http://www.sprkfv.net/"><img src="/public/img/spf.png" alt="Serge Prokofiev Foundation" /></a>
	</td>
        <td>
          <a href="http://www.gold.ac.uk/"><img src="/public/img/goldsmiths.png" alt="Goldsmmiths, University of London" /></a>
	</td>
        <td>
          <a href="http://www.princeton.edu/"><img src="/public/img/princeton.png" alt="Princeton University" /></a>
	</td>
      </tr>
      <tr>
        <td colspan="3" style="text-align:center">
          Copyright © 2012 PrOCAV
	</td>
      </tr>
    </table>
  </div>
</xsl:template>

</xsl:stylesheet>
