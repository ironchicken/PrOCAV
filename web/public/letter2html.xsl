<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:variable name="ID"><xsl:value-of select="$URI_ROOT" />/letters/<xsl:value-of select="/response/content/letter/details/ID" /></xsl:variable>

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
    <title>Serge Prokofiev: letter: <xsl:value-of select="//details/title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="DC.title" lang="en" content="{//details/title}" />
    <meta name="DC.creator" content="Serge Prokofiev" />
    <meta name="DC.date" content="{//details/composed_year}-{//details/composed_month}-{//details/composed_day}" />
    <meta name="DC.description" content="A letter of {//details/composed_year}-{//details/composed_month}-{//details/composed_day} written by or concerning Serge Prokofiev." />
    <meta name="DC.identifier" content="{$ID}" />
    <meta name="DC.type" content="composercat:Letter" />

    <meta name="record-type" content="letter" />
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
    &lt;&lt; <a href="{$URI_ROOT}/letters/{ID}"><xsl:value-of select="title" /></a>
  </li>
</xsl:template>

<xsl:template match="next_record[ID]">
  <li>
    <a href="{$URI_ROOT}/letters/{ID}"><xsl:value-of select="title" /></a> &gt;&gt;
  </li>
</xsl:template>

<xsl:template match="details">
  <div class="letter"
       id="letter{ID}"
       about="{$ID}"
       typeof="composercat:Letter">
    <h2 class="manuscript-title"
	about="{$ID}"
	property="dc:title"
	lang="en">Letter of <xsl:value-of select="composed_day" /><xsl:text> </xsl:text><xsl:call-template name="month"><xsl:with-param name="month" select="composed_month" /></xsl:call-template><xsl:text> </xsl:text><xsl:value-of select="composed_year" /></h2>

    <div class="details">
      <xsl:apply-templates select="composed_year" />
      <xsl:apply-templates select="sent_year" />
      <xsl:apply-templates select="addressee_family_name|addressee_given_name" />
      <xsl:apply-templates select="recipient_address" />
      <xsl:apply-templates select="signatory_family_name|signatory_given_name" />
      <xsl:apply-templates select="sender_address" />
      <xsl:apply-templates select="answers_id" />
      <xsl:apply-templates select="archive_abbr|archive" />
      <xsl:apply-templates select="physical_size" />
      <xsl:apply-templates select="support" />
      <xsl:apply-templates select="medium" />
      <xsl:apply-templates select="layout" />
      <xsl:apply-templates select="language" />
      <xsl:apply-templates select="script" />

      <xsl:if test="//letter/mention">
        <div class="field mentioned-entities">
	  <span class="name">Mentions</span>
	  <ul class="content mentioned-entities">
            <xsl:apply-templates select="//mention" />
	  </ul>
        </div>
      </xsl:if>
<!--
      <xsl:if test="//letter/in_archive">
        <div class="field location">
	  <span class="name">Location</span>
	  <ul class="content location">
            <xsl:apply-templates select="//in_archive" />
	  </ul>
        </div>
      </xsl:if>
-->
      <xsl:apply-templates select="notes" />
    </div>

    <xsl:apply-templates select="original_text" />
    <xsl:apply-templates select="english_text" />

    <xsl:if test="//manuscript/letter">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'letters')">+</span> Letters</h3>
      <div class="records" id="letters">
        <xsl:apply-templates select="//letter" />
      </div>
    </xsl:if>

    <xsl:if test="//letter/page">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'pages')">+</span> Pages</h3>
      <div class="records" id="pages">
        <xsl:apply-templates select="//page" />
      </div>
    </xsl:if>
  </div>
</xsl:template>

<xsl:template match="letter/details/composed_year">
  <div class="field letter-date-composed">
    <span class="name">Date composed</span>
    <span class="content letter-date-composed"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="dc:date"
	  content="http://placetime.com/interval/gregorian/{.}-{../composed_month}-{../composed_day}T00:00:00Z/P1D">
      <xsl:if test="../composed_day">
        <xsl:value-of select="../composed_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../composed_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../composed_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <a href="{$URI_ROOT}/year/{.}"><xsl:value-of select="." /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="letter/details/sent_year">
  <div class="field letter-date-sent">
    <span class="name">Date sent</span>
    <span class="content letter-date-sent"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="dc:date"
	  content="http://placetime.com/interval/gregorian/{.}-{../sent_month}-{../sent_day}T00:00:00Z/P1D">
      <xsl:if test="../sent_day">
        <xsl:value-of select="../sent_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../sent_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../sent_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <a href="{$URI_ROOT}/year/{.}"><xsl:value-of select="." /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="letter/details/addressee_family_name">
  <div class="field letter-addressee">
    <span class="name">Addressee</span>
    <span class="content letter-addressee"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:addressee"
          content="{.}"><a href="{$URI_ROOT}/persons/{../addressee_id}"><xsl:value-of select="../addressee_given_name" /> <xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/addressee_given_name[../addressee_family_name]" />
<xsl:template match="letter/details/addressee_given_name[not(../addressee_family_name)]">
  <div class="field letter-addressee">
    <span class="name">Addressee</span>
    <span class="content letter-addressee"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:addressee"
          content="{.}"><a href="{$URI_ROOT}/persons/{../addressee_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/addressee_family_name">
  <div class="field letter-addressee">
    <span class="name">Addressee</span>
    <span class="content letter-addressee"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:addressee"
          content="{.}"><!--<a href="{$URI_ROOT}/persons/{../addressee_id}">--><xsl:value-of select="../addressee_given_name" /><xsl:text> </xsl:text><xsl:apply-templates /><!--</a>--></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/addressee_given_name[../addressee_family_name]" />
<xsl:template match="letter/details/addressee_given_name[not(../addressee_family_name)]">
  <div class="field letter-addressee">
    <span class="name">Addressee</span>
    <span class="content letter-addressee"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:addressee"
          content="{.}"><a href="{$URI_ROOT}/persons/{../addressee_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/signatory_family_name">
  <div class="field letter-signatory">
    <span class="name">Signatory</span>
    <span class="content letter-signatory"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:signatory"
          content="{.}"><!--<a href="{$URI_ROOT}/persons/{../signatory_id}">--><xsl:value-of select="../signatory_given_name" /><xsl:text> </xsl:text><xsl:apply-templates /><!--</a>--></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/signatory_given_name[../signatory_family_name]" />
<xsl:template match="letter/details/signatory_given_name[not(../signatory_family_name)]">
  <div class="field letter-signatory">
    <span class="name">Signatory</span>
    <span class="content letter-signatory"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:signatory"
          content="{.}"><!--<a href="{$URI_ROOT}/persons/{../signatory_id}">--><xsl:apply-templates /><!--</a>--></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/recipient_address">
  <div class="field letter-recipient-address">
    <div class="name">Recipient address</div>
    <div class="content letter-recipient-address"
	 about="{$URI_ROOT}/letters/{../ID}"
	 property="composercat:recipient_address">
      <xsl:apply-templates />
      <xsl:if test="../recipient_town"><br /><xsl:value-of select="../recipient_town" /></xsl:if>
    </div>
  </div>
</xsl:template>

<xsl:template match="letter/details/sender_address">
  <div class="field letter-sender-address">
    <div class="name">Sender address</div>
    <div class="content letter-sender-address"
	 about="{$URI_ROOT}/letters/{../ID}"
	 property="composercat:sender_address">
      <xsl:apply-templates />
      <xsl:if test="../sender_town"><br /><xsl:value-of select="../sender_town" /></xsl:if>
    </div>
  </div>
</xsl:template>

<xsl:template match="letter/details/answers_id">
  <div class="field letter-answer-to">
    <span class="name">Answer to</span>
    <span class="content letter-answer-to"
	  about="{$URI_ROOT}/letters/{../ID}"
	  rel="composercat:letter_answers"
	  resource="{$URI_ROOT}/letters/{.}">
      <a href="{$URI_ROOT}/letters/{.}">
        <xsl:value-of select="../answers_composed_day" />
        <xsl:text> </xsl:text>
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../answers_composed_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:value-of select="../answers_composed_year" />
      </a>
    </span>
  </div>
</xsl:template>

<xsl:template match="letter/details/archive">
  <div class="field letter-location">
    <span class="name">Location</span>
    <span class="content letter-location"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:location"
	  content="{.}"><a href="{$URI_ROOT}/archives/{../archive_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/archive_abbr[not(../archive)]">
  <div class="field letter-location">
    <span class="name">Location</span>
    <span class="content letter-location"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:location"
	  content="{.}"><a href="{$URI_ROOT}/archives/{../archive_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/archive_abbr[../archive]" />

<xsl:template match="letter/details/physical_size">
  <div class="field letter-physical-size">
    <span class="name">Physical size</span>
    <span class="content letter-physical-size"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:physical_size"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/support">
  <div class="field letter-support">
    <span class="name">Support</span>
    <span class="content letter-support"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:support"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/medium">
  <div class="field letter-medium">
    <span class="name">Medium</span>
    <span class="content letter-medium"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:medium"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/layout">
  <div class="field letter-layout">
    <span class="name">Layout</span>
    <span class="content letter-layout"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:layout"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/language">
  <div class="field letter-language">
    <span class="name">Language</span>
    <span class="content letter-language"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="dc:language"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/script">
  <div class="field letter-script">
    <span class="name">Script</span>
    <span class="content letter-script"
	  about="{$URI_ROOT}/letters/{../ID}"
	  property="composercat:script"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="letter/details/notes">
  <div class="notes">
  <h4>Notes</h4>
    <p><xsl:apply-templates /></p>
  </div>
</xsl:template>

<xsl:template match="letter/details/original_text">
  <div class="letter-original-text">
  <h4>Text</h4>
    <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template match="letter/details/english_text">
  <div class="letter-english-text">
  <h4>English text</h4>
    <xsl:apply-templates />
  </div>
</xsl:template>

<xsl:template match="letter/mention">
  <li><a href="{$URI_ROOT}/{mentioned_table}/{mentioned_id}"
	 about="{$URI_ROOT}/letters/{../ID}"
	 rel="mo:letter"
	 resource="{$URI_ROOT}/{mentioned_table}/{mentioned_id}"><xsl:value-of select="mentioned_table" /> #<xsl:value-of select="mentioned_id" /> </a> [<xsl:value-of select="mentioned_extent" />]</li>
</xsl:template>

<!--
<xsl:template match="letter/in_archive">
  <li><a href="{$URI_ROOT}/archives/{archive_id}"><xsl:value-of select="archive" /></a></li>
</xsl:template>
-->

<xsl:template match="letter/page">
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
