require 'logger'
require 'time'

time_zero = Time.now

$log = Logger.new(STDOUT)
$log.level = Logger::INFO
$log.formatter = proc do |severity, time, progname, msg|
  level = Logger.const_get(severity)

  color = if level > Logger::INFO
    # Something bad
    '0;31' # red
  elsif /\d+\.\d+\.\d+\.\d+/ =~ progname
    # Running a command
    '0;32' # green
  else
    '0;36' # cyan
  end

  diff_in_s = time - time_zero

  "#{severity[0..0]} #{sprintf('%.3f', diff_in_s)} \e[#{color}m#{progname}: #{msg}\e[0m\n"
end
