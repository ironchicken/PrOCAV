<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="globals.xsl" />

<xsl:output method="html" />

<xsl:variable name="terms" select="//request/params[name='terms']/value" />

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>PrOCAV: Search: <xsl:value-of select="$terms" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <div id="body">
      <xsl:call-template name="page-menu" />
      <div id="container">
        <div class="main-content">
          <h2>Search for "<xsl:value-of select="$terms" />"</h2>
          <p>
            Your search for "<xsl:value-of select="$terms" />"
            returned <xsl:value-of select="//hits" />
            result(s).
	  </p>
          <p>
            <xsl:choose>
              <xsl:when test="//prev != ''"><a href="/search?terms={$terms}&amp;start={//prev}&amp;limit={//limit}">&lt;&lt;</a></xsl:when>
              <xsl:otherwise>&lt;&lt;</xsl:otherwise>
	    </xsl:choose>
            <xsl:text> </xsl:text>
            <xsl:value-of select="//start" /> to <xsl:value-of select="number(//start) + number(//count) - 1" />
            <xsl:text> </xsl:text>
            <xsl:choose>
              <xsl:when test="//next != ''"><a href="/search?terms={$terms}&amp;start={//next}&amp;limit={//limit}">&gt;&gt;</a></xsl:when>
              <xsl:otherwise>&gt;&gt;</xsl:otherwise>
	    </xsl:choose>
	  </p>
          <ol start="{//start}">
            <xsl:apply-templates select="//result" />
	  </ol>
	</div>
        <xsl:call-template name="user-tools" />
      </div>
    </div>
    <xsl:call-template name="page-footer" />
  </body>    
</html>
</xsl:template>

<xsl:template match="result">
  <li>
    <a href="{uri}"><xsl:value-of select="dc.title" /></a>
    <br />
    <xsl:value-of select="dc.date" />
  </li>
</xsl:template>

</xsl:stylesheet>
