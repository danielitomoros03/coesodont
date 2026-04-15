class Section
  module UserAgentParser
    module_function

    def call(ua)
      return nil if ua.blank?
      "#{os(ua)} · #{browser(ua)}".gsub(/\s*·\s*\z/, '')
    end

    def os(ua)
      case ua
      when /Windows NT 10/ then 'Windows 10/11'
      when /Windows NT 6\.3/ then 'Windows 8.1'
      when /Windows NT 6\.2/ then 'Windows 8'
      when /Windows NT 6\.1/ then 'Windows 7'
      when /Windows/ then 'Windows'
      when /iPhone|iPad|iPod/ then ios_version(ua)
      when /Android/ then android_version(ua)
      when /Mac OS X/ then mac_version(ua)
      when /CrOS/ then 'ChromeOS'
      when /Linux/ then 'Linux'
      else 'Otro'
      end
    end

    def browser(ua)
      case ua
      when /Edg\//      then "Edge #{ua[%r{Edg/([\d.]+)}, 1]}"
      when /OPR\//      then "Opera #{ua[%r{OPR/([\d.]+)}, 1]}"
      when /Chrome\//   then "Chrome #{ua[%r{Chrome/([\d.]+)}, 1]&.split('.')&.first}"
      when /Firefox\//  then "Firefox #{ua[%r{Firefox/([\d.]+)}, 1]&.split('.')&.first}"
      when /Safari\//   then "Safari #{ua[%r{Version/([\d.]+)}, 1]}"
      else ''
      end
    end

    def ios_version(ua)
      v = ua[%r{OS (\d+[_\d]*)}, 1]&.tr('_', '.')
      device = ua.include?('iPad') ? 'iPad' : 'iPhone'
      v ? "#{device} iOS #{v}" : device
    end

    def android_version(ua)
      v = ua[%r{Android ([\d.]+)}, 1]
      v ? "Android #{v}" : 'Android'
    end

    def mac_version(ua)
      v = ua[%r{Mac OS X (\d+[_\d]*)}, 1]&.tr('_', '.')
      v ? "macOS #{v}" : 'macOS'
    end
  end
end
