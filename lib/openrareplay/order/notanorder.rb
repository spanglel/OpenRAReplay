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
end
