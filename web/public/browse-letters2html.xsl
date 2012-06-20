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
    <title>Prokofiev Catalogue and Digital Archive: browse letters</title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <xsl:call-template name="page-menu" />
    <xsl:call-template name="timeline" />
    <div id="body">
      <h2>Browse letters</h2>
      <p>
        Browsing for letters where <xsl:value-of
	select="$param-name" /> is <xsl:value-of
	select="//params[name='cmp']/value" /> "<xsl:value-of
	select="$param-value" />". <xsl:value-of select="//total"
	/> records match.
      </p>
      <p>
        <xsl:choose>
          <xsl:when test="//prev != ''"><a href="/letters?{$cmp}{$param-name}={$param-value}&amp;start={//prev}&amp;limit={//limit}">&lt;&lt;</a></xsl:when>
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
          <xsl:when test="//next != ''"><a href="/letters?{$cmp}{$param-name}={$param-value}&amp;start={//next}&amp;limit={//limit}">&gt;&gt;</a></xsl:when>
          <xsl:otherwise>&gt;&gt;</xsl:otherwise>
	</xsl:choose>
      </p>
      <ol class="main-content" start="{//start}">
        <xsl:choose>
          <xsl:when test="//param[name='order_by']/value='date'">
            <xsl:apply-templates select="//letter[composed_year!='']" mode="by-date" />
	  </xsl:when>
          <xsl:when test="//param[name='order_by']/value='addressee'">
            <xsl:apply-templates select="//letter" mode="by-addressee" />
	  </xsl:when>
          <xsl:when test="//param[name='order_by']/value='sender'">
            <xsl:apply-templates select="//letter" mode="by-sender" />
	  </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="//letter" mode="by-date" />
	  </xsl:otherwise>
	</xsl:choose>
      </ol>
    </div>
    <xsl:call-template name="page-footer" />
  </body>    
</html>
</xsl:template>

<xsl:template match="letter" mode="by-date">
  <li>
    <a href="{$URI_ROOT}/letters/{document_id}">
      <xsl:value-of select="composed_day" />
      <xsl:call-template name="month"><xsl:with-param name="month" select="composed_month" /></xsl:call-template>
      <xsl:value-of select="composed_year" />
    </a>
    <br /><xsl:value-of select="addressee_given_name" /> <xsl:value-of select="addressee_family_name" />
    <br /><xsl:value-of select="recipient_address" />
  </li>
</xsl:template>

<xsl:template match="letter" mode="by-addressee">
  <li>
    <a href="{$URI_ROOT}/letters/{document_id}">
      <xsl:value-of select="addressee_family_name" />, <xsl:value-of select="addressee_given_name" />
    </a>
    <br /><xsl:value-of select="composed_day" />
    <xsl:call-template name="month"><xsl:with-param name="month" select="composed_month" /></xsl:call-template>
    <xsl:value-of select="composed_year" />
    <br /><xsl:value-of select="recipient_address" />
  </li>
</xsl:template>

<xsl:template match="letter" mode="by-sender">
  <li>
    <a href="{$URI_ROOT}/letters/{document_id}">
      <xsl:value-of select="sender_family_name" />, <xsl:value-of select="sender_given_name" />
    </a>
    <br /><xsl:value-of select="composed_day" />
    <xsl:call-template name="month"><xsl:with-param name="month" select="composed_month" /></xsl:call-template>
    <xsl:value-of select="composed_year" />
    <br /><xsl:value-of select="recipient_address" />
  </li>
</xsl:template>

</xsl:stylesheet>