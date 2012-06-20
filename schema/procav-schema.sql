-- Schema for PrOCAV database
SET NAMES utf8;
-- DROP DATABASE IF EXISTS procav;
-- CREATE DATABASE IF NOT EXISTS procav;
-- USE procav;

-- musical works by Prokofiev
CREATE TABLE works (
  ID                INT PRIMARY KEY auto_increment,
  uniform_title     VARCHAR(255) NOT NULL,
  sub_title         VARCHAR(255),
  part_of           INT,
  parent_relation   ENUM('movement', 'act', 'scene', 'number'),
  part_number       VARCHAR(32),
  part_position     INT,
  duration          FLOAT,
  notes             TEXT,
  staff_notes       TEXT);

-- works can have some additional information attached to them
CREATE TABLE musical_information (
  work_id           INT NOT NULL UNIQUE,
  performance_direction VARCHAR(128),
  key_signature     INT,
  tonic             ENUM('C','D','E','F','G','A','B'),
  tonic_chromatic   ENUM('n','b','#'),
  mode              ENUM('major','minor'),
  time_sig_beats    INT,
  time_sig_division INT,
  staff_notes       TEXT);

-- works may have additional titles, including in other languages
CREATE TABLE titles (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  manuscript_id     INT,
  edition_id        INT,
  person_id         INT,
  title             VARCHAR(255),-- NOT NULL,
  transliteration   VARCHAR(255),
  script            VARCHAR(32),
  `language`        CHAR(2),
  notes             TEXT,
  staff_notes       TEXT);

-- multiple catalogues of the works may be defined
CREATE TABLE catalogues (
  ID                INT PRIMARY KEY auto_increment,
  label             VARCHAR(32) NOT NULL UNIQUE,
  title             VARCHAR(255),
  notes             TEXT);

-- The "Opus" catalogue is provided as a default
INSERT INTO catalogues (label, title) VALUES ("Op. ", "Opus numbers");

-- Associates a work with a catalogue number in a given catalogue
CREATE TABLE catalogue_numbers (
  work_id           INT NOT NULL,
  catalogue_id      INT NOT NULL,
  `number`          VARCHAR(32) NOT NULL,
  number_position   INT NOT NULL,
  suffix            VARCHAR(32),
  suffix_position   INT,
  staff_notes       TEXT);

-- works may have any number of statuses
CREATE TABLE work_status (
  work_id           INT NOT NULL,
  status            ENUM('juvenilia', 'incomplete', 'unpublished',
                         'published') NOT NULL);

-- works may have any number of genre labels
CREATE TABLE genres (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  genre             VARCHAR(32) NOT NULL);

-- information about known musical instruments
CREATE TABLE instruments (
  ID                INT PRIMARY KEY auto_increment,
  instrument        VARCHAR(255) UNIQUE NOT NULL,
  sort_position     INT,
  description       TEXT);

-- works may require any number of instruments
CREATE TABLE scored_for (
  work_id           INT NOT NULL,
  instrument        VARCHAR(255) NOT NULL,
  `cardinality`     ENUM('solo','desk','chorus'),
  doubles_with      VARCHAR(255),
  `role`            VARCHAR(128),
  in_group          VARCHAR(128), -- e.g. "principals", "orchestra", "chorus"
  notes             TEXT,
  staff_notes       TEXT);

-- works may be derived from other works
CREATE TABLE derived_from (
  precursor_work    INT NOT NULL,
  derived_work      INT NOT NULL,
  derivation_relation ENUM('transcription', 'arrangement', 'off-shoot') NOT NULL,
  notes             TEXT,
  staff_notes       TEXT);

-- a period of compositional activity
CREATE TABLE composition (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  manuscript_id     INT,
  period_start      INT,
  period_end        INT,
  work_type         ENUM('sketch', 'contextualised sketch', 'draft short/piano score',
                         'extended draft short score', 'instrumental annotations',
                         'draft full score', 'autograph complete full score',
                         'annotated published score'));

-- editions of works (or parts of works) which may be published
CREATE TABLE editions (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  date_made	    INT,
  editor	    INT,
  work_extent       VARCHAR(64),
  notes             TEXT,
  staff_notes       TEXT);

-- a publication in which editions are published
CREATE TABLE publications (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(255) NOT NULL,
  publisher         VARCHAR(255),
  publication_place VARCHAR(128),
  date_published    INT,
  serial_number     VARCHAR(64),
  score_type        VARCHAR(128),
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that an edition is published in a publication
CREATE TABLE published_in (
  edition_id        INT NOT NULL,
  publication_id    INT NOT NULL,
  edition_extent    VARCHAR(64),
  publication_range VARCHAR(64),
  staff_notes       TEXT);

-- a performace of a work
CREATE TABLE performances (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  date_performed    INT,
  venue_id          INT,
  performance_type  ENUM('concert', 'broadcast', 'recording', 'private',
                         'staged', 'semi-staged'),
  notes             TEXT,
  staff_notes       TEXT);

-- describes venues at which performances may take place
CREATE TABLE venues (
  ID                INT PRIMARY KEY auto_increment,
  `name`            VARCHAR(255) NOT NULL,
  town_id           INT,
  country           CHAR(2),
  venue_type        VARCHAR(128),
  homepage          VARCHAR(255),
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that a person performed in a performance
CREATE TABLE performed_in (
  person_id         INT NOT NULL,
  performance_id    INT NOT NULL,
  `role`            VARCHAR(128),
  notes             TEXT,
  staff_notes       TEXT);

-- documents, including letters; documents may mention records from
-- other tables; they may comprise pages; and they may be in archives
CREATE TABLE documents (
  ID                INT PRIMARY KEY auto_increment);

-- a page of a document
CREATE TABLE document_pages (
  ID                INT PRIMARY KEY auto_increment,
  document_id       INT NOT NULL,
  page_number       INT,
  page_side         ENUM('r','v'),
  page_label        VARCHAR(32),
  notes             TEXT,
  staff_notes       TEXT);

-- -- defines a range within a document
-- CREATE TABLE document_range (
--   ID                INT PRIMARY KEY auto_increment,
--   document_id       INT NOT NULL,
--   notes             TEXT,
--   staff_notes       TEXT);

-- asserts that a page is in a range
CREATE TABLE page_in_range (
  range_id          INT NOT NULL, -- this is *not* a foreign key; ranges should share a range_id value
  page_id           INT NOT NULL,
  `position`        INT,
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that a document mentions something in the database
CREATE TABLE document_mentions (
  ID                INT PRIMARY KEY auto_increment,
  document_id       INT NOT NULL,
  range_id          INT,
  document_range    VARCHAR(64),
  mentioned_table   ENUM('works', 'titles', 'composition', 'editions', 'publications',
                         'performances', 'documents', 'texts', 'dedicated_to',
			 'commissioned_by', 'biographical_details') NOT NULL,
  mentioned_id      INT NOT NULL,
  mentioned_extent  VARCHAR(64),
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that a document contains something in the database
-- (including musical works)
CREATE TABLE document_contains (
  ID                INT PRIMARY KEY auto_increment,
  document_id       INT NOT NULL,
  contained_table   ENUM('works', 'texts') NOT NULL,
  contained_id      INT NOT NULL,
  contained_extent  VARCHAR(128) NOT NULL DEFAULT 'complete',
  range_id          INT,
  document_range    VARCHAR(128),
  hand              INT,-- points to a person who wrote in the document
  notes             TEXT,
  staff_notes       TEXT);
  
-- letters, normally from Prokofiev; these are a special class of
-- documents
CREATE TABLE letters (
  document_id       INT UNIQUE NOT NULL,
  letters_db_ID     VARCHAR(32),
  date_composed     INT,
  date_sent         INT,
  addressee         INT,
  signatory         INT,
  recipient_addr    INT,
  sender_addr       INT,
  physical_size     VARCHAR(64),
  support           VARCHAR(64), -- e.g. paper
  medium            VARCHAR(64), -- e.g. print, ink, pencil
  layout            VARCHAR(64),
  missing           TINYINT DEFAULT 0,-- NOT NULL DEFAULT 0,
  `language`        CHAR(2),
  script            VARCHAR(32),
  original_text     TEXT,
  english_text      TEXT,
  notes             TEXT,
  staff_notes       TEXT);

-- addresses to which letters may be sent
CREATE TABLE postal_addresses (
  ID                INT PRIMARY KEY auto_increment,
  address           TEXT,
  town_id           INT,
  country           CHAR(2),
  latitude	    DECIMAL(18,12),
  longitude	    DECIMAL(18,12),
  notes             TEXT,
  staff_notes       TEXT);

-- towns which can be used in post_addresses or as venues
CREATE TABLE towns (
  ID                INT PRIMARY KEY auto_increment,
  `name`            VARCHAR(255) NOT NULL,
  country           CHAR(2),
  latitude	    DECIMAL(18,12),
  longitude	    DECIMAL(18,12),
  notes             TEXT,
  staff_notes       TEXT);
  
-- a music manuscript; these are a special class of document
CREATE TABLE manuscripts (
  document_id       INT UNIQUE NOT NULL,
  title             VARCHAR(128),
  purpose           ENUM('sketch', 'contextualised sketch', 'draft short/piano score',
                         'extended draft short score', 'instrumental annotations',
                         'draft full score', 'autograph complete full score',
                         'annotated published score'),
  date_made         INT,
  physical_size     VARCHAR(64),
  support           VARCHAR(64), -- e.g. paper
  medium            VARCHAR(64), -- e.g. print, ink, pencil
  layout            VARCHAR(64),
  missing           TINYINT DEFAULT 0,-- NOT NULL DEFAULT 0,
  annotation_of     INT,
  notes             TEXT,
  staff_notes       TEXT);

-- an archive of documents or other materials
CREATE TABLE archives (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(128),
  abbreviation      VARCHAR(16),
  date_established  INT,
  date_disbanded    INT,
  city              VARCHAR(128),
  location          VARCHAR(255),
  country           CHAR(2),
  uri               VARCHAR(255),
  telephone         VARCHAR(32),
  email             VARCHAR(255),
  latitude	    DECIMAL(18,12),
  longitude	    DECIMAL(18,12),
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that an archivalable document is in an archive optionally
-- with an identifier from that archive; use a resources record to
-- associate an external URI
CREATE TABLE in_archive (
  ID                INT PRIMARY KEY auto_increment,
  document_id       INT NOT NULL,
  page_id           INT,
  archive_id        INT NOT NULL,
  aggregation_id    INT,
  archival_ref_str  VARCHAR(64),
  archival_ref_num  INT,
  date_acquired     INT,
  date_released     INT,
  access            ENUM('public', 'private'),
  item_status       ENUM('original', 'copy') NOT NULL DEFAULT 'original',
  copy_type         VARCHAR(32), -- e.g. photocopy, microfilm, scan
  copyright         VARCHAR(255),
  notes             TEXT,
  staff_notes       TEXT);

-- represents a collection within an archive; these collections are
-- organised hierarchically
CREATE TABLE aggregations (
  ID                INT PRIMARY KEY auto_increment,
  label             VARCHAR(32),
  label_num         INT,
  title             VARCHAR(32),
  `level`           ENUM('fonds', 'sub-fonds', 'series', 'sub-series', 'files', 'sub-files', 'item') NOT NULL,
  parent            INT,
  extent_stmt       VARCHAR(128),
  archive           INT NOT NULL,
  description       VARCHAR(255),
  notes             TEXT,
  staff_notes       TEXT);

-- literary works set in a work
CREATE TABLE texts (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(128),
  author            INT,
  no_author         ENUM('anonymous', 'traditional'),
  text_type         VARCHAR(64),
  original          TINYINT,
  `language`        CHAR(2),
  `source`          VARCHAR(128), -- e.g. Bible
  citation          VARCHAR(128), -- e.g. Ps 107:23
  original_content  TEXT,
  english_content   TEXT,
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that a work sets a text or that the text of a work is
-- unknown, unidentified, etc.
CREATE TABLE work_sets_text (
  work_id           INT NOT NULL,
  text_id           INT,
  text_status       ENUM('unknown', 'unidentified', 'partial', 'complete'));

-- persons mentioned in the database
CREATE TABLE persons (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(32),
  given_name        VARCHAR(255),
  family_name       VARCHAR(255),
  sex               ENUM('male', 'female'),
  nationality       CHAR(2),
  notes             TEXT,
  staff_notes       TEXT);

-- persons may be known by other names
CREATE TABLE person_names (
  person_id         INT NOT NULL,
  name_type         ENUM('nick', 'pen', 'stage', 'familial', 'maiden', 'former', 'position'),
  `name`            VARCHAR(255) NOT NULL,
  script            VARCHAR(32),
  transliteration   VARCHAR(255),
  notes             TEXT,
  staff_notes       TEXT);

-- describes relationships between persons
CREATE TABLE person_relations (
  from_person       INT NOT NULL,
  to_person         INT NOT NULL,
  relation_type     VARCHAR(32) NOT NULL,
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that a person collaborated on a musical work; (all works
-- are assumed to be composed by Prokofiev)
CREATE TABLE collaborated_on (
  work_id           INT NOT NULL,
  person_id         INT NOT NULL,
  `role`            ENUM('choreographer', 'desinger', 'director', 'producer', 'arranger'),
  notes             TEXT,
  staff_notes       TEXT);

-- records details of persons' lives
CREATE TABLE biographical_details (
  ID                INT PRIMARY KEY auto_increment,
  person_id         INT NOT NULL,
  start_date        INT NOT NULL,
  end_date          INT,
  detail_type       VARCHAR(32) NOT NULL, -- e.g. birth, death, marriage, emmigration
  notes             TEXT,
  staff_notes       TEXT);

-- asserts that a work is dedicated to a person
CREATE TABLE dedicated_to (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  person_id         INT NOT NULL,
  manuscript_id     INT,
  edition_id        INT,
  dedication_text   VARCHAR(255),
  date_made         INT,
  staff_notes       TEXT);

-- asserts that a work was commissioned by a person
CREATE TABLE commissioned_by (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  person_id         INT NOT NULL,
  commission_text   VARCHAR(255),
  date_made         INT,
  notes             TEXT,
  staff_notes       TEXT);

-- MySQL DATE or DATETIME types are not used in this database; instead
-- every date-like field is a foreign key to a record in this table
CREATE TABLE dates (
  ID                INT PRIMARY KEY auto_increment,
  `year`            INT,
  `month`           INT,
  `day`             INT,
  year_accuracy     ENUM('exactly', 'around', 'before', 'after') DEFAULT 'exactly',
  month_accuracy    ENUM('exactly', 'around', 'before', 'after') DEFAULT 'exactly',
  day_accuracy      ENUM('exactly', 'around', 'before', 'after') DEFAULT 'exactly',
  end_year          INT,
  end_month         INT,
  end_day           INT,
  end_year_accuracy ENUM('exactly', 'around', 'before', 'after') DEFAULT 'exactly',
  end_month_accuracy ENUM('exactly', 'around', 'before', 'after') DEFAULT 'exactly',
  end_day_accuracy  ENUM('exactly', 'around', 'before', 'after') DEFAULT 'exactly',
  date_text         VARCHAR(255),
  source_table      ENUM('editions', 'letters', 'manuscripts'),
  source_id         INT,
  staff_notes       TEXT);

-- digitised media available in the archive
CREATE TABLE media_items (
  ID                INT PRIMARY KEY auto_increment,
  mime_type         VARCHAR(32) NOT NULL,
  `path`            VARCHAR(255) UNIQUE,
  content_type      ENUM('audio', 'notation', 'text', 'analysis', 'data') NOT NULL,
  extent            VARCHAR(128),
  resolution        VARCHAR(128),
  date_made         DATETIME,
  date_acquired     DATETIME,
  copyright         VARCHAR(255),
  `public`          TINYINT NOT NULL DEFAULT 1,
  staff_notes       TEXT);

-- some media types will be stored in the database, rather than in the
-- filesystem
CREATE TABLE media_data (
  media_id          INT NOT NULL UNIQUE,
  `data`            BLOB NOT NULL);

-- digitised media from outside the archive
CREATE TABLE remote_media_items (
  ID                INT PRIMARY KEY auto_increment,
  mime_type         VARCHAR(32) NOT NULL,
  uri               VARCHAR(255) UNIQUE NOT NULL,
  content_type      ENUM('audio', 'notation', 'text', 'analysis', 'data') NOT NULL,
  extent            VARCHAR(128),
  resolution        VARCHAR(128),
  date_made         DATETIME,
  date_linked       DATETIME NOT NULL,
  copyright         VARCHAR(255),
  `public`          TINYINT NOT NULL DEFAULT 1,
  staff_notes       TEXT);

-- media_items may be organised into groups; for example, several
-- image files which are the pages of a manuscript
CREATE TABLE media_groups (
  ID                INT PRIMARY KEY auto_increment,
  short_description VARCHAR(64),
  staff_notes       TEXT);

-- asserts that a media_item is in a media_groups
CREATE TABLE media_in_group (
  `source`          ENUM('local', 'remote') NOT NULL,
  media_id          INT NOT NULL,
  group_id          INT NOT NULL,
  `position`        INT);

-- asserts that a media_item (or media_groups) is a representation of
-- something
CREATE TABLE representation_of (
  `source`          ENUM('local', 'remote', 'group') NOT NULL,
  media_id          INT NOT NULL,
  related_table     ENUM('works', 'editions', 'publications', 'performances',
                         'documents', 'document_pages', 'texts', 'media_items',
			 'remote_media_items')
			 NOT NULL,
  related_id        INT NOT NULL,
  relation          ENUM('digitisation', 'transcription', 'features'),
  purpose           ENUM('incipit', 'theme', 'excerpt', 'copy'),
  related_range     VARCHAR(128));

-- sources of information from outside the database
CREATE TABLE resources (
  ID                INT PRIMARY KEY auto_increment,
  uri               VARCHAR(255) UNIQUE NOT NULL,
  title             VARCHAR(255),
  mime_type         VARCHAR(32) NOT NULL,
  date_made         DATETIME,
  date_linked       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  staff_notes       TEXT);

-- points an external resource to something in the database
CREATE TABLE resource_about (
  resource_id       INT NOT NULL,
  related_table     ENUM('works', 'titles', 'genres', 'instruments', 'composition',
                         'editions', 'publications', 'performances', 'documents',
                         'document_pages', 'document_mentions', 'document_contains',
                         'archives', 'in_archive', 'aggregations', 'texts', 'persons',
                         'dedicated_to', 'commissioned_by', 'towns',
                         'remote_media_items')
			 NOT NULL,
  related_id        INT NOT NULL,
  relation          VARCHAR(128));

-- credentials for the editors
CREATE TABLE editors (
  login_name        VARCHAR(36) UNIQUE NOT NULL,
  password          VARCHAR(32) NOT NULL,
  real_name         VARCHAR(64),
  active            TINYINT NOT NULL DEFAULT 1,
  created           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);

-- these are HTTP sessions for the Web interface
CREATE TABLE sessions (
  session_id        CHAR(36) UNIQUE NOT NULL,
  session_type      ENUM('editor', 'consumer', 'public') NOT NULL,
  login_name        VARCHAR(32),
  created           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);
