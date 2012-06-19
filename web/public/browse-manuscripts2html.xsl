<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:variable
    name="param-name"
    select="//params[name != 'submit' and name != 'accept' and name != 'cmp' and name != 'start' and name != 'limit'][1]/name" />

<xsl:variable
    name="param-value"
    select="//params[name != 'submit' and name != 'accept' and name != 'cmp' and name != 'start' and name != 'limit'][1]/value" />

<xsl:variable name="cmp"><xsl:if test="//params[name='cmp']">cmp=<xsl:value-of select="//params[name='cmp']/value" />&amp;</xsl:if></xsl:variable>

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Prokofiev Catalogue and Digital Archive: browse manuscripts</title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <xsl:call-template name="page-menu" />
    <xsl:call-template name="timeline" />
    <div id="body">
      <h2>Browse manuscripts</h2>
      <p>
        Browsing for manuscripts where <xsl:value-of
	select="$param-name" /> is <xsl:value-of
	select="//params[name='cmp']/value" /> "<xsl:value-of
	select="$param-value" />". <xsl:value-of select="//total"
	/> records match.
      </p>
      <p>
        <xsl:choose>
          <xsl:when test="//prev != ''"><a href="/manuscripts?{$cmp}{$param-name}={$param-value}&amp;start={//prev}&amp;limit={//limit}">&lt;&lt;</a></xsl:when>
          <xsl:otherwise>&lt;&lt;</xsl:otherwise>
	</xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="//start != ''">
            <xsl:value-of select="//start" /> to <xsl:value-of select="number(//start) + number(//count) - 1" />
	  </xsl:when>
          <xsl:otherwise>
	    1 to <xsl:value-of select="//count" />
	  </xsl:otherwise>
	</xsl:choose>
        <xsl:text> </xsl:text>
        <xsl:choose>
          <xsl:when test="//next != ''"><a href="/manuscripts?{$cmp}{$param-name}={$param-value}&amp;start={//next}&amp;limit={//limit}">&gt;&gt;</a></xsl:when>
          <xsl:otherwise>&gt;&gt;</xsl:otherwise>
	</xsl:choose>
      </p>
      <ol class="main-content" start="{//start}">
        <xsl:apply-templates select="//manuscript" />
      </ol>
    </div>
    <xsl:call-template name="page-footer" />
  </body>    
</html>
</xsl:template>

<xsl:template match="manuscript">
  <li>
    <a href="{$URI_ROOT}/manuscripts/{document_id}"><xsl:value-of select="title" /></a>
    <br /><xsl:if test="made_year!=''"><xsl:value-of select="made_year" />; </xsl:if>
    <xsl:if test="purpose!=''"><xsl:value-of select="purpose" /></xsl:if>
  </li>
</xsl:template>

</xsl:stylesheet>