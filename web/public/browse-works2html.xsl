<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

<xsl:variable name="URI_ROOT">http://localhost</xsl:variable>

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Serge Prokofiev: <xsl:value-of select="//details/uniform_title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="DC.title" lang="en" content="{//details/uniform_title}" />
    <meta name="DC.creator" content="Serge Prokofiev" />

    <script type="text/javascript" src="jquery-1.6.2.js"> //script </script>
    <script type="text/javascript" src="json2.js"> //script </script>
    <link href="http://fonts.googleapis.com/css?family=Crimson+Text|Droid+Sans" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" type="text/css" href="/public/css/composercat.css" />
  </head>
  <body>
    <h1>Serge Prokofiev Catalogue</h1>
    <ul id="catalogue-menu">
      <li><a href="#">Home</a></li>
      <li><a href="#">Works</a></li>
      <li><a href="#">Manuscripts</a></li>
      <li><a href="#">Letters</a></li>
      <li><a href="#">Search</a></li>
    </ul>
    <ol>
      <xsl:apply-templates select="//work" />
    </ol>
    <div id="footer">

    </div>
  </body>    
</html>
</xsl:template>

<xsl:template match="work">
  <li>
    <a href="{$URI_ROOT}/works/{ID}"><xsl:value-of select="uniform_title" /></a>
  </li>
</xsl:template>

</xsl:stylesheet>