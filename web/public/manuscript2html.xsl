<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:variable name="ID"><xsl:value-of select="$URI_ROOT" />/manuscripts/<xsl:value-of select="/response/content/manuscript/details/ID" /></xsl:variable>

<xsl:template match="/">
<html xmlns:mei="http://www.music-encoding.org/ns/mei"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:foaf="http://xmlns.com/foaf/0.1/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:mo="http://purl.org/ontology/mo/"
      xmlns:moext="http://purl.org/ontology/mo-extended/"
      xmlns:event="http://purl.org/NET/c4dm/event.owl"
      version="HTML+RDFa 1.1" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Serge Prokofiev: manuscript: <xsl:value-of select="//details/title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="DC.title" lang="en" content="{//details/title}" />
    <meta name="DC.creator" content="Serge Prokofiev" />
    <meta name="DC.date" content="{//details/made_year}" />
    <meta name="DC.description" content="A musical manuscript written by Serge Prokofiev entitled {//details/title}." />
    <meta name="DC.identifier" content="{$ID}" />
    <meta name="DC.subject" content="music" />
    <meta name="DC.type" content="mo:Manuscript" />

    <meta name="record-type" content="manuscript" />
    <xsl:comment> noindex </xsl:comment>
    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <xsl:call-template name="page-header" />
    <xsl:call-template name="page-menu" />
    <xsl:call-template name="timeline" />
    <div id="body">
      <xsl:call-template name="browsing-index" />
      <xsl:comment> index </xsl:comment>
      <xsl:apply-templates select="//details" />
      <xsl:comment> noindex </xsl:comment>
    </div>
    <xsl:call-template name="page-footer" />
  </body>    
</html>
</xsl:template>

<xsl:template match="prev_record[ID]">
  <li>
    &lt;&lt; <a href="{$URI_ROOT}/manuscripts/{ID}"><xsl:value-of select="title" /></a>
  </li>
</xsl:template>

<xsl:template match="next_record[ID]">
  <li>
    <a href="{$URI_ROOT}/manuscripts/{ID}"><xsl:value-of select="title" /></a> &gt;&gt;
  </li>
</xsl:template>

<xsl:template match="details">
  <div class="manuscript main-content"
       id="manuscript{ID}"
       about="{$ID}"
       typeof="mo:Manuscript">
    <h2 class="manuscript-title"
	about="{$ID}"
	property="dc:title"
	lang="en"><xsl:value-of select="title" /></h2>

    <div class="details">
      <xsl:apply-templates select="uniform_title" />
      <xsl:apply-templates select="part_of" />
      <xsl:apply-templates select="purpose" />
      <xsl:apply-templates select="physical_size" />
      <xsl:apply-templates select="support" />
      <xsl:apply-templates select="medium" />
      <xsl:apply-templates select="layout" />
      <xsl:apply-templates select="missing" />
      <xsl:apply-templates select="made_year" />
      <xsl:apply-templates select="annotation_of" />

      <xsl:if test="//manuscript/work">
        <div class="field contained-works">
	  <span class="name">Contains works</span>
	  <ul class="content contained-works">
            <xsl:apply-templates select="//work" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:if test="//manuscript/composition">
        <div class="field composition-history">
	  <span class="name">Composition history</span>
	  <ul class="content composition-history">
            <xsl:apply-templates select="//composition" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:if test="//manuscript/in_archive">
        <div class="field location">
	  <span class="name">Location</span>
	  <ul class="content location">
            <xsl:apply-templates select="//in_archive" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:if test="//manuscript/title_source">
        <div class="field title-source">
	  <span class="name">Titles taken from this MS</span>
	  <ul class="content title-source">
            <xsl:apply-templates select="//title_source" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:if test="//manuscript/dedication_source">
        <div class="field dedication-source">
	  <span class="name">Dedications from this MS</span>
	  <ul class="content dedication-source">
            <xsl:apply-templates select="//dedication_source" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:apply-templates select="notes" />
    </div>

    <xsl:if test="//manuscript/letter">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'letters')">+</span> Letters</h3>
      <div class="records" id="letters">
        <xsl:apply-templates select="//letter" />
      </div>
    </xsl:if>

    <xsl:if test="//manuscript/page">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'pages')">+</span> Pages</h3>
      <div class="records" id="pages">
        <xsl:apply-templates select="//page" />
      </div>
    </xsl:if>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/purpose">
  <div class="field manuscript-purpose">
    <span class="name">Purpose</span>
    <span class="content manuscript-purpose"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:purpose"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/physical_size">
  <div class="field manuscript-physical-size">
    <span class="name">Physical size</span>
    <span class="content manuscript-physical-size"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:physical_size"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/support">
  <div class="field manuscript-support">
    <span class="name">Support</span>
    <span class="content manuscript-support"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:support"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/medium">
  <div class="field manuscript-medium">
    <span class="name">Medium</span>
    <span class="content manuscript-medium"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:medium"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/layout">
  <div class="field manuscript-layout">
    <span class="name">Layout</span>
    <span class="content manuscript-layout"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:layout"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/missing[text()='0']" />

<xsl:template match="manuscript/details/missing[text()='1']">
  <div class="field manuscript-missing">
    <span class="name">Missing</span>
    <span class="content manuscript-missing"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:missing">Yes</span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/made_year">
  <div class="field manuscript-date-made">
    <span class="name">Date</span>
    <span class="content manuscript-date-made"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="dc:date"
	  content="http://placetime.com/interval/gregorian/{.}-{../made_month}-{../made_day}T00:00:00Z/P1D">
      <xsl:if test="../made_day">
        <xsl:value-of select="../made_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../made_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../made_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <a href="{$URI_ROOT}/year/{.}"><xsl:value-of select="." /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="manuscript/details/notes">
  <div class="notes">
  <h4>Notes</h4>
    <p><xsl:apply-templates /></p>
  </div>
</xsl:template>

<xsl:template match="manuscript/work">
  <li><a href="{$URI_ROOT}/works/{work_id}"
	 about="{$URI_ROOT}/manuscripts/{../ID}"
	 rel="mo:manuscript"
	 resource="{$URI_ROOT}/works/{../work_id}"><xsl:value-of select="uniform_title" /></a> [<xsl:value-of select="work_extent" />]</li>
</xsl:template>

<xsl:template match="manuscript/in_archive">
  <li><a href="{$URI_ROOT}/archives/{archive_id}"><xsl:value-of select="archive" /></a></li>
</xsl:template>

<xsl:template match="manuscript/page">
  <div class="record page"
       id="page{document_page_id}"
       about="{$URI_ROOT}/page/{document_page_id}"
       typeof="composercat:Page"
       rev="mo:page"
       resource="{$ID}">
    <xsl:apply-templates select="page_label" />
    <xsl:apply-templates select="extent" />
    <xsl:apply-templates select="path" />
    <xsl:apply-templates select="notes" />
  </div>
</xsl:template>

<xsl:template match="page/page_label">
  <div class="field reference">
    <span class="name">Reference</span>
    <span class="content reference"
	  about="{$URI_ROOT}/pages/{../document_page_id}"
	  property="dc:identifier">
      <xsl:if test="../gparent_aggr_label"><a href="{$URI_ROOT}/archives?aggregation={../gparent_aggr_id}"><xsl:value-of select="../gparent_aggr_label" /></a> / </xsl:if>
      <xsl:if test="../parent_aggr_label"><a href="{$URI_ROOT}/archives?aggregation={../parent_aggr_id}"><xsl:value-of select="../parent_aggr_label" /></a> / </xsl:if>
      <xsl:apply-templates />
    </span>
  </div>
</xsl:template>

<xsl:template match="page/extent">
  <div class="field extent">
    <span class="name">Extent</span>
    <span class="content extent"
	  about="{$URI_ROOT}/pages/{../document_page_id}"
	  property="dc:extent"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="page/path">
  <div class="field {../relation}">
    <span class="name">Content</span>
    <span class="content {../relation}"
	  about="{$URI_ROOT}/pages/{../document_page_id}"
	  property="composercat:{../relation}"><img src="{$URI_ROOT}/show_media/{../media_id}" alt="media item not available" /></span>
  </div>
</xsl:template>

</xsl:stylesheet>
