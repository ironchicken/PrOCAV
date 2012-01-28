<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" />

<xsl:variable name="URI_ROOT">http://fayrfax.doc.gold.ac.uk</xsl:variable>
<xsl:variable name="ID"><xsl:value-of select="$URI_ROOT" />/works/<xsl:value-of select="/work/details/ID" /></xsl:variable>

<xsl:template match="/">
<html>
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Serge Prokofiev: <xsl:value-of select="//details/uniform_title" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="DC.title" lang="en" content="{//details/uniform_title}" />
    <meta name="DC.creator" content="Serge Prokofiev" />

    <script type="text/javascript" src="jquery-1.6.2.js"> //script </script>
    <script type="text/javascript" src="json2.js"> //script </script>
    <link href="http://fonts.googleapis.com/css?family=Crimson+Text|Droid+Sans" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" type="text/css" href="procav.css" />
  </head>
  <body>
    <h1>Sergei Prokofiev Catalogue</h1>
    <ul id="catalogue-menu">
      <li><a href="#">Home</a></li>
      <li><a href="#">Works</a></li>
      <li><a href="#">Manuscripts</a></li>
      <li><a href="#">Letters</a></li>
      <li><a href="#">Search</a></li>
    </ul>
    <xsl:apply-templates select="//details" />
    <div id="footer">

    </div>
  </body>    
</html>
</xsl:template>

<xsl:template match="details">
  <div class="work"
       id="work{ID}"
       about="{$ID}"
       typeof="mo:MusicalWork">
    <h2>
      <span class="work-title"
	    about="{$ID}"
	    property="dc:title"
	    xml:lang="en"><xsl:value-of select="uniform_title" /></span>
      <xsl:text> </xsl:text>
      <xsl:apply-templates select="//catalogue_numbers[label/text()='Op. '][1]" />
    </h2>

    <xsl:if test="//titles">
      <div class="field title">
	<span class="name">Titles</span>
        <xsl:text>: </xsl:text>
	<ul class="content title">
          <xsl:apply-templates select="//titles" />
	</ul>
      </div>
    </xsl:if>

    <div class="field composer">
      <span class="name">Composer</span>
      <xsl:text>: </xsl:text>
      <span class="content composer"
	    about="http://dbpedia.org/page/Sergei_Prokofiev"
	    typeof="foaf:Agent"
	    rel="mo:composer"
	    resource="{$ID}">Serge Prokofiev</span>
    </div>

    <xsl:if test="//genres">
      <div class="field genre">
	<span class="name">Genre</span>
        <xsl:text>: </xsl:text>
	<ul class="content genre">
          <xsl:apply-templates select="//genres" />
	</ul>
      </div>
    </xsl:if>

    <xsl:if test="//composition">
      <div class="field composition-history">
	<span class="name">Composition history</span>
        <xsl:text>: </xsl:text>
	<ul class="content composition-history">
        <xsl:apply-templates select="//composition">
          <xsl:sort select="end_year" data-type="number" order="ascending" />
          <xsl:sort select="end_month" data-type="number" order="ascending" />
          <xsl:sort select="end_day" data-type="number" order="ascending" />
        </xsl:apply-templates>
	</ul>
      </div>
    </xsl:if>

    <xsl:if test="//scored_for">
      <div class="field instrumentation">
	<span class="name">Instrumentation</span>
        <xsl:text>: </xsl:text>
	<ul class="content instrumentation">
          <xsl:apply-templates select="//scored_for" />
	</ul>
      </div>
    </xsl:if>

    <xsl:if test="//sub_works">
      <h3><xsl:call-template name="sub-works-type" /></h3>
      <xsl:apply-templates select="//sub_works" />
    </xsl:if>

    <div class="notes">
      <xsl:apply-templates select="notes" />
    </div>

    <xsl:if test="//manuscripts">
      <h3>Manuscripts</h3>
      <xsl:apply-templates select="//manuscripts" />
    </xsl:if>

    <xsl:if test="//publications">
      <h3>Publications</h3>
      <xsl:apply-templates select="//publications" />
    </xsl:if>

    <xsl:if test="//performances">
      <h3>Performances</h3>
      <xsl:apply-templates select="//performances" />
    </xsl:if>
  </div>
</xsl:template>

<xsl:template match="catalogue_numbers[label/text()='Op. ']">
  <span class="opus-number"
	about="{$ID}"
	property="dc:identifier mo:opus"><xsl:value-of select="label" /> <xsl:value-of select="number" /></span>
</xsl:template>

<xsl:template match="titles">
  <li class="title"
      about="{$ID}_{ID}"
      rev="dc:title"
      resource="{$ID}"
      xml:lang="{language}">
    <xsl:value-of select="title" />
    <xsl:if test="transliteration"> (<xsl:value-of select="transliteration" />)</xsl:if>
    <xsl:if test="language"> [<xsl:value-of select="language" />]</xsl:if>
    <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
  </li>
</xsl:template>

<xsl:template match="composition">
  <li class="composition"
       about="{$ID}"
       typeof="mo:Composition"
       rel="mo:produced_work"
       resource="{$ID}">
    <span class="work-type"
	  about="{$ID}"
	  property="event:time"
	  typeof="time:Interval"
	  content="http://placetime.com/interval/gregorian/{end_year}-{end_month}-{end_day}T00:00:00Z/P1Y">
      <xsl:if test="start_year"><a href="{$URI_ROOT}/year/{start_year}"><xsl:value-of select="start_year" /></a></xsl:if>
      <xsl:if test="start_year and end_year"><xsl:text> - </xsl:text></xsl:if>
      <xsl:if test="end_year"><a href="{$URI_ROOT}/year/{end_year}"><xsl:value-of select="end_year" /></a></xsl:if>
      <xsl:if test="work_type">; <xsl:value-of select="work_type" /></xsl:if>
      <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
    </span>
  </li>
</xsl:template>

<xsl:template match="scored_for">
  <li class="instrument"
      about="{$ID}_{instrument}"
      rev="mo-i:includes_instrument"
      resource="{$ID}"
      typeof="mo:Instrument"
      content="http://purl.org/ontology/taxonomy-a/mita#{instrument}">
    <xsl:value-of select="role" />
    <xsl:text> </xsl:text>
    <a href="{$URI_ROOT}/works?scored_for={instrument}"><xsl:value-of select="instrument" /></a>
    <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
  </li>
</xsl:template>

<xsl:template match="genres">
  <li class="genre"
      about="{$ID}_{genre}"
      rev="mo:genre"
      resource="{$ID}"
      typeof="mo:Genre">
    <a href="{$URI_ROOT}/works?genre={genre}"><xsl:value-of select="genre" /></a>
    <xsl:if test="notes"><span class="value-notes hidden"><xsl:apply-templates select="notes" /></span></xsl:if>
  </li>
</xsl:template>

<xsl:template match="sub_works">
  <div class="work-part"
       id="work{//work/ID}_m{part_position}"
       about="{$ID}_m{part_position}"
       typeof="mo:Movement"
       rev="mo:movement"
       resource="{$ID}">
    <h4>
      <span class="movement-number"
	    about="{$ID}_m{part_position}"
	    property="mo:movement_number"
	    datatype="xsd:int"
	    content="{part_position}"><xsl:value-of select="part_number" /></span>
      <xsl:text> </xsl:text>
      <span class="movement-title"
	    about="{$ID}_m{part_position}"
	    property="dc:title"
	    xml:lang="en"><xsl:value-of select="uniform_title" /></span>
    </h4>
  </div>
</xsl:template>

<xsl:template match="manuscript">
  <div class="manuscript"
       id="manuscript{ID}"
       about="{$URI_ROOT}/manuscripts/{ID}"
       typeof="mo:Manuscript"
       rev="mo:manuscript"
       resource="{$ID}">
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="purpose" />
    <xsl:apply-templates select="phsyical_size" />
    <xsl:apply-templates select="medium" />
    <xsl:apply-templates select="extent" />
    <xsl:apply-templates select="missing" />
    <!-- <xsl:apply-templates select="date_made" /> -->
    <!-- <xsl:apply-templates select="annotation_of" /> -->
    <xsl:apply-templates select="location" />
    <xsl:apply-templates select="notes" />
  </div>
</xsl:template>

<xsl:template match="manuscripts/title">
  <div class="field manuscript-title">
    <span class="name">Title</span><xsl:text>: </xsl:text>
    <span class="content manuscript-title"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="dc:title"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/purpose">
  <div class="field manuscript-purpose">
    <span class="name">Purpose</span><xsl:text>: </xsl:text>
    <span class="content manuscript-purpose"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="procav:purpose"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/phsyical_size">
  <div class="field manuscript-phsyical-size">
    <span class="name">Phsyical_Size</span><xsl:text>: </xsl:text>
    <span class="content manuscript-phsyical-size"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="procav:phsyical_size"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/medium">
  <div class="field manuscript-medium">
    <span class="name">Medium</span><xsl:text>: </xsl:text>
    <span class="content manuscript-medium"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="procav:medium"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/extent">
  <div class="field manuscript-extent">
    <span class="name">Extent</span><xsl:text>: </xsl:text>
    <span class="content manuscript-extent"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="procav:extent"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/missing">
  <div class="field manuscript-missing">
    <span class="name">Missing</span><xsl:text>: </xsl:text>
    <span class="content manuscript-missing"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="procav:missing"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/location">
  <div class="field manuscript-location">
    <span class="name">Location</span><xsl:text>: </xsl:text>
    <span class="content manuscript-location"
	  about="{$URI_ROOT}/manuscripts/{ID}"
	  property="procav:location"><xsl:apply-templates /></span>
  </div>
</xsl:template> 

<xsl:template match="manuscripts/notes">
  <div class="field manuscript-notes">
    <span class="name">Notes</span><xsl:text>: </xsl:text>
    <p class="content manuscript-notes"
       about="{$URI_ROOT}/manuscripts/{ID}"
       property="procav:notes"><xsl:apply-templates /></p>
  </div>
</xsl:template> 

<xsl:template name="sub-works-type">
  <xsl:choose>
    <xsl:when test="//genres[1]/genre/text()='opera'">Acts</xsl:when>
    <xsl:when test="//genres[1]/genre/text()='ballet'">Acts</xsl:when>
    <xsl:otherwise>Movements</xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>