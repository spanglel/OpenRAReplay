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

require_relative '../binary'
require_relative '../order/order'

module OpenRAReplay
  class Packet
    include Binary

    attr_reader :client_id, :length, :frame,
                :data, :orders,
                :byte_array

    SERVER_LOBBY_PACKET = 0

    def initialize(options = {})
      if options[:byte_array]
        @byte_array = options[:byte_array]
        parse_byte_array
      elsif options[:orders]
        @client_id = options[:client_id]
        @frame = options[:frame]
        @orders = options[:orders]
        construct_byte_array :orders
      elsif options[:data]
        @client_id = options[:client_id]
        @frame = options[:frame]
        @data = options[:data]
        construct_byte_array :data
      else
        raise "Improper options given to initialize! #{options}"
      end
    end

    def server_lobby_packet?
      (frame == SERVER_LOBBY_PACKET)
    end

    alias to_s byte_array

    def inspect
      byte_array.inspect
    end

    def unknown?
      if orders.length == 1
        order = orders.first
        return false unless order.order? || order.special_command?
      end
      false
    end

    def metadata?
      false
    end

    private

    def parse_byte_array
      @client_id = decode_u32 byte_array[0..3]
      @length = decode_u32 byte_array[4..7]
      @frame = decode_u32 byte_array[8..11]
      @data = byte_array[12..-1]
      @orders = []
      d = StringIO.new(data)
      @orders.append Order.construct(d) until d.eof?
    end

    def construct_byte_array(type)
      case type
      when :data
        @length = data.length + 4
        @byte_array = (encode_u32 client_id) + (encode_u32 length) +
                      (encode_u32 frame) + data
      when :orders
        @data = ''.force_encoding('ASCII-8BIT')
        orders.each do |order|
          @data += order.serialize
        end
        construct_byte_array :data
      end
    end
  end
end
