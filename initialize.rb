require 'google_drive'
require 'csv'

include GoogleDrive

def setup
  if internet?
    # create link with google drive
    session = Session.from_service_account_key('config.json')
    $ws = session.spreadsheet_by_key('1Gvnz_trNOUgW6CSI3eeEYk7SvqsSklIgVuoHDlmw8e8')

    # initialize trees if they don't exist
    (1..3).each { |g| create_tree g if File.empty? "ME#{g}.db" }

    # initialize or update duplicates database
    if !File.empty? 'database.db'
      update_db if $ws.modified_time > DateTime.parse(File.mtime('database.db').to_s)
    else
      create_db
    end
  end
end

def internet?
  require 'resolv'
  begin
    Resolv::DNS.new.getaddress('symbolics.com')
    return true
  rescue Resolv::ResolvError
    return false
  end
end

def create_db
  $ws.worksheets[4].export_as_file('TextureMap.csv') # texture map

  $dupes_db.execute <<-SQL
    create table textures (
      groupid int,
      game int,
      crc varchar(10),
      name varchar(100),
      size_x int,
      size_y int,
      format varchar(10),
      grade char,
      PRIMARY KEY(groupid, game, crc)
    );
  SQL
  # 2x faster than CSV.parse and much more efficient for memory (doesn't pull the whole file into RAM)
  CSV.foreach('TextureMap.csv', headers: true) do |row|
    $dupes_db.execute('insert into textures values ( ?, ?, ?, ?, ?, ?, ?, ? )', row.fields[0..7])
  end
  File.delete('TextureMap.csv')
end

def update_db
  $ws.worksheets[4].export_as_file('TextureMap.csv') # texture map

  CSV.foreach('TextureMap.csv', headers: true) do |row|
    $dupes_db.execute('insert into textures values ( ?, ?, ?, ?, ?, ?, ?, ? )', row.fields[0..7]) unless # add lines to database
        $dupes_db.execute("select * from textures where groupid=#{row[0]} and game=#{row[1]} and crc=#{row[2]} limit 1").empty? # unless they're already present
  end
  File.delete('TextureMap.csv')
end

def create_tree(game)
  $ws.worksheets[game-1].export_as_file("ME#{game}.csv")

  case game
  when 1
    database = $me1_db
  when 2
    database = $me2_db
  when 3
    database = $me3_db
  end
  database.execute <<-SQL
    create table ME#{game} (
      crc varchar(10),
      name varchar(100),
      PRIMARY KEY(crc, name)
    );
  SQL

  CSV.foreach("ME#{game}.csv", headers: true) do |row|
    database.execute("insert into ME#{game} values ( ?, ? )", row.fields[0..1])
  end
  File.delete("ME#{game}.csv")
end