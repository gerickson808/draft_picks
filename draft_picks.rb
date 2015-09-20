require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'OpenSSL'

class Player
	attr_accessor :name, :score, :value, :position

	def initialize(name,position)
		@name = name
		@position = position
	end
end

$url_base = "http://games.espn.go.com/ffl/tools/projections?&seasonTotals=true&seasonId=2015&slotCategoryId="
def parse_names
	names=[]

	path = "//td[@class='playertablePlayerName']"
	$page1.xpath(path).each do |node|
		cell = node.text.split(/\W/)
		cell.delete_if {|x| x.empty?}

		name = "#{cell[0]} #{cell[1]}"
		names << name

	end
	return names
end

def parse_projections
	scores=[]
	path = "//td[@class='playertableStat appliedPoints']"
	$page1.xpath(path).each do |node|
		cell = node.text
		scores << cell
	end
	scores.shift
	return scores
end

def get_data(position)
	category_id = {"QB"=>"0", "RB"=>"2", "WR"=>"4", "TE"=>"6", "D"=>"16", "K"=>"17"}
		url = $url_base + category_id[position.upcase]
		$page1 = Nokogiri::HTML(open(url))
		names = parse_names
		scores = parse_projections
		players = create_players(names,scores,position)
		players = get_values(players)
	return players
end

def create_players(names,scores,position)
	players = []
	names.each_with_index do |name|
		player = Player.new(name, position)	
		players << player
	end
	scores.each_with_index {|projection, index| players[index].score = projection.to_f}
	return players
end

def find_top_players_avg(players)
	players.sort! {|a,b| b.score<=>a.score}
	total = 0
	0.upto(19) do |i|
		total += players[i].score
	end
	avg = total/20
	return avg
end

def find_top_players_median(players)
	players[9].score + players[10].score / 2
end

def get_values(players)
	top_avg = find_top_players_avg(players)
	top_median = find_top_players_median(players)
	top_low = players[19].score
	weight = top_median / top_avg
	players.map do |player|
		player.value = (player.score - top_low) * weight
	end
	return players
end

positions = %w(qb rb wr te d k)
pos = {}

positions.each do |position|
	pos[position] = get_data(position)
end
players = []
pos.each {|key, value| players << value}
players.flatten!.sort!{|a,b| b.value <=>a.value}

puts "Ready"

what_do = gets.chomp
until what_do == "quit"

if what_do.to_i > 0
	num = what_do.to_i - 1
	num.upto(num+19) do |i|
		puts "#{(i+1).to_s.ljust(2," ")} #{players[i].name.ljust(20," ")} #{players[i].position.upcase.ljust(2," ")}#{players[i].value.round(2).to_s.rjust(8," ")}"
	end
elsif positions.include? what_do
	pos[what_do].each_with_index {|player, i| puts "#{(i+1).to_s.ljust(2," ")} #{player.name.ljust(20," ")} #{player.position.upcase.ljust(2," ")}#{player.value.round(2).to_s.rjust(8," ")}"}
else
	puts "Please enter either a position or a number from which to list players at all positions."
end
what_do = gets.chomp

end