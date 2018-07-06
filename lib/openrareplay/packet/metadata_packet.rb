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

require_relative 'packet'

module OpenRAReplay
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
      length2 = decode_u32 byte_array[(12 + length)..(15 + length)]
      raise "Appended length isn't correct: #{length2} vs expected #{length + 4}" unless length2 == (length + 4)
      footer = byte_array[(16 + length)..(19 + length)]
      raise "Metadata footer is not a footer: #{footer.inspect}" unless footer == METADATA_FOOTER
      @orders = []
    end

    def construct_byte_array(type)
      raise "#{self.class.name} only supports :data construction!" unless type == :data
      @orders = []
      @client_id = -1
      @frame = -1
      @length = data.length
      @byte_array = METADATA_HEADER + METADATA_VERSION +
                    (encode_u32 length) +
                    data.force_encoding('ASCII-8BIT') +
                    encode_u32(length + 4) + METADATA_FOOTER
    end
  end
end
