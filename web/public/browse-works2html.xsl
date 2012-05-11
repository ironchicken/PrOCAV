<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

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
    <title>Prokofiev Catalogue and Digital Archive: browse works</title>

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
          <h2>Browse works</h2>
          <p>
            Browsing for works where <xsl:value-of
            select="$param-name" /> is <xsl:value-of
            select="//params[name='cmp']/value" /> "<xsl:value-of
            select="$param-value" />". <xsl:value-of select="//total"
            /> records match.
	  </p>
          <p>
            <xsl:choose>
              <xsl:when test="//prev != ''"><a href="/works?{$cmp}{$param-name}={$param-value}&amp;start={//prev}&amp;limit={//limit}">&lt;&lt;</a></xsl:when>
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
              <xsl:when test="//next != ''"><a href="/works?{$cmp}{$param-name}={$param-value}&amp;start={//next}&amp;limit={//limit}">&gt;&gt;</a></xsl:when>
              <xsl:otherwise>&gt;&gt;</xsl:otherwise>
	    </xsl:choose>
	  </p>
          <ol class="main-content" start="{//start}">
            <xsl:apply-templates select="//work" />
	  </ol>
          <xsl:call-template name="user-tools" />
	</div>
      </div>
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