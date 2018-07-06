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

require_relative 'replay_sanitizer'
require_relative '../version'
require 'optparse'

module OpenRAReplay
  module Sanitize
    class CLI
      attr_accessor :ping, :message, :chat, :ip, :time, :password,
                    :player_name, :server_name, :in_name, :out_name, :force

      WARN_COUNT = 'Please provide an input and an output file!'.freeze
      WARN_INPUT = 'Input file must exist!'.freeze
      WARN_EXIST = "Output file exists! Pass the '--force' argument" \
                   ' to overwrite it.'.freeze

      def initialize(arguments)
        OptionParser.new do |parser|
          header parser
          option_ping parser
          option_message parser
          option_chat parser
          option_ip parser
          option_time parser
          option_password parser
          option_player_name parser
          option_server_name parser
          option_force parser
          footer parser
        end.parse! arguments
        handle_input arguments
      end

      def sanitize
        OpenRAReplay::Sanitize::ReplaySanitizer.new(in_name, out_name,
                                                    ping: ping,
                                                    message: message,
                                                    chat: chat,
                                                    ip: ip,
                                                    time: time,
                                                    password: password,
                                                    player_name: player_name,
                                                    server_name: server_name).sanitize
      end

      private

      def header(parser)
        parser.banner = "Usage: openra-sanitize [options] in_file out_file\n" \
                        'Reads an OpenRA replay file, trims/masks it, and outputs' \
                         ' the result as a new file' \

        parser.separator ''
        parser.separator 'Specific options:'
      end

      def footer(parser)
        parser.separator ''
        parser.separator 'Common options:'

        parser.on_tail('-h', '--help', 'Show this message') do
          puts parser
          Kernel.exit
        end

        parser.on_tail('--version', 'Show version') do
          puts "OpenRAReplay-Sanitize: #{OpenRAReplay::VERSION}"
          Kernel.exit
        end
      end

      def option_ping(parser)
        parser.on('-p', '--ping', TrueClass, 'Trim all ping-related content') do |p|
          self.ping = p
        end
      end

      def option_message(parser)
        parser.on('-m', '--message', TrueClass, 'Trim all server messages') do |m|
          self.message = m
        end
      end

      def option_chat(parser)
        parser.on('-c', '--chat', TrueClass, 'Trim all chat messages') do |c|
          self.chat = c
        end
      end

      def option_ip(parser)
        parser.on('-i', '--ip', TrueClass, 'Trim all IP addresses') do |i|
          self.ip = i
        end
      end

      def option_time(parser)
        parser.on('-t', '--time', TrueClass, 'Mask all dates and times') do |i|
          self.ip = i
        end
      end

      def option_password(parser)
        parser.on('-P', '--password', TrueClass, 'Trims the server password') do |p|
          self.password = p
        end
      end

      def option_player_name(parser)
        parser.on('-n', '--player-name', TrueClass, 'Masks all player names') do |n|
          self.player_name = n
        end
      end

      def option_server_name(parser)
        parser.on('-s', '--server-name', TrueClass, 'Trim the server name') do |s|
          self.server_name = s
        end
      end

      def option_force(parser)
        parser.on('-f', '--force', TrueClass, 'Force overwriting out_file') do |f|
          self.force = f
        end
      end

      def handle_input(arguments)
        warn_and_exit WARN_COUNT unless arguments.length == 2
        warn_and_exit WARN_INPUT unless File.exist? arguments.first
        warn_and_exit WARN_EXIST unless force || !File.exist?(arguments.last)
        self.in_name = arguments.first
        self.out_name = arguments.last
      end

      def warn_and_exit(text)
        warn text
        warn "Try 'openra-sanitize --help' for more information."
        Kernel.exit 1
      end
    end
  end
end
