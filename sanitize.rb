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

require 'psych'
require 'time'

module OpenRAReplay
  module MiniYaml
    def self.load(str)
      thing = str.gsub("\t", '  ')
      searches = []
      thing.scan(/MapTitle: (.+?)\n/m).each do |match|
        match = match.first
        searches.append [
          "MapTitle: #{match}\n",
          "MapTitle: '#{match.gsub("'", "''")}'\n"
        ]
      end
      thing.scan(/Name: (.+?)\n/m).each do |match|
        match = match.first
        searches.append ["Name: #{match}\n", "Name: '#{match.gsub("'", "''")}'\n"]
      end
      searches.each do |pair|
        thing.gsub!(pair.first, pair.last)
      end
      (Psych.safe_load thing)
    end

    def self.dump(object)
      thing = (Psych.dump object, indentation: 1)
              .force_encoding('ASCII-8BIT').gsub(/^---\n/m, '')
              .gsub('  ', "\t").gsub(': false', ': False')
              .gsub(': true', ': True').gsub(": \n", ":\n")
      searches = []
      thing.scan(/: '(.+?)'\n/m).each do |match|
        match = match.first
        searches.append [
          ": '#{match}'\n",
          ": #{match.gsub("''", "'")}\n"
        ]
      end
      thing.scan(/: "(.+?)"\n/m).each do |match|
        match = match.first
        searches.append [
          ": \"#{match}\"\n",
          ": #{match.gsub('\"', '"').gsub('\\\\', '\\')}\n"
        ]
      end
      searches.each do |pair|
        thing.gsub!(pair.first, pair.last)
      end
      thing
    end

    def self.load_time(str)
      Time.strptime(str + ' UTC', '%Y-%m-%d %H-%M-%S %Z')
    end

    def self.dump_time(time)
      time.utc.strftime('%Y-%m-%d %H-%M-%S')
    end
  end
  module Binary
    def encode_uleb128(val)
      bytes = ''.force_encoding('ASCII-8BIT')
      loop do
        byte = val & 0x7F
        val >>= 7
        byte |= 0x80 unless val.zero?
        bytes += byte.chr
        break if val.zero?
      end
      bytes
    end

    def decode_uleb128_io(input, hash = {})
      val = 0
      shift = 0
      read_bytes = ''
      loop do
        byte = input.read 1
        read_bytes += byte if hash[:output_read]
        byte = byte.ord
        val |= (byte & 0x7F) << shift
        break if (byte >> 7).zero?
        shift += 7
      end
      return [val, read_bytes] if hash[:output_read]
      val
    end

    def encode_u32(integer)
      [integer].pack('_L')
    end

    def decode_u32(string)
      string.unpack('_L').first
    end

    def decode_u8(string)
      string.unpack('C').first
    end
  end

  class Order
    extend Binary
    include Binary

    attr_reader :command, :data

    SERVER_COMMAND = 254.chr.freeze
    CLIENT_COMMAND = 255.chr.freeze
    SPECIAL_COMMAND = 191.chr.freeze

    def self.construct(input)
      char = input.read(1)
      case char
      when SERVER_COMMAND
        return ServerOrder.construct(input)
      when CLIENT_COMMAND
        return ClientOrder.construct(input)
      else
        return NotAnOrder.construct(input, char,
                                    char == SPECIAL_COMMAND)
      end
    end

    def initialize(hash = {})
      @command = hash[:command] || ''
      @data = hash[:data] || ''
    end

    def serialize
      ''
    end

    def to_s
      "<#{self.class.name} command: #{command} data: #{data}>"
    end

    def server_order?
      false
    end

    def client_order?
      false
    end

    def unknown?
      false
    end

    def special_command?
      false
    end

    def order?
      true
    end

    alias is_fe? server_order?
    alias is_ff? client_order?
  end

  class NotAnOrder < Order
    attr_reader :special_command

    def initialize(*args)
      @unknown = !!args.last[:special_command]
      super(*args)
    end

    def self.construct(input, char, special_command)
      new(
        command: char,
        data: input.read,
        special_command: special_command
      )
    end

    def serialize
      (command + data)
    end

    def special_command?
      special_command
    end

    def order?
      false
    end
  end

  class ServerOrder < Order
    def self.construct(input)
      # Credit to Stekke for putting me on the right
      # direction for these orders
      command_length = decode_uleb128_io input
      command = input.read(command_length)
      data_length = decode_uleb128_io input
      data = input.read(data_length)
      new(command: command, data: data)
    end

    def server_order?
      true
    end

    def serialize
      (Order::SERVER_COMMAND + encode_uleb128(command.length) +
       command + encode_uleb128(data.length) + data)
    end
  end

  class ClientOrder < Order
    def self.construct(input)
      command_length = decode_uleb128_io input
      command = input.read(command_length)

      # Credit to AMHOL for figuring out the structure
      # of these orders
      data = input.read(5) # subject id + flag
      flags = decode_u8(data[-1])
      if (flags & 1) == 1 # if the order has a target
        data += input.read(1)
        target_type = decode_u8(data[-1])
        case target_type
        when 1 # target is an actor
          data += input.read(4) # actor_id
        when 2 # target is the terrain
          data += if (flags & 64) == 64 # target is a cell
                    input.read(13) # target x, y, layer,
                  # and subcell
                  else # target is not a cell
                    input.read(12) # pos x, y, and z
                  end
        when 3 # target is a frozen actor
          data += input.read(8) # player actor id + frozen actor id
        end
      end
      if (flags & 4) == 4 # has target string
        strlen, out = decode_uleb128_io input, output_read: true
        data += out + input.read(strlen)
      end
      if (flags & 16) == 16 # has extra location data
        data += input.read(9) # extra x, y, and layer
      end
      if (flags & 32) == 32 # has extra data
        data += input.read(4) # has extra data
      end
      new(command: command, data: data)
    end

    def serialize
      (Order::CLIENT_COMMAND + encode_uleb128(command.length) +
       command + data)
    end

    def client_order?
      true
    end
  end

  class Packet
    include Binary

    attr_reader :client_id, :length, :frame,
                :data, :orders,
                :byte_array

    SERVER_LOBBY_PACKET = 0
    SPECIAL_FRAME = 214_748_364

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

  class MetadataPacket < Packet
    METADATA_HEADER = "\xFF\xFF\xFF\xFF".force_encoding('ASCII-8BIT').freeze
    METADATA_VERSION = "\x01\x00\x00\x00".force_encoding('ASCII-8BIT').freeze
    METADATA_FOOTER = "\xFE\xFF\xFF\xFF".force_encoding('ASCII-8BIT').freeze

    def unknown?
      false
    end

    def metadata?
      true
    end

    private

    def parse_byte_array
      header = byte_array[0..3]
      raise "Metadata header is not a header: #{header.inspect}" unless header == METADATA_HEADER
      version = byte_array[4..7]
      raise "Metadata version doesn't match current version: #{version.inspect}" unless version == METADATA_VERSION
      @length = decode_u32 byte_array[8..11]
      @client_id = -1
      @frame = -1
      @data = byte_array[12..(11 + length)]
      length_2 = decode_u32 byte_array[(12 + length)..(15 + length)]
      raise "Appended length isn't correct: #{length_2} vs expected #{length + 4}" unless length_2 == (length + 4)
      footer = byte_array[(16 + length)..(19 + length)]
      raise "Metadata footer is not a footer: #{footer.inspect}" unless footer == METADATA_FOOTER
      @orders = []
    end

    def construct_byte_array(type)
      if type == :data
        @orders = []
        @client_id = -1
        @frame = -1
        @length = data.length
        @byte_array = METADATA_HEADER + METADATA_VERSION +
                      (encode_u32 length) +
                      data.force_encoding('ASCII-8BIT') +
                      encode_u32(length + 4) + METADATA_FOOTER
      else
        raise "#{self.class.name} only supports :data construction!"
      end
    end
  end

  class PacketParser
    def initialize(file_stream)
      @file_stream = file_stream
    end

    def read_packet
      byte_array = @file_stream.read 12
      if byte_array[0..3] == "\xFF\xFF\xFF\xFF".force_encoding('ASCII-8BIT')
        length = byte_array[8..11].unpack('_L').first + 8
        byte_array += @file_stream.read length
        yield OpenRAReplay::MetadataPacket.new(byte_array: byte_array)
      else
        length = byte_array[4..7].unpack('_L').first - 4
        byte_array += @file_stream.read length
        yield OpenRAReplay::Packet.new(byte_array: byte_array)
      end
    end

    def eof?
      @file_stream.closed? || @file_stream.eof?
    end
  end

  class PacketSanitizer
    attr_reader :ping, :ip, :message
  end
end

INPUT_FILE = ARGV.first.freeze
OUTPUT_FILE = ARGV[1].freeze

raise 'Please provide an input file as an argument!' if INPUT_FILE.nil? ||
                                                        !File.file?(INPUT_FILE)
raise 'Please provide an output file as an argument!' if OUTPUT_FILE.nil?

warn INPUT_FILE
File.open(OUTPUT_FILE, 'wb') do |output_file|
  File.open(INPUT_FILE, 'rb') do |input_file|
    packet_parser = OpenRAReplay::PacketParser.new(input_file)
    player_map = {}
    until packet_parser.eof?
      packet_parser.read_packet do |packet|
        next if packet.unknown?
        newpacket = nil
        if packet.metadata?
          object = OpenRAReplay::MiniYaml.load(packet.data)
          start_time = OpenRAReplay::MiniYaml.load_time(object['Root']['StartTimeUtc'])
          epoch = Time.at(0).utc
          start_time = start_time.to_i
          stop_time = OpenRAReplay::MiniYaml.load_time(object['Root']['EndTimeUtc']) - start_time
          object['Root']['StartTimeUtc'] = OpenRAReplay::MiniYaml.dump_time(epoch)
          object['Root']['EndTimeUtc'] = OpenRAReplay::MiniYaml.dump_time(stop_time)
          object.each_key do |key|
            player = key.match(/^Player@(\d+)/)
            next unless player
            unless object[key]['IsBot']
              object[key]['Name'] = player_map[object[key]['Name']]
            end
            outcome_time = OpenRAReplay::MiniYaml.load_time(object[key]['OutcomeTimestampUtc']) - start_time
            object[key]['OutcomeTimestampUtc'] = OpenRAReplay::MiniYaml.dump_time(outcome_time)
          end
          newpacket = packet.class.new(data: OpenRAReplay::MiniYaml.dump(object))
        else
          newpacket = packet.class.new(
            client_id: packet.client_id,
            frame: packet.frame,
            orders: packet.orders.reject { |o| o.command == 'Ping' || o.command == 'Pong' || o.command == 'Message' || o.command.match('Chat') || o.command == 'SyncClientPings' }.map do |order|
              order = order
              if order.command.match('Sync') || order.command.match('Handshake')
                object = OpenRAReplay::MiniYaml.load order.data
                object['Handshake']['Password'] = nil if object['Handshake'] && object['Handshake']['Password']
                object.each_key do |key|
                  if key =~ /^Client$/
                    object[key]['IpAddress'] = nil
                  elsif key =~ /^Client@\d+$/
                    object[key]['IpAddress'] = nil
                    unless object[key]['IsBot']
                      unless player_map[object[key]['Name']]
                        player_map[object[key]['Name']] = "Player #{player_map.length + 1}"
                      end
                      object[key]['Name'] = player_map[object[key]['Name']]
                    end
                  end
                end
                object['GlobalSettings']['ServerName'] = nil if object['GlobalSettings']
                order = order.class.new(
                  command: order.command,
                  data: OpenRAReplay::MiniYaml.dump(object)
                )
              end
              order
            end
          )
        end
        output_file.write newpacket.byte_array
      end
    end
  end
end
