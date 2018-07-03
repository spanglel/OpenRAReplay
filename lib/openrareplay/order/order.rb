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

require 'openrareplay/binary'

module OpenRAReplay
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
end
