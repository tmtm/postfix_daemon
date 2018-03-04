require "postfix_daemon/version"

require 'optparse'
require 'socket'
require 'syslog'

# Postfix daemon program
class PostfixDaemon
  DEFAULT_MAX_IDLE = 100
  DEFAULT_MAX_USE = 100

  MASTER_STATUS_FD = 5
  MASTER_LISTEN_FD = 6

  # @param args [Array<String>] command line arguments
  # @yield [socket, addr]
  # @yieldparam socket [Socket]
  # @yieldparam addr [Addrinfo]
  def self.start(args=ARGV, &block)
    self.new(args).run(&block)
  end

  # @param args [Array<String>] command line arguments
  # @param setup [Proc] called on starting
  # @param service [Proc] called when client connect
  def initialize(args, setup: nil, service: nil)
    @args = args.dup
    @setup = setup
    @service = service
    @nsocks = nil
    @max_idle = nil
    @max_use = nil
  end

  # @yield [socket, addr]
  # @yieldparam socket [Socket]
  # @yieldparam addr [Addrinfo]
  def run(&block)
    parse_args
    setup
    @setup.call if @setup
    @service = block if block
    raise 'block required' unless @service
    main
  end

  private

  # general Postfix server options:
  #   -c              master.cf chroot is y, so this process should chroot to queue_directory.
  #   -d              not daemon mode
  #   -D              debug mode
  #   -i #            set max_idle=#
  #   -l              master.cf maxproc is 1
  #   -m #            set max_use=#
  #   -n name         master.cf service name
  #   -o param=value  param=value
  #   -s #            number of server sockets
  #   -S              stdin stream mode
  #   -t type         master.cf service type (inet, unix, pass)
  #   -u              master.cf unpriv is y, so this process should setuid to mail_owner.
  #   -v              verbose mode
  #   -V              message to stderr
  #   -z              master.cf maxproc is 0
  #
  # This library support only '-s', '-i', '-m' option.
  def parse_args
    @args.extend OptionParser::Arguable
    opts = @args.getopts('cdDi:lm:n:o:s:St:uvVz')
    @nsocks = opts['s'] ? opts['s'].to_i : 1
    @max_idle = opts['i'] ? opts['i'].to_i : DEFAULT_MAX_IDLE
    @max_use = opts['m'] ? opts['m'].to_i : DEFAULT_MAX_USE
    $VERBOSE = true if opts['v']
  end

  def setup
    Syslog.open(File.basename($0), nil, Syslog::LOG_MAIL) unless Syslog.opened?
    @socks = []
    fd = MASTER_LISTEN_FD
    @nsocks.times do
      @socks.push Socket.for_fd(fd)
      fd += 1
    end
    @stat_fd = IO.for_fd(MASTER_STATUS_FD)
    @generation = ENV['GENERATION'].to_i(8)
  end

  def log(message)
    Syslog.log(Syslog::LOG_INFO, message) if $VERBOSE
  end

  def main
    used_count = 0
    while used_count < @max_use
      sock, addr = accept
      break unless sock
      to_master(0) or break
      used_count += 1
      begin
        @service.call(sock, addr)
      ensure
        sock.close rescue nil
        to_master(1) or break
      end
    end
  rescue => e
    log "#{e.class}: #{e.message}"
    raise e
  end

  # @return [Socket, Addrinfo]
  def accept
    while true
      rs, = select(@socks + [@stat_fd], nil, nil, @max_idle)
      unless rs
        log 'idle timeout'
        return nil
      end
      if rs.include? @stat_fd
        log 'master disconnect'
        return nil
      end
      sock, addr = rs.first.accept_nonblock(exception: false)
      return sock, addr unless sock == :wait_readable
    end
  end

  # @param x [Integer]
  # @return [Boolean]
  def to_master(x)
    @stat_fd.syswrite [Process.pid, @generation, x].pack('iIi')
    return true
  rescue Errno::EPIPE
    log 'master disconnect'
    return false
  end
end
