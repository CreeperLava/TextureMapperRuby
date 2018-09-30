require 'http'
require 'sqlite3'
require 'csv'

@texture_map = 'Texture_Map.csv'
@dupes_db = SQLite3::Database.new 'database.db'
@full_db = SQLite3::Database.new 'full.db'

def setup
  return unless internet?
  # initialize trees if they don't exist
  (1..3).each { |g| create_tree g } if File.empty? 'full.db'

  # update from github
  update_texture_map
end

# if database doesn't exist, create it
# else if database exists, check if texture map has been modified
# if yes, download the new and replace the original
def update_texture_map
  if File.empty? 'database.db'
    download_texture_map
    create_db
  elsif tree_updated?
    download_texture_map
    update_db
  end
  File.delete @texture_map if File.exist? @texture_map
end

def tree_updated?
  last_modified_time = File.open('database.db').mtime.strftime('%FT%TZ')
  HTTP.get("https://api.github.com/repos/CreeperLava/TextureMapperCrystal/commits?path=#{@texture_map}&since=#{last_modified_time}").to_s != '[]'
end

def download_texture_map
  File.write(@texture_map, HTTP.get('https://raw.githubusercontent.com/CreeperLava/TextureMapperCrystal/master/Texture_Map.csv').to_s.gsub("\r\n", "\n"))
end

def download_game_map(game)
  File.write("ME#{game}_Tree.csv", HTTP.get("https://raw.githubusercontent.com/CreeperLava/TextureMapperCrystal/master/ME#{game}_Tree.csv").to_s.gsub("\r\n", "\n"))
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
  @dupes_db.execute <<-SQL
    create table textures (
      groupid int,
      game int,
      crc varchar(10),
      name varchar(100),
      size_x int,
      size_y int,
      grade char,
      format varchar(10),
      PRIMARY KEY(groupid, game, crc)
    );
  SQL
  update_db

  # add indexes for faster searches
  @dupes_db.execute('create index index_crc on textures (crc)')
  @dupes_db.execute('create index index_groupid_game on textures (groupid, game)')
end

def update_db
  # 2x faster than CSV.parse and much more efficient for memory (doesn't pull the whole file into RAM)
  @dupes_db.transaction
  CSV.foreach(@texture_map, headers: true) do |row|
    unless @dupes_db.execute("select * from textures where groupid=#{row[0]} and game=#{row[1]} and crc=#{row[2]} limit 1").empty?
      @dupes_db.execute('insert into textures values ( ?, ?, ?, ?, ?, ?, ?, ? )', row[0..7])
    end # unless they're already present
  end
  @dupes_db.commit
  @dupes_db.execute('vacuum')
end

def create_tree(game)
  download_game_map(game)

  @full_db.execute <<-SQL
    create table ME#{game} (
      crc varchar(10),
      name varchar(100),
      PRIMARY KEY(crc, name)
    );
  SQL

  @full_db.transaction
  CSV.foreach("ME#{game}.csv", headers: true) do |row|
    @full_db.execute("insert into ME#{game} values ( ?, ? )", row)
  @full_db.commit
  end

  # add index for faster searches
  @full_db.execute("create index index_crc_me#{game} on ME#{game} (crc)")
  @full_db.execute('vacuum')
  File.delete("ME#{game}_Tree.csv")
end

setup
