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
end
