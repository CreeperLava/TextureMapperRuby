require 'fileutils'
require 'sqlite3'
require './initialize.rb'
require 'gtk3'

$dupes_db = SQLite3::Database.new 'database.db'
$me1_db = SQLite3::Database.new 'ME1.db'
$me2_db = SQLite3::Database.new 'ME2.db'
$me3_db = SQLite3::Database.new 'ME3.db'

class Interface < Gtk::ApplicationWindow

  def initialize
    builder = Gtk::Builder.new(file: 'interface.ui')

    goButton = builder.get_object('goButton')
    goButton.signal_connect 'clicked' do
      runScan
    end

    @optionStandalone = builder.get_object('optionStandalone')
    @optionRename = builder.get_object('optionStandalone')

    @gameBox = builder.get_object('gameBox')
    @gameBox.signal_connect 'changed' do
      @selectedGame = gameBox.active
    end

    leftPane = builder.get_object('leftPane')
    @leftPaneBuffer = leftPane.buffer
    @hashRegex = Regexp.new(/((0x)[a-fA-F0-9]{8})/)
    placeHolderTag = @leftPaneBuffer.create_tag(nil, foreground: 'grey')

    # Beautiful custom-made placeholder code for left pane
    leftPane.signal_connect_after 'focus-out-event' do
      if @leftPaneBuffer.text == ""
        @leftPaneBuffer.text= "Paste your texture's hashes here, one per line."
        @leftPaneBuffer.apply_tag(placeHolderTag, @leftPaneBuffer.start_iter, @leftPaneBuffer.end_iter)
      end
    end
    leftPane.signal_connect 'focus-in-event' do
      if @leftPaneBuffer.text == "Paste your texture's hashes here, one per line."
        @leftPaneBuffer.text= ""
        @leftPaneBuffer.remove_tag(placeHolderTag, @leftPaneBuffer.start_iter, @leftPaneBuffer.end_iter)
      end
    end
    rightPaneBuffer = builder.get_object('rightPaneBuffer')

    main_window = builder.get_object('mainwindow')
    main_window.set_window_position Gtk::WindowPosition::CENTER
    main_window.show
  end



  def runScan

    @leftPaneBuffer.text.split("\n").each do |line|
        if @hashRegex.match(line)
          hash = $1
          filename = line
        #   TODO
        end
    end

    if @optionRename.active?

    end

    if @optionStandalone.active?

    end
    p @selectedGame
  end

end


# Verify if access to internet
# Initialize or update the databases as needed
# setup
window = Interface.new
Gtk.main

# http://www.rubydoc.info/gems/google_drive/GoogleDrive/File
# https://github.com/cedlemo/ruby-gtk3-tutorial
# http://www.rubydoc.info/gems/gtk3/3.2.1