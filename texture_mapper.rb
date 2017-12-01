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
    main_window = builder.get_object('mainwindow')
    main_window.set_window_position Gtk::WindowPosition::CENTER
    main_window.show
  end

end

def runScan
  puts 'yay'
end

# Verify if access to internet
# Initialize or update the databases as needed
# setup
window = Interface.new
Gtk.main

# http://www.rubydoc.info/gems/google_drive/GoogleDrive/File
# https://github.com/cedlemo/ruby-gtk3-tutorial
# http://www.rubydoc.info/gems/gtk3/3.2.1