<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:variable name="ID"><xsl:value-of select="$URI_ROOT" />/works/<xsl:value-of select="/response/content/work/details/ID" /></xsl:variable>

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
    <title>Serge Prokofiev: <xsl:value-of select="//details/uniform_title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="DC.title" lang="en" content="{//details/uniform_title}" />
    <meta name="DC.creator" content="Serge Prokofiev" />
    <meta name="DC.date" content="{//composition[last()]/end_year}" />
    <meta name="DC.description" content="The musical work entitled {//details/uniform_title} composed by Serge Prokofiev." />
    <meta name="DC.identifier" content="{$ID}" />
    <meta name="DC.subject" content="music" />
    <meta name="DC.type" content="mo:MusicalWork" />

    <meta name="record-type" content="work" />
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
    &lt;&lt; <a href="{$URI_ROOT}/works/{ID}"><xsl:value-of select="uniform_title" /><xsl:text> </xsl:text>
    <xsl:value-of select="catalogue" />
    <xsl:value-of select="catalogue_number" /></a>
  </li>
</xsl:template>

<xsl:template match="next_record[ID]">
  <li>
   <a href="{$URI_ROOT}/works/{ID}"><xsl:value-of select="uniform_title" /><xsl:text> </xsl:text>
    <xsl:value-of select="catalogue" />
    <xsl:value-of select="catalogue_number" /></a> &gt;&gt;
  </li>
</xsl:template>

<xsl:template match="details">
  <div class="work main-content"
       id="work{ID}"
       about="{$ID}"
       typeof="mo:MusicalWork">
    <h2>
      <span class="work-title"
	    about="{$ID}"
	    property="dc:title"
	    lang="en"><xsl:value-of select="uniform_title" /></span>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="//catalogue_number[label/text()='Op. '][1]" />
    </h2>

    <div class="details">
      <xsl:if test="//work/title">
        <div class="field title">
  	  <span class="name">Titles</span>
	  <ul class="content title">
            <xsl:apply-templates select="//work/title" />
	  </ul>
        </div>
      </xsl:if>

      <div class="field composer">
        <span class="name">Composer</span>
        <span class="content composer"
	      about="http://dbpedia.org/page/Sergei_Prokofiev"
	      typeof="foaf:Agent"
	      rel="mo:composer"
	      resource="{$ID}">Serge Prokofiev</span>
      </div>

      <xsl:if test="//work/genre">
        <div class="field genre">
	  <span class="name">Genre</span>
	  <ul class="content genre">
            <xsl:apply-templates select="//work/genre" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:if test="//work/composition">
        <div class="field composition-history">
	  <span class="name">Composition history</span>
	  <ul class="content composition-history">
          <xsl:apply-templates select="//composition" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:if test="//work/scored_for">
        <div class="field instrumentation">
	  <span class="name">Instrumentation</span>
	  <ul class="content instrumentation">
            <xsl:apply-templates select="//scored_for" />
	  </ul>
        </div>
      </xsl:if>

      <xsl:apply-templates select="notes" />
    </div>

    <xsl:if test="//work/sub_work">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'sub-works')">+</span> <xsl:call-template name="sub-works-type" /></h3>
      <div class="records" id="sub-works">
        <xsl:apply-templates select="//sub_work" />
      </div>
    </xsl:if>

    <xsl:if test="//work/manuscript">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'manuscripts')">+</span> Manuscripts</h3>
      <div class="records" id="manuscripts">
        <xsl:apply-templates select="//manuscript" />
      </div>
    </xsl:if>

    <xsl:if test="//work/publication">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'publications')">+</span> Publications</h3>
      <div class="records" id="publications">
        <xsl:apply-templates select="//publication" />
      </div>
    </xsl:if>

    <xsl:if test="//work/performance">
      <h3><span class="records-toggle"
		onclick="composerCat.toggleRecords(event, 'performances')">+</span> Performances</h3>
      <div class="records" id="performances">
        <xsl:apply-templates select="//performance" />
      </div>
    </xsl:if>
  </div>
</xsl:template>

<xsl:template match="work/catalogue_number[label/text()='Op. ']">
  <span class="opus-number"
	about="{$ID}"
	property="dc:identifier mo:opus"><xsl:value-of select="label" /> <xsl:value-of select="number" /></span>
</xsl:template>

<xsl:template match="work/title">
  <li class="title"
      about="{$URI_ROOT}/titles/{ID}"
      rev="dc:title"
      resource="{$ID}"
      content="{title}"
      lang="{language}">
    <xsl:value-of select="title" />
    <xsl:if test="transliteration"> (<xsl:apply-templates select="transliteration" />)</xsl:if>
    <xsl:if test="language"> [<xsl:apply-templates select="language" />]</xsl:if>
    <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
  </li>
</xsl:template>

<xsl:template match="work/composition">
  <li class="composition"
      about="{$URI_ROOT}/composition/{ID}"
      typeof="mo:Composition"
      rel="mo:produced_work"
      resource="{$ID}">
    <span class="content work-type"
	  about="{$ID}/composition/{ID}"
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

      <xsl:if test="work_type">; <xsl:apply-templates select="work_type" /></xsl:if>

      <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
    </span>
  </li>
</xsl:template>

<xsl:template match="work/scored_for">
  <xsl:variable name="scored_for"><xsl:value-of select="$ID" />#<xsl:if test="cardinality='solo'">solo_</xsl:if><xsl:value-of select="instrument" /><xsl:if test="role">_<xsl:value-of select="role" /></xsl:if></xsl:variable>

  <li class="instrument"
      about="{$scored_for}"
      rev="moext:scored_for"
      resource="{$ID}"
      typeof="mo:Instrument"
      content="http://purl.org/ontology/taxonomy-a/mita#{instrument}">
    <xsl:choose>
      <xsl:when test="cardinality='solo'">
        <span about="{$scored_for}" property="moext:instrument_forces"><xsl:value-of select="cardinality" /></span>
        <xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <span about="{$scored_for}" property="moext:instrument_forces" content="{cardinality}" style="display:none"><xsl:value-of select="cardinality" /></span>
      </xsl:otherwise>
    </xsl:choose>
    <span about="{$scored_for}" property="moext:instrument_role"><xsl:value-of select="role" /></span>
    <xsl:text> </xsl:text>
    <a href="{$URI_ROOT}/works?scored_for={instrument}"><xsl:value-of select="instrument" /></a>
    <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
  </li>
</xsl:template>

<xsl:template match="work/genre">
  <li class="genre"
      about="{$ID}#{genre}"
      rev="mo:genre"
      resource="{$ID}"
      typeof="mo:Genre"
      content="http://dbpedia.org/page/{genre}"> <!-- FIXME Use a linked resources table record, not this simple substitutio -->
    <a href="{$URI_ROOT}/works?genre={genre}"><xsl:value-of select="genre" /></a>
    <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
  </li>
</xsl:template>

<xsl:template match="work/details/notes">
  <div class="notes">
  <h4>Notes</h4>
    <p><xsl:apply-templates /></p>
  </div>
</xsl:template>

<xsl:template match="work/sub_work">
  <xsl:variable name="sub_work_id">w<xsl:value-of select="//work/ID" />#p<xsl:value-of select="part_position" /></xsl:variable>
  <div class="work-part"
       id="{$sub_work_id}"
       about="{$ID}/{part_position}"
       typeof="mo:Movement"
       rev="mo:movement"
       resource="{$ID}">
    <h4>
      <span class="movement-number"
	    about="{$ID}/{part_position}"
	    property="mo:movement_number"
	    datatype="xsd:int"
	    content="{part_position}"><xsl:value-of select="part_number" /></span>
      <xsl:text> </xsl:text>
      <span class="movement-title"
	    about="{$ID}/{part_position}"
	    property="dc:title"
	    lang="en"><xsl:value-of select="uniform_title" /></span>
    </h4>
  </div>
</xsl:template>

<xsl:template match="work/manuscript">
  <div class="record manuscript"
       id="manuscript{ID}"
       about="{$URI_ROOT}/manuscripts/{ID}"
       typeof="mo:Manuscript"
       rev="mo:manuscript"
       resource="{$ID}">
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="purpose" />
    <xsl:apply-templates select="physical_size" />
    <xsl:apply-templates select="medium" />
    <xsl:apply-templates select="extent" />
    <xsl:apply-templates select="missing" />
    <xsl:apply-templates select="date_made_year" />
    <!-- <xsl:apply-templates select="annotation_of" /> -->
    <xsl:apply-templates select="archive|archive_abbr" />
    <xsl:apply-templates select="notes" />
  </div>
</xsl:template>

<xsl:template match="work/manuscript/title">
  <div class="field manuscript-title">
    <span class="name">Title</span>
    <span class="content manuscript-title"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="dc:title"
	  content="{.}"><a href="{$URI_ROOT}/manuscripts/{../ID}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/purpose">
  <div class="field manuscript-purpose">
    <span class="name">Purpose</span>
    <span class="content manuscript-purpose"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:purpose"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/physical_size">
  <div class="field manuscript-physical-size">
    <span class="name">Physical size</span>
    <span class="content manuscript-physical-size"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:physical_size"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/support">
  <div class="field manuscript-support">
    <span class="name">Support</span>
    <span class="content manuscript-support"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:support"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/medium">
  <div class="field manuscript-medium">
    <span class="name">Medium</span>
    <span class="content manuscript-medium"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:medium"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/layout">
  <div class="field manuscript-layout">
    <span class="name">Layout</span>
    <span class="content manuscript-layout"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:layout"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/missing[text()='0']" />

<xsl:template match="work/manuscript/missing[text()='1']">
  <div class="field manuscript-missing">
    <span class="name">Missing</span>
    <span class="content manuscript-missing"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:missing">Yes</span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/date_made_year">
  <div class="field manuscript-date-made">
    <span class="name">Date</span>
    <span class="content manuscript-date-made"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="dc:date"
	  content="http://placetime.com/interval/gregorian/{.}-{../date_made_month}-{../date_made_day}T00:00:00Z/P1D">
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

<xsl:template match="work/manuscript/archive">
  <div class="field manuscript-location">
    <span class="name">Location</span>
    <span class="content manuscript-location"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:location"
	  content="{.}"><a href="{$URI_ROOT}/archives/{../archive_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/archive_abbr[not(../archive)]">
  <div class="field manuscript-location">
    <span class="name">Location</span>
    <span class="content manuscript-location"
	  about="{$URI_ROOT}/manuscripts/{../ID}"
	  property="composercat:location"
	  content="{.}"><a href="{$URI_ROOT}/archives/{../archive_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="work/manuscript/archive_abbr[../archive]" />

<xsl:template match="work/manuscript/notes">
  <div class="field manuscript-notes">
    <span class="name">Notes</span>
    <p class="content manuscript-notes"
       about="{$URI_ROOT}/manuscripts/{../ID}"
       property="composercat:notes"><xsl:apply-templates /></p>
  </div>
</xsl:template>

<xsl:template match="work/publication">
  <div class="record publication"
       id="publication{ID}"
       about="{$URI_ROOT}/publications/{ID}"
       typeof="mo:Publication"
       rev="mo:publication"
       resource="{$ID}">
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="publisher" />
    <xsl:apply-templates select="publication_place" />
    <xsl:apply-templates select="pub_date_year" />
    <xsl:apply-templates select="serial_number" />
    <xsl:apply-templates select="score_type" />
    <!-- <xsl:apply-templates select="edition_extent" /> -->
    <!-- <xsl:apply-templates select="publication_range" /> -->
    <xsl:apply-templates select="notes" />
  </div>
</xsl:template>

<xsl:template match="work/publication/title">
  <div class="field publication-title">
    <span class="name">Title</span>
    <span class="content publication-title"
	  about="{$URI_ROOT}/publications/{../ID}"
	  property="dc:title"
	  content="{.}"><a href="{$URI_ROOT}/publications/{../ID}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="work/publication/publisher">
  <div class="field publication-publisher">
    <span class="name">Publisher</span>
    <span class="content publication-publisher"
	  about="{$URI_ROOT}/publications/{../ID}"
	  property="composercat:publisher"
	  content="{.}">
      <a href="{$URI_ROOT}/publications?publisher={.}"><xsl:apply-templates /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="work/publication/publication_place">
  <div class="field publication-publication-place">
    <span class="name">Publication place</span>
    <span class="content publication-publication-place"
	  about="{$URI_ROOT}/publications/{../ID}"
	  property="composercat:publication_place"
	  content="{.}">
      <a href="{$URI_ROOT}/places/{.}"><xsl:apply-templates /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="work/publication/pub_date_year">
  <div class="field publication-pub-date">
    <span class="name">Date</span>
    <span class="content publication-pub-date"
	  about="{$URI_ROOT}/publications/{../ID}"
	  property="dc:date"
	  content="http://placetime.com/interval/gregorian/{.}-{../pub_date_month}-{../pub_date_day}T00:00:00Z/P1D">
      <xsl:if test="../pub_date_day">
        <xsl:value-of select="../pub_date_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../pub_date_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../pub_date_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <a href="{$URI_ROOT}/year/{.}"><xsl:value-of select="." /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="work/publication/serial_number">
  <div class="field publication-serial-number">
    <span class="name">Serial number</span>
    <span class="content publication-serial-number"
	  about="{$URI_ROOT}/publications/{../ID}"
	  property="composercat:serial_number"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/publication/score_type">
  <div class="field publication-score-type">
    <span class="name">Score type</span>
    <span class="content publication-score-type"
	  about="{$URI_ROOT}/publications/{../ID}"
	  property="composercat:score_type"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="work/publication/notes">
  <div class="field publication-notes">
    <span class="name">Notes</span>
    <p class="content publication-notes"
       about="{$URI_ROOT}/publications/{../ID}"
       property="composercat:notes"><xsl:apply-templates /></p>
  </div>
</xsl:template>

<xsl:template match="work/performance">
  <div class="record performance"
       id="performance{ID}"
       about="{$URI_ROOT}/performances/{ID}"
       typeof="mo:Performance"
       rev="mo:performance"
       resource="{$ID}">
    <xsl:apply-templates select="performed_year" />
    <xsl:apply-templates select="performance_type" />
    <xsl:apply-templates select="venue" />
    <xsl:apply-templates select="notes" />
  </div>
</xsl:template>

<xsl:template match="work/performance/performed_year">
  <div class="field performance-performed">
    <span class="name">Date</span>
    <span class="content performance-performed"
	  about="{$URI_ROOT}/performances/{../ID}"
	  property="dc:date"
	  content="http://placetime.com/interval/gregorian/{.}-{../performed_month}-{../performed_day}T00:00:00Z/P1D">
      <xsl:if test="../performed_day">
        <xsl:value-of select="../performed_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../performed_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../performed_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <a href="{$URI_ROOT}/year/{.}"><xsl:value-of select="." /></a>
    </span>
  </div>
</xsl:template>

<xsl:template match="work/performance/venue">
  <div class="field performance-venue">
    <span class="name">Venue</span>
    <span class="content performance-venue"
	  about="{$URI_ROOT}/venues/{../venue_id}"
	  rev="composercat:venue"
	  resource="{$URI_ROOT}/performances/{../ID}">
      <a href="{$URI_ROOT}/venues/{../venue_id}"><xsl:apply-templates /></a>
      <xsl:if test="../city">
        <xsl:text>, </xsl:text>
        <span about="{$URI_ROOT}/venues/{../venue_id}"
	      property="composercat:city"
	      content="{../city}"><a href="{$URI_ROOT}/places/{../city}"><xsl:value-of select="../city" /></a></span>
      </xsl:if>
      <xsl:if test="../country">
        <xsl:text>, </xsl:text>
        <span about="{$URI_ROOT}/venues/{../venue_id}"
	      property="composercat:country"
	      content="{../country}"><a href="{$URI_ROOT}/places/{../country}"><xsl:value-of select="../country" /></a></span>
      </xsl:if>
      <xsl:if test="../venue_type">
        <xsl:text> (</xsl:text>
        <span about="{$URI_ROOT}/venues/{../venue_id}"
	      property="composercat:venue_type"><xsl:value-of select="../venue_type" /></span>
        <xsl:text>)</xsl:text>
      </xsl:if>
    </span>
  </div>
</xsl:template>

<xsl:template match="work/performance/performance_type">
  <div class="field performance-performance-type">
    <span class="name">Performance type</span>
    <span class="content performance-performance-type"
	  about="{$URI_ROOT}/performances/{../ID}"
	  property="composercat:performance_type"
	  content="{.}"><a href="{$URI_ROOT}/performances/{../ID}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="work/performance/notes">
  <div class="field performance-notes">
    <span class="name">Notes</span>
    <p class="content performance-notes"
       about="{$URI_ROOT}/performances/{../ID}"
       property="composercat:notes"><xsl:apply-templates /></p>
  </div>
</xsl:template>

<xsl:template name="sub-works-type">
  <xsl:choose>
    <xsl:when test="//genre[1]/genre/text()='opera'">Acts</xsl:when>
    <xsl:when test="//genre[1]/genre/text()='ballet'">Acts</xsl:when>
    <xsl:otherwise>Movements</xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>