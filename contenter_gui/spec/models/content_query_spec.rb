# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

describe "Content::Query" do

COMMON_TABLES = "content_keys, languages, countries, brands, applications, mime_types, content_statuses, users AS updater_users, users AS creator_users".freeze

JOINS = <<"END"
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_statuses.id = contents.content_status_id)
AND (updater_users.id = contents.updater_user_id)
AND (creator_users.id = contents.creator_user_id)
AND (content_types.id = content_keys.content_type_id)
END

ORDER_BY = <<"END".chomp.freeze
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = contents.content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = contents.language_id),
  (SELECT countries.code FROM countries WHERE countries.id = contents.country_id),
  (SELECT brands.code FROM brands WHERE brands.id = contents.brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = contents.application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = contents.mime_type_id)
END

ORDER_BY_CV = ORDER_BY.gsub(/\.id = contents\./, '.id = cv.').freeze

DATA = "(CASE WHEN (content_types.mime_type_id NOT IN (SELECT id FROM mime_types WHERE code LIKE 'text/%')) THEN '' ELSE convert_from(contents.data, 'UTF8') END)".freeze

  it 'should create SQL to query all Content' do
    q = Content::Query.new()
    # $stderr.puts(q.sql + "\n")
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
#{ORDER_BY}
END
  end

  it 'should create SQL to query by ContentType' do
    q = Content::Query.new(:params => { :content_type => 'phrase' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_types.code = E'phrase')
    )
#{ORDER_BY}
END
  end

  it 'should create SQL to query by ContentKey' do
    q = Content::Query.new(:params => { :content_key => 'content_key' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_keys.code = E'content_key')
    )
#{ORDER_BY}
END
  end


 it 'should create SQL to query by content_id ' do
    q = Content::Query.new(:params => { :content_id => '123' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (contents.id = 123)
    )
#{ORDER_BY}
END
  end

  it 'should create SQL to query by UUID ' do
    q = Content::Query.new(:params => { :uuid => '123' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (contents.uuid = E'123')
    )
#{ORDER_BY}
END
  end


  it 'should create SQL to query by md5sum ' do
    q = Content::Query.new(:params => { :md5sum => '123' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (contents.md5sum = E'123')
    )
#{ORDER_BY}
END
  end


  [ :updater, :creator ].each do | field |
    it "should query by #{field}" do
      q = Content::Query.new(:params => { field => 'joeuser' })
      # $stderr.puts (q.sql + "\n")
      (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (#{field}_users.login = E'joeuser')
    )
#{ORDER_BY}
END
    end
  end # each

  it 'should search for data using LIKE' do
    q = Content::Query.new(:params => { :data => '%123%' }, :like => true)
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (#{DATA} LIKE E'%123%')
    )
#{ORDER_BY}
END
  end

  it 'should search for data using case-insensitive LIKE' do
    q = Content::Query.new(:params => { :data => '%123%' }, :ilike => true)
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (#{DATA} ILIKE E'%123%')
    )
#{ORDER_BY}
END
  end


  it 'should search using a version_list_id' do
    q = Content::Query.
      new(:params => { :version_list_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, #{COMMON_TABLES}, version_list_contents, content_types
WHERE
#{JOINS}
AND (version_list_contents.version_list_id   = 123)
AND (version_list_contents.content_version_id = contents.id)
#{ORDER_BY}
END
  end


  [ :content_key_id, :content_type_id, :country_id, :content_status_id ].each do | column |
    it "should search using a #{column}." do
      q = Content::Query.
        new(:params => { column => 123 }
            )
      # $stderr.puts ("\n" + q.sql + "\n")
      (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (#{column.to_s.sub(/_id\Z/, '').pluralize}.id = 123)
    )
#{ORDER_BY}
END
    end
  end

  it "should search using tasks." do
    q = Content::Query.
      new(:params => { :tasks => 123 }
          )
    # $stderr.puts ("\n" + q.sql + "\n")
    (q.sql + "\n").should =~ /\(contents.tasks LIKE E'% 123 %'\)/
  end


  it 'should search by version_list_id' do
    q = Content::Query.
      new(
          :params => { :version_list_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, #{COMMON_TABLES}, version_list_contents, content_types
WHERE
#{JOINS}
AND (version_list_contents.version_list_id   = 123)
AND (version_list_contents.content_version_id = contents.id)
#{ORDER_BY}
END
  end


  it 'should search by version_list_name' do
    q = Content::Query.
      new(
          :params => { :version_list_name => 'production' }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, #{COMMON_TABLES}, version_list_names, version_lists, version_list_contents, content_types
WHERE
#{JOINS}
AND (version_list_names.name               = E'production')
AND (version_list_contents.version_list_id   = version_list_names.version_list_id)
AND (version_list_contents.content_version_id = contents.id)
#{ORDER_BY}
END
  end


  it 'should search using a simple user_query' do
    q = Content::Query.
      new(:user_query => '  %foo_bar%  '
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (#{DATA} ILIKE E'%foo_bar%')
OR  (content_keys.code ILIKE E'%foo_bar%')
    )
#{ORDER_BY}
END
  end


  [ :content_key_id, :content_type_id, :language_id ].each do | column |
    it "should search using a simple user_query with #{column}:123" do
      q = Content::Query.
        new(:user_query => "  #{column}:321 %foo_bar%  #{column}:123"
            )
      # $stderr.puts("\n" + q.sql + "\n")
      (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (#{DATA} ILIKE E'%foo_bar%')
OR  (content_keys.code ILIKE E'%foo_bar%')
    )
AND (
    (#{column.to_s.sub(/_id\Z/, '').pluralize}.id = 123)
    )
#{ORDER_BY}
END
    end
  end

  it 'should search using a user_query with additional selection AND clauses' do
    q = Content::Query.
      new(:user_query => '  content_type:phrase language:en %foo_bar%  ', 
          :params => { :id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (contents.id = 123)
    )
AND (
    (#{DATA} ILIKE E'%foo_bar%')
OR  (content_keys.code ILIKE E'%foo_bar%')
    )
AND (
    (content_types.code = E'phrase')
AND (languages.code = E'en')
    )
#{ORDER_BY}
END
  end


  it 'should search using a user_query with content_key' do
    q = Content::Query.
      new({
            :user_query => '  content_key:key  '
          })
    # $stderr.puts("\n" + q.sql)
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_keys.code = E'key')
    )
#{ORDER_BY}
END
  end


  it 'should count using a user_query with content_key' do
    q = Content::Query.
      new({
            :user_query => '  content_key:key  ',
          })
    # $stderr.puts("\n" + q.sql(:count => true))
    (q.sql(:count => true) + "\n").should == <<"END"
SELECT COUNT(contents.*)
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_keys.code = E'key')
    )
END
  end


  it 'should search all versions using a user_query with content_key' do
    q = Content::Query.
      new({
            :user_query => '  content_key:key  ',
            :versions => true,
          })
    # $stderr.puts("\n" + q.sql)
    (q.sql + "\n").should == <<"END"
SELECT cv.* FROM content_versions AS cv
WHERE cv.id IN (
SELECT contents.id
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_keys.code = E'key')
    )
AND contents.content_id = cv.content_id
)
#{ORDER_BY_CV},
  version DESC
END
  end


  it 'should search using a user_query and version_list_id' do
    q = Content::Query.
      new(:user_query => '  content_type:email country:US %foo_bar%  ', 
          :params => { :version_list_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, #{COMMON_TABLES}, version_list_contents, content_types
WHERE
#{JOINS}
AND (version_list_contents.version_list_id   = 123)
AND (version_list_contents.content_version_id = contents.id)
AND (
    (#{DATA} ILIKE E'%foo_bar%')
OR  (content_keys.code ILIKE E'%foo_bar%')
    )
AND (
    (content_types.code = E'email')
AND (countries.code = E'US')
    )
#{ORDER_BY}
END
  end


  it 'should search using a user_query content_status and latest version' do
    q = Content::Query.
      new(:user_query => '  content_status:initial  ', 
          :latest => true
          )
    # $stderr.puts("\n" + q.sql)
    (q.sql + "\n").should == <<"END"
SELECT cv.* FROM content_versions AS cv
WHERE cv.id IN (
SELECT MAX(contents.id)
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_statuses.code = E'initial')
    )
AND contents.content_id = cv.content_id
)
#{ORDER_BY_CV}
END
  end


  it 'should count using a user_query content_status OR expression and latest version' do
    q = Content::Query.
      new(:user_query => '  latest:true content_status:approved|released  '
          )
    # $stderr.puts("\n" + q.sql(:count => true))
    (q.sql(:count => true) + "\n").should == <<"END"
SELECT COUNT(cv.*) FROM content_versions AS cv
WHERE cv.id IN (
SELECT MAX(contents.id)
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    ((content_statuses.code = E'approved') OR (content_statuses.code = E'released'))
    )
AND contents.content_id = cv.content_id
)
END
  end

  it 'should count using a user_query content_status AND expression and latest version' do
    q = Content::Query.
      new(:user_query => '  latest:true content_status:!approved&released  '
          )
    # $stderr.puts("\n" + q.sql(:count => true))
    (q.sql(:count => true) + "\n").should == <<"END"
SELECT COUNT(cv.*) FROM content_versions AS cv
WHERE cv.id IN (
SELECT MAX(contents.id)
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (((content_statuses.code IS NULL) OR (content_statuses.code <> E'approved')) AND (content_statuses.code = E'released'))
    )
AND contents.content_id = cv.content_id
)
END
  end

  it 'should query using a content_status AND expression and latest version using :exact match and not parse AND and OR expressions' do
    q = Content::Query.
      new({
            :latest => true,
            :exact => true,
            :params => {
              :content_key => "something&somethingelse",
              :content_status => "!approved&released",
            },
          }
          )
    # $stderr.puts("\n" + q.sql())
    (q.sql() + "\n").should == <<"END"
SELECT cv.* FROM content_versions AS cv
WHERE cv.id IN (
SELECT MAX(contents.id)
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (content_statuses.code = E'!approved&released')
AND (content_keys.code = E'something&somethingelse')
    )
AND contents.content_id = cv.content_id
)
#{ORDER_BY_CV}
END
  end

  [ 123, nil ].each do | b_id |
    [ :like, :ilike ].each do | opt |
      it "should search where brand_id=>#{b_id.inspect} and #{opt.inspect}" do
        q = Content::Query.
          new({
                :params => {
                  :brand_id => b_id,
                },
                opt => true,
              })
        # $stderr.puts("\n" + q.sql())
        (q.sql() + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (brands.id #{opt.to_s.upcase} E'#{b_id}')
    )
#{ORDER_BY}
END
      end # it
    end # each
  end # each

  it 'should search all versions with a :conditions option' do
    q = Content::Query.
      new({
            :user_query => '  content_key:key  ',
            :versions => true,
            :conditions => '  brands.id = 123  ',
          })
    # $stderr.puts("\n" + q.sql)
    (q.sql + "\n").should == <<"END"
SELECT cv.* FROM content_versions AS cv
WHERE cv.id IN (
SELECT contents.id
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (  brands.id = 123  )
AND (
    (content_keys.code = E'key')
    )
AND contents.content_id = cv.content_id
)
#{ORDER_BY_CV},
  version DESC
END
  end


  it 'should by filename: and versions:t' do
    q = Content::Query.
      new({
            :user_query => '  filename:abc.png versions:t  ',
          })
    # $stderr.puts("\n" + q.sql)
    (q.sql + "\n").should == <<"END"
SELECT cv.* FROM content_versions AS cv
WHERE cv.id IN (
SELECT contents.id
FROM content_versions AS contents, #{COMMON_TABLES}, content_types
WHERE
#{JOINS}
AND (
    (contents.filename = E'abc.png')
    )
AND contents.content_id = cv.content_id
)
#{ORDER_BY_CV},
  version DESC
END
  end

end # describe

