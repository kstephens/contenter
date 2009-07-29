class CreateVersionListContentVersionView < ActiveRecord::Migration
  def self.up
    execute <<'END'
CREATE VIEW version_list_content_version_view AS
SELECT vl.id AS version_list_id, cv.id AS content_version_id 
FROM version_lists vl
LEFT OUTER JOIN version_list_contents vlc
   ON vlc.version_list_id = vl.id
JOIN content_versions cv
   ON (cv.id = vlc.content_version_id) OR 
      ( cv.id IN (
	SELECT max(id)
	FROM content_versions 
	WHERE cv.created_at <= vl.point_in_time
	GROUP BY content_id))
;
COMMENT ON VIEW version_list_content_version_view IS $$
   A list of version_list_ids and the content_version_ids within them, 
   whether the content_versions are explicitly listed in the version_list_contents
   join table, or if they're implicitly included in the version_list by virtue of
   being the most recent content_version at the time of the version_list.point_in_time

   Example: SELECT cv.* FROM content_versions cv
	    JOIN version_list_content_version_view vlcvv ON vlcvv.content_version_id = cv.id
            WHERE  version_list_id = 1

$$
END
  end

  def self.down
    execute("DROP VIEW version_list_content_version_view")
  end
end
