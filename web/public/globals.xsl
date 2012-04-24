<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

<xsl:variable name="URI_ROOT">http://localhost</xsl:variable>

<xsl:template name="page-tools">
  <script type="text/javascript" src="jquery-1.6.2.js"> //script </script>
  <script type="text/javascript" src="json2.js"> //script </script>
  <link href="http://fonts.googleapis.com/css?family=Crimson+Text|Droid+Sans" rel="stylesheet" type="text/css" />
  <link rel="stylesheet" type="text/css" href="/public/css/composercat.css" />
</xsl:template>

<xsl:template name="page-header">
  <h1>PrOCAV</h1>
  <div id="page-subtitle">Prokofiev Online Catalogue Archive and Visualization</div>
  <ul id="catalogue-menu">
    <li><a href="{$URI_ROOT}">Home</a></li>
    <li><a href="#">Works</a></li>
    <li><a href="#">Manuscripts</a></li>
    <li><a href="#">Letters</a></li>
    <li><a href="#">Search</a></li>
    <li><a href="#">About</a></li>
  </ul>
</xsl:template>

<xsl:template name="page-footer">
  <div id="footer">

  </div>
</xsl:template>

</xsl:stylesheet>
