#!/usr/bin/env ruby

#    OpenRA Replay Sanitizer: Program/library to parse and generate
#    OpenRA replay files
#
#    Copyright (C) 2018  Luke Spangler
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.

#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

require 'openrareplay/miniyaml'

module OpenRAReplay
  module Sanitize
    class PacketSanitizer
      attr_reader :ping, :message, :chat, :ip, :time, :password,
                  :player_name, :server_name, :player_map

      def initialize(options = {})
        @ping = options[:ping]
        @message = options[:message]
        @chat = options[:chat]
        @ip = options[:ip]
        @time = options[:time]
        @password = options[:password]
        @player_name = options[:player_name]
        @server_name = options[:server_name]
        @player_map = {}
      end
      
      def sanitize_packet(packet)
        return sanitize_packet_metadata(packet) if packet.metadata?
        return sanitize_packet_normal(packet) unless packet.unknown?
        packet
      end
      
      private
      
      def sanitize_packet_metadata(packet)
        object = OpenRAReplay::MiniYaml.load(packet.data)
        time_placeholder = sanitize_time_packet object if time
        object.each_key do |key|
          player = key.match(/^Player@(\d+)$/)
          next unless player
          sanitize_time_player object, key, time_placeholder if time
          sanitize_name object, key if player_name
        end
        packet.class.new(data: OpenRAReplay::MiniYaml.dump(object))
      end
      
      def sanitize_packet_normal(packet)
        packet.class.new(
          client_id: packet.client_id,
          frame: packet.frame,
          orders: packet.orders.reject { |o|
            (ping && (o.command.match('Ping') || o.command == 'Pong')) ||
            (message && o.command == 'Message') || (chat &&
            (o.command == 'Chat') || o.command == 'TeamChat')
          }.map {|o| sanitize_order o }
        )
      end
      
      def sanitize_order(order)
        return order unless (order.command.match('Sync') ||
                            order.command.match('Handshake'))
        object = OpenRAReplay::MiniYaml.load order.data
        sanitize_password object if password
        sanitize_server_name object if server_name
        object.each_key do |key|
          next unless (key == 'Client' || key =~ /^Client@\d+$/)
          sanitize_name object, key if player_name
          sanitize_ip object, key if ip
        end
        order = order.class.new(
          command: order.command,
          data: OpenRAReplay::MiniYaml.dump(object)
        )
      end
      
      def sanitize_time_packet(object)
        start_time = OpenRAReplay::MiniYaml.load_time(object['Root']['StartTimeUtc'])
        epoch = Time.at(0).utc
        start_time = start_time.to_i
        stop_time = OpenRAReplay::MiniYaml.load_time(object['Root']['EndTimeUtc']) - start_time
        object['Root']['StartTimeUtc'] = OpenRAReplay::MiniYaml.dump_time(epoch)
        object['Root']['EndTimeUtc'] = OpenRAReplay::MiniYaml.dump_time(stop_time)
        start_time
      end
      
      def sanitize_time_player(object, key, start_time)
        object[key]['OutcomeTimestampUtc'] = OpenRAReplay::MiniYaml.dump_time(OpenRAReplay::MiniYaml.load_time(object[key]['OutcomeTimestampUtc']) - start_time)
      end
      
      def sanitize_password(object)
        object['Handshake']['Password'] = nil if object['Handshake'] && object['Handshake']['Password']
      end
      
      def sanitize_server_name(object)
        object['GlobalSettings']['ServerName'] = nil if object['GlobalSettings'] && object['GlobalSettings']['ServerName']
      end
      
      def sanitize_ip(object, key)
        object[key]['IpAddress'] = nil if object[key]['IpAddress']
      end
      
      def sanitize_name(object, key)
        return unless !object[key]['IsBot'] && object[key]['Name']
        unless player_map[object[key]['Name']]
          @player_map[object[key]['Name']] = "Player #{player_map.length + 1}"
        end
        object[key]['Name'] = player_map[object[key]['Name']]
      end
    end
  end
end
