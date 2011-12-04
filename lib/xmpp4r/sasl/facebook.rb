# -*- coding: utf-8 -*-

module Jabber
  module SASL
    class Facebook < Base
      SERVER = 'chat.facebook.com'
      MECHANISM = 'X-FACEBOOK-PLATFORM'
      API_VERSION = '1.0'

      attr_reader :access_token
      attr_reader :app_key
      attr_reader :call_id
      attr_reader :method
      attr_reader :nonce

      def initialize(stream, app_key, access_token)
        super(stream)

        challenge = {}
        error = nil
        @stream.send(generate_auth(MECHANISM)) { |reply|
          if reply.name == 'challenge' and reply.namespace == NS_SASL
            challenge = decode_challenge(reply.text)
          else
            error = reply.first_element(nil).name
          end
          true
        }
        raise error if error

        @nonce = challenge['nonce'].first
        @method = challenge['method'].first
        @app_key = app_key
        @access_token = access_token
        @call_id = 0
      end

      def auth(password)
        response = {}
        response['method'] = @method
        response['nonce'] = @nonce
        response['access_token'] = @access_token
        response['api_key'] = @api_key
        response['call_id'] = @call_id
        response['v'] = API_VERSION
        @call_id += 1

        response_text = encode_url(response)
        Jabber::debuglog("SASL #{MECHANISM} response:\n#{response_text}\n#{response.inspect}")

        r = REXML::Element.new('response')
        r.add_namespace NS_SASL
        r.text = encode_base64 response_text

        success_already = false
        error = nil
        @stream.send(r) { |reply|
          if reply.name == 'success'
            success_already = true
          elsif reply.name != 'challenge'
            error = reply.first_element(nil).name
          end
          true
        }

        return if success_already
        raise error if error

        # TODO: check the challenge from the server

        r.text = nil
        @stream.send(r) { |reply|
          if reply.name != 'success'
            error = reply.first_element(nil).name
          end
          true
        }

        raise error if error
      end

      def decode_challenge(challenge)
        text = decode_base64 challenge
        res = decode_url text

        Jabber::debuglog("SASL #{MECHANISM} challenge:\n#{text}\n#{res.inspect}")

        res
      end

      def decode_base64(string)
        Base64::decode64 string
      end

      def encode_base64(string, with_gsub=true)
        res = Base64::encode64 string
        if with_gsub
          res.gsub(/\s/, '')
        else
          res
        end
      end

      def decode_url(string)
        CGI::parse string
      end

      def encode_url(hash)
        hash.map { |key, value| "#{CGI.escape key}=#{CGI.escape value.to_s}"}.join('&')
      end
    end

    class << self
      def new_with_facebook(stream, mechanism)
        if mechanism == 'X-FACEBOOK-PLATFORM' or mechanism == 'FACEBOOK'
          Facebook.new(stream)
        else
          new_without_facebook(stream, mechanism)
        end
      end

      # alias_method_chain :new, :facebook
      alias_method :new_without_facebook, :new
      alias_method :new, :new_with_facebook
    end
  end
end
