require 'tmpdir'
require 'logger'

module Xi::Logger
  LOG_FILE = File.join(Dir.tmpdir, 'xi.log')

  def logger
    @@logger ||= begin
      logger = ::Logger.new(LOG_FILE)
      logger.formatter = proc do |severity, datetime, progname, msg|
        "[#{datetime.strftime("%F %T %L")}] #{msg}\n"
      end
      logger
    end
  end

  def debug(*args)
    logger.debug(args.map(&:to_s).join(' '.freeze))
  end

  def error(error)
    logger.error("#{error}:\n#{error.backtrace.join("\n".freeze)}")
    ErrorLog.instance << error.to_s
  end
end
