#!/usr/bin/env ruby
require 'postfix_daemon'

PostfixDaemon.start do |socket|
  while s = socket.gets
    socket.puts s.upcase
  end
end
