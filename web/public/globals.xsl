<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:str="http://exslt.org/strings"
		extension-element-prefixes="str"
		version="1.0">

<xsl:import href="str.replace.xsl" />

<xsl:output method="html" />

<xsl:variable name="URI_ROOT">http://localhost</xsl:variable>

<xsl:template name="page-tools">
  <script type="text/javascript" src="/public/js/jquery-1.7.2.min.js"> //script </script>
  <link href="http://fonts.googleapis.com/css?family=Crimson+Text|Droid+Sans|Dosis:400,500|Oxygen" rel="stylesheet" type="text/css" />
  <link rel="stylesheet" type="text/css" href="/public/css/composercat.css" />
  <script type="text/javascript" src="/public/js/composercat.js"> //script </script>
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

<xsl:template name="browsing-index">
  <xsl:apply-templates select="/response/index" />
</xsl:template>

<xsl:template match="index">
  <xsl:variable name="results-list"><xsl:value-of select="$URI_ROOT" />/<xsl:value-of select="index_function" />?<xsl:for-each select="index_args/*"><xsl:value-of select="name()" />=<xsl:value-of select="." />&amp;</xsl:for-each>start=<xsl:value-of select="position" /></xsl:variable>

  <ul id="navigation">
    <xsl:apply-templates select="prev_record" />
    <li><a href="{$results-list}">results list</a></li>
    <xsl:apply-templates select="next_record" />
  </ul>
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

<xsl:template match="annotation" priority="-1">
  <span class="annot-toggle" onclick="composerCat.showPopup(event, composerCat.nextAnnotation(event))">?</span><span class="annotation"><xsl:apply-templates /></span>
</xsl:template>

<xsl:template match="p|div|span|a">
  <xsl:element name="{name()}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="str:replace(string(.), '{$URI_ROOT}', string($URI_ROOT))" /></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates />
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
