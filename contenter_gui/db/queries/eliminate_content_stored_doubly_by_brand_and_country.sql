/*
  This transaction 
   1) creates a view on contents which includes the text values of brand.code, country.code etc
   2) finds content where the same data value is specified doubly at (country, brand) coordinates 
      of (_, AU), (AU, _) for example, and inserts the content ids of the brand-varying duplicates
   3) it deletes the brand-varying version of the duplicates.
   4) it puts the lotion on its skin (or else it gets the hose again!)

*/
BEGIN TRANSACTION;

-- a helpful view from which you can do text-based searches on country, brand, key, etc..
CREATE OR REPLACE VIEW contents_with_lookups AS 
 SELECT ck.code as key, ctry.code AS country, brand.code AS brand, c.id, c.uuid, c.content_key_id, c.language_id, c.country_id, c.brand_id, c.application_id, c.mime_type_id, c.md5sum, c.data, c.creator_user_id, c.updater_user_id, c.created_at, c.updated_at, c.version
   FROM contents c
   JOIN content_keys ck ON c.content_key_id = ck.id
   JOIN countries ctry ON c.country_id = ctry.id
   JOIN brands brand ON c.brand_id = brand.id;

CREATE TEMP TABLE content_ids_specified_redundantly -- ON COMMIT DROP 
AS
SELECT id, data FROM contents_with_lookups brand_centric
WHERE brand_id <> 1 -- #the wildcard
AND   country_id = 1
AND EXISTS(
 SELECT country_centric.* FROM contents_with_lookups country_centric
 WHERE  country_centric.brand_id = 1
 AND    country_centric.country_id <> 1
 AND    country_centric.content_key_id = brand_centric.content_key_id
 AND    country_centric.brand = brand_centric.country
 AND    country_centric.data = brand_centric.data
);

-- delete version_list entries recording older versions of the content records we'll be deleting
DELETE FROM version_list_contents 
WHERE content_version_id IN (
   SELECT content_version_id FROM content_versions cv
   INNER JOIN content_ids_specified_redundantly dups ON dups.id = cv.content_id 
               AND dups.data = cv.data
); 

-- delete version_list entries recording older versions of the content records we'll be deleting
DELETE FROM content_versions 
WHERE content_id in (SELECT id FROM content_ids_specified_redundantly);

-- now delete the content records themselves
DELETE FROM contents
WHERE id IN (SELECT id FROM content_ids_specified_redundantly);

COMMIT;
