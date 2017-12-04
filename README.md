# TextureMapperRuby

A port of the [TextureMapper](https://github.com/CreeperLava/MassEffectTextureMapper) for Ruby. More efficient than Java (less dependencies, way less RAM usage, faster, cleaner, what more can you ask for), and an interesting exercise in any case.

**Introduction**

This program is intended to facilitate modding of the Mass Effect trilogy (ME1, ME2, ME3).

Textures in those games are represented by hashes (hexadecimal IDs, ie 0x12345678). Many textures are reused across several games, sometimes identically, sometimes only with a resize or a small color change between one game and the other. This program makes use of a database of such textures made by AlvaroMe and myself, CreeperLava.

**Requirements**

Either Linux, Ruby 2.4 and the following Ruby gems : sqlite3, gtk3, google_drive. Install the gems with 'gem install name_of_gem'.
Or Windows, Ruby 2.4 and the same gems. Not thoroughly tested, but it should work.

**Usage**

Run the script with the following command : 'ruby texture_mapper.rb'

1. Browse for the files you wish to port from the top left dialog. The files will be displayed in the left pane, one per line. You can also add more hashes or filenames below manually, although those won't be copied over, only displayed.

2. Select the folder you want the ported textures to be copied into. By default it is set to where you selected the files. There will be no overwriting of the files you selected, the ported textures will be pasted in a subfolder named ME1, ME2 or ME3 depending on the game you choose.

4. Select the options you need. Hover over each checkbox to view the functionnality they provide in a tooltip.

5. Select the game you wish to port your textures to. The game your hashes come from doesn't matter. You can port textures from several games at once.

6. Click Go. The tool will match your hashes with the database, and display the results in the right pane. If you selected files, it will copy the matches in a subfolder.