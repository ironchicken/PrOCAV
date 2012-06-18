<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:str="http://exslt.org/strings"
   extension-element-prefixes="str"
   version="1.0">

<xsl:import href="str.replace.xsl" />
<xsl:import href="globals.xsl" />

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Prokofiev Catalogue and Digital Archive: <xsl:value-of select="/document/head/title" /></title>
    <meta name="created" value="{/document/head/created}" />
    <meta name="modified" value="{/document/head/modified}" />

    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <xsl:call-template name="page-menu" />
    <xsl:call-template name="timeline" />
    <div id="body">
      <h2><xsl:value-of select="/document/head/title" /></h2>
      <xsl:apply-templates select="//body" />
    </div>
    <xsl:call-template name="page-footer">
      <xsl:with-param name="logos">yes</xsl:with-param>
    </xsl:call-template>
  </body>    
</html>
</xsl:template>

<xsl:template match="body//*">
  <xsl:element name="{name()}">
    <xsl:for-each select="@*">
      <xsl:attribute name="{name()}"><xsl:value-of select="str:replace(string(.), '{$URI_ROOT}', string($URI_ROOT))" /></xsl:attribute>
    </xsl:for-each>
    <xsl:apply-templates />
  </xsl:element>
</xsl:template>

</xsl:stylesheet>
