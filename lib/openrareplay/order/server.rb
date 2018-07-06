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

require_relative 'order'

module OpenRAReplay
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
end
