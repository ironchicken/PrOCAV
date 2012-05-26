<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:variable name="ID"><xsl:value-of select="$URI_ROOT" />/archives/<xsl:value-of select="/response/content/archive/details/ID" /></xsl:variable>

<xsl:template match="/">
<html xmlns:mei="http://www.music-encoding.org/ns/mei"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:foaf="http://xmlns.com/foaf/0.1/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:mo="http://purl.org/ontology/mo/"
      xmlns:mo-i="http://purl.org/ontology/mo-imaginary/"
      xmlns:event="http://purl.org/NET/c4dm/event.owl"
      version="HTML+RDFa 1.0" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Serge Prokofiev: <xsl:value-of select="//details/title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="record-type" content="archive" />
    <xsl:comment> noindex </xsl:comment>
    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <div id="page">
    <xsl:call-template name="page-header" />
    <div id="body">
      <xsl:call-template name="page-menu" />
      <div id="container">
        <xsl:comment> index </xsl:comment>
        <xsl:apply-templates select="//details" />
        <xsl:comment> noindex </xsl:comment>
        <xsl:call-template name="user-tools" />
      </div>
    </div>
    <xsl:call-template name="page-footer" />
    </div>
  </body>    
</html>
</xsl:template>

<xsl:template match="details">
  <div class="archive main-content"
       id="archive{ID}"
       about="{$ID}"
       typeof="">
    <h2>
      <span class="archive-title"
	    about="{$ID}"
	    property="dc:title"
	    xml:lang="en"><xsl:value-of select="title" /></span>
    </h2>

    <div class="details">
      <xsl:apply-templates select="abbreviation" />
      <xsl:apply-templates select="established" />
      <xsl:apply-templates select="disbanded" />
      <xsl:apply-templates select="location" />
      <xsl:apply-templates select="city" />
      <xsl:apply-templates select="country" />
      <xsl:apply-templates select="uri" />
      <xsl:apply-templates select="email" />
      <xsl:apply-templates select="telephone" />
      <xsl:apply-templates select="notes" />
    </div>

    <xsl:if test="//archive/manuscript">
      <h3>Manuscripts</h3>
      <xsl:apply-templates select="//manuscript" />
    </xsl:if>

    <xsl:if test="//archive/letter">
      <h3>Letters</h3>
      <xsl:apply-templates select="//letter" />
    </xsl:if>
  </div>
</xsl:template>

<xsl:template match="details/abbreviation">
  <div class="field archive-abbreviation">
    <span class="name">Abbreviation</span>
    <span class="content archive-abbreviation"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="details/abbreviation">
  <div class="field archive-abbreviation">
    <span class="name">Abbreviation</span>
    <span class="content archive-abbreviation"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="details/established">
  <div class="field archive-established">
    <span class="name">Established</span>
    <span class="content archive-established"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property="event:time"
	  typeof="time:Interval"
	  content="http://placetime.com/interval/gregorian/{end_year}-{end_month}-{end_day}T00:00:00Z/P1Y">
      <xsl:if test="start_day">
        <xsl:value-of select="start_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="start_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_year"><a href="{$URI_ROOT}/year/{start_year}"><xsl:value-of select="start_year" /></a></xsl:if>

      <xsl:if test="start_year and end_year"><xsl:text> - </xsl:text></xsl:if>

      <xsl:if test="end_day">
        <xsl:value-of select="end_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="end_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_year"><a href="{$URI_ROOT}/year/{end_year}"><xsl:value-of select="end_year" /></a></xsl:if>

      <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
    </span>
  </div>
</xsl:template>

<xsl:template match="details/disbanded">
  <div class="field archive-disbanded">
    <span class="name">Disbanded</span>
    <span class="content archive-disbanded"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property="event:time"
	  typeof="time:Interval"
	  content="http://placetime.com/interval/gregorian/{end_year}-{end_month}-{end_day}T00:00:00Z/P1Y">
      <xsl:if test="start_day">
        <xsl:value-of select="start_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="start_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_year"><a href="{$URI_ROOT}/year/{start_year}"><xsl:value-of select="start_year" /></a></xsl:if>

      <xsl:if test="start_year and end_year"><xsl:text> - </xsl:text></xsl:if>

      <xsl:if test="end_day">
        <xsl:value-of select="end_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="end_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_year"><a href="{$URI_ROOT}/year/{end_year}"><xsl:value-of select="end_year" /></a></xsl:if>

      <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
    </span>
  </div>
</xsl:template>

<xsl:template match="details/location[../latitude and ../longitude]">
  <div class="field archive-location">
    <span class="name">Location</span>
    <span class="content archive-location"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><a href="http://maps.google.com/maps?q={../latitude},{../longitude}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="details/location[not(../latitude) or not(../longitude)]">
  <div class="field archive-location">
    <span class="name">Location</span>
    <span class="content archive-location"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="details/city">
  <div class="field archive-city">
    <span class="name">City</span>
    <span class="content archive-city"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="details/country">
  <div class="field archive-country">
    <span class="name">Country</span>
    <span class="content archive-country"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="details/uri">
  <div class="field archive-uri">
    <span class="name">Web</span>
    <span class="content archive-uri"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><a href="{.}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="details/email">
  <div class="field archive-email">
    <span class="name">Email</span>
    <span class="content archive-email"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><a href="mailto:{.}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="details/telephone">
  <div class="field archive-telephone">
    <span class="name">Telephone</span>
    <span class="content archive-telephone"
	  about="{$URI_ROOT}/archives/{../ID}"
	  property=""><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript">
  <div class="manuscript"
       id="manuscript{ID}"
       about="{$URI_ROOT}/manuscripts/{ID}"
       typeof="mo:Manuscript"
       rev="mo:manuscript"
       resource="{$URI_ROOT}/works/{work_id}">
    <xsl:apply-templates select="archival_ref_str" />
    <xsl:apply-templates select="archival_ref_num" />
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="uniform_title" />
    <xsl:apply-templates select="purpose" />
    <xsl:apply-templates select="phsyical_size" />
    <xsl:apply-templates select="medium" />
    <xsl:apply-templates select="extent" />
    <xsl:apply-templates select="missing" />
    <xsl:apply-templates select="date_made_year" />
    <!-- <xsl:apply-templates select="annotation_of" /> -->
    <xsl:apply-templates select="date_acquired" />
    <xsl:apply-templates select="date_released" />
    <xsl:apply-templates select="access" />
    <xsl:apply-templates select="item_status" />
    <xsl:apply-templates select="copy_type" />
    <xsl:apply-templates select="copyright" />

    <xsl:apply-templates select="notes" />
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/archival_ref_str">
  <div class="field manuscript-archival_ref_str">
    <span class="name">Archival reference</span>
    <span class="content manuscript-archival_ref_str"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:archival_ref_str"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/archival_ref_num[not(../archival_ref_str)]">
  <div class="field manuscript-archival_ref_num">
    <span class="name">Archival reference</span>
    <span class="content manuscript-archival_ref_num"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:archival_ref_num"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/archival_ref_num[../archival_ref_str]" />

<xsl:template match="archive/manuscript/title">
  <div class="field manuscript-title">
    <span class="name">Manuscript title</span>
    <span class="content manuscript-title"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="dc:title"><a href="{$URI_ROOT}/manuscripts/{../ID}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/uniform_title">
  <div class="field manuscript-work-uniform_title">
    <span class="name">Work</span>
    <span class="content manuscript-work-uniform_title"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property=""><a href="{$URI_ROOT}/works/{../work_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/purpose">
  <div class="field manuscript-purpose">
    <span class="name">Purpose</span>
    <span class="content manuscript-purpose"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:purpose"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/phsyical_size">
  <div class="field manuscript-phsyical-size">
    <span class="name">Phsyical_Size</span>
    <span class="content manuscript-phsyical-size"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:phsyical_size"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/medium">
  <div class="field manuscript-medium">
    <span class="name">Medium</span>
    <span class="content manuscript-medium"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:medium"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/extent">
  <div class="field manuscript-extent">
    <span class="name">Extent</span>
    <span class="content manuscript-extent"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:extent"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/missing[text()='0']" />

<xsl:template match="archive/manuscript/missing[text()='1']">
  <div class="field manuscript-missing">
    <span class="name">Missing</span>
    <span class="content manuscript-missing"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:missing">Yes</span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/date_made_year">
  <div class="field manuscript-date-made">
    <span class="name">Date</span>
    <span class="content manuscript-date-made"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="dc:date">
      <xsl:if test="../date_made_day">
        <xsl:value-of select="../date_made_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../date_made_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../date_made_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <a href="{$URI_ROOT}/year/{.}"><xsl:value-of select="." /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/date_acquired">
  <div class="field manuscript-date_acquired">
    <span class="name">Date acquired</span>
    <span class="content manuscript-date_acquired"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="event:time"
	  typeof="time:Interval"
	  content="http://placetime.com/interval/gregorian/{end_year}-{end_month}-{end_day}T00:00:00Z/P1Y">
      <xsl:if test="start_day">
        <xsl:value-of select="start_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="start_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_year"><a href="{$URI_ROOT}/year/{start_year}"><xsl:value-of select="start_year" /></a></xsl:if>

      <xsl:if test="start_year and end_year"><xsl:text> - </xsl:text></xsl:if>

      <xsl:if test="end_day">
        <xsl:value-of select="end_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="end_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_year"><a href="{$URI_ROOT}/year/{end_year}"><xsl:value-of select="end_year" /></a></xsl:if>

      <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
    </span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/date_released">
  <div class="field manuscript-date_released">
    <span class="name">Date released</span>
    <span class="content manuscript-date_released"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="event:time"
	  typeof="time:Interval"
	  content="http://placetime.com/interval/gregorian/{end_year}-{end_month}-{end_day}T00:00:00Z/P1Y">
      <xsl:if test="start_day">
        <xsl:value-of select="start_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="start_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="start_year"><a href="{$URI_ROOT}/year/{start_year}"><xsl:value-of select="start_year" /></a></xsl:if>

      <xsl:if test="start_year and end_year"><xsl:text> - </xsl:text></xsl:if>

      <xsl:if test="end_day">
        <xsl:value-of select="end_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="end_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="end_year"><a href="{$URI_ROOT}/year/{end_year}"><xsl:value-of select="end_year" /></a></xsl:if>

      <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
    </span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/access">
  <div class="field manuscript-access">
    <span class="name">Access</span>
    <span class="content manuscript-access"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:access"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/item_status">
  <div class="field manuscript-item_status">
    <span class="name">Status</span>
    <span class="content manuscript-item_status"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:item_status"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/copy_type">
  <div class="field manuscript-copy_type">
    <span class="name">Copy type</span>
    <span class="content manuscript-copy_type"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:copy_type"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/copyright">
  <div class="field manuscript-copyright">
    <span class="name">Copyright</span>
    <span class="content manuscript-copyright"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:copyright"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="archive/manuscript/notes">
  <div class="field manuscript-notes">
    <span class="name">Notes</span>
    <p class="content manuscript-notes"
       about="{$URI_ROOT}/manuscripts/{../ID}"
       property="composercat:notes"><xsl:apply-templates /></p>
  </div>
</xsl:template>

</xsl:stylesheet>
