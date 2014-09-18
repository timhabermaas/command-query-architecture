class AuthHandler
  class Unauthorized < StandardError
  end

  def initialize(policy, handler)
    @policy = policy
    @handler = handler
  end

  def handle(command)
    raise Unauthorized unless @policy.can?(command)
    @handler.handle(command)
  end
end

class LogHandler
  def initialize(handler)
    @handler = handler
  end

  def handle(command)
    start = Time.now
    puts "[Command] #{command.class.to_s.split('::').last}/#{command.attributes}"
    begin
      @handler.handle(command)
    rescue Exception => e
      puts "[Command Failed] with: #{e.message}"
      raise e
    ensure
      time = Time.now - start
      puts "[/Command] #{command.class.to_s.split('::').last} in #{time}s"
      puts
    end
  end
end
