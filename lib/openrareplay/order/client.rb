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

require 'openrareplay/order/order'

module OpenRAReplay
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
end
