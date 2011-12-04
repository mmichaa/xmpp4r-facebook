require 'rubygems'
require 'getoptlong'
require 'json'

opts = GetoptLong.new(
  ['--access_token', '-t', GetoptLong::REQUIRED_ARGUMENT],
  ['--app_key', '-a', GetoptLong::REQUIRED_ARGUMENT],
  ['--user_id', '-u', GetoptLong::REQUIRED_ARGUMENT]
)

access_token = nil
app_key = nil
user_id = nil
json = nil
opts.each do |opt, arg|
  case opt
  when '--access_token'
    access_token = arg
  when '--app_key'
    app_key = arg
  when '--user_id'
    user_id = arg.dup
  end
end


require 'xmpp4r'
require 'xmpp4r/roster'

$LOAD_PATH << '../lib'
require 'xmpp4r/facebook'

Jabber::debug = true
jid = Jabber::JID::new(user_id, Jabber::SASL::Facebook::SERVER, Jabber::SASL::Facebook::RESOURCE)
clt = Jabber::Client::new(jid)
clt.connect
sfb = Jabber::SASL::Facebook.new(clt, app_key, access_token)
clt.auth_sasl(sfb, nil)
clt.add_message_callback { |stanza|
  puts "* Got Message for you:\n** From: #{stanza.from}\n**Type: #{stanza.type}\n** Body: #{stanza.body}"
}

rst = Jabber::Roster::Helper.new(clt)
rst.wait_for_roster
rst.items.each { |jid, item|
  puts "* #{jid.to_s} | #{item.iname} | #{item.online? ? 'on' : 'off'}"
}

require 'pry'
binding.pry
