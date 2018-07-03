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

require 'openrareplay/packet/packet'
require 'openrareplay/packet/metadata_packet'

module OpenRAReplay
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
end
