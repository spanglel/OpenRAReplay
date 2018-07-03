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

module OpenRAReplay
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
      read_bytes = ''.force_encoding('ASCII-8BIT')
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
end
