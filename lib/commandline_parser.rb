$LOAD_PATH << File.dirname(__FILE__)

require 'getoptlong'
require 'rdoc/usage'
require 'osx/cocoa'
require 'version'

class CommandlineParser

  include OSX
  include Singleton

  attr_accessor :source                   # NSURL
  attr_accessor :output                   # String
  attr_accessor :paperSize                # NSSize
  attr_accessor :paginate                 # boolean
  attr_accessor :margin                   # float
  attr_accessor :stylesheetMedia          # String
  attr_accessor :printBackground          # boolean
  attr_accessor :paperOrientation         # NSPrintingOrientation
  attr_accessor :horizontallyCentered     # boolean
  attr_accessor :verticallyCentered       # boolean
  attr_accessor :cachingPolicy            # NSURLRequestCachePolicy
  attr_accessor :timeout                  # NSTimeInterval (float, seconds?)
  attr_accessor :saveDelay                # NSTimeInterval (float, seconds?)
  attr_accessor :enablePlugins            # boolean
  attr_accessor :ignoreHttpErrors         # boolean
  attr_accessor :username                 # String
  attr_accessor :password                 # String

  def configure_defaults

    # @@source = [NSURL fileURLWithPath:@"/dev/stdin"];
    # @@output = @"/dev/stdout";

    @paperSize = NSPrintInfo.sizeForPaperName('A4')
    @paginate = true
    @margin = -1.0
    @stylesheetMedia = ""
    @printBackground = false
    @paperOrientation = NSPortraitOrientation
    @horizontallyCentered = false
    @verticallyCentered = false
    @cachingPolicy = NSURLRequestUseProtocolCachePolicy
    @timeout = 3600.0
    @saveDelay = 0.0
    @enablePlugins = false
    @ignoreHttpErrors = false
    @username = ""
    @password = ""
  
  end
  
  def parse_commandline

    configure_defaults
    
    opts = GetoptLong.new(
      [ '--source',               GetoptLong::REQUIRED_ARGUMENT],
      [ '--output',               GetoptLong::REQUIRED_ARGUMENT],
      [ '--format',               GetoptLong::REQUIRED_ARGUMENT],
      [ '--portrait',             GetoptLong::NO_ARGUMENT],
      [ '--landscape',            GetoptLong::NO_ARGUMENT],
      [ '--hcenter',              GetoptLong::NO_ARGUMENT],
      [ '--vcenter',              GetoptLong::NO_ARGUMENT],
      [ '--help','-h',            GetoptLong::NO_ARGUMENT],
      [ '--caching',              GetoptLong::REQUIRED_ARGUMENT],
      [ '--timeout',              GetoptLong::REQUIRED_ARGUMENT],
      [ '--version',              GetoptLong::NO_ARGUMENT],
      [ '--margin',               GetoptLong::REQUIRED_ARGUMENT],
      [ '--stylesheet-media',     GetoptLong::REQUIRED_ARGUMENT],
      [ '--print-background',     GetoptLong::REQUIRED_ARGUMENT],
      [ '--ignore-http-errors',   GetoptLong::NO_ARGUMENT],
      [ '--username',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--password',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--paginate',             GetoptLong::REQUIRED_ARGUMENT],
      [ '--enable-plugins',       GetoptLong::REQUIRED_ARGUMENT],
      [ '--save-delay',           GetoptLong::REQUIRED_ARGUMENT]
    )

  
  opts.each do |opt, arg|
    case opt
      when '--source'
        @source = parseSourcePathOrURL(arg)
      when '--output'
        @output = parseOutputPath(arg)
      when '--format'
        @paperSize = parsePaperSize(arg)
      when '--portrait'
        @paperOrientation = NSPortraitOrientation
      when '--landscape'
        @paperOrientation = NSLandscapeOrientation
      when '--hcenter'
        @horizontallyCentered = true
      when '--vcenter'
        
      when '--help', '-h'
        puts(CommandlineParser.usage())
        NSApplication.sharedApplication.terminate(nil)
      when '--caching'
        if (arg == "no") then
          @cachingPolicy = NSURLRequestUseProtocolCachePolicy
        else
          @cachingPolicy = NSURLRequestUseProtocolCachePolicy
        end
      when '--timeout'
        @timeout = Float(arg)
      when '--version'
        puts "#{Wkpdf::VERSION::STRING}\n"
        NSApplication.sharedApplication.terminate(nil)
      when '--margin'
        @margin = Float(arg)
      when '--stylesheet-media'
        @stylesheetMedia = arg
      when '--print-background'
        @printBackground = true if (arg == "yes")
      when '--ignore-http-errors'
        @ignoreHttpErrors = (arg == "yes")
      when '--username'
        @username = arg
      when '--password'
        @password = arg
      when '--paginate'
        @paginate = (arg == "yes")
      when '--enable-plugins'
        @enablePlugins = (arg == "yes")
      when '--save-delay'
        @saveDelay = Float(arg)
    end

   end
  end
  
  def CommandlineParser.usage()

    # "  --caching arg     set caching policy (valid values are: yes, no) default is yes\n"
    # "  --timeout arg     set timeout in seconds, default: no timeout\n"

    msg =<<-END
usage: wkpdf <options>

  --source URL|file         URL or file to be converted to PDF (mandatory)  
  --output file             filename for the PDF (mandatory)
  --portrait                use portrait paper orientation
  --landscape               use landscape paper orientation
  --hcenter                 center output horizontally
  --vcenter                 center output vertically
  --format arg              select paper format (valid values are e.g. A4, A5
                            A3, Legal, Letter, Executive) CAUTION: these values
                            are case-sensitive
  --paginate arg            enable pagination of output (yes|no default: yes)
                            Output page is resized to fit content when paginate=no
  --margin arg              set paper margin in points (same value is used for
                            all 4 margins)
  --stylesheet-media arg    set the CSS media value (default: 'screen')
  --print-background arg    display background images (yes|no default: no)
  --enable-plugins arg      enable plugins (yes|no default: no)
  --ignore-http-errors      generate PDF even if server error occur (e.g.
                            server returns 404 Not Found errors.)
  --save-delay arg          wait x.y seconds after page is loaded
                            before generating the PDF
  --username arg            authenticate with this username
  --password arg            authenticate with this password
                            pages with HTTP authentication can also be accessed
                            by using user:password@example.org style URLs
  --help                    print help on options
  --version                 print version number

For further information refer to http://wkpdf.plesslweb.ch
  END
  
  end
  
  def parseSourcePathOrURL(arg)
    argAsString = NSString.stringWithUTF8String(arg)
    path = argAsString.stringByExpandingTildeInPath
    fm = NSFileManager.defaultManager
    if fm.fileExistsAtPath(path) then
      url = NSURL.fileURLWithPath(path)
    else
      url = NSURL.URLWithString(argAsString)
    end

    # check URL validity
    supportedSchemes = NSArray.arrayWithObjects("http", "https", "ftp", "file", nil)
    scheme = url.scheme
    if scheme.nil? || (supportedSchemes.indexOfObject(scheme.lowercaseString) == NSNotFound) then
      puts "#{argAsString} is neither a filename nor an URL with a supported scheme (http,https,ftp,file)\n"
       NSApplication.sharedApplication.terminate(nil)
    end

    return url.absoluteString
  end

  def parseOutputPath(arg)
    argAsString = NSString.stringWithUTF8String(arg)
    path = argAsString.stringByExpandingTildeInPath
    return path
  end

  def parsePaperSize(arg)
    paperName = NSString.stringWithUTF8String(arg)
    size = NSPrintInfo.sizeForPaperName(paperName)
    if ((size.width == 0.0) || (size.height == 0.0)) then
      puts "#{paperName} is not a valid paper format\n"
      NSApplication.sharedApplication.terminate(nil)
    end
    return size
  end

end
