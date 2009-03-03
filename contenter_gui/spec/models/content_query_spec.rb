# -*- ruby -*-
#require 'test_helper'
require 'spec/spec_helper'

describe "Content::Query" do

  it 'should create SQL to query all Content' do
    q = Content::Query.new()
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end

  it 'should create SQL to query by ContentType' do
    q = Content::Query.new(:params => { :content_type => 'phrase' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (content_types.code = E'phrase')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end

  it 'should create SQL to query by ContentKey' do
    q = Content::Query.new(:params => { :content_key => 'content_key' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (content_keys.code = E'content_key')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should create SQL to query by UUID ' do
    q = Content::Query.new(:params => { :uuid => '123' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (contents.uuid = E'123')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should create SQL to query by md5sum ' do
    q = Content::Query.new(:params => { :md5sum => '123' })
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (contents.md5sum = E'123')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should search for data using LIKE' do
    q = Content::Query.new(:params => { :data => '%123%' }, :like => true)
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (convert_from(contents.data, 'UTF8') LIKE E'%123%')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end

  it 'should search for data using LIKE' do
    q = Content::Query.new(:params => { :data => '%123%' }, :like => true)
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (convert_from(contents.data, 'UTF8') LIKE E'%123%')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should search using a revision_list_id' do
    q = Content::Query.
      new(:params => { :revision_list_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, content_keys, languages, countries, brands, applications, mime_types, revision_list_contents, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (revision_list_contents.revision_list_id   = 123)
AND (revision_list_contents.content_version_id = contents.id)
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


=begin
THIS CASE IS BROKEN.
  it 'should search using a generic id' do
    q = Content::Query.
      new(:params => { :country_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, content_keys, languages, countries, brands, applications, mime_types, revision_list_contents, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)


ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end
=end


  it 'should search by revision_list_id' do
    q = Content::Query.
      new(
          :params => { :revision_list_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, content_keys, languages, countries, brands, applications, mime_types, revision_list_contents, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (revision_list_contents.revision_list_id   = 123)
AND (revision_list_contents.content_version_id = contents.id)
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should search by revision_list_name' do
    q = Content::Query.
      new(
          :params => { :revision_list_name => 'production' }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, content_keys, languages, countries, brands, applications, mime_types, revision_list_names, revision_lists, revision_list_contents, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (revision_list_names.name               = E'production')
AND (revision_list_contents.revision_list_id   = revision_list_names.revision_list_id)
AND (revision_list_contents.content_version_id = contents.id)
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should search using a simple user_query' do
    q = Content::Query.
      new(:user_query => '  %foo_bar%  '
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (contents.uuid LIKE E'%foo_bar%')
OR  (contents.md5sum LIKE E'%foo_bar%')
OR  (convert_from(contents.data, 'UTF8') LIKE E'%foo_bar%')
OR  (content_keys.code LIKE E'%foo_bar%')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should search using a user_query with additional selection AND clauses' do
    q = Content::Query.
      new(:user_query => '  content_type:phrase language:en %foo_bar%  ', 
          :params => { :id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM contents AS contents, content_keys, languages, countries, brands, applications, mime_types, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (
    (contents.id = E'123')
    )
AND (
    (contents.uuid LIKE E'%foo_bar%')
OR  (contents.md5sum LIKE E'%foo_bar%')
OR  (convert_from(contents.data, 'UTF8') LIKE E'%foo_bar%')
OR  (content_keys.code LIKE E'%foo_bar%')
    )
AND (
    (content_types.code = E'phrase')
AND (languages.code = E'en')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end


  it 'should search using a user_query and revision_list_id' do
    q = Content::Query.
      new(:user_query => '  content_type:email country:US %foo_bar%  ', 
          :params => { :revision_list_id => 123 }
          )
    (q.sql + "\n").should == <<"END"
SELECT contents.*
FROM content_versions AS contents, content_keys, languages, countries, brands, applications, mime_types, revision_list_contents, content_types
WHERE
    (content_keys.id = contents.content_key_id)
AND (languages.id = contents.language_id)
AND (countries.id = contents.country_id)
AND (brands.id = contents.brand_id)
AND (applications.id = contents.application_id)
AND (mime_types.id = contents.mime_type_id)
AND (content_types.id = content_keys.content_type_id)

AND (revision_list_contents.revision_list_id   = 123)
AND (revision_list_contents.content_version_id = contents.id)
AND (
    (contents.uuid LIKE E'%foo_bar%')
OR  (contents.md5sum LIKE E'%foo_bar%')
OR  (convert_from(contents.data, 'UTF8') LIKE E'%foo_bar%')
OR  (content_keys.code LIKE E'%foo_bar%')
    )
AND (
    (content_types.code = E'email')
AND (countries.code = E'US')
    )
ORDER BY
  (SELECT content_keys.code FROM content_keys WHERE content_keys.id = content_key_id),
  (SELECT languages.code FROM languages WHERE languages.id = language_id),
  (SELECT countries.code FROM countries WHERE countries.id = country_id),
  (SELECT brands.code FROM brands WHERE brands.id = brand_id),
  (SELECT applications.code FROM applications WHERE applications.id = application_id),
  (SELECT mime_types.code FROM mime_types WHERE mime_types.id = mime_type_id)
END
  end

end

