require "thread/repository"

require "./bot"

module Framework
  record User, irc_user : IRC::User, context : Bot do
    delegate mask,     irc_user
    delegate realname, irc_user
    delegate nick,     irc_user
    delegate user,     irc_user
    delegate host,     irc_user
    delegate modes,    irc_user

    def self.from_nick(nick : String, context : Bot)
      from_mask nick, context
    end

    def self.from_mask(mask : String, context : Bot)
      from_mask IRC::Mask.parse(mask), context
    end

    def self.from_mask(mask : IRC::Mask, context : Bot)
      user = context.connection.users.find_user(mask)
      new user, context
    end

    def send(text : String)
      Message.new(@context, nick, text).send
    end

    def action(text : String)
      Message.new(@context, nick, text).as_action.send
    end

    def authname
      authname = irc_user.authname

      if authname.nil?
        context.connection.send IRC::Message::WHOIS, nick
        context.connection.await(IRC::Message::RPL_WHOISACCOUNT,
                                 IRC::Message::RPL_ENDOFWHOIS,
                                 IRC::Message::ERR_NOSUCHNICK) do |message|
          message.parameters[1] == nick
        end
      end

      irc_user.authname
    end
  end
end
