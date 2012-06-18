<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Prokofiev Catalogue and Digital Archive: <xsl:value-of select="//error_code" /></title>

    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <xsl:call-template name="page-menu" />
    <xsl:call-template name="timeline" />
    <div id="body">
      <h2><xsl:value-of select="//error_code" /><xsl:text> </xsl:text><xsl:value-of select="//error_desc" /></h2>
      <p>
        <xsl:value-of select="//reason" />
      </p>
      <p>
        Please note that this catalogue is still under active
        development meaning both that some features of the
        infrastructure are missing and also that some resources have
        not yet been catalogued.
      </p>
    </div>
    <xsl:call-template name="page-footer" />
  </body>    
</html>
</xsl:template>

</xsl:stylesheet>