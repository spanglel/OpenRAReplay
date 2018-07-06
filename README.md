# OpenRA Replay
>    Copyright (C) 2018  Luke Spangler
>
>    This program is free software: you can redistribute it and/or modify
>    it under the terms of the GNU Affero General Public License as
>    published by the Free Software Foundation, either version 3 of the
>    License, or (at your option) any later version.
>
>    This program is distributed in the hope that it will be useful,
>    but WITHOUT ANY WARRANTY; without even the implied warranty of
>    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
>    GNU Affero General Public License for more details.

## Description
A library and executable that can parse OpenRA replay files and produce "sanitized" versions, without pings, exact timestamps, or other unnecessary information. The long term goal is to produce a full gem project packaging both a library and an executable for reading and writing  to OpenRA replay files. However, the library will never support parsing non-YAML data beyond preserving it as a chunk. Examples of non-YAML data includes unit and building orders.

## Requirements:
A relatively recent version of Ruby.

## Installation:
```
gem install openrareplay

```

## Usage:
```
Usage: openra-sanitize [options] in_file out_file
Reads an OpenRA replay file, trims/masks it, and outputs the result as a new file

Specific options:
    -p, --ping                       Trim all ping-related content
    -m, --message                    Trim all server messages
    -c, --chat                       Trim all chat messages
    -i, --ip                         Trim all IP addresses
    -t, --time                       Mask all dates and times
    -P, --password                   Trims the server password
    -n, --player-name                Masks all player names
    -s, --server-name                Trim the server name
    -f, --force                      Force overwriting out_file

Common options:
    -h, --help                       Show this message
        --version                    Show version
```
Keep in mind that some options might not make sense without another. For instance, without removing server messages, player names would still be revealed in those messages.

![Logo of the Affero General Public License](https://www.gnu.org/graphics/agplv3-155x51.png)

