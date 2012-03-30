<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

<xsl:include href="globals.xsl" />

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Serge Prokofiev: <xsl:value-of select="//details/uniform_title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <div id="content">
      <ol>
        <xsl:apply-templates select="//work" />
      </ol>
    </div>
    <xsl:call-template name="page-footer" />
  </body>    
</html>
</xsl:template>

<xsl:template match="work">
  <li>
    <a href="{$URI_ROOT}/works/{ID}"><xsl:value-of select="uniform_title" /></a><xsl:text> </xsl:text>
    <xsl:value-of select="catalogue" />
    <xsl:value-of select="catalogue_number" />
    (<xsl:value-of select="year" />)
  </li>
</xsl:template>

</xsl:stylesheet>