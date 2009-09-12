class CreateVersionListContentKeyVersionView < ActiveRecord::Migration
  def self.up
    execute <<'END'
CREATE VIEW version_list_content_key_version_view AS
SELECT vl.id AS version_list_id, ckv.id AS content_key_version_id 
FROM version_lists vl
LEFT OUTER JOIN version_list_content_keys vlck
   ON vlck.version_list_id = vl.id
JOIN content_key_versions ckv
   ON (ckv.id = vlck.content_key_version_id) OR 
      (ckv.id IN (
	SELECT max(id)
	FROM content_key_versions 
	WHERE ckv.created_at <= vl.point_in_time
	GROUP BY content_key_id))
;
COMMENT ON VIEW version_list_content_key_version_view IS $$
   A list of version_list_ids and the content_key_version_ids within them, 
   whether the content_key_versions are explicitly listed in the version_list_contents
   join table, or if they're implicitly included in the version_list by virtue of
   being the most recent content_key_version at the time of the version_list.point_in_time

   Example: SELECT ckv.* FROM content_key_versions ckv
	    JOIN version_list_content_key_version_view vlcvv ON vlcvv.content_key_version_id = ckv.id
            WHERE version_list_id = 1

$$
END
  end

  def self.down
  end
end
