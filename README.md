# OpenRA Replay Sanitizer
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
A single-file program and pseudo-library that can parse OpenRA replay files and produce "sanitized" versions, without pings, exact timestamps, or 
other unnecessary information. The long term goal is to produce a full gem project packaging both a library and an executable for reading and writing 
to OpenRA replay files. However, the library will never support parsing non-YAML data beyond preserving it as a chunk. Examples of non-YAML data 
includes unit and building orders.

## Requirements:
A relatively recent version of Ruby.

## Use:
Running this command will produce a new file with as much unnecessary and personal information stripped as possible. Future versions will include more 
configuration options.

```
ruby sanitizer.rb $INPUT_FILE $OUTPUT_FILE
```

![Logo of the Affero General Public License](https://www.gnu.org/graphics/agplv3-155x51.png)

