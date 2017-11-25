require 'fileutils'
require 'sqlite3'
require './initialize.rb'
require 'fox16'

include Fox

$dupes_db = SQLite3::Database.new 'database.db'
$me1_db = SQLite3::Database.new 'ME1.db'
$me2_db = SQLite3::Database.new 'ME2.db'
$me3_db = SQLite3::Database.new 'ME3.db'

class Interface < FXMainWindow
  def initialize(app)
    super(app, 'Texture Mapper', width: 600, height: 400)
    workPane = FXHorizontalFrame.new(self, opts: LAYOUT_TOP)
    leftWorkPane = FXText.new(workPane, opts: LAYOUT_LEFT)
    rightWorkPane = FXText.new(workPane, opts: LAYOUT_RIGHT | TEXT_READONLY)

    buttonPane = FXHorizontalFrame.new(self, opts: LAYOUT_BOTTOM)
    optionRename = FXCheckButton.new(buttonPane, "Rename", opts: LAYOUT_RIGHT)
    buttonGo = FXButton.new(buttonPane, "Go!")

    buttonGo.connect(SEL_COMMAND) do
      testfez
    end
  end

  def create
    super
    show(PLACEMENT_SCREEN)
  end
end

def init_ui
  app = FXApp.new
  Interface.new(app)
  app.create
  app.run
end

def testfez
  puts "yay"
end

# Verify if access to internet
# Initialize or update the databases as needed
setup
init_ui

# http://www.rubydoc.info/gems/google_drive/GoogleDrive/File