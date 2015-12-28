require "thread/repository"

require "./channel"
require "./mask"
require "./message"
require "./membership"
require "./modes"
require "./user"

module IRC
  class UserManager
    def initialize
      @users = Repository(String, User).new
    end

    def register_handlers(connection)
      connection.on Message::RPL_NAMREPLY do |message|
        channel = connection.channels[message.parameters[2]]

        message.parameters.last.split(' ').each do |user|
          mode = user.chars.first
          user = user[1..-1] if {'@', '+'}.includes? mode

          membership = join Mask.parse(user), channel
          membership.modes.set 'o' if mode == '@'
          membership.modes.set 'v' if mode == '+'
        end
      end

      connection.on Message::JOIN do |message|
        channel = connection.channels[message.parameters.first]

        with_mask(message) do |mask|
          if connection.network.extended_join?
            authname = message.parameters[1]
            authname = false if authname == "*"
            realname = message.parameters.last
            user     = find_user(mask)

            join mask, channel, authname
            user.realname = realname
          else
            join mask, channel
          end
        end
      end

      connection.on Message::PART do |message|
        with_mask(message) do |mask|
          channel = connection.channels[message.parameters.first]
          if mask.nick == connection.config.nick
            connection.part channel.name
          else
            part mask, channel
          end
        end
      end

      connection.on Message::QUIT do |message|
        with_mask(message) do |mask|
          quit mask
        end
      end

      connection.on Message::KICK do |message|
        channel, nick = message.parameters
        if nick == connection.config.nick
          connection.part channel
        else
          kick Mask.parse(nick), connection.channels[channel]
        end
      end

      connection.on Message::NICK do |message|
        with_mask(message) do |mask|
          nick = message.parameters.first
          nick mask, nick
        end
      end

      connection.on Message::ACCOUNT do |message|
        with_mask(message) do |mask|
          authname = message.parameters.first
          authname = false if authname == "*"

          auth_change mask, authname
        end
      end

      connection.on Message::RPL_WHOISUSER do |message|
        _me, nick, user, host, _unused, realname = message.parameters
        user = find_user Mask.parse(nick)
        user.mask.user = user
        user.mask.host = host
        user.realname = realname
      end

      connection.on Message::RPL_WHOISACCOUNT do |message|
        _me, nick, account = message.parameters
        user = find_user(Mask.parse(nick))
        user.authname = account
      end

      connection.on Message::MODE do |message|
        target = message.parameters.first
        modes  = message.parameters[1..-1].join(' ')

        if target.starts_with? "#"
          Modes::Parser.parse(modes) do |modifier, flag, parameter|
            if parameter && Channel::MEMBERHSIP_MODES.includes?(flag)
              mask      = Mask.parse(parameter)
              parameter = nil unless {'b', 'e', 'I', 'q'}.includes?(flag)
              channel   = connection.channels[target]

              cmode mask, channel, flag, (modifier == '+'), parameter
            end
          end
        else
          user = find_user Mask.parse(target)

          user.modes.parse modes
        end
      end
    end

    def with_mask(message)
      if prefix = message.prefix
        mask = Mask.parse prefix
        yield mask
      end
    end

    def find_user(mask : Mask)
      @users.fetch(mask.nick) { User.new(mask) }.tap &.mask.update(mask)
    end

    def find_membership(mask, channel : Channel)
      find_user(mask).channels.fetch(channel.name) { Membership.new(channel) }
    end

    def track(mask)
      find_user mask
    end

    def nick(mask, new_nick)
      find_user(mask).tap do |user|
        @users.rename(mask.nick, new_nick)
        user.mask.nick = new_nick
      end
    end

    def join(mask, channel, authname=nil)
      find_user(mask).authname = authname if authname
      find_membership(mask, channel).tap &.join
    end

    def part(mask, channel)
      find_membership(mask, channel).tap &.part
    end

    def kick(mask, channel)
      part mask, channel
    end

    def quit(mask)
      @users.delete(mask.nick)
    end

    def auth_change(mask, authname)
      find_user(mask).tap &.authname=(authname)
    end

    def umode(mask, flag, gained)
      find_user(mask).tap &.mode(flag, gained)
    end

    def cmode(mask, channel, flag, gained, parameter=nil)
      find_membership(mask, channel).tap &.mode(flag, gained, parameter)
    end
  end
end
