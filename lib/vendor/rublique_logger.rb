
# modified - we prefer regular json

class RubliqueLogger
  class << self
    @@path = '/tmp/rublique.log'
    @@log = nil
    def file=(path)
      raise 'Cannot change Railique log path after logfile has been opened' unless @@log.nil?
      @@path = path
    end

    def log
      if @@log.nil?
        @@log = File.open(@@path, 'a+')
        @@log.sync = true
      end

      delta = Rublique.delta
      @@log.write [Time.now.strftime('%Y-%m-%d %H:%M:%S'), delta].to_json + "\n" unless delta.empty?
      delta
    end
  end
end
