require 'pp'

# A mishmash of different test-related utilities.
#   -- kurt AT cashnetusa.com 2007/09/28
class TestController < ApplicationController
  
  before_filter :verify_authenticity_token, :except => [ :_ ]

  before_filter :not_production


  # Security through obscurity.
  def index
    redirect_to '/'
  end


# Actions are disabled for production.
if RAILS_ENV != 'production' 

  # Diagnostic Swiss-army Knife.
  #
  # Example: 
  #   http://localhost:3000/test/_?q=ENV
  #   http://localhost:3000/test/_?q=Loan.connection
  #   http://localhost:3000/test/_?q=Loan.find+34
  #
  # Allow for optional 'text-only' flag:
  #   http://localhost:3000/test/_?q=CnuConfig.database.to_yaml&t=true
  def _
    expr = params[:q] || params[:id] || 'nil'
    ascii = params[:t]
    ascii_flg = false
    result = nil
    err = nil
    begin
      result = eval(expr, binding)
      result = pp_to_s(result)
      ascii_flg = ascii && eval(ascii, binding)
    rescue Exception => err
      result = "ERROR:\n#{err.inspect}\n#{err.backtrace.join("\n")}"
    ensure 
    end

    if ascii_flg
      text = result
      render :text => text, :layout => false
    else
      text = ''
      text += %Q{<p>Expr:</p>\n}
      text += %Q{<form action="_" method="post">\n}
      text += %Q{<textarea name="q" cols="50" rows="5">#{text_to_html(expr, false)}</textarea><br \>\n}
      text += %Q{<input type="submit" name="Eval" /><br />\n}
      text += %Q{</form>\n}
      if err
        text += %Q{<p>Error:</p>\n}
        text += %Q{#{text_to_html(err.inspect)}\n}
      end

      text += %Q{<p>Result:</p>\n}
      # text += %Q{<textarea name="result" cols="50" rows="10">#{text_to_html(result, false)}</textarea>\n} 
      text += %Q{#{text_to_html(result)}\n}
      render :text => text, :layout => false
    end
  end


  def raise_mongrel_timeout
    $stderr.puts "#{$$}: sending Mongrel::TimeoutError"
    raise Mongrel::TimeoutError, "#{self.class}"
  end


  # Use this to terminate webrick under rcov/ruby-prof.
  def graceful_exit
    logger.info "graceful_exit"
    # Find any 
    ObjectSpace.each_object(WEBrick::GenericServer) do | obj |
      logger.info "Telling #{obj} to shutdown..."
      obj.shutdown
    end
    render :text => "WEBrick should have stopped, check logs.", :layout => false
  end


  def fork_test
    $stderr.puts "#{$$}: forking..."
    
    cpid = fork do 
      10.times do 
        sleep 1
        $stderr.puts "#{$$}: Wheee!: running in another process"
      end
      $stderr.puts "#{$$}: exiting"
      exit
    end
    msg = "#{$$}: forked child #{cpid}"
    $stderr.puts msg
    render :text => "#{msg}, check $stderr", :layout => false
  end

end # if ! production and enabled

private

  def not_production
    if RAILS_ENV == 'production'
      redirect_to '/'
      return false
    end
  end

  def pp_to_s(x)
    out_old = $>
    $> = StringIO.new
    pp(x)
    result = $>.string
  ensure
    $> = out_old
    result
  end
  
  
  def text_wrap(result, len = 78)
    result = result.split("\n").map{|x| ' ' + x}
    result = result.map do | l |
      y = [ ]
      l = ' ' + l
      while l.size > len
        y << l[0 .. len] + "\\"
        l = '+' + l[len .. l.size]
      end
      y << l
    end.flatten.join("\n")
    result
  end
  
  
  def text_to_html(x, wrap_and_pre = true)
    x = text_wrap(x) if wrap_and_pre
    x.gsub!('&', "\01")
    x.gsub!('<', '&lt;')
    x.gsub!('>', '&gt;')
    x.gsub!("\01", '&amp;')
    x = "<pre>\n" + x + "\n</pre>\n" if wrap_and_pre
    x
  end
  
  
  def pp_to_html(x)
    x = pp_to_s(x)
    x = text_to_html(x)
  end
  
  
end


