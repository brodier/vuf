module Vuf
  Logger = Log4r::Logger.new self.name
  Logger.outputters = Log4r::Outputter.stderr
  Logger.level=Log4r::INFO
end
