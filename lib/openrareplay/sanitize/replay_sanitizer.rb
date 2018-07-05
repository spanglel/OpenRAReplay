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

require 'openrareplay/sanitize/packet_sanitizer'

module OpenRAReplay
  module Sanitize
    class ReplaySanitizer
      attr_reader :in_file, :out_file, :packet_sanitizer

      def initialize(in_name, out_name, opts={})
        @in_file = in_name
        @out_file = out_name
        @packet_sanitizer = OpenRAReplay::Sanitize::PacketSanitizer.new opts
      end
      
      def sanitize()
        File.open(out_file, 'wb') do |output_file|
          File.open(in_file, 'rb') do |input_file|
            packet_parser = OpenRAReplay::PacketParser.new(input_file)
            until packet_parser.eof?
              packet_parser.read_packet do |packet|
                next if packet.unknown?
                np = packet_sanitizer.sanitize_packet packet
                output_file.write np.byte_array
              end
            end
          end
        end
      end
    end
  end
end
