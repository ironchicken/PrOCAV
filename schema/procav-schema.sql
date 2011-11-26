-- Schema for PrOCAV database
SET NAMES utf8;
DROP DATABASE IF EXISTS procav;
CREATE DATABASE IF NOT EXISTS procav;
USE procav;

-- musical works by Prokofiev
CREATE TABLE works (
  ID                INT PRIMARY KEY auto_increment,
  catalogue_number  VARCHAR(32) UNIQUE,
  uniform_title     VARCHAR(255) NOT NULL,
  sub_title         VARCHAR(255),
  part_of           INT,
  parent_relation   ENUM('movement', 'act', 'scene', 'number'),
  opus_number       INT,
  opus_suffix       VARCHAR(8),
  duration          FLOAT,
  notes             TEXT);

-- works can have some additional information attached to them
CREATE TABLE musical_information (
  work_id           INT NOT NULL UNIQUE,
  performance_direction VARCHAR(128),
  tonic             ENUM('C','D','E','F','G','A','B'),
  tonic_chromatic   ENUM('n','b','#'),
  mode              ENUM('major','minor'),
  time_sig_beats    INT,
  time_sig_division INT);

-- works may have additional titles, including in other languages
CREATE TABLE titles (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  manuscript_id     INT,
  edition_id        INT,
  person_id         INT,
  title             VARCHAR(255) NOT NULL,
  transliteration   VARCHAR(255),
  script            VARCHAR(32),
  `language`        CHAR(2),
  notes             TEXT);

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

-- works may require any number of instruments
CREATE TABLE instruments (
  work_id           INT NOT NULL,
  instrument        VARCHAR(64) NOT NULL,
  `role`            VARCHAR(32));

-- works may be derived from other works
CREATE TABLE derived_from (
  precusror_work    INT NOT NULL,
  derived_work      INT NOT NULL,
  derivation_relation ENUM('transcription', 'arrangement', 'off-shoot') NOT NULL);

-- a period of compositional activity
CREATE TABLE composition (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  manuscript_id     INT NOT NULL,
  period_start      INT,
  period_end        INT,
  work_type         ENUM('sketch', 'contextualised sketch', 'draft short/piano score',
                         'extended draft short score', 'instrumental annotations',
                         'autograph complete full score') NOT NULL);

-- editions of works (or parts of works) which may be published
CREATE TABLE editions (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  date_made	    INT,
  editor	    INT,
  score_type        VARCHAR(128),
  work_extent       VARCHAR(64),
  notes             TEXT);

-- a publication in which editions are published
CREATE TABLE publications (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(255) NOT NULL,
  publisher         VARCHAR(255),
  publication_place VARCHAR(128),
  date_published    INT,
  serial_number     VARCHAR(64),
  notes             TEXT);

-- asserts that an edition is published in a publication
CREATE TABLE published_in (
  edition_id        INT NOT NULL,
  publication_id    INT NOT NULL,
  edition_extent    VARCHAR(64),
  publication_range VARCHAR(64));

-- a performace of a work
CREATE TABLE performances (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  date_performed    INT,
  venue_id          INT,
  performance_type  ENUM('concert', 'broadcast', 'recording', 'private'),
  notes             TEXT);

-- asserts that a person performed in a performance
CREATE TABLE performed_in (
  person_id         INT NOT NULL,
  performance_id    INT NOT NULL,
  `role`            VARCHAR(128));

-- letters, normally from Prokofiev
CREATE TABLE letters (
  ID                INT PRIMARY KEY auto_increment,
  letters_db_ID     VARCHAR(32),
  date_composed     INT,
  date_sent         INT,
  addressee         INT,
  signatory         INT,
  original_text     TEXT,
  english_text      TEXT);

-- asserts that a letter mentions something in the database
CREATE TABLE letter_mentions (
  ID                INT PRIMARY KEY auto_increment,
  letter_id         INT NOT NULL,
  letter_ragne      VARCHAR(64),
  mentioned_table   ENUM('works', 'titles', 'composition', 'editions', 'publications',
                         'performances', 'letters', 'manuscripts', 'texts',
                         'dedicated_to') NOT NULL,
  mentioned_id      INT NOT NULL,
  mentioned_extent  VARCHAR(64),
  notes             TEXT);

-- a music manuscript relating to a work
CREATE TABLE manuscripts (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(128),
  purpose           ENUM('sketch', 'contextualised sketch', 'draft short/piano score',
                         'extended draft short score', 'instrumental annotations',
                         'autograph complete full score') NOT NULL,
  physical_size     VARCHAR(32),
  medium            VARCHAR(32),
  extent            INT,
  missing           TINYINT NOT NULL DEFAULT 0,
  date_made         INT,
  annotation_of     INT,
  location          VARCHAR(128),
  notes             TEXT);

-- literary works set in a work
CREATE TABLE texts (
  ID                INT PRIMARY KEY auto_increment,
  title             VARCHAR(128) NOT NULL,
  author            INT,
  `language`        CHAR(2),
  original_content  TEXT,
  engish_content    TEXT);

-- persons mentioned in the database
CREATE TABLE persons (
  ID                INT PRIMARY KEY auto_increment,
  given_name        VARCHAR(255),
  family_name       VARCHAR(255),
  sex               ENUM('male', 'female'),
  nationality       CHAR(2));

-- asserts that a work is dedicated to a person
CREATE TABLE dedicated_to (
  ID                INT PRIMARY KEY auto_increment,
  work_id           INT NOT NULL,
  person_id         INT NOT NULL,
  manuscript_id     INT,
  edition_id        INT,
  dedication_text   VARCHAR(255),
  date_made         INT);

-- MySQL DATE or DATETIME types are not used in this database; instead
-- every date-like field is a foreign key to a record in this table
CREATE TABLE dates (
  ID                INT PRIMARY KEY auto_increment,
  `year`            INT,
  `month`           INT,
  `day`             INT,
  year_approx       TINYINT NOT NULL DEFAULT 0,
  month_approx      TINYINT NOT NULL DEFAULT 0,
  day_approx        TINYINT NOT NULL DEFAULT 0,
  end_year          INT,
  end_month         INT,
  end_day           INT,
  end_year_approx   TINYINT NOT NULL DEFAULT 0,
  end_month_approx  TINYINT NOT NULL DEFAULT 0,
  end_day_approx    TINYINT NOT NULL DEFAULT 0,
  date_text         VARCHAR(255),
  source_table      ENUM('editions', 'letters', 'manuscripts'),
  source_id         INT);

-- digitised media available in the archive
CREATE TABLE media_items (
  ID                INT PRIMARY KEY auto_increment,
  mime_type         VARCHAR(32) NOT NULL,
  `path`            VARCHAR(255) UNIQUE NOT NULL,
  extent            VARCHAR(128),
  resolution        VARCHAR(128),
  date_made         DATETIME,
  date_acquired     DATETIME NOT NULL,
  copyright         VARCHAR(255),
  `public`          TINYINT NOT NULL DEFAULT 1);

-- digitised media from outside the archive
CREATE TABLE remote_media_items (
  ID                INT PRIMARY KEY auto_increment,
  mime_type         VARCHAR(32) NOT NULL,
  uri               VARCHAR(255) UNIQUE NOT NULL,
  extent            VARCHAR(128),
  resolution        VARCHAR(128),
  date_made         DATETIME,
  date_linked       DATETIME NOT NULL,
  copyright         VARCHAR(255),
  `public`          TINYINT NOT NULL DEFAULT 1);

CREATE TABLE representation_of (
  `source`          ENUM('local', 'remote') NOT NULL,
  media_id          INT NOT NULL,
  related_table     ENUM('works', 'editions', 'publications', 'performances',
                         'letters', 'manuscripts', 'texts', 'media_items',
                         'remote_media_items') NOT NULL,
  related_id        INT NOT NULL,
  relation          ENUM('digitisation', 'transcription', 'features'));

-- sources of information from outside the database
CREATE TABLE resources (
  ID                INT PRIMARY KEY auto_increment,
  uri               VARCHAR(255) UNIQUE NOT NULL,
  title             VARCHAR(255),
  mime_type         VARCHAR(32) NOT NULL,
  date_made         DATETIME,
  date_linked       DATETIME NOT NULL);

-- points an external resource to something in the database
CREATE TABLE resource_about (
  resource_id       INT NOT NULL,
  related_table     ENUM('works', 'titles', 'genres', 'instruments', 'composition',
                         'editions', 'publications', 'performances', 'letters',
                         'letter_mentions', 'manuscripts', 'texts', 'persons',
                         'dedicated_to', 'remote_media_items'),
  related_id        INT NOT NULL,
  relation          VARCHAR(128));
