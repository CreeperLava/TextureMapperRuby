require 'fileutils'
require 'sqlite3'
require 'gtk3'
require 'pathname'

include FileUtils

@dupes_db = SQLite3::Database.new 'database.db'
@full_db = SQLite3::Database.new 'full.db'

class Interface < Gtk::ApplicationWindow

  def initialize
    builder = Gtk::Builder.new(file: 'interface.ui')

    goButton = builder.get_object('goButton')
    goButton.signal_connect 'clicked' do
      runScan
    end

    @fileChooser = builder.get_object('filechooserdialog1')
    openButton = builder.get_object('openButton')
    openButton.signal_connect 'clicked' do
      toLeftPane
    end

    @optionStandalone = builder.get_object('optionStandalone')
    @optionRename = builder.get_object('optionStandalone')
    @optionCopy = builder.get_object('optionCopy')
    @chooseSourceFiles = builder.get_object('chooseSourceFiles')
    @chooseDestFolder = builder.get_object('chooseDestFolder')

    @gameBox = builder.get_object('gameBox')
    @gameBox.signal_connect 'changed' do
      @selectedGame = @gameBox.active
    end

    leftPane = builder.get_object('leftPane')
    @leftPaneBuffer = leftPane.buffer
    @hashRegex = Regexp.new(/((0x)[a-fA-F0-9]{8})/)
    @placeHolderTag = @leftPaneBuffer.create_tag(nil, foreground: 'grey')

    # Beautiful custom-made placeholder code for left pane
    @placeHolderText = 'Browse for the files you want to process above, if you want to port them.

You can also just paste some hashes here, one per line, if you just want to know what they correspond to.'
    focusOut
    leftPane.signal_connect_after('focus-out-event') { focusOut }
    leftPane.signal_connect('focus-in-event') { focusIn }

    @rightPaneBuffer = builder.get_object('rightPaneBuffer')

    @error = builder.get_object('error')

    main_window = builder.get_object('mainwindow')
    main_window.set_window_position Gtk::WindowPosition::CENTER
    main_window.show
    main_window.signal_connect('destroy') { exit! }
  end


  def toLeftPane
    @leftPaneBuffer.text = ''
    @files = @fileChooser.filenames
    tmp = []
    @files.each do |file|
      if File.file? file
        @leftPaneBuffer.insert(@leftPaneBuffer.end_iter, "#{Pathname.new(file).basename}\n")
      else # check subfolders
        Pathname(file).each_child do |c|
          tmp << c.to_s
          @leftPaneBuffer.insert(@leftPaneBuffer.end_iter, "#{Pathname.new(c).basename}\n") if c.file?
        end
      end
    end
    @files.concat tmp
    @chooseDestFolder.set_current_folder @fileChooser.current_folder
    @fileChooser.close
  end


  def toRightPane(hash, match)
    @rightPaneBuffer.insert(@rightPaneBuffer.end_iter, "#{hash} -> #{match[0]} (#{match[2]})\n")
  end


  def runScan
    if @selectedGame.nil?
      @error.text = 'No game selected.'
      return
    end

    @error.text = ''
    @rightPaneBuffer.text = ''

    if @files.nil?
      @leftPaneBuffer.text.split("\n").each do |line|
        search($1).each { |match| toRightPane($1, match) } if @hashRegex.match(line)
      end
    else
      destDir = "#{@chooseDestFolder.current_folder}/ME#{@selectedGame}"
      mkdir destDir unless (File.exist? destDir) || !@optionCopy.active?
      @files.each do |file|
        next unless @hashRegex.match(file)
        search($1).each do |match|
          next if match[0] == $1 && !@optionStandalone.active?

          match[2] = 's' if match[0] == $1
          copy(file, match) if @optionCopy.active?
          toRightPane($1, match)
        end
      end
    end
  end

  def search(hash)
    group_id = @dupes_db.execute("select groupid from textures where crc='#{hash}' limit 1")[0]

    if group_id.nil?
      if @optionStandalone.active?
        # Verify if hash is indeed present in selected game. If yes, add it to the list of hashes to copy with s (solo) flag
        # If not, return nil
        solo = @full_db.execute("select crc, name from ME#{@selectedGame} where crc='#{hash}' limit 1")
        return [] if solo.empty?

        solo[0][2] = 's'
        return solo
      else
        return []
      end
    end

    matches = @dupes_db.execute("select crc, name, grade from textures where groupid=#{group_id[0]} and game=#{@selectedGame}")
    matches
  end

  def copy(file, match)
    dest = "#{@chooseDestFolder.current_folder}/ME#{@selectedGame}/#{match[1]}_#{match[0]}"
    ext = Pathname.new(file).extname.to_s

    if @optionRename.active?
      dest2 = dest
      i = 0
      while File.file?("#{dest2}#{ext}")
        i += 1
        dest2 = "#{dest}_#{i}"
      end
      dest = dest2
    end
    cp file, "#{dest}#{ext}"
  end

  def focusOut
    return unless @leftPaneBuffer.text.empty?
    @leftPaneBuffer.text = @placeHolderText
    @leftPaneBuffer.apply_tag(@placeHolderTag, @leftPaneBuffer.start_iter, @leftPaneBuffer.end_iter)
  end

  def focusIn
    return unless @leftPaneBuffer.text == @placeHolderText
    @leftPaneBuffer.text = ''
    @leftPaneBuffer.remove_tag(@placeHolderTag, @leftPaneBuffer.start_iter, @leftPaneBuffer.end_iter)
  end
end

# Verify if access to internet
# Initialize or update the databases as needed
# Threaded to avoid having to wait because of latency before displaying interface
Process.spawn("ruby initialize.rb")
Interface.new
Gtk.main
