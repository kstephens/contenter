require 'contenter/content_converter'

require 'pp'

describe "Contenter::Converter" do
  Content = Contenter::ContentConverter::Content
  Converter = Contenter::ContentConverter

  def ascii_file
    @ascii_file ||= Content.new(:file => File.dirname(__FILE__) + '/etc/ascii')
  end

  def ascii_data
    @ascii_data ||= Content.new(:data => File.read(ascii_file.file.to_s))
  end

  def html_file
    @html_file ||= Content.new(:file => File.dirname(__FILE__) + '/etc/html')
  end

  def html_data
    @html_data ||= Content.new(:data => File.read(html_file.file.to_s))
  end

  def png_file
    @png_file ||= Content.new(:file => File.dirname(__FILE__) + "/etc/add_16.png")
  end

  def png_data
    @png_data ||= Content.new(:data => File.read(png_file.file.to_s))
  end

  def gif_file
    @gif_file ||= Content.new(:file => File.dirname(__FILE__) + "/etc/loading.gif")
  end

  def gif_data
    @gif_data ||= Content.new(:data => File.read(gif_file.file.to_s))
  end


  it "should handle file_type" do
    ascii_file.file_type.should =~ /ASCII/
    ascii_data.file_type.should =~ /ASCII/
    html_file.file_type.should =~ /HTML/
    html_data.file_type.should =~ /HTML/
    png_file.file_type.should =~ /PNG image/
    png_data.file_type.should =~ /PNG image/
    gif_file.file_type.should =~ /GIF image/
    gif_data.file_type.should =~ /GIF image/
  end

  it "should handle mime_type" do
    ascii_file.mime_type.should == 'text/plain'
    ascii_data.mime_type.should == 'text/plain'
    html_file.mime_type.should == 'text/html'
    html_data.mime_type.should == 'text/html'
    png_file.mime_type.should == 'image/png'
    png_data.mime_type.should == 'image/png'
    gif_file.mime_type.should == 'image/gif'
    gif_data.mime_type.should == 'image/gif'
  end

  it "should handle suffix" do
    ascii_file.suffix.should == '.txt'
    ascii_data.suffix.should == '.txt'
    html_file.suffix.should == '.html'
    html_data.suffix.should == '.html'
    png_file.suffix.should == '.png'
    png_data.suffix.should == '.png'
    gif_file.suffix.should == '.gif'
    gif_data.suffix.should == '.gif'
  end

  it "should handle image_size" do
    png_file.image_size.should == { :height => 16, :width => 16 }
    png_data.image_size.should == { :height => 16, :width => 16 }
    gif_file.image_size.should == { :height => 32, :width => 32 }
    gif_data.image_size.should == { :height => 32, :width => 32 }
  end

  it "should produce a html -> plain conversion" do
    src = html_file
    dst = Content.new(:suffix => '.txt', :name => src.name, :directory => "/tmp")
    c = Converter.new(:src => src, :dst => dst)
    c.convert!
    dst.suffix.should == '.txt'
    dst.mime_type.should == 'text/plain'
    dst.file.to_s.should == "/tmp/#{File.basename(src.name)}#{dst.suffix}"
    dst.data.should =~ /^\s+Google\s*$/
    # dst.unlink!
  end

  it "should produce a png -> jpeg conversion" do
    src = png_file
    dst = Content.new(:suffix => '.jpeg', :name => src.name, :directory => "/tmp")
    c = Converter.new(:src => src, :dst => dst)
    c.convert!
    dst.suffix.should == '.jpeg'
    dst.mime_type.should == 'image/jpeg'
    dst.file.to_s.should == "/tmp/#{File.basename(src.name)}#{dst.suffix}"
    `imgsize -r #{dst.file}`.chomp.should == "16 16"
    # dst.unlink!
  end

  it "should produce png data -> jpeg data conversion" do
    src = png_data
    dst = Content.new(:mime_type => 'image/jpeg')
    c = Converter.new(:src => src, :dst => dst)
    c.convert!
    dst.suffix.should == '.jpeg'
    dst.mime_type.should == 'image/jpeg'
    if RUBY_PLATFORM =~ /darwin/i
      dst.file.to_s.should =~ %r"/var/folders/.*#{dst.suffix}"
    else
      dst.file.to_s.should =~ %r"/tmp/.*#{dst.suffix}"
    end
    dst.data.size.should > 100
    dst.file_type.to_s.should =~ /JPEG/
  end

  it "should produce a png -> jpeg conversion, with scaling" do
    src = png_file
    dst = Content.new(:suffix => '.jpeg', :name => src.name, :directory => "/tmp",
                      :options => { :width => 64 })
    c = Converter.new(:src => src, :dst => dst)
    c.convert!
    dst.suffix.should == '.jpeg'
    dst.file.to_s.should == "/tmp/#{File.basename(src.name)}-64x#{dst.suffix}"
    `imgsize -r #{dst.file}`.chomp.should == "64 64"
    # dst.unlink!
  end

  it "should produce a gif -> png conversion" do
    src = gif_file
    dst = Content.new(:suffix => '.png', :name => src.name, :directory => "/tmp")
    c = Converter.new(:src => src, :dst => dst)
    c.convert!
    dst.suffix.should == '.png'
    dst.file.to_s.should == "/tmp/#{File.basename(src.name)}#{dst.suffix}"
    `imgsize -r #{dst.file}`.chomp.should == "32 32"
    # dst.unlink!
  end

  it "should produce a gif -> png conversion, with scaling" do
    src = gif_file
    dst = Content.new(:suffix => '.png', :name => src.name, :directory => "/tmp",
                      :options => { :width => 64 })
    c = Converter.new(:src => src, :dst => dst)
    c.convert!
    dst.suffix.should == '.png'
    dst.file.to_s.should == "/tmp/#{File.basename(src.name)}-64x#{dst.suffix}"
    `imgsize -r #{dst.file}`.chomp.should == "64 64"
    # dst.unlink!
  end
end
