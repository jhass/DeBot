module Cinch
  module Plugins
    class Title
      alias_method :do_execute, :execute
      def exectute(m, message)
        do_execute(m, message) unless m.user.nick =~ /.*(travis|github|karmalicious).*/i 
      end
      
      def response m, title
        "[URL] #{title}"
      end
    end
  end
end
