<?xml version="1.0" encoding="utf-8" ?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" omit-xml-declaration="yes" />

<xsl:include href="globals.xsl" />

<xsl:template match="/">
<html xmlns:mei="http://www.music-encoding.org/ns/mei"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:foaf="http://xmlns.com/foaf/0.1/"
      xmlns:dc="http://purl.org/dc/elements/1.1/"
      xmlns:mo="http://purl.org/ontology/mo/"
      xmlns:mo-i="http://purl.org/ontology/mo-imaginary/"
      xmlns:event="http://purl.org/NET/c4dm/event.owl"
      version="HTML+RDFa 1.1" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title>Serge Prokofiev: <xsl:value-of select="substring-after(//request/path, 'year/')" /></title>

    <link rel="schema.DC" href="http://purl.org/dc/elements/1.1/" />
    <link rel="schema.DCTERMS" href="http://purl.org/dc/terms/" />

    <meta name="record-type" content="period" />
    <xsl:call-template name="page-tools" />
  </head>
  <body>
    <div id="page">
    <xsl:call-template name="page-header" />
    <div id="body">
      <xsl:call-template name="page-menu" />
      <div id="container">
        <div class="period main-content">
	  <h2>Period: <xsl:value-of select="substring-after(//request/path, 'year/')" /></h2>

          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">1</xsl:with-param>
            <xsl:with-param name="month-name">January</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">2</xsl:with-param>
            <xsl:with-param name="month-name">February</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">3</xsl:with-param>
            <xsl:with-param name="month-name">March</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">4</xsl:with-param>
            <xsl:with-param name="month-name">April</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">5</xsl:with-param>
            <xsl:with-param name="month-name">May</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">6</xsl:with-param>
            <xsl:with-param name="month-name">June</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">7</xsl:with-param>
            <xsl:with-param name="month-name">July</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">8</xsl:with-param>
            <xsl:with-param name="month-name">August</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">9</xsl:with-param>
            <xsl:with-param name="month-name">September</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">10</xsl:with-param>
            <xsl:with-param name="month-name">October</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">11</xsl:with-param>
            <xsl:with-param name="month-name">November</xsl:with-param>
	  </xsl:call-template>
          <xsl:call-template name="show-month">
            <xsl:with-param name="month-number">12</xsl:with-param>
            <xsl:with-param name="month-name">December</xsl:with-param>
	  </xsl:call-template>
          <!-- also call template with no arguments which will display
               records with unknown months -->
          <xsl:call-template name="show-month" />
	</div>
        <xsl:call-template name="user-tools" />
      </div>
    </div>
    <xsl:call-template name="page-footer" />
    </div>
  </body>    
</html>
</xsl:template>

<xsl:template name="show-month">
  <xsl:param name="month-number">nil</xsl:param>
  <xsl:param name="month-name">Unknown</xsl:param>

  <xsl:if test="//period/composition_start[start_month=$month-number or ($month-number='nil' and not(start_month))] or
                //period/composition_end[end_month=$month-number or ($month-number='nil' and not(end_month))] or
                //period/manuscript[made_month=$month-number or ($month-number='nil' and not(made_month))] or
                //period/letter[composed_month=$month-number or ($month-number='nil' and not(composed_month))] or
                //period/performance[performed_month=$month-number or ($month-number='nil' and not(performed_month))] or
                //period/publication[pub_date_month=$month-number or ($month-number='nil' and not(pub_date_month))]">
  <h3><span class="records-toggle"
	    onclick="composerCat.toggleRecords(event, '{$month-name}')">+</span> <xsl:value-of select="$month-name" /></h3>
  <div class="month" id="{$month-name}">

    <!-- FIXME This is not true! These are *period* starts and ends,
         not composition commencement and completion. -->
    <xsl:if test="//period/composition_start[start_month=$month-number or ($month-number='nil' and not(start_month))]">
      <h4>Works started</h4>
      <xsl:apply-templates select="//composition_start[start_month=$month-number or ($month-number='nil' and not(start_month))]">
        <xsl:sort select="start_day" data-type="number" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="//period/composition_end[end_month=$month-number or ($month-number='nil' and not(end_month))]">
      <h4>Works completed</h4>
      <xsl:apply-templates select="//composition_end[end_month=$month-number or ($month-number='nil' and not(end_month))]">
        <xsl:sort select="start_day" data-type="number" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="//period/manuscript[made_month=$month-number or ($month-number='nil' and not(made_month))]">
      <h4>Manuscripta</h4>
      <xsl:apply-templates select="//manuscript[made_month=$month-number or ($month-number='nil' and not(made_month))]">
        <xsl:sort select="made_day" data-type="number" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="//period/letter[composed_month=$month-number or ($month-number='nil' and not(composed_month))]">
      <h4>Letters</h4>
      <xsl:apply-templates select="//letter[composed_month=$month-number or ($month-number='nil' and not(composed_month))]">
        <xsl:sort select="composed_day" data-type="number" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="//period/performance[performed_month=$month-number or ($month-number='nil' and not(performed_month))]">
      <h4>Performances</h4>
      <xsl:apply-templates select="//performance[performed_month=$month-number or ($month-number='nil' and not(performed_month))]">
        <xsl:sort select="performed_day" data-type="number" />
      </xsl:apply-templates>
    </xsl:if>

    <xsl:if test="//period/publication[pub_date_month=$month-number or ($month-number='nil' and not(pub_date_month))]">
      <h4>Publications</h4>
      <xsl:apply-templates select="//publication[pub_date_month=$month-number or ($month-number='nil' and not(pub_date_month))]">
        <xsl:sort select="pub_date_day" data-type="number" />
      </xsl:apply-templates>
    </xsl:if>

  </div>
  </xsl:if>
</xsl:template>

<xsl:template match="period/composition_start|period/composition_end">
  <div class="record composition">
    <xsl:apply-templates select="uniform_title" />
    <xsl:apply-templates select="start_year|end_year" />
    <xsl:apply-templates select="work_type" />
  </div>
</xsl:template>

<xsl:template match="composition_start/uniform_title|composition_end/uniform_title">
  <div class="field work-uniform_title">
    <span class="name">Title</span>
    <span class="content work-uniform_title"><a href="{$URI_ROOT}/works/{../work_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="composition_start/start_year|composition_end/start_year">
  <div class="field composition-period_start">
    <span class="name">Date</span>
    <span class="content composition-period_start">
      <xsl:if test="../start_day">
        <xsl:value-of select="../start_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../start_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../start_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="." />
    </span>
  </div>
</xsl:template>

<xsl:template match="composition_start/end_year|composition_end/end_year">
  <div class="field composition-period_end">
    <span class="name">Date</span>
    <span class="content composition-period_end">
      <xsl:if test="../end_day">
        <xsl:value-of select="../end_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../end_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../end_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="." />
    </span>
  </div>
</xsl:template>

<xsl:template match="composition_start/work_type|composition_end/work_type">
  <div class="field work-work_type">
    <span class="name">Work type</span>
    <span class="content work-work_type"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="period/manuscript">
  <div class="record manuscript">
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="purpose" />
    <xsl:apply-templates select="made_year" />
    <xsl:apply-templates select="archive|archive_abbr" />
  </div>
</xsl:template>

<xsl:template match="manuscript/title">
  <div class="field manuscript-title">
    <span class="name">Title</span>
    <span class="content manuscript-title"><a href="{$URI_ROOT}/manuscripts/{../ID}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/purpose">
  <div class="field manuscript-purpose">
    <span class="name">Purpose</span>
    <span class="content manuscript-purpose"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="manuscript/made_year">
  <div class="field manuscript-made">
    <span class="name">Date</span>
    <span class="content manuscript-made">
      <xsl:if test="../made_day">
        <xsl:value-of select="../made_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../made_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../made_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="." />
    </span>
  </div>
</xsl:template>

<xsl:template match="manuscript/archive|manuscript/archive_abbr">
  <div class="field manuscript-location">
    <span class="name">Location</span>
    <span class="content manuscript-location"><a href="{$URI_ROOT}/archives/{../archive_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="period/letter">
  <div class="record letter">
    <xsl:apply-templates select="composed" />
    <xsl:apply-templates select="addressee_family_name" />
    <xsl:apply-templates select="signatory_family_name" />
  </div>
</xsl:template>

<xsl:template match="letter/composed_year">
  <div class="field letter-composed">
    <span class="name">Date</span>
    <span class="content letter-composed">
      <a href="{$URI_ROOT}/letters/{../ID}">
        <xsl:if test="../composed_day">
          <xsl:value-of select="../composed_day" /><xsl:text> </xsl:text>
	</xsl:if>
        <xsl:if test="../composed_month">
          <xsl:call-template name="month">
            <xsl:with-param name="month"><xsl:value-of select="../composed_month" /></xsl:with-param>
	  </xsl:call-template>
        <xsl:text> </xsl:text>
	</xsl:if>
        <xsl:value-of select="." />
      </a>
    </span>
  </div>
</xsl:template>

<xsl:template match="letter/addressee_family_name">
  <div class="field letter-addressee">
    <span class="name">Addressee</span>
    <span class="content letter-addressee"><a href="{$URI_ROOT}/persons/{../addressee_id}"><xsl:apply-templates select="../addressee_given_name" /> <xsl:apply-templates select="." /></a></span>
  </div>
</xsl:template>

<xsl:template match="letter/signatory_family_name">
  <div class="field letter-signatory">
    <span class="name">Signatory</span>
    <span class="content letter-signatory"><a href="{$URI_ROOT}/persons/{../signatory_id}"><xsl:apply-templates select="../signatory_given_name" /> <xsl:apply-templates select="." /></a></span>
  </div>
</xsl:template>

<xsl:template match="period/performance">
  <div class="record performance">
    <xsl:apply-templates select="performed_year" />
    <xsl:apply-templates select="uniform_title" />
    <xsl:apply-templates select="performance_type" />
    <xsl:apply-templates select="venue" />
  </div>
</xsl:template>

<xsl:template match="performance/performed_year">
  <div class="field performance-performed">
    <span class="name">Date</span>
    <span class="content performance-performed">
      <a href="{$URI_ROOT}/performances/{../ID}">
        <xsl:if test="../performed_day">
          <xsl:value-of select="../performed_day" /><xsl:text> </xsl:text>
	</xsl:if>
        <xsl:if test="../performed_month">
          <xsl:call-template name="month">
            <xsl:with-param name="month"><xsl:value-of select="../performed_month" /></xsl:with-param>
	  </xsl:call-template>
          <xsl:text> </xsl:text>
	</xsl:if>
        <xsl:value-of select="." />
      </a>
    </span>
  </div>
</xsl:template>

<xsl:template match="performance/uniform_title">
  <div class="field performance-work">
    <span class="name">Work</span>
    <span class="content performance-work"><a href="{$URI_ROOT}/works/{../work_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="performance/venue">
  <div class="field performance-venue">
    <span class="name">Venue</span>
    <span class="content performance-venue">
      <a href="{$URI_ROOT}/venues/{../venue_id}"><xsl:apply-templates /></a>
      <xsl:if test="../city">
        <xsl:text>, </xsl:text>
        <a href="{$URI_ROOT}/places/{../city}"><xsl:value-of select="../city" /></a>
      </xsl:if>
      <xsl:if test="../country">
        <xsl:text>, </xsl:text>
        <a href="{$URI_ROOT}/places/{../country}"><xsl:value-of select="../country" /></a>
      </xsl:if>
      <xsl:if test="../venue_type">
        <xsl:text> (</xsl:text><xsl:value-of select="../venue_type" />)
      </xsl:if>
    </span>
  </div>
</xsl:template>

<xsl:template match="performance/performance_type">
  <div class="field performance-performance_type">
    <span class="name">Performance type</span>
    <span class="content performance-performance_type"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="period/publication">
  <div class="record publication">
    <xsl:apply-templates select="title" />
    <xsl:apply-templates select="publisher" />
    <xsl:apply-templates select="pub_date_year" />
    <xsl:apply-templates select="uniform_title" />
  </div>
</xsl:template>

<xsl:template match="publication/title">
  <div class="field publication-title">
    <span class="name">Title</span>
    <span class="content publication-title"><a href="{$URI_ROOT}/publications/{../ID}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

<xsl:template match="publication/publisher">
  <div class="field publication-publisher">
    <span class="name">Publisher</span>
    <span class="content publication-publisher"><xsl:apply-templates /></span>
  </div>
</xsl:template>

<xsl:template match="publication/pub_date_year">
  <div class="field publication-pub_date">
    <span class="name">Date</span>
    <span class="content publication-pub_date">
      <xsl:if test="../pub_date_day">
        <xsl:value-of select="../pub_date_day" /><xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="../pub_date_month">
        <xsl:call-template name="month">
          <xsl:with-param name="month"><xsl:value-of select="../pub_date_month" /></xsl:with-param>
	</xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="." />
    </span>
  </div>
</xsl:template>

<xsl:template match="publication/uniform_title">
  <div class="field publication-work">
    <span class="name">Work</span>
    <span class="content publication-work"><a href="{$URI_ROOT}/works/{../work_id}"><xsl:apply-templates /></a></span>
  </div>
</xsl:template>

</xsl:stylesheet>
